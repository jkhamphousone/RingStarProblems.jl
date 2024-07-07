using RingStarProblems
using Test
using Aqua

@testset "RingStarProblems.jl" begin
    # Write your tests here.
    include("aqua.jl")

    pars = RingStarProblems.MainPar(solve_mod="Both",
                      write_res="", 
                      o_i="0", 
                      s_ij="", 
                      r_ij="", 
                      backup_factor=0.01, 
                      do_plot=false, 
                      two_opt=0, 
                      tildeV=100, 
                      time_limit=60, 
                      log_level=1, 
                      sp_solve="poly", 
                      redirect_stdio=false, 
                      F=183, 
                      html_user_notes=("seperate y_ij <= y_jj - x_ij on lazy constraints", "seperate y_ij <= y_jj - x_ij on lazy constraints"), 
                      use_blossom=false, 
                      alphas=[3], 
                      nthreads=4,
                      uc_strat=4)
    @test optmize(pars, 1) == 0
    @test optmize(pars, 3) == 0

end
