---@diagnostic disable: invalid-class-name
local insert, remove, find = table.insert, table.remove, table.find

local HttpService = game:GetService'HttpService'
local GuiService = game:GetService'GuiService'
local UserInputService = game:GetService'UserInputService'
local Players = game:GetService'Players'
local ContextActionService = game:GetService'ContextActionService'

local Color, Vector2, DrawingNew = Color3.fromRGB, Vector2.new, Drawing.new

local ViewportSize = workspace.CurrentCamera.ViewportSize

local Center = ViewportSize / 2

local Colors = (
	function()
		local _ = {}
		for Index = 0, 63 do
			insert(_, tostring(BrickColor.palette(Index)))
		end
		return _
	end
)()

local Library = {
	Drawables = {
		DrawingObjects = {};
	};
	NavigationSettings = {
		CycleSection = {
			Enum.KeyCode.Tab;
		};
		ToggleVisibility = {
			Enum.KeyCode.J;
		};
		Activate = {
			Enum.KeyCode.Q; Enum.KeyCode.Space;
		};
		Up = {
			Enum.KeyCode.W; Enum.KeyCode.Up; Enum.KeyCode.PageUp;
		};
		Down = {
			Enum.KeyCode.S; Enum.KeyCode.Down; Enum.KeyCode.PageDown;
		};
		Left = {
			Enum.KeyCode.A; Enum.KeyCode.Left;
		};
		Right = {
			Enum.KeyCode.D; Enum.KeyCode.Right;
		};
	}
}

local KeyCodesInUsage = {}

for _, KeyCodes in next, Library.NavigationSettings do
	for Index = 1, #KeyCodes do
		insert(KeyCodesInUsage, KeyCodes[Index])
	end
end

local function Draw(Type, Properties)
	local Object = DrawingNew(Type)
	for Property, Value in next, Properties do
		Object[Property] = Value
	end

	insert(Library.Drawables.DrawingObjects, Object)

	return Object
end


local function switch(toCompare)
	return function(possible)
		local _ = possible[toCompare]
		if _ then
			_(toCompare)
			return
		end

		local _ = possible['default']
		if _ then
			_(toCompare)
		end
	end
end

local function DrawingExists(_)
	return rawget(_, '__OBJECT_EXISTS') or false
end

local function typeof(Value)
	return rawget(getmetatable(Value) or {}, '__type') or type(Value)
end

