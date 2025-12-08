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


function plot_state_trajectories(fp, trajs, max_time)
    _t(t) = t / 1.0e4
    _t(t::Unitful.Time) = NoUnits(t / 1.0e4u"s")
    _z(z::Unitful.Length) = NoUnits(z / 1.0e7u"km")
    _z(z::Number) = z / 1.0e7

    xlabel = L"Time [$10^4$ s]"
    ax1 = Axis(fp[1, 1]; xlabel, ylabel = L"$Δz$ [$10^7$ km]")
    traj = rand(trajs)
    t_grid = range(100.0u"s", max_time, length = 250)
    x = _t.(t_grid)

    ax2 = Axis(fp[2, 1]; xlabel, ylabel = L"$\sqrt{Δ𝐫_⊥^2}$ [$10^7$ km]")
    rperp_stds = rperp_std(trajs).(t_grid) .|> _z

    # lines!(ax1, x, _z.(z_mean(trajs).(t_grid)); color = Cycled(2), label = "mean")

    for traj in trajs
        fv = FieldViewable(traj)
        lines!(ax1, _t.(fv.t), _z.(fv.z); color = :gray, alpha = 0.1)
        lines!(ax2, _t.(fv.t), _z.(norm.(fv.𝐝)); color = :gray, alpha = 0.1)
    end

    lines!(ax1, _t.(traj.t), _z.(traj.z); color = :black)
    lines!(ax2, _t.(traj.t), _z.(norm.(traj.𝐝)); color = :black)

    z_stds = z_std(trajs).(t_grid) .|> _z
    lines!(ax1, x, z_stds; linewidth = 3, color = Cycled(1))
    lines!(ax2, x, rperp_stds; linewidth = 3, color = Cycled(1))


    ax_Δz2 = Axis(fp[1, 2]; xlabel, ylabel = L"$⟨Δz^2⟩$ [$10^{14}$ km²]")
    lines!(ax_Δz2, x, z_stds .^ 2)
    ax_Δx2 = Axis(fp[2, 2]; xlabel, ylabel = L"$⟨Δ𝐫_⊥^2⟩$ [$10^{14}$ km²]")
    lines!(ax_Δx2, x, rperp_stds .^ 2)

    hidexdecorations!.((ax1, ax_Δz2))
    xlims!(ax1, 0, _t(max_time))
    xlims!(ax2, 0, _t(max_time))
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
