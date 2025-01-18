---@diagnostic disable:deprecated,lowercase-global
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
local Heroes = require('heroes');
local Enemies = require('enemy');
local RakNet = require('raknet');
local uiComponents = {
    mainMenu = require('ui.main-menu'),
    gameInterface = require('ui.game-interface'),
    healthBar = require('ui.health-bar'),
    logo = {
        base85 = require('resource.logo'),
        texture = nil
    },
    sun = {
        base85 = require('resource.sun'),
        texture = nil
    }
};
local color = '{914dff}';
local GameState = {
    None = 0,
    Menu = 1,
    Playing = 2
};

local Game = {
    saved = {
        heading = 0,
        pos = Vector3D(0, 0, 0)
    },
    state = GameState.Menu,
    money = 9999,
    heroToPlace = nil,
    startedAt = os.time(),
    lastGameDuration = 0
};

function Game.destroy()
    Heroes.destroy();
    Enemies.destroy();
    Map.destroy();
    Game.state = GameState.Menu;
    setCharCoordinates(PLAYER_PED, Game.saved.pos.x, Game.saved.pos.y, Game.saved.pos.z);
    Camera.restore();
    RakNet.nop = false;
end
local Vehicles = require('vehicle');
function Game.start()
    Game.saved = {
        heading = getCharHeading(PLAYER_PED),
        pos = Vector3D(getCharCoordinates(PLAYER_PED))
    };
        
    Map.init(Vehicles);
    Enemies.init();
    Camera.init(Vector3D(Map.pos.x + 17, Map.pos.y - 1, Map.pos.z + 20), Vector3D(Map.pos.x + 17, Map.pos.y + 11, Map.pos.z));
    Camera.update();
    setCharCoordinates(PLAYER_PED, Map.pedPos.x, Map.pedPos.y, Map.pedPos.z);
    setCharHeading(PLAYER_PED, Map.pedHeading);
    Game.state = GameState.Playing;
    Game.startedAt = os.time();
    RakNet.nop = true;
end



addEventHandler('onScriptTerminate', function(scr)
    if (scr == thisScript()) then
        if (Game.saved.pos.x ~= 0) then
            setCharCoordinates(PLAYER_PED, Game.saved.pos.x, Game.saved.pos.y, Game.saved.pos.z);
        end
    end
end);

