local workspace, Draw, format, clamp, Vector2 = workspace, Drawing.new, string.format, math.clamp, Vector2
local floor = math.floor

local spawn, foreach = task.spawn, table.foreach

local Camera = workspace.CurrentCamera or workspace:GetPropertyChangedSignal'CurrentCamera':Wait()

workspace:GetPropertyChangedSignal'CurrentCamera':Connect(
	function(_)
		Camera = _
	end
)

local RunService = game:GetService('RunService')
local Teams = game:GetService('Teams')

local Players = game:GetService'Players'
local LocalPlayer = Players.LocalPlayer

local Colors = {}

local WorldToViewportPointFunction, WorldToScreenPoint = Camera.WorldToViewportPoint, Camera.WorldToScreenPoint
local DistanceFromCharacter = LocalPlayer.DistanceFromCharacter

local function WorldToViewportPoint(Position)
	return WorldToViewportPointFunction(Camera, Position)
end

local Controller = {
	Objects = {};
	Settings = {
		Tracers = false;
		Boxes = true;
		DisplayHealth = true;
		DisplayDistance = true
	};
	Enabled = false;
}

local GovernmentTeams = {
	Teams:WaitForChild'Sheriff';
	Teams:WaitForChild'Military';
	Teams:WaitForChild'Special Forces';
}
local ColorsMap = {
	Innocent = Color3.fromRGB(153, 153, 153);
	Warrant = Color3.fromRGB(255, 206, 82);
	Wanted = Color3.fromRGB(170, 0, 0);
	Government = Color3.fromRGB(38, 56, 124);
}
local function ResolveStatus(Value)
	if Value == 1 then
		return ColorsMap.Innocent
	elseif Value == 2 then
		return ColorsMap.Warrant
	elseif Value == 3 then
		return ColorsMap.Wanted
	else
		return ColorsMap.Innocent
	end
end

local function PlayerAdded(Player)

	if Player == LocalPlayer then return end

	local PlayerName = tostring(Player)

	Colors[PlayerName] = ColorsMap.Warrant

	local Object = {
		Name = Draw'Text';
		Box = Draw'Quad';
		Tracer = Draw'Line';
		_ = Player;
	}

	local Name, Box, Tracer =	Object.Name,
								Object.Box,
								Object.Tracer;

	Name.Center = true
	Name.Size = 19
	Name.Outline = true
	Name.OutlineColor = Color3.new()
	-- ### Fonts = {UI = 0, System = 1, Plex = 2, Monospace = 3}
	Name.Font = 0
	Name.Transparency = 1

	Box.Thickness = 1
	Box.Transparency = 1
	Box.Filled = false

	Tracer.Thickness = 0.3
	Tracer.Transparency = 1
	Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

	Controller.Objects[PlayerName] = Object

	local WantedStatus = Player.WantedStatus.WantedStatus

	local function UpdateColor()
		local Value = WantedStatus.Value
		if table.find(GovernmentTeams, Player.Team) then
			Colors[PlayerName] = ColorsMap.Government
		else
			Colors[PlayerName] = ResolveStatus(Value)
		end
		print('New color for player!:', Colors[PlayerName])
	end

	WantedStatus.Changed:Connect(UpdateColor)

	UpdateColor()
end

local function PlayerRemoving(Player)
	local Object = Controller.Objects[tostring(Player)]
	if Object then
		for _, DrawingObject in next, Object do
			DrawingObject:Remove()
		end
	end
end

for _, Player in next, Players:GetPlayers() do
	coroutine.wrap(PlayerAdded)(Player)
end

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(PlayerRemoving)


