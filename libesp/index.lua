local HttpService = game:GetService'HttpService'
local RunService = game:GetService'RunService'
local workspace = workspace
local InstanceIdentifier = HttpService:GenerateGUID(false)

local Library = {
	Controllers = {};
	Enabled = true;
}

local function UpdateGlobal()
	for _, Controller in next, Library.Controllers do
		if Controller.Enabled then
			local Success, Error = pcall(Controller.UpdateOperation, Controller)
			if Success == false then
				warn('[' .. tostring(Controller) .. ']', Error)
			end
		end
	end
end

RunService:BindToRenderStep('_', Enum.RenderPriority.Camera.Value, UpdateGlobal)

return Library