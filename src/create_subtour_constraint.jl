function create_subtour_constraint_lazy_Labbe(
    m,
    cb_data,
    x,
    y,
    n,
    ring_edges,
    nsubtour_cons,
)
    # function to add Labbe subtour elimination constraints by lazy constraints
    # caution, y is a 2-dimensional matrix, as x
    visited = falses(n + 1) # visited[i] = true iff i is a hub reachable from the depot
    N = [[] for i = 1:n+1]
    active_nodes = Set(Int[]) # Set of all hubs


    # Populating N: N[i] is a 2-element array containing the neighbors of i in the ring or is [], or has a unique element for s and t
    for i = 1:n
        for j = i+1:n+1
            if (i, j) in ring_edges
                push!(N[i], j)
                push!(N[j], i)
                active_nodes = union(active_nodes, Set([i, j]))
            end
        end
    end

    # Populating visited by exploring the ring from node 1
    visited[1] = true
    i = N[1][1]
    visited[i] = true
    chain_complete = false
    if i == n + 1
        chain_complete = true
    end
    while chain_complete == false
        if visited[N[i][1]] == false
            i = N[i][1]
            visited[i] = true
        elseif visited[N[i][2]] == false
            i = N[i][2]
            visited[i] = true
        end

        if i == n + 1 # t has been reached
            chain_complete = true
        end
    end

    subtour = false

    # Checking if there is a subtour and populating S
    S = Int[]
    for i in active_nodes
        if visited[i] == false
            S = get_ring_nodes_lazy(ring_edges, i)
            subtour = true
            break
        end
    end

    # Generation of a lazy constraint to break the subtour
    if subtour == true
        for k in S
            nsubtour_cons += 1
            con = @build_constraint(
                sum(sum(x[mima(i, j)] for j in setdiff(1:n+1, S)) for i = 1:n if i in S) >= 2sum(y[k, j] for j in S)
            )
            MOI.submit(m, MOI.LazyConstraint(cb_data), con)

        end
    end
    return nsubtour_cons
end




function contains_subtour(ring, y, n)
    """ Returns true if the solution has subtours, and false otherwise"""
    potential_correct_ring = get_ring_nodes_lazy(ring, 1)
    nb_hubs = sum([y[i] > 0.5 for i = 1:n+1])
    return abs(length(potential_correct_ring) - nb_hubs) > 1.0e-6
end

function get_ring_nodes_lazy(ring, node)
    """ Returns the list of the hubs in the current solution """
    visited_nodes = Int[node]
    current_node = get_unvisited_neighboor_lazy(ring, node, visited_nodes)
    while current_node != 0
        push!(visited_nodes, current_node)
        current_node = get_unvisited_neighboor_lazy(ring, current_node, visited_nodes)
    end
    if length(visited_nodes) <= 1
        return Int[]
    end
    return visited_nodes
end

function get_unvisited_neighboor_lazy(ring, node, visited_nodes)
    """ A technical function used in get_ring_nodes_lazy """
    for edge in ring
        if (edge[1] == node) && (!(edge[2] in visited_nodes))
            return edge[2]
        end
        if (edge[2] == node) && (!(edge[1] in visited_nodes))
            return edge[1]
        end

    end
    return 0
end


function create_ring_edges_lazy(x, n)
    ring = Tuple{Int,Int}[]
    for i = 1:n
        for j = i+1:n+1
            if x[i, j] > 0.5
                push!(ring, (i, j))
            end
        end
    end
    return ring
end


