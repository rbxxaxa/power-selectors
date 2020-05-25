local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)

local SelectionContext = Roact.createContext()

local SelectionController = Roact.Component:extend("SelectionController")

function SelectionController:init()
	local mainManager = self.props.mainManager
	self.mainManager = mainManager

	self:updateStateFromMainManager()
end

function SelectionController:updateStateFromMainManager()
	self:setState({
		hovered = self.mainManager:getHoveredSelection() or Roact.None,
		pending = self.mainManager:getPendingSelection() or Roact.None,
		current = self.mainManager:getCurrentSelection(),
	})
end

function SelectionController:buildContextValue()
	return { hovered = self.state.hovered, pending = self.state.pending, current = self.state.current }
end

function SelectionController:render()
	return Roact.createElement(
		SelectionContext.Provider,
		{ value = self:buildContextValue() },
		self.props[Roact.Children]
	)
end

function SelectionController:didMount()
	self.unsubscribeFromMainManager = self.mainManager:subscribe(function()
		self:updateStateFromMainManager()
	end)
end

function SelectionController:willUnmount()
	self.unsubscribeFromMainManager()
end

local function withContext(render)
	return Roact.createElement(SelectionContext.Consumer, {
		render = render
	})
end

return {
	Controller = SelectionController,
	withContext = withContext,
}