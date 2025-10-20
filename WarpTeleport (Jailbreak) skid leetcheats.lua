--// Configuration

KeyCode = Enum.KeyCode.LeftAlt
Thickness = 0.01
Size = Vector3.new(3, 1, 1.5)

--// Init

local Mouse = game:GetService("Players").LocalPlayer:GetMouse()

local function RandomString() -- Credits to InfinityYield
	local Length = math.random(80, 100)
	local Array = {}
	
	for Index = 1, Length do
		Array[Index] = string.char(math.random(0, 200))
	end
	
	return table.concat(Array)
end

local function Call()
	if IsCarSelected == false then
		game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0), Mouse.Hit.Position + Vector3.new(0, 3, 0) + game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector)
	else
		if (game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position - Car.BoundingBox.Position).Magnitude > 15 then
			game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = Car.BoundingBox.CFrame + Vector3.new(0, 5, 0)
		end

		if game:GetService("Players").LocalPlayer.Character.Humanoid.Sit == true then
			require(game:GetService("ReplicatedStorage").Game.CharacterUtil).OnJump()
			wait(.5)
		end

		for Index = 1,5 do
			NearestCarAction:Callback(true)
			wait(.2)
		end
	end
end

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
Part.Size = Size

local Outline = Instance.new("SelectionBox")
Outline.Name = RandomString()
Outline.Parent = Part
Outline.Color3 = Color3.new(math.random(500, 50000000),math.random(500, 50000000),math.random(500, 50000000))
Outline.LineThickness = Thickness
Outline.Adornee = Part

NearestCarAction = nil
IsCarSelected = false
CarOutline = nil
Car = nil

task.spawn(function()
	for _, Object in ipairs(game:GetService("Workspace").Vehicles:GetDescendants()) do
		if Object:IsA("Part") and Object.Name ~= "BoundingBox" then
			Object.CanQuery = false
		end
	end

	for _, Object in ipairs(game:GetService("Workspace").VehicleSpawns:GetDescendants()) do
		if Object:IsA("Part") and Object.Name ~= "Region" then
			Object.CanQuery = false
		end
	end

	while wait(5) and Part ~= nil do
		for _, Object in ipairs(game:GetService("Workspace").Vehicles:GetDescendants()) do
			if Object:IsA("Part") and Object.Name ~= "BoundingBox" then
				Object.CanQuery = false
			end
		end

		for _, Object in ipairs(game:GetService("Workspace").VehicleSpawns:GetDescendants()) do
			if Object:IsA("Part") and Object.Name ~= "Region" then
				Object.CanQuery = false
			end
		end
	end
end)

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

--// Rendering

game:GetService("RunService").RenderStepped:Connect(function()
	Part.CFrame = Mouse.Hit + Vector3.new(0, 1, 0)
	
	if not IsCarSelected then
		Outline.Visible = game:GetService("UserInputService"):IsKeyDown(KeyCode)
		game:GetService("UserInputService").MouseIconEnabled = not game:GetService("UserInputService"):IsKeyDown(KeyCode)

		if CarOutline ~= nil then
			CarOutline.Visible = game:GetService("UserInputService"):IsKeyDown(KeyCode)
		end
	else
		Outline.Visible = false
		game:GetService("UserInputService").MouseIconEnabled = true

		if CarOutline ~= nil then
			CarOutline.Visible = game:GetService("UserInputService"):IsKeyDown(KeyCode)
		end
	end
end)

game:GetService("RunService").RenderStepped:Connect(function()
	local NearestDistance = math.huge
	local NearestCar = nil
	local CarAction = nil

	for Index, Action in next, require(game:GetService("ReplicatedStorage").Module.UI).CircleAction.Specs do
		if Action.Name == "Enter Passenger" and Action.ValidRoot ~= nil and Action.ValidRoot:GetAttribute("Locked") == false and Action.ValidRoot:FindFirstChild("_VehicleState_" .. game:GetService("Players").LocalPlayer.Name) == nil then
			CarObject = Action.ValidRoot

			if (CarObject.Seat.Position - Part.Position).Magnitude < NearestDistance then
				NearestDistance = (CarObject.Seat.Position - Part.Position).Magnitude
				NearestCar = CarObject
				CarAction = Action
			end
		end
	end

	for Index, Action in next, require(game:GetService("ReplicatedStorage").Module.UI).CircleAction.Specs do
		if NearestCar ~= nil and Action.Name == "Enter Driver" and Action.ValidRoot == NearestCar and (require(game:GetService("ReplicatedStorage").App.store)._state.garageOwned.Vehicles[NearestCar.Name] or NearestCar.Name == "Camaro" or NearestCar.Name == "Jeep" or NearestCar.Name == "Heli") then
			CarAction = Action
		end
	end

	if NearestCar ~= nil and (NearestCar.BoundingBox.Position - Part.Position).Magnitude <= 15 then
		IsCarSelected = true
		Car = NearestCar
		NearestCarAction = CarAction

		local Outline = Instance.new("SelectionBox")
		Outline.Name = RandomString()
		Outline.Parent = Car.BoundingBox
		Outline.Color3 = Color3.new(math.random(500, 50000000),math.random(500, 50000000),math.random(500, 50000000))
		Outline.LineThickness = Thickness
		Outline.Adornee = Car.BoundingBox

		if CarOutline ~= nil then
			CarOutline:Remove()
			CarOutline = nil
		end

		CarOutline = Outline
	else
		IsCarSelected = false

		if CarOutline ~= nil then
			CarOutline:Remove()
			CarOutline = nil
		end
	end
end)