function main()
    while not isSampAvailable() do wait(0) end
    Utils.msg(('Plants Vs Zombies - GTA:SA Edition by %schapo {ffffff}a.k.a %smoujeek'):format(color, color));
    Utils.msg(('See %sgithub.com/chaposcripts'):format(color));
    Heroes.init();
    Vehicles.init();
    sampRegisterChatCommand('pvz', function()
        if (Game.state == GameState.Playing) then
            Game.state = GameState.Menu;
            return Game.destroy();
        elseif (Game.state == GameState.Menu) then
            Game.state = GameState.None;
        elseif (Game.state == GameState.None) then
            Game.state = GameState.Menu;
        end
        Utils.debugMsg('Game state was changed to:', Game.state);
    end);
    sampRegisterChatCommand('pvz.money', function(amount)
        Game.money = tonumber(amount) or 1000;
        Utils.msg('Money set to', color, Game.money);
    end);
    if (DEV) then
        sampRegisterChatCommand('pvz.pool', function()
            Utils.debugMsg('Enemy pool size:', #Enemies.pool);
            Utils.debugMsg('Hero pool size:', #Heroes.pool);
        end);
    end
    while (true) do
        wait(0);
        if (Game.state == GameState.Playing) then
            Vehicles.process(Enemies.pool, Heroes.pool);
            local gp = Map.getGridPos(1, 0);
            local x, y = convert3DCoordsToScreen(gp.x, gp.y, gp.z);
            renderDrawPolygon(x, y, 10, 10, 10, 10, 0xFF00ff00)

            -- Draw hovered grid outline
            if (Game.heroToPlace) then
                local line, index, pos = Map.getGridForCoord(Map.getPointerPos(nil));
                if (line ~= -1 and pos) then
                    local x1, y1 = convert3DCoordsToScreen(pos.x - 2.5, pos.y - 2.5, pos.z);
                    local x2, y2 = convert3DCoordsToScreen(pos.x + 2.5, pos.y + 2.5, pos.z);
                    local x3, y3 = convert3DCoordsToScreen(pos.x - 2.5, pos.y + 2.5, pos.z);
                    local x4, y4 = convert3DCoordsToScreen(pos.x + 2.5, pos.y - 2.5, pos.z);
                    renderDrawLine(x1, y1, x3, y3, 2, 0xFFffffff);
                    renderDrawLine(x1, y1, x4, y4, 2, 0xFFffffff);
                    renderDrawLine(x2, y2, x4, y4, 2, 0xFFffffff);
                    renderDrawLine(x3, y3, x2, y2, 2, 0xFFffffff);
                end
                if (wasKeyPressed(VK_LBUTTON)) then
                    sampAddChatMessage(('Placed hero with type "%s" to (%d:%d)'):format(Game.heroToPlace, line, index), 0xFF00ff00);
                    Heroes.Hero:new(Game.heroToPlace, line, index)
                    Game.money = Game.money - Game.heroToPlace.price;
                    Game.heroToPlace = nil;
                elseif (wasKeyPressed(VK_RBUTTON)) then
                    Game.heroToPlace = nil;
                end
            end

            -- Processing
            Heroes.process(Enemies.pool);
            Enemies.process(Enemies.pool, Heroes.pool);
            Map.process(Enemies.pool, {
                onEnemyReachedFinishZone = function()
                    Game.destroy();
                    Game.lastGameDuration = os.time() - Game.startedAt;
                    Utils.msg('Ha-ha, you loose! Match duration:', color, Game.lastGameDuration, '{ffffff}seconds!');
                end,
                onSunTaked = function()
                    Game.money = Game.money + 50;
                    printStringNow('~y~+50', 1250);
                end,
                spawnEnemy = function(type)
                    math.randomseed(os.time() * math.random(1, 10));
                    local type = math.random(1, 1);
                    math.randomseed(os.time() * math.random(1, 10));
                    local line = math.random(1, 5);
                    Utils.debugMsg('Spawning enemy with type', type, 'on line', line);
                    Enemies.Enemy:new(type, line);
                    Map.lastEnemySpawned = os.clock();
                end
            });
        end
    end
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil;
    uiComponents.logo.texture = imgui.CreateTextureFromFileInMemory(imgui.new('const char*', uiComponents.logo.base85), #uiComponents.logo.base85);
    uiComponents.sun.texture = imgui.CreateTextureFromFileInMemory(imgui.new('const char*', uiComponents.sun.base85), #uiComponents.sun.base85);

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
    function() return Game.state ~= GameState.None end,
    function(thisWindow)
        thisWindow.HideCursor = DEV;

        table.foreach(Enemies.pool, function(k, v)
            uiComponents.healthBar(v, true);
        end);
        table.foreach(Heroes.pool, function(k, v)
            uiComponents.healthBar(v, false);
        end);
        
        local res = imgui.ImVec2(getScreenResolution());
        local style = imgui.GetStyle();
        if (Game.state == GameState.Menu) then
            uiComponents.mainMenu(res, style, uiComponents.logo.texture, { ---@diagnostic disable-line
                onExit = function()
                    Game.state = GameState.None;
                end,
                onPlay = function()
                    Game.start();
                end
            });
        elseif (Game.state == GameState.Playing) then
            uiComponents.gameInterface(
                res,
                style, ---@diagnostic disable-line
                Heroes.list,
                Game.money,
                uiComponents,
                function(heroIndex)
                    Utils.debugMsg('clicked');
                    local hero = Heroes.list[heroIndex];
                    if (not hero) then
                        return Utils.debugMsg('Error, invalid hero index!');
                    end
                    if (Game.money >= hero.price) then
                        Game.heroToPlace = hero;
                        Utils.debugMsg('Place hero to any grid section. Click RMB to cancel.');
                    else
                        sampAddChatMessage('Dear Retard, you have not enough money to purchase this hero!', -1);
                    end
                end
            );
        end
    end
);