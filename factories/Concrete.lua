local sw = require "swingwing"

local net = sw.openNetwork("")
local Limestone = net.addStage { name = "Limestone", input = 0, output = 1,x=3, y = 3 }

local sand = net.addStage { name = "Sand", input = 0, output = 1,x=3, y = 7 }
local gravel = net.addStage { name = "Gravel", input = 0, output = 1,x=3, y = 14 }


local Crusher = net.addUnit { name = "Crusher", input = 1, output = 1, x = 25 }
    :activeOn("sb.concrete.active")
local Washer = net.addUnit { name = "Washer", input = 1, output = 1, x = 25, y = 5 }
    :activeOn("sb.concrete.active")
local s4 = net.addUnit { name = "MIXER", input = 2, output = 1, x = 50 }
    :activeOn("sb.concrete.active")


local s5 = net.addUnit{ name = "MIXER", input = 3, output = 1, x = 55, y = 10 }
    :activeOn("sb.concrete.active")
local s6 = net.addUnit { name = "MIXER", input = 3, output = 1, x = 55, y = 20 }
    :activeOn("sb.concrete.active")
local Water = net.addStage { name = "Water", input = 0, output = 1,x=3, y = 24 }
local v1 = net.addValve { name = "WTR", input = 1, output = 1, pipeColor = colors.blue, x = 17, y = 25 }
    :activeOn("sb.concrete.active")


local output = net.addStage { name = "Concrete", input = 1, output = 0,x=90, y = 22 }
--sand.y=sand.y+2

net.addPipe(Water.getOutput(3), v1.getInput(2), colors.blue)
net.addPipe(v1.getOutput(1), s6.getInput(2), colors.blue)



net.addPipe(Limestone.getOutput(1), Crusher.getInput(1), colors.white) -- 3
net.addPipe(sand.getOutput(1), Washer.getInput(1), colors.yellow) -- 4 

net.addPipe(Crusher.getOutput(1), s4.getInput(1), colors.orange) -- 5
net.addPipe(Washer.getOutput(1), s4.getInput(2), colors.lightGray) -- 6



net.addPipe(s4.getOutput(1), s5.getInput(1), colors.lightGray)
net.addPipe(gravel.getOutput(1), s5.getInput(2), colors.lightGray)

net.addPipe(s5.getOutput(1), s6.getInput(1), colors.lightGray)

net.addPipe(s6.getOutput(1), output.getInput(1), colors.white)

return net
