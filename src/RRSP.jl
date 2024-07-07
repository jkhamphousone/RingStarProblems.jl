module RRSP

    a = time()
    @info "Loading Revise"
    using Revise
    using Aqua
    using JET
    using JuMP
    using Gurobi
    using MathOptInterface
    
    using Combinatorics, DelimitedFiles, Dates, Random
    @info "Loading packages... [2/3]"
    using Distributions
    using Graphs, GraphsFlows, GraphPlot, Plots
    
    using Parameters #https://stackoverflow.com/a/58022378/10094437
    using Cairo, Suppressor, Compose, Profile
    @info "Loading packages... [3/3] DONE"
    @info "Loading .jl files $(lpad("0%",4))"
    
    
    
    include("instance.jl")
    include("solution.jl")
    include("with_kw_mutable_structures.jl")
    include("solution_checker.jl")
    @info "Loading .jl files $(lpad("25%",4))"
    include("create_subtour_constraint.jl")
    include("ilp_rrsp.jl")
    include("benders_rrsp.jl")
    include("benders_subproblem_poly.jl")
    include("benders_subproblem_ilp_primal.jl")
    @info "Loading .jl files $(lpad("50%",4))"
    include("benders_subproblem_ilp_dual.jl")
    include("print.jl")
    include("three_four_rho_rsp.jl")
    include("utilities.jl")
    include("./plots/plots.jl")
    @info "Loading .jl files $(lpad("75%",4))"
    include("local_searches.jl")
    include("explore_F.jl")
    include("explore_F_ilp.jl")
    include("explore_F_bbc_subtours.jl")
    include("main.jl")
    include("post_optimization.jl")
    include("../debug/debug.jl")
    include("create_blossom_ineaqulities.jl")
    @info "Loading .jl files $(lpad("100%",4))"
    @info "took $(round(time() - a,digits=1))s to load packages and .jl files"
    include("instance.jl")
    include("solution.jl")
    include("with_kw_mutable_structures.jl")
    include("solution_checker.jl")
    @info "Loading .jl files $(lpad("25%",4))"
    include("create_subtour_constraint.jl")
    # include("ilp_rho_rsp_st_chains.jl")
    include("ilp_rrsp.jl")
    include("benders_rrsp.jl")
    include("benders_subproblem_poly.jl")
    @info "Loading .jl files $(lpad("50%",4))"
    include("benders_subproblem_ilp_primal.jl")
    include("benders_subproblem_ilp_dual.jl")
    include("print.jl")
    include("three_four_rho_rsp.jl")
    @info "Loading .jl files $(lpad("75%",4))"
    include("utilities.jl")
    # include("rho_rsp_lb.jl")
    include("./plots/plots.jl")
    include("local_searches.jl")
    include("explore_F.jl")
    include("main.jl")
    include("post_optimization.jl")
    include("read.jl")
    include("../debug/debug.jl")
    include("create_blossom_ineaqulities.jl")

    @info "Loading .jl files $(lpad("100%",4))"
    export MainPar, main, t
    @info time()-a

    # pars = MainPar(solve_mod="Both", alphas=[parse(Int, ARGS[2])], time_limit=60*60, write_res="html", log_level=1, plot_run=true, html_usernotes=ARGS[3])
    # main(pars, parse(Int, ARGS[1]))
    # exit()

end
