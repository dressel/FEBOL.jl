######################################################################
# pf.jl
# Basic filter described in Chapter 4 of Probo Robo
######################################################################


type PF <: AbstractFilter
	n::Int    # number of particles
	X::Vector{LocTuple}
	W::Vector{Float64}
	Xnew::Vector{LocTuple}
	Wnew::Vector{Float64}
	length::Float64

	function PF(m::SearchDomain, n::Int)
		X = Array(LocTuple, n)
		for i = 1:n
			xi = m.length*rand()
			yi = m.length*rand()
			X[i] = (xi, yi)
		end
		Xnew = deepcopy(X)
		W = zeros(n)
		Wnew = zeros(n)
		return new(n, X, W, Xnew, Wnew, m.length)
	end
end

function update!(pf::PF, x::Vehicle, o::Float64)
	w_sum = 0.0
	p = (x.x, x.y, x.heading)
	for i = 1:pf.n
		# don't need to sample from transition, just calculate weights
		 #pf.W[i] = O(x, pf.X[i], o) # calculate probability of obs
		 pf.W[i] = O(x.sensor, pf.X[i], p, o) # calculate probability of obs
		 w_sum = pf.W[i]
	end

	# Due to deprecation
	# TODO: check that Weights works the same way.
	#  I think it does
	#wvec = WeightVec(pf.W)
	wvec = Weights(pf.W)

	for i = 1:pf.n
		# draw with probability
		#pf.Xnew[i] = sample(pf.X, WeightVec(pf.W))
		j = sample(wvec)
		pf.Xnew[i] = pf.X[j]
		pf.Wnew[i] = pf.W[j]
	end
	copy!(pf.X, pf.Xnew)
	copy!(pf.W, pf.Wnew)
end

function centroid(f::PF)
	wsum = 0.0
	xmean = 0.0
	ymean = 0.0
	for i = 1:f.n
		wval = f.W[i]
		xmean += f.X[i][1] * wval
		ymean += f.X[i][2] * wval
		wsum += wval
	end
	return xmean/wsum, ymean/wsum
end

function reset!(f::PF)
	for i = 1:f.n
		xi = f.length*rand()
		yi = f.length*rand()
		f.X[i] = (xi, yi)
		f.Xnew[i] = (xi, yi)
	end
	fill!(f.W, 0.0)
end
