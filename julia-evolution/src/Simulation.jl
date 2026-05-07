"""
The orchestrator: holds a `World`, a population of `Agent`s, the current tick,
and a rolling history of aggregate statistics used by the dashboard.

History is stored as a `Vector{NamedTuple}` rather than separate parallel arrays
so a single `push!` per tick keeps the bookkeeping obviously consistent.
"""
mutable struct Simulation
    world::World
    agents::Vector{Agent}
    tick::Int
    history::Vector{NamedTuple{(:tick, :pop, :speed, :sense, :size),
                               Tuple{Int, Int, Float64, Float64, Float64}}}
end

"""
    Simulation(; height=200, width=200, n_agents=100, food_density=0.05)

Build a fresh simulation with a randomly-seeded world and population. Initial
agents get genes drawn from a narrow distribution around sensible midpoints so
the very first generation isn't dominated by a single lucky outlier.
"""
function Simulation(; height::Int = 200, width::Int = 200,
                      n_agents::Int = 100, food_density::Float64 = 0.05)
    world = World(height, width; initial_food_density = food_density)
    agents = [Agent((rand() * height, rand() * width),
                    20.0,
                    Genes(1.0 + 0.2 * randn(),
                          5.0 + 1.0 * randn(),
                          1.0 + 0.2 * randn()))
              for _ in 1:n_agents]
    Simulation(world, agents, 0, [])
end

# Energy accounting — exposed as functions so the balance can be tuned in one place.
#
# Metabolism: bigger & faster agents pay more per tick. The square on speed makes
# raw speed expensive and prevents runaway "sonic hedgehog" equilibria.
# Sense is cheap but not free, otherwise infinite vision always wins.
metabolic_cost(g::Genes) = 0.05 * g.size + 0.02 * g.speed^2 + 0.01 * g.sense

# Eating: food yield scales with size — bigger agents extract more per cell.
food_yield(g::Genes) = 5.0 * g.size

# Reproduction threshold scales with size, so big agents need proportionally more
# energy to split. Otherwise big agents would always out-reproduce small ones.
reproduction_threshold(g::Genes) = 30.0 * g.size

"""
    step!(sim)

Advance the simulation by one tick:

  1. Every agent decides a move, walks, and pays its metabolic cost.
  2. Agents standing on food consume it and gain `food_yield`.
  3. Agents with non-positive energy die.
  4. Agents above their reproduction threshold split; child inherits mutated genes
     and each parent keeps half the pre-split energy.
  5. Food regrows stochastically.
  6. Aggregate stats for this tick are pushed onto the history.

Order matters: movement-before-eating means an agent that steps onto food the
same tick it arrives gets rewarded, which is the intuitive behavior.
"""
function step!(sim::Simulation)
    world = sim.world
    H, W = world.height, world.width

    # 1. Move & pay upkeep.
    for a in sim.agents
        dx, dy = decide_move(a, world.food)
        nx = clamp(a.pos[1] + dx, 1.0, Float64(H))
        ny = clamp(a.pos[2] + dy, 1.0, Float64(W))
        a.pos = (nx, ny)
        a.energy -= metabolic_cost(a.genes)
    end

    # 2. Eat (if standing on a food cell).
    for a in sim.agents
        i = clamp(round(Int, a.pos[1]), 1, H)
        j = clamp(round(Int, a.pos[2]), 1, W)
        if world.food[i, j] > 0
            world.food[i, j] = 0.0
            a.energy += food_yield(a.genes)
        end
    end

    # 3. Cull the dead.
    filter!(a -> a.energy > 0, sim.agents)

    # 4. Reproduce. Collect newborns first to avoid iterating a mutating vector.
    newborns = Agent[]
    for a in sim.agents
        if a.energy ≥ reproduction_threshold(a.genes)
            a.energy /= 2
            child = Agent(a.pos, a.energy, mutate(a.genes))
            push!(newborns, child)
        end
    end
    append!(sim.agents, newborns)

    # 5. Food regrowth.
    respawn_food!(world)

    # 6. Record stats.
    sim.tick += 1
    n = length(sim.agents)
    if n > 0
        mean_speed = sum(a.genes.speed for a in sim.agents) / n
        mean_sense = sum(a.genes.sense for a in sim.agents) / n
        mean_size  = sum(a.genes.size  for a in sim.agents) / n
    else
        # Extinction: keep history well-defined so plots don't break.
        mean_speed = mean_sense = mean_size = 0.0
    end
    push!(sim.history, (tick = sim.tick, pop = n,
                        speed = mean_speed, sense = mean_sense, size = mean_size))
    return sim
end
