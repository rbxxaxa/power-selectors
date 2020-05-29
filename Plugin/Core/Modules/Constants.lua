local constants = {
	CAST_DEPTH = 0.01,
	CAST_DISTANCE = 1000,
	MOVING_SAMPLER_BUDGET = 0.5/60,
	TURBO_SAMPLER_BUDGET = 5/60,
	FRAMES_TO_SAMPLER_TURBO = 4,
	ADD_COLOR = Color3.fromRGB(136, 214, 0),
	SUBTRACT_COLOR = Color3.fromRGB(250, 51, 81),
	SELECTED_COLOR = Color3.fromRGB(43, 144, 251),
	HOVERED_COLOR = Color3.fromRGB(43, 144, 251):lerp(Color3.new(1, 1, 1), 0.5),
	SAMPLE_SPACING = 1,
	SAMPLING_GRID_SIZE = 32,
	CIRCLE_MIN_RADIUS = 4,
	CIRCLE_MAX_RADIUS = 160,
}

assert(constants.SAMPLE_SPACING%1 == 0 and constants.SAMPLE_SPACING > 0, "SAMPLE_SPACING must be a positive integer.")
assert(math.log(constants.SAMPLING_GRID_SIZE, 2)%1 == 0, "SAMPLING_GRID_SIZE must be a power of 2.")

return constants