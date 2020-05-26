local PluginRoot = script.Parent.Parent.Parent
local Modules = PluginRoot.Core.Modules
local Utilities = require(Modules.Utilities)
local CameraState = require(Modules.CameraState)
local InputState = require(Modules.InputState)
local PairSampler = require(Modules.PairSampler)
local Constants = require(Modules.Constants)
local Cryo = require(PluginRoot.Libs.Cryo)
local roundUp = Utilities.roundUp
local roundDown = Utilities.roundDown

local CAST_DEPTH = Constants.CAST_DEPTH
local CAST_DISTANCE = Constants.CAST_DISTANCE
local CAST_BUDGET = Constants.CAST_BUDGET
local GRID_SIZE = Constants.GRID_SIZE
local SUPER_GRID_SIZE = Constants.SUPER_GRID_SIZE

local CircleSelector = {}
CircleSelector.__index = CircleSelector

local DEBUG_CIRCLE_GENERATOR = false
local DEBUG_RAYCAST = false

local debugCircle, debugRaycast do
	local CoreGui = game:GetService("CoreGui")
	local RunService = game:GetService("RunService")
	local debugCircleGui = Instance.new("ScreenGui")
	debugCircleGui.Name = "DebugCircle"
	debugCircleGui.Parent = CoreGui

	local freePixels = {}
	local function putPixel(x, y)
		local pixel = table.remove(freePixels)
		if not pixel then
			pixel = Instance.new("Frame")
			pixel.Size = UDim2.fromOffset(1, 1)
			pixel.AnchorPoint = Vector2.new(0.5, 0.5)
			pixel.BorderSizePixel = 0
			pixel.BackgroundColor3 = Color3.new(1, 0, 0)
		end
		pixel.Position = UDim2.fromOffset(x, y)
		pixel.Parent = debugCircleGui
		coroutine.wrap(function()
			for i = 0, 10 do
				pixel.BackgroundTransparency = i/10
				RunService.Heartbeat:Wait()
			end
			pixel.Parent = nil
			table.insert(freePixels, pixel)
		end)()
	end

	function debugCircle(x, y)
		putPixel(x, y)
	end

	function debugRaycast(x, y)
		putPixel(x, y)
	end
end

local function createCircleGenerator(centerX, centerY, radius, gridSize)
	local generator = coroutine.wrap(function()
		local radiusSquared = radius * radius

		local minY = roundDown(centerY - radius, gridSize)
		local maxY = roundUp(centerY + radius, gridSize)
		local minX = roundDown(centerX - radius, gridSize)
		local maxX = roundUp(centerX + radius, gridSize)
		for i = 0, SUPER_GRID_SIZE*SUPER_GRID_SIZE-1 do
			local xOffset = (i%SUPER_GRID_SIZE) * GRID_SIZE
			local yOffset = math.floor(i/SUPER_GRID_SIZE) * GRID_SIZE
			for y = minY+yOffset, maxY, gridSize*4 do
				for x = minX+xOffset, maxX, gridSize*4 do
					local distSquared = (x - centerX) ^ 2 + (y - centerY) ^ 2
					if distSquared < radiusSquared then
						if DEBUG_CIRCLE_GENERATOR then
							debugCircle(x, y)
						end
						coroutine.yield(x, y)
					end
				end
			end
		end

		return
	end)

	return generator
end

local function createRaycastCallback(cameraState)
	local width = cameraState.viewportX
	local height = cameraState.viewportY
	local worldHeight = math.tan(math.rad(cameraState.fov / 2)) * CAST_DEPTH * 2
	local worldWidth = (width / height) * worldHeight
	local down = -cameraState.up
	local right = cameraState.right
	local look = cameraState.look
	local position = cameraState.position
	local topLeft = position + (look * CAST_DEPTH) + right * worldWidth * -0.5 + down * worldHeight * -0.5
	local widthVec = right * worldWidth
	local heightVec = down * worldHeight

	return function(x, y)
		local origin = topLeft + widthVec * x / width + heightVec * y / height
		local dir = (origin - position).unit * CAST_DISTANCE
		local ray = Ray.new(origin, dir)

		local hit = workspace:FindPartOnRay(ray)
		if hit and not hit.Locked then
			return hit
		end
	end
