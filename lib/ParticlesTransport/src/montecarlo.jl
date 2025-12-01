using LinearAlgebra

"""
Monte Carlo simulation for long-term particle behavior with current sheet interactions.

This module implements the Monte Carlo method for simulating energetic particle
transport in the solar wind with current sheet interactions.

# Algorithm
1. Sample initial μ₀ ~ π
2. Loop:
   - Particles fly a distance l_n = const = l with τ_n time
   - Particles interact with current sheet:
     * Trapped for time T_n = T_n(μ_n, φ)
     * Make perpendicular displacement d_n = d_n(μ_n, φ)
     * Exit with new pitch angle μ_{n+1} = μ(μ_n, φ)
   - T_n, d_n, μ_{n+1} depend on current sheet parameters Π_n from observation
"""

using Random
using Statistics
using StaticArrays

"""
State kind for particle tracking.

- `AfterFlight`: After flying between current sheets
- `AfterInteraction`: After interacting with current sheet
"""
@enum StateKind AfterFlight AfterInteraction

"""
    ParticleState

State of a particle in the simulation.
"""
struct ParticleState{V, Z, D, T}
    v::V      # parallel velocity
    μ::Float64      # pitch angle cosine
    z::Z      # parallel position
    𝐝::D      # perpendicular displacement
    t::T      # time
    kind::StateKind # state type
end

rand_μ0() = -1 + 2rand()

ParticleState(v; 𝐝0 = SA[0.0, 0.0], μ0 = rand_μ0(), kind = AfterInteraction) =
    ParticleState(velocity(v), μ0, 0.0u"km", 𝐝0, 0.0u"s", kind)


function solve(state, Π; kw...)
    Norm = normalization(Π)
    ṽ = NoUnits(state.v / Norm.V₀)
    𝐁 = normalize(Π)
    u0 = init_state(𝐁, ṽ, state.μ)
    sol = solve_param(𝐁, u0; save_everystep = false, tspan = (0.0, 1.0e3), kw...)
    return SolutionNorm(sol, Norm)
end

function cossin(ϑ)
    sin, cos = sincos(ϑ)
    return SA[cos, sin]
end

function update(state::ParticleState, solNorm)
    # normalization factor
    μf = cos_pitch_angles(solNorm)[end]
    # calculate the perpendicular displacement assuming a random direction
    ϑ = rand() * 2π
    Δd = field_lines_asym_distance(solNorm)
    Δ𝐝 = cossin(ϑ) .* (Δd / u"km" |> NoUnits)
    Δt = max(trapping_time(solNorm), 0.0u"s")
    return ParticleState(state.v, μf, state.z, state.𝐝 + Δ𝐝, state.t + Δt, AfterInteraction)
end

struct CurrentSheetInteraction{S, F, U}
    sampler::S
    solve::F
    update::U
end

CurrentSheetInteraction(sampler; solve = solve, update = update) =
    CurrentSheetInteraction(sampler, solve, update)

"""
    interact_with_current_sheet(state, interaction)

Update particle state after interaction with current sheet.
"""
function interact_with_current_sheet(state, interaction; kw...)
    Π = interaction.sampler()
    solNorm = interaction.solve(state, Π; kw...)
    return interaction.update(state, solNorm)
end

"""
    simulate_particle(interaction, l, v, max_time)

Simulate a single particle trajectory.

# Arguments
- `interaction`: Current sheet interaction
- `l`: Distance between current sheets [km]
- `v`: Particle parallel velocity [km/s]
- `max_time`: Maximum simulation time [s]

# Returns
- `Vector{ParticleState}`: Trajectory as vector of particle states
"""
function simulate_particle(sampler, l, v, max_time; kw...)
    csi = CurrentSheetInteraction(sampler)
    # Initialize particle
    state = ParticleState(v)
    # Storage for trajectory
    trajectory = [state]
    # Main simulation loop
    while state.t < max_time
        v_parallel = state.v * abs(state.μ)
        τ_flight = l / v_parallel
        state = ParticleState(state.v, state.μ, state.z + l * sign(state.μ), state.𝐝, state.t + τ_flight, AfterFlight)
        push!(trajectory, state)
        state = interact_with_current_sheet(state, csi; kw...)
        push!(trajectory, state)
        if state.t >= max_time
            break
        end
    end
    return FieldViewable(trajectory)
end

function z_at(traj, t)
    @assert t <= traj[end].t
    times = traj.t
    z_positions = traj.z

    idx = searchsortedlast(times, t)
    t1, t2 = times[idx], times[idx + 1]
    z1, z2 = z_positions[idx], z_positions[idx + 1]
    return (z1 + (z2 - z1) * (t - t1) / (t2 - t1)) / 1u"km"
end

function z_mean(trajs)
    return t -> mean(z_at(traj, t) for traj in trajs)
end

function rperp_at(traj, t)
    @assert t <= traj[end].t
    times = traj.t
    rperp_positions = traj.𝐝

    idx = searchsortedlast(times, t)
    t1, t2 = times[idx], times[idx + 1]
    rperp1, rperp2 = rperp_positions[idx], rperp_positions[idx + 1]
    return rperp1 + (rperp2 - rperp1) * (t - t1) / (t2 - t1)
end

norm2(x) = dot(x, x)

function z_std(trajs)
    return t -> std(z_at(traj, t) for traj in trajs)
end

# assuming a zero mean
function rperp_std(trajs)
    return t -> sqrt(mean(norm2(rperp_at(traj, t)) for traj in trajs))
end


"""
    estimate_diffusion_coefficient(t_grid, z_squared_mean)

Estimate perpendicular diffusion coefficient from ⟨z²⟩ vs t.

For diffusive behavior: ⟨z²⟩ = 2 κ t
"""
function estimate_diffusion_coefficient(trajs, max_time)
    t_grid = range(100u"s", max_time, length = 250)
    z2 = z_std(trajs).(t_grid) .^ 2
    rperp2 = rperp_std(trajs).(t_grid) .^ 2
    κ_para, r_para = _estimate_diffusion_coefficient(t_grid, z2)
    κ_perp, r_perp = _estimate_diffusion_coefficient(t_grid, rperp2)
    return (; κ_para, r_para, κ_perp, r_perp)
end

function _estimate_diffusion_coefficient(t_grid, z_squared_mean)
    # Use later portion of data (after transient behavior)
    start_idx = div(length(t_grid), 4)  # Skip first 25%

    t_fit = t_grid[start_idx:end]
    z2_fit = z_squared_mean[start_idx:end]

    # Linear regression: z² = 2κ_⊥ t
    n = length(t_fit)
    slope = (n * sum(t_fit .* z2_fit) - sum(t_fit) * sum(z2_fit)) /
        (n * sum(t_fit .^ 2) - sum(t_fit)^2)

    # R² calculation
    z2_pred = slope .* t_fit
    ss_res = sum((z2_fit .- z2_pred) .^ 2)
    ss_tot = sum((z2_fit .- mean(z2_fit)) .^ 2)
    r_squared = 1 - ss_res / ss_tot

    κ = slope / 2

    return κ, r_squared
end
