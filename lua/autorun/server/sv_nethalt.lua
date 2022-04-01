--[[
    NetHalt b1.0
    (Serverside)

    Mainly created as a way to create delayed net messages
    of which will only be delivered when the client is ACTUALLY in the game
    as net messages can fail if send in PlayerInitialSpawn

    You can also check out https://github.com/SnisnotAl/PlayerInitialSpawnForRealz for a hook that
    allows you to send messages inside too!

    This idea was inspired by BullyHunter on the Garry's Mod Discord server

    Functions:
        nethalt.Start(messageName)
        .Send(player)
        .Cancel() -- Cancels the message in construction

        .WriteAngle(...)
        .WriteBit(...)
        .WriteBool(...)
        .WriteColor(...)
        .WriteData(...)
        .WriteDouble(...)
        .WriteEntity(...)
        .WriteFloat(...)
        .WriteInt(...)
        .WriteMatrix(...)
        .WriteNormal(...)
        .WriteString(...)
        .WriteTable(...)
        .WriteType(...)
        .WriteUInt(...)
        .WriteVector(...)
        
        (All write functions have same arguments as their net.* counterparts)
        (See https://wiki.facepunch.com/gmod/net)


    Example code:
        hook.Add("PlayerInitialSpawn", "player_join_1", function(ply)
            nethalt.Start("Greet")
            nethalt.WriteString(string.format("Hello %s! Have a nice day!", ply:Nick()))
            nethalt.Send(ply)
        end)
]]

--[[
MIT License

Copyright (c) 2022 SnisnotAl

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

nethalt = nethalt or {
    current = nil,
    queue = {}
}

nethalt.Start = function(messageName)
    if (not messageName) or (messageName == "") then
        error(string.format("[nethalt] You didn't provide a network string\n", messageName))
        return false
    end

    if util.NetworkStringToID(messageName) == 0 then
        error(string.format("[nethalt] There is no network string named \"%s\"\n", messageName))
        return false
    end

    if nethalt.current ~= nil then
        ErrorNoHalt(string.format("[nethalt] Destroying \"%s\" network message in favor of \"%s\"\n", nethalt.current.messageName, messageName))
        nethalt.current = nil
    end

    nethalt.current = {
        messageName = messageName,
        data = {

        },
        recipient = nil
    }

    return true
end

local copyF = {
    "WriteAngle",
    "WriteBit",
    "WriteBool",
    "WriteColor",
    "WriteData",
    "WriteDouble",
    "WriteEntity",
    "WriteFloat",
    "WriteInt",
    "WriteMatrix",
    "WriteNormal",
    "WriteString",
    "WriteTable",
    "WriteType",
    "WriteUInt",
    "WriteVector",
}

for _, v in pairs(copyF) do
    nethalt[v] = function(...)
        if nethalt.current == nil then
            error("[nethalt] There is no network message to write to\n")
            return
        end
    
        table.insert(nethalt.current.data, {v, unpack({...})})
    end
end

nethalt.Send = function(ply)
    if not ply then
        error("[nethalt] You didn't provide a player\n")
        return
    end

    if nethalt.current == nil then
        error("[nethalt] There is no network message to send\n")
        return
    end

    nethalt.current.recipient = ply

    local atq = {}
    table.CopyFromTo(nethalt.current, atq)
    table.insert(nethalt.queue, atq)

    nethalt.current = nil

    if ply:GetVar("nethaltReady", false) == true then
        hook.Run("nethalt_do_now", ply) -- send instantly if already ready
    end
end

nethalt.Cancel = function()
    nethalt.current = nil
end

-- Ready checking (using net)
-- only touch if you have a big brain

util.AddNetworkString("nethalt_i_am_ready")
net.Receive("nethalt_i_am_ready", function(_, ply)
    if ply:GetVar("nethaltReady", false) == false then
        ply:SetVar("nethaltReady", true) -- one time only
        hook.Run("nethalt_do_now", ply)
    end
end)

hook.Add("nethalt_do_now", "nethalt_do_now_1", function(ply)
    for k, v in pairs(nethalt.queue) do
        if v.recipient == ply then
            local s, o = pcall(function()
                net.Start(v.messageName)

                for _, v2 in pairs(v.data) do
                    local ntype = v2[1]
                    table.remove(v2, 1) -- remove msg name from args

                    net[ntype](unpack(v2)) -- use orig func
                end

                net.Send(v.recipient)
            end)

            if s == false then
                ErrorNoHaltWithStack("[nethalt] Something went wrong :( /\n" .. o)
            end

            nethalt.queue[k] = nil
        end
    end
end)
