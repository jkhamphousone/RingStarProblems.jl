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

# pars = MainPar(solve_mod="ILP", plot_run=true, write_res = "html",  n_rand = 80, o_i = "1:1000", s_ij="l_ij", r_ij="l_ij", nb_run_rand=(parse(Int, ARGS[1]),parse(Int, ARGS[1])), two_opt=2)
# pars = MainPar(solve_mod="Benders", write_res = "local",  n_rand = parse(Int, ARGS[1]), o_i = "1:1000", s_ij="l_ij", r_ij="l_ij", nb_run_rand=(parse(Int, ARGS[2]),parse(Int, ARGS[2])), two_opt=0)
# pars = MainPar(solve_mod="Ben", write_res="local", o_i="0", s_ij="", r_ij="", backup_factor=0.01, do_plot=true, two_opt=0, tildeV=100, time_limit=3600, log_level=1, alphas=[3], sp_solve="poly", F=183, redirect_stdio=false)
# tildeV_0 = parse(Int64, ARGS[4]) == 0.0 ? 0 : 100
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

# pars = MainPar(solve_mod="g(F)", 
#                sp_solve="poly", 
#                 alphas=[parse(Int64, ARGS[3])], 
#                 write_res="local", 
#                 log_level=1, 
#                 time_limit=172000, 
#                 tildeV=100, 
#                 html_user_notes=("seperate y_ij <= y_jj - x_ij on lazy constraints", "seperate y_ij <= y_jj - x_ij on lazy constraints"), 
#                 two_opt=0, 
#                 redirect_stdio=false, 
#                 do_plot=true, 
#                 F_interval = (0.0,10000),
#                 F = 0, 
#                 backup_factor=0.01, 
#                 use_blossom=false, 
#                 nthreads=4, 
#                 gFreuse_lazycons=true)
main(pars, parse(Int64, ARGS[2]))
exit()
