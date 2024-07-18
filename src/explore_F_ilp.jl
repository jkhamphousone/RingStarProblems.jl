function ilp_st_optimize_explore!(
    m,
    x,
    y,
    x′,
    y′,
    f,
    F,
    B,
    inst,
    pars,
    start_time,
    gurobi_env,
    subtourlazy_cons,
    nsubtour_cons,
    ncall_bbc;
    log_level = 3,
)

    V = inst.V
    n = inst.n
    V′ = 1:n+1
    total_time = start_time
    blossom_time = 0.0

    @objective(m, Min, f(x, y) + F * B)
    st = MOI.get(m, MOI.TerminationStatus())

    nconnectivity_cuts::Int = 0 # Number of connectivity cuts
    nedges_cuts::Int = 0
    nblossom::Int = 0
    nblossom_pair_inequality::Int = 0


    log_level > 1 && @info "Initial status $st"


    grb = JuMP.backend(m)
    info_nlazycons = 0
    if pars.gFreuse_lazycons
        info_nlazycons = nsubtour_cons[1] - nsubtour_cons[2]
        @info "Adding $info_nlazycons lazy constraints from previous ILP solve. Total number of generated lazy constraints so far: $(length(subtourlazy_cons))"
        for i = nsubtour_cons[2]+1:nsubtour_cons[1]
            nsubtour_cons[2] += 1
            con = @constraint(m, subtourlazy_cons[i][1] >= subtourlazy_cons[i][2])
            set_attribute(grb, Gurobi.ConstraintAttribute("Lazy"), index(con), 1)
        end
        info_nlazycons = length(subtourlazy_cons)
    end
    x̂ = Dict{Tuple{Int,Int},Bool}()
    ŷ = Dict{Tuple{Int,Int},Bool}()

    function call_back_ilp_lazy(cb_data)

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
            nsubtour_cons = createsubtour_constraintexplore!(
                m,
                subtourlazy_cons,
                cb_data,
                x,
                y,
                n,
                ring_edges,
                nsubtour_cons,
            )
            if nsubtour_cons[1] == nsubtour_cons_before &&
               pars.ilpseparatingcons_method[1] ==
               "seperate y_ij <= y_jj - x_ij on lazy constraints"

                max_violated = 0.0
                max_i = -1
                max_j = -1
                for i in V
                    for j in setdiff(V, i)
                        current_violation =
                            -callback_value(cb_data, y[j, j]) +
                            callback_value(cb_data, x[mima(i, j)]) +
                            callback_value(cb_data, y[i, j])
                        if current_violation > max_violated
                            max_violated = current_violation
                            max_i = i
                            max_j = j
                        end
                    end
                end
                if max_violated > 0
                    con = @build_constraint(
                        y[max_i, max_j] <= y[max_j, max_j] - x[mima(max_i, max_j)]
                    )
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
        if pars.ucstrat
            max_current_value, con = createconnectivitycut(
                cb_data,
                x,
                y,
                V,
                n,
                nconnectivity_cuts,
                pars,
            )
        end
        if max_current_value > pars.uctolerance
            MOI.submit(m, MOI.UserCut(cb_data), con)
            nconnectivity_cuts += 1
        elseif pars.use_blossom
            tmp_time = time()
            con, nblossom_pair_inequality =
                create_blossom_inequalities(cb_data, x, y, n, nblossom_pair_inequality)
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

    set_attribute(m, MOI.UserCutCallback(), call_back_ilp_user_cuts)
    set_attribute(m, MOI.LazyConstraintCallback(), call_back_ilp_lazy)
    optimize!(m)
    total_time = time() - total_time
    ilp_time = round(total_time, digits = 3)

    nodecount = -1
    try
        nodecount = MOI.get(m, MOI.NodeCount())
    catch e
        @info "Getting Node Count is not supported by GLPK"
    end
    st = MOI.get(m, MOI.TerminationStatus())
    TL_reached = st == MOI.TIME_LIMIT
    if !has_values(m)
        return (
            m,
            0,
            ilp_time,
            blossom_time,
            TL_reached,
            Inf,
            objective_bound(m),
            zeros(Bool, n, n),
            zeros(Bool, n, n),
            zeros(Bool, n, n),
            zeros(Bool, n, n),
            nsubtour_cons,
            nconnectivity_cuts,
            nedges_cuts,
            nblossom,
            nodecount,
        )
    end


    @info "Spent $(ilp_time)s in ILP"
    @info "Blossom time : $(blossom_time)s"
    @info "Generated $nsubtour_cons subtour constraints"
    @info "Generated $nconnectivity_cuts connectivty cuts"
    @info "Nb blossom, Nb blossom pair : $(nblossom), $(nblossom_pair_inequality)"
    println("Objective : $(objective_value(m))")
    return (
        m,
        ilp_time,
        blossom_time,
        TL_reached,
        relative_gap(m),
        objective_value(m),
        objective_bound(m),
        value.(x),
        value.(y),
        nsubtour_cons,
        nconnectivity_cuts,
        nedges_cuts,
        nblossom,
        MOI.get(m, MOI.NodeCount()),
    )
end