function Controller:UpdateOperation()
	local Settings = self.Settings
	--[[
		Tracers = true;
		Boxes = true;
		DisplayHealth = true;
		DisplayDistance = true
	]]
	local Tracers, Boxes, DisplayHealth, DisplayDistance =	Settings.Tracers,
														Settings.Boxes,
														Settings.DisplayHealth,
														Settings.DisplayDistance;

	for PlayerName, DrawingObjects in next, Controller.Objects do
		--[[
			Name = Draw'Text';
			Box = Draw'Quad';
			Tracer = Draw'Line';
		]]
		local Player = DrawingObjects._
		local Character = Player.Character

		if Character == nil then
			continue
		end

		local HumanoidRootPart = Character:FindFirstChild'HumanoidRootPart' or Character.PrimaryPart or Character:FindFirstChildWhichIsA'BasePart'
		local Humanoid = Character:FindFirstChildWhichIsA'Humanoid'

		if HumanoidRootPart and Humanoid then
			local ScreenPosition, OnScreen = WorldToViewportPoint(HumanoidRootPart.Position)
			if OnScreen then
				local Health, MaxHealth = Humanoid.Health, Humanoid.MaxHealth

				local Name, Box, Tracer=	DrawingObjects.Name,
											DrawingObjects.Box,
											DrawingObjects.Tracer;

				local CoordinateFrame = HumanoidRootPart.CFrame
				local Position, RightVector, UpVector = CoordinateFrame.Position, CoordinateFrame.RightVector, CoordinateFrame.UpVector

				local DistanceCharacter = floor(DistanceFromCharacter(LocalPlayer, Position))
				local Distance = (Camera.CFrame.Position - Position).Magnitude

				local Text = (DisplayDistance and ('[' .. DistanceCharacter .. '] ') or '') .. PlayerName .. ((DisplayHealth and MaxHealth == 100) and format(' [%.2f%%]', (Health / MaxHealth) * 100) or '')
				local Color = Colors[PlayerName]

				Name.Text = Text
				Name.Color = Color
				Name.Size = clamp(18 - Distance, 18, 86)
				Name.Position = Vector2.new(
					WorldToViewportPoint(
						Position + UpVector * (Distance / 25 + 3)
					).X,
					WorldToViewportPoint(
						Position + UpVector * (Distance / 40 + 3)
					).Y
				)
				Name.Visible = true

				if Boxes then
					Box.Color = Color
					Box.Visible = true

					local _ = WorldToViewportPoint(
						Position + RightVector * -2 + UpVector * 2.5
					)

					Box.PointA = Vector2.new(
						_.X,
						_.Y
					)

					_ = WorldToViewportPoint(
						Position + RightVector * 2 + UpVector * 2.5
					)

					Box.PointB = Vector2.new(
						_.X,
						_.Y
					)

					_ = WorldToViewportPoint(
						Position + RightVector * 2 + UpVector * -2.5
					)

					Box.PointC = Vector2.new(
						_.X,
						_.Y
					)

					_ = WorldToViewportPoint(
						Position + RightVector * -2 + UpVector * -2.5
					)

					Box.PointD = Vector2.new(
						_.X,
						_ .Y
					)
				else
					Box.Visible = false
				end

				if Tracers then
					Tracer.Visible = true
					Tracer.Color = Color
					Tracer.To = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
				else
					Tracer.Visible = false
				end
			else
				local Name, Box, Tracer=	DrawingObjects.Name,
											DrawingObjects.Box,
											DrawingObjects.Tracer;

				Name.Visible, Box.Visible, Tracer.Visible = false, false, false
			end
		else
			local Name, Box, Tracer=	DrawingObjects.Name,
											DrawingObjects.Box,
											DrawingObjects.Tracer;

			Name.Visible, Box.Visible, Tracer.Visible = false, false, false
		end


	end
end

return setmetatable(
	Controller,
	{
		__newindex = function(...)
			local self, idx, val = ...
			if idx == 'Enabled' then
				if val == false then
					rawset(...)
					RunService.RenderStepped:Wait()
					foreach(Controller.Objects, function(_, DrawingObjects)
						local Name, Box, Tracer=	DrawingObjects.Name,
											DrawingObjects.Box,
											DrawingObjects.Tracer;

						Name.Visible, Box.Visible, Tracer.Visible = false, false, false
					end)
				end
			else
				return rawset(...)
			end
		end;
		__tostring = 'PlayerController';
	}
)