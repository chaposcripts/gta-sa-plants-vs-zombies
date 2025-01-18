---@diagnostic disable:lowercase-global
---@class Vector3D
---@field x number
---@field y number
---@field z number
script_name('Plants Vs Zombies - GTA:SA Edition');
script_author('chapo a.k.a moujeek');
script_url('https://t.me/chaposcripts');

DEV = LUBU_BUNDLED == nil; ---@diagnostic disable-line
BASE_PATH = DEV and 'X:\\SAMP Medium PC by chapo\\moonly\\pvz\\src\\' or getWorkingDirectory();

require('moonloader');
local imgui = require('mimgui');
local Vector3D = require('vector3d');
local Map = require('map');
local Camera = require('camera');
local Utils = require('utils');
local Heroe = require('hero');
local Heroes = require('heroes');
local Enemies = require('enemy');
local uiComponents = {
    mainMenu = require('ui.main-menu'),
    gameInterface = require('ui.game-interface'),
    healthBar = require('ui.health-bar')
};

local GameState = {
    None = 0,
    Menu = 1,
    Playing = 2
};

local state = GameState.Playing;
local placeHero = nil;
local money = 999;
local saved = {
    pos = Vector3D(0, 0, 0);
};

addEventHandler('onScriptTerminate', function(scr)
    if (scr == thisScript()) then
        if (saved.pos.x ~= 0) then
            setCharCoordinates(PLAYER_PED, saved.pos.x, saved.pos.y, saved.pos.z);
        end
    end
end);

function destroy()
    Heroes.destroy();
    Enemies.destroy();
    Map.destroy();
    state = GameState.Menu;
end

function main()
    while not isSampAvailable() do wait(0) end
    Heroes.init();
    sampRegisterChatCommand('pvz', function()
        
        saved.pos = Vector3D(getCharCoordinates(PLAYER_PED));
        
        Map.init();
        Enemies.init();
        Camera.init(Vector3D(Map.pos.x + 20, Map.pos.y - 5, Map.pos.z + 20), Vector3D(Map.pos.x + 20, Map.pos.y + 5, Map.pos.z));
        -- Camera.update();
        setCharCoordinates(PLAYER_PED, Map.pos.x, Map.pos.y, Map.pos.z);

        -- Enemies.Enemy:new(1, 1);
        state = GameState.Playing;
    end);
    sampRegisterChatCommand('pvz.pool', function()
        Utils.msg('Enemy pool size:', #Enemies.pool);
        Utils.msg('Hero pool size:', #Heroes.pool);
    end);
    while (true) do
        wait(0);
        local gp = Map.getGridPos(1, 0);
        local x, y = convert3DCoordsToScreen(gp.x, gp.y, gp.z);
        renderDrawPolygon(x, y, 10, 10, 10, 10, 0xFF00ff00)

        -- Draw hovered grid outline
        if (placeHero) then
            local line, index, pos = Map.getGridForCoord(Map.getPointerPos(nil));
            if (pos) then
                local x1, y1 = convert3DCoordsToScreen(pos.x - 2.5, pos.y - 2.5, pos.z);
                local x2, y2 = convert3DCoordsToScreen(pos.x + 2.5, pos.y + 2.5, pos.z);
                local x3, y3 = convert3DCoordsToScreen(pos.x - 2.5, pos.y + 2.5, pos.z);
                local x4, y4 = convert3DCoordsToScreen(pos.x + 2.5, pos.y - 2.5, pos.z);
                renderDrawLine(x1, y1, x3, y3, 2, 0x33ffffff);
                renderDrawLine(x1, y1, x4, y4, 2, 0x33ffffff);
                renderDrawLine(x2, y2, x4, y4, 2, 0x33ffffff);
                renderDrawLine(x3, y3, x2, y2, 2, 0x33ffffff);
            end
            if (wasKeyPressed(1)) then
                sampAddChatMessage(('Placed hero with type "%s" to (%d:%d)'):format(placeHero, line, index), 0xFF00ff00);
                -- Heroes.Hero:new(placeHero, pos);
                Heroes.Hero:new(placeHero, line, index)
                placeHero = nil;
            end
        end

        -- Check enemies position, X <= 0 == zombies won
        table.foreach(Enemies.pool, function(_, enemy)
            if (doesCharExist(enemy.handle) and select(1, getCharCoordinates(enemy.handle)) <= 0) then
                destroy();
                Utils.msg('You loose!');
            end
        end);

        -- Processing
        if (state == GameState.Playing) then
            Heroes.process(Enemies.pool);
            Enemies.process(Enemies.pool, Heroes.pool);
            Map.process(Enemies.pool, {
                onSunTaked = function()
                    money = money + 50;
                    printStringNow('~y~+50', 1250);
                end,
                spawnEnemy = function(type)
                    math.randomseed(os.time() * math.random(1, 10));
                    local type = math.random(1, 1);
                    math.randomseed(os.time() * math.random(1, 10));
                    local line = math.random(1, 5);
                    Utils.msg('Spawning enemy with type', type, 'on line', line);
                    Enemies.Enemy:new(type, line);
                    Map.lastEnemySpawned = os.clock();
                end
            });
        end
    end
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil;
    Heroes.loadTextures();

    local style = imgui.GetStyle();
    style.WindowBorderSize = 5;
    style.WindowRounding = 10;
    style.FrameRounding = 5;

    local colors = style.Colors;
    colors[imgui.Col.Border] = imgui.ImVec4(0.57, 0.26, 0.11, 1);
    colors[imgui.Col.WindowBg] = imgui.ImVec4(0.35, 0.16, 0.06, 1);
    colors[imgui.Col.ChildBg] = imgui.ImVec4(0.95, 0.94, 0.89, 1);
end);

imgui.OnFrame(
    function() return state ~= GameState.None end,
    function(thisWindow)
        table.foreach(Enemies.pool, function(k, v)
            uiComponents.healthBar(v, true);
        end);
        table.foreach(Heroes.pool, function(k, v)
            uiComponents.healthBar(v, false);
        end);
        thisWindow.HideCursor = true;
        local res = imgui.ImVec2(getScreenResolution());
        local style = imgui.GetStyle();
        if (state == GameState.Menu) then
            -- uiComponents.mainMenu(res, style);
        elseif (state == GameState.Playing) then
            uiComponents.gameInterface(
                res,
                style, ---@diagnostic disable-line
                Heroes.list,
                money,
                function(heroIndex)
                    Utils.msg('clicked');
                    local hero = Heroes.list[heroIndex];
                    if (not hero) then
                        return Utils.msg('Error, invalid hero index!');
                    end
                    if (money >= hero.price) then
                        placeHero = hero;
                        money = money - hero.price;
                    else
                        sampAddChatMessage('Dear Retard, you have not enough money to purchase this hero!', -1);
                    end
                end
            );
        end
    end
);