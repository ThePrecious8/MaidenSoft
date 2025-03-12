
local version = "v0.0.0-piss"

-- .etf     Single Color
-- .etfg    Grayscale (Black, Dark Gray, Light Gray)
-- .etfc    16 Color

local function writeColoredAt(terminal, xPosition, yPosition, text, textColor, backgroundColor)
    terminal.setCursorPos(xPosition, yPosition)
    terminal.setTextColor(textColor)
    terminal.setBackgroundColor(backgroundColor)
    terminal.write(text)
end

local ETFFile = require("lib.etfFile")
local ETFCore = require("lib.etfCore")

local tArgs = {...}

local filePath = nil
local document = nil
local edited = false
local running = true

local actionbarColors = {
    colors.blue,
    colors.orange,
    colors.red
}
local actionbar = nil
local function updateActionbar() 

    writeColoredAt(term, 1, 19, string.rep(" ", 51), colors.white, actionbarColors[1])

    if actionbar == nil then return end
    if actionbar.displayTime <= 0 then return end

    actionbar.displayTime = actionbar.displayTime - 1
    if actionbar.displayTime == 0 then
        actionbar = nil
        return
    end

    local backgroundColor = actionbarColors[actionbar.type]
    if (backgroundColor == nil) then backgroundColor = actionbarColors[1] end

    writeColoredAt(term, 1, 19, actionbar.text, colors.white, backgroundColor)

end

local function setActionBar(text, type, displayTime)
    type = type or 0
    displayTime = displayTime or 20
    actionbar = { text = text, type = type, displayTime = displayTime }
end

if #tArgs >= 1 then
    filePath = tArgs[1]
end

-- Document
if filePath == nil then
    document = ETFCore.ETFDocument:new()
else
    local function loadFile(path) 
        document = ETFFile.load(filePath)
        setActionBar("Successfully loaded file", 0, 20*5)
    end
    local status, err = pcall(loadFile)
    if not status then
        document = ETFCore.ETFDocument:new()
        setActionBar("Failed to load file", 2, 20 * 5)
    end
end

local function softExit()
    
    if edited then
        setActionBar("Not Implemented", 2)
    else 
        running = false
    end
end

-- Static UI
term.setBackgroundColor(colors.lightGray)
term.clear()
paintutils.drawLine(1,1, 51, 1, colors.blue)
writeColoredAt(term, 51, 1, "X", colors.white, colors.red)

local eventHandlers = {
    preTick = function ()
        
    end,
    postTick = function ()
        updateActionbar()
    end,

    ["mouse_click"] = function (a1, a2, a3, a4)
        setActionBar("mouse_click: " .. a2 .. " " .. a3)
        if (a2 == 51 and a3 == 1) then softExit() end
    end,

    ["terminate"] = function (a1, a2, a3, a4)
        softExit()
    end
}

while running do
    eventHandlers.preTick()

    local eventTimer = os.startTimer(0.05)
    local event, a1, a2, a3, a4
    repeat  
        event, a1, a2, a3, a4 = os.pullEventRaw()
        local eventHandler = eventHandlers[event]
        if eventHandler ~= nil then
            eventHandler(a1, a2, a3, a4)
        end
    until event == "timer" and a1 == eventTimer
    eventHandlers.postTick()
end


term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)
term.write("Thank you for using MaidenSoft Office WordTM")
term.setCursorPos(1,2)
term.write(version)
term.setCursorPos(1,3)