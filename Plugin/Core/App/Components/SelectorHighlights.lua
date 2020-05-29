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
	local selected = props.selected
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
					SurfaceTransparency = 0.2,
					LineThickness = 0.01,
				}
			)
		end
	end
	if hovered then
		local color = getColorForOperation(operation):lerp(Constants.SELECTED_COLOR, 0.4)
		for _, part in pairs(hovered) do
			boxes[part] = Roact.createElement(
				"SelectionBox",
				{
					Adornee = part,
					SurfaceColor3 = color,
					Color3 = color,
					SurfaceTransparency = 0.2,
					LineThickness = 0.01,
				}
			)
		end
	end
	if selected then
		local color = Constants.SELECTED_COLOR
		for _, part in pairs(selected) do
			if not boxes[part] and part:IsA("BasePart") and not part:IsA("Terrain") then
				boxes[part] = Roact.createElement(
					"SelectionBox",
					{
						Adornee = part,
						SurfaceColor3 = color,
						Color3 = color,
						SurfaceTransparency = 0.2,
						LineThickness = 0.01,
					}
				)
			end
		end
	end

	local fragment = Roact.createFragment(boxes)
	debug.profileend()
	return fragment
end

return SelectorHighlights