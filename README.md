# Remoteless

An evil networking library created purely out of spite. Have you ever wanted networking that will eat your dragons? Expose unpredictable and undefined behaviour? Is Hyrum's law incarnate? You're in the right place.  

Remoteless is a networking library for the Roblox engine that does not rely on `RemoteEvent`, `RemoteFunction` or `UnreliableRemoteEvent` but instead chooses alternative blasphemous methods for achieving client to server and server to client communication.

# Benchmarks 

Short answer: NO.  
Long answer: This has only a singular asinine use and is magnitudes slower than simply firing a remote event.  

![image](https://github.com/user-attachments/assets/4c82f0fa-1017-4550-9a1f-557b40f87307)

# API Examples

Remoteless uses a polling API for communicating, the polling function is `WaitForEvent` which only passes around your single buffer meaning multiple events must be handled by embedding event data directly in your buffer.

**Server:**

```luau
local Remoteless = require(game:GetService("ReplicatedStorage"):WaitForChild("Remoteless"))

Remoteless.Initiate()

local function PlayerAdded(Player)
	Remoteless.PlayerConnected(Player)
	
	while Remoteless.Active(Player) do 
		local Buf = Remoteless.WaitForEvent(Player)
		
		print("Received data from client: ", buffer.tostring(Buf))
	end
end

local function PlayerRemoving(Player)
	Remoteless.PlayerDisconnected(Player)
end

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)

for i, Player in Players:GetPlayers() do 
	task.spawn(PlayerAdded, Player)
end

task.wait(5)

while true do 
	for i, Player in Players:GetPlayers() do 
		Remoteless.Send(Player, buffer.fromstring("Good Morning!"))
	end
	
	task.wait(5)
end
```

**Client:**

```luau
local Remoteless = require(game:GetService("ReplicatedStorage"):WaitForChild("Remoteless"))

local Humanoid = script.Parent:WaitForChild("Humanoid")

Humanoid.Died:Once(function()
	Remoteless.Cancel()
end)

task.defer(function()
	while true do 
		local Buf = Remoteless.WaitForEvent()

		task.spawn(function()
			print("Received data from server: ", buffer.tostring(Buf))
		end)
	end
end)

Remoteless.Send(buffer.fromstring("Hello World"))
Remoteless.Send(buffer.fromstring("Goodbye World"))
Remoteless.Send(buffer.fromstring("Hello World"))
Remoteless.Send(buffer.fromstring("Goodbye World"))
Remoteless.Send(buffer.fromstring("Hello World"))
```
