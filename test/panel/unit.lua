--
-- Supervisor Front Panel GUI
--

local util          = require("scada-common.util")

local databus       = require("supervisor.databus")

local types             = require("scada-common.types")

local pgi           = require("supervisor.panel.pgi")
local style         = require("test.panel.style")

local chk_entry     = require("supervisor.panel.components.chk_entry")
local pdg_entry     = require("supervisor.panel.components.pdg_entry")
local rtu_entry     = require("supervisor.panel.components.rtu_entry")

local core          = require("graphics.core")

local Div               = require("graphics.elements.Div")
local Rectangle         = require("graphics.elements.Rectangle")
local TextBox           = require("graphics.elements.TextBox")

local AlarmLight        = require("graphics.elements.indicators.AlarmLight")
local CoreMap           = require("graphics.elements.indicators.CoreMap")
local DataIndicator     = require("graphics.elements.indicators.DataIndicator")
local IndicatorLight    = require("graphics.elements.indicators.IndicatorLight")
local RadIndicator      = require("graphics.elements.indicators.RadIndicator")
local TriIndicatorLight = require("graphics.elements.indicators.TriIndicatorLight")
local VerticalBar       = require("graphics.elements.indicators.VerticalBar")

local HazardButton      = require("graphics.elements.controls.HazardButton")
local MultiButton       = require("graphics.elements.controls.MultiButton")
local NumericSpinbox    = require("graphics.elements.controls.NumericSpinbox")
local PushButton        = require("graphics.elements.controls.PushButton")
local RadioButton       = require("graphics.elements.controls.RadioButton")

local ALIGN = core.ALIGN

local cpair = core.cpair


local border = core.border

local bw_fg_bg = style.bw_fg_bg
local gry_wht = style.gray_white

local period = core.flasher.PERIOD

    local function nilfunc(...)
        return
    end

