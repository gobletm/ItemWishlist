--[[
LibLootTable gives you the loot list for any Encounter in the Encounter Journal.

--]]



local MAJOR, MINOR = "LibLootTable-1.0", 1
assert(LibStub, MAJOR.." requires LibStub")
local LibLootTable, minor = LibStub:NewLibrary(MAJOR, MINOR)
if not LibLootTable then return end


function LibLootTable:GetLootTableByEncounterID(encounterID)
    EJ_ResetLootFilter()
    if self.difficultyID then EJ_SetDifficulty(self.difficultyID) end
    if self.classID then EJ_SetLootFilter(self.classID, self.specializationID) end
    EJ_SetSlotFilter(0)
    EJ_SelectEncounter(encounterID)


    local numLoot = EJ_GetNumLoot()
    if not numLoot then return end

    local lootTable = {}
    for index = 1, numLoot do
        local itemID, encounterID, name, icon, slot, armorType, link = EJ_GetLootInfoByIndex(index)
        table.insert(lootTable, link)
    end

    return lootTable
end

function LibLootTable:SetEncounterDifficulty(difficultyID)
    self.difficultyID = difficultyID
end


function LibLootTable:SetClassFilter(classID, specializationID)
    self.classID = classID
    self.specializationID = specializationID
end

