local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)

local SelectorContext = Roact.createContext()

local SelectorController = Roact.Component:extend("SelectorController")

function SelectorController:init()
	local mainManager = self.props.mainManager
	self.mainManager = mainManager

	self:updateStateFromMainManager()
end

function SelectorController:updateStateFromMainManager()
	self:setState({
        selector = self.mainManager:getSelector() or Roact.None
	})
end

function SelectorController:buildContextValue()
	return { selector = self.state.selector }
end

function SelectorController:render()
	return Roact.createElement(
		SelectorContext.Provider,
		{ value = self:buildContextValue() },
		self.props[Roact.Children]
	)
end

function SelectorController:didMount()
	self.unsubscribeFromMainManager = self.mainManager:subscribe(function()
		self:updateStateFromMainManager()
	end)
end

function SelectorController:willUnmount()
	self.unsubscribeFromMainManager()
end

local function withContext(render)
	return Roact.createElement(SelectorContext.Consumer, {
		render = render
	})
end

return {
	Controller = SelectorController,
	withContext = withContext,
}