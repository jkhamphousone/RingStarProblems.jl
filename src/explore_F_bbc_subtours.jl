
function benders_st_optimize_explore!(m, x, y, f, F, B, str_lmr, inst, pars, start_time, gurobi_env, subtourlazy_cons, nsubtour_cons, ncall_bbc)

    d′ = inst.d′
    d = inst.d
    c′ = inst.c′
    V = inst.V
    n = length(V)
    V′ = 1:n+1
    tildeV = inst.tildeV
    log_level = pars.log_level

    @objective(m, Min, f(x, y) + F * B)


    nopt_cons = 0
    nconnectivity_cuts = 0
    nblossom = 0
    nblossom_pair_inequality = 0

    total_time, sp_time, t_two_opt_time, blossom_time = start_time, 0.0, 0.0, 0.0

    x̂ = Dict{Tuple{Int,Int},Bool}()
    ŷ = Dict{Tuple{Int,Int},Bool}()
    ntwo_opt = 0

    grb = JuMP.backend(m)
    info_nlazycons = 0
    if pars.gFreuse_lazycons
        info_nlazycons = nsubtour_cons[1] - nsubtour_cons[2]
        @info "Adding $info_nlazycons lazy constraints from previous B&BC solve. Total number of generated lazy constraints so far: $(length(subtourlazy_cons))"
        for i in nsubtour_cons[2]+1:nsubtour_cons[1]
            nsubtour_cons[2] += 1
            con = @constraint(m, subtourlazy_cons[i][1] >= subtourlazy_cons[i][2])
            MOI.set(grb, Gurobi.ConstraintAttribute("Lazy"), index(con), 1)
        end
        info_nlazycons = length(subtourlazy_cons)
    end

    function call_back_benders_lazy(cb_data)

        status = callback_node_status(cb_data, m)
        if status == MOI.CALLBACK_NODE_STATUS_INTEGER
            for i in V
                for j in V′
                    if j < n + 1
                        ŷ[i, j] = Bool(round(callback_value(cb_data, y[i, j])))
                    end
                    if i < j
                        x̂[i, j] = Bool(round(callback_value(cb_data, x[i, j])))
                    end
                end
            end
            nsubtour_cons_before = nsubtour_cons[1]
            ring_edges = create_ring_edges_lazy(callback_value.(cb_data, x), n)
            nsubtour_cons = createsubtour_constraintexplore!(m, subtourlazy_cons, cb_data, x, y, n, ring_edges, nsubtour_cons)
            if nsubtour_cons[1] == nsubtour_cons_before
                B_cb = callback_value(cb_data, B) * F

                # B_cb = callback_value(cb_data, B)

                start_time_sp = time()

                B_val, α, β, γ, δ, ζ = sp_optimize_poly(x̂, ŷ, F, B_cb, inst)

                B_val *= F

                sp_time += time() - start_time_sp

                if B_cb < B_val

                    B_computed, i★, j★, k★ = compute_B_critical_tripletexplore(inst, x̂, ŷ)
                    # @show i★, j★, k★
                    tildeJ = Set([(i, j, k) for i in V, j in tildeV, k in V′ if i != j && j != k && i < k])

                    con = @build_constraint(B >=
                                            sum((1 - y[i, i] + x[mima(i, j★)] + y[i, j★] - y[j★, j★] - sum(y[i, j] for j in setdiff(V, tildeV, i))) * minimum(d′[i, k] for k in setdiff(V, i, j★) if ŷ[k, k]) for i in setdiff(V, j★) if ŷ[i, j★]; init=0) +
                                            (2x[mima(i★, j★)] + 2x[mima(j★, k★)] - 3) * c′[i★, k★] +
                                            sum(sum(d′[i, k] * (y[i, j★] - 1) for k in setdiff(V, i, j★); init=0) for i in setdiff(V, j★) if ŷ[i, j★]; init=0) +
                                            sum(sum(minimum((d′[i, k] for k in setdiff(V, i, j★) if ŷ[k, k]; init = 0) - d′[i, j]) * (x[mima(i, j)] + y[i, j] - y[j, j]) for j in setdiff(V, i) if !ŷ[j, j] && minimum(d′[i, k] for k in setdiff(V, i, j★) if ŷ[k, k]; init=0) > d′[i, j]; init=0) for i in setdiff(V, j★) if ŷ[i, j★]; init=0)
                    )

                    MOI.submit(m, MOI.LazyConstraint(cb_data), con)
                    nopt_cons += 1
                end
            end
        end
    end



    function call_back_user_cuts(cb_data)
        max_current_value = -Inf
        if pars.ucstrat == 1
            max_current_value, con = create_connectivity_cut_strategy_1(cb_data, x, y, V, n, pars)
        elseif pars.ucstrat == 2
            max_current_value, con = create_connectivity_cut_strategy_2(cb_data, x, JuMP.VariableRef[y[i, i] for i in V], V, n, pars)
        elseif pars.ucstrat == 3
            max_current_value, con = create_connectivity_cut_strategy_3(cb_data, x, JuMP.VariableRef[y[i, i] for i in V], V, n, pars)
        elseif pars.ucstrat == 4
            max_current_value, con = create_connectivity_cut_strategy_4(cb_data, x, y, V, n, nconnectivity_cuts, pars)
        end
        if max_current_value > pars.uctolerance
            MOI.submit(m, MOI.UserCut(cb_data), con)
            nconnectivity_cuts += 1
        elseif pars.use_blossom
            tmp_time = time()
            con, nblossom_pair_inequality = create_blossom_inequalities(cb_data, x, y, n, nblossom_pair_inequality)
            if con !== nothing
                nblossom += 1
                if log_level > 1
                    @show con
                    @info "blossom inequality added"
                end
                MOI.submit(m, MOI.UserCut(cb_data), con)
            end
            blossom_time += time() - tmp_time
        end
    end



    MOI.set(m, MOI.LazyConstraintCallback(), call_back_benders_lazy)
    MOI.set(m, MOI.UserCutCallback(), call_back_user_cuts)


    pathdebug = eval(@__DIR__) * "/debug/explore_F/$(today())/"
    mkpath(pathdebug)
    open("$(pathdebug)$(length(ncall_bbc))_nbnodes=$(inst.n)_alpha=$(inst.α)_F=$(str_lmr == Inf ? "NoF-CompteKSInf" : F)_total_number_of_lazycons_generated=$info_nlazycons.lp", "w") do f
        println(f, m)
    end

    optimize!(m)

    total_time = time() - total_time



    log_level > 0 && @info "ended"



    t_time = round(total_time, digits=4)
    m_time = round(total_time - sp_time, digits=4)
    s_time = round(sp_time, digits=4)
    @info "Spent $(t_time)s in Benders decomposition\nSpent $(m_time)s in Master problem\nSpent $(s_time)s in subproblem\n$nopt_cons Optimality Constraints created\n$(nsubtour_cons[1]) Subtour Constraints created"


    st = MOI.get(m, MOI.TerminationStatus())
    @show "Termination status is $st"
    TL_reached = st == MOI.TIME_LIMIT
    if !has_values(m)
        return (m, t_time, m_time, s_time, t_two_opt_time, blossom_time, TL_reached, Inf, 0, objective_bound(m), zeros(Bool, n, n), zeros(Bool, n, n), nopt_cons, nsubtour_cons, nconnectivity_cuts, ntwo_opt, nblossom, MOI.get(m, MOI.NodeCount()))
    end



    @info "Objective : $(objective_value(m))"
    @info "Best bound : $(objective_bound(m))"
    @info "B : $(value(B))"
    @info "Blossom time : $(blossom_time)s"
    @info "Nb blossom, Nb blossom pair : $(nblossom), $(nblossom_pair_inequality)"
    return (m, t_time, m_time, s_time, t_two_opt_time, blossom_time, TL_reached, relative_gap(m), objective_value(m), objective_bound(m), value.(x), Bool.(round.(value.(y))), nopt_cons, nsubtour_cons, nconnectivity_cuts, ntwo_opt, nblossom, MOI.get(m, MOI.NodeCount()), subtourlazy_cons)
