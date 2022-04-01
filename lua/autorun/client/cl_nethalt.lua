--[[
    NetHalt b1.0
    (Clientside)

    Mainly created as a way to create delayed net messages
    of which will only be delivered when the client is ACTUALLY in the game
    as net messages can fail if send in PlayerInitialSpawn
]]

hook.Add("InitPostEntity", "nethalt_i_am_ready_send", function()
    timer.Simple(0, function()
        net.Start("nethalt_i_am_ready")
        net.SendToServer()
    end)
end)
