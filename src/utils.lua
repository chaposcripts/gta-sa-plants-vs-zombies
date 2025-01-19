local ffi = require('ffi');
local Vector3D = require('vector3d');
local Utils = {};

local CPed_SetModelIndex = ffi.cast('void(__thiscall *)(void*, unsigned int)', 0x5E4880);

function Utils.setCharModel(ped, model)
    if not (doesCharExist(ped)) then return Utils.debugMsg('ped not found') end
    if (not hasModelLoaded(model)) then
        requestModel(model);
        loadAllModelsNow();
    end
    CPed_SetModelIndex(ffi.cast('void*', getCharPointer(ped)), ffi.cast('unsigned int', model));
end

function Utils.copyTable(t)
    local u = { }
    for k, v in pairs(t) do u[k] = v end
    return setmetatable(u, getmetatable(t))
end

function Utils.bringFloatTo(from, to, start_time, duration)
    local timer = os.clock() - start_time
    if timer >= 0.00 and timer <= duration then
        local count = timer / (duration / 100)
        return from + (count * (to - from) / 100), true
    end
    return (timer > duration) and to or from, false
end

function Utils.bringVec3To(from, to, start_time, duration)
    local timer = os.clock() - start_time
    if timer >= 0.00 and timer <= duration then
        local count = timer / (duration / 100)
        return Vector3D(
            from.x + (count * (to.x - from.x) / 100),
            from.y + (count * (to.y - from.y) / 100),
            from.z + (count * (to.z - from.z) / 100)
        ), true
    end
    return (timer > duration) and to or from, false
end

function Utils.mergeTable(t1, t2)
    local merged = {};
    for _, t in ipairs({ t1, t2 }) do
        for k, v in ipairs(t) do
            table.insert(merged, v);;
        end
    end
    return merged;
end

---@param path string directory
---@param ftype string|string[] file extension
---@return string[] files names
function Utils.getFilesInPath(path, ftype)
    assert(path, '"path" is required');
    assert(type(ftype) == 'table' or type(ftype) == 'string', '"ftype" must be a string or array of strings');
    local result = {};
    for _, thisType in ipairs(type(ftype) == 'table' and ftype or { ftype }) do
        local searchHandle, file = findFirstFile(path.."/"..thisType);
        table.insert(result, file)
        while file do file = findNextFile(searchHandle) table.insert(result, file) end
    end
    return result;
end

function Utils.msg(...)
    sampAddChatMessage(('PvZ // {ffffff}%s'):format(table.concat({ ... }, ' ')), 0xFF914dff);
end

function Utils.debugMsg(...)
    if (not DEV) then return end
    Utils.msg('{914dff}DEBUG // {ffffff}', ...);
end

return Utils;