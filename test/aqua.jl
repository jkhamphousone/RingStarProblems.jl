using Aqua
using RingStarProblems

@testset "Aqua.jl" begin
    Aqua.test_all(
        RingStarProblems;
        stale_deps=(;ignore=[:GLPK, :Gurobi]),
        ambiguities = (exclude = [], broken = false),
        piracies = false,
    )
end
