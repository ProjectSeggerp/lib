local insert, find, remove = table.insert, table.find, table.remove

local Vector, rgb = Vector2.new, Color3.fromRGB
local workspace = workspace

local RunService = game:GetService'RunService'
local HttpService = game:GetService'HttpService'
local Players = game:GetService'Players'

local CurrentCamera = workspace.CurrentCamera
local ViewportSize = CurrentCamera.ViewportSize

local function TransformVector(_, f)
	return Vector(f(_.X), f(_.Y))
end

local Library = {
	Drawables = {};
	Sizes = nil;
	Mouse = nil;
	PositionReference = ViewportSize / 2
}

Library.Sizes = {
	Window = Vector(
		600,
		400
	);
}

Library.PositionReference -= TransformVector(Library.Sizes.Window / 2, math.floor)

local _ = Library.Sizes

_.OutsiderOutlineThickness = 2

_.WindowBodyLineThickness = 3

_.WindowTitleSquare = Vector(
	Library.Sizes.Window.X,
	35
)

_.BorderOffset = 4

_.TabButton = Vector(
	20,
	20
)

_.TablistOffset = 3

_.Body = Vector(
	_.Window.X - (_.TabButton.X + _.TablistOffset * 2 + _.BorderOffset),
	_.Window.Y - (_.WindowTitleSquare.Y + _.WindowBodyLineThickness)
)



local Theme = {
	Accent = rgb(255, 120, 158);
	Text = {
		Default = rgb(216, 222, 233);
		Disabled = rgb(96, 122, 122);
		Outline = rgb(14, 14, 14);
	};
	Background = {
		Dark = rgb(46, 52, 64);
		PartlyDark = rgb(59, 66, 82);
		PartlyLight = rgb(67, 76, 94);
		Light = rgb(76, 86, 106);
	};
	Font = Drawing.Fonts.Plex;
}

loadstring(game:HttpGet'https://github.com/PysephWasntAvailable/DrawingElement/blob/main/Source/Loader.lua', '@AnomicX-libdraw')()

local libdraw = DrawingElement.new

-- baxo's
local function switch(toCompare)
	return function(possible)
		local _ = possible[toCompare]
			if _ then
			return _(toCompare)
		end

		local _ = possible['default']
		if _ then
			return _(toCompare)
		end
	end
end

local ZIndex = {
	UIShadow = 1;
	UIFrameBackground = 100;
	UIFrameRing = 101;
	UITitleSquare = 102;


	MousePointer = 2 ^ 31 - 1;
}



function Library:CreateWindow(WindowName)
	local IWindow = {
		Name = WindowName;
		Visible = false;
		Drawables = {};
	}

	local Window = setmetatable(
		{},
		{
			__index = IWindow;
			__newindex = function(...)
				local Window, Index, Value = unpack{
					IWindow,
					select(2, ...)
				}
				rawset(Window, Index, Value)
				return switch(Index) {
					Visible = function()
						-- implement
					end
				}
			end
		}
	)

	Window.Drawables.PrimaryWindowRing = libdraw'Square'
	Window.Drawables.PrimaryWindowRing.Filled = false

	Window.Drawables.PrimaryWindowRing.Color = Theme.Background.Dark
	Window.Drawables.PrimaryWindowRing.Thickness = Library.Sizes.OutsiderOutlineThickness
	Window.Drawables.PrimaryWindowRing.Position = Vector(
		Library.PositionReference.X,
		Library.PositionReference.Y + Library.Sizes.WindowTitleSquare.Y + Library.Sizes.WindowBodyLineThickness
	)
	Window.Drawables.PrimaryWindowRing.Size = Vector(
		Library.Sizes.Window.X,
		Library.Sizes.Window.Y - (Library.Sizes.WindowTitleSquare.Y + Library.Sizes.WindowBodyLineThickness)
	)
	Window.Drawables.PrimaryWindowRing.ZIndex = ZIndex.UIFrameRing

	Window.Drawables.TitleSquare = libdraw'Square'
	Window.Drawables.TitleSquare.Filled = true

	Window.Drawables.TitleSquare.Color = Theme.Background.Dark
	Window.Drawables.TitleSquare.Position = Library.PositionReference
	Window.Drawables.TitleSquare.Size = Library.Sizes.WindowTitleSquare

	Window.Drawables.WindowBodyLine = libdraw'Line'

	Window.Drawables.WindowBodyLine.Color = Theme.Accent
	Window.Drawables.WindowBodyLine.Thickness = Library.Sizes.WindowBodyLineThickness
	local BaseYValue = Library.PositionReference.Y + Library.Sizes.WindowTitleSquare.Y
	Window.Drawables.WindowBodyLine.From = Vector(
		Library.PositionReference.X,
		BaseYValue
	)
	Window.Drawables.WindowBodyLine.To = Vector(
		Library.PositionReference.X + Library.Sizes.Window.X,
		BaseYValue
	)

	Window.Drawables.WindowTitle = libdraw'Text'

	Window.Drawables.WindowTitle.Text = Window.Name
	Window.Drawables.WindowTitle.Color = Theme.Text.Default
	Window.Drawables.WindowTitle.Font = Theme.Font;
	Window.Drawables.WindowTitle.Size = 13

	Window.Drawables.WindowTitle.Position = Vector(
		Window.Drawables.TitleSquare.Position.X + Library.Sizes.BorderOffset,
		Window.Drawables.TitleSquare.Position.Y / 2
	)

	Window.Drawables.PrimaryWindowRing.Visible = true
	Window.Drawables.TitleSquare.Visible = true
	Window.Drawables.WindowBodyLine.Visible = true
	Window.Drawables.WindowTitle.Visible = true

	return Window
end


return Library