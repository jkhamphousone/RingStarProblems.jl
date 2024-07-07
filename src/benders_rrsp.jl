
function rrsp_create_benders_model_lazy(filename, inst, pars)
    """
    - Loads data from file
    - Calls the instance transformation
    - Calls the brute force search algorithms for 3 and 4 hub
    - Creates the master problem.
    """
    println()
    two_opt_string = ""
    if pars.two_opt == 1
        two_opt_string = "with 2-opt"
    elseif pars.two_opt >= 2
        two_opt_string = "with intense 2-opt"
    end
    @info "Benders Solving F=$(pars.F) ---  $(filename)  ---"

    n = inst.n
    V = inst.V
    V′ = 1:n+1
    tildeV = inst.tildeV
    o = inst.o
    d = inst.d
    c = inst.c
    d = inst.d
    start_time = time()

    # o, r, rp, s, bar_offset = instance_transform_improved(inst, pars.inst_trans)



    gurobi_env = Gurobi.Env()
    gurobi_model = Gurobi.Optimizer(gurobi_env)
    m = direct_model(gurobi_model)
    if pars.time_limit > 0
        set_optimizer_attribute(m, "TimeLimit", pars.time_limit)
    end
    set_optimizer_attribute(m, "Threads", pars.nthreads)
    set_optimizer_attribute(m, "OutputFlag", min(pars.log_level, 1))
    
    if pars.uc_strat > 0 || pars.use_blossom
        set_optimizer_attribute(m, "PreCrush", 1)
    end
    pars.log_level == 0 && set_silent(m)


    @variable(m, x[i=V, j=i+1:n+1], Bin)
    @variable(m, y[i=V′, j=V′], Bin)

    time_BSInf = time()
    BSInf = computeBSInf(inst)[1]
    time_BSInf = round(time() - time_BSInf,digits=5)
    @info "Computed BSInf=$BSInf in $(time_BSInf)s" 

    @variable(m, B >= 0)



 
    @constraint(m, number_hubs_1, sum(y[i, i] for i in V) >= 4)


    @constraint(m, degree_constraint_2[i=setdiff(V′, 1, n + 1)], sum(x[mima(i, j)] for j in V′ if i != j) == 2y[i, i])

    @constraint(m, depot_connected_4, sum(x[1, i] for i in setdiff(V, 1)) == 1)
    @constraint(m, depot_connected_5, sum(x[i, n+1] for i in setdiff(V, 1)) == 1)

    @constraint(m, y[1, 1] == 1)    
    @constraint(m, y[n+1, n+1] == 1)
    @constraint(m, [i = setdiff(V′, 1, n + 1)], y[1, i] == 0)

    @constraint(m, hub_or_star_7[i=V], sum(y[i, j] for j in V) == 1)

    @constraint(m, one_edge_or_arc_between_i_and_j_11[i=V, j=setdiff(V, i)], x[mima(i, j)] + y[i, j] <= y[j, j])


    function f(x, y)
        # sum(o[i] * y[i, i] for i in V) + sum(sum(d[i, j] * y[i, j] for j in V if i != j) for i in V) + sum(sum(c[i, j] * x[i, j] for j in V if i < j; init=0) for i in V)
        sum(sum(c[i,j]*x[i,j] for j in V if i < j; init=0) for i in V) + sum(c[1,i]*x[i,n+1] for i in 2:n) + sum(sum(d[i,j]*y[i,j] for j in V if i != j) for i in V) + sum(o[i]*y[i,i] for i in V)
    end
    # function ring_cost(x, y)
    #     bar_offset + sum(sum([r[i,j]*x[i,j] for j in V if i < j]) for i in V) + sum(o[i]*y[i] for i in V)
    # end

    bestsol, bestobjval = three(inst.n, inst.o, inst.c, inst.d, tildeV)
    # bestsol, bestobjval = four(inst.n, inst.o, inst.r, inst.s, tildeV, bestobjval, bestsol)
    # @constraint(m, f(x,y) + pars.F*B <= bestobjval)
    set_optimizer_attribute(m, "Cutoff", bestobjval)
    @info "3 hubs objective:" bestobjval

    if pars.warm_start != ""
        warm_hubs = parse.(Int, split(pars.warm_start, "-")[1:end-1])
        @show warm_hubs
        y_warm = zeros(Bool, n)
        for i in V
            if i in warm_hubs
                set_start_value(y[i], true)
                y_warm[i] = true
            else
                set_start_value(y[i], false)
            end
        end
        x_warm = zeros(Bool, n, n)
        x′_warm = zeros(Bool, n, n)
        for i in V
            for j in i+1:n
                set_start_value(x[i, j], false)
            end
        end
        for i in 1:length(warm_hubs)-1
            set_start_value(x[mima(warm_hubs[i], warm_hubs[i+1])...], true)
            x_warm[mima(warm_hubs[i], warm_hubs[i+1])...] = true
        end
        for i in 2:length(warm_hubs)-1
            if warm_hubs[i] in tildeV
                x′_warm[mima(warm_hubs[i-1], warm_hubs[i+1])...] = true
            end
        end
        if warm_hubs[end] in tildeV
            x′_warm[mima(warm_hubs[end-1], 1)...] = true
        end
        set_start_value(x[1, warm_hubs[end]], true)
        x_warm[1, warm_hubs[end]] = true
        set_start_value(λ, 0)
        set_start_value(offset, bar_offset)

    end




    m, t_time, m_time, s_time, blossom_time, t_two_opt_time, TL_reached, gap, UB, LB, x̂, ŷ, nopt_cons, nsubtour_cons, nconnectivity_cuts, ntwo_opt, nblossom, explored_nodes = benders_st_optimize_lazy!(m, x, y, f, inst.F, B, inst, pars, start_time, gurobi_env)



    if has_values(m)

        x̂_bool = Dict{Tuple{Int,Int},Bool}()
        x̂′_bool = Dict{Tuple{Int,Int},Bool}()
        ŷ_bool = Dict{Tuple{Int,Int},Bool}()
        ŷ′_bool = Dict{Tuple{Int,Int},Bool}()


        for i in 1:n
            for j in 1:n+1
                if j > i
                    x̂_bool[i, j] = x̂[i, j] > 0.5
                end
                if j < n + 1
                    ŷ_bool[i, j] = ŷ[i, j] > 0.5
                end
            end
        end

        x̂′_bool, ŷ′_bool = sp_optimize_ilp_primal(x̂_bool, ŷ_bool, inst, pars.log_level, gurobi_env)[2:3]



        ring = create_ring_edges_lazy(x̂_bool, n)
        @show ring
        hubs = get_ring_nodes_lazy(ring, 1)
        @show hubs
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


        if pars.time_limit > 20 && pars.assert
            resilient_checker(filename, inst, x̂, x̂′_postopt, ŷ, ŷ′_postopt, gap, B_computed, UB; log_level=pars.log_level)
        end

        sp_cost = B_computed * inst.F
        master_cost = UB - sp_cost
        return BDtable( t_time, 
                        m_time, 
                        s_time, 
                        t_two_opt_time, 
                        blossom_time, 
                        TL_reached, 
                        gap, 
                        UB, LB, 
                        nopt_cons, nsubtour_cons, nconnectivity_cuts, nblossom, ntwo_opt, 
                        master_cost, sp_cost, 
                        explored_nodes, 
                        sol)
    end
    empty_dict = Dict{Tuple{Int,Int},Bool}() 
    sol = Solution(n, Int[1], empty_dict, empty_dict, empty_dict, empty_dict, 0, 0, 0, 0)

    return BDtable(t_time, m_time, s_time, t_two_opt_time, blossom_time, TL_reached, 100, 0, LB, nopt_cons, nsubtour_cons, nconnectivity_cuts, nblossom, ntwo_opt, 0, 0, 0, sol)