function create_connectivity_cut_strategy_1(cb_data, x, y, V, n, pars)
    # """ TODO
    # Discribing strategy_number in [1,2,3,4]
    # ``\begin{itemize}
    # \item The first one is to solve one maximum-flow problem for each vertex $i\in V\backslash\{1\}:y_{ii}>0$ and to add only the connectivity cut that maximizes $2y_{ii} - f_i$. This strategy favors the most violated cut, in an attempt to keep deep cuts.
    # \item The second strategy is to stop solving more flow problems as soon as a vertex $i\in V\backslash\{1\}:y_{ii}>0$ such that $f_i < 2 y_{ii}$ is found. In practice, because of numerical imprecision, we need a given threshold $\varepsilon > 0$ to be exceeded, \textit{i.e.}, we must have $f_i + \varepsilon \le 2 y_{ii}$ for the cut to be considered violated. This strategy favors speed generation for connectivity cuts. But it seems that separating these connectivity cuts is very fast (at least for small instances).
    # \item The third strategy is to solve the max-flow problem for all the vertices in $V\backslash\{1\}$, and to keep only the inequality that is associated to a subset $S \subset V$ such that $\min(|S|,|V\backslash S|)$ is minimum, among the inequalities that are violated by an amount larger than a given threshold $\varepsilon$. Doing so favors inequalities that involve a minimum number of $x$ variables, avoiding the generation of \textit{dense} cuts, which are known to be detrimental in branch-and-cut solution methods (see \cite{MendezDiaz2008} Section 5.1, and \url{https://arxiv.org/pdf/2001.00858} page 11). Indeed, the worst case occurs when $S$ and $V\backslash S$ have the same cardinality: the corresponding connectivity cut involves $|\delta^+(S)|=\left(\frac{1}{2}n\right)^2$ $x$ variables, whereas the best case occurs when $S$ or $V\backslash S$ has cardinality one, leading to a connectivity cut involving $|\delta^+(S)|=n-1$ $x$ variables only. This strategy aims at maximizing the efficiency of connectivity cuts to keep the solver fast when they are added.
    #
    # 	\item The fourth strategy is to stop generating connectivity cuts when we reach a given threshold. Again, this limits the nasty impact on speed of adding too many cuts.
    # \end{itemize}
    # ``
    # """

    ε = 1e-6
    flow_graph, capacity_matrix, y_m = create_G_subtours(cb_data, x, y, n)

    max_violated_node = -1
    max_current_violation = 0.0


    bestf, bestpart1, bestpart2 = 0.0, Int[], Int[]
    for i = 2:n
        if y_m[i, i] > ε
            part1, part2, flow = GraphsFlows.mincut(
                flow_graph,
                1,
                i,
                capacity_matrix,
                EdmondsKarpAlgorithm(),
            )

            if !(i in part1)
                part1, part2 = part2, part1
            end
            if max_current_violation < 2sum(y_m[i, j] for j in setdiff(part1, n + 1)) - flow
                max_violated_node = i
                max_current_violation =
                    2sum(y_m[i, j] for j in setdiff(part1, n + 1)) - flow
                bestf = flow
                bestpart1 = part1
                bestpart2 = part2
            end
        end
    end

    if max_current_violation > pars.uctolerance
        # con = @build_constraint(sum(sum(x[mima(j,k)] for j in bestpart1) for k in bestpart2) >= 2y[max_violated_node,max_violated_node])
        con = @build_constraint(
            sum(sum(x[mima(j, k)] for j in bestpart1) for k in bestpart2) >=
            2sum(y[max_violated_node, j] for j in setdiff(bestpart1, n + 1))
        )
        return max_current_violation, con
    end
    return -1, []
