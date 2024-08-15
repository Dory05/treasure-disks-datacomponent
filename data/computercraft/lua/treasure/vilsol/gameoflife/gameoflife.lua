local tArgs = { ... }
local mon

-- Allow user to select peripheral to write output
if(tArgs[1] ~= nil) then
  mon = peripheral.wrap(tArgs[1])
  if mon == nil then
    print("Peripheral " .. tArgs[1] .. " does not exist.")
    return
  elseif peripheral.getType(mon) ~= "monitor" then
    print("Peripheral " .. tArgs[1] .. " is not a monitor.")
    return
  end
else
  mon = term
end

local w, h = mon.getSize()
local sBack = mon.getBackgroundColor()
local sText = mon.getTextColor()


-- Display introduction text
local intro = {
  "Conway's Game Of Life",
  "It is a game which represents life.",
  "The game runs by 4 basic rules:",
  "1. If a cell has less than 2 neighbours, it dies.",
  "2. If a cell has 2 or 3 neighbours, it lives.",
  "3. If a cell has more than 3 neighbours, it dies.",
  "4. If a cell has exactly 3 neighbours, it is born.",
  "At the top left is the generation count.",
  "Press spacebar to switch between color modes",
  "Press enter to start the game",
  "Presss backspace to quit the game",
  "Colors:",
  "Red - Cell will die in next generation",
  "Green - Cell will live in next generation",
  "Yellow - Cell will be born in next generation",
  "Press any key to continue!"
}
  
mon.setBackgroundColor(colors.black)
mon.clear()
for k,v in ipairs(intro) do
  mon.setCursorPos(1, k)
  mon.write(v)
end
os.pullEvent("key")

-- Initialze board (row-major) to empty state
local board = {}
local CELL_NONE = 0
local CELL_DIE = 2
local CELL_LIVE = 3
local CELL_NEXT = 1

local function twoIndex(x, y) return (y-1)*w + x end
local MAX_INDEX = h*w

for i=1, MAX_INDEX do
  board[i] = CELL_NONE
end

-- Get neighbour count of a cell
local function getNeighbours(src, x, y)
  local function occupyAsNum(x, y)
    local cell = src[twoIndex(x, y)]
    return (cell and (cell > CELL_NEXT and 1)) or 0
  end
  
  -- Same column as cell
  local total = occupyAsNum(x, y-1) + occupyAsNum(x, y+1)
  
  -- Column to left of cell
  if (x > 1) then
    total = total + occupyAsNum(x-1, y-1) + occupyAsNum(x-1, y) + occupyAsNum(x-1, y+1)
  end
  
  -- Column to right of cell
  if (x < w) then
    total = total + occupyAsNum(x+1, y-1) + occupyAsNum(x+1, y) + occupyAsNum(x+1, y+1)
  end
  
  return total
end

local generation = 0

-- Advance board to next generation
local function nextGen()
  local newBoard = {}
  
  -- Spawn and delete cells according to flags
  for i = 1, MAX_INDEX do
    local c = board[i]
    newBoard[i] = ((c == CELL_NEXT or c == CELL_LIVE) and CELL_LIVE) or CELL_NONE
  end
  
  -- Update the flags on the new board
  for y=1, h do
    for x=1, w do
      local nei = getNeighbours(newBoard, x, y)
      local i = twoIndex(x,y)
      
      if newBoard[i] == CELL_LIVE and (nei < 2 or nei > 3) then 
        newBoard[i] = CELL_DIE
      elseif newBoard[i] == CELL_NONE and nei == 3 then
        newBoard[i] = CELL_NEXT
      end
    end
  end
  
  -- Move buffer to live board
  board = newBoard
  generation = generation + 1
end

-- Setup color variables based on color capability
local COLOR = {}
local GRAYSCALE = not mon.isColor()
local COL_NUMBER

local function updatePalette(color)
  if not color then
    COLOR[CELL_DIE] = colors.white
    COLOR[CELL_LIVE] = colors.white
    COLOR[CELL_NEXT] = colors.black
    COL_NUMBER = colors.white
  elseif GRAYSCALE then
    COLOR[CELL_DIE] = colors.lime
    COLOR[CELL_LIVE] = colors.purple
    COLOR[CELL_NEXT] = colors.gray
    COL_NUMBER = colors.white
  else 
    COLOR[CELL_DIE] = colors.red
    COLOR[CELL_LIVE] = colors.green
    COLOR[CELL_NEXT] = colors.yellow
    COL_NUMBER = colors.blue
  end
end

local usecolor = true
COLOR[CELL_NONE] = colors.black
updatePalette(usecolor)

-- Function to draw board to screen
local function drawScreen()
  for y=h, 1, -1 do
    for x=w, 1, -1 do
      local i = twoIndex(x, y)
      mon.setBackgroundColor(COLOR[board[i]])
      mon.setCursorPos(x, y)
      mon.write(" ")
    end
  end
  
  mon.setCursorPos(1,1)
  mon.setTextColor(COL_NUMBER)
  mon.write(generation)
end

local function loop()
  while true do
    event, variable, xPos, yPos = os.pullEvent()
    if event == "mouse_click" or event == "monitor_touch" or event == "mouse_drag" then
      if variable == 1 then
        board[xPos][yPos] = 1
      else
        board[xPos][yPos] = 0
      end
    end
    if event == "key" then
      if variable == keys.enter then
        return true
      elseif variable == keys.space then
        if(mon.isColor() or mon.isColor)then
          colored = not colored
        end
      elseif variable == keys.up then
        if sleeptime > 0.1 then
          sleeptime = sleeptime - 0.1
        end
      elseif variable == keys.down then
        if sleeptime < 1 then
          sleeptime = sleeptime + 0.1
        end
      end
    end
    drawScreen()
  end
end

local function stop()
  mon.setBackgroundColor(sBack)
  mon.setTextColor(sText)
  mon.clear()
  mon.setCursorPos(1,1)
end

-- Input initial state
drawScreen()

while true do
  local e, button, x, y = os.pullEvent()
  
  if e == "mouse_click" or e == "mouse_drag" then
    board[twoIndex(x, y)] = (button == 1 and CELL_LIVE) or CELL_NONE
  elseif e == "monitor_touch" then
    board[twoIndex(x, y)] = CELL_LIVE
  elseif e == "key" then
    local name = keys.getName(button)
    if name == "backspace" then
      stop()
      return
    elseif name == "space" then
      usecolor = not usecolor
      updatePalette(usecolor)
    elseif name == "enter" then
      break
    end
  end
  
  drawScreen()
end

-- Set initial flags
nextGen()
generation = 0
drawScreen()

-- Simulation loop
local delay = 0.5
local tick = os.startTimer(delay)

while true do
  local e, button, x, y = os.pullEvent()
  
  if e == "timer" and button == tick then
    nextGen()
    drawScreen()
    tick = os.startTimer(delay)
  elseif e == "key" then 
    local name = keys.getName(button)
    if name == "backspace" then
      stop()
      return
    elseif name == "space" then
      usecolor = not usecolor
      updatePalette(usecolor)
      drawScreen()
    elseif name == "up" then
      delay = math.max(0, delay - 0.1)
    elseif name == "down" then
      delay = math.min(delay + 0.1, 1)
    end
  end
end
