local Utils = require('utils');
local imgui = require('mimgui');
local Map = require('map');
local font = renderCreateFont('arial', 8, 5); -- For debug info
local Heroes = {
    Hero = {},
    list = {},
    pool = {},
    initialized = false
};

function Heroes.Hero:applyDamageTakenAnimation()
    local anims = {'PED:SHOT_leftP'}
end

setmetatable(Heroes.Hero, {__call = function(t, ...)
    return t:new(...);
end});

---@class Hero
---@field name string
---@field maxHealth number
---@field handle number
---@field weapon? number
---@field price number
---@field health? number
---@field attackDistance? number
---@field idleAnimation? Animation
---@field attackAnimation? Animation
---@field takeDamageAnimation? Animation
---@field attackInterval? number
---@field lastAttack? number
---@field noTargetRequired? boolean
---@field onTick? fun()
---@field onTargetFound? fun(self: Hero, target: Enemy)
---@field onDamageReceived? fun(self: Hero, damage: number, from: Enemy)
---@field onDeath? fun(self: Hero, damage: number, enemy: Enemy)
---@field updateTarget fun(self: Hero, targets: {target: Enemy, distance: number}[])
---@field drawDebugInfo fun(self: Hero)
---@field destroy fun(self: Hero)
---@field die fun(self: Hero)
---@field dealDamage fun(self: Hero, damage: number, from: Enemy)
---@field storage? table<any, any>

function Heroes.destroy()
    for _, hero in ipairs(Heroes.pool) do
        hero:destroy();
    end
end

