local insert, find, remove = table.insert, table.find, table.remove

local Vector2, Color = Vector2.new, Color3.fromRGB

local GuiService = game:GetService'GuiService'
local HttpService = game:GetService'HttpService'
local UserInputService = game:GetService'UserInputService'
local Players = game:GetService'Players'
local ContextActionService = game:GetService'ContextActionService'


local function switch(toCompare)
	return function(possible)
		local _ = possible[toCompare]
		if _ then
			_(toCompare)
			return
		end

		local _ = possible.default
		if _ then
			_(toCompare)
		end
	end
end

local function fromHex(_)
	_ = _:gsub('#', '')
	local R, G, B = _:sub(1, 2), _:sub(3, 4), _:sub(5, 6)
	return Color(
		tonumber(('0x%s'):format(R)),
		tonumber(('0x%s'):format(G)),
		tonumber(('0x%s'):format(B))
	)
end

local Library = {}

local MaximumRenderPriority = 2147483647

local ZIndexes = {
	ComponentHolder = -1;
	ComponentHolderOutline = -1;
	ComponentElements = MaximumRenderPriority;
	ComponentBackground = MaximumRenderPriority - 1;
	ComponentOutline = MaximumRenderPriority - 1;
}

local Colors = {
	Background = fromHex'#2E3440';
	Outline = fromHex'#ECEFF4';
	InnerBackground = fromHex'#3B4252';
	Label = fromHex'#D8DEE9';
}

