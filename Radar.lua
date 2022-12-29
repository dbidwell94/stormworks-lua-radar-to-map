--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey


--[====[ HOTKEYS ]====]
-- Press F6 to simulate this file
-- Press F7 to build the project, copy the output from /_build/out/ into the game to use
-- Remember to set your Author name etc. in the settings: CTRL+COMMA


--[====[ EDITABLE SIMULATOR CONFIG - *automatically removed from the F7 build output ]====]
---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "9x5")
    simulator:setProperty("ExampleNumberProperty", 123)
    simulator:setProperty("radarDishMaxRange", 1000)
    rotation = 0

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.width)
        simulator:setInputNumber(2, screenConnection.height)
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)
        simulator:setInputNumber(20, rotation)
        simulator:setInputNumber(22, 25)


        -- NEW! button/slider options from the UI
        simulator:setInputBool(31, simulator:getIsClicked(1)) -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(31, simulator:getSlider(1)) -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2)) -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(32, simulator:getSlider(2) * 50) -- set input 32 to the value from slider 2 * 50
        rotation = rotation + 0.005
    end
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!

require("LifeBoatAPI")
lbMath = LifeBoatAPI.LBMaths
Vector = LifeBoatAPI.LBVec


function Radar()
    local toReturn = {}
    toReturn.channels = { [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {}, [7] = {}, [8] = {} }
    toReturn.update = function()
        toReturn.rotation = (input.getNumber(20) % 1) * 360
        for k, v in pairs(toReturn.channels) do
            v.distance = input.getNumber(1 + (2 * (k - 1)))
            v.direction = lbMath.lbmaths_radsToDegrees *
                (input.getNumber(2 + (2 * (k - 1))) * lbMath.lbmaths_turnsToRads)
            v.detected = v.distance > 0
        end
    end
    return toReturn
end

---@type number
local myRotation
---@type number
local searchRange = property.getNumber('radarDishMaxRange')
---@type number
local mapRadius = nil;
---@type LBVec
local currentPos = Vector:new()
---@type table | nil
local screenSize = nil
---@type number | nil
local mapZoomAmount = 25
local radarInput = Radar()

---@return number
function getMapRadius(zoom)
    local sc = screenSize or { x = 0, y = 0 }
    local mapPointX, mapPointY = map.mapToScreen(currentPos.x, currentPos.y, zoom, sc.x,
        sc.y, currentPos.x + searchRange, currentPos.y)

    local mapPointVec = Vector:new(mapPointX, mapPointY)
    local centerVec = Vector:new(sc.x / 2, sc.y / 2)

    return centerVec:lbvec_distance(mapPointVec)
end

--[[
    Called once every frame. Logic goes here
--]]
function onTick()
    mapZoomAmount = input.getNumber(22)
    currentPos = Vector:new(input.getNumber(17), input.getNumber(18))
    myRotation = (input.getNumber(20) % 1) * 360
    radarInput.update()
    output.setNumber(1, radarInput.rotation)
end

--[[
    Called once every frame. Draw calls go here
--]]
function onDraw()
    screenSize = LifeBoatAPI.LBVec:new(screen.getWidth(), screen.getHeight())

    local centerPos = Vector:new(screenSize.x / 2, screenSize.y / 2)
    mapRadius = getMapRadius(mapZoomAmount)

    screen.drawMap(currentPos.x, currentPos.y, mapZoomAmount);
    screen.setColor(0, 255, 0)
    screen.drawCircleF(centerPos.x, centerPos.y, 1)

    -- Draw radar range circle
    screen.drawCircle(centerPos.x, centerPos.y, mapRadius)

    -- Draw radar line
    local x2 = centerPos.x + mapRadius * math.cos(radarInput.rotation * lbMath.lbmaths_degsToRads)
    local y2 = centerPos.y + mapRadius * math.sin(radarInput.rotation * lbMath.lbmaths_degsToRads)
    screen.drawLine(centerPos.x, centerPos.y, x2, y2)
end
