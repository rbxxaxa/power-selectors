local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)
local Contexts = PluginRoot.Core.App.Contexts
local CameraContext = require(Contexts.CameraContext)
local SettingsContext = require(Contexts.SettingsContext)
local SelectionContext = require(Contexts.SelectionContext)
local InputContext = require(Contexts.InputContext)

local ContextWrapper = Roact.Component:extend("ContextWrapper")

function ContextWrapper:render()
	local props = self.props
	local mainManager = props.mainManager
	return Roact.createElement(CameraContext.Controller, { mainManager = mainManager }, {
		Roact.createElement(SettingsContext.Controller, { mainManager = mainManager }, {
			Roact.createElement(InputContext.Controller, {mainManager = mainManager}, {
				Roact.createElement(SelectionContext.Controller, {mainManager = mainManager}, props[Roact.Children])
			})
		})
	})
end

return ContextWrapper