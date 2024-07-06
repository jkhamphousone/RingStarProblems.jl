a = time()

@info "Loading packages... [1/3]"

using JuMP
using Gurobi
using MathOptInterface

using Combinatorics, DelimitedFiles, Dates, Random
@info "Loading packages... [2/3]"
using Distributions
using Graphs, GraphsFlows, GraphPlot, Plots

using Parameters #https://stackoverflow.com/a/58022378/10094437
using Cairo, Suppressor, Compose, Fontconfig, Profile
@info "Loading packages... [3/3] DONE"
@info "Loading .jl files $(lpad("0%",4))"



include("instance.jl")
include("solution.jl")
include("with_kw_mutable_structures.jl")
include("solution_checker.jl")
@info "Loading .jl files $(lpad("25%",4))"
include("create_subtour_constraint.jl")
include("ilp_rrsp.jl")
# include("ilp_rho_rsp_st_chains.jl")
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

export MainPar, main, t



solve_m = parse(Int64, ARGS[1]) == 1 ? "ILP" : "Ben"


pars = MainPar(solve_mod="g(F)exploreonly$solve_m",
               write_res="html", 
               o_i="0", 
               s_ij="", 
               r_ij="", 
               backup_factor=0.01, 
               do_plot=true, 
               two_opt=0, 
               tildeV=100, 
               time_limit=86400, 
               log_level=1, 
               sp_solve="poly", 
               redirect_stdio=false, 
               F=183, 
               html_user_notes=("seperate y_ij <= y_jj - x_ij on lazy constraints", "seperate y_ij <= y_jj - x_ij on lazy constraints"), 
               use_blossom=false, 
               alphas=[parse(Int64, ARGS[3])], 
               nthreads=4,
               uc_strat=4)

main(pars, parse(Int64, ARGS[2]))
exit()
