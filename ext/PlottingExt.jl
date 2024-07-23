module PlottingExt

using RingStarProblems, Graphs, Colors, GraphPlot, Compose

function RingStarProblems.perform_plot(pars, inst, filename, result_table, is_ilp)
    @info "plotting filename $(filename), α = $(inst.α)"
    n = inst.n

    solving_met = is_ilp ? "ilp" : "benders_$(pars.sp_solve)"

    hubs = result_table.sol.hubs
    @show hubs
    dark = RGBX(0, 0, 0)
    white = RGBX(1, 1, 1)
    darkred = RGBX(0.5, 0.2, 0.2)
    dauphineblue = RGBX(0.19, 0.267, 0.5176)
    teal_backup = RGBX(0, 0.502, 0.502)
    darkorange = RGBX(1, 0.549, 0.0)
    nodefillc = [i == 1 ? dark : darkred for i = 1:n]
    nodelabel_colors = [i == result_table.sol.j★ ? dark : white for i = 1:n]



    inst_graph = SimpleGraph(n)
    nodesize = ones(Float64, n)
    nodelabelsize = ones(Float64, n)


    number_edges = 0
    edge_colors = []


    nodelabels = String[
        i == result_table.sol.j★ ? "$i\n $(round(result_table.sol.B,digits=2))" : "$i"
        for i = 1:n
    ]


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
        filename == :RandomInstance ? "random_instance_$(pars.nrand)_$solving_met" :
        "$(rpad(String(filename),20,"_"))_α-$(inst.α)_$solving_met"

    mkpath(eval(@__DIR__) * "/results/$(alpha_or_nrand)")


    pdfpath =
        eval(@__DIR__) *
        "/results/$alpha_or_nrand/$(alpha_or_nrand)_TL-$(pars.timelimit)$(two_opt_string)_F=$(inst.F)_UB=$(round(result_table.UB))).pdf"
    draw(
        PDF(pdfpath),
        gplot(
            inst_graph,
            inst.x,
            inst.y,
            nodesize = nodesize,
            nodefillc = nodefillc,
            edgestrokec = edge_colors,
            nodelabel = nodelabels,
            nodelabelsize = nodelabelsize,
            nodelabelc = nodelabel_colors,
            EDGELINEWIDTH = 1.1,
            edgelinewidth = 1.1,
        ),
    )

    @info pdfpath
end
end
