local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)
local Core = PluginRoot.Core
local Constants = require(Core.Modules.Constants)

local SelectionBoxes = Roact.Component:extend("SelectionBoxes")

local function getColorForOperation(operation)
	return operation == "add" and Constants.ADD_COLOR or Constants.SUBTRACT_COLOR
end

function SelectionBoxes:shouldUpdate(incomingProps, incomingState)
	return self.props.hovered ~= incomingProps.hovered or
		self.props.pending ~= incomingProps.pending or
		self.props.current ~= incomingProps.current
end

function SelectionBoxes:render()
	local props = self.props
	local hovered = props.hovered
	local pending = props.pending
	local current = props.current
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
			if not boxes[part] then
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
	end
	-- for _, part in pairs(current) do
	-- 	local color = Constants.SELECTED_COLOR
	-- 	if not boxes[part] then
	-- 		boxes[part] = Roact.createElement(
	-- 			"SelectionBox",
	-- 			{
	-- 				Adornee = part,
	-- 				SurfaceColor3 = color,
	-- 				Color3 = color,
	-- 				SurfaceTransparency = 0.5,
	-- 				LineThickness = 0.05,
	-- 			}
	-- 		)
	-- 	end
	-- end

	return Roact.createFragment(boxes)
end

return SelectionBoxes