end

function createsubtour_constraintexplore!(m::Model, subtourlazy_cons, cb_data, x, y, n, ring_edges, nsubtour_cons; is_ilp=false)
    # function to add Labbe subtour elimination constraints by lazy constraints
    # caution, y is a 2-dimensional matrix, as x
    visited = falses(n + 1) # visited[i] = true iff i is a hub reachable from the depot
    N = [[] for i in 1:n+1]
    active_nodes = Set(Int[]) # Set of all hubs


    # Populating N: N[i] is a 2-element array containing the neighbors of i in the ring or is [], or has a unique element for s and t
    for i in 1:n
        for j in i+1:n+1
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
        #println("i=$(i), visited(i)=$(visited[i])")
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
        LHS = sum(sum(x[mima(i, j)] for j in setdiff(1:n+1, S)) for i in 1:n if i in S)
        for k in S
            RHS = 2sum(y[k, j] for j in S)
            con = @build_constraint(LHS >= RHS)
            if !is_ilp
                nsubtour_cons[1] += 1
                push!(subtourlazy_cons, (LHS, RHS))
            end
            MOI.submit(m, MOI.LazyConstraint(cb_data), con)
        end
    end
    return nsubtour_cons
end


function sp_optimize_poly(x̂, ŷ, F, B, inst)
    V = inst.V
    n = length(V)

    tildeV = inst.tildeV
    c′ = inst.c′
    d′ = inst.d′
    n = inst.n



    β = Dict{Tuple{Int,Int,Int},Float64}()
    δ = Dict{Tuple{Int,Int,Int},Float64}()
    γ = Dict{Tuple{Int,Int},Float64}()
    ζ = Dict{Tuple{Int,Int},Float64}()
    α = Dict{Int,Float64}()

    i★, j★, k★ = compute_B_critical_tripletexplore(inst, x̂, ŷ)[2:4]
    for i in V
        for j in tildeV
            for k in i+1:n+1
                if j != i && j != k
                    if (i, j, k) != (i★, j★, k★)
                        β[i, j, k] = 0
                        δ[i, j, k] = 0
                    end
                end
            end
        end
        if i != j★ && ŷ[i, j★]
            γ[i, j★] = F
            α[i] = F * minimum(d′[i, k] for k in setdiff(V, j★) if ŷ[k, k])
        elseif !ŷ[i, j★]
            γ[i, j★] = 0
        end

        if i != j★ && !ŷ[i, j★]
            α[i] = 0
        end

        for j in setdiff(V, tildeV, i)
            ζ[i, j] = F * minimum(d′[i, k] for k in setdiff(V, j★) if ŷ[k, k]) * ŷ[i, j★]
        end

        for j in setdiff(tildeV, i, j★)
            ζ[i, j] = 0
        end
        ζ[i, j★] = 0 # TODO tell André this is not in the LaTeX document
    end



    for j in setdiff(tildeV, j★)
        for i in setdiff(V, j)
            γ[i, j] = 0
        end
    end
    α[j★] = 0

    if i★ != k★
        β[i★, j★, k★] = F * c′[i★, k★]
        δ[i★, j★, k★] = F

        obj = c′[i★, k★] + sum(minimum(d′[i, k] for k in setdiff(V, j★) if ŷ[k, k]) for i in setdiff(V, j★) if ŷ[i, j★]; init=0)
    else
        β[i★, j★, k★] = 0
        δ[i★, j★, k★] = 0
        obj = 0
    end
    return obj, α, β, γ, δ, ζ
