local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)
local Utilities = require(PluginRoot.Core.Modules.Utilities)

local RunService = game:GetService("RunService")

local CircleMarquee = Roact.PureComponent:extend("CircleMarquee")

function CircleMarquee:init()
	self.state = {
		currentRadius = self.props.radius,
		desiredRadius = self.props.radius,
	}
end

function CircleMarquee:didMount()
	self.hConn = RunService.Heartbeat:Connect(function(dt)
		local currentRadius = self.state.currentRadius
		local desiredRadius = self.state.desiredRadius
		if currentRadius ~= desiredRadius then
			-- Decided not to use dt for this.
			-- The frame the selector exits turbo mode, the dt will be huge.
			-- That ruins the easing effect.
			local newRadius = Utilities.lerp(currentRadius, desiredRadius, 0.5)
			if math.abs(newRadius - desiredRadius) < 1 then
				newRadius = desiredRadius
			end
			self:setState({
				currentRadius = newRadius
			})
		end
	end)
end

function CircleMarquee:willUnmount()
	self.hConn:Disconnect()
end

function CircleMarquee.getDerivedStateFromProps(nextProps, lastState)
	return {
		desiredRadius = nextProps.radius
	}
end

function CircleMarquee:render()
	local props = self.props
	local position = props.position
	local radius = self.state.currentRadius

	return Roact.createElement("ImageLabel",
		{
			Size = UDim2.fromOffset(radius*2-2, radius*2-2),
			Image = "rbxassetid://5048041217",
			BackgroundTransparency = 1,
			ImageTransparency = 0.8,
			ImageColor3 = Color3.new(0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = position,
		},
		(function()
			local segments = {}

			local segmentCount = math.max(8, math.floor(2*math.pi*radius / 10))
			local segmentLength = 2 * radius * math.sin(math.pi/segmentCount)
			local inradius = radius * math.cos(math.pi/segmentCount)
			local color = Color3.new(1, 1, 1)
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