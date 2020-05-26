local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)
local Contexts = PluginRoot.Core.App.Contexts
local MainContext = require(Contexts.MainContext)

local ContextWrapper = Roact.Component:extend("ContextWrapper")

function ContextWrapper:render()
	local props = self.props
	local mainManager = props.mainManager
	return Roact.createElement(MainContext.Controller, { mainManager = mainManager },
		props[Roact.Children]
	)
end

return ContextWrapper