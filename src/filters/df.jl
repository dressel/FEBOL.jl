######################################################################
# df.jl
# Discrete filters
######################################################################

# n is the number of cells per side
# cell_size is size of a single cell
type DF <: AbstractFilter
	b::Matrix{Float64}
	n::Int64
	cell_size::Float64
	num_bins::Int64
	bin_range::UnitRange{Int64}

	function DF(m::SearchDomain, n::Int64, num_bins::Int64=36)
		b = ones(n, n) / (n * n)
		return new(b, n, m.length/n, num_bins, 0:(num_bins-1))
	end
	function DF(m::SearchDomain, n::Int64, bin_range::UnitRange{Int64})
		b = ones(n, n) / (n * n)
		num_bins = length(bin_range)
		return new(b, n, m.length/n, num_bins, bin_range)
	end
end

# TODO: I think this can be made faster by checking that df.b[xj,yj] > 0
function update!(df::DF, x::Vehicle, o::Float64)
	ob = obs2bin(o, df, x.sensor)
	num_cells = df.n
	bp_sum = 0.0

	for theta_x = 1:num_cells
		for theta_y = 1:num_cells
			# convert grid cell number to actual location
			if df.b[theta_x, theta_y] > 0.0
				tx = (theta_x-1) * df.cell_size + df.cell_size/2.0
				ty = (theta_y-1) * df.cell_size + df.cell_size/2.0
				df.b[theta_x, theta_y] *= O(x, (tx, ty), ob, df)
				bp_sum += df.b[theta_x, theta_y]
			end
		end
	end

	# normalize
	for theta_x = 1:num_cells
		for theta_y = 1:num_cells
			df.b[theta_x, theta_y] /= bp_sum
		end
	end
end


# returns x, y value
function centroid(df::DF)
	x_val = 0.0; y_val = 0.0
	x_sum = 0.0; y_sum = 0.0
	for x = 1:df.n
		for y = 1:df.n
			x_val += (x-.5) * df.b[x,y]
			x_sum += df.b[x,y]
			y_val += (y-.5) * df.b[x,y]
			y_sum += df.b[x,y]
		end
	end
	return x_val*df.cell_size / x_sum, y_val*df.cell_size / y_sum
end


# Returns the entropy of the distribution.
# Could just borrow this from Distributions.jl
function entropy(df::DF)
	ent = 0.0
	for xj = 1:df.n
		for yj = 1:df.n
			prob = df.b[xj,yj]
			if prob > 0.0
				ent -= prob*log(prob)
			end
		end
	end
	return ent / log(df.n * df.n)
end


reset!(f::DF) = fill!(f.b, 1.0/(f.n*f.n))


######################################################################
# Functions required for O()
######################################################################

"""
`O(m::SearchDomain, x::Vehicle, theta, o::ObsBin)`

Arguments:

 * `m` is a `SearchDomain`
 * `x` is a `Vehicle`
 * `theta` is a possible jammer location
 * `o` is an observation, 0 to 35

Returns probability of observing `o` from `(xp, theta)` in domain `m`.
"""
function O(x::Vehicle, theta::LocTuple, o::ObsBin, df::DF)
	return O(x, (x.x, x.y, x.heading), theta, o, df)
end

function O(x::Vehicle, xp::Pose, theta::LocTuple, o::ObsBin, df::DF)
	return O(x, x.sensor, xp, theta, o, df)
end

function O(x::Vehicle, s::BearingOnly, xp::Pose, theta::LocTuple, o::ObsBin, df::DF)

	# Calculate true bearing, and find distance to bin edges
	ang_deg = true_bearing(xp, theta)
	rel_start, rel_end = rel_bin_edges(ang_deg, o, df)

	# now look at probability
	d = Normal(0, x.sensor.noise_sigma)
	p = cdf(d, rel_end) - cdf(d, rel_start)
	return p
end

function O(x::Vehicle, s::DirOmni, xp::Pose, theta::LocTuple, o::ObsBin, df::DF)
	rel_bearing = x.heading - true_bearing(xp, theta)
	if rel_bearing < 0.0
		rel_bearing += 360.0
	end
	rel_int = round(Int, rel_bearing, RoundDown) + 1

	low_val = floor(o)
	high_val = low_val + 1
	d = Normal(s.means[rel_int], s.stds[rel_int])
	p = cdf(d, high_val) - cdf(d, low_val)
	return p
end





# 355 - 4.9999 = 0
# 5 - 14.9999 = 1
# 15 - 24.999 = 2
function obs2bin(o::Float64, df::DF, s::BearingOnly)
	full_bin = 360.0 / df.num_bins
	half_bin = full_bin / 2.0

	ob = round( Int, div((o + half_bin), full_bin) )
	if ob == df.num_bins
		ob = 0
	end
	return ob
end

# here, num_bins isn't too important; we just bin to nearest integer
obs2bin(o::Float64, df::DF, s::DirOmni) = round(Int, o, RoundDown)


# returns (start_deg, end_deg) integer tuple
function bin2deg(bin_deg::Int, df::DF)
	full_bin = 360.0 / df.num_bins
	half_bin = full_bin / 2.0
	if bin_deg == 0
		start_val = -half_bin
		end_val = half_bin
	else
		start_val = full_bin * bin_deg - half_bin
		end_val  = full_bin * bin_deg + half_bin
	end
	return start_val, end_val
end

# Find the relative offset
# TODO: must account for different discretizations
function rel_bin_edges(bearing_deg, o::ObsBin, df::DF)

	# calculate start, end degrees of bin
	start_deg, end_deg = bin2deg(o, df)

	# compute relative distance to true bearing
	rel_start = fit_180(bearing_deg - start_deg)
	rel_end = fit_180(bearing_deg - end_deg)

	#rel_start = min(abs(rel_start), abs(rel_end))
	#rel_end = rel_start + 360.0 / df.num_bins

	# Make sure start is further left on number line
	if rel_end < rel_start
		temp = rel_start
		rel_start = rel_end
		rel_end = temp
	end

	# If we straddle the wrong point
	# Say df.num_bins = 10, and rel_start = -175, rel_end = 175
	# rel_end - rel_start would be 350 degrees, but this should be 10
	# so set rel_start to 175 and rel_end to 185
	# TODO: I'm pretty sure this doesn't work for df.num_bins = 2
	if (rel_end - rel_start) - 1e-3 > (360.0/df.num_bins)
		rel_start = rel_end
		rel_end += 360.0/df.num_bins
	end

	return rel_start, rel_end
end

function noiseless(x::Vehicle, theta::LocTuple)
	noiseless(x, x.sensor, theta)
end
function noiseless(x::Vehicle, s::BearingOnly, theta::LocTuple)
	true_bearing(x, theta)
end
function noiseless(x::Vehicle, s::DirOmni, theta::LocTuple)
	rel_bearing = x.heading - true_bearing(x, theta)
	if rel_bearing < 0.0
		rel_bearing += 360.0
	end
	rel_int = round(Int, rel_bearing, RoundDown) + 1

	return s.means[rel_int]
end