end
function create_connectivity_cut_strategy_2(cb_data, x, y, V, n, pars)
    # """ TODO
    # Discribing strategy_number in [1,2,3,4]
    # ``\begin{itemize}
    # 	\item The first one is to solve one maximum-flow problem for each vertex $i\in V\backslash\{1\}:y_{ii}>0$ and to add only the connectivity cut that maximizes $2y_{ii} - f_i$. This strategy favors the most violated cut, in an attempt to keep deep cuts.
    # 	\item The second strategy is to stop solving more flow problems as soon as a vertex $i\in V\backslash\{1\}:y_{ii}>0$ such that $f_i < 2 y_{ii}$ is found. In practice, because of numerical imprecision, we need a given threshold $\varepsilon > 0$ to be exceeded, \textit{i.e.}, we must have $f_i + \varepsilon \le 2 y_{ii}$ for the cut to be considered violated. This strategy favors speed generation for connectivity cuts. But it seems that separating these connectivity cuts is very fast (at least for small instances).
    # 	\item The third strategy is to solve the max-flow problem for all the vertices in $V\backslash\{1\}$, and to keep only the inequality that is associated to a subset $S \subset V$ such that $\min(|S|,|V\backslash S|)$ is minimum, among the inequalities that are violated by an amount larger than a given threshold $\varepsilon$. Doing so favors inequalities that involve a minimum number of $x$ variables, avoiding the generation of \textit{dense} cuts, which are known to be detrimental in branch-and-cut solution methods (see \cite{MendezDiaz2008} Section 5.1, and \url{https://arxiv.org/pdf/2001.00858} page 11). Indeed, the worst case occurs when $S$ and $V\backslash S$ have the same cardinality: the corresponding connectivity cut involves $|\delta^+(S)|=\left(\frac{1}{2}n\right)^2$ $x$ variables, whereas the best case occurs when $S$ or $V\backslash S$ has cardinality one, leading to a connectivity cut involving $|\delta^+(S)|=n-1$ $x$ variables only. This strategy aims at maximizing the efficiency of connectivity cuts to keep the solver fast when they are added.
    #
    # 	\item The fourth strategy is to stop generating connectivity cuts when we reach a given threshold. Again, this limits the nasty impact on speed of adding too many cuts.
    # \end{itemize}
    # ``
    # """
    ε = 10e-16
    x_m = zeros(Float64, n, n)
    y_m = Float64[callback_value(cb_data, y[i]) for i = 1:n]
    flow_graph = DiGraph(n)
    capacity_matrix = zeros(Float64, n, n)
    for i = 1:n
        for j = i+1:n
            x_m[i, j] = callback_value(cb_data, x[i, j])
            if x_m[i, j] > ε
                add_edge!(flow_graph, i, j)
                add_edge!(flow_graph, j, i)
                capacity_matrix[i, j] = x_m[i, j]
                capacity_matrix[j, i] = x_m[i, j]
            end
        end
    end
    max_violated_node = -1
    max_current_violation = 0.0

    bestf, bestpart1, bestpart2 = 0.0, Int[], Int[]
    for i = 2:n
        if y_m[i] > ε
            part1, part2, flow = GraphsFlows.mincut(
                flow_graph,
                1,
                i,
                capacity_matrix,
                EdmondsKarpAlgorithm(),
            )
            if max_current_violation < 2y_m[i] - flow
                max_violated_node = i
                max_current_violation = 2y_m[i] - flow
                bestf = flow
                bestpart1 = part1
                bestpart2 = part2
                break
            end
        end
    end

    if max_current_violation > pars.uctolerance
        con = @build_constraint(
            sum(sum(x[mima(j, k)] for j in bestpart1) for k in bestpart2) >=
            2y[max_violated_node]
        )

        return max_current_violation, con
    end
    return -1, []
end
function create_connectivity_cut_strategy_3(cb_data, x, y, V, n, pars)
    # """ TODO
    # Discribing strategy_number in [1,2,3,4]
    # ``\begin{itemize}
    # 	\item The first one is to solve one maximum-flow problem for each vertex $i\in V\backslash\{1\}:y_{ii}>0$ and to add only the connectivity cut that maximizes $2y_{ii} - f_i$. This strategy favors the most violated cut, in an attempt to keep deep cuts.
    # 	\item The second strategy is to stop solving more flow problems as soon as a vertex $i\in V\backslash\{1\}:y_{ii}>0$ such that $f_i < 2 y_{ii}$ is found. In practice, because of numerical imprecision, we need a given threshold $\varepsilon > 0$ to be exceeded, \textit{i.e.}, we must have $f_i + \varepsilon \le 2 y_{ii}$ for the cut to be considered violated. This strategy favors speed generation for connectivity cuts. But it seems that separating these connectivity cuts is very fast (at least for small instances).
    # 	\item The third strategy is to solve the max-flow problem for all the vertices in $V\backslash\{1\}$, and to keep only the inequality that is associated to a subset $S \subset V$ such that $\min(|S|,|V\backslash S|)$ is minimum, among the inequalities that are violated by an amount larger than a given threshold $\varepsilon$. Doing so favors inequalities that involve a minimum number of $x$ variables, avoiding the generation of \textit{dense} cuts, which are known to be detrimental in branch-and-cut solution methods (see \cite{MendezDiaz2008} Section 5.1, and \url{https://arxiv.org/pdf/2001.00858} page 11). Indeed, the worst case occurs when $S$ and $V\backslash S$ have the same cardinality: the corresponding connectivity cut involves $|\delta^+(S)|=\left(\frac{1}{2}n\right)^2$ $x$ variables, whereas the best case occurs when $S$ or $V\backslash S$ has cardinality one, leading to a connectivity cut involving $|\delta^+(S)|=n-1$ $x$ variables only. This strategy aims at maximizing the efficiency of connectivity cuts to keep the solver fast when they are added.
    #
    # 	\item The fourth strategy is to stop generating connectivity cuts when we reach a given threshold. Again, this limits the nasty impact on speed of adding too many cuts.
    # \end{itemize}
    # ``
    # """
    ε = 10e-16
    x_m = zeros(Float64, n, n)
    y_m = Float64[callback_value(cb_data, y[i]) for i = 1:n]
    flow_graph = DiGraph(n)
    capacity_matrix = zeros(Float64, n, n)
    for i = 1:n
        for j = i+1:n
            x_m[i, j] = callback_value(cb_data, x[i, j])
            if x_m[i, j] > ε
                add_edge!(flow_graph, i, j)
                add_edge!(flow_graph, j, i)
                capacity_matrix[i, j] = x_m[i, j]
                capacity_matrix[j, i] = x_m[i, j]
            end
        end
    end
    max_violated_node = -1
    max_current_violation = 0.0

    bestf, bestF, bestlabels = 0.0, zeros(Float64, n, n), ones(Int64, n)
    for i = 2:n
        if y_m[i] > ε
            flow, F, labels = maximum_flow(
                flow_graph,
                1,
                i,
                capacity_matrix,
                algorithm = BoykovKolmogorovAlgorithm(),
            )
            if max_current_violation < 2y_m[i] - flow
                if sum(labels .== 1) <= sum(bestlabels .== 1)
                    max_violated_node = i
                    max_current_violation = 2y_m[i] - flow
                    bestf = flow
                    bestF = F
                    bestlabels = labels
                end
            end
        end
    end
    if max_current_violation > pars.uctolerance
        con = @build_constraint(
            sum(
                sum(
                    x[j, k] for j in V if j < k && (
                        (bestlabels[j] == 1 && bestlabels[k] != 1) ||
                        (bestlabels[k] == 1 && bestlabels[j] != 1)
                    )
                ) for k in V
            ) >= 2y[max_violated_node]
        )
        return max_current_violation, con
    end
    return -1, []
