function create_G(cb_data, x, n)
<<<<<<< HEAD
    # ε = 1e-6
    x_m = zeros(Float64, n + 1, n + 1) # x_m[i,j] est la valeur callback fractionnaire de l'arête ij
=======
    x_m = zeros(Float64, n + 1, n + 1) # x_m[i,j] is the fractional callback value of edge (i,j)
>>>>>>> main
    G = DiGraph(n + 1)
    c_m = zeros(Float64, n + 1, n + 1)
    c′_m = zeros(Float64, n + 1, n + 1)

    for i in 1:n
        for j in i+1:n+1
            x_m[i, j] = callback_value(cb_data, x[i, j])
        end
    end
    for i in 1:n
        for j in i+1:n+1
            if x_m[i, j] > 0
                add_edge!(G, i, j)
                add_edge!(G, j, i)
                # Calcul of c and c'
                c_m[i, j] = x_m[i, j]
                c_m[j, i] = c_m[i, j]
                c′_m[i, j] = 1 - x_m[i, j]
                c′_m[j, i] = c′_m[i, j]
            end
        end

    end
    return G, c_m, c′_m
end
function create_G_subtours(cb_data, x, y, n)
    ε = 1e-6
    x_m = zeros(Float64, n + 1, n + 1)
    y_m = zeros(Float64, n, n)
    G = DiGraph(n + 1)
    capacity_matrix = zeros(Float64, n + 1, n + 1)
    for i in 1:n
        for j in i+1:n+1
            x_m[i, j] = callback_value(cb_data, x[i, j])
            if x_m[i, j] > ε
                add_edge!(G, i, j)
                add_edge!(G, j, i)
                capacity_matrix[i, j] = x_m[i, j]
                capacity_matrix[j, i] = x_m[i, j]
            end
        end
        for j in 1:n
            y_m[i, j] = callback_value(cb_data, y[i, j])
        end
    end
    capacity_matrix[1, n+1] = 1
    capacity_matrix[n+1, 1] = 1
    return G, capacity_matrix, y_m
end





cbv(cb_data, x, edge) = callback_value(cb_data, x[mima(edge[1], edge[2])])

function create_blossom_inequalities(cb_data, x, y, n, nblossom_pair_inequality)
    """
    Algorithm 2 of ODD MINIMUM CUT SETS AND b-MATCHINGS REVISITED page 1485
    """
    r = Inf
    # Compute G (n+1 nodes), c and c'
    G, c_m, c′_m = create_G(cb_data, x, n)
    # Compute graph G and the cut-tree
    c_min_m = min.(c_m, c′_m)
    E_T, max_flow = compute_cut_tree(n, G, c_min_m)

    best_F = Tuple{Int,Int}[]
    best_U = Int[]
    βU = Inf
    for e in E_T
        δU, U = create_cut_part_one(G, E_T, e, n)
        F_odd = 1
        if (1 in U && !(n + 1 in U)) || (n + 1 in U && !(1 in U))
            F_odd = 0
        end
        if length(δU) > 0
            βU, F = compute_βU(δU, c_m, c′_m, F_odd) # This function returns beta(U) as in (10) in the paper of Letchford and Theis, "Odd minimum cut sets and b-matching revisited", see page 1484. It also returns F, the associated subset of edges.
            if βU < r
                best_F = F
                best_U = U
                r = βU
            end
        end

    end
    if 1 > βU
        con = nothing
            # Constraints page 133-134 of Kedad-Sidhoum et al, 2010.
            if 1 in best_U && n + 1 in best_U
                con = @build_constraint(
                    sum(sum(x[i, j] for i in best_U if i < j) for j in best_U)
                    +
                    sum(x[mima(f[1], f[2])] for f in best_F)
                    <=
                    2 + 2sum(y[i, i] for i in setdiff(best_U, 1, n + 1)) - floor((length(best_F) - 1) / 2.0)
                    )
                    # @show "type 1"
                    # @show con
                    # @show best_U
                    # @show best_F
            elseif !(1 in best_U) && !(n + 1 in best_U)
                con = @build_constraint(
                    sum(sum(x[i, j] for i in best_U if i < j) for j in best_U)
                    +
                    sum(x[mima(f[1], f[2])] for f in best_F)
                    <=
                    2sum(y[i, i] for i in setdiff(best_U, 1, n + 1)) - floor((length(best_F) - 1) / 2.0)
                )
                # @show "type 2"
                #     @show con
                #     @show best_U
                #     @show best_F
            else # either s or t is in best_U, but not both of them, this is a blossom pair inequality
                nblossom_pair_inequality += 1
                con = @build_constraint(
                    sum(sum(x[i, j] for i in best_U if i < j) for j in best_U)
                    +
                    sum(x[mima(f[1], f[2])] for f in best_F)
                    <=
                    2sum(y[i, i] for i in setdiff(best_U, 1, n + 1)) - div(length(best_F), 2)
                )
                # @show "type 3 (blossom pair)"
                #     @show con
                #     @show best_U
                #     @show best_F
            end
        return con, nblossom_pair_inequality
    end
    return nothing, nblossom_pair_inequality
