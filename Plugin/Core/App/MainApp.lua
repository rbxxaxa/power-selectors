local PluginRoot = script.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)
local App = PluginRoot.Core.App
local Contexts = App.Contexts
local ContextWrapper = require(Contexts.ContextWrapper)
local Components = App.Components
local CircleSelectorView = require(Components.CircleSelectorView)

local MainApp = Roact.Component:extend("MainApp")

function MainApp:render()
	local mainManager = self.props.mainManager
	return Roact.createElement(ContextWrapper, { mainManager = mainManager }, {
		CircleSelectorView = Roact.createElement(CircleSelectorView)
	})
end

return MainApp