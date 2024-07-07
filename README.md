# Resilient Ring Star Problem

[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
This is a my [julia](https://julialang.org/) project started during my PhD thesis to solve the Resilient Ring Star Problem also named 1-R-RSP.

The package can solve 1-R-RSP thanks to:
 - An Integer Linear Programming model
 - A Branch-and-Benders-cut algorithm

Usage:
```julia> pars = MainPar(solve_mod="Both",
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
```julia>id_instance = 3
   julia> main(pars, instance_id)
```


