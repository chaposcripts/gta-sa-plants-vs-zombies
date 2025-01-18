local imgui = require('mimgui');
local link = require('ui.link');

function imgui.CenterText(text)
    imgui.SetCursorPosX(imgui.GetWindowSize().x / 2 - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end

---@param res ImVec2
---@param style imgui.Style
---@param cb {onExit: fun(), onPlay: fun()}
return function(res, style, logoTexture, cb)
    local size = imgui.ImVec2(400, 220);
    imgui.SetNextWindowSize(size, imgui.Cond.Always);
    imgui.SetNextWindowPos(imgui.ImVec2(res.x / 2, res.y / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5));
    if (imgui.Begin('plants-vs-zombies-main-menu', nil, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove)) then
        imgui.SetCursorPos(imgui.ImVec2(10, 10));
        imgui.TextDisabled('by chapo');
        imgui.SetCursorPos(imgui.ImVec2(size.x - 30 - 10, 10));
        if (imgui.Button('X##close', imgui.ImVec2(30, 30))) then
            cb.onExit();
        end
        imgui.SetCursorPos(imgui.ImVec2(size.x / 2 - 100, 20));
        imgui.Image(logoTexture, imgui.ImVec2(200, 100));
        imgui.CenterText('GTA:SA Edition');
        
        local playButtonSize = imgui.ImVec2(imgui.GetWindowWidth() - 40, 40);
        imgui.SetCursorPos(imgui.ImVec2(20, 150));
        if (imgui.Button('PLAY', playButtonSize)) then
            cb.onPlay();
        end
        
        imgui.SetWindowFontScale(1);
        imgui.SetCursorPos(imgui.ImVec2(20, size.y - 25));
        link('https://t.me/chaposcripts', 'Telegram');
        imgui.SameLine(nil, 110);
        link('https://github.com/chaposcripts', 'GitHub');
        imgui.SameLine(nil, 109);
        link('https://youtube.com/@ya_chapo', 'YouTube');
    end
    imgui.End();
end
