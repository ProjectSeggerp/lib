local insert, find, remove = table.insert, table.find, table.remove

local Vector, rgb = Vector2.new, Color3.fromRGB
local workspace = workspace

local RunService = game:GetService'RunService'
local HttpService = game:GetService'HttpService'
local TextService = game:GetService('TextService')
local Players = game:GetService'Players'

local CurrentCamera = workspace.CurrentCamera
local ViewportSize = CurrentCamera.ViewportSize

local function TransformVector(_, f)
	return Vector(f(_.X), f(_.Y))
end

local Library = {
	Sizes = nil;
	PositionReference = Vector();--TransformVector(ViewportSize / 2, math.floor);
}

Library.Sizes = {
	Window = ViewportSize;
	--[[
		Vector(
			800,
			600
		);
	]]
}

--Library.PositionReference -= Library.Sizes.Window / 2

local _ = Library.Sizes

_.OutsiderOutlineThickness = 1

_.WindowBodyLineThickness = 3

_.WindowTitleSquare = Vector(
	Library.Sizes.Window.X,
	35
)

_.BorderOffset = 4

_.TabButton = Vector(
	200,
	36
)

_.TablistOffset = 3

_.ComponentSeparation = 3

_.Body = Vector(
	_.Window.X,
	_.Window.Y - (_.WindowTitleSquare.Y + _.WindowBodyLineThickness)
)

_.TabsBackground = Vector(
	_.TabButton.X + _.TablistOffset * 2,
	_.Body.Y - _.BorderOffset * 2
)

_.Column = Vector(
	_.Body.X - _.BorderOffset * 4 - (_.TablistOffset * 2 + _.TabButton.X),
	_.Body.Y - _.BorderOffset * 2
) / 2


local Theme = {
	Accent = rgb(255, 120, 158); -- rgb(36, 196, 101) possibly?
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
	TextSize = 13;
}

local libdraw = import'libdraw'

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

local function tcpy(t)
	local _ = {}
	for Index, Value in next, t do
		_[Index] = Value
	end

	return _
end

local ZIndex = {
	UIShadow = 1;
	UIFrameBackground = 100;
	UIFrameRing = 101;
	UITitleSquare = 102;
	UITitleLabel = 103;
	BodyDelimiter = 103;

	TabsBackground = 104;
	TabBackground = 105;
	TabTitle = 106;

	SectorBackground = 104;
	SectorOutlines = 103;
	SectorTitle = 105;


	MousePointer = 2 ^ 31 - 1;
}

local function CalculateTextBounds(Text, Size, Font)
	local _ = libdraw'Text'
	_.Text = Text
	_.Size = Size or Theme.TextSize
	_.Font = Font or Theme.Font

	local TextBounds = _.TextBounds

	_:Remove()
	_ = nil

	return TextBounds
end

local function TransformText(Text, ContainerBounds)
	local String = Text.Text

	Text.Size = Text.Size > ContainerBounds.Y and ContainerBounds.Y or Text.Size

	local TextAcummulator

	local ctr = 0

	while ctr <= #String do
		ctr += 1

		local SubString = String:sub(1, ctr)

		local TextBounds = CalculateTextBounds(SubString, Text.Size, Text.Font)

		if TextBounds.X > ContainerBounds.X then
			break
		else
			TextAcummulator = SubString
		end
	end

	return TextAcummulator:sub(1, -3) .. '...' or ''
end

