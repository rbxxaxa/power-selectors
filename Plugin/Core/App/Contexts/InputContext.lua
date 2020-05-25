local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)

local InputContext = Roact.createContext()

local InputController = Roact.Component:extend("InputController")

function InputController:init()
	local mainManager = self.props.mainManager
	self.mainManager = mainManager

	self:updateStateFromMainManager()
end

function InputController:updateStateFromMainManager()
	self:setState({
		inputState = self.mainManager:getInputState(),
	})
end

function InputController:buildContextValue()
	return { inputState = self.state.inputState }
end

function InputController:render()
	return Roact.createElement(
		InputContext.Provider,
		{ value = self:buildContextValue() },
		self.props[Roact.Children]
	)
end

function InputController:didMount()
	self.unsubscribeFromMainManager = self.mainManager:subscribe(function()
		self:updateStateFromMainManager()
	end)
end

function InputController:willUnmount()
	self.unsubscribeFromMainManager()
end

local function withContext(render)
	return Roact.createElement(InputContext.Consumer, {
		render = render
	})
end

return {
	Controller = InputController,
	withContext = withContext,
}