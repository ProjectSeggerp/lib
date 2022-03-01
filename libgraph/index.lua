local UserInputService = game:GetService'UserInputService'

local Camera = workspace.CurrentCamera or workspace:GetPropertyChangedSignal'CurrentCamera':Wait()

workspace:GetPropertyChangedSignal'CurrentCamera':Connect(function(_)
	Camera = _
end)

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

local PositioningType = {
	Next = 1;
	Previous = 2;
	Up = 3;
	Down = 4;
}

local Library = {
	Graphs = {};
	OriginOffset = Vector2.new(0, 15);
	PositioningType = PositioningType.Next;
}

function Library:Tween(Line, From, To)
	local _From, _To = Line.From, Line.To
	for _ = 0, 1, .05 do
		Line.From = _From:Lerp(From, _); Line.To = _To:Lerp(To, _);
		task.wait()
	end
end

function Library:CreateGraph(Information)
	local Identifier, Size, MaxValue, Color, NodeAmount = Information.Identifier, Information.Size, Information.MaxValue or Information.Size.Y, Information.Color, Information.NodeAmount or 4
	local Graph = {
		Identifier = Identifier;
		Size = Size or Vector2.new(85, 150);
		MaxValue = MaxValue or 100;
		Color = Color or Color3.new(1);
		Points = {}; PointHolder = {};
		NodeAmount = NodeAmount;
		Axes = {};
		Nodes = {};
		Text = nil
	}

	Graph.Points = setmetatable(
		Graph.Points,
		{
			__index = Graph.PointHolder;
			__newindex = function(...)
				local _, Index, Value = ...

				if Index >= Graph.NodeAmount + 1 then
					table.remove(Graph.PointHolder, 1)
					table.insert(Graph.PointHolder, math.clamp(Value, 1, Graph.MaxValue))
				else
					table.insert(Graph.PointHolder, math.clamp(Value, 1, Graph.MaxValue))
				end
			end
		}
	)

	Graph.AxesOrigin = Vector2.new((Camera.ViewportSize.X - Graph.Size.X) - Library.OriginOffset.X, Camera.ViewportSize.Y - Library.OriginOffset.Y)

	local XLine, YLine = Drawing.new'Line', Drawing.new'Line'

	Graph.Axes.X, Graph.Axes.Y = XLine, YLine

	XLine.Color, YLine.Color = Color3.new(1, 1, 1), Color3.new(1, 1, 1)

	XLine.Visible, YLine.Visible = true, true

	XLine.From, YLine.From = Graph.AxesOrigin, Graph.AxesOrigin

	--[[
		|
		|
		|
		|
		O-----------------
	]]

	XLine.To, YLine.To = Vector2.new(
		Graph.AxesOrigin.X,
		Graph.AxesOrigin.Y - Graph.Size.Y
	),
	Vector2.new(
		Graph.AxesOrigin.X + Graph.Size.X,
		Graph.AxesOrigin.Y
	)

	local Text = Drawing.new'Text'

	Text.Visible = true;
	Text.Color = Color3.new(1, 1, 1)

	Text.Text = Identifier

	Text.Position = Vector2.new(YLine.To.X - Text.TextBounds.X, YLine.To.Y - Text.TextBounds.Y)

	Graph.Text = Text

	for _ = 1, Graph.NodeAmount do
		local Line = Drawing.new'Line'

		Line.Color, Line.Visible = Graph.Color, false

		Line.From, Line.To = Graph.AxesOrigin, Graph.AxesOrigin

		Line.Thickness = .1

		table.insert(Graph.Nodes, Line)
	end

	switch(Library.PositioningType) {
		[PositioningType.Next] = function()
			Library.OriginOffset += Vector2.new(Graph.Size.X, 0)
		end;
		[PositioningType.Previous] = function()
			Library.OriginOffset += Vector2.new(-Graph.Size.X, 0)
		end;
		[PositioningType.Up] = function()
			Library.OriginOffset += Vector2.new(0, Graph.Size.Y)
		end;
		[PositioningType.Down] = function()
			Library.OriginOffset += Vector2.new(0, -Graph.Size.Y)
		end;
	}

	function Graph:Render()
		XLine.From, YLine.From = Graph.AxesOrigin, Graph.AxesOrigin
		XLine.To, YLine.To = Vector2.new(
			Graph.AxesOrigin.X,
			Graph.AxesOrigin.Y - Graph.Size.Y
		),
		Vector2.new(
			Graph.AxesOrigin.X + Graph.Size.X,
			Graph.AxesOrigin.Y
		)
		Text.Position = Vector2.new(YLine.To.X - Text.TextBounds.X, YLine.To.Y - Text.TextBounds.Y)

		for Index = 1, #Graph.PointHolder do
			local CurrentValue = Graph.PointHolder[Index]
			local PreviousValue = Graph.PointHolder[Index - 1]

			local Line = Graph.Nodes[Index]

			if Line then
				Line.Visible = true

				local From

				if Index == 1 then
					From = Graph.AxesOrigin + Vector2.new(1, 1)
				else
					From = Vector2.new(
						(Graph.AxesOrigin.X) + (Index - 1) * (Graph.Size.X / Graph.NodeAmount),
						(Graph.AxesOrigin.Y) - (PreviousValue * (Graph.Size.Y / Graph.MaxValue))
					)
				end

				local To = Vector2.new(
					Graph.AxesOrigin.X + Index * (Graph.Size.X / Graph.NodeAmount),
					Graph.AxesOrigin.Y - ((CurrentValue * (Graph.Size.Y / Graph.MaxValue)))
				)

				task.spawn(Library.Tween, Library, Line, From, To)
			end
		end
	end

	function Graph:CreatePoint(Value)
		assert(type(Value) == 'number', 'Numerical value expected.')

		self.Points[#self.PointHolder + 1] = Value -- no __len moment

		Graph:Render()
	end

	return Graph
end

return Library