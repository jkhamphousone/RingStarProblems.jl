
@with_kw mutable struct ILPtable @deftype Float64
    t_time = .0 ; @assert t_time >= .0
    two_opt_time = .0 ; @assert two_opt_time >= .0
    blossom_time = .0 ; @assert blossom_time >= .0
    TL_reached = false ;
    gap = .0 ; @assert 0 <= gap
    UB = .0
    LB = .0
    nsubtour_cons = 0 ; @assert nsubtour_cons >= 0
    nconnectivity_cuts = 0 ; @assert nconnectivity_cuts >= 0
    nedges_cuts = 0 ;
    ntwo_opt = 0 ; @assert ntwo_opt >= 0 #11
    nblossom = 0 ; @assert nblossom >= 0 #12
    nodes_explored::Int = -1 ;
    sol::Solution = Solution() ;
    """
    """
end
    
function round!(ilp::ILPtable)
    setfield!.(Ref(ilp), 1:4, round.(getfield.(Ref(ilp), 1:4), digits=2))
    setfield!.(Ref(ilp), 5:5, round.(getfield.(Ref(ilp), 5:5), digits=3))
    setfield!.(Ref(ilp), 6:12, round.(getfield.(Ref(ilp), 6:12), digits=2))
    return ilp
end


function rrsp_create_ilp_lazy(filename, inst, pars)
    println()
    two_opt_string = ""
    if pars.two_opt >= 1
        two_opt_string = "2-opt"
    end
    @info "ILP Solving F=$(pars.F) ---  $filename  ---"
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
    m = direct_model(Gurobi.Optimizer(gurobi_env))
    if pars.timelimit > 0
        set_optimizer_attribute(m, "TimeLimit", pars.timelimit)
    end
    set_optimizer_attribute(m, "Threads", pars.nthreads)
    set_optimizer_attribute(m, "OutputFlag", min(pars.log_level, 1))
    if pars.ucstrat > 0 || pars.use_blossom
        set_optimizer_attribute(m, "PreCrush", 1)
    end
    pars.log_level == 0 && set_silent(m)

    @variable(m, x[i=V, j=i+1:n+1], Bin)
    @variable(m, y[i=V′, j=V′], Bin)
    @variable(m, x′[i=V, j=i+1:n+1], Bin)
    @variable(m, y′[i=V, j=V; i != j], Bin)
    @variable(m, θ[i=V, j=setdiff(tildeV, i)] >= 0)
    
    time_BSInf = time()
    BSInf = computeBSInf(inst)[1]
    time_BSInf = round(time() - time_BSInf,digits=5)
    @info "Computed BSInf=$BSInf in $(time_BSInf)s" 
    @variable(m, B >= 0)


    # @constraint(m, x′[1,n+1] == 0)
    # @constraint(m, x[1,n+1] == 1)
    @constraint(m, number_hubs_1, sum(y[i, i] for i in V) >= 4)


    @constraint(m, degree_constraint_2[i=setdiff(V′, 1, n + 1)], sum(x[mima(i, j)] for j in V′ if i != j) == 2y[i, i])

    @constraint(m, depot_connected_4, sum(x[1, i] for i in setdiff(V, 1)) == 1)
    @constraint(m, depot_connected_5, sum(x[i, n+1] for i in setdiff(V, 1)) == 1)


    @constraint(m, y[1, 1] == 1)
    @constraint(m, y[n+1, n+1] == 1)
    @constraint(m, depot_s_not_aterminal[i = setdiff(V′, 1)], y[1, i] == 0)
    @constraint(m, depot_t_not_aterminal[i = setdiff(V′, n + 1)], y[n+1, i] == 0)

    @constraint(m, hub_or_star_7[i=V], sum(y[i, j] for j in V) == 1)

    # @constraint(m, arc_or_edge_8[i=V,j=V; i != j], y[i,j] <= y[j,j] - x[mima(i,j)])


    for i in V
        for k in i+1:n+1
            for j in tildeV
                if j != i && j != k
                    @constraint(m, x[mima(i, j)] + x[mima(j, k)] <= 1 + x′[mima(i, k)])
                end
            end
        end
    end


    # if pars.ilpseparatingcons_method[1] == ""
    #     @constraint(m, backup_or_regular_edge_10[i=V, j=i+1:n+1], 2(x[i, j] + x′[i, j]) <= y[i, i] + y[j, j])
    # end

    @constraint(m, recovery_terminal_10[i=V], sum(y′[i, j] for j in V if j != i) == 1 - y[i, i] - sum(y[i, j] for j in setdiff(V, tildeV, i)))

    @constraint(m, one_edge_or_arc_between_i_and_j_11[i=V, j=setdiff(V, i)], x[mima(i, j)] + y[i, j] + x′[mima(i, j)] + y′[i, j] <= y[j, j])

    # if pars.ilpseparatingcons_method[1] == "with constraints (12)"
    #     @constraint(m, backup_or_regular_arc_12[i=V, j=V; i != j], y′[i, j] <= y[j, j] - y[i, j])
    # end

    @constraint(m, reconnecting_star_cost_13[i=V, j=setdiff(tildeV, i)], sum(d′[i, k] * (y′[i, k] + y[i, j] - 1) for k in setdiff(V, i, j)) <= θ[i, j])

    @constraint(m, backup_cost_14[i=V, j=tildeV, k=i+1:n+1; i != j && j != k], c′[mima(i, k)] * (x′[mima(i, k)] + x[mima(i, j)] + x[mima(j, k)] - 2) + sum(θ[t, j] for t in setdiff(V, j)) <= B)


    # if pars.ilpseparatingcons_method[1] == "y_ij <= y_jj no constraint on the fly"
    #     @constraint(m, terminal_to_hub[i=V, j=setdiff(V, i)], y[i, j] <= y[j, j])
    # elseif pars.ilpseparatingcons_method[1] == "y_ij <= y_jj - x_ij no constraint on the fly"
    #     @constraint(m, terminal_to_hub[i=V, j=setdiff(V, i)], y[i, j] <= y[j, j] - x[mima(i, j)])
    # end

    @info "Number of constraints in model is: $(num_constraints(m, AffExpr, MOI.GreaterThan{Float64}) + num_constraints(m, AffExpr, MOI.LessThan{Float64}))"

    if length(pars.warm_start) > 0
        @show warm_start
        y_warm = zeros(Bool, n)
        for i in V
            if i in warm_start
                set_start_value(y[i, i], true)
                y_warm[i] = true
            else
                set_start_value(y[i, i], false)
            end
        end
        x_warm = zeros(Bool, n, n)
        x′_warm = zeros(Bool, n, n)
        for i in V
            for j in i+1:n
                set_start_value(x[i, j], false)
            end
        end
        for i in 1:length(warm_start)-1
            set_start_value(x[mima(warm_start[i], warm_start[i+1])...], true)
            x_warm[mima(warm_start[i], warm_start[i+1])...] = true
        end

        set_start_value(x[warm_start[end], n+1], true)

    end
    @show F
    function f(x, y)
        sum(sum(c[i, j] * x[i, j] for j in V if i < j; init=0) for i in V) + sum(c[1, i] * x[i, n+1] for i in 2:n) + sum(sum(d[i, j] * y[i, j] for j in V if i != j) for i in V) + sum(o[i] * y[i, i] for i in V) + F * B
        # sum(sum(c[i,j]*x[i,j] for j in V if i < j; init=0) for i in V) + sum(sum(d[i,j]*y[i,j] for j in V if i != j) for i in V) + sum(o[i]*y[i,i] for i in V) + F*B
    end


    bestsol, bestobjval = three(inst.n, inst.o, inst.c, inst.d, tildeV)
    # bestsol, bestobjval = four(inst.n, inst.o, inst.r, inst.s, tildeV, bestobjval, bestsol)
    # @constraint(m, f(x,y) + pars.F*B <= bestobjval)
    # set_optimizer_attribute(m, "Cutoff", bestobjval)
    # @info "3 hubs objective:" bestobjval

    m, UB, t_time, blossom_time, TL_reached, gap, LB, x̂, x̂′, ŷ, ŷ′, nsubtour_cons, nconnectivity_cuts, nedges_cuts, nblossom, explored_nodes = ilp_st_optimize_lazy!(m, x, y, x′, y′, f, V, n, inst.d, pars, start_time; pars.log_level)





    if has_values(m)
        x̂_bool = Dict{Tuple{Int,Int},Bool}()
        x̂′_bool = Dict{Tuple{Int,Int},Bool}()
        ŷ_bool = Dict{Tuple{Int,Int},Bool}()
        ŷ′_bool = Dict{Tuple{Int,Int},Bool}()

        for i in 1:n
            for j in 1:n+1
                if j > i
                    x̂_bool[i, j] = x̂[i, j] > 0.5
                    x̂′_bool[i, j] = x̂′[i, j] > 0.5
                end
                if j < n + 1
                    ŷ_bool[i, j] = ŷ[i, j] > 0.5
                    if i != j
                        ŷ′_bool[i, j] = ŷ′[i, j] > 0.5
                    end
                end
            end
        end




        ring = create_ring_edges_lazy(x̂_bool, n)
        hubs = get_ring_nodes_lazy(ring, 1)
        x̂′_postopt, ŷ′_postopt = x̂′_bool, ŷ′_bool
        if pars.post_procedure
            x̂′_postopt, ŷ′_postopt = post_optimization_procedure(inst, x̂_bool, ŷ_bool, ring)[1:2]
        end

        if pars.log_level > 0
            if pars.log_level > 1
                println()
                @info "$nsubtour_cons Subtour Constraints created"
            end
            print_ring_nodes(ŷ, n, false)
            print_ring_edges(x̂_bool, inst.c, n)
            print_ring_edges(x̂′_postopt, inst.c′, n, true)
            print_star_edges(ŷ_bool, inst.d, n)
            print_star_edges(ŷ′_postopt, inst.d′, n, true)
        end

        B_computed, i★, j★, k★, = compute_B_critical_triple(inst, x̂_bool, ŷ_bool)
        sol = Solution(n, hubs, x̂_bool, x̂′_postopt, ŷ_bool, ŷ′_postopt, B_computed, i★, j★, k★)


        @show LB, UB
        if pars.timelimit > 20 && pars.assert
            resilient_checker(filename, inst, x̂, x̂′_postopt, ŷ, ŷ′_postopt, gap, B_computed, UB; log_level=0)
        end





        return ILPtable(t_time, 0.0, blossom_time, TL_reached, gap, UB, LB, nsubtour_cons, nconnectivity_cuts, nedges_cuts, 0, nblossom, explored_nodes, sol)
    end
    empty_dict = Dict{Tuple{Int,Int},Bool}()
    sol = Solution(n, Int[1], empty_dict, empty_dict, empty_dict, empty_dict, 0, 0, 0, 0)

    return ILPtable(t_time, 0.0, 0.0, TL_reached, 100, 0, LB, nsubtour_cons, nconnectivity_cuts, nedges_cuts, 0, nblossom, explored_nodes, sol)
