module Terrain

using Images, Colors, ImageView

  type HeightMap
    resolution::Int
    data::Array 
    exponent::Int
  end

  " Create a heightmap of all 1s "
  function heightmap(exponent::Int)
    res = 2^exponent + 1
    return HeightMap(res, ones(Float64, (res,res)), exponent)
  end

  " Adjust the HeightMap to range 0:1 "
  function normalise(hm::HeightMap)
    max = findmax(hm.data)[1]
    min = findmin(hm.data)[1]
    span = max - min
    norm_data = map(i -> (i-min)/span, hm.data)
    return HeightMap(hm.resolution, norm_data, hm.exponent)
  end

  " Create a random hm of the dimensions of the input. "
  function randomise(hm::HeightMap)
    res = hm.resolution
    rand_data = rand((res, res))
    return HeightMap(res, rand_data, hm.exponent)
  end

  " A random + or - of extent `spread` "
  function randdiff(spread)
    return (spread*rand()*2)-spread
  end

  " Adds `randdiff(spread)` to `val` "
  function jitter(val::Float64, spread::Float64)
    return val + randdiff(spread)
  end

  " Sets the corners of `hm` to random values. "
  function mpd_corners!(hm::HeightMap)
    res = hm.resolution
    hm.data[1,1] = rand()
    hm.data[1,res] = rand()
    hm.data[res,1] = rand()
    hm.data[res,res] = rand()
    return hm
  end


  " Performs midpoint displacement on a sub-grid of `hm` 
  defined by `x`, `y` and `width`, using `spread` for jitter."
  function mpd_displace!(hm::HeightMap, x, y, width, spread)

    #find edges
    lx = 1 + (width * (x - 1))
    rx = lx + width  
    by = 1 + (width * (y - 1))
    ty = by + width 
  
    #find centers
    cx = round(Int, (lx + rx)/2)
    cy = round(Int, (by + ty)/2)
    
    #find corners
    ul = hm.data[lx,ty]
    ur = hm.data[rx,ty]
    ll = hm.data[lx,by]
    lr = hm.data[rx,by]

    #set centres to average of corners, plus jitter
    hm.data[cx,ty] = jitter((ul + ur)/2, spread)
    hm.data[lx,cy] = jitter((ul + ll)/2, spread)
    hm.data[cx,by] = jitter((ll + lr)/2, spread)
    hm.data[rx,cy] = jitter((ur + lr)/2, spread)
    hm.data[cx,cy] = jitter((ur + lr + ll + ul)/4, spread)
    return hm
  end


  " Generates terrain through midpoint displacement. "
  function midpoint_displacement(hm::HeightMap, spread=0.3)
    #set random corners
    mpd_corners!(hm)
    i = 0 
    #Iterate up to size of map
    while i < hm.exponent
      chunks = 2^i
      chunkwidth = round(Int, (hm.resolution - 1 )/chunks)
      #for every chunk of the current size
      for x in 1:chunks
        for y in 1:chunks
          #average corners
          mpd_displace!(hm, x, y, chunkwidth, spread)
        end
      end                
      i += 1
      spread *= 0.5
    end
    return normalise(hm)
   end 
   

  " Simple greys, more is less. "
  function greyscale(x)
    return RGB(x, x, x)
  end

  " Colours a 'soft' blue/green bleed. "
  function bluegreen(x)
    return RGB(x/2, x, 1-x)
  end

  " Colours land/sea distinctly, with a borderline. "
  function border(x, depth=0.5, thickness=0.005)
    if x > depth+thickness
      return RGB(x, depth+(1-x), 0.2)
    elseif x > depth-thickness
      return RGB(0,0,0)
    else
      return RGB(0.2, x, 1-x)
    end
  end

  " Colours contour lines at intervals `steps`, drawing
    sea-level at `depth` "
  function contours(x, depth=0.5, thickness=0.005, steps=0.1)
    i = 1.0
    while i > depth
      if x > i - thickness && x < i + thickness
        return RGB(i, 0.5, 0.5)
      end
      i -= steps
    end 

    i = 0.0
    while i < depth
      if x > i && x < i + steps
        return RGB(i/2,i,1-i)
      end
      i += steps
    end

    return RGB(1,1,1)
  end

  function water(x, depth=0.5)
    if x > depth
      return RGB(1,1,1)
    else
      return RGB(0,0,1)
    end
  end


  " Draw a river from point `(x,y)`, falling downhill until the
  `depth` or the edge of the map is found. "
  function start_river(hm::HeightMap, i, j, depth, flow=0.01)

    data = copy(hm.data)
    path = Vector[]
    possible = Vector[]
    curheight = hm.data[i,j]

    while true

      square =Dict(1 => (i - 1,j - 1),
                   2 => (i, j - 1),
                   3 => (i + 1, j - 1),
                   4 => (i - 1, j),
                   5 => (i - 1, j + 1),
                   6 => (i, j + 1),
                   7 => (i + 1, j + 1), 
                   8 => (i + 1, j))

      for (key, value) in square
        if value[1] <= hm.resolution && value[1] >= 1 && value[2] <= hm.resolution && value[2] >= 1 &&  !([value[1], value[2]] in possible) && !([value[1], value[2]] in path)
          push!(possible, [value[1], value[2]])
        end
      end
      
      ls = length(possible) 
      terrain = map(x -> data[x[1],x[2]], possible)
      while ls > 0
        hval,indmin = findmin(terrain)
        
        #get loc values
        loc = possible[indmin]
        deleteat!(possible, indmin)
        deleteat!(terrain, indmin)

        ls = length(possible) 
        hval = data[loc[1], loc[2]]
#        println("($ls) $hval <= $curheight + $flow", hval <= curheight+flow && hval != depth + flow)
        if hval < depth || loc[1] in [1,hm.resolution] || loc[2] in [1,hm.resolution]
          for p in path
            data[p[1],p[2]] = depth + flow
          end
          return HeightMap(hm.resolution, data, hm.exponent)
        elseif hval <= curheight + flow 
          curheight = data[loc[1],loc[2]]
          push!(path, [loc[1], loc[2]])
          i = loc[1]
          j = loc[2]
          break
        end
      end

      if ls == 0
        break
      end

    end
    println("Aborting River")
    return HeightMap(hm.resolution, data, hm.exponent)
  end

  
  " Randomly initiate rivers above altitide `height` with probability `start_prob`,
  down to defined sea-depth `depth`. "
  function rivers(hm::HeightMap, depth=0.4, height=0.8, start_prob=0.02)
    for i in 1:hm.resolution
      for j in 1:hm.resolution
        point = hm.data[i,j]
        if point > height && rand() > (1-start_prob)
          hm = start_river(hm, i, j, depth)
        end
      end
    end
    return hm
  end
      

  " Transform heightmap into an image. "
  function to_image(hm::HeightMap, rgb=greyscale)
    data = map(rgb, hm.data)
    return Image(data, colorspace="sRGB", spatialorder="x y")
  end


  export heightmap, normalise, randomise, to_image, jitter, midpoint_displacement, view, rivers, start_river
  
  export contours, border, bluegreen, greyscale, water

end
