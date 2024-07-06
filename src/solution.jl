@with_kw mutable struct Solution @deftype Dict{Tuple{Int,Int},Bool}
    n::Int = 0 ;
    hubs::Vector{Int} = Int[] # Vector of size |H|. n+1 doesn't appear
    x_opt = Dict{Tuple{Int,Int},Bool}() 
    x′_opt = Dict{Tuple{Int,Int},Bool}() 
    y_opt = Dict{Tuple{Int,Int},Bool}() 
    y′_opt = Dict{Tuple{Int,Int},Bool}() 
    B::Float64 = .0
    i★::Int = 0; @assert i★ >= 0
    j★::Int = 0; @assert j★ >= 0 # j★ is the critical hub that is responsible for the value of B
    k★::Int = 0; @assert k★ >= 0
end

function print_solution(file, sol::Solution, inst::Instance)
    backup = true
    print_term = false
    print(file, print_hubs(sol.hubs, print_term))
    print(file, print_ring_edges(sol.x_opt, inst.c, inst.n, !backup, print_term))
    print(file, print_star_edges(sol.y_opt, inst.d, inst.n, !backup, print_term))
    print(file, print_ring_edges(sol.x′_opt, inst.c′, inst.n, backup, print_term))
    print(file, print_star_edges(sol.y′_opt, inst.d′, inst.n, backup, print_term))
    println(file, "B = $(sol.B)")
    println(file, "i★ = $(sol.i★)")
    println(file, "j★ = $(sol.j★)")
    println(file, "k★ = $(sol.k★)")
end