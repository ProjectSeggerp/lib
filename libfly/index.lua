local RunService = game:GetService'RunService'
local Players = game:GetService('Players')
local UserInputService = game:GetService'UserInputService'
local Camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal'CurrentCamera':Connect(function(_)
	Camera = workspace.CurrentCamera
end)
local DefaultGameGravity = workspace.Gravity
local Controller = {
	CharacterController = nil;
	Enabled = false;
	Speed = 50;
}

local function CreateController(Character)
	local Humanoid = Character:FindFirstChildWhichIsA'Humanoid'

	local Model

	local CharacterController = {
		InputBeganConnecttion = nil;
		InputEndedConnection = nil;
		CameraUpdateConnection = nil;

		BreakAcknowlodgnement = Instance.new'BindableEvent';

		Disposed = false;

		Navigator = {
			Left = false;
			Right = false;
			Forward = false;
			Backward = false;
		};
	}

	local function UpdateVariables()
		if Humanoid.SeatPart then
			Model = Humanoid.SeatPart.Parent.Parent
		else
			Model = Character
		end

		CharacterController.Model = Model
	end

	Humanoid:GetPropertyChangedSignal'SeatPart':Connect(UpdateVariables)

	UpdateVariables()

	CharacterController.InputBeganConnection = UserInputService.InputBegan:Connect(function(InputObject, GameProcessedEvent)
		if GameProcessedEvent == false then
			if InputObject.UserInputType == Enum.UserInputType.Keyboard then
				if InputObject.KeyCode == Enum.KeyCode.W then
					CharacterController.Navigator.Forward = true
				elseif InputObject.KeyCode == Enum.KeyCode.S then
					CharacterController.Navigator.Backward = true
				elseif InputObject.KeyCode == Enum.KeyCode.A then
					CharacterController.Navigator.Left = true
				elseif InputObject.KeyCode == Enum.KeyCode.D then
					CharacterController.Navigator.Right = true
				end
			end
		end
	end)

	CharacterController.InputEndedConnection = UserInputService.InputEnded:Connect(function(InputObject, GameProcessedEvent)
		if GameProcessedEvent == false then
			if InputObject.UserInputType == Enum.UserInputType.Keyboard then
				if InputObject.KeyCode == Enum.KeyCode.W then
					CharacterController.Navigator.Forward = false
				elseif InputObject.KeyCode == Enum.KeyCode.S then
					CharacterController.Navigator.Backward = false
				elseif InputObject.KeyCode == Enum.KeyCode.A then
					CharacterController.Navigator.Left = false
				elseif InputObject.KeyCode == Enum.KeyCode.D then
					CharacterController.Navigator.Right = false
				end
			end
		end
	end)

	CharacterController.CameraUpdateConnection = Camera:GetPropertyChangedSignal'CFrame':Connect(function()
		if Controller.Enabled then
			local _ = Model.PrimaryPart.CFrame
			Model:SetPrimaryPartCFrame(
				CFrame.new(_.Position, _.Position + Camera.CFrame.LookVector)
			)
		end
	end)

	local function NavigatorLoop()
		while true do
			local Delta = RunService.RenderStepped:Wait()
			if CharacterController.Disposed then
				CharacterController.BreakAcknowlodgnement:Fire()
				break
			end
			if Controller.Enabled then
				local _ = Model.PrimaryPart.CFrame
				if CharacterController.Navigator.Forward then
					Model:SetPrimaryPartCFrame(
						_ + (Camera.CFrame.LookVector * (Delta * Controller.Speed))
					)
				end
				if CharacterController.Navigator.Backward then
					Model:SetPrimaryPartCFrame(
						_ + (-Camera.CFrame.LookVector * (Delta * Controller.Speed))
					)
				end
				if CharacterController.Navigator.Left then
					Model:SetPrimaryPartCFrame(
						_ + (-Camera.CFrame.RightVector * (Delta * Controller.Speed))
					)
				end
				if CharacterController.Navigator.Right then
					Model:SetPrimaryPartCFrame(
						_ + (Camera.CFrame.RightVector * (Delta * Controller.Speed))
					)
				end
			end
		end
	end

	task.spawn(NavigatorLoop)

	CharacterController.BreakAcknowlodgnement.Event:Connect(function()
		CharacterController.InputBeganConnection:Disconnect()
		CharacterController.InputEndedConnection:Disconnect()
		CharacterController.CameraUpdateConnection:Disconnect()
	end)

	function CharacterController:Dispose()
		self.Disposed = true
		self.BreakAcknowlodgnement.Event:Wait()
	end

	return CharacterController
end

local function HandleCharacter(Character)
	if Controller.CharacterController then
		Controller.CharacterController:Dispose()
	end

	local _ = CreateController(Character)

	Controller.CharacterController = _
end

Players.LocalPlayer.CharacterAdded:Connect(HandleCharacter)

if Players.LocalPlayer.Character then
	HandleCharacter(Players.LocalPlayer.Character)
end

local Proxy = setmetatable(
	{},
	{
		__index = Controller;
		__newindex = function(...)
			local self, Index, Value = ...
			rawset(Controller, select(2, ...))
			if Index == 'Enabled' then
				workspace.Gravity = Value and 0 or DefaultGameGravity
			end
		end
	}
)

Proxy.Enabled = true
