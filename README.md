# FEBOL

[![Build Status](https://travis-ci.org/dressel/FEBOL.jl.svg?branch=master)](https://travis-ci.org/dressel/FEBOL.jl)
[![Coverage Status](https://coveralls.io/repos/github/dressel/FEBOL.jl/badge.svg?branch=master)](https://coveralls.io/github/dressel/FEBOL.jl?branch=master)

This package allows the testing of various filters and belief representations for a single UAV performing bearing-only localization of a single, stationary jammer.
The main question I want to answer is: what effects do the various filters and approximations have on localization time and computational time?

This code is rapidly changing. I make no guarantees about its correctness or usability at any time.

Check out the [complete documentation](http://feboljl.readthedocs.io/en/latest/index.html).





## Bearing Only Examples
The code below creates a search domain 100 meters by 100 meters, with a jammer located at (40,70).
The vehicle starts at (50,50) and moves at the default 4 m/s.
It is equipped with the standard `BearingOnly` sensor with 10 degree standard deviation.
A discrete filter with 100 bins is used for state estimation.
A `CirclePolicy` moves the UAV perpendicular to the last received bearing.
Measurements are received every half second.

```
using FEBOL

m = SearchDomain(100, 40, 70)
f = DF(m, 100)
x = Vehicle(50, 50)
p = CirclePolicy()

gif(m,x,f,p,18)
```
The resulting trajectory is saved as a gif. The jammer is a red triangle.
<p align="center">
<img src="http://stanford.edu/~dressel/gifs/gif3.gif"/>
</p>

Alternatively, you can use a greedy entropy minimizing policy that considers 8 different directions (45 degrees apart).

```
using FEBOL

m = SearchDomain(100, 40, 70)
f = DF(m, 100)
x = Vehicle(50, 50)
p = GreedyPolicy(x, 8)

gif(m,x,f,p,18)
```
<p align="center">
<img src="http://stanford.edu/~dressel/gifs/gif5.gif"/>
</p>

The following example is a particle filter with 10,000 particles. The green x marks the mean of the particles.
```
using FEBOL

m = SearchDomain(100, 40, 70)
f = PF(m, 10000)
x = Vehicle(50, 50)
p = CirclePolicy()

gif(m,x,f,p,18)
```
<p align="center">
<img src="http://stanford.edu/~dressel/gifs/gif4.gif"/>
</p>

## Directional+Omni Examples
```
using FEBOL

m = SearchDomain(100, 40, 70)
f = DF(m, 100)
sensor = DirOmni("norm360.csv")
sensor.stds *= 0.2
x = Vehicle(50, 50, sensor)
p = GreedyPolicy(x, 8)

gif(m,x,f,p,17)
```
<p align="center">
<img src="http://stanford.edu/~dressel/gifs/gif2.gif"/>
</p>
This example is also interesting:
<p align="center">
<img src="http://stanford.edu/~dressel/gifs/gif1.gif"/>
</p>

## FOV examples
```
using FEBOL

m = SearchDomain(100, 40, 70)
f = DF(m, 100)
f.bin_range = 0:1
region_probs = [(60.0,0.9), 70.0,0.5), (180.0,0.1)]
sensor = FOV(region_probs)
x = Vehicle(50, 50, sensor)
p = GreedyPolicy(x, 8)

gif(m,x,f,p,18)
```
<p align="center">
<img src="http://stanford.edu/~dressel/gifs/gif8.gif"/>
</p>

## TODO:

* handle observation directly over jammer
* implement particle filters
* implement centroid, variance functions
* rigorously test centroid functions
* allow user to specify degree discretization in discrete filter (also particle filter?)
* allow interpolations in plotting (instead of "none")

