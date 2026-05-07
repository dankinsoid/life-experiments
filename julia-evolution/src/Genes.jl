"""
Genetic traits of an agent. All three are continuous and heritable with mutation.

- `speed`:  how far the agent moves per tick (cells).
- `sense`:  radius within which the agent can perceive food (cells).
- `size`:   body size — larger agents cost more energy per tick but can store more.

The trade-offs encoded in the energy model (see `Simulation.step!`) are what
allow natural selection to produce non-trivial equilibria.
"""
mutable struct Genes
    speed::Float64
    sense::Float64
    size::Float64
end

"""
    mutate(g::Genes; rate=0.1) -> Genes

Return a copy of `g` with each trait perturbed by Gaussian noise of std `rate`
(relative to the current value). Traits are clamped to a small positive minimum
so an agent never degenerates into something non-viable that would divide by zero.
"""
function mutate(g::Genes; rate::Float64 = 0.1)
    perturb(x) = max(0.05, x * (1 + rate * randn()))
    Genes(perturb(g.speed), perturb(g.sense), perturb(g.size))
end
