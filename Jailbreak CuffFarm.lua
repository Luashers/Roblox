local PlayerList = {"Camera", "Terrarian"}
for _, Player in ipairs(game:GetService("Players"):GetChildren()) do
    table.insert(PlayerList, Player.Name)
end

for _, Object in ipairs(game:GetService("Workspace"):GetChildren()) do
    if Object.Name == "Cell" then
        print("")
    else
        if table.find(PlayerList, Object.Name) == nil then
            pcall(function()
                Object:Remove()
            end)
        end
    end
end

for _, Object in ipairs(game:GetService("ReplicatedStorage"):GetChildren()) do
    Object:Remove()
end

for _, Object in ipairs(game:GetService("Players").LocalPlayer.PlayerScripts:GetChildren()) do
    Object:Remove()
end

for _, Object in ipairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
    Object:Remove()
end

for _, Object in ipairs(game:GetService("Players").LocalPlayer:GetChildren()) do
    if table.find({"PlayerGui", "PlayerScripts", "StarterGear", "leaderstats", "Backpack", "Folder", ""}, Object.Name) == nil then
        Object:Remove()
    end
end

for _, Object in ipairs(game:GetService("Lighting"):GetChildren()) do
    Object:Remove()
end

local function c()
    repeat task.wait() until game:GetService("Players").LocalPlayer.Character ~= nil and game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid") ~= nil and game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid").Health ~= 0 and game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart") ~= nil and game:GetService("Players").LocalPlayer.Team ~= game:GetService("Teams").Criminal

    wait(.5)

    if game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position.Y < 18 then
        wait(2)
        replicatesignal(game:GetService("Players").LocalPlayer.Kill)
        game:GetService("Players").LocalPlayer.Character.Humanoid.Health = 0
    else
        print(game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position.Y)
        game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position.X, 1000, game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position.Z)
        task.wait(0.05)
        repeat 
            local Unit = (Vector3.new(-1547, 1000, -2108) - game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position).Unit * 150;
            game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(Unit.X, 0, Unit.Z)

            task.wait()

            game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position.X, 1000, game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position.Z)
        until (game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(-1547, 1000, -2108)).Magnitude < 10

        game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.zero
        game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-1547, 1000, -2108)
        task.wait(0.05)
        game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-1547, 52, -2108)

        repeat 
            wait()
            game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-1547, 52, -2108)
        until game:GetService("Players").LocalPlayer.Team ~= game:GetService("Teams").Criminal
        wait(4.2)
        replicatesignal(game:GetService("Players").LocalPlayer.Kill)
        game:GetService("Players").LocalPlayer.Character.Humanoid.Health = 0
    end
end
game:GetService("Players").LocalPlayer.CharacterAdded:Connect(c)
c()