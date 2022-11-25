################################################################################
### Simulation
################################################################################

function distance_matrix(adjMatrix)
    n = length(adjMatrix) |> sqrt |> Int
    distMatrix = zeros(Int, n, n)
    for i in 1:n
        adjacents = [index for (index, value) in enumerate(adjMatrix[i, :]) if value == 1]
        traveled = [i]
        allAdj = []
        dist = 0
        while !issetequal(traveled, 1:n)
            dist += 1
            for j in adjacents
                distMatrix[j, i] = dist 
                adjToj = [index for (index, value) in enumerate(adjMatrix[j, :]) if value == 1]
                allAdj = union(adjToj, allAdj) # all nodes adjacent to the js
                append!(traveled, j)
                adjacents = setdiff(allAdj, traveled) # all new nodes to travel to
            end
        end
    end
    distMatrix
end

function simulation(adjMatrix, Sstart, Zstart; p = 0.5, q = 0.5, stayPut = false)
    distMatrix = distance_matrix(adjMatrix)
    Spos = Sstart
    Zpos = Zstart
    n = 0
    # test = [0, 0, 0, 0]
    while Spos != Zpos
        survTurn = n % 2 == 0
        curPos = survTurn ? Spos : Zpos
        oppPos = survTurn ? Zpos : Spos
        options = [index for (index, value) in enumerate(adjMatrix[curPos, :]) if value > 0]
        stayPut ? append!(options, curPos) : nothing # add currrent pos to options
        distances = distMatrix[options, :][:, oppPos]
        optDist = [[options[index], value] for (index, value) in enumerate(distances)]
        # 
        roll = rand(0:eps():1)
        toBeat = survTurn ? p : q
        if roll > toBeat # bad roll
            Spos = survTurn ? rand(optDist)[1] : Spos
            Zpos = survTurn ? Zpos : rand(optDist)[1]
            # test = hcat(test, [n, Spos, Zpos, roll])
        elseif survTurn
            optDist = [ele for ele in optDist if ele[2] == maximum(distances)]
            Spos = rand(optDist)[1]
            # test = hcat(test, [n, Spos, Zpos, roll])
        else 
            optDist = [ele for ele in optDist if ele[2] == minimum(distances)]
            Zpos = rand(optDist)[1]
            # test = hcat(test, [n, Spos, Zpos, roll])
        end
        n += 1
    end
    n
    # test
end

# [simulation(petersen, 1, 10) for i in 1:10000] |> sum |> x -> x/10000
