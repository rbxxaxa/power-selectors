local function create(camera)
	local cf = camera.CFrame
	local viewportSize = camera.ViewportSize
	return { 
		position = cf.Position,
		look = cf.LookVector,
		up = cf.UpVector,
		right = cf.RightVector,
		fov = camera.FieldOfView,
		viewportX = viewportSize.X,
		viewportY = viewportSize.Y
	}
end

local function isDifferent(a, b)
	if a == b then return false end
	return a.position ~= b.position or
		a.look ~= b.look or
		a.up ~= b.up or
		a.right ~= b.right or
		a.fov ~= b.fov or
		a.viewportX ~= b.viewportX or
		a.viewportY ~= b.viewportY
end

return {
	create = create,
	isDifferent = isDifferent
}