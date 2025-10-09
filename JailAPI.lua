--[[//
JailAPI 1a

Documentation:

API:Punch() -- Calling punch
API:ToggleCrawl() -- Toggling crawl mode
API:Arrest(Player: Player) -- Arresting player when it in ~5 studs
API:Eject(Player: Player) -- Ejecting player when it in ~5 studs
API:PuzzleSolver() -- Automaticly solving puzzle, like in PowerPlant
API:GetRobberies() -- Retunrs robberies and his states
 States: [
  1. OPEN
  2. ROBBING
  3. CLOSED
 ]
API:Notification(Data: table) -- Sends jailbreak notification
 Data: [
   ["Text"] = "Hello, world!",
   ["Duration"] = 1, -- If duration will be 0, message will be forever
   ["Style"] = "Default" -- Builtin styles: Default, Builtin
 ]
API:GetStyleTables() -- Returns style tables for notifications
 How to use:
  [
   API:GetStyleTables()["MyStyle1"] = {
    ["Color"] = Color3.fromRGB(255, 255, 255), -- Notification Outline Color
    ["Sound"] = 1234567890, -- Roblox Sound Id
    ["TimePosition"] = 0.07 -- I dont fucking know what is this doing, 
   }
  ]

API.WeaponSystem:GetGuns() -- Returns an table with gun names, and attributes (Jailbreak attributes, and api`s bool attribute 'Equipped')
API.WeaponSystem:EquipGun(GunName: string, State: bool) -- Equipping gun

API.PromptSystem:FindPrompts(Prompt: string) -- Searches and retunrs table with all prompts with name in args
API.PromptSystem:Call(Prompt: table (jailbreak prompt)) -- Using prompt
API.PromptSystem:GetSubscribedObject(Prompt: table (jailbreak prompt)) -- Returns prompts subscribed object

API.VehicleSystem:DropRope() -- Dropping/Pulling rope on any Heli
API.VehicleSystem:DropBomb() -- Attempting to drop bomb
API.VehicleSystem:SpawnChassis(Name: string) -- Spawning ground vehicle
API.VehicleSystem:SpawnHeli(Name: string) -- Spawning heli (Required to be near heli spawner)
\\]]--

local API = {}
local WeaponSystem = {}
local PromptSystem = {}
local VehicleSystem = {}

local Movement = {}

ba = game:GetService("ReplicatedStorage")
bb = game:GetService("Workspace")
ab = require(ba.Game.Robbery.PuzzleFlow)
aa = getupvalue(ab.Init, 3)
ac = require(ba.Module.UI)
ad = require(ba.Robbery.RobberyConsts)
af = ba.RobberyState
ah = require(ba.Game.Vehicle.Heli)
ag = debug.getupvalue(ah, 14)
ai = require(ba.Game.DefaultActions)
aj = require(ba.Game.Notification)
ak = game:GetService("Players").LocalPlayer.Folder

function PromptSystem:FindPrompts(Text)
    Actions = {}

    for Index, Action in next, ac.CircleAction.Specs do
        if Text ~= nil and Action.Name == Text then
            table.insert(Actions, Action)
        end
    end

    return Actions
end

function PromptSystem:Call(Prompt)
    return Prompt:Callback(true)
end

function PromptSystem:GetSubscribedObject(Prompt)
    return Prompt.ValidRoot or error("Prompt has no subscribed object.")
end

function Movement:Tween(ToObject, Speed, ObjectToMove)
    if typeof(ToObject) == "CFrame" then
        End = ToObject
    elseif typeof(ToObject) == "Position" then
        End = CFrame.new(ToObject)
    else
        End = CFrame.new(ToObject.Position)
    end

    return game:GetService("TweenService"):Create(ObjectToMove, TweenInfo.new((ToObject.Position - ObjectToMove.Position).Magnitude / Speed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CFrame = End})
end

function API:Punch()
    ai.punchButton.onPressed()
end

function API:ToggleCrawl()
    ai.crawlButton.onPressed()
end

function VehicleSystem:DropRope()
    ag.attemptDropRope()
end

function VehicleSystem:DropBomb()
    ag.attemptDropBomb()
end

function API:Arrest(Player)
    for Index, Action in next, ac.CircleAction.Specs do
        if Action.Name == "Arrest" and Action.PlayerName == Player.Name then
            Action:Callback(true)

            return true
        end
    end

    return false
end

function API:Eject(Player)
    for Index, Action in next, ac.CircleAction.Specs do
        if Action.Name == "Arrest" and Action.PlayerName == Player.Name then
            Action:Callback(true)

            return true
        end
    end

    return false
end

function VehicleSystem:SpawnChassis(Name)
    ba:WaitForChild("GarageSpawnVehicle"):FireServer("Chassis", Name)
end

function VehicleSystem:SpawnHeli(Name)
    bb:WaitForChild("AerialSpawn"):WaitForChild("Prompt"):WaitForChild("OnPressedRemote"):FireServer(true)
    ba:WaitForChild("GarageSetUIOpen"):FireServer(false)
    ba:WaitForChild("GarageSpawnVehicle"):FireServer("Heli", Name)
end

function API:PuzzleSolver() -- Used AI, i too lazy for this shit
    matrix = aa.Grid
    grid_size = #matrix

    local function Pathfinder(matrix, start, finish, color, grid_size)
        local directions = {
            {-1, 0},
            {0, 1},
            {1, 0},
            {0, -1}
        }
        
        local queue = {{pos = start, path = {start}}}
        local visited = {}
        visited[start[1] .. "," .. start[2]] = true
        
        while #queue > 0 do
            local current = table.remove(queue, 1)
            local i, j = current.pos[1], current.pos[2]
            local path = current.path
            
            if i == finish[1] and j == finish[2] then
                local result = {}
                for idx = 2, #path - 1 do
                    table.insert(result, path[idx])
                end
                return result
            end
            
            for _, dir in ipairs(directions) do
                local ni, nj = i + dir[1], j + dir[2]
                
                if ni >= 1 and ni <= grid_size and nj >= 1 and nj <= grid_size then
                    local RobberyName = ni .. "," .. nj
                    
                    if (matrix[ni][nj] == -1 or matrix[ni][nj] == color) and not visited[RobberyName] then
                        visited[RobberyName] = true
                        local new_path = {}
                        for _, point in ipairs(path) do
                            table.insert(new_path, point)
                        end
                        table.insert(new_path, {ni, nj})
                        table.insert(queue, {pos = {ni, nj}, path = new_path})
                    end
                end
            end
        end
        
        return {}
    end

    local solved_matrix = {}
    for i = 1, grid_size do
        solved_matrix[i] = {}
        for j = 1, grid_size do
            solved_matrix[i][j] = matrix[i][j]
        end
    end

    local colors = {}
    for i = 1, grid_size do
        for j = 1, grid_size do
            local cell = solved_matrix[i][j]
            if cell ~= -1 and not colors[cell] then
                colors[cell] = true
            end
        end
    end

    for color, _ in pairs(colors) do
        local points = {}
        for i = 1, grid_size do
            for j = 1, grid_size do
                if solved_matrix[i][j] == color then
                    table.insert(points, {i, j})
                end
            end
        end
        
        if #points == 2 then
            local start = points[1]
            local finish = points[2]
            
            local path = Pathfinder(solved_matrix, start, finish, color, grid_size)
            
            for _, point in ipairs(path) do
                local i, j = point[1], point[2]
                solved_matrix[i][j] = color
            end
        end
    end

    aa.Grid = solved_matrix
    aa.OnConnection()
end

function API:GetRobberies()
    local RobberyFolder = af
    local RobberyData = {"BANK","BANK2","JEWELRY","MUSEUM","POWER_PLANT","TRAIN_PASSENGER","TRAIN_CARGO","CARGO_SHIP","CARGO_PLANE","STORE_GAS","STORE_DONUT","MONEY_TRUCK","HOME_VAULT","TOMB","CROWN_JEWEL","MANSION","OIL_RIG"}
    local RobberyStates = {
        [1] = "OPEN",
        [2] = "ROBBING",
        [3] = "CLOSED"
    }
    local Result = {}

    for Index, Robbery in ipairs(RobberyFolder:GetChildren()) do
        RobberyName = RobberyData[Index]
        RobberyStatus = RobberyStates[Robbery.Value]

        table.insert(Result, {RobberyName, RobberyStatus})
    end

    return Result
end

function API:Notification(Data)
    aj.new(Data)
end

function API:GetStyleTables()
    return debug.getupvalue(aj.new, 1)
end

function WeaponSystem:GetGuns()
    local Inventory = {}

    for _, Tool in ipairs(ak:GetChildren()) do
        Inventory[Tool.Name] = Tool:GetAttributes()
        Inventory[Tool.Name]["Equipped"] = Tool:GetAttribute("InventoryItemLocalEquipped") % 2
    end

    return Inventory
end

function WeaponSystem:EquipGun(GunName, State)
    for _, Tool in ipairs(ak:GetChildren()) do
        if Tool.Name == GunName then
            local EquipRemote = Tool:FindFirstChild("InventoryEquipRemote") or error("gun has no equip remote")

            EquipRemote:FireServer(State)            
        end
    end

    return error("no gun found")
end

function API:SelectTeam(Team)
    if Team ~= "Police" and Team ~= "Prisoner" then
        return error("invalid team string")
    end

    firesignal(game:GetService("Players").LocalPlayer.PlayerGui.AppUI.Buttons.Sidebar.TeamSwitch.TeamSwitch.MouseButton1Down)
    repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("ConfirmationGui") ~= nil
    firesignal(game:GetService("Players").LocalPlayer.PlayerGui.ConfirmationGui.Confirmation.Background.ContainerButtons.ContainerYes.Button.MouseButton1Down)
    repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("TeamSelectGui") ~= nil

    if Team == "Prisoner" then
        firesignal(game:GetService("Players").LocalPlayer.PlayerGui.TeamSelectGui.TeamSelect.Frame.MiddleContainer.TeamsContainer.ImagesContainer.CriminalTeam.Activated)
    else
        firesignal(game:GetService("Players").LocalPlayer.PlayerGui.TeamSelectGui.TeamSelect.Frame.MiddleContainer.TeamsContainer.ImagesContainer.PoliceTeam.Activated)
    end
end

API.WeaponSystem = WeaponSystem
API.PromptSystem = PromptSystem
API.VehicleSystem = VehicleSystem

API.Movement = Movement
API.TeleportSystem = TeleportSystem
API.InstantTeleport = InstantTeleport

return API
