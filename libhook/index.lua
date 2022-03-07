local game = game
local next = next
local select = select
local pack, remove = table.pack, table.remove
local Library = {
	Callbacks = {};
	Flags = {
		Continue = 0;
		Stop = 1;
		Return = 2;
		InfiniteYield = 100;
	}
}

local TCallbacks = Library.Callbacks

local function CreateHandler(Name)
	local _ = TCallbacks[Name]
	for Index = 1, #_ do
		local Callback = _[Index]
		local FullReturns = pack(Callback())
		local Flag, ReducedArguments = remove(FullReturns)
	end
end

function Library:Metamethod(Object, Metamethod, Function)
	if typeof(Object) == 'Instance' then
		Object = game -- GETUPVAL<AB> R(A) := UPVALS[B]
	end


end

return Library