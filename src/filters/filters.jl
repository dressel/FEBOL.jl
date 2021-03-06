######################################################################
# filters.jl
# Handles the different filters
######################################################################

abstract type AbstractFilter end

"""
`update!(f::AbstractFilter, p::Pose, o::Real)`

`update!(f::AbstractFilter, x::Vehicle, o::Real)`

Updates the belief of filter `f` given a vehicle `x` and observation `o`.
The observation `o` is a real number in [0,360).
If your filter requires this number to be binned into an integer, it must take care of that internally.
"""
function update!(f::AbstractFilter, x::Vehicle, o)
    update!(f, get_pose(x), o)
end

function update!(f::AbstractFilter, p::Pose, o)
    error(typeof(f), " does not yet implement update!(f,x,o).")
end

# multi vehicle update
function update!(f::AbstractFilter,vx::Vector{Vehicle}, vo::Vector{Float64})
    num_vehicles = length(vx)
    for i = 1:num_vehicles
        update!(f, vx[i], vo[i])
    end
end


"""
`centroid(f::AbstractFilter)`

Returns the centroid of the filter's belief. If the belief is a Gaussian, this will return the mean.
"""
function centroid(f::AbstractFilter)
    error(typeof(f), " does not yet implement centroid(f).")
end


"""
`covariance(f::AbstractFilter)`

Returns the covariance of the filter's belief. If the belief is a Gaussian, this will return Sigma.
"""
function covariance(f::AbstractFilter)
    error(typeof(f), " does not yet implement centroid(f).")
end


"""
`entropy(f::AbstractFilter)`

Returns the entropy of the filter's belief.
"""
function entropy(f::AbstractFilter)
    error(typeof(f), " does not yet implement entropy(f).")
end


"""
`reset!(f::AbstractFilter)`

Resets the belief of filter `f`.
"""
function reset!(f::AbstractFilter)
    error(typeof(f), " does not yet implement reset!(f).")
end


# Include the different filters
include("df.jl")
include("kalman.jl")
include("ekf.jl")
include("eif.jl")
include("ukf.jl")
include("pf.jl")
