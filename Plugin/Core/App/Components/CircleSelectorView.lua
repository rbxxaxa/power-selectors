local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)
local App = PluginRoot.Core.App
local Contexts = App.Contexts
local MainContext = require(Contexts.MainContext)
local Components = App.Components
local CircleMarquee = require(Components.CircleMarquee)
local SelectorHighlights = require(Components.SelectorHighlights)

local CircleSelectorView = Roact.PureComponent:extend("CircleSelectorView")

function CircleSelectorView:render()
    return MainContext.withContext(function(mainContext)
        local mainManager = mainContext.mainManager
        if mainManager:getMode() ~= "circle" then return end
        local settings = mainManager:getSettings()
        local selector = mainManager:getSelector()
        local inputState = mainManager:getInputState()
        local circleMarquee = Roact.createElement(CircleMarquee, {
            position = UDim2.fromOffset(inputState.x, inputState.y),
            radius = settings.circleRadius,
            operation = settings.operation,
        })

        local selectorHighlights = Roact.createElement(SelectorHighlights, {
            hovered = selector:getHovered(),
            pending = selector:getPending(),
            operation = settings.operation,
        })

        return Roact.createFragment({
            circleMarquee,
            selectorHighlights
        })
    end)
end

return CircleSelectorView