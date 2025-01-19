---@diagnostic disable:duplicate-doc-field
local Vector3D = require('vector3d');
local Object = {};
local pool = {};

addEventHandler('onScriptTerminate', function(scr)
    if (scr == thisScript()) then
        for k, v in ipairs(pool) do
            -- v:destroy();
        end
    end
end);

---@class Object
---@field handle number
---@field tag string
---@field setCollision fun(self: Object, collision: boolean)
---@field destroy fun(self: Object)
---@field setScale fun(self: Object, scale: number)
---@field setRotation fun(self: Object, rotation: Vector3D)
---@field setPosition fun(self: Object, position: Vector3D)

setmetatable(Object, {__call = function(t, ...)
    return t:new(...)
end})

function Object:setCollision(bool)
    self.collision = bool;
    setObjectCollision(self.handle, bool);
end

function Object:setRotation(rotation)
    self.rotation = rotation;
    setObjectRotation(self.handle, rotation.x, rotation.y, rotation.z);
end

function Object:setPosition(pos)
    self.pos = pos;
    setObjectCoordinates(self.handle, pos.x, pos.y, pos.z);
end

function Object:destroy()
    deleteObject(self.handle);
    print('Object:destroy(), handle = ', self.handle);
    for index, handle in ipairs(pool) do
        if (handle == self.handle) then
            table.remove(pool, index);
        end
    end
end

function Object:setScale(scale)
    self.scale = scale;
    setObjectScale(self.handle, scale);
end

function Object:new(model, pos, rotation, collision, scale, tag)
    local handle = createObject(model, pos.x, pos.y, pos.z)
    assert(doesObjectExist(handle), 'Error creating object.');
    if (rotation) then
        setObjectRotation(handle, rotation.x, rotation.y, rotation.z);
    end
    setObjectCollision(handle, collision);
    setObjectScale(handle, scale or 1);
    print('Object:new(), handle = ', handle);
    local instance = {
        handle = handle,
        tag = tag or '',
        scale = 1,
        collision = collision,
        rotation = Vector3D(0, 0, 0)
    };
    local meta = setmetatable(instance, {__index = self})
    table.insert(pool, meta);
    return meta
end

return Object;