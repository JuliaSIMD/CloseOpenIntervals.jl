using CloseOpenIntervals
using Test

const ArrayInterface = CloseOpenIntervals.ArrayInterface
@testset "CloseOpenIntervals.jl" begin
  function mysum(x, N)
    s = zero(eltype(x))
    @inbounds @fastmath for i ∈ CloseOpen(N)
      s += x[i+1]
    end
    s
  end
  function mysafesum(x, N)
    s = zero(eltype(x))
    @inbounds @fastmath for i ∈ SafeCloseOpen(N)
      s += x[i+1]
    end
    s
  end
  x = rand(128);
  for n ∈ 1:128
    @test mysum(x,n) ≈ mysafesum(x,n) ≈ sum(view(x,1:n))
    @test length(CloseOpen(n)) == n
  end
  @test @inferred(mysum(x,0)) == first(x)
  @test @inferred(mysafesum(x,0)) == 0.0
  @test @inferred(mysum(x, CloseOpenIntervals.StaticInt(128))) ≈ sum(x)
  @test @inferred(ArrayInterface.static_length(CloseOpen(CloseOpenIntervals.StaticInt(128)))) === CloseOpenIntervals.StaticInt(128)
  @test @inferred(eltype(CloseOpen(7))) === Int
  @test ArrayInterface.known_length(CloseOpen(CloseOpenIntervals.StaticInt(128))) == 128
end