end
function createconnectivitycut(cb_data, x, y, V, n, nconnectivity_cuts, pars)
    # """ TODO
    # Discribing strategy_number in [1,2,3,4]
    # ``\begin{itemize}
    # 	\item The first one is to solve one maximum-flow problem for each vertex $i\in V\backslash\{1\}:y_{ii}>0$ and to add only the connectivity cut that maximizes $2y_{ii} - f_i$. This strategy favors the most violated cut, in an attempt to keep deep cuts.
    # 	\item The second strategy is to stop solving more flow problems as soon as a vertex $i\in V\backslash\{1\}:y_{ii}>0$ such that $f_i < 2 y_{ii}$ is found. In practice, because of numerical imprecision, we need a given threshold $\varepsilon > 0$ to be exceeded, \textit{i.e.}, we must have $f_i + \varepsilon \le 2 y_{ii}$ for the cut to be considered violated. This strategy favors speed generation for connectivity cuts. But it seems that separating these connectivity cuts is very fast (at least for small instances).
    # 	\item The third strategy is to solve the max-flow problem for all the vertices in $V\backslash\{1\}$, and to keep only the inequality that is associated to a subset $S \subset V$ such that $\min(|S|,|V\backslash S|)$ is minimum, among the inequalities that are violated by an amount larger than a given threshold $\varepsilon$. Doing so favors inequalities that involve a minimum number of $x$ variables, avoiding the generation of \textit{dense} cuts, which are known to be detrimental in branch-and-cut solution methods (see \cite{MendezDiaz2008} Section 5.1, and \url{https://arxiv.org/pdf/2001.00858} page 11). Indeed, the worst case occurs when $S$ and $V\backslash S$ have the same cardinality: the corresponding connectivity cut involves $|\delta^+(S)|=\left(\frac{1}{2}n\right)^2$ $x$ variables, whereas the best case occurs when $S$ or $V\backslash S$ has cardinality one, leading to a connectivity cut involving $|\delta^+(S)|=n-1$ $x$ variables only. This strategy aims at maximizing the efficiency of connectivity cuts to keep the solver fast when they are added.
    #
    # 	\item The fourth strategy is to stop generating connectivity cuts when we reach a given threshold. Again, this limits the nasty impact on speed of adding too many cuts.
    # \end{itemize}
    # ``
    # """
    if nconnectivity_cuts < pars.ucstrat_limit
        # if nconnectivity_cuts <= 1999
        # if nconnectivity_cuts%100 == 0
        #     println("Generating a user cut")
        # end
        return create_connectivity_cut_strategy_1(cb_data, x, y, V, n, pars)
    end
    return -1, []
end
