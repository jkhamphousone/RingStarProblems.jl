module RRSP

    a = time()
    @info "Loading Revise"
    using Revise
    @info "Loading JuMP"
    using JuMP
    @info "Loading Gurobi"
    using Gurobi
    # @info "Loading Combinatorics, DelimitedFiles, Dates and StatsBase"
    # using Combinatorics, DelimitedFiles, Dates, StatsBase
    @info "Loading Combinatorics, DelimitedFiles, Dates and Random"
    using Combinatorics, DelimitedFiles, Dates, Random
    @info "Loading Distributions, Graphs, GraphsFlows and Plots"
    using Distributions
    using Graphs, GraphsFlows, GraphPlot, Plots
    # using Graphs, GraphPlot, Plots
    @info "Loading Parameters and Formatting"
    using Parameters, Formatting #https://stackoverflow.com/a/58022378/10094437
    @info "Loading Compose, Cairo, Fontconfig and Suppressor"
    using Cairo, Fontconfig, Compose, Suppressor
    using Dualization
    @info "Loading .jl files $(lpad("0%",4))"

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
    @info time()-a



end
