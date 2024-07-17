import RingStarProblems as RSP
using Test
using JuMP
using GLPK
using Gurobi
@testset "RingStarProblems.jl" begin
	# Write your tests here.
	include("aqua.jl")
	include("solutionchecker.jl")

	pars = RSP.SolverParameters(
		solve_mod = RSP.Both(),             # ILP, B&BC or Both
		sp_solve = RSP.Poly(),
		writeresults = RSP.WHTML(),         # output results locally, html or no output ""
		o_i = 0,                            # opening costs
		s_ij = RSP.Euclidian(),             # star costs
		r_ij = RSP.Euclidian(),             # ring costs
		backup_factor = 0.01,               # backup_factor c'=0.01c and d'=0.01c
		do_plot = false,                    # plot_results (to debug)
		two_opt = 0,                        # use two_opt heuristic (not functional yet)
		tildeV = 100,                       # uncertain nodes set
		timelimit = 60,                     # Gurobi TL
		log_level = 1,                      # console output log_level
		redirect_stdio = false,             # redirecting_stdio to output file
		F = 183,                            # total failing time F, see PhD manuscript
		use_blossom = false,                # use blossom inequalities (not functional yet)
		alphas = [3],                       # See [Labbé et al., 2004](ttps://doi.org/10.1002/net.10114)
		nthreads = 4,                       # Number of threads used in GUROBI, set 0 for maximum number of available threads
		ucstrat = true,                     # use user cut
	)


	@test RSP.rspoptimize(pars, 1; solutionchecker = true, optimizer =
	optimizer_with_attributes(GLPK.Optimizer,
		"msg_lev" => GLPK.GLP_MSG_ALL,
		"tm_lim" => pars.timelimit)
	) == 0
	@test RSP.rspoptimize(pars, 1; solutionchecker = true, optimizer = optimizer_with_attributes(Gurobi.Optimizer,
		"TimeLimit" => pars.timelimit)) == 0
	@test RSP.rspoptimize(pars, 3; solutionchecker = true, optimizer = optimizer_with_attributes(Gurobi.Optimizer,
		"TimeLimit" => pars.timelimit)) == 0
end
