module Options

using Parameters

module SolveMod
struct BranchBendersCut end
struct ILP end
struct NoOptimize end
struct gF end
struct gFexploreonlyILP end
struct gFexploreonlyben end
const USolveMod =
    Union{BranchBendersCut,ILP,NoOptimize,gF,gFexploreonlyILP,gFexploreonlyben}

export BranchBendersCut, ILP, NoOptimize, gF, gFexploreonlyILP, gFexploreonlyben, USolveMod
end

using .SolveMod

module SPSolve
struct Poly end
struct LP end
const USPSolve = Union{Poly,LP}
export Poly, LP, USPSolve
end

using .SPSolve

module WResults
struct WHTML end
struct WLocal end
const UWriteResults = Union{WHTML,WLocal,Bool,String}
export WHTML, WLocal, UWriteResults
end
using .WResults

module Costs
using Parameters

struct Euclidian end
@with_kw mutable struct RandomInterval
    a::Int
    b::Int
    @assert 0 < a < b
end
const UCosts = Union{Euclidian,RandomInterval,Int}
export Euclidian, RandomInterval, UCosts
end
using .Costs


export SolveMod, BranchBendersCut, ILP, USolveMod
export SPSolve,
    NoOptimize, gF, gFexploreonlyILP, gFexploreonlyben, USolveMod, Poly, LP, USPSolve
export WResults, WHTML, WLocal, UWriteResults
export Costs, Euclidian, RandomInterval, UCosts





end


using .Options

"""
	SolverParameters
	poly: "poly" or "hybrid"
	random: 0 if not a random instance
			number of instance nodes otherwise
	alpha: Labbé alpha value to test
	writeresults: "WHTML()" writing results in html file
				  "WLocal()" writing longchapars folder
			      false not writing results
	nrand: Number of nodes in random instances
	o_i: "1", "0", "random" or "1:1000"
"""
@with_kw mutable struct SolverParameters
    @deftype UInt
    solve_mod::USolveMod
    sp_solve::USPSolve = Poly()
    tildeV = 0
    @assert 0 ≤ tildeV ≤ 100
    alpha = 5
    F::Float64 = 0.0
    @assert F ≥ 0
    warm_start::Vector{Int} = Int[]
    @assert length(warm_start) == 0 || warm_start[1] == Int[1]  # Exemple of 5 hubs warm_start: Int[1,2,5,3,4] TODO: in developpment
    inst_trans = 2
    @assert inst_trans in Int[0, 1, 2]
    ucstrat::Bool = true
    ucstrat_limit = 2000
    @assert ucstrat_limit ≥ 0
    uctolerance::Float64 = 0.01
    @assert uctolerance ≥ 0
    writeresults::UWriteResults
    nrand = 0
    @assert nrand >= 0
    o_i::UCosts
    s_ij::UCosts
    r_ij::UCosts
    backup_factor::Float64 = 0.01
    @assert 0 <= backup_factor <= 1 # Will be used to determine factor between c, c′, d and d′. c′ = backup_factor*c and d′ = backup_factor*d
    nb_runrand::Tuple{Int,Int} = (1, 1)
    @assert nb_runrand[2] in 1:10 || nrand == 0 && 1 <= nb_runrand[1] <= nb_runrand[2]
    two_opt = 0
    @assert two_opt in [0, 1, 2]
    plotting::Bool = true
    log_level = 1
    @assert log_level in Int[0, 1, 2]
    lp_relaxation::Bool = false
    assert::Bool = true
    write_log::Bool = false
    post_procedure::Bool = true
    F_interval::Tuple{Float64,Float64} = (0.0, 183)
    redirect_stdio::Bool = true            # link to redirect stdio https://stackoverflow.com/a/69059106/10094437
    use_blossom::Bool = true
    gFreuse_lazycons::Bool = true
end