function Heroes.init()
    if (Heroes.initialized) then
        return print('WARNING: Heroes already initialized!');
    end
    Heroes.initialized = true;
    print('Loading heroes');
    if (DEV) then
        for _, file in ipairs(Utils.getFilesInPath('X:\\SAMP Medium PC by chapo\\moonly\\pvz\\src\\heroes', '*.lua')) do
            if (file ~= 'init.lua') then
                table.insert(Heroes.list, require('heroes.' .. file:sub(1, #file - 4)));
                print('INFO: Loaded hero ', file)
            end
        end
    else
        Heroes.list = {
            require('heroes.sunflower'),
            require('heroes.pistol'),
            require('heroes.rifle'),
            require('heroes.bigboy'),
            require('heroes.boxer')
        };
    end
    
    local modelsToLoad, animationsToLoad = {}, {};
    for heroIndex, hero in ipairs(Heroes.list) do
        table.insert(modelsToLoad, hero.model or nil);
        table.insert(modelsToLoad, hero.weapon or nil);
        
        table.insert(animationsToLoad, hero.attackAnimation and hero.attackAnimation.file or nil);
        table.insert(animationsToLoad, hero.idleAnimation and hero.idleAnimation.file or nil);
        table.insert(animationsToLoad, hero.takeDamageAnimation and hero.takeDamageAnimation.file or nil);
    end

    for _, modelId in ipairs(modelsToLoad) do
        if (not hasModelLoaded(modelId)) then
            requestModel(modelId);
        end
    end
    loadAllModelsNow();
    
    for _, animation in ipairs(animationsToLoad) do
        if (not hasAnimationLoaded(animation)) then
            requestAnimation(animation);
        end
    end

    addEventHandler('onScriptTerminate', function(scr)
        if (scr == thisScript()) then
            Heroes.destroy();
        end
    end);
end

function Heroes.loadTextures()
    if (not Heroes.initialized) then
        Heroes.init();
    end
    for index, heroData in ipairs(Heroes.list) do
        if (heroData.imageBase85) then
            Heroes.list[index].texture = imgui.CreateTextureFromFileInMemory(imgui.new('const char*', heroData.imageBase85), #heroData.imageBase85);
        else
            print('WARNING: missing hero icon for', heroData.name);
        end
    end
end

---Processing for all heroes in pool
---@param enemyPool Enemy[]
function Heroes.process(enemyPool)
    for index, hero in ipairs(Heroes.pool) do
        if (doesCharExist(hero.handle)) then
            hero:process(index, enemyPool);
        end
    end
end

function Heroes.Hero:drawDebugInfo()
    if (isCharOnScreen(self.handle)) then
        local x, y = convert3DCoordsToScreen(getCharCoordinates(self.handle));
        renderFontDrawText(font, ('Health: %d\nNext Attack: %d\nGridPos: %d-%d\n%s'):format(self.health, self.attackInterval - (os.clock() - (self.lastAttack or 0)), self.grid.line, self.grid.index, self.target == nil and '{ff0000}NO TARGET{ffffff}' or 'TARGET: ' .. tostring(self.target)), x, y, 0xFFffffff, false);
        if (self.target) then
            local tx, ty = convert3DCoordsToScreen(getCharCoordinates(self.target));
            renderDrawLine(x, y, tx, ty, 1, 0xFFff0000);
        end
    end
end

---@param indexInPool number
function Heroes.Hero:process(indexInPool, enemyPool)
    if (DEV) then
        self:drawDebugInfo();
    end
    self:call('onTick');
    if (not self.noTargetRequired) then
        self:updateTarget();
    end
    if (self.attackInterval) then
        if (self.lastAttack and (self.target ~= nil or self.noTargetRequired)) then
            local timeSinceLastAttack = os.clock() - self.lastAttack;
            if (timeSinceLastAttack > self.attackInterval) then
                if (self.attackAnimation) then
                    taskPlayAnim(self.handle, self.attackAnimation.name, self.attackAnimation.file, 4.0, false, true, true, true, 0);
                end

                for _, enemy in ipairs(enemyPool) do
                    if (enemy.handle == self.target) then
                        enemy:dealDamage(self.damage, self);
                        break;
                    end
                end

                self:call('onAttack', self.attackAnimation ~= nil);
                self.lastAttack = os.clock();
            end
        else
            self.lastAttack = os.clock();
        end
    end
end

---@param fn string
---@param ... any
---@return any
function Heroes.Hero:call(fn, ...)
    return type(self[fn]) == 'function' and self[fn](self, ...) or nil;
end

function Heroes.Hero:destroy()
    if (doesCharExist(self.handle)) then
        deleteChar(self.handle);
        print('Hero was destroyed, handle = ', self.handle);
    end
end

function Heroes.drawEntityHealthBar(entity)
    local GUI_BAR_SIZE = imgui.ImVec2(50, 5);
    local BGDL = imgui.GetBackgroundDrawList();
    local x, y, z = getCharCoordinates(entity.handle);
    local pos = imgui.ImVec2(convert3DCoordsToScreen(x, y, z + 1.5));
    BGDL:AddRectFilled(
        pos - imgui.ImVec2(GUI_BAR_SIZE.x / 2, 0),
        pos + imgui.ImVec2(GUI_BAR_SIZE.x / 2, GUI_BAR_SIZE.y),
        0xCC000000,
        2
    );
    local healthPercent = entity.health / entity.maxHealth;
    pos.x = pos.x - GUI_BAR_SIZE.x / 2;
    BGDL:AddRectFilled(
        pos + imgui.ImVec2(1, 1),
        pos + imgui.ImVec2(GUI_BAR_SIZE.x * healthPercent - 1, GUI_BAR_SIZE.y - 1),
        0xCC0000ff,
        2
    );
    BGDL:AddText(pos + imgui.ImVec2(GUI_BAR_SIZE.x + 5, -7), 0xFFFFFFFF, tostring(entity.health));
end

function Heroes.Hero:kill()
    setCharCoordinates(self.handle, -100, -100, -100);
    self.target = nil;
    self.noTargetRequired = true;
    self:call('onDeath');
end

---@param damage number
---@param from {handle: number, damage: number}
function Heroes.Hero:dealDamage(damage, from)
    self.health = self.health - from.damage;
    if (self.health <= 0) then
        self:kill();
    end
    if (self.takeDamageAnimation) then
        taskPlayAnim(self.handle, self.takeDamageAnimation.name, self.takeDamageAnimation.file, 4.0, false, true, true, true, 0);
    end
    print('damage from', from.handle, 'to', self.handle);
    self:call('onDamageReceived', from.damage, from);
end

function Heroes.Hero:updateTarget()
    local heroX, heroY, heroZ = getCharCoordinates(self.handle);
    self.target = nil;
    local enemies = {};
    for index = self.grid.index, 9 do
        local pos = Map.getGridPos(self.grid.line, index);

        if (DEV) then
            local x, y = convert3DCoordsToScreen(pos.x, pos.y, pos.z);
            renderDrawPolygon(x, y, 10, 10, 10, 10, 0xFFff00ff);
        end

        local peds = Map.findPedsInGrid(self.grid.line, index);
        if (#peds > 0) then
            for _, ped in ipairs(peds) do
                if (ped ~= self.handle and ped ~= PLAYER_PED) then
                    table.insert(enemies, {
                        handle = ped,
                        dist = getDistanceBetweenCoords3d(heroX, heroY, heroZ, getCharCoordinates(ped))
                    });
                end
            end
        end
    end
    pcall(table.sort, enemies, function(a, b)
        return a.dist < b.dist;
    end);
    local target = #enemies > 0 and enemies[1] or nil;
    if (target) then
        self.target = target.dist <= (self.attackDistance or 100) and target.handle or nil;
    end
    return enemies;
end

---@param heroParams Hero
---@param line number
---@param index number
---@return Hero
function Heroes.Hero:new(heroParams, line, index)
    local instance = Utils.copyTable(heroParams);
    local spawnPos = Map.getGridPos(line, index);
    -- spawnPos.z = spawnPos.z + 1;
    local ped = createChar(4, instance.model, spawnPos.x, spawnPos.y, spawnPos.z);
    freezeCharPosition(ped, true);
    setCharHeading(ped, 270);
    instance.handle = ped;
    instance.health = instance.maxHealth;
    instance.grid = {
        line = line,
        index = index
    };

    if (heroParams.weapon) then
        giveWeaponToChar(ped, heroParams.weapon, 9999);
        setCurrentCharWeapon(ped, heroParams.weapon);
    end
    
    local newMeta = setmetatable(instance, {__index = self});
    table.insert(Heroes.pool, newMeta);
    return newMeta;
end

return Heroes;