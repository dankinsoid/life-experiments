module Evolution

using GLMakie

include("Genes.jl")
include("Agent.jl")
include("World.jl")
include("Simulation.jl")
include("Viz.jl")

export Genes, Agent, World, Simulation, step!, run_dashboard, run_evolution

"""
    run_evolution(; kwargs...)

Convenience entry point: build a fresh `Simulation` and open the dashboard.
All keyword arguments are forwarded to `Simulation`.
"""
function run_evolution(; kwargs...)
    sim = Simulation(; kwargs...)
    run_dashboard(sim)
    return sim
end

end # module
