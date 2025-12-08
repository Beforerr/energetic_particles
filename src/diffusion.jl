using QuadGK
using Unitful
using Unitful: Velocity, Energy, BField
using Unitful: mp
using UnitfulAstro
using DataFrames
include("./utils.jl")

@enum κParallelMethod begin
    Chen24
    CurrentSheet
end

@enum κPerpMethod begin
    Classical
    Discontinuity
end


vs = 4 .^ (3:9) .* 1u"km/s"
Es = energy.(vs)
D_nn_Es = [0.00697285, 0.0456724, 0.10554, 0.14347, 0.16, 0.18, 0.2]

function D_nn(E)
    i = findfirst(isequal(E), Es)
    return D_nn_Es[i]
end

"""D_μμ = D_nn * ν"""
D_μμ(E) = event_frequency(E) * D_nn(E) |> upreferred

D_μμ(μ, E) = D_μμ(E)

# Compute the parallel spatial diffusion coefficient κ_‖
"""
``κ_∥ = \\frac{v^2}{8} ∫_{-1}^1 dμ \\frac{(1-μ^2)^2}{D_{μμ}}``

# Notes

@earlDiffusiveIdealizationChargedparticle1974
"""
function κ_parallel(v, ::Val{Discontinuity})
    E = energy(v)
    # Define the integrand
    integrand(μ) = (1 - μ^2)^2 / D_μμ(μ, E)

    # Perform numerical integration over μ (-1 to 1)
    integral, err = quadgk(integrand, -1.0, 1.0)

    # Calculate κ_‖
    return v^2 / 8 * integral |> u"cm^2 /s"
end


"""
where r and E are in the units of au and keV, respectively.
"""
function κ_parallel(r, E::Real, ::Val{Chen24})
    # Coefficients from the formula
    kappa_base = 5.16e18 * u"cm^2/s"     # Base value of kappa
    # kappa_error = 1.22e18 * u"cm^2/s"    # Uncertainty in kappa base value
    r_exponent = 1.17
    # r_exponent_error = 0.08    # Uncertainty in r exponent
    E_exponent = 0.71
    # E_exponent_error = 0.02    # Uncertainty in E exponent
    return kappa_base * r^r_exponent * E^E_exponent
end

κ_parallel(r, E::Energy, ::Val{Chen24}) = κ_parallel(r, NoUnits(E / u"keV"), Val(Chen24))


λ_parallel(κ_parallel, v::Velocity) = 3 * κ_parallel / v |> upreferred
λ_parallel(κ_parallel, E::Energy; m = mp) = λ_parallel(κ_parallel, velocity(E; m))

v_parallel(E; m = mp) = velocity(E; m) * sqrt(2) / 2

"""
Frequency of scattering events for particle with parallel speed v in flow with velocity U and event seperation time Δt
"""
function event_frequency(v::Velocity; U = 4.0e2u"km/s", Δt = 30u"minute")
    s = U * Δt
    return v / s |> upreferred
end

"""
Arrival time for particle with parallel speed v to travel to 1AU
"""
function arrival_time(v::Velocity; s = 1u"AU")
    return s / v |> u"d"
end

# κ_perp(E; B = 10u"nT", a = 10) = (a * gyroradius(B, E))^2 * event_frequency(E) |> u"cm^2 /s"

event_frequency(E; kw...) = event_frequency(v_parallel(E); kw...)
