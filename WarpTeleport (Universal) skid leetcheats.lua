--// Init

local function RandomString() -- Credits to InfinityYield
	local Length = math.random(80, 100)
	local Array = {}
	
	for Index = 1, Length do
		Array[Index] = string.char(math.random(0, 200))
	end
	
	return table.concat(Array)
end

local Mouse = game:GetService("Players").LocalPlayer:GetMouse()

local IsLeftMouseDown = false
game:GetService("UserInputService").InputBegan:Connect(function(Input, IsProcessed)
	if not IsProcessed and Input.UserInputType == Enum.UserInputType.MouseButton1 then
		IsLeftMouseDown = true
	end
end)

game:GetService("UserInputService").InputEnded:Connect(function(Input, IsProcessed)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		IsLeftMouseDown = false
	end
end)

local Part = Instance.new("Part")
Part.Name = RandomString()
Part.Parent = game:GetService("Workspace")
Part.Transparency = 1
Part.Anchored = true
Part.CanCollide = false
Part.CanQuery = false
Part.Size = Vector3.new(3, 1, 1.5)

local Outline = Instance.new("SelectionBox")
Outline.Name = RandomString()
Outline.Parent = Part
Outline.Color3 = Color3.new(255,255,255)
Outline.LineThickness = 0.01
Outline.Adornee = Part

--// Animation

local StartTime = os.clock()
game:GetService("RunService").RenderStepped:Connect(function()
	local Elapsed = os.clock() - StartTime
	local Progress = (Elapsed % 6) / 6

	local AngleX = 360 * Progress
	local AngleY = 360 * Progress
	local AngleZ = 360 * Progress

	Part.Orientation = Vector3.new(AngleX, AngleY, AngleZ)
end)

--// Movement & Transparency

local Mouse = game:GetService("Players").LocalPlayer:GetMouse()

game:GetService("RunService").RenderStepped:Connect(function()
	Part.CFrame = Mouse.Hit + Vector3.new(0, 1, 0)
	
	Outline.Visible = game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftAlt)
	game:GetService("UserInputService").MouseIconEnabled = not game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftAlt)
end)

--// Teleportation

while Part ~= nil do
	if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftAlt) then
		if IsLeftMouseDown then
			game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0), Mouse.Hit.Position + Vector3.new(0, 3, 0) + game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector)
            
			while IsLeftMouseDown do
				task.wait()
			end
		end
	end
	
	task.wait()
end