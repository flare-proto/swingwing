local sw = require "swingwing"
local net = sw.openNetwork("")
local s = net.addStage{name="TEST",input=2,output=1}
local s2 = net.addStage{name="TEST",input=2,output=1}
net.layout()
print(s2.getOutput(1))