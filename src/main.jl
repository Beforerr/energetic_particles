using DrWatson
using OhMyThreads: tmap

function gap(times, v)
    return median(diff(times) .|> u"s") * v
end

function build_sampler(df)
    tdf = @chain df begin
        @rselect(
            :B = :B_mag * u"nT",
            :θ = abs(acosd(:B_n_mva / :B_mag)),
            :β = :ω_in / 2,
            :L = :L_n_mva
        )
        @rsubset(!any(isnan, [:B, :θ, :β, :L]))
        dropmissing
    end
    return let rows = eachrow(tdf)
        () -> begin
            row = rand(rows)
            return RotationalDiscontinuity(; B = row.B, θ = row.θ, β = row.β, L = row.L, sign = rand((1, -1)))
        end
    end
end

@kwdef struct Experiment{E, L, T}
    id::String
    e::E
    l::L
    n::Int = 256
    seed::Int = 1234
    max_time::T = 2.0e4u"s"
end

DrWatson.default_allowed(::Experiment) = (Real, String, Quantity)

function produce(exp::Experiment, sampler)
    data, _ = produce_or_load(exp, datadir()) do c
        Random.seed!(c.seed)
        trajs = tmap(i -> simulate_particle(sampler, c.l, c.e, c.max_time), 1:c.n)
        @strdict trajs
    end
    return data
end
