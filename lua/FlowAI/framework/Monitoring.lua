local WORK_RATE = 50

local CreateWorkLimiter = import('/mods/DilliDalli/lua/FlowAI/framework/utils/WorkLimits.lua').CreateWorkLimiter

UnitList = Class({
    Init = function(self)
        self.size = 0
        self.units = {}
    end,

    AddUnit = function(self, unit)
        self.size = self.size + 1
        self.units[self.size] = unit
    end,

    FetchUnit = function(self)
        while self.size > 0 do
            local unit = self.units[self.size]
            self.units[self.size] = nil
            self.size = self.size - 1
            if unit and (not unit.Dead) then
                return unit
            end
        end
        return nil
    end,
})

function CreateUnitList()
    local ul = UnitList()
    ul:Init()
    return ul
end

UnitMonitoring = class({
    Init = function(self,brain)
        self.brain = brain
        self.registrations = {}
    end,

    MonitoringThread = function(self)
        local workLimiter = CreateWorkLimiter(WORK_RATE,"UnitMonitoring:MonitoringThread")
        while self.brain:IsAlive() and workLimiter:Wait() do
            local allUnits = self.brain.aiBrain:GetListOfUnits(categories.ALL,false,true)
            workLimiter:Wait()
            for i, unit in allUnits do
                workLimiter:MaybeWait()
                if unit and (not unit.Dead) and (not unit.FlowAI) then
                    unit.FlowAI = {}
                    local bpID = unit.UnitId
                    local j = 1
                    while j <= self.registrations[bpID].count do
                        self.registrations[unitBlueprint].lists[j]:AddUnit(unit)
                        j = j+1
                    end
                end
                
            end
        end
        workLimiter:End()
    end,

    RegisterInterest = function(self, unitBlueprint, unitList)
        self.registrations[unitBlueprint].count = self.registrations[unitBlueprint].count + 1
        self.registrations[unitBlueprint].lists[self.registrations[unitBlueprint].count] = unitList
    end,

    Run = function(self)
        self:ForkThread(self.MonitoringThread)
    end,

    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.brain.trash:Add(thread)
            return thread
        else
            return nil
        end
    end,
})