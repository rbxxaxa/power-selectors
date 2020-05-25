local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Libs.Roact)
local App = PluginRoot.Core.App
local Contexts = App.Contexts
local SettingsContext = require(Contexts.SettingsContext)
local SelectionContext = require(Contexts.SelectionContext)
local InputContext = require(Contexts.InputContext)
local Components = App.Components
local CircleMarquee = require(Components.CircleMarquee)
local SelectionBoxes = require(Components.SelectionBoxes)

local CircleSelectorView = Roact.Component:extend("CircleSelectorView")

function CircleSelectorView:render()
    return SettingsContext.withContext(function(settingsContext)
        if settingsContext.mode ~= "circle" then return end
        return SelectionContext.withContext(function(selectionContext)
            return InputContext.withContext(function(inputContext)
                local inputState = inputContext.inputState
                local settings = settingsContext.settings
                local circleMarquee = Roact.createElement(CircleMarquee, {
                    position = UDim2.fromOffset(inputState.x, inputState.y),
                    radius = settings.circleSelectRadius,
                    operation = settings.operation,
                })

                local selectionBoxes = Roact.createElement(SelectionBoxes, {
                    hovered = selectionContext.hovered,
                    pending = selectionContext.pending,
                    current = selectionContext.current,
                    operation = settings.operation,
                })

                return Roact.createFragment({
                    circleMarquee,
                    selectionBoxes
                })
            end)
        end)
    end)
end

return CircleSelectorView