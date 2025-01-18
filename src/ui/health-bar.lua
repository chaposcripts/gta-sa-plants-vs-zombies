local imgui = require('mimgui');
local GUI_BAR_SIZE = imgui.ImVec2(50, 5);

---@type Hero | Enemy
return function(entity, isEnemy)
    if (not doesCharExist(entity.handle) or not isCharOnScreen(entity.handle)) then
        return;
    end
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
        isEnemy and 0xFF4242db or 0xFF21b82e,
        2
    );
    BGDL:AddText(pos + imgui.ImVec2(GUI_BAR_SIZE.x + 5, -7), 0xFFFFFFFF, tostring(entity.health));
end