end

function ilp_st_optimize_lazy!(m, x, y, x′, y′, f, V, n, r, pars, start_time; log_level=3)

    total_time = start_time
    blossom_time = 0.0

    @objective(m, Min, f(x, y))
    st = MOI.get(m, MOI.TerminationStatus())

    nsubtour_cons::Int = 0 # Number of optimality, feasibility and subtour constraints
    nconnectivity_cuts::Int = 0 # Number of connectivity cuts
    nedges_cuts::Int = 0
    nblossom::Int = 0
    nblossom_pair_inequality::Int = 0


    log_level > 1 && @info "Initial status $st"


    function call_back_ilp_lazy(cb_data)

        status = callback_node_status(cb_data, m)
        if status == MOI.CALLBACK_NODE_STATUS_INTEGER

            ring_edges = create_ring_edges_lazy(callback_value.(cb_data, x), n)
            nsubtour_cons_before = nsubtour_cons
            nsubtour_cons = create_subtour_constraint_lazy_Labbe(m, cb_data, x, y, n, ring_edges, nsubtour_cons)
            if nsubtour_cons_before == nsubtour_cons

                max_violated = 0.0
                max_i = -1
                max_j = -1
                for i in V
                    for j in setdiff(V, i)
                        current_violation = -callback_value(cb_data, y[j, j]) + callback_value(cb_data, x[mima(i, j)]) + callback_value(cb_data, y[i, j])
                        if current_violation > max_violated
                            max_violated = current_violation
                            max_i = i
                            max_j = j
                        end
                    end
                end
                if max_violated > 0
                    con = @build_constraint(y[max_i, max_j] <= y[max_j, max_j] - x[mima(max_i, max_j)])
                    MOI.submit(m, MOI.LazyConstraint(cb_data), con)
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
                if pars.log_level > 1
                    @show con
                    @info "blossom inequality added"
                end
                MOI.submit(m, MOI.UserCut(cb_data), con)
            end
            blossom_time += time() - tmp_time
        end
    end

    MOI.set(m, MOI.UserCutCallback(), call_back_ilp_user_cuts)
    MOI.set(m, MOI.LazyConstraintCallback(), call_back_ilp_lazy)
    optimize!(m)
    total_time = time() - total_time
    ilp_time = round(total_time, digits=3)


    st = MOI.get(m, MOI.TerminationStatus())
    TL_reached = st == MOI.TIME_LIMIT
    if !has_values(m)
        return (m, 0, ilp_time, blossom_time, TL_reached, Inf, objective_bound(m), zeros(Bool, n, n), zeros(Bool, n, n), zeros(Bool, n, n), zeros(Bool, n, n), nsubtour_cons, nconnectivity_cuts, nedges_cuts, nblossom, MOI.get(m, MOI.NodeCount()))
    end


    @info "Spent $(ilp_time)s in ILP"
    @info "Blossom time : $(blossom_time)s"
    @info "Generated $nsubtour_cons subtour constraints"
    @info "Generated $nconnectivity_cuts connectivty cuts"
    @info "Nb blossom, Nb blossom pair : $(nblossom), $(nblossom_pair_inequality)"
    println("Objective : $(objective_value(m))")

    return (m, objective_value(m), ilp_time, blossom_time, TL_reached, relative_gap(m), objective_bound(m), value.(x), value.(x′), value.(y), value.(y′), nsubtour_cons, nconnectivity_cuts, nedges_cuts, nblossom, MOI.get(m, MOI.NodeCount()))
end