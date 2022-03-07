local HttpService = game:GetService'HttpService'
local RunService = game:GetService'RunService'
local workspace = workspace
local InstanceIdentifier = HttpService:GenerateGUID(false):lower()

local IControllers = {}

local function CreateErrorHandler(Name)
	return function (Error)
		warn(string.format('[%s] %s', Name, debug.traceback(Error)))
	end
end

local Library = {
	Controllers = setmetatable(
		{},
		{
			__index = IControllers;
			__newindex = function(...)
				local Controllers, Index, Value = unpack{IControllers, select(2, ...)}
				if type(Value) == 'table' then
					Value.ErrorHandler = CreateErrorHandler(tostring(Index))
					IControllers[Index] = Value
				else
					error'Only tables are permitted.'
				end
			end
		}
	);
}



local function UpdateGlobal()
	for _, Controller in next, Library.Controllers do
		if Controller.Enabled then
			xpcall(Controller.UpdateOperation, Controller.ErrorHandler, Controller)
		end
	end
end

RunService:BindToRenderStep(InstanceIdentifier, Enum.RenderPriority.Camera.Value, UpdateGlobal)

return Library