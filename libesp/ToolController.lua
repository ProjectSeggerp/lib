local workspace, Draw, format, clamp, floor, Vector2 = workspace, Drawing.new, string.format, math.clamp, floor, Vector2

local spawn, foreach = task.spawn, table.foreach

local Camera = workspace.CurrentCamera or workspace:GetPropertyChangedSignal'CurrentCamera':Wait()

workspace:GetPropertyChangedSignal'CurrentCamera':Connect(
	function(_)
		Camera = _
	end
)

local RunService = game:GetService'RunService'

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
		ShowDistance = true
	};
	Enabled = false;
}


local function ToolAdded(Tool)
	local Object = {
		Name = Draw'Text';
		Box = Draw'Quad';
		Tracer = Draw'Line';
		_ = Tool;
	}

	local Name, Box, Tracer =	Object.Name,
								Object.Box,
								Object.Tracer;

	Name.Center = true
	-- // Adjust size based on view
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

	table.insert(Controller.Objects, Object)
end

local function ToolRemoving(Tool)
	local DrawingObjects
	for _, Object in next, Controller.Objects do
		if Object._ == Tool then
			DrawingObjects = Object
			break
		end
	end
	if DrawingObjects then
		for _, DrawingObject in next, DrawingObjects do
			DrawingObject:Remove()
		end
	end
end

local Drops = workspace:WaitForChild'Drops'

for _, Drop in next, Drops:GetChildren() do
	coroutine.wrap(ToolAdded)(Drop)
end

Drops.ChildAdded:Connect(ToolAdded)

Drops.ChildRemoved:Connect(ToolRemoving)


function Controller:UpdateOperation()
	local Settings = self.Settings
	--[[
		Tracers = true;
		Boxes = true;
		ShowDistance = true
	]]
	local Tracers, Boxes, ShowDistance =	Settings.Tracers,
											Settings.Boxes,
											Settings.ShowDistance;

	for _, DrawingObjects in next, Controller.Objects do
		--[[
			Name = Draw'Text';
			Box = Draw'Quad';
			Tracer = Draw'Line';
		]]
		local Tool = DrawingObjects._
		local ToolName = tostring(Tool)

		local Hitbox = Tool:FindFirstChild'hitbox'

		if Hitbox then
			local ScreenPosition, OnScreen = WorldToViewportPoint(Hitbox.Position)
			if OnScreen then
				local Name, Box, Tracer=	DrawingObjects.Name,
											DrawingObjects.Box,
											DrawingObjects.Tracer;

				
				local CoordinateFrame = Hitbox.CFrame
				local Position, RightVector, UpVector = CoordinateFrame.Position, CoordinateFrame.RightVector, CoordinateFrame.UpVector
				local DistanceCharacter = floor(DistanceFromCharacter(LocalPlayer, Position))
				local Distance = (Camera.CFrame.Position - Position).Magnitude

				local Text = (ShowDistance and ('[' .. DistanceCharacter .. '] ') or '') .. ToolName

				Name.Text = Text
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
					Box.Visible = true

					Box.PointA = Vector2.new(
						WorldToViewportPoint(
							Position + RightVector * -2 + UpVector * 2.5
						).X,
						WorldToViewportPoint(
							Position + RightVector * -2 + UpVector * 2.5
						).Y
					)

					Box.PointB = Vector2.new(
						WorldToViewportPoint(
							Position + RightVector * 2 + UpVector * 2.5
						).X,
						WorldToViewportPoint(
							Position + RightVector * 2 + UpVector * 2.5
						).Y
					)

					Box.PointC = Vector2.new(
						WorldToViewportPoint(
							Position + RightVector * 2 + UpVector * -2.5
						).X,
						WorldToViewportPoint(
							Position + RightVector * 2 + UpVector * -2.5
						).Y
					)

					Box.PointD = Vector2.new(
						WorldToViewportPoint(
							Position + RightVector * -2 + UpVector * -2.5
						).X,
						WorldToViewportPoint(
							Position + RightVector * -2 + UpVector * -2.5
						).Y
					)
				else
					Box.Visible = false
				end

				if Tracers then
					Tracer.Visible = true
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