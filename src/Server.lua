local workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local mutex = require(script.Parent:WaitForChild("Mutex"))
local signal = require(script.Parent:WaitForChild("Signal"))

local RemotelessReceiver = {}

local PlayerBuffers = { }
local PlayerPolls = { }
local PlayerConnections = { }

local OutOfRangeVector = Vector3.new(1000, 1, 1000)
local BigSizeVector = Vector3.new(50, 50, 50)

function RemotelessReceiver.Initiate()
	local Ratelimit = { }
	local Communication = Instance.new("Folder")
	Communication.Name = "Communication"

	local function CreateRoutePart()
		local Part = Instance.new("Part")
		Part.Anchored = true 
		Part.CanCollide = false 
		Part.CanTouch = true 
		Part.CanQuery = true 
		Part.Position = OutOfRangeVector
		Part.Size = BigSizeVector
		Part.Transparency = 1
		
		return Part 
	end
	
	for j = 1, 2 do 
		for i = 0, 256 do 
			local Part = CreateRoutePart()
			Part.Name = `Byte_{j}_{i}`
			Part:SetAttribute("RouteType", j)

			Part.Touched:Connect(function(CharacterPart)
				local Character = CharacterPart.Parent
				local Player = Players:GetPlayerFromCharacter(Character)

				if not Player then 
					return --/* ?? */
				end

				if Part:GetAttribute("RouteType") == 1 then
					Communication[`Byte_2_{i}`]:SetAttribute(Player.Name, nil)
				else 
					Communication[`Byte_1_{i}`]:SetAttribute(Player.Name, nil)
				end
				
				--/* Repeating byte, needs to switch to other byte upload */
				if Part:GetAttribute(Player.Name) then
					return
				end
				
				Part:SetAttribute(Player.Name, true)
				
				if not PlayerBuffers[Player] then
					PlayerBuffers[Player] = ""
				end
				
				PlayerBuffers[Player] ..= string.char(i)
			end)

			Part.Parent = Communication
		end
	end
	
	local CompletePart = CreateRoutePart()
	CompletePart.Name = `Complete`

	CompletePart.Touched:Connect(function(CharacterPart)
		local Character = CharacterPart.Parent
		local Player = Players:GetPlayerFromCharacter(Character)

		if not Player then 
			return --/* ?? */
		end
		
		if CompletePart:GetAttribute(Player.Name) then
			return
		end

		CompletePart:SetAttribute(Player.Name, true)
		
		local Buf = PlayerBuffers[Player]
		PlayerBuffers[Player] = nil
		
		PlayerPolls[Player]:Fire(buffer.fromstring(Buf))
	end)
	
	CompletePart.Parent = Communication
	
	local PostCompletePart = CreateRoutePart()
	PostCompletePart.Name = `PostComplete`

	PostCompletePart.Touched:Connect(function(CharacterPart)
		local Character = CharacterPart.Parent
		local Player = Players:GetPlayerFromCharacter(Character)

		if not Player then 
			return --/* ?? */
		end

		CompletePart:SetAttribute(Player.Name, nil)
	end)
	
	PostCompletePart.Parent = Communication
	
	Communication.Parent = workspace
end

function RemotelessReceiver.PlayerConnected(Player)
	PlayerPolls[Player] = signal.new()
	
	local PlayerGui = Player:WaitForChild("PlayerGui")
	
	local Communication = Instance.new("ScreenGui")
	Communication.ResetOnSpawn = false
	Communication.Name = "Communication"
	Communication.Parent = PlayerGui
	
	
	PlayerConnections[Player] = Player.CharacterRemoving:Connect(function()
		PlayerBuffers[Player] = nil
	end)
end

function RemotelessReceiver.PlayerDisconnected(Player)
	PlayerPolls[Player] = nil
	PlayerBuffers[Player] = nil
	PlayerConnections[Player]:Disconnect()
	PlayerConnections[Player] = nil
end

function RemotelessReceiver.Active(Player)
	return PlayerPolls[Player] and true or false
end

function RemotelessReceiver.WaitForEvent(Player)
	local Buf = PlayerPolls[Player]:Wait()	
	
	return Buf
end

function RemotelessReceiver.Send(Player, Buf)
	local PlayerGui = Player:FindFirstChild("PlayerGui")
	
	if not PlayerGui then
		error("Player gui was not loaded")
	end
	
	local Communication = PlayerGui:FindFirstChild("Communication")
	
	if not Communication then
		error("Communications folder was not loaded")
	end
	
	local StringValue = Instance.new("StringValue")
	StringValue.Value = buffer.tostring(Buf)
	StringValue.Parent = Communication
	
	task.delay(30, function()
		StringValue:Destroy()
	end)
end

return RemotelessReceiver