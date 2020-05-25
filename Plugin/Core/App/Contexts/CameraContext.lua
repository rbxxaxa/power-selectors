local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)

local CameraContext = Roact.createContext()

local CameraController = Roact.Component:extend("CameraController")

function CameraController:init()
	local mainManager = self.props.mainManager
	self.mainManager = mainManager

	self:updateStateFromMainManager()
end

function CameraController:updateStateFromMainManager()
	self:setState({
		cameraState = self.mainManager:getCameraState()
	})
end

function CameraController:buildContextValue()
	return { cameraState = self.state.cameraState }
end

function CameraController:render()
	return Roact.createElement(
		CameraContext.Provider,
		{ value = self:buildContextValue() },
		self.props[Roact.Children]
	)
end

function CameraController:didMount()
	self.unsubscribeFromMainManager = self.mainManager:subscribe(function()
		self:updateStateFromMainManager()
	end)
end

function CameraController:willUnmount()
	self.unsubscribeFromMainManager()
end

local function withContext(render)
	return Roact.createElement(CameraContext.Consumer, {
		render = render
	})
end

return {
	Controller = CameraController,
	withContext = withContext,
}