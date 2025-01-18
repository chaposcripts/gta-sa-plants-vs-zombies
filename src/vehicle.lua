local Utils = require('utils');
local Map = require('map');
local font = renderCreateFont('arial', 8, 5); -- For debug info
local Vehicles = {
    Vehicle = {},
    pool = {}
};

local VEHICLE_MODEL = 572;
local VEHICLE_MOVEMENT_UPDATE_RATE = 0.1;

---@class Vehicle
---@field handle number
---@field movement {started: boolean, x: number, startTime: number}

setmetatable(Vehicles.Vehicle, {__call = function(t, ...)
    return t:new(...);
end});

function Vehicles.destroy()
    for _, hero in ipairs(Vehicles.pool) do
        hero:destroy();
    end
end

function Vehicles.init()
    if (not hasModelLoaded(VEHICLE_MODEL)) then
        requestModel(VEHICLE_MODEL);
        loadAllModelsNow();
    end

    addEventHandler('onScriptTerminate', function(scr)
        if (scr == thisScript()) then
            Vehicles.destroy();
        end
    end);
end

function Vehicles.process(enemyPool, heroPool)
    for index, vehicle in ipairs(Vehicles.pool) do
        vehicle:process(enemyPool, heroPool);
    end
end

function Vehicles.Vehicle:process(enemyPool, heroPool)
    print(#enemyPool)
    if (self.movementStartTime) then
        local newX = Utils.bringFloatTo(self.startX, self.endX, self.movementStartTime, 5);
        setCarCoordinates(self.handle, newX, self.spawnPos.y, self.spawnPos.z);
        if (newX >= self.endX) then
            self.movementStartTime = nil;
            self:destroy();
            return;
        end
    end
    
    local x, y, z = getCarCoordinates(self.handle);
    local sx, sy = convert3DCoordsToScreen(x, y, z);
    for _, entity in ipairs(Utils.mergeTable(enemyPool, heroPool)) do
        if (not doesCharExist(entity.handle)) then return end
        if (DEV) then
            local ex, ey = convert3DCoordsToScreen(getCharCoordinates(entity.handle));
            renderDrawLine(sx, sy, ex, ey, 1, 0xFF0000ff);
        end
        if (getDistanceBetweenCoords3d(x, y, z, getCharCoordinates(entity.handle)) <= 1) then
            Utils.debugMsg('ped tounching veh, ped', entity.handle, 'veh', self.handle);
            if (not self.movementStartTime) then
                self.movementStartTime = os.clock();
            end
            entity:kill();
        end
    end

    if (DEV) then
        renderFontDrawText(font, ('Handle: %d\nX: %0.2f'):format(self.handle, x), sx, sy, 0xFFffffff, false);
    end
end

function Vehicles.Vehicle:startMovement()
    self.movementStartTime = os.clock();
end

function Vehicles.Vehicle:destroy()
    if (doesVehicleExist(self.handle)) then
        print('deleting veh with handle', self.handle);
        deleteCar(self.handle);
        for k, v in ipairs(Vehicles.pool) do
            if (v.handle == self.handle) then
                table.remove(Vehicles.pool, k);
            end
        end
    end
end

---@param line number
---@return Vehicle
function Vehicles.Vehicle:new(line)
    local spawnPos = Map.getGridPos(line, 0);
    local vehicleHandle = createCar(VEHICLE_MODEL, spawnPos.x, spawnPos.y, spawnPos.z); ---@diagnostic disable-line
    setCarHeading(vehicleHandle, 270);
    local instance = {
        handle = vehicleHandle,
        movementStartTime = nil,
        spawnPos = spawnPos,
        startX = spawnPos.x,
        endX = 43
    };

    local newMeta = setmetatable(instance, {__index = self});
    table.insert(Vehicles.pool, newMeta);
    return newMeta;
end

return Vehicles;