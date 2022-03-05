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
			return _(toCompare)
		end

		local _ = possible.default
		if _ then
			return _(toCompare)
		end
	end
end

local function fromHex(_)
	_ = _:gsub('#', '')
	local R, G, B
	if #_ == 3 then
		R, G, B = _:sub(1), _:sub(2), _:sub(3)
	else
		R, G, B = _:sub(1, 2), _:sub(3, 4), _:sub(5, 6)
	end
	return Color(
		tonumber(('0x%s'):format(R)),
		tonumber(('0x%s'):format(G)),
		tonumber(('0x%s'):format(B))
	)
end

local function rgba(...)
	local R, G, B, A = ...
	local H, S, V = Color3.toHSV(Color(R, G, B))
	return Color3.fromHSV(H, S, V + A)
end


local Library = {
	Drawables = {};
}

local MaximumRenderPriority = 2147483647

local ZIndexes = {
	ComponentHolder = -1;
	ComponentHolderOutline = -1;
	ComponentElements = MaximumRenderPriority;
	ComponentBackground = MaximumRenderPriority - 1;
	ComponentOutline = MaximumRenderPriority - 1;
}

local Palette = {
	Text = {
		Primary = fromHex'#fff';
		Secondary = rgba(255, 255, 255, 0.7);
		Disabled = rgba(255, 255, 255, 0.5);
	};
	Actions = {
		Active = fromHex'#fff';
		Hover = rgba(255, 255, 255, 0.08);
		Selected = rgba(255, 255, 255, 0.16);
		Disabled = rgba(255, 255, 255, 0.3);
		DisabledBackground = rgba(255, 255, 255, 0.12);
	};
	Background = fromHex'#121212';
	Accent = rgba(255, 159, 52, 1);--fromHex'#ff789e';--fromHex'#23c19d';
	Divider = rgba(255, 255, 255, 0.12);
}

local function CreateDrawable(Type)

	local Drawable = Drawing.new(Type)

	local SetIndexes = {}
	local Object, ObjectMetatable = {}, {}

	function ObjectMetatable:__newindex(...)
		local Index = ...
		insert(SetIndexes, Index)

		return rawset(...)
	end

	setmetatable(
		Object,
		ObjectMetatable
	)

	for Index in next, Object do
		print(Index)
		insert(SetIndexes, Index)
	end

	local Proxy, ProxyMetatable = {
		Drawable = Drawable;
		Type = Type;
	},
	{}

	function ProxyMetatable:__newindex(Index, Value)
		if find(SetIndexes, Index) ~= nil then
			Object[Index] = Value
		else
			local err, res = pcall(
				function()
					Drawable[Index] = Value
				end
			)
			if err == false then
				error(string.format('%s: %s', tostring(Index) or '', res))
			end
		end
	end

	function ProxyMetatable:__index(Index)
		if Object[Index] ~= nil then
			return switch(Index) {
				Position = function()
					if Proxy.Type == 'Line' then
						return Proxy.From
					else
						return Proxy.Position
					end
				end;
				Size = function()
					if Proxy.Type == 'Text' then
						return Proxy.TextBounds
					else
						return Proxy.Size
					end
				end;
				default = function()
					return Object[Index]
				end
			}
		else
			local err, res = pcall(
				function()
					return Drawable[Index]
				end
			)
			if err == false then
				error('unknown property \''..tostring(Index)..'\' '..res)
			else
				return res
			end
		end
	end

	function Proxy:InBounds(Position)
		local Size = self.Size
		return 
	end

	function Proxy:Remove()
		return self.Drawable:Remove()
	end

	return setmetatable(Proxy, ProxyMetatable)
end

local function Draw(Class, Properties)
	local Object = CreateDrawable(Class)
	for Property, Value in next, Properties do
		Object[Property] = Value
	end

	insert(Library.Drawables, Object)

	return Object
end

local function CreateOutline(_, ZIndex)
	local Outline = Draw(
		'Square',
		{
			Visible = true;
			Position = _.Position - Vector2(1, 1);
			Size = _.Size + Vector2(1, 1);
			Filled = false;
			Thickness = 1;
			ZIndex = ZIndex or MaximumRenderPriority;
			Color = Palette.Accent;
		}
	)

	return Outline
end

local ContainerXOffset, ContainerYOffset = 5, 5

local TitleSectionHeight = 30

local DelimiterThickness = 3

