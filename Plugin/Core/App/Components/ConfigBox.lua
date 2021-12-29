local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)

local ConfigBox = Roact.PureComponent:extend("ConfigBox")

function ConfigBox:render()
	local props = self.props
	local title = props.title

	return Roact.createElement("Frame",
		{
			Size = UDim2.new(0, 200, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			BackgroundTransparency = 0.5,
			BackgroundColor3 = Color3.new(0, 0, 0),
		},
		(function()
			local children = {}

			children.Padding = Roact.createElement("UIPadding", {
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
			})

			children.Title = Roact.createElement("TextLabel", {
				Text = title,
				BackgroundTransparency = 1,
				Font = Enum.Font.RobotoMono,
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 16,
				Size = UDim2.new(1, 0, 0, 16),
				TextXAlignment = Enum.TextXAlignment.Left,
				RichText = true,
			})

			children.Contents = Roact.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Position = UDim2.new(0, 0, 0, 20),
			}, {
				List = Roact.createElement("UIListLayout", {
					Padding = UDim.new(0, 4),
				})
			}, props[Roact.Children])

			return children
		end)()
	)
end

return ConfigBox