end

function debug_RRSP(inst, α, α_poly, β, β_poly, γ, γ_poly, δ, δ_poly, ζ, ζ_poly)
    println("test")
    V = inst.V
    n = length(V)
    tildeV = inst.tildeV
    for i in V
        if α[i] > 0 || α_poly[i] > 0
            println("α[$i] = $(α[i]), α_poly[$i] = $(α_poly[i])")
        end
    end
    for i in V
        for j in tildeV
            for k in i+1:n+1
                if i != j && j != k
                    if β[i, j, k] > 0 || β_poly[i, j, k] > 0
                        println("β[$i, $j, $k] = $(β[i,j,k]), β_poly[$i, $j, $k] = $(β_poly[i,j,k])")
                    end
                end
            end
        end
    end
    for i in V
        for j in setdiff(tildeV, i)
            if γ[i, j] > 0 || γ_poly[i, j] > 0
                println("γ[$i, $j] = $(γ[i,j]), γ_poly[$i,$j] = $(γ_poly[i,j])")
            end
        end
    end
    for i in V
        for j in tildeV
            for k in i+1:n+1
                if i != j && j != k
                    if δ[i, j, k] > 0 || δ_poly[i, j, k] > 0 && !(i == 1 && k == n + 1)
                        println("δ[$i, $j, $k] = $(δ[i,j,k]), δ_poly[$i, $j, $k] = $(δ_poly[i,j,k]) cost[$(inst.d′[i,k == n+1 ? 1 : k])]")
                    end
                end
            end
        end
    end
    for i in V
        for j in setdiff(V, i)
            if ζ[i, j] > 0 || ζ_poly[i, j] > 0
                println("ζ[$i, $j] = $(ζ[i,j]), ζ_poly[$i,$j] = $(ζ_poly[i,j])")
            end
        end
    end
