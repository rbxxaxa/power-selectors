local PluginRoot = script.Parent.Parent
local MainManager = require(PluginRoot.Core.Modules.MainManager)
local Roact = require(PluginRoot.Libs.Roact)
local MainApp = require(PluginRoot.Core.App.MainApp)

local CoreGui = game:GetService("CoreGui")

local PluginMain = {}

function PluginMain.start(plugin)
	local mainGui = Instance.new("ScreenGui", CoreGui)

	local mainManager = MainManager.new(plugin)
	local app = Roact.createElement(MainApp, {mainManager = mainManager})
	local handle = Roact.mount(
		app, mainGui, "PowerSelectors"
	)

	plugin.Unloading:Connect(function()
		mainManager:Destroy()
		Roact.unmount(handle)
	end)
end

return PluginMain