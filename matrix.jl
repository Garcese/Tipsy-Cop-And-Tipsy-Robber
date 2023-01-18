################################################################################
### All stuff related to the main matrix
################################################################################

function probs(i, n; rn = [])
    @variables psc[1:n+2] psn[1:n+2] psf[1:n+2] pzc[1:n+2] pzn[1:n+2] pzf[1:n+2]
    if i < 1
        probabilites = [0, 1, 0, 0, 1, 0] 
    elseif i == n
        probabilites = [psc[i], psn[i], 0, pzc[i], pzn[i], 0] 
    # elseif i > n
    #     probabilites = zeros(Num, 6)
    else
        probabilites = [psc[i], psn[i], psf[i], pzc[i], pzn[i], pzf[i]]
    end
    # If we can't have neutrals at that i, turn to 0.
    if i in rn
        probabilites[2] = 0
        probabilites[5] = 0
    end
    probabilites
end 

function my_subs(i, n; rn = [])
    @variables psc[1:n+2] psn[1:n+2] psf[1:n+2] pzc[1:n+2] pzn[1:n+2] pzf[1:n+2] C[1:n] c[1:n] f[1:n] F[1:n]
    Csub = i == 1 ? [nothing => nothing] : [psc[i]*pzc[i-1] => C[i]]
    Fsub = [psf[i]*pzf[i+1] => F[i]]
    # logic necessary depending on rn var, little c
    if i == 1 && i in rn
        csub = [psc[i] => c[i]]
    elseif i == 1
        csub = [psc[i] + psn[i]*pzc[i] => c[i]]
    elseif !(i in rn) && i - 1 in rn
        csub = [psn[i]*pzc[i] => c[i]]
    elseif i in rn && !(i - 1 in rn)
        csub = [psc[i]*pzn[i-1] => c[i]]
    else
        csub = [psc[i]*pzn[i-1] + psn[i]*pzc[i] => c[i]]
    end
    # now for little f
    if !(i in rn) && i + 1 in rn
        fsub = [psn[i]*pzf[i] => f[i]]
    elseif i in rn && !(i + 1 in rn)
        fsub = [psf[i]*pzn[i+1] => f[i]]
    else
        fsub = [psf[i]*pzn[i+1] + psn[i]*pzf[i] => f[i]]
    end
    Dict([Csub; csub; fsub; Fsub])
end

function gen_matrix(n; rn = [], simplify = true)
    matrix = zeros(Num, n, n)
    for i in 1:n, j in 1:n
        C = probs(i, n, rn = rn)[1]*probs(i - 1, n, rn = rn)[4]
        c = probs(i, n, rn = rn)[1]*probs(i - 1, n, rn = rn)[5] + probs(i, n, rn = rn)[2]*probs(i, n, rn = rn)[4]
        f = probs(i, n, rn = rn)[3]*probs(i + 1, n, rn = rn)[5] + probs(i, n, rn = rn)[2]*probs(i, n, rn = rn)[6]
        F = probs(i, n, rn = rn)[3]*probs(i + 1, n, rn = rn)[6]
        subs = my_subs(i, n, rn = rn)
        C = simplify ? substitute(C, subs) : C
        c = simplify ? substitute(c, subs) : c
        f = simplify ? substitute(f, subs) : f
        F = simplify ? substitute(F, subs) : F
        if i == j + 2
            matrix[i, j] = -C
        elseif i == j + 1
            matrix[i, j] = -c
        elseif i == j
            matrix[i, j] = C + c + f + F
        elseif i == j - 1
            matrix[i, j] = -f
        elseif i == j - 2
            matrix[i, j] = -F
        end
    end
    matrix
end

# Determinant Stuff ----------------

function prod_pivots(length; shift = 0, symbolic = false)
    max_index = length + shift
    if symbolic
        @variables S[1:max_index, 1:max_index]
        out = S[length, shift + 1]
    else
        @variables C[1:max_index] c[1:max_index] f[1:max_index] F[1:max_index]
        terms = []
        if length == 1
            out = c[1 + shift]
        else
            for i in 1:floor(length/2)
                i = Int(i)
                new_C = C[2*i + shift]
                new_F = length % 2 == 0 && i == floor(length/2) ? 1 : F[2*i - 1 + shift]
                append!(terms, new_C*new_F)
            end
            out = length % 2 == 0 ? prod(terms)*f[length - 1 + shift] : prod(terms)*c[length + shift] 
        end
    end
    out
end

function gen_det(n; symbolic = false, Xs = false)
    @variables C[1:n] c[1:n] f[1:n] F[1:n] X[1:n]
    dets = [prod_pivots(1, symbolic = symbolic)]
    i = 1
    while i < n
        to_add = []
        for (index, value) in enumerate(dets)
            new = i == index ? value*(Xs ? X[i+1] : C[i+1] + c[i+1]) : value*prod_pivots(i+1 - index, shift = index, symbolic = symbolic)
            append!(to_add, new)
        end
        append!(dets, sum(to_add) + prod_pivots(i+1, symbolic = symbolic))
        i += 1
    end
    dets[n] |> Symbolics.expand
end

