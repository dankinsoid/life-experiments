using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "Evolution.jl"))
using .Evolution

# Tweak these to explore different ecological regimes:
#   - higher food_density  → smaller, slower agents tend to win
#   - lower food_density   → pressure toward more `sense` and `speed`
#   - larger n_agents      → noisier early dynamics, slower realtime
run_evolution(height = 200, width = 200, n_agents = 100, food_density = 0.05)
