local Heroes = {
    Hero = {},
    pool = {}
};

local Hero_PED_TYPE = 6;

setmetatable(Heroes.Hero, {__call = function(t, ...)
    return t:new(...)
end})

---@enum HeroType
local HeroType = {
    Default = 1,
    Deagle = 2
};
Heroes.HeroType = HeroType;

---@class Animation
---@field file string
---@field name string

---@class HeroData
---@field name string
---@field model number
---@field cost number
---@field maxHealth number
---@field weapon? number
---@field attackAnimation? Animation
---@field attackInterval? number
---@field attackRange? number
---@field lastAttack? number
---@field storage? table
---@field idleAnimation? Animation
---@field onTick? fun(tickrate?: number)

---@type table<HeroType, HeroData>
local HeroData = {
    [HeroType.Default] = {
        model = 167,
        name = 'Default',
        maxHealth = 100,
        cost = 50,
        storage = { lastSunDropped = os.time() }
    },
    [HeroType.Deagle] = {
        model = 106,
        name = 'Weak Retard With Deagle',
        maxHealth = 150,
        cost = 100,
        storage = { lastSunDropped = os.time() },
        weapon = 24
    },
};

Heroes.HeroData = HeroData;

function Heroes.init()
    for k, v in pairs(HeroData) do
        if (not hasModelLoaded(v.model)) then
            requestModel(v.model);
            loadAllModelsNow();
            print('Model', v.model, 'was loaded.');
        end

        -- load weapon model
        if (v.weapon) then
            local model = getWeapontypeModel(v.weapon);
            if (not hasModelLoaded(model)) then
                requestModel(model);
                loadAllModelsNow();
            end
        end
        -- load animations
        if (v.idleAnimation or v.attackAnimation) then
            -- for _, animationFile in ipairs({ v.idleAnimation.file or v.attackAnimation.file, v.attackAnimation.file or v.idleAnimation.file }) do
            --     if ()
            -- end
            if (v.idleAnimation) then
                if (not hasAnimationLoaded(v.idleAnimation.file)) then
                    requestAnimation(v.idleAnimation.file);
                end
            end
            if (v.attackAnimation) then
                if (not hasAnimationLoaded(v.attackAnimation.file)) then
                    requestAnimation(v.attackAnimation.file);
                end
            end
        end
    end
    addEventHandler('onScriptTerminate', function(scr)
        if (scr == thisScript()) then
            for index, hero in pairs(Heroes.pool) do
                hero:destroy();
            end
        end
    end);
end

function Heroes.process()
    for k, v in pairs(Heroes.pool) do
        v:process();
    end
end

function Heroes.Hero:process()
    -- print('Processing hero, handle', self.handle);
end

function Heroes.Hero:destroy()
    if (doesCharExist(self.handle)) then
        deleteChar(self.handle);
        print('Hero was destroyed, handle = ', self.handle);
    end
end

---@param type HeroType
function Heroes.Hero:new(type, pos)
    assert(HeroData[type], 'Unknown Hero type: ' .. type);
    local heroData = HeroData[type];
    local ped = createChar(Hero_PED_TYPE, heroData.model, pos.x, pos.y, pos.z);
    setCharHeading(ped, 270);
    if (heroData.idleAnimation) then
        taskPlayAnim(PLAYER_PED, heroData.idleAnimation.name, heroData.idleAnimation.file, 4.0, false, 0, 0, 0, -1);
    end
    if (heroData.weapon) then
        giveWeaponToChar(ped, heroData.weapon, 9999);
        setCurrentCharWeapon(ped, heroData.weapon);
    end
    local instance = {
        handle = ped,
        line = nil
    };
    local newMeta = setmetatable(instance, {__index = self})
    table.insert(Heroes.pool, newMeta);
    return newMeta;
end

return Heroes;