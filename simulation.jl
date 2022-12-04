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

function simulation(adjMatrix, Sstart, Zstart; p = 0.5, q = 0.5, stayPut = false, animate = false)
    distMatrix = distance_matrix(adjMatrix)
    Spos = Sstart
    Zpos = Zstart
    n = 0
    myroll = 100
    if animate 
        anim = Animation()
        graph = Graph(adjMatrix)
    end 
    while Spos != Zpos
        if animate
            currentDist = distMatrix[Spos, :][Zpos]
            rollText = (n ->
                n == 0 ? "n/a" :
                n % 2 == 1 ? "Sroll: $(round(myroll, digits = 2))" :
                n % 2 == 0 ? "Zroll: $(round(myroll, digits = 2))" :  
                n).(n)
            nodeLabel = fill("", length(adjMatrix[1, :]))
            nodeLabel[Spos] = "S"
            nodeLabel[Zpos] = "Z"
            pos_helper = (nodeLabel -> 
                nodeLabel == "" ? 1 :
                nodeLabel == "S" ? 2 :
                nodeLabel == "Z" ? 3 : 
                nodeLabel).(nodeLabel)
            nodeColor = [colorant"grey", colorant"green", colorant"red"]
            nodeFillC = nodeColor[pos_helper]
            output = gplot(graph, nodelabel = nodeLabel, nodefillc = nodeFillC, layout = circular_layout)
            output = compose(output,
                (context(), Compose.text(-1.15, -1.05, "Turn: $n")),
                (context(), Compose.text(-1.15, -0.95, "Current Distance: $currentDist")),
                (context(), Compose.text(-1.15, -0.85, rollText)),
                (context(), rectangle(), fill("white"))
            )
            tmpFile = joinpath(anim.dir, @sprintf("%06d.png", n))
            Compose.draw(PNG(tmpFile), output)
            push!(anim.frames, tmpFile)
        end
        survTurn = n % 2 == 0
        curPos = survTurn ? Spos : Zpos
        oppPos = survTurn ? Zpos : Spos
        options = [index for (index, value) in enumerate(adjMatrix[curPos, :]) if value > 0]
        stayPut ? append!(options, curPos) : nothing # add currrent pos to options
        distances = distMatrix[options, :][:, oppPos]
        optDist = [[options[index], value] for (index, value) in enumerate(distances)]
        # 
        toBeat = survTurn ? p : q
        roll = rand(0:eps():1)
        myroll = roll
        if roll > toBeat # bad roll
            Spos = survTurn ? rand(optDist)[1] : Spos
            Zpos = survTurn ? Zpos : rand(optDist)[1]
        elseif survTurn
            optDist = [ele for ele in optDist if ele[2] == maximum(distances)]
            Spos = rand(optDist)[1]
        else 
            optDist = [ele for ele in optDist if ele[2] == minimum(distances)]
            Zpos = rand(optDist)[1]
        end
        n += 1
    end
    if animate
        rollText = (n ->
            n % 2 == 1 ? "Sroll: $(round(myroll, digits = 2))" :
            n % 2 == 0 ? "Zroll: $(round(myroll, digits = 2))" :  
            n).(n)
        nodeLabel = fill("", length(adjMatrix[1, :]))
            nodeLabel[Zpos] = "Z"
            pos_helper = (nodeLabel -> 
                nodeLabel == "" ? 1 :
                nodeLabel == "Z" ? 2 : 
                nodeLabel).(nodeLabel)
        nodeColor = [colorant"grey", colorant"red"]
        nodeFillC = nodeColor[pos_helper]
        output = gplot(graph, nodelabel = nodeLabel, nodefillc = nodeFillC, layout = circular_layout)
        output = compose(output,
            (context(), Compose.text(-1.15, -1.05, "Game ended on turn: $n")),
            (context(), Compose.text(-1.15, -0.95, "Current Distance: 0")),
            (context(), Compose.text(-1.15, -0.85, rollText)),
            (context(), rectangle(), fill("white"))
        )
        tmpFile = joinpath(anim.dir, @sprintf("%06d.png", n))
        Compose.draw(PNG(tmpFile), output)
        push!(anim.frames, tmpFile)
        gif(anim, "media/simulation.gif", fps = 1)
    else
        n
    end
end

# [simulation(petersen, 1, 10) for i in 1:10000] |> sum |> x -> x/10000

# function simulation(adjMatrix, Sstart, Zstart; p = 0.5, q = 0.5, stayPut = false)
#     distMatrix = distance_matrix(adjMatrix)
#     Spos = Sstart
#     Zpos = Zstart
#     n = 0
#     # test = [0, 0, 0, 0]
#     while Spos != Zpos
#         survTurn = n % 2 == 0
#         curPos = survTurn ? Spos : Zpos
#         oppPos = survTurn ? Zpos : Spos
#         options = [index for (index, value) in enumerate(adjMatrix[curPos, :]) if value > 0]
#         stayPut ? append!(options, curPos) : nothing # add currrent pos to options
#         distances = distMatrix[options, :][:, oppPos]
#         optDist = [[options[index], value] for (index, value) in enumerate(distances)]
#         # 
#         roll = rand(0:eps():1)
#         toBeat = survTurn ? p : q
#         if roll > toBeat # bad roll
#             Spos = survTurn ? rand(optDist)[1] : Spos
#             Zpos = survTurn ? Zpos : rand(optDist)[1]
#             # test = hcat(test, [n, Spos, Zpos, roll])
#         elseif survTurn
#             optDist = [ele for ele in optDist if ele[2] == maximum(distances)]
#             Spos = rand(optDist)[1]
#             # test = hcat(test, [n, Spos, Zpos, roll])
#         else 
#             optDist = [ele for ele in optDist if ele[2] == minimum(distances)]
#             Zpos = rand(optDist)[1]
#             # test = hcat(test, [n, Spos, Zpos, roll])
#         end
#         n += 1
#     end
#     n
#     # test
# end