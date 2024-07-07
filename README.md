# Resilient Ring Star Problem Solver
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

This is a [julia](https://julialang.org/) project started during my PhD thesis to solve the Resilient Ring Star Problem also named 1-R-RSP. [Chapter 3 of my Thesis manuscript](https://theses.hal.science/tel-04319443) as well as [Khamphousone et al., 2021](https://www.researchgate.net/profile/Fabian-Castano/publication/351117932_Introducing_the_Resilient_Ring_Star_Problem/links/60886e808ea909241e2c5ee0/Introducing-the-Resilient-Ring-Star-Problem.pdf) and [Khamphousone et al., 2023](https://hal.science/hal-04286851) introduce 1-R-RSP.

## Ring Star Problem Solver
When settings `backup_factor=0` or `tildeV=0`, 1-R-RSP reduces to RSP and ResilientRSPSolver solves RSP.

The package can solve 1-R-RSP thanks to:
 - A Branch-and-Benders-cut algorithm (refered as B&BC)
 - An Integer Linear Programming model (ILP)
 - Or both, sequentially

# Usage
```julia
julia> using ResilientRSPSolver
julia> pars = ResilientRSPSolver.MainPar(
                        solve_mod="Both",     # ILP, B&BC or Both
                        write_res="",         # output results locally, html or no output ""
                        o_i="0",              # opening costs
                        s_ij="",              # star costs
                        r_ij="",              # ring costs
                        backup_factor=0.01,   # backup_factor c'=0.01c and d'=0.01c
                        do_plot=false,        # plot_results (to debug)
                        two_opt=0,            # use two_opt heuristic (not functional yet)
                        tildeV=100,           # uncertain nodes set
                        time_limit=120,       # Gurobi TL
                        log_level=1,          # console output log_level
                        sp_solve="poly",      # solving subproblem method for B&BC
                        redirect_stdio=false, # redirecting_stdio to output file
                        F=183,                # total failing time F, see PhD manuscript
                        use_blossom=false,    # use blossom inequalities (not functional yet)
                        alphas=[3],           # See [Labbé et al., 2004](ttps://doi.org/10.1002/net.10114)
                        nthreads=4,           # Number of threads used in GUROBI, set 0 for maximum number of available threads
                        uc_strat=4            # user cut strategy
)
```
Then:
```julia
julia> id_instance = 3
julia> ResilientRSPSolver.optimize(pars, instance_id)
```
