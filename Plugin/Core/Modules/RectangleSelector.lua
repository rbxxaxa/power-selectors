local PluginRoot = script.Parent.Parent.Parent
local Modules = PluginRoot.Core.Modules
local Utilities = require(Modules.Utilities)
local CameraState = require(Modules.CameraState)
local InputState = require(Modules.InputState)
local PairSampler = require(Modules.PairSampler)
local Constants = require(Modules.Constants)
local roundUp = Utilities.roundUp
local roundDown = Utilities.roundDown

local CAST_DEPTH = Constants.CAST_DEPTH
local CAST_DISTANCE = Constants.CAST_DISTANCE
local TURBO_SAMPLER_BUDGET = Constants.TURBO_SAMPLER_BUDGET
local MOVING_SAMPLER_BUDGET = Constants.MOVING_SAMPLER_BUDGET
local FRAMES_TO_SAMPLER_TURBO = Constants.FRAMES_TO_SAMPLER_TURBO
local SAMPLE_SPACING = Constants.SAMPLE_SPACING
local SAMPLING_GRID_SIZE = Constants.SAMPLING_GRID_SIZE

local RectangleSelector = {}
RectangleSelector.__index = RectangleSelector

local DEBUG_GENERATOR = false
local DEBUG_RAYCAST = false
local DEBUG_WARN_WHEN_SAMPLER_DONE = false

local debugRectangle, debugRaycast
if DEBUG_RAYCAST or DEBUG_GENERATOR then
	local CoreGui = game:GetService("CoreGui")
	local RunService = game:GetService("RunService")
	local debugRectangleGui = Instance.new("ScreenGui")
	debugRectangleGui.Name = "DebugRectangle"
	debugRectangleGui.Parent = CoreGui

	local freePixels = {}
	local function putPixel(x, y)
		local pixel = table.remove(freePixels)
		if not pixel then
			pixel = Instance.new("Frame")
			pixel.Size = UDim2.fromOffset(SAMPLE_SPACING, SAMPLE_SPACING)
			pixel.AnchorPoint = Vector2.new(0.5, 0.5)
			pixel.BorderSizePixel = 0
		end
		pixel.BackgroundColor3 = Color3.new(1, 0, 0)
		pixel.Position = UDim2.fromOffset(x, y)
		pixel.Parent = debugRectangleGui
		coroutine.wrap(function()
			for i = 0, 10 do
				local per = i/10
				pixel.BackgroundTransparency = per
				pixel.BackgroundColor3 = Color3.new(1, 0, 0):lerp(Color3.new(0, 0, 0), per)
				RunService.Heartbeat:Wait()
			end
			pixel.Parent = nil
			table.insert(freePixels, pixel)
		end)()
	end

	function debugRectangle(x, y)
		putPixel(x, y)
	end

	function debugRaycast(x, y)
		putPixel(x, y)
	end
end

--[[
	A sequence of indices in a SAMPLING_GRID_SIZE x SAMPLING_GRID_SIZE grid (0 to SAMPLING_GRID_SIZE^2-1).
	Pattern looks like this when you iterate through it (assuming SAMPLING_GRID_SIZE is 8):

	i = 1
	x_______
	________
	________
	________
	________
	________
	________
	________

	i = 4
	x___x___
	________
	________
	________
	x___x___
	________
	________
	________

	i = 16
	x_x_x_x_
	________
	x_x_x_x_
	________
	x_x_x_x_
	________
	x_x_x_x_
	________

	i = 64
	xxxxxxxx
	xxxxxxxx
	xxxxxxxx
	xxxxxxxx
	xxxxxxxx
	xxxxxxxx
	xxxxxxxx
	xxxxxxxx

	As you can see, the indices are ordered such that iterating through them results in
	a pattern that gets more and more granular.
	This is also the reason why SAMPLING_GRID_SIZE must be a power of 2.
]]
local gridTraversalOrder do
	gridTraversalOrder = {}

	local alreadyVisited = {}
	local fac = SAMPLING_GRID_SIZE
	while fac >= 1 do
		for y = 0, SAMPLING_GRID_SIZE-1 do
			for x = 0, SAMPLING_GRID_SIZE-1 do
				if x%fac == 0 and y%fac == 0 then
					local i = x + y*SAMPLING_GRID_SIZE
					if not alreadyVisited[i] then
						table.insert(gridTraversalOrder, i)
						alreadyVisited[i] = true
					end
				end
			end
		end
		fac = fac/2
	end
end

