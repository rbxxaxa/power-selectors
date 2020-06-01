local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)

local RectangleMarquee = Roact.PureComponent:extend("RectangleMarquee")

function RectangleMarquee:render()
	local props = self.props
	local size = props.size
	local position = props.position

	return Roact.createElement("Frame",
		{
			Size = size,
			BorderSizePixel = 0,
			BackgroundTransparency = 0.8,
			BackgroundColor3 = Color3.new(0, 0, 0),
			Position = position,
		},
		(function()
			local children = {}

			local color = Color3.new(1, 1, 1)
			local function createRect(rectPos, rectSize)
				return Roact.createElement("ImageLabel", {
					Image = "rbxassetid://5120400998",
					ImageColor3 = color,
					BackgroundTransparency = 1,
					Size = rectSize,
					Position = rectPos,
					ScaleType = Enum.ScaleType.Tile,
					TileSize = UDim2.fromOffset(8, 8),
				})
			end

			children.Top = createRect(UDim2.fromScale(0, 0), UDim2.new(1, 0, 0, 1))
			children.Bottom = createRect(UDim2.fromScale(0, 1), UDim2.new(1, 0, 0, 1))
			children.Left = createRect(UDim2.fromScale(0, 0), UDim2.new(0, 1, 1, 0))
			children.Right = createRect(UDim2.fromScale(1, 0), UDim2.new(0, 1, 1, 0))

			return children
		end)()
	)
end

return RectangleMarquee