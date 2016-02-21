# Terrain Generator

A `Julia` module for terrain generation. Uses midpoint displacement for
building terrain-like heightmaps, and a rolling pathfinding method for
river placement (which is currently very slow). 

## Results

```{julia}
view(to_image(rivers(midpoint_displacement(heightmap(9))),contours))
```

![example map](http://xn--bta-yla.net/resources/images/2016-02-21-173654_1920x1080_scrot.png)

![example map](http://xn--bta-yla.net/resources/images/2016-02-21-172943_1920x1080_scrot.png)

