local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)
local Core = PluginRoot.Core
local Constants = require(Core.Modules.Constants)

local CircleMarquee = Roact.PureComponent:extend("CircleMarquee")

local function getColorForOperation(operation)
	return operation == "add" and Constants.ADD_COLOR or Constants.SUBTRACT_COLOR
end

function CircleMarquee:render()
    local props = self.props
    local position = props.position
    local operation = props.operation
    local radius = props.radius

    local color = getColorForOperation(operation)
    return Roact.createElement("ImageLabel",
        {
            Size = UDim2.fromOffset(radius*2-2, radius*2-2),
            Image = "rbxassetid://5048041217",
            BackgroundTransparency = 1,
            ImageTransparency = 0.8,
            ImageColor3 = color,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = position,
        },
        (function()
            local segments = {}

            local segmentCount = math.max(8, math.floor(2*math.pi*radius / 10))
            local segmentLength = 2 * radius * math.sin(math.pi/segmentCount)
            local inradius = radius * math.cos(math.pi/segmentCount)
            for i = 1, segmentCount do
                local angle = i/segmentCount * math.pi * 2
                local x = math.cos(angle) * inradius
                local y = math.sin(angle) * inradius
                table.insert(segments, Roact.createElement("Frame", {
                    BackgroundColor3 = color,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(segmentLength*0.5, 1),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Rotation = math.deg(angle + math.pi/2),
                    Position = UDim2.fromOffset(x+radius, y+radius)
                }))
            end

            return segments
        end)()
    )
end

return CircleMarquee