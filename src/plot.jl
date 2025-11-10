using AlgebraOfGraphics

set_aog_theme!()

using JumpProcessesPDF: df_rand_jumps

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
