local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)
local App = PluginRoot.Core.App
local Contexts = App.Contexts
local MainContext = require(Contexts.MainContext)
local Components = App.Components
local RectangleMarquee = require(Components.RectangleMarquee)
local SelectorHighlights = require(Components.SelectorHighlights)

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

		children.hint = Roact.createElement("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 24),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 0.5,
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
		}, {
			Roact.createElement("TextLabel", {
				Text = "<b>Rectangle Select:</b> Drag across the screen to select parts. Hold <b>Shift</b> to remove parts from the current selection. Activate Rectangle Select again to stop.",
				RichText = true,
				Size = UDim2.new(1, 0, 0, 16),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				TextSize = 16,
				TextWrapped = true,
				Font = Enum.Font.SourceSans,
				TextColor3 = Color3.new(1, 1, 1),
				TextStrokeTransparency = 0,
				TextStrokeColor3 = Color3.new(0, 0, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			})
		})

		return Roact.createFragment(children)
	end)
end

return RectangleSelectorView