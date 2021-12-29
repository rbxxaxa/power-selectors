local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)
local App = PluginRoot.Core.App
local Contexts = App.Contexts
local MainContext = require(Contexts.MainContext)
local Components = App.Components
local RectangleMarquee = require(Components.RectangleMarquee)
local SelectorHighlights = require(Components.SelectorHighlights)
local ConfigBox = require(Components.ConfigBox)

local RectangleSelectorView = Roact.PureComponent:extend("RectangleSelectorView")

function RectangleSelectorView:render()
	return MainContext.withContext(function(mainContext)
		local mainManager = mainContext.mainManager
		if mainManager:getMode() ~= "rectangle" then return end
		local settings = mainManager:getSettings()
		local selector = mainManager:getSelector()
		local cursorInfo = selector:getCursorInfo()

		local children = {}
		if cursorInfo.started then
			children.rectangleMarquee = Roact.createElement(RectangleMarquee, {
				position = UDim2.fromOffset(cursorInfo.startX, cursorInfo.startY),
				size = UDim2.fromOffset(cursorInfo.x - cursorInfo.startX, cursorInfo.y - cursorInfo.startY)
			})
		end
		children.selectorHighlights = Roact.createElement(SelectorHighlights, {
			hovered = selector:getHovered() or {},
			pending = selector:getPending(),
			selected = mainManager:getCurrentSelection(),
			operation = settings.operation,
		})

		local mouse = mainManager:getPlugin():GetMouse()
		mouse.Icon = "rbxasset://SystemCursors/Cross"

		children.Config = Roact.createElement(ConfigBox, {
			title = "Rectangle Selector",
		})

		return Roact.createFragment(children)
	end)
end

return RectangleSelectorView