local function create(pluginMouse, leftMouseDown)
	local x = pluginMouse.X
	local y = pluginMouse.Y
	return {
		x = x,
		y = y,
		leftMouseDown = leftMouseDown,
	}
end

local function isDifferent(a, b)
	if a == b then return false end
	return a.x ~= b.x or
		a.y ~= b.y or
		a.leftMouseDown ~= b.leftMouseDown
end

return {
	create = create,
	isDifferent = isDifferent
}