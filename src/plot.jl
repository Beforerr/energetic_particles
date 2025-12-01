using AlgebraOfGraphics

set_aog_theme!()

using JumpProcessesPDF: df_rand_jumps

using ParticlesTransport: z_mean, z_std, rperp_std


const 𝐋 = (;
    E = "Energy [MeV]",
    t = "Time [s]",
    Δz = L"$Δz$ [km]",
    Δz2 = L"$⟨Δz^2⟩$ [km²]",
    Δx = L"$\sqrt{Δ𝐫_⊥^2}$ [km]",
    Δx2 = L"$⟨Δ𝐫_⊥^2⟩$ [km²]",
    κpara = L"$κ_∥$ [km²/s]",
    κperp = L"$κ_⊥$ [km²/s]",
)

_time(t) = t
_time(t::Unitful.Time) = NoUnits(t / u"s")
_z(t) = t
_z(t::Unitful.Length) = NoUnits(t / u"km")

function plot_state_trajectories(fp, trajs, max_time)
    xlabel = 𝐋.t
    ax1 = Axis(fp[1, 1]; xlabel, ylabel = 𝐋.Δz)
    traj = rand(trajs)
    max_time = _time(max_time)
    t_grid = range(100.0, max_time, length = 250)
    z_stds = z_std(trajs).(t_grid .* u"s")
    lines!(ax1, t_grid, z_stds)
    lines!(ax1, t_grid, z_mean(trajs).(t_grid .* u"s"))
    lines!(ax1, _time.(traj.t), _z.(traj.z); color = :black)

    ax2 = Axis(fp[2, 1]; xlabel, ylabel = 𝐋.Δx)
    rperp_stds = rperp_std(trajs).(t_grid .* u"s")
    lines!(ax2, t_grid, rperp_stds)
    lines!(ax2, _time.(traj.t), _z.(norm.(traj.𝐝)); color = :black)

    for traj in trajs
        fv = FieldViewable(traj)
        lines!(ax1, _time.(fv.t), _z.(fv.z); color = :gray, alpha = 0.1)
        lines!(ax2, _time.(fv.t), _z.(norm.(fv.𝐝)); color = :gray, alpha = 0.1)
    end

    ax_Δz2 = Axis(fp[1, 2]; xlabel, ylabel = 𝐋.Δz2)
    lines!(ax_Δz2, t_grid, z_stds .^ 2)
    ax_Δx2 = Axis(fp[2, 2]; xlabel, ylabel = 𝐋.Δx2)
    lines!(ax_Δx2, t_grid, rperp_stds .^ 2)

    # hidexdecorations!.((ax1, ax_Δz2))
    xlims!(ax1, 0, max_time * 1.01)
    xlims!(ax2, 0, max_time * 1.01)
    return fp
end

plot_state_trajectories(trajs, max_time) = plot_state_trajectories(Figure(), trajs, max_time)

function plot_pitch_angle_cdf(f, results; n = 100, add_stationary_distribution = false)

    results.sα0 = sind.(results.α0)
    results.Δsα = sind.(results.α1) - results.sα0

    sα_jumps = df_rand_jumps(results, :sα0, :Δsα; n, incremental = true, bounds = (0, 1))
    s2α_jumps = df_rand_jumps(results, :s2α0, :Δs2α; n, incremental = true, bounds = (0, 1))
    μ_jumps = df_rand_jumps(results, :μ0, :Δμ; n, incremental = true, bounds = (-1, 1))

    mid_index = div(size(s2α_jumps, 1), 2)

    ax = Axis(f[1, 1]; xlabel = "sin(α)^2", ylabel = "F")
    ecdfplot!(s2α_jumps[1, :]; label = "Initial")
    ecdfplot!(s2α_jumps[mid_index, :]; label = "Intermediate", color = Cycled(2))
    ecdfplot!(s2α_jumps[end, :]; label = "Final", color = Cycled(3))

    Axis(f[1, 2]; xlabel = "cos(α)")
    ecdfplot!(μ_jumps[1, :]; label = "Initial")
    ecdfplot!(μ_jumps[mid_index, :]; label = "Intermediate", color = Cycled(2))
    ecdfplot!(μ_jumps[end, :]; label = "Final", color = Cycled(3))

    if add_stationary_distribution
        tm = transition_matrix(results)
        μs = tm.dims[1].val
        dμ = μs[2] - μs[1]
        lines!(μs, dμ .* cumsum(stationary_distribution(μs)); label = "Stationary", color = Cycled(4))
    end

    Axis(f[1, 3]; xlabel = "sin(α)")
    ecdfplot!(sα_jumps[1, :]; label = "Initial")
    ecdfplot!(sα_jumps[mid_index, :]; label = "Intermediate", color = Cycled(2))
    ecdfplot!(sα_jumps[end, :]; label = "Final", color = Cycled(3))

    # tm = transition_matrix(results)
    # plot(f[0, 1:end], tm)

    return axislegend(ax; position = :lt)
end
