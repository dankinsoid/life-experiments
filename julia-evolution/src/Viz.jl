"""
GLMakie dashboard for an evolution simulation.

Layout:
  ┌─────────────────────┬──────────────┐
  │                     │  population  │
  │       world         ├──────────────┤
  │  (food + agents)    │  mean speed  │
  │                     ├──────────────┤
  │                     │  mean sense  │
  │                     ├──────────────┤
  │                     │  mean size   │
  └─────────────────────┴──────────────┘

Observables drive the redraw: every `step!` we update a handful of `Observable`s
and Makie repaints only what changed. That's what makes realtime tractable here.
"""
function run_dashboard(sim::Simulation; fps::Float64 = 30.0)
    H, W = sim.world.height, sim.world.width

    # Live data bound to the plot.
    food_obs  = Observable(copy(sim.world.food))
    xs_obs    = Observable(Float64[a.pos[2] for a in sim.agents])  # column → x
    ys_obs    = Observable(Float64[a.pos[1] for a in sim.agents])  # row    → y
    sizes_obs = Observable(Float64[6 * a.genes.size for a in sim.agents])

    ticks_obs = Observable(Int[])
    pop_obs   = Observable(Int[])
    speed_obs = Observable(Float64[])
    sense_obs = Observable(Float64[])
    size_obs  = Observable(Float64[])

    fig = Figure(size = (1200, 800))

    ax_world = Axis(fig[1:4, 1], title = "world", aspect = DataAspect(),
                    xlabel = "x", ylabel = "y")
    heatmap!(ax_world, food_obs, colormap = [:black, :green],
             colorrange = (0.0, 1.0))
    scatter!(ax_world, xs_obs, ys_obs, markersize = sizes_obs, color = :white,
             strokecolor = :red, strokewidth = 0.5)
    xlims!(ax_world, 1, W)
    ylims!(ax_world, 1, H)

    ax_pop   = Axis(fig[1, 2], title = "population")
    ax_speed = Axis(fig[2, 2], title = "mean speed")
    ax_sense = Axis(fig[3, 2], title = "mean sense")
    ax_size  = Axis(fig[4, 2], title = "mean size", xlabel = "tick")
    for ax in (ax_pop, ax_speed, ax_sense)
        hidexdecorations!(ax, grid = false)
    end

    lines!(ax_pop,   ticks_obs, pop_obs,   color = :white)
    lines!(ax_speed, ticks_obs, speed_obs, color = :cyan)
    lines!(ax_sense, ticks_obs, sense_obs, color = :magenta)
    lines!(ax_size,  ticks_obs, size_obs,  color = :yellow)

    display(fig)

    dt = 1 / fps
    while events(fig).window_open[]
        step!(sim)

        # Mutate the plot data in place and notify Makie once per frame.
        food_obs[] = sim.world.food
        xs_obs[]    = Float64[a.pos[2] for a in sim.agents]
        ys_obs[]    = Float64[a.pos[1] for a in sim.agents]
        sizes_obs[] = Float64[6 * a.genes.size for a in sim.agents]

        # Append latest history sample. Rebuilding each Observable array is O(tick)
        # which is fine for small run times; replace with a ring buffer if it hurts.
        hist = sim.history
        ticks_obs[] = [h.tick  for h in hist]
        pop_obs[]   = [h.pop   for h in hist]
        speed_obs[] = [h.speed for h in hist]
        sense_obs[] = [h.sense for h in hist]
        size_obs[]  = [h.size  for h in hist]

        if isempty(sim.agents)
            @info "extinction event — stopping" tick=sim.tick
            break
        end

        sleep(dt)
    end
end
