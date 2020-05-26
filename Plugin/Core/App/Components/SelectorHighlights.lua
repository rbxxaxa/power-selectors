local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)
local Core = PluginRoot.Core
local Constants = require(Core.Modules.Constants)

local SelectorHighlights = Roact.PureComponent:extend("SelectorHighlights")

local function getColorForOperation(operation)
	return operation == "add" and Constants.ADD_COLOR or Constants.SUBTRACT_COLOR
end

function SelectorHighlights:render()
	debug.profilebegin("SelectorHighlights::render")
	local props = self.props
	local hovered = props.hovered
	local pending = props.pending
	local operation = props.operation

	local boxes = {}
	if pending then
		local color = getColorForOperation(operation)
		for _, part in pairs(pending) do
			boxes[part] = Roact.createElement(
				"SelectionBox",
				{
					Adornee = part,
					SurfaceColor3 = color,
					Color3 = color,
					SurfaceTransparency = 0.5,
					LineThickness = 0.05,
				}
			)
		end
	end
	if hovered then
		local color = Constants.SELECTED_COLOR
		for _, part in pairs(hovered) do
			boxes[part] = Roact.createElement(
				"SelectionBox",
				{
					Adornee = part,
					SurfaceColor3 = color,
					Color3 = color,
					SurfaceTransparency = 0.5,
					LineThickness = 0.05,
				}
			)
		end
	end

	local fragment = Roact.createFragment(boxes)
	debug.profileend()
	return fragment
end

return SelectorHighlights