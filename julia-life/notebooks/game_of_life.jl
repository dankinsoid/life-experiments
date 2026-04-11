
using GLMakie

grid = Observable(rand(0:1, 100, 100))
fig = heatmap(grid, colormap = :grays)
display(fig)

while events(fig).window_open[]
  next = copy(grid[])
  for i in axes(next, 1), j in axes(next, 2)
    neighbors = sum(grid[][max(i-1,1):min(i+1,end), max(j-1,1):min(j+1,end)]) - grid[][i,j]
    if next[i,j] == 1
      next[i,j] = neighbors == 2 || neighbors == 3 ? 1 : 0
    else
      next[i,j] = neighbors == 3 ? 1 : 0
    end
  end
  grid[] = next
  sleep(0.1)
end


readline()