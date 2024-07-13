module RingStarProblems
    if "JULIA_REGISTRYCI_AUTOMERGE" in keys(ENV) && ENV["JULIA_REGISTRYCI_AUTOMERGE"] == "JULIA_REGISTRYCI_AUTOMERGE"

    else
        a = time()
        @info "Loading Revise"
        using Revise
        @info "Loading JuMP"
        using JuMP
        @info "Loading Gurobi"
        using Gurobi
        @info "Loading Combinatorics, DelimitedFiles, Dates and Random"
        using Combinatorics, DelimitedFiles, Dates, Random
        @info "Loading Distributions, Graphs, GraphsFlows and Plots"
        using Distributions
        using Graphs, GraphsFlows, Plots
        @info "Loading Parameters and Formatting"
        using Parameters
        @info "Loading, Cairo, Suppressor and Options"
        using Cairo, Suppressor
        using Dualization
        
        @info "Loading .jl files $(lpad("0%",4))"

        include("instance.jl")
        include("solution.jl")
        include("options.jl")

        include("solution_checker.jl")
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
        include(eval(@__DIR__) * "/plots/plots.jl")
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
end
