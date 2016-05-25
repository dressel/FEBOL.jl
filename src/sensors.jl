######################################################################
# sensors.jl
######################################################################

abstract Sensor

type BearingOnly <: Sensor
	noise_sigma::Float64
end

type DirOmni <: Sensor
	means::Vector{Float64}
	stds::Vector{Float64}

	function DirOmni(file::AbstractString)
		means = vec(readcsv(file)[:,2])
		stds = ones(360)
		return new(means, stds)
	end
end


# Takes a vector of 36 angles and turns it into 360 via linear interpolation
function makenorm()
	data = readcsv("norm.csv")
	values = vec(data[:,2])
	new_values = zeros(360)
	for i = 1:35
		val_start = 10*(i-1)+1
		new_values[val_start] = values[i]
		for j = 1:9
			new_values[val_start + j] = (10.0-j)*values[i] + j*values[i+1]
			new_values[val_start + j] /= 10.0
		end
	end
	# now handle the last one
	i = 36
	val_start = 10*(i-1)+1
	new_values[val_start] = values[i]
	for j = 1:9
		new_values[val_start + j] = (10.0-j)*values[i] + j*values[1]
		new_values[val_start + j] /= 10.0
	end
	return new_values
end