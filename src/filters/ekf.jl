######################################################################
# ekf.jl
# handles kalman filter stuff
######################################################################

# length is size of one side of search domain
type EKF <: AbstractFilter
	mu::Vector{Float64}			# belief
	Sigma::Matrix{Float64}		# belief
	length::Float64	

	function EKF(m::SearchDomain)
		mu = m.length/2 * ones(2)
		S = 1e9 * eye(2)
		return new(mu, S, m.length)
	end
end

# have to include search domain because jammer location factors in
# Really, I should just fold that into the state
# TODO: just subtracting is not ok, need circle distance (can be negative)
function update!(ekf::EKF, x::Vehicle, o::Float64)
	xr = ekf.mu[1] - x.x
	yr = ekf.mu[2] - x.y
	if xr == 0.0 && yr === 0.0
		xr = 1e-6
		yr = 1e-6
	end
	Ht = [yr, -xr]' * (180.0 / pi) / (xr^2 + yr^2)
	Kt = ekf.Sigma * Ht' * inv(Ht * ekf.Sigma * Ht' + x.noise_sigma^2)

	o_predict = true_bearing(x, ekf.mu) 
	# Computing o - o_predict... both will be in range 0 to 360
	# Make sure this value is within -180,180
	o_diff = fit_180(o - o_predict)
	#mu_t = ekf.mu + Kt * (o - o_predict)
	mu_t = ekf.mu + Kt * o_diff
	Sigma_t = (eye(2)  - Kt * Ht) * ekf.Sigma

	# TODO: use copy here
	ekf.mu = vec(mu_t)
	ekf.Sigma = Sigma_t
end

centroid(ekf::EKF) = (ekf.mu[1], ekf.mu[2])
function reset!(f::EKF)
	f.mu = f.length/2 * ones(2)
	f.Sigma = 1e9 * eye(2)
end