end

function compute_βU(δU, c_m, c′_m, F_odd)
    """
        This is step 5 of Algorithm 2
    """
    F = Tuple{Int,Int}[]
    f = (-1, -1)
    best_diff = Inf
    for e in δU
        # x_e = cbv(cb_data, x, edge)
        if c_m[e[1], e[2]] > c′_m[e[1], e[2]]
            push!(F, e)

        end
        if best_diff > abs(c_m[e[1], e[2]] - c′_m[e[1], e[2]])
            best_diff = abs(c_m[e[1], e[2]] - c′_m[e[1], e[2]])
            f = e
        end
    end
    if length(F) % 2 != F_odd # if |T cap U| + |F| is even, we should find an edge f as follows:
        if f in F
            filter!(e -> e ≠ f, F)
        else
            push!(F, f)
        end
    end

    # We calculate β(U) knowing F
    βU = 0
    for e in δU
        if !(e in F)
            βU += c_m[e[1], e[2]]
        else
            βU += c′_m[e[1], e[2]]
        end
    end
    return βU, F
end

function create_cut_part_one(G, E_T, edge, n)
    """
    for a given edge e of the cut tree of G (represented by its edge set E_T), this function returns the set U of nodes that belong to the same connected component as s (node 1) in the cut tree once edge e has been removed. It also returns δU, the set of all edges with exactly one endpoint in U
    """
    incidence_matrix = zeros(Bool, n + 1, n + 1) # Incidence matrix of G
    for e in E_T
        incidence_matrix[e[1], e[2]] = 1
        incidence_matrix[e[2], e[1]] = 1
    end
    δU = Tuple{Int,Int}[]

    incidence_matrix[edge[1], edge[2]] = 0 # Removing edge
    incidence_matrix[edge[2], edge[1]] = 0

    # for i in 1:n+1
    #     for j in 1:n+1
    #         if incidence_matrix[i,j] == 1
    #             @show i,j
    #         end
    #     end
    # end
    g = SimpleGraph(incidence_matrix)
    X = connected_components(g)
    if length(X) > 2
        @show X
        println("Cut tree")
        @show E_T
    # println()
    end
    for i in X[1]
        for j in X[2]
            # if has_edge(G, i, j)
            push!(δU, (i, j))
            # end
        end
    end
    return δU, X[1]
end


function compute_cut_tree(n, G, c_min_m)
    p = ones(Int, n + 1)
    # for i in 1:n+1
    #     for j in i+1:n+1
    #         if capacity_matrix[i,j] > 0
    #             println("$i => $j [$(capacity_matrix[i,j])] ; ")
    #         end
    #     end
    #     println()
    # end


    fl = zeros(Float64, n + 1)
    fl[1] = -1 # Should not be used
    for s in 2:n+1
        t = p[s]
        part1, part2, flow = GraphsFlows.mincut(G, s, t, c_min_m, EdmondsKarpAlgorithm())
        # @show part1
        # @show part2
        # @show flow
        X = s in part1 ? part1 : part2
        fl[s] = flow
        for i in 1:n+1
            if (i != s) && (i in X) && p[i] == t
                p[i] = s
            end
            
        end
        if p[t] in X
            p[s] = p[t]
            p[t] = s
            fl[s] = fl[t]
            fl[t] = flow
        end
    end
    # println("Cut tree")
    E_T = Tuple{Int,Int}[]
    for i in 2:n+1
        push!(E_T, (i, p[i]))
        # print("$i => $(p[i]) [$(fl[i])],\n")
    end
    # println()
    return E_T, fl
end