################################################################################
### All stuff related to the main matrix
################################################################################

function adjugate(matrix)
    n = length(matrix) |> sqrt |> Int
    # If it's a 1x1 matrix, the adjugate is just 1
    if n == 1
        1
    else
        # Else starting calcuating matrix of minors
        cofMatrix = similar(matrix)
        for i in 1:n
            for j in 1:n
                cofMatrix[i, j] = matrix[Not(i), Not(j)] |> x -> (-1)^(i + j)*det(x)
            end
        end
        cofMatrix |> transpose .|> Symbolics.expand
    end
end

# Convert Symbolic.jl expression to sympy
function PyObject(ex::Num)
    ex |> x -> latexify(x, env = :raw) |> 
        String |> 
        x -> replace(x, r"\s+(?=[^[\{]*\})" => "") |> # when an index is greater than one digits
        x -> replace(x, r"(?<![\+,\-]) (?![\+,\-])" => "*") |> 
        x -> replace(x, r"}|{" => "") |> # this helps convert multidimensional symbolic arrays too!
        sympy.parse_expr
end

# Convert Symbolic.jl array to sympy
function PyObject(matrix::Matrix{Num})
    matrix .|> x -> latexify(x, env = :raw) |> 
        String |> 
        x -> replace(x, r"\s+(?=[^[\{]*\})" => "") |> # when an index is greater than one digits
        x -> replace(x, r"(?<![\+,\-]) (?![\+,\-])" => "*") |> 
        x -> replace(x, r"}|{" => "") |> # this helps convert multidimensional symbolic arrays too!
        sympy.parse_expr
end

# Convert Integery to Sympy
function PyObject(int::Int)
    int
end

# order indices, not using indexed bases
# Negative expressions print with (-1) in the front, which is not really desirable
function order_indices(expr::Sym; reverse = false)
    if expr.is_Mul
        indexed = [arg for arg in expr.args if !(arg.is_Add || arg.is_Mul)] .|> 
            string |> 
            x -> sort(x, by = y -> parse(Int, match(r"[0-9]+", y).match)) .|> # adjusted to account multi-digit indices
            sympy.sympify .|> 
            sympy.UnevaluatedExpr
        muls = [arg for arg in expr.args if arg.is_Mul]
        adds = [arg for arg in expr.args if arg.is_Add]
        new = 1
        for add in adds
            new = new*order_indices(add, reverse = reverse)
        end
        sympy.prod(muls)*sympy.prod(indexed)*new
    elseif expr.is_Add
        add_expr = 0
        for arg in expr.args
            add_expr = add_expr + order_indices(arg, reverse = reverse)
        end
        add_expr
    else 
        expr
    end
end

# If somehow gets passed to just a number
function order_indices(expr; reverse = false)
    expr
end

# create a big dictionary for substituting in the adjugate
function big_dict(n)
    dict = Dict([])
    for i in reverse(2:n), j in reverse(1:n)
        key = prod_pivots(i, shift = j - 1) |> PyObject
        value = prod_pivots(i, shift = j - 1, symbolic = true) |> PyObject
        push!(dict, key => value)
    end
    dict
end