local HelperFunctions do
	HelperFunctions = {}

	function HelperFunctions:LongestString(Strings)
		local Longest = 0
		for _, String in next, Strings do
			if #String > Longest then
				Longest = #String
			end
		end

		return Longest
	end

	function HelperFunctions:FormatStrings(Strings)
		local FormattedStrings = {}
		local Longest = self:LongestString(Strings)
		for _, String in next, Strings do
			insert(FormattedStrings, String .. (' '):rep(Longest - #String))
		end

		return FormattedStrings
	end

	function HelperFunctions:SetSelectionRange(Range, ProtectedElement, Value)
		for Index = 1, #Range do
			local Element = Range[Index]
			if ProtectedElement ~= Element then
				Element.Selected = Value
			end
		end
	end

	function HelperFunctions:SetElementRangeVisibility(Range, Value)
		for Index = 1, #Range do
			local Element = Range[Index]
			Element.Label.Visible = Value
		end
	end

	function HelperFunctions:SetLabelRangeVisibility(Range, Value)
		for Index = 1, #Range do
			local Label = Range[Index]
			Label.Visible = Value
		end
	end

	function HelperFunctions:ProxyTable(T)
		return setmetatable(
			{},
			{
				__index = function(...)
					return rawget(T, select(2, ...))
				end;
				__newindex = function(...)
					return rawset(T, select(2, ...))
				end
			}
		)
	end
end

function Library:CreateWindow(WindowName)
	local _ = GuiService:GetGuiInset().Y + 15;
	local InternalWindow = {
		Name = WindowName or 'unauthorized was here';
		HelpLabels = {};
		HelpLabelOffset = _;
		SectionOffset = _;
		IsBindingKey = false;
		SelectedSection = nil;
		Keybinds = {};
		Sections = {};
		Theme = {
			Font = Drawing.Fonts.Plex;
			Size = 13;
			HighlightColor = Color(2, 144, 252);
			Color = Color(255, 255, 255);
			Transparency = 1;
		};
		Visible = true;
		Actions = {};
	}
	local Window = setmetatable(
		{},
		{
			__newindex = function(...)
				return rawset(InternalWindow, select(2, ...))
			end;
			__index = function(...)
				return rawget(InternalWindow, select(2, ...))
			end
		}
	)

	Window.Watermark = Draw(
		'Text',
		{
			Text = WindowName;
			Font = Window.Theme.Font;
			Size = Window.Theme.Size;
			Visible = Window.Visible;
			Color = Window.Theme.Color;
			Transparency = Window.Theme.Transparency;
			Position = ViewportSize;
		}
	)

	Window.Watermark.Position -= Window.Watermark.TextBounds

	function Window:CreateHelpLabel(Text)
		local Label = Draw(
			'Text',
			{
				Text = Text;
				Font = Window.Theme.Font;
				Size = Window.Theme.Size;
				Visible = Window.Visible;
				Color = Window.Theme.HighlightColor;
				Transparency = Window.Theme.Transparency;
				Position = Vector2(ViewportSize.X, Window.HelpLabelOffset);
			}
		)

		Label.Position -= Label.TextBounds

		insert(Window.HelpLabels, Label)

		Window.HelpLabelOffset += 15

		return Label
	end

	function Window:CreateSection(SectionName)
		local Section
		local InternalSection = {
			Identifier = SectionName or '?';
			Elements = {};
			Labels = {};
			ElementOffset = Vector2();
			DesignatedOffset = _;
			SelectedElement = nil;
			Selected = false;
		}
		Section = setmetatable(
			{},
			{
				__type = 'Section';
				__tostring = SectionName;
				__index = InternalSection;
				__newindex = function(...)
					local Section, Index, Value = ...

					switch(Index) {
						Selected = function()
							switch(Value) {
								[true] = function()
									Section.Title.Text = string.format('[ %s ]', Section.Identifier)
									for _, Element in next, Section.Elements do
										Element.Label.Visible = true
										print(Element.Identifier, true)
									end
									for _ = 1, #Section.Labels do
										Section.Labels[_].Visible = true
									end
								end;
								[false] = function()
									Section.Title.Text = string.format('> %s', Section.Identifier)
									for _, Element in next, Section.Elements do
										Element.Label.Visible = false
										print(Element.Identifier, false)
									end
									for _ = 1, #Section.Labels do
										Section.Labels[_].Visible = false
									end
								end;
							}
						end
					}

					return rawset(InternalSection, select(2, ...))
				end
			}
		)

		Section.Title = Draw(
			'Text',
			{
				Text = '> ' .. Section.Identifier;
				Font = Window.Theme.Font;
				Size = Window.Theme.Size;
				Visible = Window.Visible;
				Color = Window.Theme.HighlightColor;
				Transparency = Window.Theme.Transparency;
				Position = Vector2(6, Window.SectionOffset);
			}
		)

		--local HorizontalWidth = Section.Title.TextBounds.X

		--Window.SectionOffset += (HorizontalWidth * 2) * (3 / 4)

		local TemporalText = Draw(
			'Text',
			{
				Text = string.format('[ %s ] >', Section.Identifier);
				Font = Window.Theme.Font;
				Size = Window.Theme.Size;
				Visible = false;
				Position = Vector2(-ViewportSize.X, -ViewportSize.Y)
			}
		)

		local SelectedTextBounds = TemporalText.TextBounds

		TemporalText:Remove()

		TemporalText = nil

		Section.ElementOffset = Vector2(Section.Title.Position.X + SelectedTextBounds.X + 3, Section.Title.Position.Y)

		Window.SectionOffset += Section.Title.TextBounds.Y + 10

		function Section:CreateLabel(Text)
			local Label = Draw(
				'Text',
				{
					Text = '> ' .. Text;
					Font = Window.Theme.Font;
					Size = Window.Theme.Size;
					Visible = Section.Selected;
					Color = Window.Theme.HighlightColor;
					Transparency = Window.Theme.Transparency;
					Position = Section.ElementOffset;
				}
			)

			insert(Section.Labels, Label)

			Section.ElementOffset += Vector2(0, 15)

			return Label
		end

		function Section:CreateButton(Identifier, Callback)
			local InternalButton = {
				Identifier = Identifier;
				Callback = Callback;
				Selected = false;
				Label = Draw(
					'Text',
					{
						Text = '?';
						Font = Window.Theme.Font;
						Size = Window.Theme.Size;
						Visible = Section.Selected;
						Color = Window.Theme.Color;
						Transparency = Window.Theme.Transparency;
						Position = Section.ElementOffset;
					}
				)
			}
			local Button = setmetatable(
				{},
				{
					__type = 'Button';
					__index = InternalButton;
					__newindex = function(...)
						local Button, Index, Value = ...;
						--print('Button.__newindex', ...)
						switch(Index) {
							Identifier = function()
								rawset(InternalButton, Index, Value)
								Button:Render()
							end;
							Selected = function()
								Button:Highlight(Value)
								Button:Render()
								if Value then
									HelperFunctions:SetSelectionRange(Section.Elements, Button, false)
									Section.SelectedElement = Button
									rawset(InternalButton, 'Selected', true)
									Button:Render()
								else
									rawset(InternalButton, 'Selected', false)
									Button:Render()
								end
							end
						}
						return rawset(InternalButton, select(2, ...))
					end
				}
			)

			Button.Label.Text = string.format('  %s', Button.Identifier)

			Section.ElementOffset += Vector2(0, 15)

			insert(Section.Elements, Button)

			function Button:Activate()
				Button.Callback()
			end

			function Button:Highlight(State)
				Button.Label.Color = (State and Window.Theme.HighlightColor) or Window.Theme.Color
			end

			function Button:Render()
				self.Label.Text = string.format(
					'  %s%s',
					self.Identifier,
					self.Selected and ' <' or ''
				)
			end

			return Button
		end

		function Section:CreateSelector(Identifier, Callback, DefaultValue, Minimum, Maximum, Precision)
			local InternalSelector = {
				Value = DefaultValue or 0;
				Identifier = Identifier;
				Precision = Precision or 1;
				Callback = Callback;
				Selected = false;
				Label = Draw(
					'Text',
					{
						Text = '?';
						Font = Window.Theme.Font;
						Size = Window.Theme.Size;
						Visible = Section.Selected;
						Color = Window.Theme.Color;
						Transparency = Window.Theme.Transparency;
						Position = Section.ElementOffset;
					}
				)
			}
			local Selector = setmetatable(
				{},
				{
					__type = 'Selector';
					__index = InternalSelector;
					__newindex = function(...)
						local Selector, Index, Value = ...;
						--print('Selector.__newindex', ...)

						switch(Index) {
							Identifier = function()
								rawset(InternalSelector, Index, Value)
								Selector:Render()
							end;
							Value = function()
								rawset(InternalSelector, Index, Value)
								Selector:Render()
							end;
							Selected = function()
								Selector:Highlight(Value)
								Selector:Render()
								if Value then
									HelperFunctions:SetSelectionRange(Section.Elements, Selector, false)
									Section.SelectedElement = Selector
									rawset(InternalSelector, 'Selected', true)
									Selector:Render()
								else
									rawset(InternalSelector, 'Selected', false)
									Selector:Render()
								end
							end
						}

						return rawset(InternalSelector, select(2, ...))
					end
				}
			)

			Selector.Label.Text = string.format('  %s <%d>', Selector.Identifier, Selector.Value)

			Selector.Callback(Selector.Value)

			Section.ElementOffset += Vector2(0, 15)

			function Selector:Highlight(State)
				Selector.Label.Color = (State and Window.Theme.HighlightColor) or Window.Theme.Color
			end

			function Selector:Advance()
				Selector.Value = math.clamp(Selector.Value + Selector.Precision, Minimum, Maximum)
				Selector.Callback(Selector.Value)
			end

			function Selector:Back()
				Selector.Value = math.clamp(Selector.Value - Selector.Precision, Minimum, Maximum)
				Selector.Callback(Selector.Value)
			end

			function Selector:Render()
				Selector.Label.Text = string.format(
					'  %s <%d>%s',
					Selector.Identifier,
					tostring(Selector.Value),
					Selector.Selected  and ' <' or ''
				)
			end

			insert(Section.Elements, Selector)

			return Selector
		end

		function Section:CreateToggle(Identifier, Callback, DefaultValue)
			local InternalToggle = {
				Identifier = Identifier;
				Value = DefaultValue or false;
				Callback = Callback;
				Selected = false;
				Label = Draw(
					'Text',
					{
						Text = '?';
						Font = Window.Theme.Font;
						Size = Window.Theme.Size;
						Visible = Section.Selected;
						Color = Window.Theme.Color;
						Transparency = Window.Theme.Transparency;
						Position = Section.ElementOffset;
					}
				)
			}
			local Toggle = setmetatable(
				{},
				{
					__type = 'Toggle';
					__index = InternalToggle;
					__newindex = function(...)
						local Toggle, Index, Value = ...
						--print('Toggle.__newindex', ...)
						switch(Index) {
							Identifier = function()
								rawset(InternalToggle, Index, Value)
								Toggle:Render()
							end;
							Value = function()
								rawset(InternalToggle, Index, Value)
								Toggle:Render()
							end;
							Selected = function()
								Toggle:Highlight(Value)
								Toggle:Render()
								if Value then
									HelperFunctions:SetSelectionRange(Section.Elements, Toggle, false)
									Section.SelectedElement = Toggle
									rawset(InternalToggle, 'Selected', true)
									Toggle:Render()
								else
									rawset(InternalToggle, 'Selected', false)
									Toggle:Render()
								end
							end
						}

						return rawset(InternalToggle, select(2, ...))
					end
				}
			)

			Toggle.Label.Text = string.format('  %s <%s>', Toggle.Identifier, tostring(Toggle.Value))

			Toggle.Callback(Toggle.Value)

			Section.ElementOffset += Vector2(0, 15)

			function Toggle:Highlight(State)
				Toggle.Label.Color = (State and Window.Theme.HighlightColor) or Window.Theme.Color
			end

			function Toggle:Render()
				Toggle.Label.Text = string.format(
					'  %s <%s>%s',
					Toggle.Identifier,
					tostring(Toggle.Value),
					Toggle.Selected and ' <' or ''
				)
			end

			insert(Section.Elements, Toggle)

			return Toggle
		end

		function Section:CreateList(Identifier, Values, Callback, DefaultValue)
			local InternalList = {
				Identifier = Identifier;
				Callback = Callback;
				Values = Values;
				Value = DefaultValue;
				Selected = false;
				Label = Draw(
					'Text',
					{
						Text = '?';
						Font = Window.Theme.Font;
						Size = Window.Theme.Size;
						Visible = Section.Selected;
						Color = Window.Theme.Color;
						Transparency = Window.Theme.Transparency;
						Position = Section.ElementOffset;
					}
				)
			}
			local List = setmetatable(
				{},
				{
					__type = 'List';
					__index = InternalList;
					__newindex = function(...)
						local List, Index, Value = ...
						--print('List.__newindex', ...)
						switch(Index) {
							Identifier = function()
								rawset(InternalList, Index, Value)
								List:Render()
							end;
							Value = function()
								rawset(InternalList, Index, Value)
								List:Render()
							end;
							Selected = function()
								List:Highlight(Value)
								List:Render()
								if Value then
									HelperFunctions:SetSelectionRange(Section.Elements, List, false)
									Section.SelectedElement = List
									rawset(InternalList, 'Selected', true)
									List:Render()
								else
									rawset(InternalList, 'Selected', false)
									List:Render()
								end
							end;
							Values = function()
								List.Value = Value[1] or nil
							end
						}

						return rawset(InternalList, select(2, ...))
					end
				}
			)

			List.Label.Text = string.format('  %s <%s>', List.Identifier, tostring(List.Value))

			if List.Value then
				List.Callback(List.Value)
			end

			Section.ElementOffset += Vector2(0, 15)

			function List:Highlight(State)
				List.Label.Color = (State and Window.Theme.HighlightColor) or Window.Theme.Color
			end

			function List:Next()
				local Index = find(Values, List.Value) or 0
				local NextValue = Values[Index + 1]
				if NextValue then
					List.Value = NextValue
					List.Callback(NextValue)
				end
			end

			function List:Previous()
				local Index = find(Values, List.Value) or 2
				local PreviousValue = Values[Index - 1]
				if PreviousValue then
					List.Value = PreviousValue
					List.Callback(PreviousValue)
				end
			end

			function List:Render()
				List.Label.Text = string.format(
					'  %s <%s>%s',
					List.Identifier,
					tostring(List.Value) or '?',
					List.Selected and ' <' or ''
				)
			end

			if DefaultValue == nil then
				List.Value = Values[1]
			end

			insert(Section.Elements, List)

			return List
		end

		function Section:CreateColorSelector(Identifier, Callback, DefaultValue)
			return self:CreateList(
				Identifier,
				Colors,
				Callback,
				DefaultValue
			)
		end

		function Section:CreatePlayerSelector(Identifier, Callback, DefaultValue)
			local TPlayers = Players:GetPlayers()
			local List = self:CreateList(
				Identifier,
				TPlayers,
				Callback,
				DefaultValue
			)
			Players.PlayerAdded:Connect(function(Player)
				table.insert(TPlayers, Player)
			end)
			Players.PlayerRemoving:Connect(function(Player)
				local Index = find(TPlayers, Player)
				if Index then
					table.remove(TPlayers, Index)
					if List.Value == Player then
						List:Next()
					end
				end
			end)
			return List
		end

		function Section:CreateKeybind(Identifier, Callback, DefaultValue)
			local InternalKeybind = {
				Identifier = Identifier;
				Value = DefaultValue or Enum.KeyCode.Unknown;
				Callback = Callback;
				Binding = false;
				Selected = false;
				Label = Draw(
					'Text',
					{
						Text = '?';
						Font = Window.Theme.Font;
						Size = Window.Theme.Size;
						Visible = Section.Selected;
						Color = Window.Theme.Color;
						Transparency = Window.Theme.Transparency;
						Position = Section.ElementOffset;
					}
				)
			}
			local Keybind = setmetatable(
				{},
				{
					__type = 'Keybind';
					__index = InternalKeybind;
					__newindex = function(...)
						local Keybind, Index, Value = ...
						--print('Keybind.__newindex', ...)
						switch(Index) {
							Identifier = function()
								rawset(InternalKeybind, Index, Value)
								Keybind:Render()
							end;
							Value = function()
								rawset(InternalKeybind, Index, Value)
								Keybind:Render()
							end;
							Binding = function()
								if Value then
									Keybind.Value = Enum.KeyCode.Unknown
									Window.IsBindingKey = Value
									Keybind:Render()
								end
							end;
							Selected = function()
								Keybind:Highlight(Value)
								Keybind:Render()
								if Value then
									HelperFunctions:SetSelectionRange(Section.Elements, Keybind, false)
									Section.SelectedElement = Keybind
									rawset(InternalKeybind, 'Selected', true)
									Keybind:Render()
								else
									rawset(InternalKeybind, 'Selected', false)
									Keybind:Render()
								end
							end;
						}

						return rawset(InternalKeybind, select(2, ...))
					end
				}
			)

			Keybind.Label.Text = string.format('  %s <%s>', Keybind.Identifier, Keybind.Value.Name)

			Section.ElementOffset += Vector2(0, 15)

			function Keybind:Highlight(State)
				Keybind.Label.Color = (State and Window.Theme.HighlightColor) or Window.Theme.Color
			end

			function Keybind:Render()
				Keybind.Label.Text = string.format(
					'  %s <%s>%s',
					Keybind.Identifier,
					Keybind.Value.Name == 'Unknown' and '?' or Keybind.Value.Name,
					Keybind.Selected and ' <' or ''
				)
			end

			function Keybind:Activate()
				if Window.IsBindingKey == false then
					Window.IsBindingKey = true
					Keybind.Value = Enum.KeyCode.Unknown
					Keybind:Render()
				end
			end

			insert(Section.Elements, Keybind); insert(Window.Keybinds, Keybind)

			return Keybind
		end

		insert(Window.Sections, Section)

		local FirstSection = Window.Sections[1]

		FirstSection.Selected = true
		Window.SelectedSection = FirstSection

		if #FirstSection.Elements >= 1 then
			HelperFunctions:SetSelectionRange(FirstSection.Elements, FirstSection.Elements[1], false)
			FirstSection.Elements[1].Selected = true
		end

		return Section
	end

	function Window:CycleSection()
		local Index = find(Window.Sections, Window.SelectedSection)
		if Index == nil then
			return error'???'
		end
		local Section
		if Window.Sections[Index + 1] then
			Section = Window.Sections[Index + 1]
		elseif Window.Sections[1] then
			Section = Window.Sections[1]
		end

		if #Section.Elements == 0 then
			return
		end

		Window.SelectedSection.Selected = false
		Section.Selected = true
		Window.SelectedSection = Section
	end

	function Window:NavigateUp()
		local Section = Window.SelectedSection
		if Section == nil then
			return
		end
		local Index = find(Section.Elements, Section.SelectedElement) or 2

		if Section.Elements[Index - 1] then
			Section.Elements[Index - 1].Selected = true
		end
	end

	function Window:NavigateDown()
		local Section = Window.SelectedSection
		if Section == nil then
			return
		end
		local Index = find(Section.Elements, Section.SelectedElement) or 0

		if Section.Elements[Index + 1] then
			Section.Elements[Index + 1].Selected = true
		end
	end

	function Window:NavigateLeft()
		local Section = Window.SelectedSection
		if Section == nil or Section.SelectedElement == nil then
			return
		end
		local Element = Section.SelectedElement

		if typeof(Element) == 'Selector' then
			Element:Back()
		elseif typeof(Element) == 'List' then
			Element:Previous()
		end
	end

	function Window:NavigateRight()
		local Section = Window.SelectedSection
		if Section == nil or Section.SelectedElement == nil then
			return
		end
		local Element = Section.SelectedElement

		print(typeof(Element))

		if typeof(Element) == 'Selector' then
			Element:Advance()
		elseif typeof(Element) == 'List' then
			Element:Next()
		end
	end

	function Window:Activate()
		local Section = Window.SelectedSection
		if Section == nil or Section.SelectedElement == nil then
			return
		end
		local Element = Section.SelectedElement

		print(typeof(Element))

		if typeof(Element) == 'Button' or typeof(Element) == 'Keybind' then
			Element:Activate()
		elseif typeof(Element) == 'Toggle' then
			Element.Value = not Element.Value
		end
	end

	function Window:ToggleVisibility(State)
		for _, Section in next, Window.Sections do
			Section.Title.Visible = State
			if State and Section.Selected then
				HelperFunctions:SetElementRangeVisibility(Section.Elements, true)
				HelperFunctions:SetLabelRangeVisibility(Section.Labels, true)
			elseif State and Section.Selected == false then
				HelperFunctions:SetElementRangeVisibility(Section.Elements, false)
				HelperFunctions:SetLabelRangeVisibility(Section.Labels, false)
			elseif State == false then
				HelperFunctions:SetElementRangeVisibility(Section.Elements, false)
				HelperFunctions:SetLabelRangeVisibility(Section.Labels, false)
			end
		end
		Window.Visible = State
		if Window.Visible then
			Window:SetupNavigationControls()
		else
			table.foreach(
				Window.Sections,
				function(_, Section)
					HelperFunctions:SetLabelRangeVisibility(Section.Labels, false)
				end
			)
			Window:DisableNavigationControls()
		end
	end

	function Window:SetupNavigationControls()
		for InputClass, KeyCodes in next, Library.NavigationSettings do
			local GUID = string.lower(HttpService:GenerateGUID(false))
			ContextActionService:BindCoreActionAtPriority(
				GUID,
				function(...)
					local _, UserInputState = ...
					if UserInputState ~= Enum.UserInputState.Begin then
						return
					end
					switch(InputClass) {
						Activate = function()
							return Window:Activate()
						end;
						CycleSection = function()
							return Window:CycleSection()
						end;
						Down = function()
							return Window:NavigateDown()
						end;
						Up = function()
							return Window:NavigateUp()
						end;
						Left = function()
							return Window:NavigateLeft()
						end;
						Right = function()
							return Window:NavigateRight()
						end;
					}
					return Enum.ContextActionResult.Sink
				end,
				false,
				Enum.ContextActionPriority.High.Value,
				unpack(KeyCodes)
			)
			insert(Window.Actions, GUID)
		end
	end

	function Window:DisableNavigationControls()
		for _, Identifier in next, Window.Actions do
			ContextActionService:UnbindCoreAction(Identifier)
		end
		table.clear(Window.Actions)
	end

	local function InputBegan(InputObject)
		local KeyCode = InputObject.KeyCode

		if UserInputService:GetFocusedTextBox() == nil and find(Library.NavigationSettings.ToggleVisibility, KeyCode) ~= nil then
			return Window:ToggleVisibility(not Window.Visible)
		end

		if UserInputService:GetFocusedTextBox() then
			return
		end

		if find(KeyCodesInUsage, KeyCode) then
			return
		end

		local Section = Window.SelectedSection
		if Section == nil then
			return
		end
		local Element = Section.SelectedElement

		if Window.IsBindingKey and InputObject.UserInputType == Enum.UserInputType.Keyboard and Element and typeof(Element) == 'Keybind' and find(KeyCodesInUsage, KeyCode) == nil then
			Window.IsBindingKey = false

			if KeyCode == Enum.KeyCode.Delete or KeyCode == Enum.KeyCode.Backspace then
				print('Bound', KeyCode, 'to', Element.Identifier)
				Element.Value = Enum.KeyCode.Unknown
				Element:Render()
			else
				print('Bound', KeyCode, 'to', Element.Identifier)
				Element.Value = KeyCode
				Element:Render()
			end
			return
		elseif Window.IsBindingKey then
			Window.IsBindingKey = false
		end

		for _, Keybind in next, InternalWindow.Keybinds do
			if Keybind.Value ~= Enum.KeyCode.Unknown then
				if Keybind.Value == KeyCode then
					task.spawn(Keybind.Callback)
				end
			end
		end
	end

	UserInputService.InputBegan:Connect(InputBegan)

	Window:SetupNavigationControls()

	return Window
end
return Library