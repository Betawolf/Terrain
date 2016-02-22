module Terrain

using Images, Colors, ImageView

  type TerrainMap
    resolution::Int
    height::Array 
    water::Array
    verdancy::Array
    exponent::Int
  end

  " Create a heightmap of all 1s "
  function heightmap(exponent::Int)
    res = 2^exponent + 1
    return TerrainMap(res, ones(Float64, (res,res)), zeros(Float64, (res,res)), zeros(Float64, (res,res)), exponent)
  end

  " Adjust the TerrainMap to range 0:1 "
  function normalise(array)
    max = findmax(array)[1]
    min = findmin(array)[1]
    span = max - min
    return map(i -> (i-min)/span, array)
  end

  " Create a random hm of the dimensions of the input. "
  function randomise(hm::TerrainMap)
    res = hm.resolution
    rand_data = rand((res, res))
    return TerrainMap(res, rand_data, hm.water, hm.verdancy, hm.exponent)
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
  function mpd_corners!(hm::TerrainMap)
    res = hm.resolution
    hm.height[1,1] = rand()
    hm.height[1,res] = rand()
    hm.height[res,1] = rand()
    hm.height[res,res] = rand()
    return hm
  end


  " Performs midpoint displacement on a sub-grid of `hm` 
  defined by `x`, `y` and `width`, using `spread` for jitter."
  function mpd_displace!(hm::TerrainMap, x, y, width, spread)

    #find edges
    lx = 1 + (width * (x - 1))
    rx = lx + width  
    by = 1 + (width * (y - 1))
    ty = by + width 
  
    #find centezeros(Float64, (res,res))rs
    cx = round(Int, (lx + rx)/2)
    cy = round(Int, (by + ty)/2)
    
    #find corners
    ul = hm.height[lx,ty]
    ur = hm.height[rx,ty]
    ll = hm.height[lx,by]
    lr = hm.height[rx,by]

    #set centres to average of corners, plus jitter
    hm.height[cx,ty] = jitter((ul + ur)/2, spread)
    hm.height[lx,cy] = jitter((ul + ll)/2, spread)
    hm.height[cx,by] = jitter((ll + lr)/2, spread)
    hm.height[rx,cy] = jitter((ur + lr)/2, spread)
    hm.height[cx,cy] = jitter((ur + lr + ll + ul)/4, spread)
    return hm
  end


  " Generates terrain through midpoint displacement. "
  function midpoint_displacement(hm::TerrainMap, spread=0.3)
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
    return TerrainMap(hm.resolution, normalise(hm.height), hm.water, hm.verdancy, hm.exponent)
   end 
   

  " Simple greys, more is less. "
  function greyscale(x)
    h,w,v = x
    return RGB(h, h, h)
  end

  " Colours a 'soft' blue/green bleed. "
  function bluegreen(x)
    h,w,v = x
    return RGB(h/2, h, 1-h)
  end

  " Colours land/sea distinctly "
  function bordergradient(x)
    h,w,v = x
    if w == 0
      return RGB(h, (1-h/2), 0.2)
    else
      return RGB(0.2, 1-w/2, 1-w/2)
    end
  end

  function border(x)
    h,w,v = x
    if w == 0
      return RGB(1,1,1)
    else
      return RGB(0.6,0.6,0.6)
    end
  end
      

  " Colours contour lines at intervals `steps`, drawing
    sea-level at `depth` "
  function contours(x, thickness=0.005, steps=0.1)
    h,w,v = x
    i = 1.0
    while i > 0 
      if w > 0 && h >= (i - steps) &&  h < i 
        return RGB(i,i,i+(1-i)/2)
      elseif w == 0 && h > i - thickness && h < i + thickness
        return RGB(i, 0.5, 0.5)
      end
      i -= steps
    end 
    return RGB(1,1,1)
  end


  " Colours contours + lines at intervals `steps`, drawing
    sea-level at `depth` "
  function coloured_contours(x, thickness=0.005, steps=0.1)
    h,w,v = x
    i = 1.0
    while i > 0 
      if w > 0 && h >= (i - steps) &&  h < i 
        return RGB(i,i,i+(1-i)/2)
      elseif w == 0 && h > i - thickness && h < i + thickness
        return RGB(i, 0.5, 0.5)
      elseif w == 0 && h > (i - steps) && h < i 
        return RGB(i+(1-i)/2, i+(1-i)/2, i)
      end
      i -= steps
    end 
    return RGB(1,1,1)
  end


  " Colours contours + lines at intervals `steps`, drawing
    sea-level at `depth` "
  function coloured_contours(x, thickness=0.005, steps=0.1)
    h,w,v = x
    i = 1.0
    while i > 0 
      if w > 0 && h >= (i - steps) &&  h < i 
        return RGB(i,i,i+(1-i)/2)
      elseif w == 0 && h > i - thickness && h < i + thickness
        return RGB(i, 0.5, 0.5)
      elseif w == 0 && h > (i - steps) && h < i 
        return RGB(i+(1-i)/2, i+(1-i)/2, i)
      end
      i -= steps
    end 
    return RGB(1,1,1)
  end

  " Colours contours + lines at intervals `steps`, drawing
    sea-level at `depth` "
  function life(x, thickness=0.005, steps=0.1)
    h,w,v = x
    i = 1.0
    while i > 0 
      if w > 0 && h >= (i - steps) &&  h < i 
        return RGB(i,i,i+(1-i)/2)
      elseif w == 0 && h > (i - steps) && h < i 
        return RGB(max(0,(i+(1-i)/2)-v/2), min(1,i+(1-i)/2), max(0,i-v/2))
      end
      i -= steps
    end 
    return RGB(1,1,1)
  end


  " Draw a river from point `(x,y)`, falling downhill until the
  `depth` or the edge of the map is found. "
  function start_river(hm::TerrainMap, i, j, depth, flow=0.01)

    hdata = copy(hm.height)
    wdata = copy(hm.water)
    path = Vector[]
    possible = Vector[]
    curheight = hm.height[i,j]

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
      terrain = map(x -> hdata[x[1],x[2]], possible)
      while ls > 0
        hval,indmin = findmin(terrain)
        
        #get loc values
        loc = possible[indmin]
        deleteat!(possible, indmin)
        deleteat!(terrain, indmin)

        ls = length(possible) 