end


function post_optimization_procedure(inst, ŷ, ŷ′)
    θ = Dict{Tuple{Int,Int},Float64}()
    n = inst.n
    for i in inst.V
        for j in inst.tildeV
            if i != j && ŷ[i, j]
                k = 1
                bool_k = true
                while bool_k
                    if k == n+1
                        bool_k = false
                    elseif k != i && !ŷ′[i, k]
                        k += 1
                    else
                        bool_k = false  
                    end
                end
                if k == n+1
                    θ[i, j] = inst.d′[i, 1]
                    ŷ′[i, 1] = 1
                end
            else
                θ[i, j] = 0
                ŷ′[i, j] = 0
            end
        end
    end
    return ŷ, ŷ′, θ
end


function compute_B_critical_tripletexplore(inst, x̂, ŷ)
    tildeV = inst.tildeV
    c′ = inst.c′
    d′ = inst.d′
    n = inst.n
    adj = Vector{Int}[Int[] for _ in 1:n+1]
    V = 1:n
    for i in V
        for j in i+1:n+1
            # if j < n+1 && x̂[i,j]
            if x̂[i, j] > .5
                push!(adj[j], i)
                push!(adj[i], j)
                # elseif j == n+1 && x̂[i,j]
                #     push!(adj[1], i)
                #     push!(adj[i], 1)
            end
        end
    end


    for i in setdiff(V,1)
        if ŷ[i, i] > .5
            @assert length(adj[i]) == 2
            if adj[i][1] > adj[i][2]
                adj[i][1], adj[i][2] = adj[i][2], adj[i][1]
            end
        end
    end

    costReconnection = zeros(Float64, n)
    for i in V
        if ŷ[i, i] < .5
            # Determining j such that ŷ[i,j] = 1
            j = 1
            while ŷ[i, j] < .5
                j += 1
            end
            if j in tildeV
                costReconnection[i] = Inf
                for k in setdiff(V, j)
                    if ŷ[k, k] > .5
                        if d′[i, k] < costReconnection[i]
                            costReconnection[i] = d′[i, k]
                        end
                    end
                end
            end
        end
    end

    B = 0.0
    i★, j★, k★ = -1, -1, -1
    for j in tildeV
        if ŷ[j, j] > .5
            hubFixingCost = c′[adj[j][1], adj[j][2]]
            for i in setdiff(V, j)
                if ŷ[i, j] > .5
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

