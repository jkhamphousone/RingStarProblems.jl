# Resilient Ring Star Problem Solver
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

This is a my [julia](https://julialang.org/) project started during my PhD thesis to solve the Resilient Ring Star Problem also named 1-R-RSP. [Chapter 3 of my Thesis manuscript](https://theses.hal.science/tel-04319443) as well as [Khamphousone et al., 2021](https://www.researchgate.net/profile/Fabian-Castano/publication/351117932_Introducing_the_Resilient_Ring_Star_Problem/links/60886e808ea909241e2c5ee0/Introducing-the-Resilient-Ring-Star-Problem.pdf) and [Khamphousone et al., 2023](https://hal.science/hal-04286851) introduce 1-R-RSP.

The package can solve 1-R-RSP thanks to:
 - An Integer Linear Programming model
 - A Branch-and-Benders-cut algorithm
 - (Or both)

# Usage
```
julia> using RRSP
julia> pars = RRSP.MainPar(solve_mod="Both",
                      write_res="", 
                      o_i="0", 
                      s_ij="", 
                      r_ij="", 
                      backup_factor=0.01, 
                      do_plot=false, 
                      two_opt=0, 
                      tildeV=100, 
                      time_limit=120, 
                      log_level=1, 
                      sp_solve="poly", 
                      redirect_stdio=false, 
                      F=183, 
                      html_user_notes=("seperate y_ij <= y_jj - x_ij on lazy constraints", "seperate y_ij <= y_jj - x_ij on lazy constraints"), 
                      use_blossom=false, 
                      alphas=[3], 
                      nthreads=4,
                      uc_strat=4)
```
Then:
```
julia> id_instance = 3
julia> RRSP.optimize(pars, instance_id)
```