function Library:CreateWindow(Name)
	local Window, _Tabs
	_Tabs = {}
	Window = {
		Name = Name;
		InFocus = false;
		DetachedContainer = nil;
		Components = {};
		-- acount for 1 pixel outline
		ComponentWidth = 150;
		ComponentHeight = 30;
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



	local Background = Draw(
		'Square',
		{
			Visible = false;
			Position = Vector2(
				6,
				GuiService:GetGuiInset().Y
			);
			Size = Vector2(Window.ComponentWidth + ContainerXOffset * 2, TitleSectionHeight + DelimiterThickness + 1 + ContainerYOffset * 2);
			Filled = true;
			ZIndex = ZIndexes.ComponentHolder;
			Color = Palette.Background;
		}
	)

	local Delimiter = Draw(
		'Line',
		{
			Visible = true;
			From = Vector2(
				Background.Position.X,
				Background.Position.Y + TitleSectionHeight
			);
			To = Vector2(
				Background.Size.X,
				Background.Position.Y + TitleSectionHeight
			);
			Thickness = DelimiterThickness;
			ZIndex = ZIndexes.ComponentHolder;
			Color = Palette.Accent;
		}
	)

	local TitleLabel = Draw(
		'Text',
		{
			Text = Window.Name;
			Font = Drawing.Fonts.UI;
			Size = 19;
			Visible = true;
			Color = Palette.Accent;
			Position = Vector2(Background.Position.X + 5, Background.Position.Y + TitleSectionHeight / 2);
			ZIndex = ZIndexes.ComponentElements;
		}
	)

	TitleLabel.Position -= Vector2(
		0,
		TitleLabel.TextBounds.Y / 2
	)

	local BackgroundOutline = CreateOutline(Background, ZIndexes.ComponentHolderOutline)

	Window.Drawables.Background = Background
	Window.Drawables.Outline = BackgroundOutline
	Window.Drawables.DelimiterLine = Delimiter

	local TabComponentAllocationPosition = Background.Position + Vector2(ContainerXOffset, ContainerYOffset + TitleSectionHeight + DelimiterThickness + 1)

	function Window:UpdateTabContainer()
		Background.Size = Vector2(Window.ComponentWidth + ContainerXOffset * 2, Window.ComponentHeight * #Window.Tabs + ContainerYOffset * 2 + TitleSectionHeight + DelimiterThickness + 1)

		BackgroundOutline.Size = Background.Size + Vector2(1, 1);
	end

	function Window:CreateTab(Text)
		local InternalTab = {
			Text = Text;
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
								Tab.Drawables.Background.Color = Palette.Background;
								Tab.Drawables.Label.Color = Palette.Accent;
								Tab:RenderSectors(true)
							elseif Value == false then
								Tab.Drawables.Background.Color = Palette.Actions.DisabledBackground;
								Tab.Drawables.Label.Color = Palette.Text.Primary;
								Tab:RenderSectors(false)
							else
								Tab.Drawables.Background.Color = Palette.Actions.DisabledBackground;
								Tab.Drawables.Label.Color = Palette.Text.Primary;
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
				Size = Vector2(Window.ComponentWidth, Window.ComponentHeight);
				Filled = true;
				ZIndex = ZIndexes.ComponentBackground;
				Color = Palette.Actions.DisabledBackground;
			}
		)

		local SelectorLabel = Draw(
			'Text',
			{
				Text = Tab.Text;
				Font = Drawing.Fonts.UI;
				Size = 19;
				Visible = true;
				Color = Palette.Text.Primary;
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
		Tab.Drawables.Label = SelectorLabel

		function Tab:RenderSectors(bool)
			if bool then
				for _, Sector in next, self.Sectors do
					Sector.Visible = true
				end
			else
				for _, Sector in next, self.Sectors do
					Sector.Visible = false
				end
			end
		end

		local OverallSectorWidth = ContainerXOffset * 2 + Window.ComponentWidth

		local SectorAllocationPosition = Vector2(Background.Position.X + Background.Size.X + Window.SectorOffset, GuiService:GetGuiInset().Y)

		function Tab:CreateSector(Text)
			local ISector = {
				Text = Text;
				Visible = false;
				Components = {};
				Drawables = {};
			}
			local Sector;Sector = setmetatable(
				{},
				{
					__index = ISector;
					__newindex = function(...)
						local _, Index, Value = ...
						ISector[Index] = Value
						return switch(Index) {
							Visible = function()
								if Value then
									Sector.Drawables.Outline.Visible = true
									Sector:SetVisbility(true)
								elseif Value == false then
									Sector.Drawables.Outline.Visible = false
									Sector:SetVisbility(false)
								else
									Sector.Drawables.Outline.Visible = false
									Sector:SetVisbility(false)
								end
							end
						}
					end
				}
			)

			local SectorBackground = Draw(
				'Square',
				{
					Visible = false;
					Position = SectorAllocationPosition;
					Size = Vector2(Window.ComponentWidth + ContainerXOffset * 2, ContainerYOffset * 2 + Window.ComponentHeight + TitleSectionHeight + DelimiterThickness + 1);
					Filled = true;
					ZIndex = ZIndexes.ComponentHolder;
					Color = Palette.Background;
				}
			)

			local SectorOutline = CreateOutline(SectorBackground, ZIndexes.ComponentOutline)

			local SectorTitleLabel = Draw(
				'Text',
				{
					Text = Sector.Text;
					Font = Drawing.Fonts.UI;
					Size = 19;
					Visible = false;
					Color = Palette.Accent;
					Position = Vector2(SectorBackground.Position.X + 5, SectorBackground.Position.Y + TitleSectionHeight / 2);
					ZIndex = ZIndexes.ComponentElements;
				}
			)

			SectorTitleLabel.Position -= Vector2(
				0,
				SectorTitleLabel.TextBounds.Y / 2 + 2
			)

			local DelimiterLine = Draw(
				'Line',
				{
					Visible = false;
					From = Vector2(
						SectorBackground.Position.X,
						SectorBackground.Position.Y + TitleSectionHeight
					);
					To = Vector2(
						SectorBackground.Position.X + Window.ComponentWidth + ContainerXOffset * 2,
						GuiService:GetGuiInset().Y + TitleSectionHeight
					);
					ZIndex = ZIndexes.ComponentHolder;
					Color = Palette.Accent;
				}
			)

			Sector.Drawables.Background = SectorBackground
			Sector.Drawables.Outline = SectorOutline
			Sector.Drawables.Line = DelimiterLine
			Sector.Drawables.Label = SectorTitleLabel

			local ComponentAllocationPosition = Vector2(SectorBackground.Position.X + ContainerXOffset, SectorBackground.Position.Y + ContainerYOffset + TitleSectionHeight - 1)

			function Sector:Update()
				Sector.Drawables.Background.Size = Vector2(Window.ComponentWidth + ContainerXOffset * 2, TitleSectionHeight + Window.ComponentHeight * #Sector.Components + ContainerYOffset * 2)
				Sector.Drawables.Outline.Size = Sector.Drawables.Background.Size + Vector2(1, 1)
			end

			function Sector:SetVisbility(_)
				if _ then
					Sector.Drawables.Background.Visible = true
					Sector.Drawables.Outline.Visible = true
					Sector.Drawables.Line.Visible = true
					Sector.Drawables.Label.Visible = true
					for _, Component in next, Sector.Components do
						for _, Drawable in next, Component.Drawables do
							Drawable.Visible = true
						end
					end
				else
					Sector.Drawables.Background.Visible = false
					Sector.Drawables.Outline.Visible = false
					Sector.Drawables.Line.Visible = false
					Sector.Drawables.Label.Visible = false
					for _, Component in next, Sector.Components do
						for _, Drawable in next, Component.Drawables do
							Drawable.Visible = false
						end
					end
				end
			end

			function Sector:CreateButton(Text, Callback)
				local IButton = {
					Hover = false;
					Text = Text;
					Drawables = {};
				}
				local Button;Button = setmetatable(
					{},
					{
						__index = IButton;
						__newindex = function(...)
							local _, Index, Value = ...
							IButton[Index] = Value
							return switch(Index) {
								Hover = function()
									Button.Drawables.Background.Color = Value and Palette.Actions.Hover or Palette.Actions.Active
								end;
								Text = function()
									Button.Drawables.Label.Text = tostring(Value)
								end
							}
						end
					}
				)

				local Background = Draw(
					'Square',
					{
						Visible = false;
						Position = ComponentAllocationPosition;
						Size = Vector2(Window.ComponentWidth - 1, Window.ComponentHeight - 1);
						Filled = true;
						ZIndex = ZIndexes.ComponentHolder;
						Color = Palette.Actions.DisabledBackground;
					}
				)

				local ButtonLabel = Draw(
					'Text',
					{
						Text = Button.Text;
						Font = Drawing.Fonts.UI;
						Size = 19;
						Visible = false;
						Color = Palette.Text.Primary;
						Position = Vector2(Background.Position.X + 5, Background.Position.Y + Background.Size.Y / 2);
						ZIndex = ZIndexes.ComponentElements;
					}
				)

				ButtonLabel.Position -= Vector2(
					0,
					ButtonLabel.TextBounds.Y / 2
				)

				Button.Drawables.Label = ButtonLabel
				Button.Drawables.Background = Background

				function Button:Activate()
					Callback()
				end

				insert(Sector.Components, Button)

				Sector:Update()

				ComponentAllocationPosition += Vector2(0, Window.ComponentHeight)

				return Button
			end

			insert(Tab.Sectors, Sector)

			SectorAllocationPosition += Vector2(OverallSectorWidth + Window.SectorOffset)

			return Sector
		end

		insert(Window.Tabs, Tab)

		self:UpdateTabContainer()

		return Tab
	end

	return Window
end

local Window = Library:CreateWindow'isa uwu'

local _ = Window:CreateTab'Local'

local one, two = _:CreateSector'anus stretching', _:CreateSector'balls pulling';

one:CreateButton'button'
one:CreateButton'niggers make me mad'
one:CreateButton'trollage'

two:CreateButton'free sex'
two:CreateButton'free haram sex'

_.Selected = true

Window:CreateTab'Weapons'

Window:CreateTab'Visuals'

getgenv()._ = Window