end

function CircleSelector.new(initialRadius, initialCameraState, initialInputState)
	local self = {}
	setmetatable(self, CircleSelector)

	self.radius = initialRadius
	self.cameraState = initialCameraState
	self.inputState = initialInputState
	self:_resetPending()
	self:_resetHovered()
	self:_resetSampleCache()
	self:_resetSampler()

	return self
end

function CircleSelector:_resetSampleCache()
	self.alreadySampled = {}
	self.sampleCache = {}
end

function CircleSelector:_resetSampler()
	self.raycaster = createRaycastCallback(self.cameraState)
	self.circleGen = createCircleGenerator(self.inputState.x, self.inputState.y, self.radius, GRID_SIZE)
	self.sampler = PairSampler.create(
		self.alreadySampled,
		self.sampleCache,
		self.circleGen,
		function(x, y)
			if DEBUG_RAYCAST then
				debugRaycast(x, y)
			end
			local hit = self.raycaster(x, y)
			return hit
		end
	)
	self.isSamplerDone = false
end

function CircleSelector:step(cameraState, inputState)
	local lastHovered = self.hovered
	if CameraState.isDifferent(self.cameraState, cameraState) then
		self.cameraState = cameraState
		self.inputState = inputState
		self:_resetSampleCache()
		self:_resetSampler()
		self:_resetHovered()
	elseif InputState.isDifferent(self.inputState, inputState) then
		self.inputState = inputState
		self:_resetSampler()
		self:_resetHovered()
	end

	local castTime = 0
	local mouseDown = inputState.leftMouseDown
	local updated = false
	local pendingToAdd, hoveredToAdd = {}, {}
	debug.profilebegin("CircleSelector, step sample")
	while not self.isSamplerDone do
		local start = tick()
		local cached, hit = self.sampler()
		if cached == nil then
			self.isSamplerDone = true
			break
		end
		if not cached then
			castTime = castTime + tick() - start
		end

		if hit then
			if mouseDown then
				if not self.pendingSet[hit] then
					self.pendingSet[hit] = true
					table.insert(pendingToAdd, hit)
				end
			end
			if not self.pendingSet[hit] and not self.hoveredSet[hit] then
				self.hoveredSet[hit] = true
				table.insert(hoveredToAdd, hit)
			end
			updated = true
		end

		if castTime > CAST_BUDGET then
			break
		end
	end
	debug.profileend()

	debug.profilebegin("CircleSelector, step tables")
	if #pendingToAdd > 0 then
		table.move(self.pending, 1, #self.pending, #pendingToAdd+1, pendingToAdd)
		local newPending = pendingToAdd
		self.pending = newPending
	end

	if #hoveredToAdd > 0 then
		table.move(self.hovered, 1, #self.hovered, #hoveredToAdd+1, hoveredToAdd)
		local newHovered = hoveredToAdd
		if #lastHovered ~= #newHovered then
			self.hovered = newHovered
		else
			local newHoveredSet = Cryo.List.toSet(newHovered)
			local hoveredChanged = false
			for _, part in pairs(lastHovered) do
				if newHoveredSet[part] == nil then
					hoveredChanged = true
					break
				end
				newHoveredSet[part] = nil
			end
			if next(newHoveredSet) then
				hoveredChanged = true
			end
			if hoveredChanged then
				self.hovered = newHovered
			else
				self.hovered = lastHovered
			end
		end
	end
	debug.profileend()

	return updated
end

function CircleSelector:getPending()
	return self.pending
end

function CircleSelector:getHovered()
	return self.hovered
end

function CircleSelector:_resetPending()
	if self.pendingSet and next(self.pendingSet) == nil then return end

	self.pending = {}
	self.pendingSet = {}
end

function CircleSelector:_resetHovered()
	if self.hoveredSet and next(self.hoveredSet) == nil then return end

	self.hovered = {}
	self.hoveredSet = {}
end

function CircleSelector:clear()
	self:_resetSampleCache()
	self:_resetSampler()
	self:_resetPending()
	self:_resetHovered()
end

function CircleSelector:destroy()
end

return CircleSelector