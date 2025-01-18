local imgui = require('mimgui');


---@param res ImVec2
---@param style imgui.Style
---@param heroes any
return function(res, style, heroes, money, cb)
    local heroIconSize = imgui.ImVec2(75, 75);
    imgui.SetNextWindowPos(imgui.ImVec2(res.x / 2, 100), imgui.Cond.Always, imgui.ImVec2(0.5, 0));
    if (imgui.Begin('plants-vs-zombies-gui', nil, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.AlwaysAutoResize)) then
        local fgdl = imgui.GetForegroundDrawList();
        local heroInfoSize = imgui.ImVec2(75, 100);

        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0));
        imgui.PushStyleColor(imgui.Col.ChildBg, style.Colors[imgui.Col.WindowBg]);
        if (imgui.BeginChild('money', heroInfoSize, true)) then
            local dl = imgui.GetWindowDrawList();
            local cursorPos = imgui.GetCursorScreenPos();
            fgdl:AddCircleFilled(cursorPos + imgui.ImVec2(heroInfoSize.x / 2, heroInfoSize.y / 2 - 15), 30, imgui.GetColorU32Vec4(style.Colors[imgui.Col.Border]), 50);
            fgdl:AddRectFilled(cursorPos + imgui.ImVec2(0, 75), cursorPos + imgui.ImVec2(heroInfoSize.x, 75 + 25), 0xFFffffff, 5);
            local moneySize = imgui.CalcTextSize(tostring(money));
            fgdl:AddText(cursorPos + imgui.ImVec2(heroInfoSize.x / 2 - moneySize.x / 2, 80), 0xFF000000, tostring(money));
        end
        imgui.EndChild();
        imgui.PopStyleColor();

        for index, hero in pairs(heroes) do
            imgui.SameLine();
            local pStart = imgui.GetCursorScreenPos();
            if (imgui.BeginChild('hero-' .. index, imgui.ImVec2(75, 100), true)) then
                local dl = imgui.GetWindowDrawList();
                local p = imgui.GetCursorScreenPos();
                dl:AddImage(hero.texture, p, p + imgui.ImVec2(75, 75));
                local color = imgui.GetColorU32Vec4(style.Colors[imgui.Col.ChildBg]);
                dl:AddRectFilledMultiColor(p + imgui.ImVec2(0, 60), p + imgui.ImVec2(75, 100), 0x00ffffff, 0x00ffffff, color, color);
                local nameSize = imgui.CalcTextSize(hero.name);
                dl:AddText(p + imgui.ImVec2(75 / 2 - nameSize.x / 2, 65), 0xFF000000, hero.name);
                local priceSize = imgui.CalcTextSize(tostring(hero.price));
                dl:AddText(p + imgui.ImVec2(75 / 2 - priceSize.x / 2, 80), 0xFF000000, tostring(hero.price));
            end
            imgui.EndChild();
            if (imgui.IsMouseClicked(0) and imgui.IsMouseHoveringRect(pStart, pStart + imgui.ImVec2(75, 100))) then
                cb(index);
            end
        end
        imgui.PopStyleVar();
    end
    imgui.EndChild();
end