local function createRectangleGenerator(topLeftX, topLeftY, bottomRightX, bottomRightY)
	local generator = coroutine.wrap(function()
		local minY = roundDown(topLeftY, SAMPLE_SPACING)
		local maxY = roundUp(bottomRightY, SAMPLE_SPACING)
		local minX = roundDown(topLeftX, SAMPLE_SPACING)
		local maxX = roundUp(bottomRightX, SAMPLE_SPACING)
		for _, i in ipairs(gridTraversalOrder) do
			local xOffset = (i%SAMPLING_GRID_SIZE) * SAMPLE_SPACING
			local yOffset = math.floor(i/SAMPLING_GRID_SIZE) * SAMPLE_SPACING
			for y = minY+yOffset, maxY, SAMPLE_SPACING*SAMPLING_GRID_SIZE do
				for x = minX+xOffset, maxX, SAMPLE_SPACING*SAMPLING_GRID_SIZE do
			if DEBUG_GENERATOR then
			debugRectangle(x, y)
			end
			coroutine.yield(x, y)
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

	local raycastParams = RaycastParams.new()
	local ignoreList = {}
	raycastParams.FilterDescendantsInstances = ignoreList
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	return function(x, y)
		local origin = topLeft + widthVec * x / width + heightVec * y / height
		local dir = (origin - position).unit * CAST_DISTANCE

		local hit
		while true do
			local result = workspace:Raycast(origin, dir, raycastParams)
			if result == nil then
				break
			end
			hit = result.Instance
			if hit and hit.Transparency == 1 then
				table.insert(ignoreList, hit)
				raycastParams.FilterDescendantsInstances = ignoreList
			else
				break
			end
		end
		if hit and not hit.Locked then
			return { hit }
		else
			return {}
		end
	end
end

function RectangleSelector.new(initialCameraState, initialInputState)
	local self = {}
	setmetatable(self, RectangleSelector)

	self.committed = false
	self.cameraState = initialCameraState
	self.inputState = initialInputState
	self.started = false
	self.startX = nil
	self.startY = nil
	self:_resetPending()
	self:_resetSampleCache()
	self:_resetSampler()
	self:_updateCursorInfo()

	return self
end

function RectangleSelector:_resetSampleCache()
	self.alreadySampled = {}
	self.sampleCache = {}
end

function RectangleSelector:_resetSampler()
	if not self.started then
	self.sampler = nil
	return
	end

	self.raycaster = createRaycastCallback(self.cameraState)
	local topLeftX = math.min(self.startX, self.inputState.x)
	local topLeftY = math.min(self.startY, self.inputState.y)
	local bottomRightX = math.max(self.startX, self.inputState.x)
	local bottomRightY = math.max(self.startY, self.inputState.y)
	self.rectangleGen = createRectangleGenerator(topLeftX, topLeftY, bottomRightX, bottomRightY)
	self.sampler = PairSampler.create(
		self.alreadySampled,
		self.sampleCache,
		self.rectangleGen,
		function(x, y)
			if DEBUG_RAYCAST then
				debugRaycast(x, y)
			end
			local hit = self.raycaster(x, y)
			return hit
		end
	)
	self.samplerRunningFrames = 0
	self.isSamplerDone = false
end

function RectangleSelector:_calculateSamplerBudget()
	if self.samplerRunningFrames > FRAMES_TO_SAMPLER_TURBO then
		return TURBO_SAMPLER_BUDGET
	else
		return MOVING_SAMPLER_BUDGET
	end
end

function RectangleSelector:step(cameraState, inputState)
	if CameraState.isDifferent(self.cameraState, cameraState) then
		local oldCameraState = self.cameraState
		self.cameraState = cameraState
		self:_onCameraStateChanged(cameraState, oldCameraState)
	end

	if InputState.isDifferent(self.inputState, inputState) then
		local oldInputState = self.inputState
		self.inputState = inputState
		self:_onInputStateChanged(inputState, oldInputState)
	end

	if self.committed or not self.started then
		return
	end

	local timeStartedSampling = tick()
	local mouseDown = inputState.leftMouseDown
	local pendingToAdd = {}
	local samplerBudget = self:_calculateSamplerBudget()
	debug.profilebegin("RectangleSelector, step sample")
	while not self.isSamplerDone do
		local cached, hits = self.sampler()
		if cached == nil then
			self.isSamplerDone = true
			if DEBUG_WARN_WHEN_SAMPLER_DONE then
				warn("Sampler done.")
			end
			break
		end

		for _, hit in pairs(hits) do
			if mouseDown then
				if not self.pendingSet[hit] then
					self.pendingSet[hit] = true
					table.insert(pendingToAdd, hit)
				end
			end
		end

		local timeSpentSampling = tick() - timeStartedSampling
		if timeSpentSampling > samplerBudget then
			break
		end
	end
	debug.profileend()

	debug.profilebegin("RectangleSelector, step tables")
	local updated = false
	if #pendingToAdd > 0 then
		table.move(self.pending, 1, #self.pending, #pendingToAdd+1, pendingToAdd)
		local newPending = pendingToAdd
	self.pending = newPending
		updated = true
	end
	debug.profileend()

	self.samplerRunningFrames = self.samplerRunningFrames+1

	return updated
end

function RectangleSelector:_onCameraStateChanged(newCameraState, oldCameraState)
	if self.committed then return end

	self:_resetPending()
	self:_resetSampleCache()
	self:_resetSampler()
end

function RectangleSelector:_onInputStateChanged(newInputState, oldInputState)
	if self.committed then return end

	local wasMouseDown = oldInputState.leftMouseDown
	local isMouseDown = newInputState.leftMouseDown
	if self.started then
		if not isMouseDown and wasMouseDown then
			self.committed = true
		end
	else
		if isMouseDown and not wasMouseDown then
			self.started = true
			self.startX = newInputState.x
			self.startY = newInputState.y
		end
	end

	if self.committed then return end

	self:_resetPending()
	self:_resetSampler()
	self:_updateCursorInfo()
end

function RectangleSelector:_updateCursorInfo()
	self.cursorInfo = {
		started = self.started,
		startX = self.startX,
		startY = self.startY,
		x = self.inputState.x,
		y = self.inputState.y,
	}
end

function RectangleSelector:getCursorInfo()
	return self.cursorInfo
end

function RectangleSelector:getPending()
	return self.pending
end

function RectangleSelector:getHovered()
	return nil
end

function RectangleSelector:_resetPending()
	if self.pendingSet and next(self.pendingSet) == nil then return end

	self.pending = {}
	self.pendingSet = {}
end

function RectangleSelector:isCommitted()
	return self.committed
end

function RectangleSelector:destroy()
end

return RectangleSelector