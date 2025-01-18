local Utils = require('utils');

local hero = {
    name = 'Pistol',
    maxHealth = 150,
    attackInterval = 12,
    price = 100,
    model = 106,
    weapon = 24,
    attackAnimation = {
        file = 'SILENCED',
        name = 'Silence_fire'
    },
    noTargetRequired = false,
    damage = 20,
    attackDistance = 50
};

return hero;