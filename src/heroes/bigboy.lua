local Utils = require('utils');

local hero = {
    name = 'BigBoy',
    maxHealth = 400,
    attackInterval = 5,
    price = 100,
    model = 149,
    storage = {
        lastSunDropped = os.clock(),
    },
    attackAnimation = {
        file = 'DEALER',
        name = 'DEALER_IDLE'
    },
    noTargetRequired = true,
    damage = 0
};

function hero:onDamageReceived(damage, from)
    if (self.health <= self.maxHealth / 2) then
       Utils.setCharModel(self.handle, 269);
    end
end

return hero;