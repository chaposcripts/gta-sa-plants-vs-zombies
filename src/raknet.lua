local RakNet = {
    nop = false
};

function RakNet.init()
    for _, event in ipairs({ 'onSendPacket', 'onReceivePacket', 'onSendRpc', 'onReceiveRpc' }) do
        addEventHandler(event, function()
            return RakNet.nop;
        end);
    end
end

return RakNet;