end
function benders_st_optimize_lazy!(m, x, y, f, F, B, inst, pars, start_time, gurobi_env)

    @objective(m, Min, f(x, y) + F * B)

    d′ = inst.d′
    d = inst.d
    c′ = inst.c′
    V = inst.V
    n = length(V)
    V′ = 1:n+1
    tildeV = inst.tildeV
    log_level = pars.log_level

    # subtourlazy_cons = ScalarConstraint{AffExpr, MathOptInterface.GreaterThan{Float64}}
    # []

    nopt_cons = 0
    nsubtour_cons = 0
    nconnectivity_cuts = 0
    nblossom = 0
    nblossom_pair_inequality = 0

    total_time, sp_time, sp_obj, t_two_opt_time, blossom_time = start_time, 0.0, 0.0, 0.0, 0.0

    x̂ = Dict{Tuple{Int,Int},Bool}()
    ŷ = Dict{Tuple{Int,Int},Bool}()
    # best_feasible_obj = Inf
    ntwo_opt = 0
    ε = 10e-15

    improve_two_opt = false

    # x_improve_two_opt = zeros(Float64, n, n)
    # y_improve_two_opt = zeros(Float64, n)
    # λ_improve_two_opt = .0
    # bar_offset_improve_two_opt = .0

    gurobi_model = Gurobi.Optimizer(gurobi_env)
    sp_m = direct_model(gurobi_model)
    set_optimizer_attribute(sp_m, "OutputFlag", 0)
    first_sp_m = true

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


            nsubtour_cons_before = nsubtour_cons
            ring_edges = create_ring_edges_lazy(callback_value.(cb_data, x), n)
            nsubtour_cons = create_subtour_constraint_lazy_Labbe(m, cb_data, x, y, n, ring_edges, nsubtour_cons)
            if nsubtour_cons == nsubtour_cons_before
                B_cb = callback_value(cb_data, B) * inst.F
                start_time_sp = time()
                if pars.sp_solve == "poly"
                    B_val, α, β, γ, δ, ζ = sp_optimize_poly(x̂, ŷ, inst)
                    B_val *= inst.F

                else
                    B_val, α, β, γ, δ, ζ, sp_m, first_sp_m = sp_optimize_ilp_dual(x̂, ŷ, inst, pars.log_level, sp_m, first_sp_m)
                end

                sp_time += time() - start_time_sp


                if pars.two_opt == 2
                    two_opt_time = time()


                    x′, sp_cost = compute_sp_res(x̂, ŷ, V, n, tildeV, rp, s)[[1, 3]] # TODO create simpler functions that do only compute backup ring cost and ring cost
                    hubs, master_ring_cost = compute_master_hubs_and_cost(x̂, V, n, tildeV, o, r)
                    x_two_opt, x′_two_opt, two_opt_cost = run_two_opt_wiki(x̂, x′, hubs, sp_cost + master_ring_cost + bar_offset, pars, n, r, rp, tildeV)


                    B_two_opt = two_opt_cost - ring_cost(x_two_opt, ŷ)
                    t_two_opt_time += time() - two_opt_time


                    if two_opt_cost < min(bestobjval, sp_cost + master_ring_cost + bar_offset)

                        pars.log_level > 1 && print("Feasible solution found of value $(two_opt_cost)")
                        improve_two_opt = true
                        for i in V
                            for j in i+1:n
                                x_improve_two_opt[i, j] = Float64(round(x_two_opt[i, j]))
                            end
                        end
                        y_improve_two_opt = Float64.(round.(ŷ))
                        bar_offset_improve_two_opt = bar_offset
                        B_improve_two_opt = B_two_opt

                    end
                end
                
                if B_cb < B_val

                    B_computed, i★, j★, k★ = compute_B_critical_triple(inst, x̂, ŷ)
                    tildeJ = Set([(i, j, k) for i in V, j in tildeV, k in V′ if i != j && j != k && i < k])

                    if pars.sp_solve == "LP"

                        con = @build_constraint(inst.F * B >=
                                                sum((1 - y[i, i] - sum(y[i, j] for j in setdiff(V, tildeV, i); init=0))α[i] for i in V) +
                                                sum((x[mima(i, j)] + x[mima(j, k)] - 1)β[i, j, k] for (i, j, k) in tildeJ) +
                                                sum((sum(d′[i, k] * (y[i, j] - 1) for k in setdiff(V, i, j)))γ[i, j] for i in V for j in tildeV if i != j) +
                                                sum(c′[i, k] * (x[mima(i, j)] + x[mima(j, k)] - 2)δ[i, j, k] for (i, j, k) in tildeJ) +
                                                sum((x[mima(i, j)] + y[i, j] - y[j, j])ζ[i, j] for i in V for j in V if i != j)
                        )


                        MOI.submit(m, MOI.LazyConstraint(cb_data), con)
                    else
                        con = @build_constraint(B >=
                                                sum((1 - y[i, i] + x[mima(i, j★)] + y[i, j★] - y[j★, j★] - sum(y[i, j] for j in setdiff(V, tildeV, i))) * minimum(d′[i, k] for k in setdiff(V, i, j★) if ŷ[k, k]) for i in setdiff(V, j★) if ŷ[i, j★]; init=0) +
                                                (2x[mima(i★, j★)] + 2x[mima(j★, k★)] - 3) * c′[i★, k★] +
                                                sum(sum(d′[i, k] * (y[i, j★] - 1) for k in setdiff(V, i, j★); init=0) for i in setdiff(V, j★) if ŷ[i, j★]; init=0) +
                                                sum(sum(minimum((d′[i, k] for k in setdiff(V, i, j★) if ŷ[k, k]; init=0) - d′[i, j])*(x[mima(i,j)] + y[i,j] - y[j,j]) for j in setdiff(V, i) if !ŷ[j, j] && minimum(d′[i, k] for k in setdiff(V, i, j★) if ŷ[k, k]; init=0) > d′[i, j]; init=0) for i in setdiff(V, j★) if ŷ[i, j★]; init=0)
                        )

                        MOI.submit(m, MOI.LazyConstraint(cb_data), con)
                    end
                    nopt_cons += 1
                else
                    if pars.two_opt == 1
                        two_opt_time = time()


                        x′, sp_cost = compute_sp_res(x̂, ŷ, V, n, tildeV, rp, s)[[1, 3]] # TODO create simpler functions that do only compute backup ring cost and ring cost
                        hubs, master_ring_cost = compute_master_hubs_and_cost(x̂, V, n, tildeV, o, r)
                        x_two_opt, x′_two_opt, two_opt_cost = run_two_opt_wiki(x̂, x′, hubs, sp_cost + master_ring_cost + bar_offset, pars, n, r, rp, tildeV)


                        λ_two_opt = two_opt_cost - ring_cost(x_two_opt, ŷ)


                        if two_opt_cost < min(bestobjval, sp_cost + master_ring_cost + bar_offset)
                            # We accept two-opt solution
                            println("Feasible solution found of value $(two_opt_cost)")
                            improve_two_opt = true
                            for i in V
                                for j in i+1:n
                                    x_improve_two_opt[i, j] = Float64(round(x_two_opt[i, j]))
                                end
                            end
                            y_improve_two_opt = Float64.(round.(ŷ))
                            bar_offset_improve_two_opt = bar_offset
                            λ_improve_two_opt = λ_two_opt
                            pars.log_level > 1 && @info "New heuristic solution found with value $two_opt_cost"
                        end
                        t_two_opt_time += time() - two_opt_time
                    end
                end
            end
        end
    end


    function call_back_benders_heuristic(cb_data)
        if improve_two_opt
            ntwo_opt += 1
            two_opt_time = time()
            vars_submit = JuMP.VariableRef[]
            vars_improve_two_opt_submit = Bool[]
            for i in V
                for j in i+1:n
                    push!(vars_submit, x[i, j])
                    push!(vars_improve_two_opt_submit, x_improve_two_opt[i, j])
                end
            end
            for i in V
                push!(vars_submit, y[i])
                push!(vars_improve_two_opt_submit, y_improve_two_opt[i])
            end



            status = MOI.submit(
                m, MOI.HeuristicSolution(cb_data), vcat(vars_submit, offset, λ), vcat(vars_improve_two_opt_submit, bar_offset_improve_two_opt, λ_improve_two_opt))

            pars.log_level > 1 && println("Submitted a heuristic solution with status $status")
            improve_two_opt = false
            t_two_opt_time += time() - two_opt_time
        end
    end



    function call_back_user_cuts(cb_data)
        max_current_value = -Inf
        if pars.uc_strat == 1
            max_current_value, con = create_connectivity_cut_strategy_1(cb_data, x, y, V, n, pars)
        elseif pars.uc_strat == 2
            max_current_value, con = create_connectivity_cut_strategy_2(cb_data, x, JuMP.VariableRef[y[i, i] for i in V], V, n, pars)
        elseif pars.uc_strat == 3
            max_current_value, con = create_connectivity_cut_strategy_3(cb_data, x, JuMP.VariableRef[y[i, i] for i in V], V, n, pars)
        elseif pars.uc_strat == 4
            max_current_value, con = create_connectivity_cut_strategy_4(cb_data, x, y, V, n, nconnectivity_cuts, pars)
        end
        if max_current_value > pars.uc_tolerance
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



    MOI.set(m, MOI.LazyConstraintCallback(), call_back_benders_lazy)
    MOI.set(m, MOI.HeuristicCallback(), call_back_benders_heuristic)
    MOI.set(m, MOI.UserCutCallback(), call_back_user_cuts)


    optimize!(m)

    total_time = time() - total_time



    pars.log_level > 0 && @info "ended"

    

    t_time = round(total_time, digits=4)
    m_time = round(total_time - sp_time, digits=4)
    s_time = round(sp_time, digits=4)
    @info "Spent $(t_time)s in Benders decomposition\nSpent $(m_time)s in Master problem\nSpent $(s_time)s in subproblem\n$nopt_cons Optimality Constraints created\n$nsubtour_cons Subtour Constraints created"


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
    return (m, t_time, m_time, s_time, t_two_opt_time, blossom_time, TL_reached, relative_gap(m), objective_value(m), objective_bound(m), value.(x), Bool.(round.(value.(y))), nopt_cons, nsubtour_cons, nconnectivity_cuts, ntwo_opt, nblossom, MOI.get(m, MOI.NodeCount()))
