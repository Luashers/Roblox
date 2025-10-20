DlWQapEWNSZFwUQAmzLQ = false

local old;
old = hookfunction(Instance.new("RemoteEvent").FireServer, function(...)
	local Args = {...}

	if string.sub(tostring(Args[2]), 1,1) == "!" and not DlWQapEWNSZFwUQAmzLQ then
		if Args[3] == "Renamed Service" or Args[3] == "FailedPcall" then
			warn("[NN] Local AntiCheat hooked")
			DlWQapEWNSZFwUQAmzLQ = true

			return function() end
		end
	end

	return old(...)
end)

warn("[NN] Initilization...")

game:GetService("Workspace").Name = "Workspace"

if game:GetService("Players").LocalPlayer.Team ~= game:GetService("Teams").Prisoner then
    if game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("TeamSelectGui") == nil then
        firesignal(game:GetService("Players").LocalPlayer.PlayerGui.AppUI.Buttons.Sidebar.TeamSwitch.TeamSwitch.MouseButton1Down)
        repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("ConfirmationGui") ~= nil
        firesignal(game:GetService("Players").LocalPlayer.PlayerGui.ConfirmationGui.Confirmation.Background.ContainerButtons.ContainerYes.Button.MouseButton1Down)
        
        for Index = 1, 50 do
            if game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("TeamSelectGui") ~= nil then
                break
            end
            wait(0.05)
        end
    end
    firesignal(game:GetService("Players").LocalPlayer.PlayerGui.TeamSelectGui.TeamSelect.Frame.MiddleContainer.TeamsContainer.ImagesContainer.CriminalTeam.Activated)
end

local LongTeleport = loadstring(game:HttpGet("https://raw.githubusercontent.com/Luashers/Roblox/refs/heads/main/Teleport%20System.lua"))()
local QuickTeleport = function(Object, NewCFrame, Speed)
    local Tween = game:GetService("TweenService"):Create(Object, TweenInfo.new((CFrame.Position - Object.Position).Magnitude / Speed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CFrame = NewCFrame})
    Tween:Play()
    Tween.Completed:Wait()

    return Tween
end
local Teleport = function(Object, NewCFrame)
    Object.CFrame = CFrame.new(NewCFrame)
end

local IsAlive = function()
    if game:GetService("Players").LocalPlayer.Character == nil or game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid") == nil or game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart") == nil or game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid").Health == 0 then
        return false
    end

    return true
end

repeat wait() until IsAlive()

State = {
    ["State"] = "Initilization",
    ["_ConnectedFunctions"] = {},
    ["OnChanged"] = function(Self, Function)
        table.insert(Self["_ConnectedFunctions"], Function)
    end,
    ["SetState"] = function(Self, NewState)
        Self["State"] = NewState

        for Index, StateFunction in ipairs(Self["_ConnectedFunctions"]) do
            pcall(function() Function(NewState) end)
        end
    end
}

local function AirDrop()
    if game:GetService("Workspace"):FindFirstChild("Drop") ~= nil and game:GetService("Workspace"):FindFirstChild("Drop"):FindFirstChild("Countdown") ~= nil and game:GetService("Workspace"):FindFirstChild("Drop"):GetAttribute("BriefcaseCollected") ~= true then
        State:SetState("Teleporting to airdrop")

        local AirDrop = game:GetService("Workspace"):FindFirstChild("Drop")

        LongTeleport(CFrame.new(AirDrop:FindFirstChild("Countdown").Position.X, 1500, AirDrop:FindFirstChild("Countdown").Position.Z))

        State:SetState("Waiting until AirDrop land")

        repeat 
            game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(AirDrop:FindFirstChild("Countdown").Position.X, 1500, AirDrop:FindFirstChild("Countdown").Position.Z)
            game:GetService("Workspace").Gravity = 0

            wait(1)
        until AirDrop:GetAttribute("BriefcaseLanded") == true
        game:GetService("Workspace").Gravity = 192

        State:SetState("Collecting AirDrop")

        game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = AirDrop:FindFirstChild("Countdown").CFrame

        wait()

        AirDrop:FindFirstChild("BriefcasePress"):FireServer(false)
        repeat
            AirDrop:FindFirstChild("BriefcaseHoldUpdate"):FireServer()

            if AirDrop:FindFirstChild("NPC") ~= nil then
                for Index, NPC in ipairs(AirDrop:FindFirstChild("NPCs")) do
                    if NPC:FindFirstChild("Humanoid") ~= nil then
                        NPC.Humanoid.Health = 0
                    end
                end
            end

            wait(0.25)
        until not IsAlive() or game:GetService("Workspace"):FindFirstChild("Drop"):GetAttribute("BriefcaseCollected") == true

        State:SetState("Collecting cash")

        for Index, Action in next, require(game:GetService("ReplicatedStorage").Module.UI).CircleAction.Specs do
            if Action.Tag.Name == "Cash" and Action.ValidRoot:FindFirstChild("PlayerName").Value == "AirDrop Reward" then
                local Root = Action.ValidRoot

                QuickTeleport(game:GetService("Players").LocalPlayer.Character.HumanoidRootPart, Root.BoundingBox.CFrame + Vector3.new(0, 3, 0), 50)
                Action:Callback(true)
            end
        end

        State:SetState("Collected AirDrop")
    else
        return false
    end
end

State:OnChanged(function(State)
    warn(State)
end)

AirDrop()