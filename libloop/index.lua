---@diagnostic disable: undefined-global
-- This sets loops to run at your current fps, which means that it's completly computer speed idendependant!
local RunService = game:GetService("RunService")
local ReportingEvent = Instance.new('BindableEvent')
local libloop = {__LOOPS = {}}
function libloop:AddLoop(LoopData)
    assert(LoopData, 'LoopData is missing!')
    LoopData.Ready = true
    self.__LOOPS[LoopData.Name] = LoopData
end
local function CreateFunction(CallBack, Name)
    return function()
        local Success, Error = pcall(CallBack)
        if not Success then
            ReportingEvent:Fire(Name, false)
            return error(string.format('[%s] Loop failed to run, stopped from further running. Error: %s',Name,tostring(Error)))
        else
            ReportingEvent:Fire(Name, true)
        end
    end
end
local function GetInterval(variant)
    if typeof(variant) == "number" then
        return variant
    elseif typeof(variant) == "function" then
        local Success, Interval = pcall(variant) 
        return Success and Interval or (not error('Failed to get interval, returning default one.', 1)) and 1
    end
end
local function MainCallback()
    task.wait()
    for LoopName, LoopProperties in next, libloop.__LOOPS do
        if not LoopProperties.Ready or LoopProperties.PreventFromRunning then 
            continue
        end
        task.spawn(
            function()
                if LoopProperties.RunCheckFunction then
                    local Success, Run = pcall(LoopProperties.RunCheckFunction)
                    if not (Success and Run) then
                        return
                    end
                end
                task.delay(GetInterval(LoopProperties.Interval), CreateFunction(LoopProperties.Function, LoopName))
                LoopProperties.Ready = false
                local Name, SuccessFullyExecuted = nil, nil
                repeat
                    Name, SuccessFullyExecuted = ReportingEvent.Event:Wait()
                until Name == LoopName
                if not SuccessFullyExecuted then
                    LoopProperties.PreventFromRunning = true
                end
                LoopProperties.Ready = true
            end
        )
    end
end
RunService.Heartbeat:Connect(MainCallback)
setrawmetatable(libloop, {
    __newindex = function(self, k, v)
        return error('Tried to set a read-only object.', 2)
    end,
    __eq = function(...) return false end,
    __metatable = 'The metatable is locked.', 
    __type = 'libloop'
})
setreadonly(libloop, true)
return libloop