end



function compute_sp_res(x̂, ŷ, V, n, tildeV, r, s)
    """
    r here is a backup cost. Ask yourself if you call with it "rp"?
    Solves the subproblem from an integer solution of the master problem.
    It returns the y_ij (star arcs), the x' (backup edges) and sp_cost, which is the total backup cost + star cost.
    """
    x′ = zeros(Bool, n, n)
    y_sp = zeros(Bool, n, n)
    sp_cost = 0.0
    nb_hubs = sum(ŷ .> 0.5)
    for i in V
        if ŷ[i] < 0.5
            costcertain = Inf
            costuncertain = [Inf, Inf]
            best_star_cost = Inf
            certain_j = -1
            uncertain_j = [-1, -1]
            best_j = Int[]
            for j in V
                if i != j && ŷ[j] > 0.5
                    if !(j in tildeV) && s[i, j] < costcertain
                        costcertain = s[i, j]
                        certain_j = j
                    elseif j in tildeV
                        if s[i, j] < costuncertain[1]
                            costuncertain[2] = costuncertain[1]
                            costuncertain[1] = s[i, j]
                            uncertain_j[2] = uncertain_j[1]
                            uncertain_j[1] = j
                        elseif s[i, j] < costuncertain[2]
                            costuncertain[2] = s[i, j]
                            uncertain_j[2] = j
                        end
                    end
                end
                if sum(costuncertain) < best_star_cost && sum(costuncertain) < costcertain
                    best_j = [uncertain_j[1], uncertain_j[2]]
                    best_star_cost = sum(costuncertain)
                end
                if costcertain < best_star_cost && costcertain < sum(costuncertain)
                    best_j = [certain_j]
                    best_star_cost = costcertain
                end
            end
            for j in best_j
                y_sp[i, j] = true
            end
            sp_cost += best_star_cost
        else
            y_sp[i, i] = true
            if i in tildeV
                if nb_hubs > 4
                    neighboors = Int[]
                    for j in 1:i-1
                        if x̂[j, i] > 0.5
                            push!(neighboors, j)
                        end
                    end
                    for j in i+1:n
                        if x̂[i, j] > 0.5
                            push!(neighboors, j)
                        end
                    end
                    @assert length(neighboors) == 2
                    if neighboors[2] < neighboors[1]
                        neighboors[1], neighboors[2] = neighboors[2], neighboors[1]
                    end
                    sp_cost += r[neighboors[1], neighboors[2]]
                    x′[neighboors[1], neighboors[2]] = true
                end
            end
        end
    end
    if nb_hubs == 4
        H = findall(x -> x > 0.5, [ŷ[i] for i in V])
        counted = Tuple{Int,Int}[]
        for i in H
            neighboors = Int[]
            if i in tildeV
                for j in 1:i-1
                    if x̂[j, i] > 0.5
                        push!(neighboors, j)
                    end
                end
                for j in i+1:n
                    if x̂[i, j] > 0.5
                        push!(neighboors, j)
                    end
                end

                @assert length(neighboors) == 2
                if neighboors[2] < neighboors[1]
                    neighboors[1], neighboors[2] = neighboors[2], neighboors[1]
                end
                if !((neighboors[1], neighboors[2]) in counted)
                    sp_cost += r[neighboors[1], neighboors[2]]
                    x′[neighboors[1], neighboors[2]] = true
                    push!(counted, (neighboors[1], neighboors[2]))
                end
            end
        end
    end

    return x′, y_sp, sp_cost
end

function compute_master_hubs_and_cost(x_opt, V, n, tildeV, o, r)
    # TODO supprimer tildeV
    master_cost = 0.0
    H = Int[]
    for i in V
        for j in i+1:n
            if x_opt[i, j] > 0.5
                if !(i in H)
                    push!(H, i)
                    master_cost += o[i]
                end
                if !(j in H)
                    push!(H, j)
                    master_cost += o[j]
                end
                master_cost += r[i, j]
            end
        end
    end
    return H, master_cost
end


