"""
Magnetic field configuration for particle scattering studies.

The field is defined by:

    B_z = B_n = const
    B_x = B_0 * (z/L) / (1 + a/2 * (z/L)^2)^2
    B_y = 0

The corresponding field line trajectory is:

    x(z) = (B_0/B_n) * (1/2 * (z/L)^2) / (1 + a/2 * (z/L)^2)

This profile captures the curvature and convergence of field lines at
the current sheet center (z=0). The parameter `a` controls how quickly
the transverse field falls off at large |z|; the ratio B_0/B_n sets
the maximum inclination of the field lines.
"""

using CurrentSheetTestParticle
using CurrentSheetTestParticle: normalization, normalize, SolutionNorm
using StaticArrays
using Unitful
using Unitful: BField, Length, NoUnits

"""
    ScatteringConfig

Magnetic field configuration based on:

    B_z = B_n = const
    B_x = B_0 * (z/L) / (1 + a/2 * (z/L)^2)^2

# Fields
- `B_n`: Normal (guide) field component [nT]
- `B_0`: Transverse field amplitude [nT]
- `L`:   Current sheet half-thickness [km]
- `a`:   Profile shape parameter (default 2.0; controls how fast B_x
         decays at large |z|)
- `sign`: Field polarity (+1 or -1)

# Notes
The total asymptotic transverse field-line displacement from z = -∞ to
z = +∞ is:

    Δx_∞ = (B_0/B_n) * L * (2/a)

So for `a = 2` the net deflection is one current-sheet thickness per
unit of B_0/B_n.
"""
@kwdef struct ScatteringConfig{B <: BField, L <: Length}
    B_n::B
    B_0::B
    L::L
    a::Float64 = 2.0
    sign::Int = 1
end

# ──────────────────────────────────────────────────────────────────────────────
# Callable field interface  (r in units of L; returns B in units of B_n)
# ──────────────────────────────────────────────────────────────────────────────

"""
    (c::ScatteringConfig)(r̃)

Return the magnetic field vector at normalised position `r̃ = r/L`, in
units of `B_n`.
"""
function (c::ScatteringConfig)(r̃)
    ξ = r̃[3]              # z / L
    ε = NoUnits(c.B_0 / c.B_n)
    Bx = c.sign * ε * ξ / (1 + c.a / 2 * ξ^2)^2
    return SA[Bx, 0.0, 1.0]
end

# ──────────────────────────────────────────────────────────────────────────────
# Normalization and normalised-field objects
# ──────────────────────────────────────────────────────────────────────────────

"""
    NormalisedScatteringField

Dimensionless version of `ScatteringConfig`, callable as `B(r̃)` → unit
B-field vector.
"""
struct NormalisedScatteringField
    ε::Float64      # B_0 / B_n
    a::Float64
    sign::Int
end

function (f::NormalisedScatteringField)(r̃)
    ξ = r̃[3]
    Bx = f.sign * f.ε * ξ / (1 + f.a / 2 * ξ^2)^2
    B  = SA[Bx, 0.0, 1.0]
    return B / norm(B)
end

"""
    normalization(c::ScatteringConfig)

Return the normalisation constants for `c`.

The natural scales are:
- Length:   `L`
- Time:     `t_c = m_p / (q B_n)`  (proton cyclotron period)
- Velocity: `V₀ = L / t_c = q B_n L / m_p`
"""
function normalization(c::ScatteringConfig)
    t_c = (Unitful.mp / (Unitful.q * c.B_n)) |> u"s"
    V₀  = c.L / t_c
    return (; V₀, L_n = c.L, B_n = c.B_n, t_c)
end

"""
    normalize(c::ScatteringConfig)

Return the dimensionless field object for use in ODE integration.
"""
function normalize(c::ScatteringConfig)
    ε = NoUnits(c.B_0 / c.B_n)
    return NormalisedScatteringField(ε, c.a, c.sign)
end

# ──────────────────────────────────────────────────────────────────────────────
# Sampler
# ──────────────────────────────────────────────────────────────────────────────

"""
    build_scattering_sampler(; B_n, B_0_range, L, a, kwargs...)

Return a zero-argument callable that draws a random `ScatteringConfig`
each time it is called.

# Arguments
- `B_n`:       Normal field [nT]
- `B_0_range`: `(B_0_min, B_0_max)` uniform range for the transverse
               field amplitude [nT]
- `L`:         Current sheet thickness [km]
- `a`:         Profile shape parameter
"""
function build_scattering_sampler(;
    B_n,
    B_0_range,
    L,
    a = 2.0,
)
    B_0_min, B_0_max = B_0_range
    return () -> ScatteringConfig(;
        B_n,
        B_0 = B_0_min + rand() * (B_0_max - B_0_min),
        L,
        a,
        sign = rand((1, -1)),
    )
end

"""
    build_scattering_sampler(df; kwargs...)

Build a sampler from a `DataFrame` containing observed solar-wind
parameters.  Expected columns: `B_mag` [nT], `L_n_mva` [km], `ω_in`
[rad].  The transverse amplitude is taken as `B_0 = B_mag * sin(θ_B)`
where `θ_B = acos(B_n_mva / B_mag)`.
"""
function build_scattering_sampler(df; a = 2.0)
    tdf = @chain df begin
        @rselect(
            :B_n = :B_mag * abs(cosd(:θ_B)) * u"nT",
            :B_0 = :B_mag * sind(:θ_B) * u"nT",
            :L   = :L_n_mva,
        )
        @rsubset(!any(isnan, [:B_n, :B_0, :L]))
        dropmissing
    end
    return let rows = eachrow(tdf)
        () -> begin
            row = rand(rows)
            ScatteringConfig(;
                B_n  = row.B_n,
                B_0  = row.B_0,
                L    = row.L,
                a,
                sign = rand((1, -1)),
            )
        end
    end
end