function Library:CreateWindow(Name)
	local Window, _Tabs
	_Tabs = {}
	Window = {
		Name = Name;
		InFocus = false;
		DetachedContainer = nil;
		Components = {};
		-- acount for 1 pixel outline
		ComponentWidth = 201;
		ComponentHeight = 31;
		SectorOffset = 5;
		Drawables = {};
		Tabs = setmetatable(
			{},
			{
				__index = _Tabs;
				__newindex = function(...)
					local Tabs, Index, Value = ...
					if _Tabs[Index] == nil then
						Window.TabAdded:Fire(Value)
						_Tabs[Index] = Value
					else
						return error'attempt to overwrite an existing tab.'
					end
				end
			}
		);

		-- Events
		TabAdded = Instance.new'BindableEvent'
	}

	local function Draw(Type, Properties)
		local Object = Drawing.new(Type)
		for Property, Value in next, Properties do
			Object[Property] = Value
		end

		insert(Window.Drawables, Object)

		return Object
	end

	local TabsBackgroundXOffset, TabsBackgroundYOffset = 5, 5

	local TitleSectorHeight = 21 -- acount for intermediate line

	local TabsBackground = Draw(
		'Square',
		{
			Visible = false;
			Position = Vector2(
				6,
				GuiService:GetGuiInset().Y + TitleSectorHeight
			);
			Size = Vector2(Window.ComponentWidth + TabsBackgroundXOffset * 2, Window.ComponentHeight + TabsBackgroundYOffset * 2);
			Filled = true;
			ZIndex = ZIndexes.ComponentHolder;
			Color = Colors.Background;
		}
	)

	local TitleBackground = Draw(
		'Square',
		{
			Visible = true;
			Position = Vector2(
				6,
				GuiService:GetGuiInset().Y
			);
			Size = Vector2(Window.ComponentWidth + TabsBackgroundXOffset * 2, TitleSectorHeight);
			Filled = true;
			ZIndex = ZIndexes.ComponentHolder;
			Color = Colors.Background;
		}
	)

	local TitleDelimiter = Draw(
		'Line',
		{
			Visible = true;
			From = Vector2(
				5,
				GuiService:GetGuiInset().Y + TitleSectorHeight - 1
			);
			To = Vector2(
				5 + Window.ComponentWidth + TabsBackgroundXOffset * 2,
				GuiService:GetGuiInset().Y + TitleSectorHeight - 1
			);
			ZIndex = ZIndexes.ComponentHolder;
			Color = Colors.Outline;
		}
	)

	local TitleLabel = Draw(
		'Text',
		{
			Text = Name;
			Font = Drawing.Fonts.UI;
			Size = 19;
			Visible = true;
			Color = Colors.Label;
			Position = Vector2(TitleBackground.Position.X + 5, TitleBackground.Position.Y + TitleBackground.Size.Y / 2);
			ZIndex = ZIndexes.ComponentElements;
		}
	)

	TitleLabel.Position -= Vector2(
		0,
		TitleLabel.TextBounds.Y / 2
	)

	local TabsBackgroundOutline = Draw(
		'Square',
		{
			Visible = true;
			Position = Vector2(
				5,
				GuiService:GetGuiInset().Y
			);
			Size = TabsBackground.Size + Vector2(1, 1 + TitleSectorHeight);
			Filled = false;
			Thickness = 1;
			ZIndex = ZIndexes.ComponentHolderOutline;
			Color = Colors.Outline;
		}
	)

	TabsBackground.Visible, TabsBackgroundOutline.Visible = true, true

	local TabComponentAllocationPosition = TabsBackground.Position + Vector2(TabsBackgroundXOffset, TabsBackgroundYOffset)

	function Window:UpdateTabContainer()
		TabsBackground.Size = Vector2(Window.ComponentWidth + TabsBackgroundXOffset * 2, Window.ComponentHeight * #Window.Tabs + TabsBackgroundYOffset * 2)

		TabsBackgroundOutline.Size = TabsBackground.Size + Vector2(1, 1 + TitleSectorHeight);
	end

	function Window:CreateTab(Name)
		local InternalTab = {
			Name = Name;
			Selected = false;
			Sectors = {};
			Drawables = {};
		}
		local Tab;Tab = setmetatable(
			{},
			{
				__index = InternalTab;
				__newindex = function(...)
					local _, Index, Value = ...
					InternalTab[Index] = Value
					return switch(Index) {
						Selected = function()
							if Value then
								Tab.Drawables.Outline.Visible = true
								Tab:RenderSectors(true)
							elseif Value == false then
								Tab.Drawables.Outline.Visible = false
								Tab:RenderSectors(false)
							else
								Tab.Drawables.Outline.Visible = false
								Tab:RenderSectors(false)
							end
						end
					}
				end
			}
		)

		local SelectorBackground = Draw(
			'Square',
			{
				Visible = true;
				Position = TabComponentAllocationPosition;
				Size = Vector2(Window.ComponentWidth - 1, Window.ComponentHeight - 1);
				Filled = true;
				ZIndex = ZIndexes.ComponentBackground;
				Color = Colors.InnerBackground;
			}
		)

		local SelectorOutline = Draw(
			'Square',
			{
				Visible = false;
				Position = TabComponentAllocationPosition - Vector2(1, 1);
				Size = SelectorBackground.Size + Vector2(1, 1);
				Filled = false;
				Thickness = 1;
				ZIndex = ZIndexes.ComponentOutline;
				Color = Colors.Outline;
			}
		)

		local SelectorLabel = Draw(
			'Text',
			{
				Text = Tab.Name;
				Font = Drawing.Fonts.UI;
				Size = 19;
				Visible = true;
				Color = Colors.Label;
				Position = Vector2(SelectorBackground.Position.X + 5, SelectorBackground.Position.Y + SelectorBackground.Size.Y / 2);
				ZIndex = ZIndexes.ComponentElements;
			}
		)

		SelectorLabel.Position -= Vector2(
			0,
			SelectorLabel.TextBounds.Y / 2
		)

		TabComponentAllocationPosition += Vector2(0, Window.ComponentHeight)

		Tab.Drawables.Background = SelectorBackground
		Tab.Drawables.Outline = SelectorOutline
		Tab.Drawables.Label = SelectorLabel

		local OverallSectorWidth = TabsBackgroundXOffset * 2 + Window.ComponentWidth

		local SectorAllocationPosition = Vector2(TabsBackgroundOutline.Position.X + TabsBackgroundOutline.Size.X + Window.SectorOffset, GuiService:GetGuiInset().Y)

		function Tab:CreateSector(Name)
			local ISector = {
				Name = Name;
				Selected = false;
				Components = {};
			}
			local Sector;Sector = setmetatable(
				{},
				{
					__index = ISector;
					__newindex = function(...)
						local _, Index, Value = ...
						ISector[Index] = Value
						return switch(Index) {
							Selected = function()
								if Value then
									Sector.Drawables.Outline.Visible = true
								elseif Value == false then
									Sector.Drawables.Outline.Visible = false
								else
									Sector.Drawables.Outline.Visible = false
								end
							end
						}
					end
				}
			)

			local SectorOutline = Draw(
				'Square',
				{
					Visible = false;
					Position = SectorAllocationPosition;
					Size = SelectorBackground.Size + Vector2(1, 1);
					Filled = false;
					Thickness = 1;
					ZIndex = ZIndexes.ComponentOutline;
					Color = Colors.Outline;
				}
			)

			local SectorBackground = Draw(
				'Square',
				{
					Visible = false;
					Position = SectorAllocationPosition + Vector2(1, 1);
					Size = Vector2(Window.ComponentWidth + TabsBackgroundXOffset * 2, Window.ComponentHeight + TabsBackgroundYOffset * 2);
					Filled = true;
					ZIndex = ZIndexes.ComponentHolder;
					Color = Colors.Background;
				}
			)

			function Sector:Update()
				
			end

			insert(Tab.Sectors, Sector)

			SectorAllocationPosition += SectorAllocationPosition

			return Sector
		end

		insert(Window.Tabs, Tab)

		self:UpdateTabContainer()

		return Tab
	end

	return Window
end

local Window = Library:CreateWindow'fatpoopballs'

Window:CreateTab'Local'

Window:CreateTab'Weapons'

Window:CreateTab'Visuals'