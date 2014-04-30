--[[ 
Version 3.4.5
Recent Changes:
  Improved session restoring for those using fuel
  Added New Rednet Support
  New Arguments!
    -atChest [force] Using this with -resume will tell the turtle that it is at its chest, and needs to go back to where it was
]]
--Defining things
civilTable = nil; _G.civilTable = {}; setmetatable(civilTable, {__index = _G}); setfenv(1,civilTable)
VERSION = "3.4.5" --Adding this so I can differentiate versions on error messages
originalDay = os.day() --Used in logging
numResumed = 0 --Number of times turtle has been resumed
-------Defaults for Arguments----------
--Arguments assignable by text
x,y,z = 3,3,3 --These are just in case tonumber fails
inverted = false --False goes from top down, true goes from bottom up [Default false] 
rednetEnabled = false --Default rednet on or off  [Default false]
--Arguments assignable by tArgs
dropSide = "front" --Side it will eject to when full or done [Default "front"]
careAboutResources = true --Will not stop mining once inventory full if false [Default true]
doCheckFuel = true --Perform fuel check [Default true]
doRefuel = false --Whenever it comes to start location will attempt to refuel from inventory [Default false]
invCheckFreq = 10 --Will check for inventory full every <-- moved spaces [Default 10]
keepOpen = 1 --How many inventory slots it will attempt to keep open at all times [Default 1]
fuelSafety = "moderate" --How much fuel it will ask for: safe, moderate, and loose [Default moderate]
saveFile = "Civil_Quarry_Restore" --Where it saves restore data [Default "Civil_Quarry_Restore"]
doBackup = true --If it will keep backups for session persistence [Default true]
uniqueExtras = 8 --How many different items (besides cobble) the turtle expects. [Default 8]
maxTries = 50 --How many times turtle will try to dig a block before it "counts" bedrock [Default 50]
gpsEnabled = false -- If option is enabled, will attempt to find position via GPS api [Default false]
gpsTimeout = 3 --The number of seconds the program will wait to get GPS coords. Not in arguments [Default 3]
logging = true --Whether or not the turtle will log mining runs. [Default ...still deciding]
logFolder = "Quarry_Logs" --What folder the turtle will store logs in [Default "Quarry_Logs"]
logExtension = "" --The extension of the file (e.g. ".txt") [Default ""]
startDown = 0 --How many blocks to start down from the top of the mine [Default 0]
enderChestEnabled = false --Whether or not to use an ender chest [Default false]
enderChestSlot = 16 --What slot to put the ender chest in [Default 16]
--Standard number slots for fuel (you shouldn't care)
fuelTable = { --Will add in this amount of fuel to requirement.
safe = 1000,
moderate = 200,
loose = 0 } --Default 1000, 200, 0
--Standard rednet channels
channels = {
send = os.getComputerID() + 1  ,
receive = os.getComputerID() + 101 ,
confirm = "Turtle Quarry Receiver",
message = "Civil's Quarry",
}

local help_paragraph = [[
Welcome!: Welcome to quarry help. Below are help entries for all parameters. Examples and tips are at the bottom.
-Default: This will force no prompts. If you use this and nothing else, only defaults will be used.
-dim: [length] [width] [height] This sets the dimensions for the quarry
-invert: [t/f] If true, quarry will be inverted (go up instead of down)
-rednet: [t/f] If true and you have a wireless modem on the turtle, will attempt to make a rednet connection for sending important information to a screen
-restore / -resume: If your quarry stopped in the middle of its run, use this to resume at the point where the turtle was. Not guarenteed to work properly. For more accurate location finding, check out the -GPS parameter
-atChest: [force] This is for use with "-restore," this will tell the restarting turtle that it is at its home chest, so that if it had gotten lost, it now knows where it is.
-doRefuel: [t/f] If true, the turtle will refuel itself with coal and planks it finds on its mining run
-doCheckFuel: [t/f] If you for some reason don't want the program to check fuel usage, set to false. This is honestly a hold-over from when the refueling algorithm was awful...
-uniqueExtras: [number] The expected number of slots filled with low-stacking items like ore. Higher numbers request more fuel.
-chest: [side] This specifies what side the chest at the end will be on. You can say "top", "bottom", "front", "left", or "right"
-enderChest: This one is special. If you use "-enderChest true" then it will use an enderChest in the default slot. However, you can also do "-enderChest [slot]" then it will take the ender chest from whatever slot you tell it to. Like 7... or 14... or whatever.
-GPS: [force] If you use "-GPS" and there is a GPS network, then the turtle will record its first two positions to precisly calculate its position if it has to restart. This will only take two GPS readings
-sendChannel: [number] This is what channel your turtle will send rednet messages on
-receiveChannel: [number] This is what channel your turtle will receive rednet messages on
-startY: [current Y coord] Randomly encountering bedrock? This is the parameter for you! Just give it what y coordinate you are at right now. If it is not within bedrock range, it will never say it found bedrock
-maxTries: [number] This is the number of times the turtle will try to dig before deciding its run into bedrock.
-logging: [t/f] If true, will record information about its mining run in a folder at the end of the mining run
-doBackup: [t/f] If false, will not back up important information and cannot restore, but will not make an annoying file (Actually I don't really know why anyone would use this...)
-saveFile: [word] This is what the backup file will be called
-logFolder: [word] The folder that quarry logs will be stored in
-logExtension: [word] The extension given to each quarry log (e.g. ".txt" or ".notepad" or whatever)
-invCheckFreq: [number] This is how often the turtle will check if it has the proper amount of slots open
-keepOpen: [number] This is the number of the slots the turtle will make sure are open. It will check every invCheckFreq blocks
-careAboutResources: [t/f] Who cares about the materials! If set to false, it will just keep mining when its inventory is full
-startDown: [number] If you set this, the turtle will go down this many blocks from the start before starting its quarry
  =
  C _ |
      |
      |
      |
      |_ _ _ _ >
-manualPos: [xPos] [zPos] [yPos] [facing] This is for advanced use. If the server reset when the turtle was in the middle of a 100x100x100 quarry, fear not, you can now manually set the position of the turtle. yPos is always positive. The turtle's starting position is 0, 1, 1, 0. Facing is measured 0 - 3. 0 is forward, and it progresses clockwise. Example- "-manualPos 65 30 30 2"
-help: Thats what this is :D
Examples: Everything below is examples and tips for use
Important Note:
  None of the above parameters are necessary. They all have default values, and the above are just if you want to change them.
Examples [1]: 
  Want to just start a quarry from the interface, without going through menus? It's easy! Just use some parameters. Assume you called the program "quarry." To start a 10x6x3 quarry, you just type in "quarry -dim 10 6 3 -default". 
  You just told it to start a quarry with dimensions 10x6x3, and "-default" means it won't prompt you about invert or rednet. Wasn't that easy?
Examples [2]:
  Okay, so you've got the basics of this now, so if you want, you can type in really long strings of stuff to make the quarry do exactly what you want. Now, say you want a 40x20x9, but you want it to go down to diamond level, and you're on the surface (at y = 64). You also want it to send rednet messages to your computer so you can see how its doing. 
Examples [2] [cont.]:
  Oh yeah! You also want it to use an ender chest in slot 12 and restart if the server crashes. Yeah, you can do that. You would type
  "quarry -dim 40x20x9 -invert false -startDown 45 -rednet true -enderChest 12 -restore"
  BAM. Now you can just let that turtle do it's thing
Tips:
  The order of the parameters doesn't matter. "quarry -invert false -rednet true" is the same as "quarry -rednet true -invert false"
  
  Capitalization doesn't matter. "quarry -iNVErt FALSe" does the same thing as "quarry -invert false"
Tips [cont.]:
  For [t/f] parameters, you can also use "yes" and "no" so "quarry -invert yes"
  
  For [t/f] parameters, it only cares about the first letter. So you can use "quarry -invert t" or "quarry -invert y"
Tips [cont.]:
  If you are playing with fuel turned off, the program will automatically change settings for you so you don't have to :D
  
  If you want, you can load this program onto a computer, and use "quarry -help" so you can have help with the parameters whenever you want.
Internal Config:
  At the top of this program is an internal configuration file. If there is some setup that you use all the time, you can just change the config value at the top and run "quarry -default" for a quick setup.
  
  You can also use this if there are settings that you don't like the default value of.
]]

--Parsing help for display
--[[The way the help table works:
All help indexes are numbered. There is a help[i].title that contains the title,
and the other lines are in help[i][1] - help[i][#help[i] ]
Different lines (e.g. other than first) start with a space.
As of now, the words are not wrapped, fix that later]]
local help = {}
local i = 0
local titlePattern = ".-%:" --Find the beginning of the line, then characters, then a ":"
local textPattern = "%:.+" --Find a ":", then characters until the end of the line
for a in help_paragraph:gmatch("\n?.-\n") do --Matches in between newlines
local current = string.sub(a,1,-2).."" --Concatenate Trick
if string.sub(current,1,1) ~= " " then
i = i + 1
help[i] = {}
help[i].title = string.sub(string.match(current, titlePattern),1,-2)..""
help[i][1] = string.sub(string.match(current,textPattern) or " ",3,-1)
elseif string.sub(current,1,1) == " " then
table.insert(help[i], string.sub(current,2, -1).."")
end
end


local supportsRednet = (peripheral.wrap("right") ~= nil)

local tArgs = {...}
--You don't care about these
      xPos,yPos,zPos,facing,percent,mined,moved,relxPos, rowCheck, connected, isInPath, layersDone, attacked, startY, chestFull, gotoDest, atChest, fuelLevel, numDropOffs
    = 0,   1,   1,   0,     0,      0,    0,    1,       true   ,  false,     true,     1,          0,        0,      false,     "",       false,   0,         0
    
--NOTE: rowCheck is a bit. true = "right", false = "left"
    
local foundBedrock = false

local totals = {cobble = 0, fuel = 0, other = 0} -- Total for display (cannot go inside function)
local function count() --Done any time inventory dropped and at end
  slot = {}        --1: Cobble 2: Fuel 3:Other
  for i=1, 16 do   --[1] is type, [2] is number
    slot[i] = {}
    slot[i][2] = turtle.getItemCount(i)
  end
  slot[1][1] = 1   -- = Assumes Cobble/Main
  for i=1, 16 do   --Cobble Check
    turtle.select(i)
    if turtle.compareTo(1)  then
      slot[i][1] = 1
      totals.cobble = totals.cobble + slot[i][2]
    elseif turtle.refuel(0) then
      slot[i][1] = 2
      totals.fuel = totals.fuel + slot[i][2]
    else
      slot[i][1] = 3
      totals.other = totals.other + slot[i][2]
    end
  end
  turtle.select(1)
end

local getFuel, checkFuel
if turtle then
  getFuel = turtle.getFuelLevel  --This is for cleanup at the end
  do --Common variable name...
  local flag = turtle.getFuelLevel() == "unlimited"--Unlimited screws up my calculations
  if flag then --Fuel is disabled
    turtle.getFuelLevel = function() return math.huge end --Infinite Fuel
  end --There is no "else" because it will already return the regular getFuel
  end
  checkFuel = turtle.getFuelLevel --Just an alias for backwards compat
end

 -----------------------------------------------------------------
--Input Phase
local function screen(xPos,yPos)
xPos, yPos = xPos or 1, yPos or 1
term.setCursorPos(xPos,yPos); term.clear(); end
local function screenLine(xPos,yPos)
term.setCursorPos(xPos,yPos); term.clearLine(); end

screen(1,1)
print("----- Welcome to Quarry! -----")
print("")

local sides = {top = "top", right = "right", left = "left", bottom = "bottom", front = "front"} --Used to whitelist sides
local changedT, tArgsWithUpper = {}, {}
changedT.new = function(key, value) table.insert(changedT,{key, value}) end --Numeric list of lists
local function capitalize(text) return (string.upper(string.sub(text,1,1))..string.sub(text,2,-1)) end
for i=1, #tArgs do tArgsWithUpper[i] = tArgs[i]; tArgsWithUpper[tArgsWithUpper[i]] = i; tArgs[i] = tArgs[i]:lower(); tArgs[tArgs[i]] = i end --My signature key-value pair system, now with upper

local restoreFound, restoreFoundSwitch = false --Initializing so they are in scope
function addParam(name, displayText, formatString, forcePrompt, trigger, variableOverride) --To anyone that doesn't understand this very well, probably not your best idea to go in here.
  if trigger == nil then trigger = true end --Defaults to being able to run
  if not trigger then return end --This is what the trigger is for. Will not run if trigger not there
  if restoreFoundSwitch or tArgs["-default"] then forcePrompt = false end --Don't want to prompt if these
  local toGetText = name:lower() --Because all params are now lowered
  local formatType = formatString:match("^%a+"):lower() or error("Format String Unknown: "..formatString) --Type of format string
  local args = formatString:sub(({formatString:find(formatType)})[2] + 2).."" --Everything in formatString but the type and space
  local variable = variableOverride or name --Goes first to the override for name
  local func = loadstring("return "..variable)
  setfenv(func,getfenv(1))
  local originalValue = assert(func)() --This is the default value, for checking to add to changed table
  if originalValue == nil then error("From addParam, \""..variable.."\" returned nil",2) end --I may have gotten a wrong variable name
  local givenValue, toRet --Initializing for use
  if tArgs["-"..toGetText] then
    givenValue = tArgsWithUpper[tArgs["-"..toGetText]+1] --This is the value after the desired parameter
  elseif forcePrompt then
    write(displayText.."? ")
    givenValue = io.read()
  end
  if formatType == "force" then --This is the one exception. Should return true if givenValue is nothing
    toRet = (tArgs["-"..toGetText] and true) or false --Will return true if param exists, otherwise false
  end
  if not (givenValue or toRet) then return end --Don't do anything if you aren't given anything. Leave it as default, except for "force"
  if formatType == "boolean" then --All the format strings will be basically be put through a switch statement
    toRet = givenValue:sub(1,1):lower() == "y" or givenValue:sub(1,1):lower() == "t" --Accepts true or yes
    if formatString == "boolean special" then 
      toRet = givenValue:sub(1,1):lower() ~= "n" and givenValue:sub(1,1):lower() ~= "f" --Accepts anything but false or no
    end
  elseif formatType == "string" then
    toRet = givenValue:match("^[%w%.]+") --Basically anything not a space or control character etc
  elseif formatType == "number" then
    toRet = tonumber(givenValue) --Note this is a local, not the above so we don't change anything
    if not toRet then return end --We need a number... Otherwise compare errors
    toRet = math.abs(math.floor(toRet)) --Get proper integers
    local startNum, endNum = formatString:match("(%d+)%-(%d+)") --Gets range of numbers
    startNum, endNum = tonumber(startNum), tonumber(endNum)
    if not ((toRet >= startNum) and (toRet <= endNum)) then return end --Can't use these
  elseif formatType == "side" then
    local exclusionTab = {} --Ignore the wizardry here. Just getting arguments without format string
    for a in args:gmatch("%S+") do exclusionTab[a] = true end --This makes a list of the sides to not include
    if not exclusionTab[givenValue] then toRet = sides[givenValue] end --If side is not excluded
  elseif formatType == "list" then
    toRet = {}
    for a in args:gmatch("[^,]") do
      table.insert(toRet,a)
    end
  elseif formatType == "force" then --Do nothing, everything is already done
  else error("Improper formatType",2)
  end
  if toRet == nil then return end --Don't want to set variables to nil... That's bad
  tempParam = toRet --This is what loadstring will see :D
  local func = loadstring(variable.." = tempParam")
  setfenv(func, getfenv(1))
  func()
  tempParam = nil --Cleanup of global
  if toRet ~= originalValue then
    changedT.new(displayText, tostring(toRet))
  end
  return toRet
end

--Check if it is a turtle
if not(turtle or tArgs["help"] or tArgs["-help"] or tArgs["-?"] or tArgs["?"]) then --If all of these are false then
  print("This is not a turtle, you might be looking for the \"Companion Rednet Program\" \nCheck My forum thread for that")
  print("Press 'q' to quit, or any other key to start help ")
  if ({os.pullEvent("char")})[2] ~= "q" then tArgs.help = true else error("",0) end
end

if tArgs["help"] or tArgs["-help"] or tArgs["-?"] or tArgs["?"] then
  print("You have selected help, press any key to continue"); print("Use arrow keys to naviate, q to quit"); os.pullEvent("key")
  local pos = 1
  local key = 0
  while pos <= #help and key ~= keys.q do
    if pos < 1 then pos = 1 end
    screen(1,1) 
    print(help[pos].title)
    for a=1, #help[pos] do print(help[pos][a]) end
    repeat
      _, key = os.pullEvent("key")
    until key == 200 or key == 208 or key == keys.q
    if key == 200 then pos = pos - 1 end
    if key == 208 then pos = pos + 1 end
  end
  error("",0)
end

--Saving
addParam("doBackup", "Backup Save File", "boolean")
addParam("saveFile", "Save File Name", "string")

restoreFound = fs.exists(saveFile)
restoreFoundSwitch = (tArgs["-restore"] or tArgs["-resume"] or tArgs["-atchest"]) and restoreFound
if restoreFoundSwitch then
  local file = fs.open(saveFile,"r")
  local test = file.readAll() ~= ""
  file.close()
  if test then
    os.run(getfenv(1),saveFile) --This is where the actual magic happens
    numResumed = numResumed + 1
    if turtle.getFuelLevel() ~= math.huge then --If turtle uses fuel
      if fuelLevel - turtle.getFuelLevel() == 1 then
        if facing == 0 then xPos = xPos + 1
        elseif facing == 2 then xPos = xPos - 1
        elseif facing == 1 then zPos = zPos + 1
        elseif facing == 3 then zPos = zPos - 1 end
      elseif fuelLevel - turtle.getFuelLevel() ~= 0 then
        print("Very Strange Fuel in Restore Section...")
        print("Current: ",turtle.getFuelLevel())
        print("Saved: ",fuelLevel)
        print("Difference: ",fuelLevel - turtle.getFuelLevel())
        os.pullEvent("char")
      end
     end
    if gpsEnabled then --If it had saved gps coordinates
      print("Found GPS Start Coordinates") 
      local currLoc = {gps.locate(gpsTimeout)} or {}
      local backupPos = {xPos, yPos, zPos} --This is for comparing to later
      if #currLoc > 0 and #gpsStartPos > 0 and #gpsSecondPos > 0 then --Cover all the different positions I'm using
        print("GPS Position Successfully Read")
        if currLoc[1] == gpsStartPos[1] and currLoc[3] == gpsStartPos[3] then --X coord, y coord, z coord in that order
          xPos, yPos, zPos = 0,1,1
          if facing ~= 0 then turnTo(0) end
          print("Is at start")
        else
          if inverted then --yPos setting
          ------------------------------------------------FIX THIS
          end
          local function copyTable(tab) local toRet = {}; for a, b in pairs(tab) do toRet[a] = b end; return toRet end
          local a, b = copyTable(gpsStartPos), copyTable(gpsSecondPos) --For convenience
          if b[3] - a[3] == -1 then--If went north (-Z)
            a[1] = a[1] - 1 --Shift x one to west to create a "zero"
            xPos, zPos = -currLoc[3] + a[3], currLoc[1] + -a[1]
          elseif b[1] - a[1] == 1 then--If went east (+X)
            a[3] = a[3] - 1 --Shift z up one to north to create a "zero"
            xPos, zPos = currLoc[1] + -a[1], currLoc[3] + -a[3]
          elseif b[3] - a[3] == 1 then--If went south (+Z)
            a[1] = a[1] + 1 --Shift x one to east to create a "zero"
            xPos, zPos = currLoc[3] + a[3], -currLoc[1] + a[3]
          elseif b[1] - a[1] == -1 then--If went west (-X)
            a[3] = a[3] + 1 --Shift z down one to south to create a "zero"
            xPos, zPos = -currLoc[1] + a[1], -currLoc[3] + a[3]
          else
            print("Improper Coordinates")
            print("GPS Locate Failed, Using Standard Methods")        ----Maybe clean this up a bit to use flags instead.
          end  
        end
        print("X Pos: ",xPos)
        print("Y Pos: ",yPos)
        print("Z Pos: ",zPos)
        print("Facing: ",facing)
        for i=1, 3, 2 do --We want 1 and 3, but 2 could be coming back to start.
          if backupPos[i] ~= currLoc[i] then
            events = {} --We want to remove event queue if not in proper place, so won't turn at end of row or things.
          end
        end
      else
        print("GPS Locate Failed, Using Standard Methods")
      end    
    print("Restore File read successfully. Starting in 3"); sleep(3)
    end
  else
    fs.delete(saveFile)
    print("Restore file was empty, sorry, aborting")
    error("",0)
  end
else --If turtle is just starting
  events = {} --This is the event queue :D
  originalFuel = checkFuel() --For use in logging. To see how much fuel is REALLY used
end

--Dimensions
if tArgs["-dim"] then 
  local a,b,c = x,y,z
  local num = tArgs["-dim"]
  x = tonumber(tArgs[num + 1]) or x; z = tonumber(tArgs[num + 2]) or z; y = tonumber(tArgs[num + 3]) or y
  if a ~= x then changedT.new("Length", x) end
  if c ~= z then changedT.new("Width", z) end
  if b ~= y then changedT.new("Height", y) end
elseif not (tArgs["-default"] or restoreFoundSwitch) then
  print("What dimensions?")
  print("")
  --This will protect from negatives, letters, and decimals
  term.write("Length? ")
  x = math.floor(math.abs(tonumber(io.read()) or x))
  term.write("Width? ")
  z = math.floor(math.abs(tonumber(io.read()) or z))
  term.write("Height? ")
  y = math.floor(math.abs(tonumber(io.read()) or y))
  changedT.new("Length",x); changedT.new("Width",z); changedT.new("Height",y)
end
--Invert
addParam("invert", "Inverted","boolean", true, nil, "inverted")
addParam("startDown","Start Down","number 1-256")
--Inventory
addParam("chest", "Chest Drop Side", "side front", nil, nil, "dropSide")
addParam("enderChest","Ender Chest Enabled","boolean special", nil, nil, "enderChestEnabled") --This will accept anything (including numbers) thats not "f" or "n"
addParam("enderChest", "Ender Chest Slot", "number 1-16", nil, nil, "enderChestSlot") --This will get the number slot if given
--Rednet
addParam("rednet", "Rednet Enabled","boolean",true, supportsRednet, "rednetEnabled")
addParam("gps", "GPS Location Services", "force", nil, (not restoreFoundSwitch) and supportsRednet, "gpsEnabled" ) --Has these triggers so that does not record position if restarted.
if gpsEnabled and not restoreFoundSwitch then
  gpsStartPos = {gps.locate(gpsTimeout)} --Stores position in array
  gpsEnabled = #gpsStartPos > 0 --Checks if location received properly. If not, position is not saved
end
addParam("sendChannel", "Rednet Send Channel", "number 1-65535", false, supportsRednet, "channels.send")
addParam("receiveChannel","Rednet Receive Channel", "number 1-65535", false, supportsRednet, "channels.receive")
--Fuel
addParam("uniqueExtras","Unique Items", "number 0-15")
addParam("doRefuel", "Refuel from Inventory","boolean", nil, turtle.getFuelLevel() ~= math.huge) --math.huge due to my changes
addParam("doCheckFuel", "Check Fuel", "boolean", nil, turtle.getFuelLevel() ~= math.huge)
--Logging
addParam("logging", "Logging", "boolean")
addParam("logFolder", "Log Folder", "string")
addParam("logExtension","Log Extension", "string")
--Misc
addParam("startY", "Start Y","number 1-256")
addParam("invCheckFreq","Inventory Check Frequency","number 1-342")
addParam("keepOpen", "Slots to Keep Open", "number 1-15")
addParam("careAboutResources", "Care About Resources","boolean")
addParam("maxTries","Tries Before Bedrock", "number 1-9001")
--Manual Position
if tArgs["-manualpos"] then --Gives current coordinates in xPos,zPos,yPos, facing
  local a = tArgs["-manualpos"]
  xPos, zPos, yPos, facing = tonumber(tArgs[a+1]) or xPos, tonumber(tArgs[a+2]) or zPos, tonumber(tArgs[a+3]) or yPos, tonumber(tArgs[a+4]) or facing
  changedT.new("xPos",xPos); changedT.new("zPos",zPos); changedT.new("yPos",yPos); changedT.new("facing",facing)
  restoreFoundSwitch = true --So it doesn't do beginning of quarry behavior
end
if addParam("atChest", "Is at Chest", "force") then --This sets position to 0,1,1, facing forward, and queues the turtle to go back to proper row.
  local neededLayer = math.floor((yPos+1)/3)*3-1 --Make it a proper layer, +- because mining rows are 2, 5, etc.
  if neededLayer > 2 and neededLayer%3 ~= 2 then --If turtle was not on a proper mining layer
    print("Last known pos was not in proper layer, restarting quarry")
    sleep(4)
    neededLayer = 2
  end
  xPos, zPos, yPos, facing, rowCheck, layersDone = 0,1,1, 0, true, math.ceil(neededLayer/3)
  events = {{"goto",1,1,neededLayer, 0}}
end


local function saveProgress(extras) --Session persistence
exclusions = { modem = true, }
if doBackup then
local toWrite = ""
for a,b in pairs(getfenv(1)) do
  if not exclusions[a] then
      --print(a ,"   ", b, "   ", type(b)) --Debug
    if type(b) == "string" then b = "\""..b.."\"" end
    if type(b) == "table" then b = textutils.serialize(b) end
    if type(b) ~= "function" then
      toWrite = toWrite..a.." = "..tostring(b).."\n"
    end
  end
end
toWrite = toWrite.."doCheckFuel = false\n" --It has already used fuel, so calculation unnesesary
local file
repeat
  file = fs.open(saveFile,"w")
until file --WHY DOES IT SAY ATTEMPT TO INDEX NIL!!!
file.write(toWrite)
if type(extras) == "table" then
  for a, b in pairs(extras) do
    file.write(a.." = "..tostring(b))
  end
end
if turtle.getFuelLevel() ~= math.huge then --Used for location comparing
  file.write("fuelLevel = "..tostring(turtle.getFuelLevel()))
end
file.close()
end
end

local area = x*z
local volume = x*y*z
local lastHeight = y%3
layers = math.ceil(y/3)
local yMult = layers --This is basically a smart y/3 for movement
local moveVolume = (area * yMult) --Kept for display percent
--Calculating Needed Fuel--
do --Because many local variables unneeded elsewhere
  local numItems = uniqueExtras --Convenience
  local itemSize = extrasStackSize
  local changeYFuel = 2*(y + startDown)
  local dropOffSupplies = 2*(x + z + y + startDown) --Assumes turtle as far away as possible, and coming back
  local frequency = math.floor(((volume/(64*(16-numItems))) ) --This is complicated: volume / inventory space of turtle, defined as (16-num unique stacks)
                                 * (layers/y)) --This is the ratio of height to actual height mined. Close to 1/3 usually, so divide above by 3
  if enderChestEnabled then frequency = 0 end
  neededFuel = moveVolume + changeYFuel + frequency * dropOffSupplies
end


--[[
local exStack = numberOfStacksPerRun --Expected stacks of items before full
neededFuel = yMult * x * z + --This is volume it will run through
      (startDown + y)*(2+1/(64*exStack)) + --This is simplified and includes the y to get up times up and down + how many times it will drop stuff off
      (x+z)*(yMult + 1/(64*exStack))  --Simplified as well: It is getting to start of row plus getting to start of row how many times will drop off stuff
      --Original equation: x*z*y/3 + y * 2 + (x+z) * y/3 + (x + z + y) * (1/64*8)
neededFuel = math.ceil(neededFuel)
]]
--Getting Fuel
if doCheckFuel and checkFuel() < neededFuel then
neededFuel = neededFuel + fuelTable[fuelSafety] --For safety
  print("Not enough fuel")
  print("Current: ",checkFuel()," Needed: ",neededFuel)
  print("Starting SmartFuel...")
  sleep(2) --So they can read everything.
  term.clear()
  local oneFuel, neededFuelItems
  local currSlot = 0
  local function output(text, x, y) --For displaying fuel
    local currX, currY = term.getCursorPos()
    term.setCursorPos(x,y)
    term.clearLine()
    term.write(text)
    term.setCursorPos(currX,currY)
    end
  local function roundTo(num, target) --For stacks of fuel
    if num >= target then return target elseif num < 0 then return 0 else return num end
  end
  local function updateScreen()
    output("Welcome to SmartFuel! Now Refueling...", 1,1)
    output("Currently taking fuel from slot "..currSlot,1,2)
    output("Current single fuel: "..tostring(oneFuel or 0),1,3)
    output("Current estimate of needed fuel: ",1,4)
    output("Single Items: "..math.ceil(neededFuelItems or 0),4,5)
    output("Stacks:       "..math.ceil((neededFuelItems or 0) / 64),4,6)
    output("Needed Fuel: "..tostring(neededFuel),1,12)
    output("Current Fuel: "..tostring(checkFuel()),1,13)
  end
  while checkFuel() <= neededFuel do
    currSlot = currSlot + 1
    turtle.select(currSlot)
    updateScreen()
    while turtle.getItemCount(currSlot) == 0 do sleep(1.5) end
    repeat
      local previous = checkFuel()
      turtle.refuel(1)
      oneFuel = checkFuel() - previous
      updateScreen()
    until (oneFuel or 0) > 0 --Not an if to prevent errors if fuel taken out prematurely.
    neededFuelItems = (neededFuel - checkFuel()) / oneFuel
    turtle.refuel(math.ceil(roundTo(neededFuelItems, 64))) --Change because can only think about 64 at once.
    if turtle.getItemCount(roundTo(currSlot + 1, 16)) == 0 then --Resets if no more fuel
      currSlot = 0
    end
    neededFuelItems = (neededFuel - checkFuel()) / oneFuel
  end
end
--Ender Chest Obtaining
function promptEnderChest()
  while turtle.getItemCount(enderChestSlot) ~= 1 do
    screen(1,1)
    print("You have decided to use an Ender Chest!")
    print("Please place one Ender Chest in slot ",enderChestSlot)
    sleep(1)
  end
  print("Ender Chest in slot ",enderChestSlot, " checks out")
end
if enderChestEnabled then
    if restoreFoundSwitch and turtle.getItemCount(enderChestSlot) == 0 then --If the turtle was stopped while dropping off items.
      turtle.select(enderChestSlot)
      turtle.dig()
      turtle.select(1)
    end
  promptEnderChest()
  sleep(2)
end
--Initial Rednet Handshake
if rednetEnabled then
screen(1,1)
print("Rednet is Enabled")
print("The Channel to open is "..channels.send)
modem = peripheral.wrap("right")
modem.open(channels.receive)
local i = 0
  repeat
    local id = os.startTimer(3)
    i=i+1
    print("Sending Initial Message "..i)
    modem.transmit(channels.send, channels.receive, channels.message)
    local message
    repeat
      local event, idCheck, channel,_,locMessage, distance = os.pullEvent()
      message = locMessage
    until (event == "timer" and idCheck == id) or (event == "modem_message" and channel == channels.receive and message == channels.confirm)
  until message == channels.confirm
connected = true
print("Connection Confirmed!")
sleep(1.5)
end
function biometrics(isAtBedrock)
  if not rednetEnabled then return end --This function won't work if rednet not enabled :P
  local toSend = { label = os.getComputerLabel() or "No Label", id = os.getComputerID(),
    percent = percent, relxPos = relxPos, zPos = zPos, xPos = xPos, yPos = yPos,
    layersDone = layersDone, x = x, z = z, layers = layers,
    openSlots = getNumOpenSlots(), mined = mined, moved = moved,
    chestFull = chestFull, isAtChest = (xPos == 0 and yPos == 1 and zPos == 1),
    isGoingToNextLayer = (gotoDest == "layerStart"), foundBedrock = foundBedrock,
    fuel = turtle.getFuelLevel(), volume = volume,
    }
  modem.transmit(channels.send, channels.receive, textutils.serialize(toSend))
  id = os.startTimer(0.1)
  local event, message
  repeat
    local locEvent, idCheck, confirm, _, locMessage, distance = os.pullEvent()
    event, message = locEvent, locMessage or ""
  until (event == "timer" and idCheck == id) or (event == "modem_message" and confirm == channels.receive)
  if event == "modem_message" then connected = true else connected = false end
  message = message:lower()
  if message == "stop" then error("Rednet said to stop...",0) end
  if message == "return" then
    endingProcedure()
    error('Rednet said go back to start...',0)
  end
  if message == "drop" then
    dropOff()
  end
end
--Showing changes to settings
screen(1,1)
print("Your selected settings:")
if #changedT == 0 then
print("Completely Default")
else
for i=1, #changedT do
print(changedT[i][1],": ",changedT[i][2]) --Name and Value
end
end
print("\nStarting in 3"); sleep(1); print("2"); sleep(1); print("1"); sleep(1.5) --Dramatic pause at end



----------------------------------------------------------------
--Define ALL THE FUNCTIONS
--Event System Functions
function eventAdd(...)
  return table.insert(events,1, {...}) or true
end
function eventGet(pos)
  return events[tonumber(pos) or #events]
end
function eventPop(pos)
  return table.remove(events,tonumber(pos) or #events) or false --This will return value popped, tonumber returns nil if fail, so default to end
end
function eventRun(value, ...)
  local argsList = {...}
  if type(value) == "string" then
    if value:sub(-1) ~= ")" then --So supports both "up()" and "up"
      value = value .. "("
      for a, b in pairs(argsList) do --Appending arguments
        local toAppend
        if type(b) == "table" then toAppend = textutils.serialize(b)
        elseif type(b) == "string" then toAppend = "\""..tostring(b).."\"" --They weren't getting strings around them
        else toAppend = tostring(b) end
        value = value .. (toAppend or "true") .. ", "
      end
      if value:sub(-1) ~= "(" then --If no args, do not want to cut off
        value = value:sub(1,-3)..""
      end
      value = value .. ")"
    end
    --print(value) --Debug
    local func = loadstring(value)
    setfenv(func, getfenv(1))
    return func()
  end
end
function eventClear(pos)
  if pos then events[pos] = nil else events = {} end
end   
function runAllEvents()
  while #events > 0 do
    local toRun = eventGet()
    --print(toRun[1]) --Debug
    eventRun(unpack(toRun))
    eventPop()
  end
end
--Inventory Related Functions
function isFull(slots)
  slots = slots or 16
  local numUsed = 0
  sleep(0)
  for i=1, 16 do
    if turtle.getItemCount(i) > 0 then numUsed = numUsed + 1 end
  end
  if numUsed > slots then
    return true 
  end
  return false
end

--Display Related Functions
function display() --This is just the last screen that displays at the end
  screen(1,1)
  print("Total Blocks Mined: "..mined)
  print("Current Fuel Level: "..turtle.getFuelLevel())
  print("Cobble: "..totals.cobble)
  print("Usable Fuel: "..totals.fuel)
  print("Other: "..totals.other)
  if rednetEnabled then
    print("")
    print("Sent Stop Message")
    local finalTable = {mined = mined, cobble = totals.cobble, fuelblocks = totals.fuel,
        other = totals.other, fuel = checkFuel() }
    modem.transmit(channels.send,channels.receive,"stop")
    sleep(0.5)
    modem.transmit(channels.send,channels.receive,textutils.serialize(finalTable))
    modem.close(channels.receive)
  end
  if doBackup then fs.delete(saveFile) end
end
function updateDisplay() --Runs in Mine(), display information to the screen in a certain place
screen(1,1)
print("Blocks Mined")
print(mined)
print("Percent Complete")
print(percent.."%")
print("Fuel")
print(checkFuel())
  -- screen(1,1)
  -- print("Xpos: ")
  -- print(xPos)
  -- print("RelXPos: ")
  -- print(relxPos)
  -- print("Z Pos: ")
  -- print(zPos)
  -- print("Y pos: ")
  -- print(yPos)
if rednetEnabled then
screenLine(1,7)
print("Connected: "..tostring(connected))
end
end
--Utility functions
function logMiningRun(textExtension, extras) --Logging mining runs
if logging then
local number
if not fs.isDir(logFolder) then
  fs.delete(logFolder)
  fs.makeDir(logFolder)
  number = 1
else
  local i = 0
  repeat
    i = i + 1
  until not fs.exists(logFolder.."/Quarry_Log_"..tostring(i)..(textExtension or ""))
  number = i
end
handle = fs.open(logFolder.."/Quarry_Log_"..tostring(number)..(textExtension or ""),"w")
local function write(...)
  for a, b in ipairs({...}) do
    handle.write(tostring(b))
  end
  handle.write("\n")
end
write("Welcome to the Quarry Logs!")
write("Entry Number: ",number)
write("Quarry Version: ",VERSION)
write("Dimensions (X Z Y): ",x," ",z," ", y)
write("Blocks Mined: ", mined)
write("  Cobble: ", totals.cobble)
write("  Usable Fuel: ", totals.fuel)
write("  Other: ",totals.other)
write("Total Fuel Used: ",  (originalFuel or (neededFuel + checkFuel()))- checkFuel()) --Protect against errors with some precision
write("Expected Fuel Use: ", neededFuel)
write("Days to complete mining run: ",os.day()-originalDay)
write("Number of times resumed: ", numResumed)
handle.close()
end
end
function dig(doAdd, func)
  doAdd = doAdd or true
  func = func or turtle.dig
  if func() then
    if doAdd then
      mined = mined + 1
    end
    return true
  end
  return false
end
if not inverted then --Regular functions :) I switch definitions for optimizatoin (I thinK)
  function digUp(doAdd)
    return dig(doAdd,turtle.digUp)
  end
  function digDown(doAdd)
    return dig(doAdd,turtle.digDown)
  end
else
  function digDown(doAdd)
    return dig(doAdd,turtle.digUp)
  end
  function digUp(doAdd)
    return dig(doAdd,turtle.digDown)
  end
end
function setRowCheckFromPos()
  rowCheck = (zPos % 2 == 1) --It will turn right at odd rows
end
function relxCalc()
  if rowCheck then relxPos = xPos else relxPos = (x-xPos)+1 end
end
function forward(doAdd)
  if doAdd == nil then doAdd = true end
  if turtle.forward() then
    if doAdd then
      moved = moved + 1
    end
    if facing == 0 then
      xPos = xPos + 1
    elseif facing == 1 then
      zPos = zPos + 1
    elseif facing == 2 then
      xPos = xPos - 1
    elseif facing == 3 then
      zPos = zPos - 1
    else
      error("Function forward, facing should be 0 - 3, got "..tostring(facing),2)
    end
    relxCalc()
    return true
  end
  return false
end
function up(sneak)
  sneak = sneak or 1
  if inverted and sneak == 1 then
    down(-1)
  else
    while not turtle.up() do --Absolute dig, not relative
      if not dig(true, turtle.digUp) then
        attackUp()
        sleep(0.5)
      end
    end
    yPos = yPos - sneak --Oh! I feel so clever
  end                   --This works because inverted :)
  saveProgress()
  biometrics()
end
function down(sneak)
  sneak = sneak or 1
  local count = 0
  if inverted and sneak == 1 then
    up(-1)
  else
    while not turtle.down() do
      count = count + 1
      if not dig(true, turtle.digDown) then --This is absolute dig down, not relative
        attackDown()
        sleep(0.2)
      end
      if count > 20 then bedrock() end
    end
    yPos = yPos + sneak
  end
  saveProgress()
  biometrics()
end
function right(num)
  num = num or 1
  for i=1, num do facing = coterminal(facing+1); saveProgress(); turtle.turnRight() end
end
function left(num)
  num = num or 1
  for i=1, num do facing = coterminal(facing-1); saveProgress(); turtle.turnLeft() end
end
function attack(doAdd, func)
  doAdd = doAdd or true
  func = func or turtle.attack
  if func() then
    if doAdd then 
      attacked = attacked + 1
    end
    return true
  end
  return false
end
function attackUp(doAdd)
  if inverted then
    return attack(doAdd, turtle.attackDown)
  else
    return attack(doAdd, turtle.attackUp)
  end
end
function attackDown(doAdd)
  if inverted then
    return attack(doAdd, turtle.attackUp)
  else
    return attack(doAdd, turtle.attackDown)
  end
end


function mine(doDigDown, doDigUp, outOfPath,doCheckInv) -- Basic Move Forward
  if doCheckInv == nil then doCheckInv = true end
  if doDigDown == nil then doDigDown = true end
  if doDigUp == nil then doDigUp = true end
  if outOfPath == nil then outOfPath = false end
  isInPath = (not outOfPath) --For rednet
  if inverted then
    doDigUp, doDigDown = doDigDown, doDigUp --Just Switch the two if inverted
  end
  if doRefuel and checkFuel() <= fuelTable[fuelSafety]/2 then
    for i=1, 16 do
    if turtle.getItemCount(i) > 0 then
      turtle.select(i)
      if checkFuel() < 200 + fuelTable[fuelSafety] then
        turtle.refuel()
      end
    end
    end
    turtle.select(1)
  end
  local count = 0
  while not forward(not outOfPath) do
    sleep(0) --Calls coroutine.yield to prevent errors
    count = count + 1
    if not dig() then
      attack()
    end
    if count > 10 then
      attack()
      sleep(0.2)
    end
    if count > maxTries then
      if turtle.getFuelLevel() == 0 then --Don't worry about inf fuel because I modified this function
        saveProgress({doCheckFuel = true})
        error("No more fuel",0)
      elseif yPos > (startY-7) and turtle.detect() then --If it is near bedrock
        bedrock()
      else --Otherwise just sleep for a bit to avoid sheeps
        sleep(1)
      end
    end
  end
  checkSanity() --Not kidding... This is necessary
  saveProgress(tab)
  if doDigUp then
  while turtle.detectUp() do 
    sleep(0) --Calls coroutine.yield
    if not dig(true,turtle.digUp) then --This needs to be an absolute, because we are switching doDigUp/Down
      attackUp()
      count = count + 1
    end
    if count > 50 and yPos > (startY-7) then --Same deal with bedrock as above
      bedrock()
    end
    end
  end
  if doDigDown then
   dig(true,turtle.digDown) --This needs to be absolute as well
  end
  percent = math.ceil(moved/moveVolume*100)
  updateDisplay()
  if doCheckInv and careAboutResources then
    if moved%invCheckFreq == 0 then
     if isFull(16-keepOpen) then dropOff() end
    end
  end
  biometrics()
end
--Insanity Checking
function checkSanity()
  if not isInPath then --I don't really care if its not in the path.
    return true
  end
  if not (facing == 0 or facing == 2) and #events == 0 then --If mining and not facing proper direction and not in a turn
    turnTo(0)
    rowCheck = true
  end
  if xPos < 0 or xPos > x or zPos < 0 or zPos > z or yPos < 0 then
    saveProgress()
    print("I have gone outside boundaries, attempting to fix (maybe)")
    if xPos > x then goto(x, zPos, yPos, 2) end --I could do this with some fancy math, but this is much easier
    if xPos < 0 then goto(1, zPos, yPos, 0) end
    if zPos > z then goto(xPos, z, yPos, 3) end
    if zPos < 0 then goto(xPos, 1, yPos, 1) end
    setRowCheckFromPos() --Row check right (maybe left later)
    relxCalc() --Get relxPos properly
    eventClear()
    
    --[[
    print("Oops. Detected that quarry was outside of predefined boundaries.")
    print("Please go to my forum thread and report this with a short description of what happened")
    print("If you could also run \"pastebin put Civil_Quarry_Restore\" and give me that code it would be great")
    error("",0)]]
  end
end

local function fromBoolean(input) --Like a calculator
if input then return 1 end
return 0
end
local function multBoolean(first,second) --Boolean multiplication
return (fromBoolean(first) * fromBoolean(second)) == 1
end
function coterminal(num, limit) --I knew this would come in handy :D
limit = limit or 4 --This is for facing
return math.abs((limit*fromBoolean(num < 0))-(math.abs(num)%limit))
end
if tArgs["-manualpos"] then
  facing = coterminal(facing) --Done to improve support for "-manualPos"
  if facing == 0 then rowCheck = true elseif facing == 2 then rowCheck = false end --Ditto
  relxCalc() --Ditto
end

--Direction: Front = 0, Right = 1, Back = 2, Left = 3
function turnTo(num)
  num = num or facing
  num = coterminal(num) --Prevent errors
  local turnRight = true
  if facing-num == 1 or facing-num == -3 then turnRight = false end --0 - 1 = -3, 1 - 0 = 1, 2 - 1 = 1
  while facing ~= num do          --The above is used to smartly turn
    if turnRight then
      right()
    else 
      left() 
    end
  end
end
function goto(x,z,y, toFace, destination)
  --Will first go to desired z pos, then x pos, y pos varies
  x = x or 1; y = y or 1; z = z or 1; toFace = toFace or facing
  gotoDest = destination or "" --This is used by biometrics
  --Possible destinations: layerStart, quarryStart
  if yPos > y then --Will go up first if below position
    while yPos~=y do up() end
  end
  if zPos > z then
    turnTo(3)
  elseif zPos < z then 
    turnTo(1)
  end
  while zPos ~= z do mine(false,false,true,false) end
  if xPos > x then
    turnTo(2)
  elseif xPos < x then
    turnTo(0)
  end
  while xPos ~= x do mine(false,false,true,false) end
  if yPos < y then --Will go down after if above position
    while yPos~=y do down() end
  end
  turnTo(toFace)
  saveProgress()
  gotoDest = ""
end
function getNumOpenSlots()
  local toRet = 0
  for i=1, 16 do
    if turtle.getItemCount(i) == 0 then
      toRet = toRet + 1
    end
  end
  return toRet
end
function drop(side, final, allowSkip)
side = sides[side] or "front"    --The final number means that it will
if final then final = 0 else final = 1 end --drop a whole stack at the end
local allowSkip = allowSkip or (final == 0) --This will allow drop(side,t/f, rednetConnected)
count()
if doRefuel then
  for i=1, 16 do
    if slot[i][1] == 2 then
      turtle.select(i); turtle.refuel()
    end
  end
  turtle.select(1)
end
if side == "right" then turnTo(1) end
if side == "left" then turnTo(3) end
local whereDetect, whereDrop1, whereDropAll
local _1 = slot[1][2] - final --All but one if final, all if not final
if side == "top" then
whereDetect = turtle.detectUp ; whereDrop = turtle.dropUp
elseif side == "bottom" then
whereDetect = turtle.detectDown ; whereDrop = turtle.dropDown
else
whereDetect = turtle.detect; whereDrop = turtle.drop
end
local function waitDrop(val) --This will just drop, but wait if it can't
  val = val or 64
  local try = 1
  while not whereDrop(val) do
    print("Chest Full, Try "..try)
    chestFull = true
    if rednetEnabled then --To send that the chest is full
      biometrics()
    end
    try = try + 1
    sleep(2)
  end
  chestFull = false
end
repeat
local detected = whereDetect()
if detected then
  waitDrop(_1)
  for i=1, 2 do --This is so I quit flipping missing items when chests are partially filled
    for i=2, 16 do
      if turtle.getItemCount(i) > 0 then
        turtle.select(i)
        waitDrop(nil, i)
      end
    end
  end
elseif not allowSkip then
  print("Waiting for chest placement place a chest to continue")
  while not whereDetect() do
    sleep(1)
  end
end
until detected or allowSkip
if not allowSkip then totals.cobble = totals.cobble - 1 end
turtle.select(1)
end

--Ideas: Bring in inventory change-checking functions, count blocks that have been put in, so it will wait until all blocks have been put in.
function drop(side, final, blacklist)
  side = sides[side] or "front"
  blacklist = blacklist or {}
  local function waitDrop(num, slot) --This will just drop, but wait if it can't
    num = num or 64
    local tries = 1
    while not whereDrop(num) do
      term.clear()
      term.setCursorPos(1,1)
      print("Chest Full, Try "..tries)
      chestFull = true
      biometrics()--To send that the chest is full
      tries = tries + 1
      sleep(2)
    end
    chestFull = false
  end

end

function dropOff() --Not local because called in mine()
  local currX,currZ,currY,currFacing = xPos, zPos, yPos, facing
  if careAboutResources then
    if not enderChestEnabled then --Regularly
      eventAdd("goto", 1,1,currY,2) --Need this step for "-startDown"
      eventAdd("goto(0,1,1,2)")
      eventAdd("drop", dropSide,false)
      eventAdd("turnTo(0)")
      eventAdd("mine",false,false,true,false)
      eventAdd("goto(1,1,1, 0)")
      eventAdd("goto", 1, 1, currY, 0)
      eventAdd("goto", currX,currZ,currY,currFacing)
    else --If using an enderChest
      if turtle.getItemCount(enderChestSlot) ~= 1 then eventAdd("promptEnderChest()") end
      eventAdd("turnTo",currFacing-2)
      eventAdd("dig",false)
      eventAdd("turtle.select",enderChestSlot)
      eventAdd("turtle.place")
      eventAdd("drop","front",false)
      eventAdd("turtle.select", enderChestSlot)
      eventAdd("dig",false)
      eventAdd("turnTo",currFacing)
      eventAdd("turtle.select(1)")
    end
  runAllEvents()
  numDropOffs = numDropOffs + 1 --Analytics tracking
  end
return true
end
function endingProcedure() --Used both at the end and in "biometrics"
  eventAdd("goto",1,1,yPos,2,"quarryStart") --Allows for startDown variable
  eventAdd("goto",0,1,1,2, "quarryStart") --Go back to base
  runAllEvents()
  --Output to a chest or sit there
  if enderChestEnabled then
    while turtle.detect() do dig(false) end --This gets rid of blocks in front of the turtle.
    eventAdd("turtle.select",enderChestSlot)
    eventAdd("turtle.place")
    eventAdd("turtle.select(1)")
  end
  eventAdd("drop",dropSide, true)
  eventAdd("turnTo(0)")

  --Display was moved above to be used in bedrock function
  eventAdd("display")
  --Log current mining run
  eventAdd("logMiningRun",logExtension)
  toQuit = true --I'll use this flag to clean up
  runAllEvents()
  --Cleanup
  turtle.getFuelLevel = getFuel
end
function bedrock()
  foundBedrock = true --Let everyone know
  if rednetEnabled then biometrics() end
  if checkFuel() == 0 then error("No Fuel",0) end
  local origin = {x = xPos, y = yPos, z = zPos}
  print("Bedrock Detected")
  if turtle.detectUp() then
    print("Block Above")
    local var
    if facing == 0 then var = 2 elseif facing == 2 then var = 0 else error("Was facing left or right on bedrock") end
    goto(xPos,zPos,yPos,var)
    for i=1, relxPos do mine(false, false); end
  end
  eventClear() --Get rid of any excess events that may be run. Don't want that.
  endingProcedure()
  print("\nFound bedrock at these coordinates: ")
  print(origin.x," Was position in row\n",origin.z," Was row in layer\n",origin.y," Blocks down from start")
  error("",0)
end

function endOfRowTurn(startZ, wasFacing, mineFunctionTable)
local halfFacing = 1
local toFace = coterminal(wasFacing + 2) --Opposite side
if zPos == startZ then
  if facing ~= halfFacing then turnTo(halfFacing) end
  mine(unpack(mineFunctionTable or {}))
end
if facing ~= toFace then
  turnTo(toFace)
end
end


-------------------------------------------------------------------------------------
--Pre-Mining Stuff dealing with session persistence
runAllEvents()
if toQuit then error("",0) end --This means that it was stopped coming for its last drop

local doDigDown, doDigUp = (lastHeight ~= 1), (lastHeight == 0) --Used in lastHeight
if not restoreFoundSwitch then --Regularly
  --Check if it is a mining turtle
  if not isMiningTurtle then
    local a, b = turtle.dig()
    if a then mined = mined + 1; isMiningTurtle = true
    elseif b == "Nothing to dig with" then 
      print("This is not a mining turtle. To make a mining turtle, craft me together with a diamond pickaxe")
      error("",0)
    end
  end
  mine(false,false,true) --Get into quarry by going forward one
  if gpsEnabled and not restoreFoundSwitch then --The initial locate is done in the arguments. This is so I can figure out what quadrant the turtle is in.
    gpsSecondPos = {gps.locate(gpsTimeout)} --Note: Does not run this if it has already been restarted.
  end
  for i = 1, startDown do
    eventAdd("down") --Add a bunch of down events to get to where it needs to be.
  end
  runAllEvents()
  if not(y == 1 or y == 2) then down() end --Go down. If y is one or two, it doesn't need to do this.
else --restore found
  if not(layersDone == layers and not doDigDown) then digDown() end
  if not(layersDone == layers and not doDigUp) then digUp() end  --Get blocks missed before stopped
end
--Mining Loops--------------------------------------------------------------------------
turtle.select(1)
while layersDone <= layers do -------------Height---------
local lastLayer = layersDone == layers --If this is the last layer
local secondToLastLayer = (layersDone + 1) == layers --This is for the going down at the end of a layer.
moved = moved + 1 --To account for the first position in row as "moved"
if not(layersDone == layers and not doDigDown) then digDown() end --This is because it doesn't mine first block in layer
if not restoreFoundSwitch then rowCheck = true end
relxCalc()
while zPos <= z do -------------Width----------
while relxPos < x do ------------Length---------
mine(not lastLayer or (doDigDown and lastLayer), not lastLayer or (doDigUp and lastLayer)) --This will be the idiom that I use for the mine function
end ---------------Length End-------
if zPos ~= z then --If not on last row of section
  local func
  if rowCheck == true then --Swithcing to next row
  func = "right"; rowCheck = false; else func = false; rowCheck = true end --Which way to turn
    eventAdd("endOfRowTurn", zPos, facing , {not lastLayer or (doDigDown and lastLayer), not lastLayer or (doDigUp and lastLayer)}) --The table is passed to the mine function
    runAllEvents()
else break
end
end ---------------Width End--------
eventAdd("goto",1,1,yPos,0, "layerStart") --Goto start of layer
if not lastLayer then --If there is another layer
  for i=1, 2+fromBoolean(not(lastHeight~=0 and secondToLastLayer)) do eventAdd("down()") end --The fromBoolean stuff means that if lastheight is 1 and last and layer, will only go down two
end
eventAdd("setRowCheckFromPos")
eventAdd("relxCalc")
layersDone = layersDone + 1
restoreFoundSwitch = false --This is done so that rowCheck works properly upon restore
runAllEvents()
end ---------------Height End-------

endingProcedure() --This takes care of getting to start, dropping in chest, and displaying ending screen
