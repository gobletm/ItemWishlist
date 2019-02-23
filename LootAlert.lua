ItemWishlistLootAlert = LibStub("AceAddon-3.0"):NewAddon("ItemWishlistLootAlert", "AceConsole-3.0", "AceEvent-3.0" )
local LibLootTable = LibStub("LibLootTable-1.0")


local function getClassID()
    local _, _, classID = UnitClass('player')
	return classID
end

local function getLootSpecialization()
    local lootSpecialization = GetLootSpecialization() or 0
	if(lootSpecialization == 0) then
		lootSpecialization = (GetSpecializationInfo(GetSpecialization() or 0)) or 0
	end
    return lootSpecialization
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("SPELL_CONFIRMATION_PROMPT")

frame:SetScript("OnEvent",
	function(self, event, ...)
		local spellID, confirmType, text, duration, currencyID, currencyCost, difficultyID = ...
        if ItemWishlist:getLootAlert() and event == "SPELL_CONFIRMATION_PROMPT" and confirmType == 1 then
            local instanceInfoID, encounterID = GetJournalInfoForSpellConfirmation(spellID)

            LibLootTable:SetEncounterDifficulty(difficultyID)
            LibLootTable:SetClassFilter(getClassID(), getLootSpecialization())
            local lootTable = LibLootTable:GetLootTableByEncounterID(encounterID)


            local itemWishList = ItemWishlist:GetItemList()
            local result_msg = ""

            for i= 1, #lootTable do
                local itemName = GetItemInfo(lootTable[i])
                if itemWishList[itemName] then
                    result_msg = result_msg .. lootTable[i] .."\n"
                end
            end

            if result_msg ~= "" then
                print("|cffffa000ItemWishlist|r: This Boss can drop the following Loot that is on your wishlist\n" .. result_msg)
            end

        end
	end)