function rrsp_create_ilp_lazyexplore(filename, inst, pars, nsubtour_cons, subtourlazy_cons, BSInf, KSl, hub1, hub2, hub3)
    println()
    two_opt_string = ""
    if pars.two_opt >= 1
        two_opt_string = "2-opt"
    end
    @info "ILP Solving F=Inf ---  $filename  ---"
    n = inst.n
    V′ = union(inst.V, n + 1)
    V = inst.V
    c = inst.c
    d = inst.d
    o = inst.o
    c′ = inst.c′
    d′ = inst.d′
    F = inst.F



    start_time = time()
    tildeV = inst.tildeV



    gurobi_env = Gurobi.Env()
    m_ilp = direct_model(Gurobi.Optimizer(gurobi_env))
    if pars.timelimit > 0
        set_optimizer_attribute(m_ilp, "TimeLimit", pars.timelimit)
    end
    set_optimizer_attribute(m_ilp, "Threads", pars.nthreads)
    set_optimizer_attribute(m_ilp, "OutputFlag", min(pars.log_level, 1))
    if pars.ucstrat > 0 || pars.use_blossom
        set_optimizer_attribute(m_ilp, "PreCrush", 1)
    end
    pars.log_level == 0 && set_silent(m_ilp)

    @variable(m_ilp, x_milp[i=V, j=i+1:n+1], Bin)
    @variable(m_ilp, y_milp[i=V′, j=V′], Bin)
    @variable(m_ilp, x′_milp[i=V, j=i+1:n+1], Bin)
    @variable(m_ilp, y′_milp[i=V, j=V; i != j], Bin)
    @variable(m_ilp, θ_milp[i=V, j=setdiff(tildeV, i)] >= 0)



    @constraint(m_ilp, number_hubs_1, sum(y_milp[i, i] for i in V) >= 4)


    @constraint(m_ilp, degree_constraint_2[i=setdiff(V′, 1, n + 1)], sum(x_milp[mima(i, j)] for j in V′ if i != j) == 2y_milp[i, i])

    @constraint(m_ilp, depot_connected_4, sum(x_milp[1, i] for i in setdiff(V, 1)) == 1)
    @constraint(m_ilp, depot_connected_5, sum(x_milp[i, n+1] for i in setdiff(V, 1)) == 1)

    @constraint(m_ilp, y_milp[1, 1] == 1)
    @constraint(m_ilp, y_milp[n+1, n+1] == 1)
    @constraint(m_ilp, [i = setdiff(V′, 1, n + 1)], y_milp[1, i] == 0)

    @constraint(m_ilp, hub_or_star_7[i=V], sum(y_milp[i, j] for j in V) == 1)

    for i in V
        for k in i+1:n+1
            for j in tildeV
                if j != i && j != k
                    # @constraint(m_ilp, x_milp[mima(i, j)] + x_milp[mima(j, k)] <= y_milp[j, j] + x′_milp[mima(i, k)])
                    @constraint(m_ilp, x_milp[mima(i, j)] + x_milp[mima(j, k)] <= 1 + x′_milp[mima(i, k)])
                end
            end
        end
    end


    # testing backup edge costs that are greater than BSInf
    n_x′fixed = 0
    n_y′fixed = 0
    for i in V
        for j in i+1:n+1
            if j < n+1
                if c′[i,j] > BSInf
                    fix(x′_milp[i,j], 0)
                    n_x′fixed += 1
                end
            elseif i != 1
                if c′[1,i] > BSInf
                    fix(x′_milp[i,n+1], 0)
                    n_x′fixed += 1
                end
            end
        end
        for j in setdiff(V, i)
            if d′[i,j] > BSInf
                n_y′fixed += 1
                fix(y′_milp[i,j], 0)
            end
        end
    end
    @info "fixed $n_x′fixed x′ variables and $n_y′fixed y′ variables"


    @constraint(m_ilp, backup_or_regular_edge_10[i=V, j=i+1:n+1], 2(x_milp[i, j] + x′_milp[i, j]) <= y_milp[i, i] + y_milp[j, j])


    @constraint(m_ilp, recovery_terminal_10[i=V], sum(y′_milp[i, j] for j in V if j != i) == 1 - y_milp[i, i] - sum(y_milp[i, j] for j in setdiff(V, tildeV, i)))

    @constraint(m_ilp, one_edge_or_arc_between_i_and_j_11[i=V, j=setdiff(V, i)], x_milp[mima(i, j)] + y_milp[i, j] + x′_milp[mima(i, j)] + y′_milp[i, j] <= y_milp[j, j])

    # if pars.ilpseparatingcons_method[1] == "with constraints (12)"
    #     @constraint(m_ilp, backup_or_regular_arc_12[i=V, j=V; i != j], y′_milp[i, j] <= y_milp[j, j] - y_milp[i, j])
    # end

    @constraint(m_ilp, reconnecting_star_cost_13[i=V, j=setdiff(tildeV, i)], sum(d′[i, k] * (y′_milp[i, k] + y_milp[i, j] - 1) for k in setdiff(V, i, j)) <= θ_milp[i, j])

    con14 = @constraint(m_ilp, backup_cost_14[i=V, j=tildeV, k=i+1:n+1; i != j && j != k], c′[mima(i, k)] * (x′_milp[mima(i, k)] + x_milp[mima(i, j)] + x_milp[mima(j, k)] - 2) + sum(θ_milp[t, j] for t in setdiff(V, j)) <= BSInf)
    @show BSInf



    # if pars.ilpseparatingcons_method[1] == "y_ij <= y_jj no constraint on the fly"
    #     @constraint(m_ilp, terminal_to_hub[i=V, j=setdiff(V, i)], y_milp[i, j] <= y_milp[j, j])
    # elseif pars.ilpseparatingcons_method[1] == "y_ij <= y_jj - x_ij no constraint on the fly"
    #     @constraint(m_ilp, terminal_to_hub[i=V, j=setdiff(V, i)], y_milp[i, j] <= y_milp[j, j] - x_milp[mima(i, j)])
    # end

    @info "Number of constraints in model is: $(num_constraints(m_ilp, AffExpr, MOI.GreaterThan{Float64}) + num_constraints(m_ilp, AffExpr, MOI.LessThan{Float64}))"


    function f_ilp(x_milp, y_milp)
        sum(sum(c[i, j] * x_milp[i, j] for j in V if i < j; init=0) for i in V) + sum(c[1, i] * x_milp[i, n+1] for i in 2:n) + sum(sum(d[i, j] * y_milp[i, j] for j in V if i != j) for i in V) + sum(o[i] * y_milp[i, i] for i in V)
    end


    # @constraint(m_ilp, f_ilp(x_milp, y_milp) ≥ KSl)

    m_ilp, UB, t_time, blossom_time, TL_reached, gap, LB, x̂, x̂′, ŷ, ŷ′, nsubtour_cons, nconnectivity_cuts, nedges_cuts, nblossom, explored_nodes = ilp_st_optimize_lazyexplore!(m_ilp, x_milp, y_milp, x′_milp, y′_milp, θ_milp, f_ilp, inst, pars, start_time, nsubtour_cons, subtourlazy_cons, hub1, hub2, hub3; pars.log_level)




    if has_values(m_ilp)


        if pars.log_level > 0
            if pars.log_level > 1
                println()
                @info "$nsubtour_cons Subtour Constraints created"
            end
        end


        @show LB, UB


        return UB, x̂, ŷ
    end
