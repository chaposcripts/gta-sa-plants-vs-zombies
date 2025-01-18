local Vector3D = require('vector3d');
local Object = require('object');

local sunflower = {
    name = 'Sunflower',
    maxHealth = 100,
    attackInterval = 5,
    price = 50,
    model = 167,
    storage = {
        lastSunDropped = os.clock(),
    },
    attackAnimation = {
        file = 'GRENADE',
        name = 'WEAPON_throw'
    },
    noTargetRequired = true,
    damage = 0
};

function sunflower:onAttack(wasAnimationPlayed)
    local x, y, z = getCharCoordinates(self.handle);
    local sun = Object:new(1247, Vector3D(x, y, z + 2), nil, true, 1, 'sunflower');
    print('sun handle', sun.handle, 'ptr', getObjectPointer(sun.handle));
end

return sunflower;