using RingStarProblems
using Test
using JET
using JuMP
using GLPK
using Gurobi

include("aqua.jl")

@testset "RingStarProblems.jl" begin
    # Write your tests here.

    @info JET.report_package(RingStarProblems)




    pars = SolverParameters(
        solve_mod = BranchBendersCut(),     # ILP, or B&BC
        F = 7,                              # total failing time F, see PhD manuscript
        sp_solve = Poly(),
        writeresults = false,               # output results locally, html or no output ""
        o_i = 0,                            # opening costs
        s_ij = Euclidian(),                 # star costs
        r_ij = Euclidian(),                 # ring costs
        backup_factor = 0.01,               # backup_factor c'=0.01c and d'=0.01c
        do_plot = false,                    # plot_results (to debug)
        two_opt = 0,                        # use two_opt heuristic (not functional yet)
        tildeV = 100,                       # uncertain nodes set
        timelimit = 60_000,                 # Solver Time Limit
        log_level = 1,                      # console output log_level
        redirect_stdio = false,             # redirecting_stdio to output file
        use_blossom = false,                # use blossom inequalities (not functional yet)
        alphas = [3],                       # See [Labbé et al., 2004](ttps://doi.org/10.1002/net.10114)
        nthreads = 4,                       # Number of threads used in GUROBI, set 0 for maximum number of available threads
        ucstrat = true,                     # use user cut
    )


    include("solutionchecker.jl")

    @test rspoptimize(
        pars,
        :TinyInstance_10_3,
        optimizer_with_attributes(GLPK.Optimizer, "msg_lev" => 2, "tm_lim" => 15),
        true,
    ) == 0
    @test rspoptimize(
        pars,
        :Instance_15_1_0_3_1,
        optimizer_with_attributes(
            GLPK.Optimizer,
            "msg_lev" => GLPK.GLP_MSG_ALL,
            "tm_lim" => pars.timelimit,
        ),
        true,
    ) == 0
    @test rspoptimize(
        pars,
        :eil51,
        optimizer_with_attributes(
            GLPK.Optimizer,
            "msg_lev" => GLPK.GLP_MSG_ALL,
            "tm_lim" => pars.timelimit,
        ),
        true,
    ) == 0

    pars.F = 0

    @test rspoptimize(
        pars,
        :TinyInstance_12_2,
        optimizer_with_attributes(GLPK.Optimizer, "msg_lev" => 2, "tm_lim" => 10_000),
        true,
    ) == 0
    pars.sp_solve = LP()
    pars.redirect_stdio = true
    pars.nthreads = false
    @test rspoptimize(
        pars,
        :eil51,
        optimizer_with_attributes(GLPK.Optimizer, "msg_lev" => 2, "tm_lim" => 10_000),
        true,
    ) == 0
end
