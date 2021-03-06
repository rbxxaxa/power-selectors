local function round(n, multiple)
	multiple = multiple or 1
	return math.floor(n/multiple + 0.5) * multiple
end

local function roundDown(n, multiple)
	multiple = multiple or 1
	return math.floor(n/multiple) * multiple
end

local function roundUp(n, multiple)
	multiple = multiple or 1
	return math.floor(n/multiple + 1) * multiple
end

local function lerp(a, b, t)
	return a * (1-t) + b * t
end

return {
	round = round,
	roundDown = roundDown,
	roundUp = roundUp,
	lerp = lerp,
}