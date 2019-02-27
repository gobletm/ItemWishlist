--[[
LibLootTable gives you the loot list for any Encounter in the Encounter Journal.

--]]



local MAJOR, MINOR = "LibLootTable-1.0", 1
assert(LibStub, MAJOR.." requires LibStub")
local LibLootTable, minor = LibStub:NewLibrary(MAJOR, MINOR)
if not LibLootTable then return end

local function getLootTable(ID, mode)
    EJ_ResetLootFilter()
    if LibLootTable.difficultyID then EJ_SetDifficulty(LibLootTable.difficultyID) end
    if LibLootTable.classID then EJ_SetLootFilter(LibLootTable.classID, LibLootTable.specializationID) end
    EJ_SetSlotFilter(0)
    
    if mode == "instance" then 
        EJ_SelectInstance(ID)
    elseif mode == "encounter" then
        EJ_SelectEncounter(ID)
    end
    
    local numLoot = EJ_GetNumLoot()
    if not numLoot then return end

    local lootTable = {}
    for index = 1, numLoot do
        local itemID, encounterID, name, icon, slot, armorType, link = EJ_GetLootInfoByIndex(index)
        table.insert(lootTable, link)
    end

    return lootTable
end

function LibLootTable:GetLootTableByEncounterID(encounterID)
    return getLootTable(encounterID, "encounter")
end

function LibLootTable:GetLootTableByinstanceID(instanceID)
    return getLootTable(instanceID, "instance")
end


function LibLootTable:SetEncounterDifficulty(difficultyID)
    self.difficultyID = difficultyID
end


function LibLootTable:SetClassFilter(classID, specializationID)
    self.classID = classID
    self.specializationID = specializationID
end

