function post_optimization_procedure(inst, x̂, ŷ, ring)
    n = inst.n
    n_hubs = sum(ŷ[i,i] for i in 1:n)
    tildeV = inst.tildeV
    d′ = inst.d′
    # x′ = zeros(Bool, n, n+1)
    # y′ = zeros(Bool, n, n)
    x′ = Dict{Tuple{Int,Int},Bool}() 
    y′ = Dict{Tuple{Int,Int},Bool}() 
    θ = Dict{Tuple{Int,Int}, Float64}()

    V = 1:n
    if inst.F == 0 || isempty(tildeV)
        for i in V
            for j in setdiff(V,i)
                if i < j
                    x′[i,j] = false
                end
                y′[i,j] = false
                if j in tildeV
                    θ[i,j] = false
                end
            end
        end
    elseif n_hubs == 4
        a = -1
        b = -1
        c = -1
        unvisited_edges = Tuple{Int,Int}[]
        
        for edge in ring
            if !(edge[1] == 1 && edge[2] == n+1)
                if edge[1] == 1
                    a = edge[2]
                elseif edge[2] == 1
                    a = edge[1]
                elseif edge[1] == n+1
                    c = edge[2]
                elseif edge[2] == n+1
                    c = edge[1]
                else
                    push!(unvisited_edges, edge)
                end
            end
        end
        for edge in unvisited_edges
            if edge[1] == a
                b = edge[2]
            elseif edge[2] == a
                b = edge[1]
            elseif edge[1] == c
                b = edge[2]
            else
                @assert edge[2] == c
                b = edge[1]
            end
        end
        @assert a >= 0 && b >= 0 && c >= 0
        if 1 in tildeV || b in tildeV
            x′[a,c] = true
        end
        if a in tildeV || c in tildeV
            x′[1,b] = true
        end
    else
        for i in V
            for j in setdiff(tildeV, i)
                for k in setdiff(i+1:n+1,j)
                    if x̂[mima(i,j)] == x̂[mima(j,k)] == 1
                        x′[i,k] = true
                    end
                end
            end
        end
    end
    for i in V
        if ŷ[i,i]
            for j in setdiff(V,i)
                y′[i,j] = false
                if j in tildeV
                    θ[i,j] = .0
                end
            end
            
        else
            for j in setdiff(V,i)
                if ŷ[i,j] && j in setdiff(V,tildeV)
                    for k in setdiff(V,i)
                        y′[i,k] = false
                        θ[i,k] = .0
                    end
                elseif ŷ[i,j] && j in tildeV
                    min_d = Inf
                    k = -1
                    for q in setdiff(V,j)
                        if ŷ[q,q] && d′[i,q] < min_d
                            k = q
                            min_d = d′[i,q]
                        end
                    end
                    y′[i,k] = true
                    for q in setdiff(V,i,k)
                        y′[i,q] = false
                    end
                    θ[i,j] = min_d
                    for q in setdiff(tildeV,i,j)
                        θ[i,q] = .0
                    end
                end
            end
        end
    end
    return x′, y′, θ
end
        
function compute_B_critical_triple(inst, x̂, ŷ)
    tildeV = inst.tildeV
    c′ = inst.c′
    d′ = inst.d′
    n = inst.n
    if inst.F == 0 || isempty(tildeV)
        return 0, 1, 1, 1
    end
    adj = Vector{Int}[Int[] for _ in 1:n+1]
    V = 1:n
    for i in V
        for j in i+1:n+1
            # if j < n+1 && x̂[i,j]
            if x̂[i,j]
                push!(adj[j], i)
                push!(adj[i], j)
            # elseif j == n+1 && x̂[i,j]
            #     push!(adj[1], i)
            #     push!(adj[i], 1)
            end
        end
    end


    for i in V
        if ŷ[i,i]
            if length(adj[i]) == 2 && adj[i][1] > adj[i][2]
                adj[i][1], adj[i][2] = adj[i][2], adj[i][1]
            end
        end
    end

    costReconnection = zeros(Float64, n)
    for i in V
        if !ŷ[i,i]
            # Determining j such that ŷ[i,j] = 1
            j = 1
            while !ŷ[i,j]
                j += 1
            end
            if j in tildeV
                costReconnection[i] = Inf
                for k in setdiff(V,j)
                    if ŷ[k,k]
                        if d′[i,k] < costReconnection[i]
                            costReconnection[i] = d′[i,k]
                        end
                    end
                end
            end
        end
    end

    B = .0
    i★, j★, k★ = -1, -1, -1

    for j in tildeV
        if ŷ[j,j]
            hubFixingCost = c′[adj[j][1], adj[j][2]]
            for i in setdiff(V,j)
                if ŷ[i,j]
                    hubFixingCost += costReconnection[i]
                end
            end
            if hubFixingCost > B
                B = hubFixingCost
                i★, j★, k★ = adj[j][1], j, adj[j][2]
            end
        end
    end
    return B, i★, j★, k★

end
        
