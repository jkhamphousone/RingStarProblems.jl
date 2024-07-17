[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

# [Ring Star Problem](https://en.wikipedia.org/wiki/Ring_star_problem) variants Solver

## Resilient Ring Star Problem
The references:
 - [Khamphousone et al., 2023](https://hal.science/hal-04286851) 
 - [Khamphousone et al., 2021](https://hal.science/hal-03211922/)
 - [Chapter 3 of my Thesis manuscript](https://theses.hal.science/tel-04319443)

Introduce the Resilient Ring Star Problem (called 1-R-RSP).

The package can solve 1-R-RSP thanks to:
 - A Branch-and-Benders-cut algorithm (refered to as B&BC)
 - An Integer Linear Programming model (ILP)
 - Both, sequentially

## Ring Star Problem

![Ring Star Problem network](https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Ring_Star_Problem_solution.svg/360px-Ring_Star_Problem_solution.svg.png?20240712195658)

When setting `backup_factor=0` or `tildeV=0`, 1-R-RSP reduces to RSP

## The Survivable Ring Star Problem

[A Survivable Ring Star Problem solver](https://doi.org/10.1002/net.22193) will be added.

# Requirements

[JuMP.jl](https://github.com/jump-dev/JuMP.jl) must be installed. You can only use CPLEX, GLPK, Gurobi, Xpress, and SCIP yet (as of 16th of July 2024) [because solver-independent callback support is restricted to these ones](https://jump.dev/JuMP.jl/stable/manual/callbacks/#Available-solvers).

# Installation
```julia
julia> import Pkg ; Pkg.add("RingStarProblems")
```

# Usage
```julia
julia> import RingStarProblems as RSP
julia> using JuMP
julia> pars = RSP.SolverParameters(
        solve_mod      = RSP.Both(),          # ILP, B&BC or Both
        sp_solve       = RSP.Poly(),
        writeresults   = RSP.WHTML(),         # output results locally, html or no output ""
        o_i            = 0,                   # opening costs
        s_ij           = RSP.Euclidian(),     # star costs
        r_ij           = RSP.Euclidian(),     # ring costs
        backup_factor  = 0.01,                # backup_factor c'=0.01c and d'=0.01c
        do_plot        = false,               # plot_results (to debug)
        two_opt        = 0,                   # use two_opt heuristic (not functional yet)
        tildeV         = 100,                 # uncertain nodes set
        timelimit      = 120,                 # Gurobi TL
        log_level      = 1,                   # console output log_level
        redirect_stdio = false,               # redirecting_stdio to output file
        F              = 183,                 # total failing time F, see PhD manuscript
        use_blossom    = false,               # use blossom inequalities (not functional yet)
        alphas         = [3],                 # See [Labbé et al., 2004](ttps://doi.org/10.1002/net.10114)
        nthreads       = 4                   # Number of threads used in GUROBI, set 0 for maximum number of available threads
       )
```
### GLPK
To use GLPK optimizer:
```julia
julia> using GLPK
julia> id_instance = 3
julia> rspoptimize(pars, id_instance; optimizer =
		JuMP.optimizer_with_attributes(GLPK.Optimizer,
			"msg_lev" => GLPK.GLP_MSG_ALL,
			"tm_lim" => pars.timelimit)
	)
```

### Gurobi
To use Gurobi optimizer:
```julia
julia> using Gurobi
julia> rspoptimize(pars, id_instance; optimizer = JuMP.optimizer_with_attributes(Gurobi.Optimizer,
		"TimeLimit" => pars.timelimit))
```
