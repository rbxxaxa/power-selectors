local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)
local Contexts = PluginRoot.Core.App.Contexts
local MainManagerContext = require(Contexts.MainManagerContext)

local ContextWrapper = Roact.Component:extend("ContextWrapper")

function ContextWrapper:render()
	local props = self.props
	local mainManager = props.mainManager
	return Roact.createElement(MainManagerContext.Controller, { mainManager = mainManager },
		props[Roact.Children]
	)
end

return ContextWrapper