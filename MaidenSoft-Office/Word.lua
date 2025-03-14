
local version = "v0.0.0-piss"

local function writeColoredAt(terminal, xPosition, yPosition, text, textColor, backgroundColor)
    terminal.setCursorPos(xPosition, yPosition)
    terminal.setTextColor(textColor)
    terminal.setBackgroundColor(backgroundColor)
    terminal.write(text)
end

local ETFFile = require("lib.mds.etf.file")
local ETFCore = require("lib.mds.etf.core")
local mathUtils = require("lib.mds.utils.math")

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

    writeColoredAt(term, 1, 19, actionbar.text .. string.rep(" ", math.max(0, 51 - #actionbar.text) ), colors.white, backgroundColor)

end

local function setTitle(title)
    if (#title > 40) then
        title = string.sub(title, 1, 18) .. "..." .. string.sub(title, #title-18, #title)
    end
    paintutils.drawLine(1,1, 50, 1, colors.blue)
    writeColoredAt(term,  52/2 - #title/2, 1, title, colors.white, colors.blue)
end

local function setActionBar(text, type, displayTime)
    type = type or 0
    type = type + 1
    displayTime = displayTime or 20
    actionbar = { text = text, type = type, displayTime = displayTime }
end

local pageViewBounds = {
    width = 25,
    height = 21,
    padding = 2,
    margin = 1
}
local viewData = {
    position = 0,
    maxPosition = 0,
    viewportHeight = 16,
    viewportWidth = 25 + pageViewBounds.padding*2 - 1,
    viewportPositionX = 11,
    viewportPositionY = 2,
}
local function renderPages() 
    for characterPositionY = 0, viewData.viewportHeight, 1 do
        for characterPositionX = 0 , viewData.viewportWidth, 1 do
            local screenPostionX = characterPositionX + viewData.viewportPositionX
            local screenPostionY = characterPositionY + viewData.viewportPositionY

            local verticalPosition = characterPositionY + viewData.position
            local horizontalPosition = characterPositionX

            local page = math.floor((verticalPosition + pageViewBounds.margin - pageViewBounds.padding) / (pageViewBounds.height + pageViewBounds.margin + 2*pageViewBounds.padding))
            local row = verticalPosition - page * (pageViewBounds.height + pageViewBounds.margin + 2*pageViewBounds.padding) - pageViewBounds.padding - pageViewBounds.margin
            local column = horizontalPosition - pageViewBounds.padding

            page = page + 1

            if (page <= #document.pages and row >= 0 and row < pageViewBounds.height and characterPositionX >= 0 and column >= 0 and column < pageViewBounds.width) then
                -- Content
                local character, color = document:getCharacter(page, row+1, column+1)
                character = character or " "

                writeColoredAt(term, screenPostionX, screenPostionY, character, color, colors.white)
            elseif (row < 0 and row >= 0 - pageViewBounds.padding) or (row >= pageViewBounds.height and row < pageViewBounds.height + pageViewBounds.padding) then
                -- Padding
                writeColoredAt(term, screenPostionX, screenPostionY, " ", colors.red, colors.white)
            elseif (row >= 0 and row < pageViewBounds.height) and ((column < 0) or (column >= pageViewBounds.width)) then
                -- Padding
                writeColoredAt(term, screenPostionX, screenPostionY, " ", colors.red, colors.white)
            else
                -- Margin
                writeColoredAt(term, screenPostionX, screenPostionY, " ", colors.red, colors.lightGray)
            end
        end
    end
end

local scrollbar = {
    length = 0,
    maxLength = 17,
    screenPositionX = 51,
    screenPositionY = 2,
    mouseStartY = nil,
    initialScrollPosition = nil
}
local function calculateScrollHeight() 
    viewData.maxPosition = (#document.pages) * (pageViewBounds.height + pageViewBounds.margin + 2*pageViewBounds.padding) - viewData.viewportHeight

    -- Rendering bar

    paintutils.drawLine(scrollbar.screenPositionX, scrollbar.screenPositionY, scrollbar.screenPositionX, scrollbar.screenPositionY + scrollbar.maxLength - 1, colors.gray)

    local barHeightRatio = viewData.viewportHeight/(viewData.maxPosition + viewData.viewportHeight)

    if (barHeightRatio < 1) then
        local barPostionRatio = viewData.position / (viewData.maxPosition)

        local barHeight = mathUtils.round(barHeightRatio * scrollbar.maxLength)
        local barOffset = mathUtils.round(barPostionRatio * (scrollbar.maxLength-barHeight-1))

        paintutils.drawLine(scrollbar.screenPositionX, scrollbar.screenPositionY + barOffset, scrollbar.screenPositionX, scrollbar.screenPositionY + barOffset + barHeight, colors.white)
    end
    

end

-- Main
if #tArgs >= 1 then
    filePath = shell.resolve(tArgs[1])
end

-- Document
if filePath ~= nil then

    local pathAbbriviation = filePath
    if (#pathAbbriviation > 20) then
        pathAbbriviation = "..." .. string.sub(pathAbbriviation, #pathAbbriviation - 17, #pathAbbriviation)
    end

    local function loadFile(path) 
        document = ETFFile.load(filePath)
        setActionBar("Successfully loaded file: " .. pathAbbriviation, 0, 20*5)
    end
    local status, err = pcall(loadFile)
    if not status then
        document = ETFCore.ETFDocument:new()
        setActionBar("Failed to load file: ".. pathAbbriviation, 2, 20 * 5)
    end
end

document = document or ETFCore.ETFDocument:new()

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
setTitle(document.title .. " - MdS Office Word")
writeColoredAt(term, 51, 1, "X", colors.white, colors.red)

local eventHandlers = {
    preTick = function ()
        
    end,
    postTick = function ()
        calculateScrollHeight()
        updateActionbar()
        renderPages()
    end,

    ["mouse_click"] = function (mouseButton, mouseX, mouseY, _)
        setActionBar("mouse_click: " .. mouseX .. " " .. mouseY)
        if (mouseX == 51 and mouseY == 1) then
            softExit()
        elseif (mouseX == scrollbar.screenPositionX and mouseY >= scrollbar.screenPositionY and mouseY < scrollbar.screenPositionY + scrollbar.maxLength) then
            setActionBar("Scroll Selected")
            scrollbar.initialScrollPosition = viewData.position
            scrollbar.mouseStartY = mouseY - scrollbar.screenPositionY
        end
    end,

    ["mouse_up"] = function (mouseButton, mouseX, mouseY, _)
        if (scrollbar.mouseStartY ~= nil) then
            setActionBar("Scroll Deselected")
            scrollbar.mouseStartY = nil
        end

    end,

    ["terminate"] = function (a1, a2, a3, a4)
        softExit()
    end,

    ["mouse_scroll"] = function (direction, xPos, yPos, _)
        viewData.position = mathUtils.clamp(viewData.position + ((direction <= 0) and -1 or 1) , 0, viewData.maxPosition)
        setActionBar("Scroll: " .. viewData.position .. ", D: " .. direction)
    end,

    ["mouse_drag"] = function (button, mouseX, mouseY, _)
        
        if (scrollbar.mouseStartY ~= nil) then
            local mousePositionOffsetRatio = -(mouseY - scrollbar.screenPositionY - scrollbar.mouseStartY) / (scrollbar.maxLength - 1)
    
            viewData.position = mathUtils.clamp( scrollbar.initialScrollPosition - mathUtils.round(mousePositionOffsetRatio * (viewData.maxPosition + viewData.viewportHeight)), 0, viewData.maxPosition )

            setActionBar("Scroll Drag Offset Ratio: " .. mousePositionOffsetRatio)
            
        end

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