--// Teleportation

while Part ~= nil do
	if game:GetService("UserInputService"):IsKeyDown(KeyCode) then
		if IsLeftMouseDown then
			Call()
            
			while IsLeftMouseDown do
				task.wait()
			end
		end
	end
	
	task.wait()
end

local Outline = Instance.new("SelectionBox")
Outline.Name = RandomString()
Outline.Parent = Part
Outline.Color3 = Color3.new(255,255,255)
Outline.LineThickness = 0.01
Outline.Adornee = Part

NearestCarAction = nil
IsCarSelected = false
CarOutline = nil
Car = nil

task.spawn(function()
	for _, Object in ipairs(game:GetService("Workspace").Vehicles:GetDescendants()) do
		if Object:IsA("Part") and Object.Name ~= "BoundingBox" then
			Object.CanQuery = false
		end
	end

	for _, Object in ipairs(game:GetService("Workspace").VehicleSpawns:GetDescendants()) do
		if Object:IsA("Part") and Object.Name ~= "Region" then
			Object.CanQuery = false
		end
	end

	while wait(5) and Part ~= nil do
		for _, Object in ipairs(game:GetService("Workspace").Vehicles:GetDescendants()) do
			if Object:IsA("Part") and Object.Name ~= "BoundingBox" then
				Object.CanQuery = false
			end
		end

		for _, Object in ipairs(game:GetService("Workspace").VehicleSpawns:GetDescendants()) do
			if Object:IsA("Part") and Object.Name ~= "Region" then
				Object.CanQuery = false
			end
		end
	end
end)

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

--// Rendering

game:GetService("RunService").RenderStepped:Connect(function()
	Part.CFrame = Mouse.Hit + Vector3.new(0, 1, 0)
	
	if not IsCarSelected then
		Outline.Visible = game:GetService("UserInputService"):IsKeyDown(KeyCode)
		game:GetService("UserInputService").MouseIconEnabled = not game:GetService("UserInputService"):IsKeyDown(KeyCode)

		if CarOutline ~= nil then
			CarOutline.Visible = game:GetService("UserInputService"):IsKeyDown(KeyCode)
		end
	else
		Outline.Visible = false
		game:GetService("UserInputService").MouseIconEnabled = true

		if CarOutline ~= nil then
			CarOutline.Visible = game:GetService("UserInputService"):IsKeyDown(KeyCode)
		end
	end
end)

game:GetService("RunService").RenderStepped:Connect(function()
	local NearestDistance = math.huge
	local NearestCar = nil
	local CarAction = nil

	for Index, Action in next, require(game:GetService("ReplicatedStorage").Module.UI).CircleAction.Specs do
		if Action.Name == "Enter Passenger" and Action.ValidRoot ~= nil and Action.ValidRoot:GetAttribute("Locked") == false then
			CarObject = Action.ValidRoot

			if (CarObject.Seat.Position - Part.Position).Magnitude < NearestDistance then
				NearestDistance = (CarObject.Seat.Position - Part.Position).Magnitude
				NearestCar = CarObject
				CarAction = Action
			end
		end
	end

	for Index, Action in next, require(game:GetService("ReplicatedStorage").Module.UI).CircleAction.Specs do
		if NearestCar ~= nil and Action.Name == "Enter Driver" and Action.ValidRoot == NearestCar and (require(game:GetService("ReplicatedStorage").App.store)._state.garageOwned.Vehicles[NearestCar.Name] or NearestCar.Name == "Camaro" or NearestCar.Name == "Jeep" or NearestCar.Name == "Heli") then
			CarAction = Action
		end
	end

	if NearestCar ~= nil and (NearestCar.BoundingBox.Position - Part.Position).Magnitude <= 15 then
		IsCarSelected = true
		Car = NearestCar
		NearestCarAction = CarAction

		local Outline = Instance.new("SelectionBox")
		Outline.Name = RandomString()
		Outline.Parent = Car.BoundingBox
		Outline.Color3 = Color3.new(255,255,255)
		Outline.LineThickness = 0.01
		Outline.Adornee = Car.BoundingBox

		if CarOutline ~= nil then
			CarOutline:Remove()
			CarOutline = nil
		end

		CarOutline = Outline
	else
		IsCarSelected = false

		if CarOutline ~= nil then
			CarOutline:Remove()
			CarOutline = nil
		end
	end
end)

--// Teleportation

while Part ~= nil do
	if game:GetService("UserInputService"):IsKeyDown(KeyCode) then
		if IsLeftMouseDown then
			pcall(function()
				Call()
			end)
            
			while IsLeftMouseDown do
				task.wait()
			end
		end
	end
	
	task.wait()
end