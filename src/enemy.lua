local Map = require('map');
local Utils = require('utils');
local Vector3D = require('vector3d');

local Enemies = {
    Enemy = {},
    pool = {}
};

setmetatable(Enemies.Enemy, {__call = function(t, ...)
    return t:new(...)
end})

---@enum EnemyType
local EnemyType = {
    Default = 1,
    Strong = 2
};

---@class EnemyData
---@field name string
---@field model number
---@field maxHealth number
---@field attackAnimation? Animation
---@field attackInterval? number
---@field weapon? number
---@field animationSpeed? number
---@field lastAttack? number
---@field route? {to: Vector3D, from: Vector3D}
---@field spawnedAt? number
---@field handle? number
---@field disableProcess? boolean
---@field grid? {line: number, index: number}
---@field line? number
---@field health? number
---@field x? number
---@field lastXUpdate? number

---@class Enemy

---@type table<EnemyType, EnemyData>
local EnemyData = {
    [EnemyType.Default] = {
        model = 267,
        name = 'placeholder',
        maxHealth = 100,
        damage = 33,
        attackInterval = 5,
        attackAnimation = {
            file = 'FIGHT_B',
            name = 'FightB_M'
        }
    },
    [EnemyType.Strong] = {
        name = 'SWAT',
        model = 285,
        maxHealth = 300,
        attackInterval = 5
    }
};

function Enemies.destroy()
    for _, enemy in ipairs(Enemies.pool) do
        enemy:destroy();
        print('Destroyed enemy', enemy.handle);
    end
end

function Enemies.init()
    for _, v in pairs(EnemyData) do
        if (not hasModelLoaded(v.model)) then ---@diagnostic disable-line
            requestModel(v.model); ---@diagnostic disable-line
            loadAllModelsNow();
            print('Model', v.model, 'was loaded.');
        end
    end

    addEventHandler('onScriptTerminate', function(scr)
        if (scr == thisScript()) then
            Enemies.destroy();
        end
    end);
end

function Enemies.process(enemiesPool, heroPool)
    for _, enemy in ipairs(enemiesPool) do
        if (doesCharExist(enemy.handle)) then
            enemy:process(heroPool);
        end
    end
end

---@param pos Vector3D
function Enemies.Enemy:setCoordinates(pos)
    pos.z = Map.pos.z + 1;
    local ptr = getCharPointer(self.handle);
    if (not ptr) then
        return print('WARNING, unable to set entity coordinates, ptr == nil, handle =', self.handle);
    end

    local matrixPtr = readMemory(ptr + 0x14, 4, false);
    if (matrixPtr == 0) then
        return print('WARNING, unable to set entity coordinates, matrix pointer == nil, handle =', self.handle);
    end

    local posPtr = matrixPtr + 0x30;
    writeMemory(posPtr + 0, 4, representFloatAsInt(pos.x), false);
    writeMemory(posPtr + 4, 4, representFloatAsInt(pos.y), false);
    writeMemory(posPtr + 8, 4, representFloatAsInt(pos.z), false);
end

function Enemies.Enemy:kill()
    setCharCoordinates(self.handle, 0, 0, -100);
    self.disableProcess = true;
end
local font = renderCreateFont('arial', 8, 5); -- For debug info
local ENEMY_MAP_PASS_TIME = 100;
local ENEMY_ROUTE_LENGTH = 50;
local MAP_START = 50;
local MAP_END = 0;
local ENEMY_X_UPDATE_SPEED = 0.01;
---@param enemy Enemy
local function calculateEnemyPosition(enemy)
    
    return 1;
end

---@return number
function Enemies.Enemy:getDistanceToFinish()
    return getDistanceBetweenCoords3d(self.route.to.x, self.route.to.y, self.route.to.z, getCharCoordinates(self.handle));
end

