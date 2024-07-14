using Aqua
@testset "Aqua.jl" begin
    Aqua.test_all(
      RingStarProblems;
      ambiguities=(exclude=[], broken=true),
      piracies=false,
    )
  end