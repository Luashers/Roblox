local function Invisible()
    Weapons = {}

    for Index, Weapon in ipairs(game:GetService("Players").LocalPlayer.Folder:GetChildren()) do
        if Weapon:GetAttribute("AmmoCurrent") ~= nil and Weapon:FindFirstChild("InventoryEquipRemote") ~= nil then
            table.insert(Weapons, Weapon)
        end
    end

    if #Weapons == 0 then
        require(game:GetService("ReplicatedStorage").Game.Notification).new({
            ["Text"] = "[LI] You has no guns."
        })
    else
        Weapon = Weapons[math.random(1, #Weapons)]

        Weapon.InventoryEquipRemote:FireServer(true)

        local Mouse = {
            ["Local"] = true,
            ["ProjectMouseLocationToWorld"] = function(...)
                return Vector3.new(math.huge, math.huge, math.huge)
            end,
            ["GetMouseLocation"] = function() return end,
            ["LastReplicateMousePosition"] = -math.huge,
            ["MousePosition"] = nil
        }

        require(game:GetService("ReplicatedStorage").Game.Item.Gun).UpdateMousePosition(Mouse)

        wait(.5)

        Weapon.InventoryEquipRemote:FireServer(false)
    end
end

Invisible()