function Enemies.Enemy:process(heroPool)
    -- print('Processing enemy', self.handle);
    if (not self.disableProcess) then
        local currentPos = Vector3D(getCharCoordinates(self.handle));

        local targetEndGrid = Map.getGridPos(self.line, 0);
        targetEndGrid.z = targetEndGrid.z + 1;
        local isPlantFound, colpoint = processLineOfSight(currentPos.x, currentPos.y, currentPos.z, targetEndGrid.x, targetEndGrid.y, targetEndGrid.z, false, false, true, false, false, false, false, false);
        local distanceToTarget = colpoint == nil and -1 or getDistanceBetweenCoords3d(currentPos.x, currentPos.y, currentPos.z, colpoint.pos[1], colpoint.pos[2], colpoint.pos[3]);

        if (not isPlantFound or distanceToTarget > 1.5) then
            -- taskCharSlideToCoord(self.handle, 0, 0, 0, 0, 1);
            if (os.clock() - self.lastXUpdate > ENEMY_X_UPDATE_SPEED) then
                self:setCoordinates(Vector3D(currentPos.x - (DEV and 0.3 or 0.01), currentPos.y, currentPos.z));
                self.lastXUpdate = os.clock();
            end
        else
            if (colpoint.entityType == 3) then
                local targetHandle = getCharPointerHandle(colpoint.entity);
                if (not doesCharExist(targetHandle)) then
                    return print('ERROR: cannot get target handle for enemy!');
                end
                
                -- Deal damage to target
                local timeSinceLastAttack = os.clock() - self.lastAttack;
                if (timeSinceLastAttack > self.attackInterval) then
                    for _, v in pairs(heroPool) do
                        if (v.handle == targetHandle) then
                            v:dealDamage(self.damage, self);
                            v:call('onDamageReceived', self.damage, self);
                            if (self.attackAnimation and hasAnimationLoaded(self.attackAnimation.file)) then
                                clearCharTasksImmediately(self.handle);
                                taskPlayAnim(self.handle, self.attackAnimation.name, self.attackAnimation.file, 4.0, false, true, true, true, 0);
                            else
                                print('WARNING: Missing animation for enemy!');
                            end
                            self.lastAttack = os.clock();
                            break;
                        end
                    end
                end
            end
        end

        if (DEV) then
            local x, y = convert3DCoordsToScreen(currentPos.x, currentPos.y, currentPos.z);
            local x2, y2 = convert3DCoordsToScreen(targetEndGrid.x, targetEndGrid.y, targetEndGrid.z);
            renderDrawLine(x, y, x2, y2, 1, isPlantFound and 0xFFffff00 or 0xFF00ffff);
            renderFontDrawText(font, ('HP: %s\nTarget: %s\nDist: %0.2f\nDist to end: %0.2f\nX: %s'):format(tostring(self.health), tostring(isPlantFound), distanceToTarget, self:getDistanceToFinish(), self.x), x, y, 0xFFffffff, false);
        end
    end
end


function Enemies.Enemy:processMovement()
    

end

---@param damage number
---@param from Hero
function Enemies.Enemy:dealDamage(damage, from)
    self.health = self.health - damage;
    if (self.health <= 0) then
        self:kill();
    end
end

function Enemies.Enemy:destroy()
    if (doesCharExist(self.handle)) then
        deleteChar(self.handle);
        for k, v in ipairs(Enemies.pool) do
            if (v.handle == self.handle) then
                table.remove(Enemies.pool, k);
            end
        end
        print('Enemy was destroyed, handle = ', self.handle);
    end
end

---@param type EnemyType
---@param line number
---@param disableMovement? boolean
function Enemies.Enemy:new(type, line, disableMovement)
    assert(EnemyData[type], 'Unknown enemy type: ' .. type);
    local instance = Utils.copyTable(EnemyData[type]);
    local spawnPos = Map.getGridPos(line, 10);
    spawnPos.z = spawnPos.z + 1;
    local ped = createChar(4, instance.model, spawnPos.x, spawnPos.y, spawnPos.z - 2); ---@diagnostic disable-line
    freezeCharPosition(ped, false);
    -- taskWanderStandard(ped);
    clearCharTasksImmediately(ped);
    setCharCoordinates(ped, getCharCoordinates(ped));
    setCharHeading(ped, 90);
    instance.x = spawnPos.x;
    instance.lastXUpdate = os.clock();
    instance.health = instance.maxHealth;
    instance.handle = ped; ---@diagnostic disable-line
    instance.line = line;
    instance.lastAttack = os.clock();
    instance.route = {
        from = spawnPos,
        to = Map.getGridPos(line, 0)
    };
    instance.grid = {
        line = line
    };
    instance.spawnedAt = os.clock();
    instance.disableProcess = disableMovement;
    -- instance.startDist = self:getDistanceToFinish();
    if (not disableMovement) then
        -- taskCharSlideToCoord(ped, 0, 0, 0, 0, 1);
    end
    local newMeta = setmetatable(instance, {__index = self});
    newMeta.startDist = newMeta:getDistanceToFinish();
    table.insert(Enemies.pool, newMeta);
    Utils.msg('new enemy spawned, pool len:', #Enemies.pool);
    return newMeta;
end

return Enemies;