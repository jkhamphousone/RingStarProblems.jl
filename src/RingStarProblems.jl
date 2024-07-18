module RingStarProblems


    a = time()

    @info "Loading JuMP"
    using JuMP
    @info "Loading Combinatorics, DelimitedFiles, Dates and Random"
    using Combinatorics, DelimitedFiles, Dates, Random
    @info "Loading Distributions, Graphs, GraphsFlows"
    using Distributions
    using Graphs, GraphsFlows
    @info "Loading Parameters and Formatting"
    using Parameters
    @info "Loading, Cairo, Suppressor and Options"
    using Cairo, Suppressor
    using Dualization

    @info "Loading .jl files $(lpad("0%",4))"

    include("options.jl")
    include("instance.jl")
    include("solution.jl")

    export SolveMod, Both, BranchBendersCut, ILP, USolveMod
    export SPSolve,
        NoOptimize, gF, gFexploreonlyILP, gFexploreonlyben, USolveMod, Poly, LP, USPSolve
    export WResults, WHTML, WLocal, UWriteResults
    export Costs, Euclidian, RandomInterval, UCosts
    export rspoptimize, SolverParameters
    @info "Loading .jl files $(lpad("25%",4))"
    include("create_subtour_constraint.jl")
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
    # TODO: make functional include("./plots/plots.jl")
    include("local_searches.jl")
    include("explore_F.jl")
    include("main.jl")
    include("post_optimization.jl")
    include("read.jl")

    include("create_blossom_ineaqulities.jl")
    include("../test/solutionchecker.jl")


    @info "Loading .jl files $(lpad("100%",4))"
    @info "Took $(round(time()-a, digits=1))s to load RingStarProblems.jl"

    # # Make the repostiroy writeable in order to output results to subfolder ./src/results
    # chmod(eval(@__DIR__), 0760; recursive=true)


end
