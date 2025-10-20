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

game:GetService("Workspace").Name = "Workspace"