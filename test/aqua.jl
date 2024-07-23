using RingStarProblems
using Aqua: Aqua


@testset "aqua deps compat" begin
    Aqua.test_deps_compat(RingStarProblems)
end

# This often gives false positive
# @testset "aqua project toml formatting" begin
#     Aqua.test_project_toml_formatting(RingStarProblems)
# end

@testset "aqua unbound_args" begin
    Aqua.test_unbound_args(RingStarProblems)
end

@testset "aqua undefined exports" begin
    Aqua.test_undefined_exports(RingStarProblems)
end

# Perhaps some of these should be fixed. Some are for combinations of types
# that make no sense.
# @testset "aqua test ambiguities" begin
#     Aqua.test_ambiguities([RingStarProblems, Core, Base])
# end

@testset "aqua piracies" begin
    Aqua.test_piracies(RingStarProblems)
end

@testset "aqua project extras" begin
    Aqua.test_project_extras(RingStarProblems)
end

@testset "aqua state deps" begin
    Aqua.test_stale_deps(RingStarProblems; ignore = [:GLPK, :Gurobi, :LiveServer])
end
