function table_clone(t)
    local t2 = {}
    for k,v in pairs(t) do
      t2[k] = v
    end
    return t2
  end
local EventFunction = {event = nil,handler = nil}
function EventFunction:new(event, handler) 
    local new = table_clone(EventFunction)
    new.event = event
    new.handler = handler
    return new
end
local EventEmitter = {__events = {}}
EventEmitter.on = function(...) 
    local args = {...}
    assert(#args >= 1, 'event to fire missing')
    assert(type(args[2]) == 'function', 'handler must be a function')
    local event = args[1]
    assert(type(event) == 'string', 'event must be a string')
    local tmp = EventFunction:new(args[1],args[2])
    table.insert(EventEmitter.__events, tmp)
end;
EventEmitter.emit = function(...) 
    local args = {...}
    assert(#args >= 1, 'event to fire missing')
    
    local event = args[1]
    table.remove(args, 1)
    for _,ev in pairs(EventEmitter.__events) do 
        if ev.event == event then 
            pcall(ev.handler, unpack(args))
        end
    end
end;
--allow the use of one require for multiple EventEmitter instances.   
local EventManager = {}
function EventManager:new()
    local tmp = table_clone(EventEmitter)
    return tmp
end

return EventManager