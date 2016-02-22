# Terrain Generator

A `Julia` module for terrain generation. Uses midpoint displacement for
building terrain-like heightmaps, a rolling pathfinding method for
river placement (which is currently very slow) and a moisture and height
sensitive vegetation placement function.

## Results

```{julia}
view(to_image(waters(midpoint_displacement(heightmap(9))),contours))
```


![example contour map 1](http://xn--bta-yla.net/resources/images/2016-02-21-173654_1920x1080_scrot.png)

![example contour map 2](http://xn--bta-yla.net/resources/images/2016-02-21-172943_1920x1080_scrot.png)

```{julia}
view(to_image(foliage(waters(midpoint_displacement(heightmap(9)))),life))
```
![example life map](http://xn--bta-yla.net/resources/images/2016-02-22-024922_1920x1080_scrot.png)