end

function ilp_st_optimize_lazyexplore!(m_ilp, x_milp, y_milp, x′_milp, y′_milp, θ_milp, f_ilp, inst, pars, start_time, nsubtour_cons, subtourlazy_cons, hub1, hub2, hub3; log_level=3)

    V = inst.V
    n = inst.n
    V′ = 1:n+1
    tildeV = inst.tildeV
    total_time = start_time
    blossom_time = 0.0

    @objective(m_ilp, Min, f_ilp(x_milp, y_milp))
    st = MOI.get(m_ilp, MOI.TerminationStatus())

    nconnectivity_cuts::Int = 0 # Number of connectivity cuts
    nedges_cuts::Int = 0
    nblossom::Int = 0
    nblossom_pair_inequality::Int = 0


    log_level > 1 && @info "Initial status $st"


    function call_back_ilp_lazy(cb_data)

        status = callback_node_status(cb_data, m_ilp)
        if status == MOI.CALLBACK_NODE_STATUS_INTEGER

            nsubtour_cons_before = nsubtour_cons[1]
            ring_edges = create_ring_edges_lazy(callback_value.(cb_data, x_milp), n)
            nsubtour_cons = createsubtour_constraintexplore!(m_ilp, subtourlazy_cons, cb_data, x_milp, y_milp, n, ring_edges, nsubtour_cons; is_ilp=true)
            if nsubtour_cons[1] == nsubtour_cons_before

                max_violated = 0.0
                max_i = -1
                max_j = -1
                for i in V
                    for j in setdiff(V, i)
                        current_violation = -callback_value(cb_data, y_milp[j, j]) + callback_value(cb_data, x_milp[mima(i, j)]) + callback_value(cb_data, y_milp[i, j])
                        if current_violation > max_violated
                            max_violated = current_violation
                            max_i = i
                            max_j = j
                        end
                    end
                end
                if max_violated > 0
                    con = @build_constraint(y_milp[max_i, max_j] <= y_milp[max_j, max_j] - x_milp[mima(max_i, max_j)])
                    MOI.submit(m_ilp, MOI.LazyConstraint(cb_data), con)
                    nedges_cuts += 1
                    return
                end
            end
        end
        if status == MOI.CALLBACK_NODE_STATUS_UNKNOWN
            error()
        end
    end



    function call_back_ilp_user_cuts(cb_data)
        max_current_value = -Inf
        if pars.ucstrat == 1
            max_current_value, con = create_connectivity_cut_strategy_1(cb_data, x_milp, y_milp, V, n, pars)
        elseif pars.ucstrat == 2
            max_current_value, con = create_connectivity_cut_strategy_2(cb_data, x_milp, JuMP.VariableRef[y_milp[i, i] for i in V], V, n, pars)
        elseif pars.ucstrat == 3
            max_current_value, con = create_connectivity_cut_strategy_3(cb_data, x_milp, JuMP.VariableRef[y_milp[i, i] for i in V], V, n, pars)
        elseif pars.ucstrat == 4
            max_current_value, con = create_connectivity_cut_strategy_4(cb_data, x_milp, y_milp, V, n, nconnectivity_cuts, pars)
        end
        if max_current_value > pars.uctolerance
            MOI.submit(m_ilp, MOI.UserCut(cb_data), con)
            nconnectivity_cuts += 1
        elseif pars.use_blossom
            tmp_time = time()
            con, nblossom_pair_inequality = create_blossom_inequalities(cb_data, x_milp, y_milp, n, nblossom_pair_inequality)
            if con !== nothing
                nblossom += 1
                if pars.log_level > 1
                    @show con
                    @info "blossom inequality added"
                end
                MOI.submit(m_ilp, MOI.UserCut(cb_data), con)
            end
            blossom_time += time() - tmp_time
        end
    end

    MOI.set(m_ilp, MOI.UserCutCallback(), call_back_ilp_user_cuts)
    MOI.set(m_ilp, MOI.LazyConstraintCallback(), call_back_ilp_lazy)



    pathdebug = eval(@__DIR__) * "/debug/explore_F/ILP/march/$(today())/"
    mkpath(pathdebug)
    open("$(pathdebug)nbnodes=$(n)_F=NoF-CompteKSInf.lp", "w") do f
        println(f, m_ilp)
    end




    ring = Tuple{Int,Int}[(1,hub2), (hub2, hub1), (hub1, hub3), (hub3, n+1)]
    ring_backup = Tuple{Int,Int}[(1, hub1), (hub2, hub3), (hub1, n+1)]

    hubs = Int[1, hub2, hub1, hub3, n+1]

    for i in V
        for j in i+1:n+1
            if (i,j) in ring
                println("x[$i,$j)]=true")
                set_start_value(x_milp[i,j], true)
            elseif (j, i) in ring
                println("x[$j,$i)]=true")
                set_start_value(x_milp[i,j], true)
            else
                # println("x[$i,$j)]=false")
                set_start_value(x_milp[i,j], false)
            end
            if (i,j) in ring_backup || (j,i) in ring_backup
                println("x'[$(mima(i,j)[1]),$(mima(i,j)[2])]=true")
                set_start_value(x′_milp[mima(i,j)], true)
            else
                # println("x[$i,$j]=false")
                set_start_value(x′_milp[mima(i,j)], false)
            end
        end
        for j in setdiff(tildeV, i)
            set_start_value(θ_milp[i, j], 0)
        end
    end
    for i in V′
        for j in V′
            
            if (j in hubs && i == j) || (j != i && j == 1 && !(i in hubs))
                println("y[$i,$j)]=true")
                set_start_value(y_milp[i,j], true)
            elseif i != j 
                set_start_value(y_milp[i,j], false)
            end
        end
        if i != n+1
            for j in setdiff(V, i)
                set_start_value(y′_milp[i,j], false)
            end
        end
    end
    println("y[$(n+1),$(n+1))]=true")
    set_start_value(y_milp[n+1,n+1], true)
        

    

    optimize!(m_ilp)

    c′ = inst.c′
    for k in keys(c′)
        for v in c′[k]
            print("c′[$(k[1]),$(k[2])] = $(v), ")
        println()
        end
    end

    d′ = inst.d′
    for k in keys(d′)
        for v in d′[k]
            print("d′[$(k[1]),$(k[2])] = $(v), ")
        println()
        end
    end

    total_time = time() - total_time
    ilp_time = round(total_time, digits=3)


    st = MOI.get(m_ilp, MOI.TerminationStatus())
    TL_reached = st == MOI.TIME_LIMIT
    if !has_values(m_ilp)
        @assert false
    end


    @info "Spent $(ilp_time)s in ILP"
    @info "Blossom time : $(blossom_time)s"
    @info "Generated $nsubtour_cons subtour constraints"
    @info "Generated $nconnectivity_cuts connectivty cuts"
    @info "Nb blossom, Nb blossom pair : $(nblossom), $(nblossom_pair_inequality)"


    println("Objective : $(objective_value(m_ilp))")

    return (m_ilp, objective_value(m_ilp), ilp_time, blossom_time, TL_reached, relative_gap(m_ilp), objective_bound(m_ilp), value.(x_milp), value.(x′_milp), value.(y_milp), value.(y′_milp), nsubtour_cons, nconnectivity_cuts, nedges_cuts, nblossom, MOI.get(m_ilp, MOI.NodeCount()))
end