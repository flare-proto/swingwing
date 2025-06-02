--
-- Nuclear Generation Facility SCADA Supervisor
--

require("/initenv").init_env()

local crash      = require("scada-common.crash")
local comms      = require("scada-common.comms")
local log        = require("scada-common.log")
local network    = require("scada-common.network")
local ppm        = require("scada-common.ppm")
local tcd        = require("scada-common.tcd")
local types      = require("scada-common.types")
local util       = require("scada-common.util")

local core       = require("graphics.core")


local renderer   = require("test.renderer")



local SUPERVISOR_VERSION = "v1.7.0"

local println = util.println
local println_ts = util.println_ts

----------------------------------------
-- get configuration
----------------------------------------


local cfv = util.new_validator()

assert(cfv.valid(), "startup> the number of reactor cooling configurations is different than the number of units")

----------------------------------------
-- log init
----------------------------------------

log.init("/logs.txt", 0, false)

log.info("========================================")
log.info("BOOTING supervisor.startup " .. SUPERVISOR_VERSION)
log.info("========================================")
println(">> SCADA Supervisor " .. SUPERVISOR_VERSION .. " <<")

crash.set_env("supervisor", SUPERVISOR_VERSION)
crash.dbg_log_env()

----------------------------------------
-- main application
----------------------------------------

local function main()
    ----------------------------------------
    -- startup
    ----------------------------------------

    -- record firmware versions and ID


    -- mount connected devices
    ppm.mount_all()

    -- message authentication init


    -- get modem




    -- start UI
    local fp_ok, message = renderer.try_start_ui(1, 1)

    if not fp_ok then
        println_ts(util.c("UI error: ", message))
        log.error(util.c("front panel GUI render failed with error ", message))
    else
        -- redefine println_ts local to not print as we have the front panel running
        println_ts = function (_) end
    end


    local MAIN_CLOCK = 0.15
    local loop_clock = util.new_clock(MAIN_CLOCK)

    -- start clock
    loop_clock.start()

    -- halve the rate heartbeat LED flash
    local heartbeat_toggle = true

    -- init startup recovery
    
    -- event loop
    while true do
        local event, param1, param2, param3, param4, param5 = util.pull_event()

        -- handle event
        if event == "timer" and loop_clock.is_clock(param1) then
            -- main loop tick

            heartbeat_toggle = not heartbeat_toggle

            -- iterate sessions
            

            loop_clock.start()
        elseif event == "timer" then
            -- a non-clock timer event, check watchdogs
            

            -- notify timer callback dispatcher
            tcd.handle(param1)
        elseif event == "mouse_click" or event == "mouse_up" or event == "mouse_drag" or event == "mouse_scroll" or
               event == "double_click" then
            -- handle a mouse event
            renderer.handle_mouse(core.events.new_mouse_event(event, param1, param2, param3))
        end

        -- check for termination request
        if event == "terminate" or ppm.should_terminate() then
            println_ts("closing sessions...")
            log.info("terminate requested, closing sessions...")
            
            log.info("sessions closed")
            break
        end
    end

    renderer.close_ui()

    util.println_ts("exited")
    log.info("exited")
end

if not xpcall(main, crash.handler) then
    pcall(renderer.close_ui)
    crash.exit()
else
    log.close()
end
