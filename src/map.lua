local Vector3D = require('vector3d');
local Object = require('object');

local Map = {
    pos = Vector3D(0, 0, 100),
    pedPos = Vector3D(-9.5483312606812, 9.7751541137695, 101.42999267578),
    pedHeading = 180,
    pool = {},
    lastEnemySpawned = os.clock()
};

local GRID_SIZE = 5;

function Map.destroy()
    print('deleting all objects, count:', #Map.pool);
    for _, object in pairs(Map.pool) do
        print('deleting obj', object.handle);
        deleteObject(object.handle);
    end
end

---@param pos Vector3D
---@return number? handle
---@return number?
---@return number?
---@return Vector3D?
function Map.findAllPedsInGrid(pos)
    for _, pedHandle in ipairs(getAllChars()) do
        local line, index, gridCenter = Map.getGridForCoord(Vector3D(getCharCoordinates(pedHandle)));
        if (line == -1) then
            return pedHandle, line, index, gridCenter;
        end
    end
    return
end

function Map.init(Vehicles)
    -- Create ground (grass)
    table.insert(Map.pool, Object:new(19550, Map.pos, Vector3D(0, 0, 0), true, 1, 'floor'));
    
    -- Create house
    table.insert(Map.pool, Object:new(3639, Vector3D(Map.pos.x - 15, Map.pos.y + 10, Map.pos.z), Vector3D(0, 0, 90), true, 1, 'house'));

    -- Decorations
    -- table.insert(Map.pool, Object:new(6313, Vector3D(Map.pos.x + 10, Map.pos.y + 40, Map.pos.z - 10), false, 1, 'mountain'));
    table.insert(Map.pool, Object:new(18363, Vector3D(Map.pos.x, Map.pos.y + 60, Map.pos.z - 70), Vector3D(0, 0, 0), false, 1, 'mountain'));
    table.insert(Map.pool, Object:new(873, Vector3D(Map.pos.x + 15, Map.pos.y + 30, Map.pos.z), Vector3D(0, 0, 90), false, 1, 'grass1'));
    table.insert(Map.pool, Object:new(874, Vector3D(Map.pos.x + 35, Map.pos.y + 30, Map.pos.z), Vector3D(0, 0, 90), false, 1, 'grass1'));
    table.insert(Map.pool, Object:new(873, Vector3D(Map.pos.x + 50, Map.pos.y + 30, Map.pos.z), Vector3D(0, 0, 90), false, 1, 'grass1'));
    table.insert(Map.pool, Object:new(762, Vector3D(Map.pos.x + 30, Map.pos.y + 30, Map.pos.z - 5), Vector3D(0, 0, 90), false, 1, 'tree1'));
    
    table.insert(Map.pool, Object:new(18270, Vector3D(Map.pos.x + 20, Map.pos.y + 40, Map.pos.z - 21), Vector3D(0, 0, 270), false, 1, 'trees'));
    table.insert(Map.pool, Object:new(8147, Vector3D(Map.pos.x + 20, Map.pos.y + 23, Map.pos.z - 2), Vector3D(0, 0, 90), false, 1, 'wall'));
    table.insert(Map.pool, Object:new(17000, Vector3D(Map.pos.x, Map.pos.y + 30, Map.pos.z), Vector3D(0, 0, 0), false, 1, 'tower'));
    table.insert(Map.pool, Object:new(10571, Vector3D(Map.pos.x, Map.pos.y - 20, Map.pos.z), Vector3D(0, 0, 90), false, 1, ''));
    -- Create grid
    for line = 1, 5 do
        for section = 1, 9 do
            if ((line % 2 == 0 and section % 2 == 0) or (line % 2 == 1 and section % 2 == 1)) then
                table.insert(
                    Map.pool,
                    Object:new(
                        19790,
                        Vector3D(Map.pos.x + GRID_SIZE * (section - 1), Map.pos.y + GRID_SIZE * (line - 1), Map.pos.z - 4.9),
                        Vector3D(0, 0, 0),
                        false,
                        1,
                        'floor' .. line .. section
                    )
                );
            end
        end
    end

    -- Spawn vehicles (enemies "dead-zone")
    for i = 1, 5 do
        Vehicles.Vehicle:new(i);
    end

    -- Remove all objects on script unload
    addEventHandler('onScriptTerminate', function(scr)
        if (scr == thisScript()) then
            Map.destroy();
        end
    end);
end

---Just for debugging
function Map.getHoveredGrid()
    local pos = Map.getPointerPos(nil);
    setCharCoordinates(PLAYER_PED, pos.x, pos.y, pos.z);
end

function Map.findPedsInGrid(line, index)
    local peds = {};
    local pos = Map.getGridPos(line, index);
    for k, v in ipairs(getAllChars()) do
        local x, y, z = getCharCoordinates(v);
        if (x >= pos.x - 2.5 and x <= pos.x + 2.5 and y >= pos.y - 2.5 and y <= pos.y + 2.5) then
            table.insert(peds, v);
        end
    end
    return peds;
end

---@param pos Vector3D
---@return number line
---@return number index
---@return Vector3D GridBlockCenter
function Map.getGridForCoord(pos)
    for line = 1, 5 do
        for section = 1, 9 do
            local currentGridBlockCenter = Vector3D(Map.pos.x + (section - 1) * GRID_SIZE, Map.pos.y + (line - 1) * GRID_SIZE, Map.pos.z);
            if (pos.x >= currentGridBlockCenter.x - 2.5 and pos.x <= currentGridBlockCenter.x + 2.5 and pos.y >= currentGridBlockCenter.y - 2.5 and pos.y <= currentGridBlockCenter.y + 2.5) then
                return line, section, currentGridBlockCenter;
            end
        end
    end
    return -1, -1, Vector3D(0, 0, 0);
end

---@param line number
---@param index number
---@return Vector3D Position
function Map.getGridPos(line, index)
    return Vector3D(Map.pos.x + (index - 1) * GRID_SIZE, Map.pos.y + (line - 1) * GRID_SIZE, Map.pos.z);
end

---@param line number
---@return Vector3D Position
function Map.findSpawnPointForLine(line)
    return Map.getGridPos(line, 9 + 2);
end

---@param enemyPool any
---@param callbacks {onSunTaked: fun(), spawnEnemy: fun(line: number), onEnemyReachedFinishZone: fun()}
function Map.process(enemyPool, callbacks)
    -- Process sun
    if (wasKeyPressed(VK_LBUTTON)) then
        local pos, colpoint = Map.getPointerPos();
        if (pos and colpoint) then
            if (colpoint.entityType == 4) then
                local handle = getObjectPointerHandle(colpoint.entity);
                if (getObjectModel(handle) == 1247) then
                    callbacks.onSunTaked();
                    deleteObject(handle);
                end
            end
        end
    end

    for _, enemy in ipairs(enemyPool) do
        if (select(1, getCharCoordinates(enemy.handle)) <= -5) then
            enemy:destroy();
            callbacks.onEnemyReachedFinishZone();
            return;
        end
    end

    if (os.clock() - Map.lastEnemySpawned > 5) then
        math.randomseed(os.time() * math.random(1, 10));
        callbacks.spawnEnemy(math.random(0, 1));
    end
end

---@param custom? boolean[]
---@return Vector3D Position
---@return table<string, unknown> ColPoint
function Map.getPointerPos(custom)
    local args = custom or {true, true, false, true, false, false, false};
    local curX, curY = getCursorPos();
    local resX, resY = getScreenResolution();
    local posX, posY, posZ = convertScreenCoordsToWorld3D(curX, curY, 700.0);
    local camX, camY, camZ = getActiveCameraCoordinates();
    local result, colpoint = processLineOfSight(camX, camY, camZ, posX, posY, posZ, table.unpack(args));
    if (result and colpoint.entity ~= 0) then
        local normal = colpoint.normal;
        local pos = Vector3D(colpoint.pos[1], colpoint.pos[2], colpoint.pos[3]) - (Vector3D(normal[1], normal[2], normal[3]) * 0.1);
        local zOffset = 300;
        if (normal[3] >= 0.5) then zOffset = 1 end
        local result, colpoint2 = processLineOfSight(pos.x, pos.y, pos.z + zOffset, pos.x, pos.y, pos.z - 0.3, table.unpack(args));
        if (result) then
            return Vector3D(colpoint2.pos[1], colpoint2.pos[2], colpoint2.pos[3]), colpoint2;
        end
    end
    return Vector3D(0, 0, 0), colpoint;
end

return Map;