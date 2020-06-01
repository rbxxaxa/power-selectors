local PluginRoot = script.Parent.Parent.Parent
local Core = PluginRoot.Core
local Modules = Core.Modules
local InputState = require(Modules.InputState)
local CameraState = require(Modules.CameraState)
local Constants = require(Modules.Constants)
local CircleSelector = require(Modules.CircleSelector)
local Libs = PluginRoot.Libs
local Maid = require(Libs.Maid)
local Oyrc = require(Libs.Oyrc)

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local CurrentCamera = workspace.CurrentCamera

local MainManager = {}
MainManager.__index = MainManager

function MainManager.new(plugin)
	local self = {}
	setmetatable(self, MainManager)

	self.maid = Maid.new()
	self.mode = "none"

	local mouse = plugin:GetMouse()
	self.mouse = mouse

	self.plugin = plugin
	local toolbar = plugin:CreateToolbar("Power Selectors")
	self.maid:GiveTask(toolbar)

	local circleSelectButton = toolbar:CreateButton("Circle Select", "Toggle Circle Select", "")
	circleSelectButton.Click:Connect(function()
		if self.mode ~= "circle" then
			self:activate("circle")
		else
			self:deactivate()
		end
	end)
	self.circleSelectButton = circleSelectButton

	self.mainEvent = Instance.new("BindableEvent")
	self.maid:GiveTask(self.mainEvent)
	self.settings = {
		circleRadius = 100,
		operation = "add"
	}
	self.cameraState = self:_calculateCurrentCameraState()
	self.inputState = self:_calculateCurrentInputState()
	self.selector = nil

	self.maid:GiveTask(RunService.Heartbeat:Connect(function(dt)
		debug.profilebegin("PowerSelector, MainManager::step")
		self:_step(dt)
		debug.profileend()
	end))

	self.maid:GiveTask(Selection.SelectionChanged:Connect(function()
		self.cachedSelection = nil
	end))

	self.maid:GiveTask(UserInputService.InputChanged:Connect(function(inputObject, gameProcessedEvent)
		if gameProcessedEvent then return end
		if self.mode == "circle" and inputObject.UserInputType == Enum.UserInputType.MouseWheel and
			inputObject:IsModifierKeyDown(Enum.ModifierKey.Ctrl) then

			local newRadius
			if inputObject.Position.Z > 0 then
				newRadius = math.clamp(self.settings.circleRadius * 0.9, Constants.CIRCLE_MIN_RADIUS, Constants.CIRCLE_MAX_RADIUS)
			else
				newRadius = math.clamp(self.settings.circleRadius * 1.11, Constants.CIRCLE_MIN_RADIUS, Constants.CIRCLE_MAX_RADIUS)
			end
			if newRadius ~= self.settings.circleRadius then
				self.settings.circleRadius = newRadius
				self.selector:setRadius(self.settings.circleRadius)
				self.mainEvent:Fire()
			end
		end
	end))

	self.maid:GiveTask(UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
		if gameProcessedEvent then return end
		if inputObject.UserInputType == Enum.UserInputType.Keyboard then
			local keyCode = inputObject.KeyCode
			if keyCode == Enum.KeyCode.LeftShift and not inputObject:IsModifierKeyDown(Enum.ModifierKey.Ctrl) and
				self.mode ~= "none" then

				self.settings.operation = self.settings.operation == "add" and "subtract" or "add"
				self:_resetSelector()
				self.mainEvent:Fire()
			elseif keyCode == Enum.KeyCode.C then
				if inputObject:IsModifierKeyDown(Enum.ModifierKey.Shift) and
					inputObject:IsModifierKeyDown(Enum.ModifierKey.Ctrl) then

					if self.mode == "none" then
						self:activate("circle")
					end
				end
			end
		end
	end))

	plugin.Deactivation:Connect(function()
		self.selector = nil
		self.mode = "none"

		self.mainEvent:Fire()
	end)

	return self
end

function MainManager:_step(dt)
	local updated = false
	local currentCameraState = self:_calculateCurrentCameraState()
	if CameraState.isDifferent(self.cameraState, currentCameraState) then
		self.cameraState = currentCameraState
		updated = true
	end
	local currentInputState = self:_calculateCurrentInputState()
	if InputState.isDifferent(self.inputState, currentInputState) then
		self.inputState = currentInputState
		updated = true
	end
	if self.selector then
		updated = self.selector:step(self.cameraState, self.inputState) or updated
		if self.selector:isCommitted() then
			local pending = self.selector:getPending()
			if self.settings.operation == "add" then
				self:addToSelection(pending)
			else
				self:removeFromSelection(pending)
			end
			self:_resetSelector()
			updated = true
		end
	end

	if updated then
		self.mainEvent:Fire()
	end
end

function MainManager:addToSelection(parts)
	if #parts == 0 then return end

	local addSet = Oyrc.List.toSet(parts)
	for _, part in pairs(self:getCurrentSelection()) do
		addSet[part] = nil
	end

	if next(addSet) == nil then
		return
	end

	local newSelection = Oyrc.List.join(self:getCurrentSelection(), Oyrc.Dictionary.keys(addSet))
	Selection:Set(newSelection)
end

function MainManager:removeFromSelection(parts)
	if #parts == 0 then return end

	local currentParts = Oyrc.List.toSet(self:getCurrentSelection())
	local changed = false
	for _, part in pairs(parts) do
		if currentParts[part] then
			changed = true
			currentParts[part] = nil
		end
	end

	if not changed then
		return
	end

	local newSelection = Oyrc.Dictionary.keys(currentParts)
	Selection:Set(newSelection)
end

function MainManager:_calculateCurrentInputState()
	return InputState.create(
		self.mouse,
		UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
	)
end

function MainManager:_calculateCurrentCameraState()
	return CameraState.create(CurrentCamera)
end

function MainManager:activate(mode)
	self.mode = mode
	self.plugin:Activate(true)
	if mode == "circle" then
		self.selector = self:_createSelector("circle")
	end

	self.mainEvent:Fire()
end

function MainManager:_createSelector(selectorType)
	if selectorType == "circle" then
		return CircleSelector.new(self.settings.circleRadius, self.cameraState, self.inputState)
	end
end

function MainManager:_resetSelector()
	local mode = self.mode
	assert(self.mode ~= "none")
	if mode == "circle" then
		self.selector = self:_createSelector("circle")
	end
end

function MainManager:deactivate()
	self.plugin:Deactivate()
end

function MainManager:getInputState()
	return self.inputState
end

function MainManager:getCameraState()
	return self.cameraState
end

function MainManager:subscribe(callback)
	local connection = self.mainEvent.Event:Connect(callback)
	return function()
		connection:Disconnect()
	end
end

function MainManager:_onCameraStateChanged(newCameraState)
	self.cameraState = newCameraState

	self.mainEvent:Fire()
end

function MainManager:_onInputStateChanged(newInputState)
	self.inputState = newInputState

	self.mainEvent:Fire()
end

function MainManager:Destroy()
	self.maid:Destroy()
end

function MainManager:getCurrentSelection()
	if self.cachedSelection == nil then
		self.cachedSelection = Selection:Get()
	end

	return self.cachedSelection
end

function MainManager:getMode()
	return self.mode
end

function MainManager:getSettings()
	return self.settings
end

function MainManager:getSelector()
	return self.selector
end

return MainManager