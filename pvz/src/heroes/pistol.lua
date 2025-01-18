local Utils = require('utils');

local hero = {
    name = 'Pistol',
    maxHealth = 150,
    attackInterval = 6,
    price = 100,
    model = 106,
    storage = {
        lastSunDropped = os.clock(),
    },
    weapon = 24,
    attackAnimation = {
        file = 'SILENCED',
        name = 'Silence_fire'
    },
    noTargetRequired = false,
    damage = 20,
    attackDistance = 50
};

function hero:onDamageReceived(damage, from)
    
end

return hero;