--
-- Graphics Rendering Control
--

local panel_view = require("test.panel.pipenet")
local sw = require "swingwing"
local pgi        = require("test.panel.pgi")
--local style      = require("test.panel.style")
local style         = require("test.panel.style")
local themes      = require("graphics.themes")

local core       = require("graphics.core")
local flasher    = require("graphics.flasher")

local DisplayBox = require("graphics.elements.DisplayBox")

---@class supervisor_renderer
local renderer = {}

local ui = {
    display = nil
}

-- render engine
local engine = {
    color_mode = 1,         ---@type COLOR_MODE
    monitors = nil,         ---@type monitors_struct|nil
    dmesg_window = nil,     ---@type Window|nil
    ui_ready = false,
    fp_ready = false,
    ui = {
        front_panel = nil,  ---@type DisplayBox|nil
        main_display = nil, ---@type DisplayBox|nil
        flow_display = nil, ---@type DisplayBox|nil
        unit_displays = {}  ---@type (DisplayBox|nil)[]
    },
    disable_flow_view = false
}


-- try to start the UI
---@param theme FP_THEME front panel theme
---@param color_mode COLOR_MODE color mode
---@return boolean success, any error_msg
function renderer.try_start_ui(theme, color_mode)
    local status, msg = true, nil

    if ui.display == nil then
        -- set theme
        --style.set_theme(theme, color_mode)
        style.set_themes(themes.UI_THEME.DEEPSLATE,themes.FP_THEME.BASALT,themes.COLOR_MODE.STANDARD)
        -- reset terminal
        

        -- set overridden colors
        for i = 1, #style.theme.colors do
            term.setPaletteColor(style.theme.colors[i].c, style.theme.colors[i].hex)
        end

        term.setTextColor(colors.white)
        term.setBackgroundColor(style.theme.bg)
        term.clear()
        term.setCursorPos(1, 1)
        -- apply color mode

        -- init front panel view
        status, msg = pcall(function ()
            ui.display = DisplayBox{window=term.current(),fg_bg=style.root}
            panel_view(ui.display)
        end)

        

        if status then
            -- start flasher callback task
            flasher.run()
        else
            -- report fail and close ui
            msg = core.extract_assert_msg(msg)
            renderer.close_ui()
        end
    end

    sw.psil.publish("sb.concrete.active",true)

    return status, msg
end

-- close out the UI
function renderer.close_ui()
    if ui.display ~= nil then
        -- stop blinking indicators
        flasher.clear()

        -- disable PGI
        pgi.unlink()

        -- hide to stop animation callbacks
        ui.display.hide()

        -- clear root UI elements
        ui.display = nil

        -- restore colors
        --for i = 1, #style.theme.colors do
        --    local r, g, b = term.nativePaletteColor(style.theme.colors[i].c)
        --    term.setPaletteColor(style.theme.colors[i].c, r, g, b)
        --end

        -- reset terminal
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setCursorPos(1, 1)
    end
end

-- is the UI ready?
---@nodiscard
---@return boolean ready
function renderer.ui_ready() return ui.display ~= nil end

-- handle a mouse event
---@param event mouse_interaction|nil
function renderer.handle_mouse(event)
    if ui.display ~= nil and event ~= nil then
        ui.display.handle_mouse(event)
    end
end

return renderer