-- create new front panel view
---@param panel DisplayBox main displaybox
local function init(parent)
    
    local s_hi_box = style.theme.highlight_box
    local s_hi_bright = style.theme.highlight_box_bright
    local s_field = style.theme.field_box

    local hc_text = style.hc_text
    local lu_cpair = style.lu_colors
    local hzd_fg_bg = style.hzd_fg_bg
    local dis_colors = style.dis_colors
    local arrow_fg_bg = cpair(style.theme.label, s_hi_box.bkg)

    local ind_bkg = style.ind_bkg
    local ind_grn = style.ind_grn
    local ind_yel = style.ind_yel
    local ind_red = style.ind_red
    local ind_wht = style.ind_wht

    
    local unit = 1
    

    local main = Div{parent=parent,x=1,y=1}

    if unit == nil then return main end


    TextBox{parent=main,text="Reactor Unit #1",alignment=ALIGN.CENTER,fg_bg=style.theme.header}

    -----------------------------
    -- main stats and core map --
    -----------------------------

    local core_map = CoreMap{parent=main,x=2,y=3,reactor_l=18,reactor_w=18}
    core_map.resize(3,3)

    TextBox{parent=main,x=12,y=22,text="Heating Rate",width=12,fg_bg=style.label}
    local heating_r = DataIndicator{parent=main,x=12,label="",format="%14.0f",value=0,unit="mB/t",commas=true,lu_colors=lu_cpair,width=19,fg_bg=s_field}


    TextBox{parent=main,x=12,y=25,text="Commanded Burn Rate",width=19,fg_bg=style.label}
    local burn_r = DataIndicator{parent=main,x=12,label="",format="%14.2f",value=0,unit="mB/t",lu_colors=lu_cpair,width=19,fg_bg=s_field}


    TextBox{parent=main,text="F",x=2,y=22,width=1,fg_bg=style.label}
    TextBox{parent=main,text="C",x=4,y=22,width=1,fg_bg=style.label}
    TextBox{parent=main,text="\x1a",x=6,y=24,width=1,fg_bg=style.label}
    TextBox{parent=main,text="\x1a",x=6,y=25,width=1,fg_bg=style.label}
    TextBox{parent=main,text="H",x=8,y=22,width=1,fg_bg=style.label}
    TextBox{parent=main,text="W",x=10,y=22,width=1,fg_bg=style.label}

    local fuel  = VerticalBar{parent=main,x=2,y=23,fg_bg=cpair(style.theme.fuel_color,colors.gray),height=4,width=1}
    local ccool = VerticalBar{parent=main,x=4,y=23,fg_bg=cpair(colors.blue,colors.gray),height=4,width=1}
    local hcool = VerticalBar{parent=main,x=8,y=23,fg_bg=cpair(colors.white,colors.gray),height=4,width=1}
    local waste = VerticalBar{parent=main,x=10,y=23,fg_bg=cpair(colors.brown,colors.gray),height=4,width=1}


    TextBox{parent=main,x=32,y=22,text="Core Temp",width=9,fg_bg=style.label}
    local fmt = util.trinary(true, "%10.2f", "%11.2f")
    local core_temp = DataIndicator{parent=main,x=32,label="",format=fmt,value=0,commas=true,unit="K",lu_colors=lu_cpair,width=13,fg_bg=s_field}

    TextBox{parent=main,x=32,y=25,text="Burn Rate",width=9,fg_bg=style.label}
    local act_burn_r = DataIndicator{parent=main,x=32,label="",format="%8.2f",value=0,unit="mB/t",lu_colors=lu_cpair,width=13,fg_bg=s_field}

    TextBox{parent=main,x=32,y=28,text="Damage",width=6,fg_bg=style.label}
    local damage_p = DataIndicator{parent=main,x=32,label="",format="%11.0f",value=0,unit="%",lu_colors=lu_cpair,width=13,fg_bg=s_field}
    

    TextBox{parent=main,x=32,y=31,text="Radiation",width=21,fg_bg=style.label}
    local radiation = RadIndicator{parent=main,x=32,label="",format="%9.3f",lu_colors=lu_cpair,width=13,fg_bg=s_field}


    -------------------
    -- system status --
    -------------------

    local u_stat = Rectangle{parent=main,border=border(1,colors.gray,true),thin=true,width=33,height=4,x=46,y=3,fg_bg=bw_fg_bg}
    local stat_line_1 = TextBox{parent=u_stat,x=1,y=1,text="UNKNOWN",width=33,alignment=ALIGN.CENTER,fg_bg=bw_fg_bg}
    local stat_line_2 = TextBox{parent=u_stat,x=1,y=2,text="awaiting data...",width=33,alignment=ALIGN.CENTER,fg_bg=gry_wht}


    -----------------
    -- annunciator --
    -----------------

    -- annunciator colors (generally) per IAEA-TECDOC-812 recommendations

    local annunciator = Div{parent=main,width=23,height=18,x=22,y=3}

    -- connectivity
    local plc_online = IndicatorLight{parent=annunciator,label="PLC Online",colors=cpair(ind_grn.fgd,ind_red.fgd)}
    local plc_hbeat  = IndicatorLight{parent=annunciator,label="PLC Heartbeat",colors=ind_wht}
    local rad_mon    = TriIndicatorLight{parent=annunciator,label="Radiation Monitor",c1=ind_bkg,c2=ind_yel.fgd,c3=ind_grn.fgd}

    annunciator.line_break()

    -- operating state
    local r_active = IndicatorLight{parent=annunciator,label="Active",colors=ind_grn}
    local r_auto   = IndicatorLight{parent=annunciator,label="Automatic Control",colors=ind_wht}


    -- main unit transient/warning annunciator panel
    local r_scram = IndicatorLight{parent=annunciator,label="Reactor SCRAM",colors=ind_red}
    local r_mscrm = IndicatorLight{parent=annunciator,label="Manual Reactor SCRAM",colors=ind_red}
    local r_ascrm = IndicatorLight{parent=annunciator,label="Auto Reactor SCRAM",colors=ind_red}
    local rad_wrn = IndicatorLight{parent=annunciator,label="Radiation Warning",colors=ind_yel}
    local r_rtrip = IndicatorLight{parent=annunciator,label="RCP Trip",colors=ind_red}
    local r_cflow = IndicatorLight{parent=annunciator,label="RCS Flow Low",colors=ind_yel}
    local r_clow  = IndicatorLight{parent=annunciator,label="Coolant Level Low",colors=ind_yel}
    local r_temp  = IndicatorLight{parent=annunciator,label="Reactor Temp. High",colors=ind_red}
    local r_rhdt  = IndicatorLight{parent=annunciator,label="Reactor High Delta T",colors=ind_yel}
    local r_firl  = IndicatorLight{parent=annunciator,label="Fuel Input Rate Low",colors=ind_yel}
    local r_wloc  = IndicatorLight{parent=annunciator,label="Waste Line Occlusion",colors=ind_yel}
    local r_hsrt  = IndicatorLight{parent=annunciator,label="Startup Rate High",colors=ind_yel}


    -- RPS annunciator panel

    TextBox{parent=main,text="REACTOR PROTECTION SYSTEM",fg_bg=cpair(colors.black,colors.cyan),alignment=ALIGN.CENTER,width=33,x=46,y=8}
    local rps = Rectangle{parent=main,border=border(1,colors.cyan,true),thin=true,width=33,height=12,x=46,y=9}
    local rps_annunc = Div{parent=rps,width=31,height=10,x=2,y=1}

    local rps_trp = IndicatorLight{parent=rps_annunc,label="RPS Trip",colors=ind_red,flash=true,period=period.BLINK_250_MS}
    local rps_dmg = IndicatorLight{parent=rps_annunc,label="Damage Level High",colors=ind_red,flash=true,period=period.BLINK_250_MS}
    local rps_exh = IndicatorLight{parent=rps_annunc,label="Excess Heated Coolant",colors=ind_yel}
    local rps_exw = IndicatorLight{parent=rps_annunc,label="Excess Waste",colors=ind_yel}
    local rps_tmp = IndicatorLight{parent=rps_annunc,label="Core Temperature High",colors=ind_red,flash=true,period=period.BLINK_250_MS}
    local rps_nof = IndicatorLight{parent=rps_annunc,label="No Fuel",colors=ind_yel}
    local rps_loc = IndicatorLight{parent=rps_annunc,label="Coolant Level Low Low",colors=ind_yel}
    local rps_flt = IndicatorLight{parent=rps_annunc,label="PPM Fault",colors=ind_yel,flash=true,period=period.BLINK_500_MS}
    local rps_tmo = IndicatorLight{parent=rps_annunc,label="Connection Timeout",colors=ind_yel,flash=true,period=period.BLINK_500_MS}
    local rps_sfl = IndicatorLight{parent=rps_annunc,label="System Failure",colors=ind_red,flash=true,period=period.BLINK_500_MS}



    -- cooling annunciator panel

    TextBox{parent=main,text="REACTOR COOLANT SYSTEM",fg_bg=cpair(colors.black,colors.blue),alignment=ALIGN.CENTER,width=33,x=46,y=22}
    local rcs = Rectangle{parent=main,border=border(1,colors.blue,true),thin=true,width=33,height=24,x=46,y=23}
    local rcs_annunc = Div{parent=rcs,width=27,height=22,x=3,y=1}
    local rcs_tags = Div{parent=rcs,width=2,height=16,x=1,y=7}

    local c_flt  = IndicatorLight{parent=rcs_annunc,label="RCS Hardware Fault",colors=ind_yel}
    local c_emg  = TriIndicatorLight{parent=rcs_annunc,label="Emergency Coolant",c1=ind_bkg,c2=ind_wht.fgd,c3=ind_grn.fgd}
    local c_cfm  = IndicatorLight{parent=rcs_annunc,label="Coolant Feed Mismatch",colors=ind_yel}
    local c_brm  = IndicatorLight{parent=rcs_annunc,label="Boil Rate Mismatch",colors=ind_yel}
    local c_sfm  = IndicatorLight{parent=rcs_annunc,label="Steam Feed Mismatch",colors=ind_yel}
    local c_mwrf = IndicatorLight{parent=rcs_annunc,label="Max Water Return Feed",colors=ind_yel}


    local available_space = 16 - (2 + 4)

    local function _add_space()
        -- if we have some extra space, add padding
        rcs_tags.line_break()
        rcs_annunc.line_break()
    end

    -- boiler annunciator panel(s)

    if 1 > 0 then
        if available_space > 0 then _add_space() end

        TextBox{parent=rcs_tags,x=1,text="B1",width=2,fg_bg=hc_text}
        local b1_wll = IndicatorLight{parent=rcs_annunc,label="Water Level Low",colors=ind_red}
        

        TextBox{parent=rcs_tags,text="B1",width=2,fg_bg=hc_text}
        local b1_hr = IndicatorLight{parent=rcs_annunc,label="Heating Rate Low",colors=ind_yel}
        
    end
    

    -- turbine annunciator panels

    if available_space > 1 then _add_space() end

    TextBox{parent=rcs_tags,text="T1",width=2,fg_bg=hc_text}
    local t1_sdo = TriIndicatorLight{parent=rcs_annunc,label="Steam Relief Valve Open",c1=ind_bkg,c2=ind_yel.fgd,c3=ind_red.fgd}


    TextBox{parent=rcs_tags,text="T1",width=2,fg_bg=hc_text}
    local t1_tos = IndicatorLight{parent=rcs_annunc,label="Turbine Over Speed",colors=ind_red}
    

    TextBox{parent=rcs_tags,text="T1",width=2,fg_bg=hc_text}
    local t1_gtrp = IndicatorLight{parent=rcs_annunc,label="Generator Trip",colors=ind_yel,flash=true,period=period.BLINK_250_MS}
    

    TextBox{parent=rcs_tags,text="T1",width=2,fg_bg=hc_text}
    local t1_trp = IndicatorLight{parent=rcs_annunc,label="Turbine Trip",colors=ind_red,flash=true,period=period.BLINK_250_MS}

    util.nop()

    ----------------------
    -- reactor controls --
    ----------------------

    local burn_control = Div{parent=main,x=12,y=28,width=19,height=3,fg_bg=s_hi_box}
    local burn_rate = NumericSpinbox{parent=burn_control,x=2,y=1,whole_num_precision=4,fractional_precision=1,min=0.1,arrow_fg_bg=arrow_fg_bg,arrow_disable=style.theme.disabled}
    TextBox{parent=burn_control,x=9,y=2,text="mB/t",fg_bg=style.theme.label_fg}


    local set_burn_btn = PushButton{parent=burn_control,x=14,y=2,text="SET",min_width=5,fg_bg=cpair(colors.black,colors.yellow),active_fg_bg=style.wh_gray,dis_fg_bg=dis_colors,callback=nilfunc}





    local start = HazardButton{parent=main,x=2,y=28,text="START",accent=colors.lightBlue,dis_colors=dis_colors,callback=nilfunc,fg_bg=hzd_fg_bg}
    local ack_a = HazardButton{parent=main,x=12,y=32,text="ACK \x13",accent=colors.orange,dis_colors=dis_colors,callback=nilfunc,fg_bg=hzd_fg_bg}
    local scram = HazardButton{parent=main,x=2,y=32,text="SCRAM",accent=colors.yellow,dis_colors=dis_colors,callback=nilfunc,fg_bg=hzd_fg_bg}
    local reset = HazardButton{parent=main,x=22,y=32,text="RESET",accent=colors.red,dis_colors=dis_colors,callback=nilfunc,fg_bg=hzd_fg_bg}


    TextBox{parent=main,text="WASTE PROCESSING",fg_bg=cpair(colors.black,colors.brown),alignment=ALIGN.CENTER,width=33,x=46,y=48}
    local waste_proc = Rectangle{parent=main,border=border(1,colors.brown,true),thin=true,width=33,height=3,x=46,y=49}
    local waste_div = Div{parent=waste_proc,x=2,y=1,width=31,height=1}

    local waste_mode = MultiButton{parent=waste_div,x=1,y=1,options=style.get_waste().unit_opts,callback=nilfunc,min_width=6}


    ----------------------
    -- alarm management --
    ----------------------

    local alarm_panel = Div{parent=main,x=2,y=36,width=29,height=16,fg_bg=s_hi_bright}

    local a_brc = AlarmLight{parent=alarm_panel,x=6,y=2,label="Containment Breach",c1=ind_bkg,c2=ind_red.fgd,c3=ind_grn.fgd,flash=true,period=period.BLINK_250_MS}
    local a_rad = AlarmLight{parent=alarm_panel,x=6,label="Containment Radiation",c1=ind_bkg,c2=ind_red.fgd,c3=ind_grn.fgd,flash=true,period=period.BLINK_250_MS}
    local a_dmg = AlarmLight{parent=alarm_panel,x=6,label="Critical Damage",c1=ind_bkg,c2=ind_red.fgd,c3=ind_grn.fgd,flash=true,period=period.BLINK_250_MS}
    alarm_panel.line_break()
    local a_rcl = AlarmLight{parent=alarm_panel,x=6,label="Reactor Lost",c1=ind_bkg,c2=ind_red.fgd,c3=ind_grn.fgd,flash=true,period=period.BLINK_250_MS}
    local a_rcd = AlarmLight{parent=alarm_panel,x=6,label="Reactor Damage",c1=ind_bkg,c2=ind_red.fgd,c3=ind_grn.fgd,flash=true,period=period.BLINK_250_MS}
    local a_rot = AlarmLight{parent=alarm_panel,x=6,label="Reactor Over Temp",c1=ind_bkg,c2=ind_red.fgd,c3=ind_grn.fgd,flash=true,period=period.BLINK_250_MS}
    local a_rht = AlarmLight{parent=alarm_panel,x=6,label="Reactor High Temp",c1=ind_bkg,c2=ind_yel.fgd,c3=ind_grn.fgd,flash=true,period=period.BLINK_500_MS}
    local a_rwl = AlarmLight{parent=alarm_panel,x=6,label="Reactor Waste Leak",c1=ind_bkg,c2=ind_red.fgd,c3=ind_grn.fgd,flash=true,period=period.BLINK_250_MS}
    local a_rwh = AlarmLight{parent=alarm_panel,x=6,label="Reactor Waste High",c1=ind_bkg,c2=ind_yel.fgd,c3=ind_grn.fgd,flash=true,period=period.BLINK_500_MS}
    alarm_panel.line_break()
    local a_rps = AlarmLight{parent=alarm_panel,x=6,label="RPS Transient",c1=ind_bkg,c2=ind_yel.fgd,c3=ind_grn.fgd,flash=true,period=period.BLINK_500_MS}
    local a_clt = AlarmLight{parent=alarm_panel,x=6,label="RCS Transient",c1=ind_bkg,c2=ind_yel.fgd,c3=ind_grn.fgd,flash=true,period=period.BLINK_500_MS}
    local a_tbt = AlarmLight{parent=alarm_panel,x=6,label="Turbine Trip",c1=ind_bkg,c2=ind_red.fgd,c3=ind_grn.fgd,flash=true,period=period.BLINK_250_MS}



    -- ack's and resets
    local C = setmetatable({},{__index=function (t, k)
        return nilfunc
    end})

    local c = setmetatable({},{__index=function (t, k)
        return C
    end})
    local ack_fg_bg = cpair(colors.black, colors.orange)
    local rst_fg_bg = cpair(colors.black, colors.lime)
    local active_fg_bg = cpair(colors.white, colors.gray)

    PushButton{parent=alarm_panel,x=2,y=2,text="\x13",callback=c.c_breach.ack,fg_bg=ack_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=4,y=2,text="R",callback=c.c_breach.reset,fg_bg=rst_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=2,y=3,text="\x13",callback=c.radiation.ack,fg_bg=ack_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=4,y=3,text="R",callback=c.radiation.reset,fg_bg=rst_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=2,y=4,text="\x13",callback=c.dmg_crit.ack,fg_bg=ack_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=4,y=4,text="R",callback=c.dmg_crit.reset,fg_bg=rst_fg_bg,active_fg_bg=active_fg_bg}

    PushButton{parent=alarm_panel,x=2,y=6,text="\x13",callback=c.r_lost.ack,fg_bg=ack_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=4,y=6,text="R",callback=c.r_lost.reset,fg_bg=rst_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=2,y=7,text="\x13",callback=c.damage.ack,fg_bg=ack_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=4,y=7,text="R",callback=c.damage.reset,fg_bg=rst_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=2,y=8,text="\x13",callback=c.over_temp.ack,fg_bg=ack_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=4,y=8,text="R",callback=c.over_temp.reset,fg_bg=rst_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=2,y=9,text="\x13",callback=c.high_temp.ack,fg_bg=ack_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=4,y=9,text="R",callback=c.high_temp.reset,fg_bg=rst_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=2,y=10,text="\x13",callback=c.waste_leak.ack,fg_bg=ack_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=4,y=10,text="R",callback=c.waste_leak.reset,fg_bg=rst_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=2,y=11,text="\x13",callback=c.waste_high.ack,fg_bg=ack_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=4,y=11,text="R",callback=c.waste_high.reset,fg_bg=rst_fg_bg,active_fg_bg=active_fg_bg}

    PushButton{parent=alarm_panel,x=2,y=13,text="\x13",callback=c.rps_trans.ack,fg_bg=ack_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=4,y=13,text="R",callback=c.rps_trans.reset,fg_bg=rst_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=2,y=14,text="\x13",callback=c.rcs_trans.ack,fg_bg=ack_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=4,y=14,text="R",callback=c.rcs_trans.reset,fg_bg=rst_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=2,y=15,text="\x13",callback=c.t_trip.ack,fg_bg=ack_fg_bg,active_fg_bg=active_fg_bg}
    PushButton{parent=alarm_panel,x=4,y=15,text="R",callback=c.t_trip.reset,fg_bg=rst_fg_bg,active_fg_bg=active_fg_bg}

    -- color tags

    TextBox{parent=alarm_panel,x=5,y=13,text="\x95",width=1,fg_bg=cpair(s_hi_bright.bkg,colors.cyan)}
    TextBox{parent=alarm_panel,x=5,text="\x95",width=1,fg_bg=cpair(s_hi_bright.bkg,colors.blue)}
    TextBox{parent=alarm_panel,x=5,text="\x95",width=1,fg_bg=cpair(s_hi_bright.bkg,colors.blue)}

    --------------------------------
    -- automatic control settings --
    --------------------------------

    TextBox{parent=main,text="AUTO CTRL",fg_bg=cpair(colors.black,colors.purple),alignment=ALIGN.CENTER,width=13,x=32,y=36}
    local auto_ctl = Rectangle{parent=main,border=border(1,colors.purple,true),thin=true,width=13,height=15,x=32,y=37}
    local auto_div = Div{parent=auto_ctl,width=13,height=15,x=1,y=1}

    local group = RadioButton{parent=auto_div,options=types.AUTO_GROUP_NAMES,callback=function()end,radio_colors=cpair(style.theme.accent_dark,style.theme.accent_light),select_color=colors.purple}

    

    auto_div.line_break()

    
    local set_grp_btn = PushButton{parent=auto_div,text="SET",x=4,min_width=5,fg_bg=cpair(colors.black,colors.yellow),active_fg_bg=style.wh_gray,dis_fg_bg=gry_wht,callback=nilfunc}

    auto_div.line_break()

    TextBox{parent=auto_div,text="Prio. Group",width=11,fg_bg=style.label}
    local auto_grp = TextBox{parent=auto_div,text="Manual",width=11,fg_bg=s_field}

    
    auto_div.line_break()

    local a_rdy = IndicatorLight{parent=auto_div,label="Ready",x=2,colors=ind_grn}
    local a_stb = IndicatorLight{parent=auto_div,label="Standby",x=2,colors=ind_wht,flash=true,period=period.BLINK_1000_MS}


    -- enable/disable controls based on group assignment (start button is separate)



end

return init
