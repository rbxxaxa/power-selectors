local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)

local MainContext = Roact.createContext()

local MainManagerController = Roact.Component:extend("MainManagerController")

function MainManagerController:init()
	local mainManager = self.props.mainManager
	self.mainManager = mainManager

	self:updateStateFromMainManager()
end

function MainManagerController:updateStateFromMainManager()
	self:setState({
		mainManager = self.mainManager
	})
end

function MainManagerController:buildContextValue()
	return { mainManager = self.state.mainManager }
end

function MainManagerController:render()
	return Roact.createElement(
		MainContext.Provider,
		{ value = self:buildContextValue() },
		self.props[Roact.Children]
	)
end

function MainManagerController:didMount()
	self.unsubscribeFromMainManager = self.mainManager:subscribe(function()
		self:updateStateFromMainManager()
	end)
end

function MainManagerController:willUnmount()
	self.unsubscribeFromMainManager()
end

local function withContext(render)
	return Roact.createElement(MainContext.Consumer, {
		render = render
	})
end

return {
	Controller = MainManagerController,
	withContext = withContext,
}