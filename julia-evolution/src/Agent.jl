"""
An individual in the simulation.

Agents are mutable because they move, eat, and change energy every tick —
allocating a fresh struct per tick would dominate runtime for large populations.

- `pos`:    continuous position in the world, `(x, y)`. Continuous (not grid-cell)
            so `speed` can express sub-cell differences between agents.
- `energy`: current energy reserve; death at ≤ 0, reproduction above a threshold.
- `genes`:  heritable traits (see `Genes`).
"""
mutable struct Agent
    pos::Tuple{Float64, Float64}
    energy::Float64
    genes::Genes
end

"""
    decide_move(agent, food_matrix) -> (dx, dy)

Decide how the agent moves this tick, based *only* on what it can see locally.
Agent scans cells within `genes.sense` for food; if any are found, steps toward
the nearest one with magnitude `genes.speed`. Otherwise performs a random walk
of the same magnitude.

Kept as a pure function (no mutation) so the movement policy can be swapped
later without touching `Simulation.step!`.
"""
function decide_move(agent::Agent, food::Matrix{Float64})
    x, y = agent.pos
    r = agent.genes.sense
    sp = agent.genes.speed
    H, W = size(food)

    # Bounding box of cells the agent can perceive, clamped to world bounds.
    x_lo = max(1, floor(Int, x - r))
    x_hi = min(H, ceil(Int, x + r))
    y_lo = max(1, floor(Int, y - r))
    y_hi = min(W, ceil(Int, y + r))

    best_d2 = Inf
    best = (0.0, 0.0)
    @inbounds for i in x_lo:x_hi, j in y_lo:y_hi
        if food[i, j] > 0
            d2 = (i - x)^2 + (j - y)^2
            if d2 < best_d2 && d2 ≤ r^2
                best_d2 = d2
                best = (Float64(i), Float64(j))
            end
        end
    end

    if isfinite(best_d2) && best_d2 > 0
        # Step of length `sp` toward the nearest food cell.
        dx = best[1] - x
        dy = best[2] - y
        d  = sqrt(best_d2)
        return (sp * dx / d, sp * dy / d)
    else
        # Random walk — angle uniform, magnitude `sp`.
        θ = 2π * rand()
        return (sp * cos(θ), sp * sin(θ))
    end
end
