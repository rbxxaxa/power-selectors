local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)
local App = PluginRoot.Core.App
local Contexts = App.Contexts
local MainContext = require(Contexts.MainContext)
local Components = App.Components
local CircleMarquee = require(Components.CircleMarquee)
local SelectorHighlights = require(Components.SelectorHighlights)
local ConfigBox = require(Components.ConfigBox)

local CircleSelectorView = Roact.PureComponent:extend("CircleSelectorView")

function CircleSelectorView:render()
	return MainContext.withContext(function(mainContext)
		local mainManager = mainContext.mainManager
		if mainManager:getMode() ~= "circle" then return end
		local settings = mainManager:getSettings()
		local selector = mainManager:getSelector()
		local cursorInfo = selector:getCursorInfo()

		local children = {}
		children.circleMarquee = Roact.createElement(CircleMarquee, {
			position = UDim2.fromOffset(cursorInfo.x, cursorInfo.y),
			radius = settings.circleRadius,
		})

		children.selectorHighlights = Roact.createElement(SelectorHighlights, {
			hovered = selector:getHovered(),
			pending = selector:getPending(),
			selected = mainManager:getCurrentSelection(),
			operation = settings.operation,
		})

		local mouse = mainManager:getPlugin():GetMouse()
		mouse.Icon = "rbxasset://SystemCursors/Cross"

		children.Config = Roact.createElement(ConfigBox, {
			title = "Circle Selector",
		})

		return Roact.createFragment(children)
	end)
end

return CircleSelectorView