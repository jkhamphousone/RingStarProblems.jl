using RingStarProblems
using Test
using JET
using JuMP
using GLPK
using GraphPlot, Compose, Colors

include("aqua.jl")

@testset "RingStarProblems.jl" begin
	# Write your tests here.

	@info JET.report_package(RingStarProblems)




	pars = SolverParameters(
		solve_mod = BranchBendersCut(),     # ILP, or BranchBendersCut
		F = 7,                              # total failing time F in days per year, see [`PhD manuscript`](https://theses.hal.science/tel-04319443)
		sp_solve = Poly(),
		o_i = 0,                            # opening costs
		s_ij = Euclidian(),                 # star costs
		r_ij = Euclidian(),                 # ring costs
		alpha = 3,                          # See [Labbé et al., 2004](ttps://doi.org/10.1002/net.10114)
		backup_factor = 0.01,               # backup_factor c'=0.01c and d'=0.01c
		writeresults = false,               # output results locally, html or no output ""
		plotting = false,                   # plot_results (to debug)
		tildeV = 100,                       # uncertain nodes set
		log_level = 1,                      # console output log_level
		redirect_stdio = false,             # redirecting_stdio to output file
		use_blossom = false,                # use blossom inequalities (not functional yet)
		ucstrat = true,                     # use user cut
	)


	include("solutionchecker.jl")

	@test rspoptimize(
		pars,
		:TinyInstance_10_3,
		optimizer_with_attributes(GLPK.Optimizer, "msg_lev" => 2),
		true,
	) == 0
	@test rspoptimize(
		pars,
		:Instance_15_1_0_3_1,
		optimizer_with_attributes(GLPK.Optimizer, "msg_lev" => 2), 
        true,
	) == 0
	@test rspoptimize(
		pars,
		:eil51,
		optimizer_with_attributes(GLPK.Optimizer, "msg_lev" => 2, "tm_lim" => 20_000),
		true,
	) == 0

	pars.F = 0
	pars.plotting = true

	@test rspoptimize(
		pars,
		:TinyInstance_12_2, 
        optimizer_with_attributes(GLPK.Optimizer, "msg_lev" => 2),
		true,
	) == 0
	pars.sp_solve = LP()
	pars.redirect_stdio = true
	@test rspoptimize(
		pars,
		:eil51, 
        optimizer_with_attributes(GLPK.Optimizer, "msg_lev" => 2, "tm_lim" => 15_000),
		true,
	) == 0
end
