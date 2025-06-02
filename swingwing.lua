local sw = {}

local psil           = require("scada-common.psil")

local toasermq= require "toastermq_client"

local astar = require "astar"

local function newNet()
    ---@class network
    local net = {}
    local stages = {}

    local pipes = {}

    local avail = {}

    local function basePipe(start, pipeEnd, pipeColor)
        local pipe = {
            sx = start.x,
            sy = start.y,
            start = start,
            pipeEnd = pipeEnd,
            ex = pipeEnd.x,
            ey = pipeEnd.y,
            pipeColor = pipeColor
        }

        return pipe
    end

    local function newPipe(start, pipeEnd, pipeColor)
        --[[if (start.x == pipeEnd.x) or (start.y == pipeEnd.y) then

        else
            local s1 = vector.new(start.x,start.y)
            local s2 = vector.new(start.x,pipeEnd.y)
            local s3 = vector.new(pipeEnd.x,pipeEnd.y)

            local p1 = basePipe(s1,s2,pipeColor)
            local p2 = basePipe(s2,s3,pipeColor)
            return {p1,p2}
        end]]
        return { basePipe(start, pipeEnd, pipeColor) }
    end

    local function newIConnector(IConnectorData)
        ---@class IConnector
        local IConnector = {
            w = IConnectorData.w,
            h = (math.max(IConnectorData.input, IConnectorData.output)*2)+1 ,
            input = IConnectorData.input,
            output = IConnectorData.output,
            x = IConnectorData.x or 2,
            y = IConnectorData.y or 1,
            name = IConnectorData.name,
            activated_by = "NOP"
        }
        function IConnector.getOutput(num)
            return vector.new(IConnector.w + IConnector.x, (num*2 + IConnector.y))
        end

        function IConnector.getInput(num)
            return vector.new(IConnector.x - 2, (num*2 + IConnector.y))
        end

        function IConnector:activeOn(by)
            self.activated_by = by
            return self
        end

        return IConnector
    end

    local function newStage(stageData)
        stageData.w = #stageData.name + 4
        local stage = newIConnector(stageData)
        stage.h = 1

        function stage.getOutput()
            return vector.new(stage.x+stage.w, stage.y)
        end

        function stage.getInput()
            return vector.new(stage.x - 2, stage.y)
        end
        return stage
    end

    local function newValve(stageData)
        stageData.w = #stageData.name + 2
        local stage = newIConnector(stageData)
        stage.h = 2
        stage.valve = true
        stage.pipeColor = stageData.pipeColor

        function stage.getOutput()
            return vector.new(stage.x+stage.w, stage.y-1)
        end

        function stage.getInput()
            return vector.new(stage.x - 1, stage.y-1)
        end
        return stage
    end

    local function newUnit(stageData)
        stageData.w = 20
        local stage = newIConnector(stageData)
        
        return stage
    end

    function net.addUnit(stageData)
        local stage = newUnit(stageData)
        table.insert(stages, stage)
        return stage
    end

    function net.addStage(stageData)
        local stage = newStage(stageData)
        table.insert(stages, stage)
        return stage
    end
    function net.addValve(stageData)
        local stage = newValve(stageData)
        table.insert(stages, stage)
        return stage
    end

    function net.addPipe(start, pipeEnd, pipeColor)
        local pipe = newPipe(start, pipeEnd, pipeColor)
        for index, value in ipairs(pipe) do
            table.insert(pipes, value)
        end
        return pipe
    end

    --#region pipe

    -- Pipe spacing between elements
    local PIPE_MARGIN = 1 -- increase if you need more space for pipes

    -- Checks if two elements overlap, including pipe margin
    local function checkOverlap(a, b)
        return not (
            (a.x-PIPE_MARGIN) + a.w + PIPE_MARGIN <= (b.x-PIPE_MARGIN) or
            (b.x-PIPE_MARGIN) + b.w + PIPE_MARGIN <= (a.x-PIPE_MARGIN) or
            a.y + a.h + PIPE_MARGIN <= b.y or
            b.y + b.h + PIPE_MARGIN <= a.y
        )
    end

    -- Layout function
    local function layoutElements(elements)
        -- Sort by Y then X
        table.sort(elements, function(a, b)
            return a.y == b.y and a.x < b.x or a.y < b.y
        end)

        for i = 1, #elements do
            local el = elements[i]
            local moved = true
            while moved do
                moved = false
                for j = 1, i - 1 do
                    local other = elements[j]
                    if checkOverlap(el, other) then
                        -- Move this element down to clear the other, including pipe spacing
                        el.y = other.y + other.h + PIPE_MARGIN
                        moved = true
                    end
                end
            end
        end
    end

    -- Check if a point is inside an element (with optional padding)
    local function pointInElement(x, y, el, padding)
        padding = padding or 0
        return x >= el.x - 1 and x < el.x + el.w + padding and
            y >= el.y - padding and y < el.y + el.h + padding
    end

    local pipeGrid = {} -- pipeGrid[y][x] = true

    -- Helper: check if cell is blocked
    local function isBlocked(x, y, elements)
        -- Check elements
        for _, el in ipairs(elements) do
            if pointInElement(x, y, el) then return true end
        end

        -- Check pipes
        return pipeGrid[y] and pipeGrid[y][x]
    end

    -- Mark a pipe segment (horizontal or vertical) on the grid
    local function markPipeSegment(x1, y1, x2, y2)
        if x1 == x2 then
            for y = math.min(y1, y2), math.max(y1, y2) do
                pipeGrid[y] = pipeGrid[y] or {}
                pipeGrid[y][x1] = true
            end
        elseif y1 == y2 then
            for x = math.min(x1, x2), math.max(x1, x2) do
                pipeGrid[y1] = pipeGrid[y1] or {}
                pipeGrid[y1][x] = true
            end
        end
    end

    -- Replace pathBlocked with grid-aware version
    local function pathBlocked(x1, y1, x2, y2, elements)
        if x1 == x2 then
            for y = math.min(y1, y2), math.max(y1, y2) do
                if isBlocked(x1, y, elements) then return true end
            end
        elseif y1 == y2 then
            for x = math.min(x1, x2), math.max(x1, x2) do
                if isBlocked(x, y1, elements) then return true end
            end
        else
            error("Only H/V paths allowed")
        end
        return false
    end

    -- Convert points to segments with pipeEnd
    local function pointsToSegments(points)
        local segments = {}
        
        for i = 1, #points - 1 do
            local seg = {
                start = points[i],
                pipeEnd = points[i + 1]
            }
            markPipeSegment(seg.start.x, seg.start.y, seg.pipeEnd.x, seg.pipeEnd.y)
            table.insert(segments, seg)
        end
        return segments
    end

    -- Routing with pipe overlap avoidance
    function net.routePipe(start, target)
        local points = {}
        local elements = stages
        local function addPoint(x, y)
            table.insert(points, { x = x, y = y })
        end

        local sx, sy = start.x, start.y
        local tx, ty = target.x, target.y

        -- Straight L-paths first
        if not pathBlocked(sx, sy, tx, sy, elements) and
            not pathBlocked(tx, sy, tx, ty, elements) then
            addPoint(sx, sy)
            addPoint(tx, sy)
            addPoint(tx, ty)
            return pointsToSegments(points)
        end

        if not pathBlocked(sx, sy, sx, ty, elements) and
            not pathBlocked(sx, ty, tx, ty, elements) then
            addPoint(sx, sy)
            addPoint(sx, ty)
            addPoint(tx, ty)
            return pointsToSegments(points)
        end

        -- Horizontal detour
        for dx = 1, 15 do
            for _, dir in ipairs({ -1, 1 }) do
                local mx = sx + dx * dir
                if not pathBlocked(sx, sy, mx, sy, elements) and
                    not pathBlocked(mx, sy, mx, ty, elements) and
                    not pathBlocked(mx, ty, tx, ty, elements) then
                    addPoint(sx, sy)
                    addPoint(mx, sy)
                    addPoint(mx, ty)
                    addPoint(tx, ty)
                    return pointsToSegments(points)
                end
            end
        end

        -- Vertical detour
        for dy = 1, 15 do
            for _, dir in ipairs({ -1, 1 }) do
                local my = sy + dy * dir
                if not pathBlocked(sx, sy, sx, my, elements) and
                    not pathBlocked(sx, my, tx, my, elements) and
                    not pathBlocked(tx, my, tx, ty, elements) then
                    addPoint(sx, sy)
                    addPoint(sx, my)
                    addPoint(tx, my)
                    addPoint(tx, ty)
                    return pointsToSegments(points)
                end
            end
        end

        return nil -- No route found
    end

    --#endregion

    function net.layout()
        layoutElements(stages)
    end

    function net.pipes()
        return pipes
    end

    function net.stages()
        return stages
    end

    return net
end

---@return network
function sw.openNetwork(path)
    local net = newNet()

    return net
end

sw.psil =  psil.create()

function sw.daemon(side,exchange,address)
    return function()
        toasermq.connect(side,address)
        toasermq.bind("swingwing-"..exchange,"#",exchange)
        while true do
            local _,msg = toasermq.recv()
            sw.psil.publish(msg.routingKey,msg.data)
        end
    end, toasermq.daemon
    
end

return sw
