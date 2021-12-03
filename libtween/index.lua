local libtween = newproxy(true)
local metatable = getmetatable(libtween)
local RunService = game:GetService('RunService')
local Heartbeat = RunService.Heartbeat
local Wait = Heartbeat.Wait
local func_container = {
	tweenSync = function(part, target, distPerTick)
		while Wait(Heartbeat) and (part.CFrame.Position - target.CFrame.Position).Magnitude < 1 do
			part.CFrame = CFrame.lookAt(target.CFrame:Lerp(part.CFrame, distPerTick).Position, target.CFrame.Position)
		end
	end;
	tween = function(part, target, distPerTick)
		local Returns = {
			Completed = Instance.new('BindableEvent').Event
		}
		local co = coroutine.create(function()
			while Wait(Heartbeat) and (part.CFrame.Position - target.CFrame.Position).Magnitude < 1 do
				part.CFrame = CFrame.lookAt(target.CFrame:Lerp(part.CFrame, distPerTick).Position, target.CFrame.Position)
			end
			Returns.Completed:Fire()
		end)
		coroutine.resume(co)
		return Returns
	end
}
function metatable.__index(self, index)
	return rawget(func_container, index)
end
function metatable.__namecall(self, ...)
	local func = rawget(func_container, getnamecallmethod())
	if func then
		return func(self, ...)
	else
		return error(string.format('this object has no field named %s', getnamecallmethod()), 2)
	end
end
metatable.__type = 'libtween'


return setmetatable(libtween, metatable)
