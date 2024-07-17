function optimize_plot_gap(do_plot_gap, m, time_step, timelimit)
    if do_plot_gap
        set_optimizer_attribute(m, "TimeLimit", time_step)
        gap_history = Float64[]
        start_time = time()
        solving_time = 0
        times_arr = Float64[]
        while solving_time < timelimit
            optimize!(m)
            solving_time = time() - start_time
            gap = MOI.get(m, MOI.RelativeGap())
            status = termination_status(m)
            push!(gap_history, gap)
            push!(times_arr, solving_time)
            gap > 0.01 || status == MOI.TIME_LIMIT || break
        end

        plt = plot(times_arr, gap_history)
        gui(plt)
    else
        optimize!(m)
    end
end


function plot_results_plan_run(
    pars,
    inst,
    filename,
    result_table,
    is_ilp,
    plot_backup_edge = false,
)
    @info "plotting filename $(filename[1]), α = $(inst.α)"
    n = inst.n

    solving_met = is_ilp ? "ilp" : "benders_$(pars.sp_solve)"

    hubs = result_table.sol.hubs
    @show hubs
    darkred = plot_backup_edge ? RGBX(0.5, 0.2, 0.2) : RGBX(0.8, 0, 0)
    dark = RGBX(0, 0, 0)
    dauphineblue = RGBX(0.19, 0.267, 0.5176)
    teal_backup = RGBX(0, 0.502, 0.502)
    darkorange = RGBX(1, 0.549, 0.0)
    nodefillc = [i == 1 ? dark : darkred for i = 1:n]
    nodelabel_colors = [i == result_table.sol.j★ ? dark : colorant"white" for i = 1:n]



    inst_graph = SimpleGraph(n)
    nodesize = ones(Float64, n)
    nodelabelsize = ones(Float64, n)


    number_edges = 0
    edge_colors = []


    nodelabels =
        String[i == result_table.sol.j★ ? "$i\n $(result_table.sol.B)" : "$i" for i = 1:n]


    for i = 1:n
        for j = i+1:n
            if result_table.sol.x_opt[i, j]
                add_edge!(inst_graph, i, j)
                push!(edge_colors, dauphineblue)
                number_edges += 1
                nodefillc[i] = dauphineblue
                nodesize[i] = 1.1
                nodefillc[j] = dauphineblue
                nodesize[j] = 1.1
            elseif i == 1 && result_table.sol.x_opt[j, n+1]
                @show i
                add_edge!(inst_graph, 1, j)
                push!(edge_colors, dauphineblue)
                number_edges += 1
            end
            if result_table.sol.y_opt[i, j] || result_table.sol.y_opt[j, i]
                add_edge!(inst_graph, i, j)
                push!(edge_colors, darkred)
                number_edges += 1
            end
            if result_table.sol.y′_opt[i, j] || result_table.sol.y′_opt[j, i]
                add_edge!(inst_graph, i, j)
                push!(edge_colors, teal_backup)
                number_edges += 1
            end
        end
    end

    nodefillc[result_table.sol.j★] = darkorange


    nodesize[1] = 1.1
    nodefillc[1] = dark
    two_opt_string = ""
    if pars.two_opt == 1
        two_opt_string = "_2-opt"
    elseif pars.two_opt == 2
        two_opt_string = "_intense_2-opt"
    end
    alpha_or_nrand =
        filename[1] == "random_instance" ? "random_instance_$(pars.nrand)_$solving_met" :
        "$(rpad(filename[1],20,"_"))_α-$(inst.α)_$solving_met"
    mkpath(eval(@__DIR__) * "/results/html/plots/journal_2023/$(alpha_or_nrand)")
    draw(
        PDF(
            eval(@__DIR__) *
            "/Results/html/plots/journal_2023/$alpha_or_nrand/$(alpha_or_nrand)_$(rpad(plot_backup_edge ? "backup-ring" : "ring_",5,"_"))TL-$(pars.timelimit)$(two_opt_string)_F=$(inst.F)_UB=$(round(result_table.UB))$(pars.ilpseparatingcons_method[2] == "" ? "" : "___$(pars.ilpseparatingcons_method[2])__").pdf",
        ),
        gplot(
            inst_graph,
            inst.x,
            inst.y,
            nodesize = nodesize,
            nodefillc = nodefillc,
            edgestrokec = edge_colors,
            nodelabel = nodelabels,
            nodelabelsize = nodesize,
            nodelabelc = nodelabel_colors,
            EDGELINEWIDTH = 1.1,
            edgelinewidth = 1.1,
        ),
    )

end
