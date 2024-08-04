local workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local Communication = workspace:WaitForChild("Communication")
local ServerCommunication = Player:WaitForChild("PlayerGui"):WaitForChild("Communication")

repeat
	RunService.RenderStepped:Wait()
until #Communication:GetChildren() == ((2 * 256) + 2 + 2)

local Complete, PostComplete = Communication.Complete, Communication.PostComplete

local RemotelessReplicator = {}

local mutex = require(script.Parent:WaitForChild("Mutex"))
local SendingMutex = mutex.new()
local SendingThread = nil

local OutOfRangeVector = Vector3.new(1000, 1, 1000)

function RemotelessReplicator.Send(Buf)
	local Character = Player.Character 
	
	if not Character then 
		return 
	end
	
	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	
	if not HumanoidRootPart then
		return
	end
	
	--/* If the character dies while we're doing this it might actually explode, idk tho */
	
	mutex.lock(SendingMutex)
	
	SendingThread = coroutine.running()
		
	local Length = buffer.len(Buf)

	for i = 0, Length - 1 do
		local value = buffer.readu8(Buf, i)
		
		local ByteRoute1 = Communication[`Byte_1_{value}`]
		local ByteRoute2 = Communication[`Byte_2_{value}`]
		
		local ByteRoute = ByteRoute1:GetAttribute(Player.Name) and ByteRoute2 or ByteRoute1
		
		repeat
			ByteRoute.CFrame = HumanoidRootPart.CFrame
			RunService.RenderStepped:Wait()
		until ByteRoute:GetAttribute(Player.Name)

		ByteRoute.Position = OutOfRangeVector
		
		RunService.RenderStepped:Wait()
	end
	
	repeat
		Complete.CFrame = HumanoidRootPart.CFrame
		RunService.RenderStepped:Wait()
	until Complete:GetAttribute(Player.Name)

	Complete.Position = OutOfRangeVector
	
	repeat
		PostComplete.CFrame = HumanoidRootPart.CFrame
		RunService.RenderStepped:Wait()
	until not Complete:GetAttribute(Player.Name)

	PostComplete.Position = OutOfRangeVector
	
	SendingThread = nil 
	
	mutex.unlock(SendingMutex)
end

function RemotelessReplicator.Cancel()
	if SendingThread then 
		coroutine.close(SendingThread)
		SendingThread = nil 
	end
		
	mutex.cleanunlock(SendingMutex)
	
	for i, Route in Communication:GetChildren() do 
		Route.Position = OutOfRangeVector
	end
end

function RemotelessReplicator.WaitForEvent()
	local BufVal = ServerCommunication.ChildAdded:Wait()
	
	return buffer.fromstring(BufVal.Value)
end

return RemotelessReplicator