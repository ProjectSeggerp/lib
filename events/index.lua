local insert, pack, pcall, format, spawn, assert, type, error, tostring = table.insert, table.pack, pcall, string.format, task.spawn, assert, type, error, tostring

local Library = {}

function Library:new()
	local Instance = {
		Events = {}
	}

	function Instance:Emit(EventName, ...)
		assert(type(EventName) == 'string', 'string expected as event name.')
		local Callbacks = self.Events[EventName]
		if Callbacks then
			for _, Callback in next, Callbacks do
				spawn(function(...)
					local Success, Error = pcall(Callback, ...)

					if Success == false then
						error(format('[%s] Error while invoking callback: %s', EventName, tostring(Error)), 3)
					end
				end, ...)
			end
		end

		return self
	end

	function Instance:Handle(EventName, ...)
		local Callbacks = pack(...)
		local Table = self.Events[EventName] or {}
		for _ = 1, #Callbacks do
			insert(Table, Callbacks[_])
		end
		self.Events[EventName] = Table

		return self
	end

	-- Older versions compatibility.

	function Instance.emit(...)
		return Instance:Emit(...)
	end

	function Instance.on(...)
		return Instance:Handle(...)
	end

	return Instance
end

return setmetatable(
	Library,
	{
		__call = Library.new;
	}
)