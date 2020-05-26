local PluginRoot = script.Parent.Parent.Parent
local Core = PluginRoot.Core
local InputState = require(Core.Modules.InputState)
local CameraState = require(Core.Modules.CameraState)
local Libs = PluginRoot.Libs
local Maid = require(Libs.Maid)
local CircleSelector = require(Core.Modules.CircleSelector)

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
		circleSelectRadius = 100,
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
	end

	if updated then
		self.mainEvent:Fire()
	end
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
		self.selector = CircleSelector.new(self.settings.circleSelectRadius, self.cameraState, self.inputState)
	end

	self.mainEvent:Fire()
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