#        hval = hdata[loc[1], loc[2]]
#        println("($ls) $hval <= $curheight + $flow", hval <= curheight+flow && hval != depth + flow)
        if hval < depth || loc[1] in [1,hm.resolution] || loc[2] in [1,hm.resolution]
          push!(path, [loc[1], loc[2]])
          for p in path
            hdata[p[1],p[2]] -= flow
            wdata[p[1],p[2]] += flow
          end
          return TerrainMap(hm.resolution, hdata, wdata, hm.verdancy, hm.exponent)
        elseif hval <= curheight + flow 
          curheight = hdata[loc[1],loc[2]]
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
    return TerrainMap(hm.resolution, hdata, wdata, hm.verdancy, hm.exponent)
  end

  
  " Randomly initiate rivers above altitide `height` with probability `start_prob`,
  down to defined sea-depth `depth`. "
  function waters(hm::TerrainMap, depth=0.4, low_height=0.7, high_height=0.9, start_prob=0.02)
    for i in 1:hm.resolution
      for j in 1:hm.resolution
        point = hm.height[i,j]
        if point > low_height && point < high_height && rand() > (1-start_prob)
          hm = start_river(hm, i, j, depth)
        elseif point < depth
          hm.water[i,j] = depth - point
        end
      end
    end
    return hm
  end


  function foliage(hm::TerrainMap, base_prob=0.2)
    block_width = hm.exponent
    #Set random noise
    verd = rand((hm.resolution, hm.resolution)) * base_prob * ((1-hm.height)/16)

    #Add moisture data
    for x in 1:hm.resolution
      for y in 1:hm.resolution
        lx = max(1, x - block_width)
        ly = max(1, y - block_width)
        ux = min(x + block_width, hm.resolution)
        uy = min(y + block_width, hm.resolution)
        sample = sub(hm.water, (lx:ux, ly:uy))

        #locations of water spots
        inds = find(x->x>0,sample)
        wet = 0
        if length(inds) > 0
           dists = abs(inds - (2 * block_width * block_width))
           dist,ind= findmin(dists)
           depth = sample[inds[ind]]
           wet = min(1, (1/log2(dist))+depth) 
        end
        verd[x,y] += wet
      end
    end
    #Average out
    for x in 1:hm.resolution
      for y in 1:hm.resolution
        lx = max(1, round(Int,  x - block_width))
        ly = max(1, round(Int,  y - block_width))
        ux = round(Int, min(x + block_width, hm.resolution))
        uy = round(min(y + block_width, hm.resolution))
        sample = sub(verd, (lx:ux, ly:uy))
        avg = mean(sample)
        verd[x,y] = avg
      end
    end
    return TerrainMap(hm.resolution, hm.height, hm.water, normalise(verd), hm.exponent)
  end


  " Transform terrainmap into an image. "
  function to_image(hm::TerrainMap, rgb=greyscale)
    data = reshape(map(rgb, collect(zip(hm.height, hm.water, hm.verdancy))), hm.resolution, hm.resolution)
    return Image(data, colorspace="sRGB", spatialorder="x y")
  end


  export heightmap, normalise, randomise, to_image, jitter, midpoint_displacement, view, waters, start_river, foliage, TerrainMap
  
  export contours, border, bluegreen, greyscale, coloured_contours, life

end
