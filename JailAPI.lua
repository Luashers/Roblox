--[[//
JailAPI 1d

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
API:SelectTeam(Team: string) -- Choosing team by string

API.WeaponSystem:GetGuns() -- Returns an table with gun names, and attributes (Jailbreak attributes, and api`s bool attribute 'Equipped')
API.WeaponSystem:EquipGun(GunName: string, State: bool) -- Equipping gun

API.PromptSystem:FindPrompts(Prompt: string) -- Searches and retunrs table with all prompts with name in args
API.PromptSystem:Call(Prompt: table (jailbreak prompt)) -- Using prompt
API.PromptSystem:GetSubscribedObject(Prompt: table (jailbreak prompt)) -- Returns prompts subscribed object

API.VehicleSystem:DropRope() -- Dropping/Pulling rope on any Heli
API.VehicleSystem:DropBomb() -- Attempting to drop bomb
API.VehicleSystem:SpawnChassis(Name: string) -- Spawning ground vehicle
API.VehicleSystem:SpawnHeli(Name: string) -- Spawning heli (Required to be near heli spawner)

API.Movement:Tween(ToObject: CFrame;Vector3;Part, Speed: int;float, ObjectToMove: Part)
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

function API:PuzzleSolver() -- Used AI, fucking piece of shit
    Grid = aa.Grid

    local dirs = {{1,0},{-1,0},{0,1},{0,-1}}

    -- Clone grid
    local function cloneGrid(grid)
        local c = {}
        for y=1,#grid do
            c[y] = {}
            for x=1,#grid[y] do
                c[y][x] = grid[y][x]
            end
        end
        return c
    end

    -- In bounds check
    local function inBounds(grid, x, y)
        return x>=1 and x<=#grid[1] and y>=1 and y<=#grid
    end

    -- Collect all color pairs
    local function collectPairs(grid)
        local pairs = {}
        for y=1,#grid do
            for x=1,#grid[y] do
                local v = grid[y][x]
                if v >= 0 then
                    pairs[v] = pairs[v] or {}
                    table.insert(pairs[v], {x=x,y=y})
                end
            end
        end
        return pairs
    end

    -- BFS to expand color into empty cells
    local function expandColor(grid, start, goal, color)
        local queue = {{x=start.x, y=start.y}}
        local visited = {}
        for y=1,#grid do visited[y] = {} end
        visited[start.y][start.x] = true

        local parent = {}
        parent[start.y..","..start.x] = nil

        while #queue>0 do
            local cur = table.remove(queue,1)
            if cur.x==goal.x and cur.y==goal.y then
                -- reconstruct path
                local path = {}
                local k = cur.y..","..cur.x
                while k do
                    local coords = {}
                    coords.y, coords.x = k:match("(%d+),(%d+)")
                    coords.x = tonumber(coords.x)
                    coords.y = tonumber(coords.y)
                    table.insert(path,1,coords)
                    k = parent[k]
                end
                -- fill path
                for _,p in ipairs(path) do
                    if grid[p.y][p.x]==-1 then
                        grid[p.y][p.x] = color
                    end
                end
                return true
            end
            for _,d in ipairs(dirs) do
                local nx, ny = cur.x+d[1], cur.y+d[2]
                if inBounds(grid,nx,ny) and not visited[ny][nx] then
                    local v = grid[ny][nx]
                    if v==-1 or (nx==goal.x and ny==goal.y) then
                        visited[ny][nx] = true
                        table.insert(queue,{x=nx,y=ny})
                        parent[ny..","..nx] = cur.y..","..cur.x
                    end
                end
            end
        end
        return false -- no path found
    end

    -- Check if all cells are filled
    local function allFilled(grid)
        for y=1,#grid do
            for x=1,#grid[y] do
                if grid[y][x]==-1 then return false end
            end
        end
        return true
    end

    -- Main AutoSolve function
    local function AutoSolve(grid)
        local g = cloneGrid(grid)
        local bpairs = collectPairs(g)

        -- sort colors by manhattan distance (shortest first)
        local colors = {}
        for c,v in pairs(bpairs) do
            local a,b = v[1],v[2]
            local dist = math.abs(a.x-b.x)+math.abs(a.y-b.y)
            table.insert(colors,{c=c,dist=dist})
        end
        table.sort(colors,function(a,b) return a.dist<b.dist end)

        -- Try to expand each color in order
        for _,info in ipairs(colors) do
            local c = info.c
            local pts = bpairs[c]
            local success = expandColor(g, pts[1], pts[2], c)
            if not success then
                return nil,"No valid solution"
            end
        end

        if allFilled(g) then
            return g
        else
            return nil,"Could not fill all cells"
        end
    end

    local solved, err = AutoSolve(Grid)

    if not solved then
        return false
    end

    aa.Grid = solved_matrix
    aa.OnConnection()

    return true
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

    if game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("TeamSelectGui") == nil then
        firesignal(game:GetService("Players").LocalPlayer.PlayerGui.AppUI.Buttons.Sidebar.TeamSwitch.TeamSwitch.MouseButton1Down)
        repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("ConfirmationGui") ~= nil
        firesignal(game:GetService("Players").LocalPlayer.PlayerGui.ConfirmationGui.Confirmation.Background.ContainerButtons.ContainerYes.Button.MouseButton1Down)
        
        for Index = 1, 50 do
            if game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("TeamSelectGui") ~= nil then
                break
            end
            wait(0.05)

            if Index == 50 then
                return "cooldown"
            end
        end
    end

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