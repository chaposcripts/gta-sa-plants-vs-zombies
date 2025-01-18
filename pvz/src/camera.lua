local Vector3D = require('vector3d');
local Camera = {
    pos = Vector3D(0, 0, 0),
    point = Vector3D(0, 0, 0)
};

---@param pos Vector3D
---@param point Vector3D
function Camera.init(pos, point)
    Camera.pos, Camera.point = pos, point;
    addEventHandler('onScriptTerminate', function(scr)
        if (scr == thisScript()) then
            Camera.restore();
        end
    end);
end

---@param pos Vector3D
function Camera.setPos(pos)
    cameraResetNewScriptables()
    setFixedCameraPosition(pos.x, pos.y, pos.z, 0, 0, 0)
end

---@param point Vector3D
function Camera.setPointAt(point)
    cameraResetNewScriptables()
    pointCameraAtPoint(point.x, point.y, point.z, 2)
end

function Camera.update()
    Camera.setPos(Camera.pos);
    Camera.setPointAt(Camera.point);
end

Camera.restore = restoreCameraJumpcut;

return Camera;