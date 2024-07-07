# 25.04.22
for j in [350]
    pars = MainPar(solved_mod="Ben", time_limit=3600, write_res="html", n_rand=j, o_i="0", s_ij="random", r_ij="l_ij", nb_run_rand=5)
    main(pars) ; GC.gc()
end

# 15.04.22
for j in [20, 25, 30, 35, 40]
    pars = MainPar(time_limit=3600, write_res="html", n_rand=j, o_i="1:1000", s_ij="l_ij", r_ij="l_ij", nb_run_rand=5)
    main(pars) ; GC.gc()
end

# 12.04.22
for i in 0:4
  for j in [15, 20, 25, 30]
    pars = MainPar(uc_strat=i, time_limit=3600, write_res="html", n_rand=j, o_i="1:1000", s_ij="l_ij", r_ij="l_ij", nb_run_rand=5)
    if i > 0
      pars = MainPar(solve_mod="Benders", uc_strat=i, time_limit=3600, write_res="html", n_rand=j, o_i="1:1000", s_ij="l_ij", r_ij="l_ij", nb_run_rand=5)
    end
    main(pars) ; GC.gc()
  end
end

# for i in 1 4; do j7 src/RhoRSP_script.jl 1 5 $i 500 0.000; done ; for i in 2000 10000; do j7 src/RhoRSP_script.jl 1 5 4 $i ; done

# # eil51
# for i in 0.000001 0.001 0.1 0.5; do j7 src/RhoRSP_script.jl 1 3 1 0 $i; done; for i in 500 2000 10000; do for j in 0.000001 0.001 0.1 0.5; do j7 src/RhoRSP_script.jl 1 3 4 $i $j; done; done

# # kroA100 
# j7 src/RhoRSP_script.jl 8 3 0 0 0; for i in 0.000001 0.001 0.1 0.5; do j7 src/RhoRSP_script.jl 8 3 1 0 $i; done; for i in 500 2000 10000; do for j in 0.000001 0.001 0.1 0.5; do j7 src/RhoRSP_script.jl 8 3 4 $i $j; done; done


# for i in {1..10}; do for j in 3 5 7; do j7 src/RhoRSP_script.jl $i $j; done; done
declare -a arr=("y_ij <= y_jj no constraint on the fly" "y_ij <= y_jj - x_ij no constraint on the fly" "seperate y_ij <= y_jj - x_ij on lazy constraints")

for i in "${arr[@]}"; do j7 src/RRSP_script.jl $i; done

for i in {1..10}; do for j in 0.1 0.5 1 2 5 10; do j7 src/RRSP_script.jl $j $i; done ; done
for i in 1 2 8 10; do for j in 0.1 0.5 1 2 5; do j7 src/RRSP_script.jl $j $i; done ; done
for i in 11 12; do for j in 0.5 1 2 5 10 100; do echo "Running for i=$i and j=$j" ; j7 src/RRSP_script.jl $i $j; done ; done


