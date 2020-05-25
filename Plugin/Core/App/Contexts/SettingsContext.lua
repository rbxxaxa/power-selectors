local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)

local SettingsContext = Roact.createContext()

local SettingsController = Roact.Component:extend("SettingsController")

function SettingsController:init()
	local mainManager = self.props.mainManager
	self.mainManager = mainManager

	self:updateStateFromMainManager()
end

function SettingsController:updateStateFromMainManager()
	self:setState({
		settings = self.mainManager:getSettings(),
		mode = self.mainManager:getMode()
	})
end

function SettingsController:buildContextValue()
	return { settings = self.state.settings, mode = self.state.mode }
end

function SettingsController:render()
	return Roact.createElement(
		SettingsContext.Provider,
		{ value = self:buildContextValue() },
		self.props[Roact.Children]
	)
end

function SettingsController:didMount()
	self.unsubscribeFromMainManager = self.mainManager:subscribe(function()
		self:updateStateFromMainManager()
	end)
end

function SettingsController:willUnmount()
	self.unsubscribeFromMainManager()
end

local function withContext(render)
	return Roact.createElement(SettingsContext.Consumer, {
		render = render
	})
end

return {
	Controller = SettingsController,
	withContext = withContext,
}