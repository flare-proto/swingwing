--
-- Flow Monitor GUI
--

local types          = require("scada-common.types")
local util           = require("scada-common.util")



local style          = require("test.panel.style")
local sw = require "swingwing"

local core           = require("graphics.core")

local Div            = require("graphics.elements.Div")
local PipeNetwork    = require("graphics.elements.PipeNetwork")
local Rectangle      = require("graphics.elements.Rectangle")
local TextBox        = require("graphics.elements.TextBox")

local DataIndicator  = require("graphics.elements.indicators.DataIndicator")
local HorizontalBar  = require("graphics.elements.indicators.HorizontalBar")
local IndicatorLight = require("graphics.elements.indicators.IndicatorLight")
local StateIndicator = require("graphics.elements.indicators.StateIndicator")

local LED         = require("graphics.elements.indicators.LED")

local CONTAINER_MODE = types.CONTAINER_MODE
local COOLANT_TYPE = types.COOLANT_TYPE

local ALIGN = core.ALIGN

local cpair = core.cpair
local border = core.border
local pipe = core.pipe

local wh_gray = style.wh_gray

-- create new flow view
---@param main DisplayBox main displaybox
local function init(main)
    local s_hi_bright = style.theme.highlight_box_bright
    local s_field = style.theme.field_box
    local text_col = style.text_colors
    local lu_col = style.lu_colors
    local lu_c_d = style.lu_colors_dark

    ---comment
    ---@param IConnectorData IConnector
    local function tank(IConnectorData)
        local tank = Div{parent=main,x=IConnectorData.x,y=IConnectorData.y+2,width=20,height=IConnectorData.h,fg_bg=style.wh_gray}

        TextBox{parent=tank,text=IConnectorData.name,alignment=ALIGN.CENTER,fg_bg=style.wh_gray}

--        local tank_box = Rectangle{parent=tank,border=border(1,colors.gray,false),width=20,height=12,y=2,x=1}
        local conn = LED{parent=tank,x=2,y=2,label="ACTIVE",colors=cpair(colors.green_off,colors.black)}

        TextBox{parent=tank,x=1,y=3,text="Fill",width=10,height=1,fg_bg=style.wh_gray}
 
    end

    ---@param IConnectorData IConnector
    local function stage(IConnectorData)
        if IConnectorData.valve then
            local vx = IConnectorData.x
            local vy = IConnectorData.y+1
            local pipes =PipeNetwork{parent=main,x=vx,y=vy,pipes={pipe(2,0,IConnectorData.w,0,IConnectorData.pipeColor,true)},bg=style.theme.bg}

            --local valve = Div{parent=main,x=IConnectorData.x,y=IConnectorData.y+2,width=IConnectorData.w,height=IConnectorData.h}
            TextBox{parent=main,x=IConnectorData.x,y=IConnectorData.y+1,text="\x10\x11",fg_bg=text_col,width=2}
            local conn = IndicatorLight{parent=main,x=vx,y=vy+1,label=IConnectorData.name,colors=style.ind_grn}
            
        elseif IConnectorData.h == 1 then
            
            TextBox{parent=main,x=IConnectorData.x,y=IConnectorData.y+2,text=IConnectorData.name,alignment=ALIGN.CENTER,width=IConnectorData.w,fg_bg=wh_gray}
            
        else
            tank(IConnectorData)
        end
    end

    local net = sw.openNetwork("")
    local Limestone = net.addStage{name="Limestone",input=1,output=1,y=3}
    
    local sand = net.addStage{name="Sand",input=1,output=1,y=7}
    local gravel = net.addStage{name="Gravel",input=1,output=1,y=14}

    
    local Crusher = net.addUnit{name="Crusher",input=1,output=1,x=25}
    local Washer = net.addUnit{name="Washer",input=1,output=1,x=25,y=5}
    local s4 = net.addUnit{name="MIXER",input=2,output=1,x=50}
    
    
    local s5 = net.addUnit{name="MIXER",input=3,output=1,x=55,y=10}
    local s6 = net.addUnit{name="MIXER",input=3,output=1,x=55,y=20}
    local Water = net.addStage{name="Water",input=1,output=1,y=24}
    local v1 = net.addValve{name="WTR",input=1,output=1,pipeColor=colors.blue,x=13,y=25}

    --sand.y=sand.y+2

    net.addPipe(Water.getOutput(3),v1.getInput(2),colors.blue)
    net.addPipe(v1.getOutput(1),s6.getInput(2),colors.blue)



    net.addPipe(Limestone.getOutput(1),Crusher.getInput(1),colors.white)
    net.addPipe(sand.getOutput(1),Washer.getInput(1),colors.yellow)

    net.addPipe(Crusher.getOutput(1),s4.getInput(1),colors.orange)
    net.addPipe(Washer.getOutput(1),s4.getInput(2),colors.lightGray)
    
    net.addPipe(v1.getOutput(3),s4.getInput(4),colors.green_hc)

    net.addPipe(s4.getOutput(1),s5.getInput(1),colors.lightGray)
    net.addPipe(gravel.getOutput(1),s5.getInput(2),colors.lightGray)

    net.addPipe(s5.getOutput(1),s6.getInput(1),colors.lightGray)
    
    local pipes = {}

    for index, value in ipairs(net.pipes()) do
        local routed = net.routePipe(value.start,value.pipeEnd)
        if routed then
            for index, v2 in ipairs(routed) do
                table.insert(pipes,pipe(v2.start.x, v2.start.y,v2.pipeEnd.x, v2.pipeEnd.y, value.pipeColor, true))
            end
        end
        
        
    end
    
    if pipes then
        PipeNetwork{parent=main,x=1,y=2,pipes=pipes,bg=style.theme.bg}
    end
    
    stage(Limestone)
    stage(sand)
    stage(Water)
    stage(gravel)
    stage(Crusher)
    stage(Washer)
    stage(s4)
    stage(s5)
    stage(s6)
    stage(v1)

    -- window header message
    local header = TextBox{parent=main,y=1,text="Factory Management"..sand.x.." "..sand.y,alignment=ALIGN.CENTER,fg_bg=style.theme.header}
    -- max length example: "01:23:45 AM - Wednesday, September 28 2022"
    



    local po_pipes = {}
    local emcool_pipes = {}

    -- get the y offset for this unit index
    ---@param idx integer unit index
    local function y_ofs(idx) return ((idx - 1) * 20) end

    
    

    util.nop()

    ---------
    -- SPS --
    ---------

    


end

return init
