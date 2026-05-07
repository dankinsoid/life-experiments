"""
The environment agents live in.

The world is a rectangular grid where each cell either contains one unit of food
(`1.0`) or is empty (`0.0`). Using a `Matrix{Float64}` rather than `Bool` keeps
the door open for partial food amounts later without changing the data layout.
"""
mutable struct World
    food::Matrix{Float64}
    height::Int
    width::Int
end

"""
    World(height, width; initial_food_density=0.05)

Create a fresh world of the given size, sprinkled with food cells at the
requested density.
"""
function World(height::Int, width::Int; initial_food_density::Float64 = 0.05)
    food = Float64.(rand(height, width) .< initial_food_density)
    World(food, height, width)
end

"""
    respawn_food!(world; rate=0.002)

Each empty cell independently regrows food with probability `rate` per tick.
Keeps the ecosystem from collapsing once agents deplete their local area.
"""
function respawn_food!(world::World; rate::Float64 = 0.002)
    @inbounds for idx in eachindex(world.food)
        if world.food[idx] == 0 && rand() < rate
            world.food[idx] = 1.0
        end
    end
end
