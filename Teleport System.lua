--// Fork by Luashers v2

--// services

local replicated_storage = game:GetService("ReplicatedStorage");
local run_service = game:GetService("RunService");
local pathfinding_service = game:GetService("PathfindingService");
local players = game:GetService("Players");
local tween_service = game:GetService("TweenService");

--// variables

local player = players.LocalPlayer;

local dependencies = {
    variables = {
        up_vector = Vector3.new(0, 1500, 0),
        raycast_params = RaycastParams.new(),
        path = pathfinding_service:CreatePath({WaypointSpacing = 3}),
        player_speed = 150, 
        vehicle_speed = 450,
        heli_speed = 8000, -- Heli`s almost unlimited by speed for anticheat
        heli_priority = 1, -- Priority studs for heli, automaticly, changing useless
        teleporting = false,
        stopVelocity = false
    },
    modules = {
        ui = require(replicated_storage.Module.UI),
        store = require(replicated_storage.App.store),
        player_utils = require(replicated_storage.Game.PlayerUtils),
        vehicle_data = require(replicated_storage.Game.Garage.VehicleData),
        character_util = require(replicated_storage.Game.CharacterUtil),
        paraglide = require(replicated_storage.Game.Paraglide)
    },
    helicopters = { Heli = true }, -- heli is included in free vehicles
    motorcycles = { Volt = false }, -- volt type is "custom" but works the same as a motorcycle
    free_vehicles = { Camaro = true, Jeep = true, Heli = true},
    unsupported_vehicles = { SWATVan = true, Wraith = true},
    door_positions = { }    
};

local movement = { };
local utilities = { };

--// function to toggle if a door can be collided with

function utilities:toggle_door_collision(door, toggle)
    for index, child in next, door.Model:GetChildren() do 
        if child:IsA("BasePart") then 
            child.CanCollide = toggle;
        end; 
    end;
end;

--// function to get the nearest vehicle that can be entered

function utilities:get_nearest_vehicle(tried, spawned) -- unoptimized
    local nearest;
    local distance = math.huge;

    for index, action in next, dependencies.modules.ui.CircleAction.Specs do -- all of the interations
        if action.IsVehicle and action.ShouldAllowEntry == true and action.Enabled == true and action.Name == "Enter Driver" or action.Name == "Hijack" then -- if the interaction is to enter the driver seat of a vehicle
            local vehicle = action.ValidRoot;

            if not table.find(tried, vehicle) and workspace.VehicleSpawns:FindFirstChild(vehicle.Name) then
                if not dependencies.unsupported_vehicles[vehicle.Name] and (dependencies.modules.store._state.garageOwned.Vehicles[vehicle.Name] or dependencies.free_vehicles[vehicle.Name]) and not vehicle.Seat.Player.Value then -- check if the vehicle is supported, owned and not already occupied
                    if not workspace:Raycast(vehicle.Seat.Position, dependencies.variables.up_vector, dependencies.variables.raycast_params) then
                        local magnitude = (vehicle.Seat.Position - player.Character.HumanoidRootPart.Position).Magnitude;

                        if action.ValidRoot.Name == "Heli" then -- Adding priority to heli`s due hes speed
                            magnitude = magnitude - dependencies.variables.heli_priority
                        end

                        if magnitude < distance then 
                            distance = magnitude;
                            nearest = action;
                        end;
                    end;
                end;
            end;
        end;
    end;

    for Index, Spawner in ipairs(game:GetService("Workspace"):GetChildren()) do
        if Spawner.Name == "AerialSpawn" and Spawner:FindFirstChild("Prompt") ~= nil and spawned ~= "dont need, heli are near" and nearest.Name ~= "Heli" then
            local Magnitude = (Spawner.Prompt.Position - player.Character.HumanoidRootPart.Position).Magnitude

            if Magnitude - dependencies.variables.heli_priority < distance then
                nearest = Spawner
            end
        end
    end

    if nearest.Name == "AerialSpawn" then
        movement:move_to_position(player.Character.HumanoidRootPart, nearest.Prompt.CFrame, dependencies.variables.player_speed);

        wait(.1)

        dependencies.variables.stopVelocity = true

        player.Character.HumanoidRootPart.CFrame = nearest.Prompt.CFrame + Vector3.new(0, 5, 0)

        wait(.1)

        if game:GetService("Players").LocalPlayer.Team == game:GetService("Teams").Prisoner and not workspace:Raycast(player.Character.HumanoidRootPart.Position, dependencies.variables.up_vector, dependencies.variables.raycast_params) then
            player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 50000, 0)
            
            atts = 0
            repeat
                atts = atts + 1
                wait(.1)
            until game:GetService("Players").LocalPlayer.Team ~= game:GetService("Teams").Prisoner or atts > 60

            if atts > 60 then
                dependencies.variables.stopVelocity = false
                return utilities:get_nearest_vehicle(tried or {}, "dont need, heli are near")
            end

            wait(.2)
        end

        player.Character.HumanoidRootPart.CFrame = nearest.Prompt.CFrame + Vector3.new(0, 5, 0)

        for Index = 1,10 do
            nearest.Prompt.OnPressedRemote:FireServer(true)
            task.wait(0.01)
        end

        wait(.5)

        game:GetService("ReplicatedStorage"):WaitForChild("GarageSpawnVehicle"):FireServer("Heli", "Heli")
        game:GetService("ReplicatedStorage"):WaitForChild("GarageSetUIOpen"):FireServer(false)

        wait(1)

        dependencies.variables.stopVelocity = false

        return utilities:get_nearest_vehicle(tried or {}, "dont need, heli are near")
    end

    if distance > 500 and game:GetService("Players").LocalPlayer.Team ~= game:GetService("Teams").Prisoner and spawned == nil then
        game:GetService("ReplicatedStorage"):WaitForChild("GarageSpawnVehicle"):FireServer("Chassis", "Camaro")
        wait(2)

        if game:GetService("Players").LocalPlayer.Character.Humanoid.Sit == true then -- Spawned successfully
            for Index, Vehicle in ipairs(Workspace.Vehicles:GetChildren()) do
                if Vehicle.Seat.PlayerName.Value == game:GetService("Players").LocalPlayer.Name then
                    return {
                        ["ValidRoot"] = Vehicle,
                        ["Callback"] = function(bool)
                            dependencies.modules.character_util.OnJump(); -- something fucking wrong
                        end
                    }
                end
            end
        end
    end

    dependencies.variables.stopVelocity = false

    return nearest;
end;

--// function to pathfind to a position with no collision above

function movement:pathfind(tried)
    local distance = math.huge;
    local nearest;

    local tried = tried or { };
    
    for index, value in next, dependencies.door_positions do -- find the nearest position in our list of positions without collision above
        if not table.find(tried, value) then
            local magnitude = (value.position - player.Character.HumanoidRootPart.Position).Magnitude;
            
            if magnitude < distance then 
                distance = magnitude;
                nearest = value;
            end;
        end;
    end;

    table.insert(tried, nearest);

    utilities:toggle_door_collision(nearest.instance, false);

    local path = dependencies.variables.path;
    path:ComputeAsync(player.Character.HumanoidRootPart.Position, nearest.position);

    if path.Status == Enum.PathStatus.Success then -- if path making is successful
        local waypoints = path:GetWaypoints();

        for index = 1, #waypoints do 
            local waypoint = waypoints[index];
            
            player.Character.HumanoidRootPart.CFrame = CFrame.new(waypoint.Position + Vector3.new(0, 2.5, 0)); -- walking movement is less optimal

            if not workspace:Raycast(player.Character.HumanoidRootPart.Position, dependencies.variables.up_vector, dependencies.variables.raycast_params) then -- if there is nothing above the player
                utilities:toggle_door_collision(nearest.instance, true);

                return;
            end

            task.wait(0.05);
        end;
    end;

    utilities:toggle_door_collision(nearest.instance, true);

    movement:pathfind(tried);
end;

--// function to interpolate characters position to a position

function movement:move_to_position(part, cframe, speed, car, target_vehicle, tried_vehicles)
    local vector_position = cframe.Position;
    
    if not car and workspace:Raycast(part.Position, dependencies.variables.up_vector, dependencies.variables.raycast_params) then -- if there is an object above us, use pathfind function to get to a position with no collision above
        movement:pathfind();
        task.wait(0.5);
    end;
    
    local y_level = 1500;
    local higher_position = Vector3.new(vector_position.X, y_level, vector_position.Z); -- 1500 studs above target position

    repeat -- use velocity to move towards the target position
        local velocity_unit = (higher_position - part.Position).Unit * speed;
        part.Velocity = Vector3.new(velocity_unit.X, 0, velocity_unit.Z);

        task.wait();

        part.CFrame = CFrame.new(part.CFrame.X, y_level, part.CFrame.Z);

        if target_vehicle and target_vehicle.Seat.Player.Value then -- if someone occupies the vehicle while we're moving to it, we need to move to the next vehicle
            table.insert(tried_vehicles, target_vehicle);

            local nearest_vehicle = utilities:get_nearest_vehicle(tried_vehicles, "Skipping spawn due to we in air");
            local vehicle_object = nearest_vehicle and nearest_vehicle.ValidRoot;

            if vehicle_object then 
                movement:move_to_position(player.Character.HumanoidRootPart, vehicle_object.Seat.CFrame, 135, false, vehicle_object);
            end;

            return;
        end;
    until (part.Position - higher_position).Magnitude < 20;

    part.CFrame = CFrame.new(part.Position.X, vector_position.Y, part.Position.Z);
    part.Velocity = Vector3.zero;
end;

--// raycast filter

dependencies.variables.raycast_params.FilterType = Enum.RaycastFilterType.Blacklist;
dependencies.variables.raycast_params.FilterDescendantsInstances = { player.Character, workspace.Vehicles, workspace:FindFirstChild("Rain")};

workspace.ChildAdded:Connect(function(child) -- if it starts raining, add rain to collision ignore list
    if child.Name == "Rain" then 
        table.insert(dependencies.variables.raycast_params.FilterDescendantsInstances, child);
    end;
end);

player.CharacterAdded:Connect(function(character) -- when the player respawns, add character back to collision ignore list
    table.insert(dependencies.variables.raycast_params.FilterDescendantsInstances, character);
end);

for _, Object in ipairs(Workspace:GetChildren()) do
    if Object:IsA("MeshPart") and Object.Name == "MeshPart" and Object:FindFirstChild("TopDecal") ~= nil and Object.Color == Color3.fromRGB(159, 222, 249) then
        Object:Remove()
    end
end

--// get free vehicles, owned helicopters, motorcycles and unsupported/new vehicles

for index, vehicle_data in next, dependencies.modules.vehicle_data do
    if vehicle_data.Type == "Heli" then -- helicopters
        dependencies.helicopters[vehicle_data.Make] = true;
    elseif vehicle_data.Type == "Motorcycle" then --- motorcycles
        dependencies.motorcycles[vehicle_data.Make] = true;
    end;

    if vehicle_data.Type ~= "Chassis" and vehicle_data.Type ~= "Motorcycle" and vehicle_data.Type ~= "Heli" and vehicle_data.Type ~= "DuneBuggy" and vehicle_data.Make ~= "Volt" then -- weird vehicles that are not supported
        dependencies.unsupported_vehicles[vehicle_data.Make] = true;
    end;
    
    if not vehicle_data.Price then -- free vehicles
        dependencies.free_vehicles[vehicle_data.Make] = true;
    end;
end;

--// get all positions near a door which have no collision above them

for index, value in next, workspace:GetDescendants() do
    if value.Name:sub(-4, -1) == "Door" then 
        local touch_part = value:FindFirstChild("Touch");

        if touch_part and touch_part:IsA("BasePart") then
            for distance = 5, 100, 5 do 
                local forward_position, backward_position = touch_part.Position + touch_part.CFrame.LookVector * (distance + 3), touch_part.Position + touch_part.CFrame.LookVector * -(distance + 3); -- distance + 3 studs forward and backward from the door
                
                if not workspace:Raycast(forward_position, dependencies.variables.up_vector, dependencies.variables.raycast_params) then -- if there is nothing above the forward position from the door
                    table.insert(dependencies.door_positions, { instance = value, position = forward_position });

                    break;
                elseif not workspace:Raycast(backward_position, dependencies.variables.up_vector, dependencies.variables.raycast_params) then -- if there is nothing above the backward position from the door
                    table.insert(dependencies.door_positions, { instance = value, position = backward_position });

                    break;
                end;
            end;
        end;
    end;
end;

--// no fall damage or ragdoll 

local old_is_point_in_tag = dependencies.modules.player_utils.isPointInTag;
dependencies.modules.player_utils.isPointInTag = function(point, tag)
    if dependencies.variables.teleporting and tag == "NoRagdoll" or tag == "NoFallDamage" then
        return true;
    end;
    
    return old_is_point_in_tag(point, tag);
end;

--// anti skydive

local oldIsFlying = dependencies.modules.paraglide.IsFlying
dependencies.modules.paraglide.IsFlying = function(...)
    if dependencies.variables.teleporting and getinfo(2, "s").source:find("Falling") then
        return true
    end
    
    return oldIsFlying(...)
end

--// stop velocity

task.spawn(function()
    while task.wait() do
        if dependencies.variables.stopVelocity and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.Velocity = Vector3.zero;
        end;
    end;
end);

--// main teleport function (not returning a new function directly because of recursion)

local function teleport(cframe, tried) -- unoptimized
    local relative_position = (cframe.Position - player.Character.HumanoidRootPart.Position);
    local target_distance = relative_position.Magnitude;

    if target_distance <= 20 and not workspace:Raycast(player.Character.HumanoidRootPart.Position, relative_position.Unit * target_distance, dependencies.variables.raycast_params) then 
        player.Character.HumanoidRootPart.CFrame = cframe; 
        
        return;
    end; 

    dependencies.variables.teleporting = true;
    dependencies.heli_priority = target_distance / 10;

    local tried = tried or { };
    local nearest_vehicle = utilities:get_nearest_vehicle(tried);
    local vehicle_object = nearest_vehicle and nearest_vehicle.ValidRoot;

    if vehicle_object then 
        local vehicle_distance = (vehicle_object.Seat.Position - player.Character.HumanoidRootPart.Position).Magnitude;

        if target_distance < vehicle_distance then -- if target position is closer than the nearest vehicle
            movement:move_to_position(player.Character.HumanoidRootPart, cframe, dependencies.variables.player_speed);
        else 
            if vehicle_object.Seat.PlayerName.Value ~= player.Name then
                movement:move_to_position(player.Character.HumanoidRootPart, vehicle_object.Seat.CFrame, dependencies.variables.player_speed, false, vehicle_object, tried);

                dependencies.variables.stopVelocity = true;

                local enter_attempts = 1;

                repeat -- attempt to enter car
                    if nearest_vehicle.Name == "Hijack" then -- hijacking vehicle if needed
                        nearest_vehicle:Callback(true)

                        for index, action in next, dependencies.modules.ui.CircleAction.Specs do
                            if action.ValidRoot == vehicle_object and action.Name == "Enter Driver" then
                                nearest_vehicle = action
                            end
                        end
                    end

                    nearest_vehicle:Callback(true)
                    
                    enter_attempts = enter_attempts + 1;

                    task.wait(0.1);
                until enter_attempts == 10 or vehicle_object.Seat.PlayerName.Value == player.Name;

                dependencies.variables.stopVelocity = false;

                if vehicle_object.Seat.PlayerName.Value ~= player.Name then -- if it failed to enter, try a new car
                    table.insert(tried, vehicle_object);

                    return teleport(cframe, tried or { vehicle_object });
                end;
            end;

            if vehicle_object.Name == "Heli" then -- cuz ts too fast
                wait(.2)
                movement:move_to_position(vehicle_object.Engine, cframe, dependencies.variables.heli_speed, true);
                wait(.2)
            else
                movement:move_to_position(vehicle_object.Engine, cframe, dependencies.variables.vehicle_speed, true);
            end

            repeat -- attempt to exit car
                task.wait(0.15);
                dependencies.modules.character_util.OnJump();
            until vehicle_object.Seat.PlayerName.Value ~= player.Name;
        end;
    else
        movement:move_to_position(player.Character.HumanoidRootPart, cframe, dependencies.variables.player_speed);
    end;

    task.wait(0.5);
    dependencies.variables.teleporting = false;
end;

return teleport