function Library:CreateWindow(WindowName)
	local Window, IWindow
	local ISizes = tcpy(Library.Sizes)
	ISizes.Window = nil
	IWindow = {
		Name = WindowName;
		Visible = false;
		Drawables = {};
		Tabs = {};
		Size = Library.Sizes.Window;
		Sizes = setmetatable(
			{},
			{
				__index = ISizes;
				__newindex = function(...)
					Window:Render()
					return rawset(ISizes, select(2, ...))
				end
			}
		);
		Position = Library.PositionReference;
		Edges = {

		}
	}

	Window = setmetatable(
		{},
		{
			__index = IWindow;
			__newindex = function(...)
				local _, Index, Value = ...
				rawset(IWindow, Index, Value)
				return switch(Index) {
					Visible = function()
						Window.Drawables.PrimaryWindowRing.Visible = Value
						Window.Drawables.TitleSquare.Visible = Value
						Window.Drawables.WindowBodyLine.Visible = Value
						Window.Drawables.WindowTitle.Visible = Value
						Window.Drawables.BodyBackground.Visible = Value
						Window.Drawables.TabsBackground.Visible = Value
						for _, Tab in next, Window.Tabs do
							Tab.Visible = Value
						end
					end;
					Size = function()
						Window.Sizes.Body = Vector(
							Window.Size.X,
							Window.Size.Y - (Window.Sizes.WindowTitleSquare.Y + Window.Sizes.WindowBodyLineThickness)
						)

						Window.Sizes.WindowTitleSquare = Vector(
							Window.Size.X,
							35
						)

						Window.Sizes.TabsBackground = Vector(
							Window.Sizes.TabButton.X + Window.Sizes.TablistOffset * 2,
							Window.Sizes.Body.Y - Window.Sizes.BorderOffset * 2
						)

						Window:Render()
					end;
					Position = function()
						Window:Render()
					end;
					Name = function()
						Window.Drawables.WindowTitle.Text = Value
						TransformText(
							Window.Drawables.WindowTitle,
							Vector(
								Window.Drawables.TitleSquare.Size.X - Window.Sizes.BorderOffset,
								Window.Drawables.TitleSquare.Size.Y
							)
						)
					end
				}
			end
		}
	)

	Window.Drawables.PrimaryWindowRing = libdraw'Square'
	Window.Drawables.TitleSquare = libdraw'Square'
	Window.Drawables.WindowBodyLine = libdraw'Line'
	Window.Drawables.WindowTitle = libdraw'Text'
	Window.Drawables.BodyBackground = libdraw'Square'
	Window.Drawables.TabsBackground = libdraw'Square'

	workspace.CurrentCamera:GetPropertyChangedSignal'ViewportSize':Connect(function(_)
		Window.Size = _
	end)

	function Window:Render()
		Window.Drawables.PrimaryWindowRing.Filled = false

		Window.Drawables.PrimaryWindowRing.Color = Theme.Background.Dark
		Window.Drawables.PrimaryWindowRing.Thickness = Window.Sizes.OutsiderOutlineThickness
		Window.Drawables.PrimaryWindowRing.Position = Vector(
			Window.Position.X,
			Window.Position.Y + Window.Sizes.WindowTitleSquare.Y + Window.Sizes.WindowBodyLineThickness
		)
		Window.Drawables.PrimaryWindowRing.Size = Vector(
			Window.Size.X,
			Window.Size.Y - (Window.Sizes.WindowTitleSquare.Y + Window.Sizes.WindowBodyLineThickness)
		)
		Window.Drawables.PrimaryWindowRing.ZIndex = ZIndex.UIFrameRing

		Window.Drawables.TitleSquare.Filled = true

		Window.Drawables.TitleSquare.Color = Theme.Background.Dark
		Window.Drawables.TitleSquare.Position = Window.Position
		Window.Drawables.TitleSquare.Size = Window.Sizes.WindowTitleSquare
		Window.Drawables.TitleSquare.ZIndex = ZIndex.UITitleSquare

		Window.Drawables.WindowBodyLine.Color = Theme.Accent
		Window.Drawables.WindowBodyLine.Thickness = Window.Sizes.WindowBodyLineThickness + 1
		local BaseYValue = Window.Position.Y + Window.Sizes.WindowTitleSquare.Y
		Window.Drawables.WindowBodyLine.From = Vector(
			Window.Position.X,
			BaseYValue
		)
		Window.Drawables.WindowBodyLine.To = Vector(
			Window.Position.X + Window.Size.X,
			BaseYValue
		)
		Window.Drawables.WindowBodyLine.ZIndex = ZIndex.BodyDelimiter

		Window.Name = Window.Name
		Window.Drawables.WindowTitle.Color = Theme.Text.Default
		Window.Drawables.WindowTitle.Font = Theme.Font;
		Window.Drawables.WindowTitle.Size = Theme.TextSize
		Window.Drawables.WindowTitle.ZIndex = ZIndex.UITitleLabel

		Window.Drawables.WindowTitle.Position = Vector(
			Window.Drawables.TitleSquare.Position.X + Window.Sizes.BorderOffset,
			Window.Drawables.TitleSquare.Position.Y + Window.Drawables.TitleSquare.Size.Y / 2
		)

		Window.Drawables.WindowTitle.Position -= Vector(
			0,
			Window.Drawables.WindowTitle.TextBounds.Y / 2
		)

		Window.Drawables.BodyBackground.Filled = true

		Window.Drawables.BodyBackground.Color = Theme.Background.PartlyDark
		Window.Drawables.BodyBackground.Position = Vector(
			Window.Position.X,
			Window.Position.Y + Window.Sizes.WindowTitleSquare.Y + Window.Sizes.WindowBodyLineThickness
		)
		Window.Drawables.BodyBackground.Size = Window.Sizes.Body
		Window.Drawables.BodyBackground.ZIndex = ZIndex.UIFrameBackground

		Window.Drawables.TabsBackground.Filled = true

		Window.Drawables.TabsBackground.Color = Theme.Background.PartlyLight
		Window.Drawables.TabsBackground.Position = Vector(
			Window.Drawables.BodyBackground.Position.X,
			Window.Drawables.BodyBackground.Position.Y
		)
		Window.Drawables.TabsBackground.Size = Window.Sizes.TabsBackground
		Window.Drawables.TabsBackground.ZIndex = ZIndex.TabsBackground

		Window.ColumnPositionReference = Vector(
			Window.Drawables.TabsBackground.Position.X + Window.Drawables.TabsBackground.Size.X,
			Window.Drawables.TabsBackground.Position.Y
		)

		for _, Tab in next, Window.Tabs do
			Tab:Render()
		end

		return Window
	end

	function Window:CreateTab(Title, Description)
		local Tab, ITab
		ITab = {
			Title = Title;
			Description = Description;
			Selected = false;
			Visible = false;
			Drawables = {};
			Columns = {};
			ColumnSize = Vector(
				Window.AvaiableColumnSpace.X - Window.Sizes.BorderOffset * 2,
				Window.AvaiableColumnSpace.Y
			);
			Index = nil;
		}

		Tab = setmetatable(
			{},
			{
				__index = ITab;
				__newindex = function(...)
					local _, Index, Value = ...
					ITab[Index] = Value

					return switch(Index) {
						Selected = function()
							Tab.Drawables.Title.Color = Value and Theme.Text.Default or Theme.Text.Disabled
							Tab.Drawables.Background.Color = Value and Theme.Background.PartlyDark or Theme.Background.Dark
							for _, Column in next, Tab.Columns do
								Column.Visible = Value
							end
						end;
						Visible = function()
							Tab.Drawables.Background.Visible = Value
							Tab.Drawables.Title.Visible = Value
						end
					}
				end
			}
		)

		Tab.Drawables.Background = libdraw'Square'
		Tab.Drawables.Title = libdraw'Text'

		function Tab:CalculateColumnBounds()

		end

		function Tab:Render()
			Tab.Drawables.Background.Color = Theme.Background.Dark
			Tab.Drawables.Background.Filled = true
			Tab.Drawables.Background.Position = Vector(
				Window.Drawables.TabsBackground.Position.X + Window.Sizes.TablistOffset,
				Window.Drawables.TabsBackground.Position.Y + (Window.Sizes.TabButton.Y + Window.Sizes.TablistOffset) * Tab.Index
			)
			Tab.Drawables.Background.Size = Window.Sizes.TabButton
			Tab.Drawables.Background.ZIndex = ZIndex.TabBackground

			Tab.Drawables.Title.Text = Tab.Title
			Tab.Drawables.Title.Color = Tab.Selected and Theme.Text.Default or Theme.Text.Disabled
			Tab.Drawables.Title.Center = true
			Tab.Drawables.Title.Position = Tab.Drawables.Background.Position + Tab.Drawables.Background.Size / 2
			Tab.Drawables.Title.ZIndex = ZIndex.TabTitle

			local _ = Vector(
				Window.Sizes.Body.X - (Window.Sizes.TabsBackground.X + Window.Sizes.BorderOffset * ((#Tab.Columns - 1) + 2)),
				Window.Sizes.Body.Y - Window.Sizes.BorderOffset * 2
			)

			Tab.ColumnSize = _ / Vector(#Tab.Columns, 1)

			for Index = 1, #Tab.Columns do
				Tab.Columns[Index]:Render()
			end

			return Tab
		end


		function Tab:CreateColumn()
			local Column, IColumn
			IColumn = {
				Visible = false;
				Sectors = {};
				PositionReference = Vector();
			}
			Column = setmetatable(
				{},
				{
					__index = IColumn;
					__newindex = function(...)
						local _, Index, Value = ...
						rawset(IColumn, Index, Value)
						return switch(Index) {
							Visible = function()
								for _, Sector in next, Column.Sectors do
									Sector.Visible = Value
								end
							end
						}
					end
				}
			)

			function Column:CreateSector(Name)
				local Sector, ISector
				ISector = {
					Components = {};
					Drawables = {};
					Visible = false;
				}
				Sector = setmetatable(
					{},
					{
						__index = function(_, Index)
							return switch(Index) {
								Size = function()
									return ISector.Drawables.Background.Size
								end;
								default = function()
									return ISector[Index]
								end
							}
						end;
						__newindex = function(...)
							local _, Index, Value = ...
							rawset(ISector, Index, Value)
							return switch(Index) {
								Visible = function()
									Sector.Drawables.Background.Visible = Value
									Sector.Drawables.Label.Visible = Value
									for _, Component in next, ISector.Components do
										Component.Visible = Value
									end
								end
							}
						end
					}
				)

				Sector.Drawables.Background = libdraw'Square'
				Sector.Drawables.Label = libdraw'Text'


				function Sector:Render()
					Sector.Drawables.Background.Position = Sector.PositionReference
					Sector.Drawables.Background.Color = Theme.Background.Dark
					Sector.Drawables.Background.Size = Vector(
						Tab.ColumnSize.X,
						2 * Window.Sizes.BorderOffset
					)

					for Index = 1, #Sector.Components do
						Sector.Drawables.Background.Size += Vector(0, Sector.Components[Index].Bounds.Y)
					end

					Sector.Drawables.Background.ZIndex = ZIndex.SectorBackground

					Sector.Drawables.Label.Text = Name
					Sector.Drawables.Label.Center = true
					Sector.Drawables.Label.Position = Vector(Sector.Drawables.Background.Position.X + Sector.Drawables.Background.Size.X / 2, Sector.Drawables.Background.Position.Y)
					Sector.Drawables.Label.ZIndex = ZIndex.SectorTitle
					Sector.Drawables.Label.Color = Theme.Text.Default


					local ComponentPositionReference = Sector.PositionReference + Vector(
						Window.Sizes.BorderOffset,
						Window.Sizes.BorderOffset
					)

					for _, Component in next, Sector.Components do
						Component.PositionReference = ComponentPositionReference
						Component:Render()
						ComponentPositionReference += Vector(0, Component.Bounds.Y + Window.Sizes.ComponentSeparation)
					end

					return Sector
				end



				function Sector:GetArea()
					local Size = Vector(
						Window.Sizes.Column.X,
						2 * Window.Sizes.BorderOffset
					)

					for Index = 1, #Sector.Components do
						Size += Vector(0, Sector.Components[Index].Bounds.Y)
					end

					return Sector.Drawables.Background.Position, Sector.Drawables.Background.Position + Size
				end

				function Sector:CreateLabel(Text)
					local Label, ILabel
					ILabel = {
						Text = nil;
						Drawables = {};
						Visible = false;
					}
					Label = setmetatable(
						{},
						{
							__index = function(_, Index)
								return switch(Index) {
									Bounds = function()
										return Label.Drawables.Text.TextBounds
									end;
									default = function()
										return ILabel[Index]
									end
								}
							end;
							__newindex = function(...)
								local _, Index, Value = ...
								rawset(ILabel, Index, Value)
								return switch(Index) {
									Text = function()
										Label.Drawables.Text.Text = Value
										TransformText(Label.Drawables.Text, Tab.ColumnSize)
									end
								}
							end
						}
					)

					Label.Drawables.Text = libdraw'Text'

					function Label:Render()
						Label.Drawables.Text.Color = Theme.Text.Default
						Label.Drawables.Text.Position = Vector(
							Sector.LastComponent.Height
						)
						Label.Drawables.Text.Size = Theme.TextSize
						Label.Drawables.Text.Font = Theme.Font

						Label.Text = Text

						return Label
					end

					insert(ISector.Components, Label)

					Column:Render()

					return Label:Render()
				end

				insert(Column.Sectors, Sector)

				Column:Render()

				return Sector:Render()
			end

			function Column:Render()
				local SectorAllocationPosition = Column.PositionReference

				for Index = 1, #Column.Sectors do
					local Sector = Column.Sectors

					Sector.PositionReference = SectorAllocationPosition

					Sector:Render()

					SectorAllocationPosition += Vector(0, Sector.Size.Y + Window.Sizes.BorderOffset)
				end

				return Column
			end

			insert(Tab.Columns, Column)

			return Column:Render()
		end

		insert(Window.Tabs, Tab)

		Tab.Index = #Window.Tabs

		return Tab:Render()
	end

	return Window:Render()
end


return Library