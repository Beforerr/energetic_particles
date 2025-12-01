using ParticlesTransport
using Test
using Aqua

@testset "ParticlesTransport.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(ParticlesTransport)
    end
    # Write your tests here.
end
