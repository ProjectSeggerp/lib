local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local insert, find, remove = table.insert, table.find, table.remove
local wrap = coroutine.wrap
local Vector = Vector2.new
local events = import'events'

local Library = {
	Objects = {};
}

local MouseInbounds, OutsideBounds = {}, {}
local _ = false
local QueueSignal = Instance.new'BindableEvent'
local Mouse = Players.LocalPlayer:GetMouse()
local RbxGuiYInset = GuiService:GetGuiInset().Y
local MouseX, MouseY = Mouse.X, Mouse.Y + RbxGuiYInset

local function AwaitCleanOperation()
	if _ then
		QueueSignal.Event:Wait()
	end
end

local function QueueInsert(Table, Index)
	wrap(function()
		AwaitCleanOperation()
		Table[Index] = true
	end)()
end

local function QueueRemove(Table, Index)
	wrap(function()
		AwaitCleanOperation()
		Table[Index] = nil
	end)()
end

local function QueueSwap(t1, t2, i)
	wrap(function()
		AwaitCleanOperation()
		t1[i] = nil
		t2[i] = nil
	end)()
end

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

function Library:new(Class)
	local Drawable = Drawing.new(Class)

	local SetIndexes = {}
	local Object, ObjectMetatable = {
		LeftEdge = 0;
		RightEdge = 0;
		TopEdge = 0;
		BottomEdge = 0;
	}, {}

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
		Class = Class;
	},
	{}
	local EventEmitter = events:new()

	function ProxyMetatable:__newindex(Index, Value)
		if find(SetIndexes, Index) ~= nil then
			Object[Index] = Value
			switch(Index) {
				Position = function()
					local Size = self.Size
					if self.Class ~= 'Line' then
						local UpperLeftCorner = Value
						local UpperRightCorner = Vector(Value.X + Size.X)
						local BottomLeftCorner = Value - Vector(0, Size.Y)
						local BottomRightCorner = UpperRightCorner - Vector(0, Size.Y)
						self.UpperLeftCorner = UpperLeftCorner
						self.BottomLeftCorner = BottomLeftCorner
						self.UpperRightCorner = UpperRightCorner
						self.BottomRightCorner = BottomRightCorner

						local XPosition, YPosition = Value.X, Value.Y
						self.LeftEdge = XPosition
						self.RightEdge = XPosition + Size.X
						self.TopEdge = YPosition
						self.BottomEdge = YPosition + Size.Y
					end
				end
			}
		else
			local err, res = pcall(
				function()
					Drawable[Index] = Value
				end
			)
			if err == false then
				error(string.format('%s: %s', tostring(Index) or '', res))
			end
			return switch(Index) {
				Visible = function()
					if Value then
						QueueInsert(OutsideBounds, self)
					else
						QueueRemove(MouseInbounds, self)
						QueueRemove(OutsideBounds, self)
					end
				end
			}
		end
	end

	function ProxyMetatable:__index(Index)
		if Object[Index] ~= nil then
			return switch(Index) {
				Position = function()
					if Proxy.Class == 'Line' then
						return Proxy.From
					else
						return Proxy.Position
					end
				end;
				Size = function()
					if Proxy.Class == 'Text' then
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

	function Proxy:Remove()
		return self.Drawable:Remove()
	end

	insert(self.Objects, Proxy)

	return setmetatable(Proxy, ProxyMetatable)
end




local function SteppedHandler()
	MouseX, MouseY = Mouse.X, Mouse.Y + RbxGuiYInset

	AwaitCleanOperation()

	_ = true

	for Element in next, MouseInbounds do
		if (MouseX <= Element.LeftEdge or MouseX >= Element.RightEdge) or (MouseY <= Element.TopEdge or MouseY >= Element.BottomEdge) then
			QueueSwap(MouseInbounds, OutsideBounds, Element)

			Element:Emit'MouseLeave'
		else
			Element:Emit'MouseMoved'
		end
	end

	for Element in next, OutsideBounds do
		if (MouseX >= Element.LeftEdge and MouseX <= Element.RightEdge) and (MouseY >= Element.TopEdge and MouseY <= Element.BottomEdge) then
			QueueSwap(OutsideBounds, MouseInbounds, Element)

			Element:Emit'MouseEnter'
		end
	end

	_ = false

	QueueSignal:Fire()
end

local function InputBeganHandler(...)
	local InputObject, GameProcessedEvent = ...
	if GameProcessedEvent then
		return
	end

	AwaitCleanOperation()

	_ = true

	if InputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		for Element in next, MouseInbounds do
			Element:Emit'MouseClick'
		end
	else
		for Element in next, MouseInbounds do
			Element:Emit('InputBegan', InputObject)
		end
	end

	_ = false

	QueueSignal:Fire()
end

UserInputService.InputBegan:Connect(
	InputBeganHandler
)

RunService.RenderStepped:Connect(
	SteppedHandler
)

return setmetatable(
	Library,
	{
		__call = Library.new;
	}
)