@with_kw mutable struct MainPar @deftype String
    solve_mod = "Both" ; @assert solve_mod in ["Ben", "ILP", "Both", "No_optimize", "g(F)", "g(F)exploreonlyILP", "g(F)exploreonlyBen"]
    sp_solve = "poly" ; @assert sp_solve in ["poly", "hybrid", "LP"]
    tildeV::Int = 0 ; @assert 0 <= tildeV <= 100
    alphas::Vector{Int} = Int[5]
    F::Float64 = 0.0 ; @assert 0 <= F
    warm_start::String = "" ; @assert warm_start == "" || warm_start[1] == '1'  # Exemple of 5 hubs warm_start: "1-2-5-3-4"
    inst_trans::Int = 2 ; @assert inst_trans in Int[0,1,2]
    uc_strat::Int = 4 ; @assert uc_strat in Int[0,1,2,3,4]
    uc_strat_4_limit::Int = 2000 ;
    uc_tolerance::Float64 = .01 ;
    time_limit::Int = 3600 ; @assert time_limit >= 0 # time_limit = 0 means infinity
    nthreads::Int = 8 ; @assert nthreads >= 0
    write_res = "html" ; @assert write_res in String["", "html", "local"]
    n_rand::Int = 0 ; @assert n_rand >= 0
    o_i = "" ; @assert o_i in String["", "0", "1", "random", "1:1000"]
    s_ij = ""; @assert s_ij in String["", "l_ij", "random"]
    r_ij = ""; @assert r_ij in String["", "l_ij", "n"]
    backup_factor::Float64 = 0.01; @assert 0 <= backup_factor <= 1 # Will be used to determine factor between c, c′, d and d′. c′ = backup_factor*c and d′ = backup_factor*d    #     end
    # end
    for i in V
        for j in setdiff(V, i)
            if ζ[i,j] > 0 || ζ_poly[i,j] > 0
                println("ζ[$i, $j] = $(ζ[i,j]), ζ_poly[$i,$j] = $(ζ_poly[i,j])")
            end
        end
    end
end

function compute_sims(i, ŷ, s, V, tildeV)
    sim_i = Inf
    m_i = 0
    for j in tildeV
        if j != i && ŷ[j] && sim_i > s[i, j]
            sim_i = s[i, j]
            m_i = j
        end
    end
    sim_i′ = Inf
    m_i′ = 0

    for j in tildeV
        if j != i && j != m_i && ŷ[j]
            if sim_i′ > s[i, j]
                sim_i′ = s[i, j]
                m_i′ = j
            end
        end
    end
    sim_istar = Inf
   
    log_level::Int = 1; @assert log_level in Int[0, 1, 2]
    lp_relaxation::Bool = false ;
    assert::Bool = true
    write_log::Bool = false
    html_user_notes::Tuple{String,String} = "seperate y_ij <= y_jj - x_ij on lazy constraints", "seperate y_ij <= y_jj - x_ij on lazy constraints"
    post_procedure::Bool = true
    F_interval::Tuple{Float64,Float64} = (0.0,183)
    redirect_stdio::Bool = true ; # link to redirect stdio https://stackoverflow.com/a/69059106/10094437
    use_blossom::Bool = true ;
    gFreuse_lazycons::Bool = true ;
    """
    "y_ij <= y_jj no constraint on the fly"
    "y_ij <= y_jj - x_ij no constraint on the fly"
    "seperate y_ij <= y_jj - x_ij on lazy constraints"
    ("without constraints (10) and (12)", "without(10)&(12)")
    """
    """
        solve_mod: "Ben" or "ILP"
        poly: "poly" or "hybrid"
        random: 0 if not a random instance
                number of instance nodes otherwise
        alphas: array of Labbé alphas values to test
        write_res: "html" writing results in html file
                   "local" writing longchapars folder
                   "" not writing results
        n_rand: Number of nodes in random instances
        o_i: "1", "0", "random" or "1:1000"
    """
end




    

@with_kw mutable struct BDtable @deftype Float64
<<<<<<< HEAD
=======
    """
        Class for B&BC results
    """
>>>>>>> main
    t_time = .0 ; @assert t_time >= .0
    m_time = .0 ; @assert m_time >= .0
    s_time = .0 ; @assert s_time >= .0
    blossom_time = .0 ; @assert blossom_time >= .0
    two_opt_time = .0 ; @assert two_opt_time >= .0
    TL_reached = false ;
    gap = .0 ; @assert 0 <= gap
    UB = .0
    LB = .0
    nopt_cons = 0 ; @assert nopt_cons >= 0
    nsubtour_cons = 0 ; @assert nsubtour_cons >= 0
    nconnectivity_cuts = 0 ; @assert nconnectivity_cuts >= 0
    nblossom = 0 ; @assert nblossom >= 0 #12
    ntwo_opt = 0 ; @assert ntwo_opt >= 0
    m_cost = .0 ;
    sp_cost = .0 ; #15
    nodes_explored::Int = -1 ; #16
    sol::Solution = Solution() ;
    """
    """
end

@with_kw mutable struct ILPtable @deftype Float64
<<<<<<< HEAD
=======
    """
        Class for ILP results
    """
>>>>>>> main
    t_time = .0 ; @assert t_time >= .0
    two_opt_time = .0 ; @assert two_opt_time >= .0
    blossom_time = .0 ; @assert blossom_time >= .0
    TL_reached = false ;
    gap = .0 ; @assert 0 <= gap
    UB = .0
    LB = .0
    nsubtour_cons = 0 ; @assert nsubtour_cons >= 0
    nconnectivity_cuts = 0 ; @assert nconnectivity_cuts >= 0
    nedges_cuts = 0 ;
    ntwo_opt = 0 ; @assert ntwo_opt >= 0 #11
    nblossom = 0 ; @assert nblossom >= 0 #12
    nodes_explored::Int = -1 ;
    sol::Solution = Solution() ;
    """
    """
end



function round!(bdt::BDtable)
    setfield!.(Ref(bdt), 1:6, round.(getfield.(Ref(bdt), 1:6), digits=2))
    setfield!.(Ref(bdt), 7:7, round.(getfield.(Ref(bdt), 7:7), digits=3)) # Gap rounded at 3 digits
    setfield!.(Ref(bdt), 8:16, round.(getfield.(Ref(bdt), 8:16), digits=2))
    return bdt
end

function round!(ilp::ILPtable)
    setfield!.(Ref(ilp), 1:4, round.(getfield.(Ref(ilp), 1:4), digits=2))
    setfield!.(Ref(ilp), 5:5, round.(getfield.(Ref(ilp), 5:5), digits=3))
    setfield!.(Ref(ilp), 6:12, round.(getfield.(Ref(ilp), 6:12), digits=2))
    return ilp
end
