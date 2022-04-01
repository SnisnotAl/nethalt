# NetHalt b1.0

## Purpose
Mainly created as a way to create delayed net messages
of which will only be delivered when the client is ACTUALLY in the game
as net messages can fail if send in PlayerInitialSpawn without any checks

## Notes
  - You can use this pretty much the same was as net.
  - This is for WRITE only, as this is only for early server -> client communication
if the client is able to messsage the server, they are already in and this library has no use

## Example Usage
```lua
hook.Add("PlayerInitialSpawn", "player_join_1", function(ply)
    nethalt.Start("Greet")
    nethalt.WriteString(string.format("Hello %s! Have a nice day!", ply:Nick()))
    nethalt.Send(ply)
end)
```

### Other
You can also check out https://github.com/SnisnotAl/PlayerInitialSpawnForRealz for a hook that
allows you to send messages inside too!
