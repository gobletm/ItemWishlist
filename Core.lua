-- load libraries
ItemWishlist = LibStub("AceAddon-3.0"):NewAddon("ItemWishlist", "AceConsole-3.0", "AceEvent-3.0")
local ItemWishlist = ItemWishlist
local AceGUI = LibStub("AceGUI-3.0")

local LDB = LibStub("LibDataBroker-1.1")
local dataobj = LDB:NewDataObject("ItemWishlist", {
    type = "data source",
    label = "ItemWishlist",
    text = "ItemWishlist",
    icon = "Interface\\AddOns\\ItemWishlist\\icon.tga",
})

local LibDualSpec = LibStub('LibDualSpec-1.0')
------------------------------------------------------------------------------------------------
-- helper functions

-- Concat the contents of the parameter list,
-- separated by the string delimiter (just like in perl)
-- example: strjoin(", ", {"Anna", "Bob", "Charlie", "Dolores"})
local function strjoin(delimiter, list)
    local len = getn(list)
    if len == 0 then
        return ""
    end
    local string = list[1]
    for i = 2, len do
        string = string .. delimiter .. list[i]
    end
    return string
end

-- Split text into a list consisting of the strings in text,
-- separated by strings matching delimiter (which may be a pattern).
-- example: strsplit(",%s*", "Anna, Bob, Charlie,Dolores")
local function strsplit(delimiter, text)
    local list = {}
    local pos = 1
    if strfind("", delimiter, 1) then -- this would result in endless loops
        error("delimiter matches empty string!")
    end
    while 1 do
        local first, last = strfind(text, delimiter, pos)
        if first then -- found?
            tinsert(list, strsub(text, pos, first-1))
            pos = last+1
        else
            tinsert(list, strsub(text, pos))
            break
        end
    end
    return list
end

-- returns the length of a table with key, value pairs
local function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- returns an iterator for a table with key, value pairs
local function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

-- strips the widespaces from a string
local function trim(s)
  return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

------------------------------------------------------------------------------------------------
-- functions
function ItemWishlist:setTooltipColor(r,g,b,a, tooltipColorType)
    self.db.profiles[self.db:GetCurrentProfile()][tooltipColorType] = {r = r, g = g, b = b, a = a}
end

function ItemWishlist:getTooltipColor(tooltipColorType)
    local tooltipColor = self.db.profiles[self.db:GetCurrentProfile()][tooltipColorType]
    if not tooltipColor then
        return 0.4, 1, 0.4, 1
    end
    return tooltipColor.r, tooltipColor.g, tooltipColor.b, tooltipColor.a
end

function ItemWishlist:setOnlySelectetItem(checked)
    self.db.profiles[self.db:GetCurrentProfile()]["showOnlySelectetItem"] = checked
end

function ItemWishlist:getOnlySelectetItem()
    return self.db.profiles[self.db:GetCurrentProfile()]["showOnlySelectetItem"] or false
end

function ItemWishlist:setLootAlert(checked)
    self.db.profiles[self.db:GetCurrentProfile()]["showLootAlert"] = checked
end

function ItemWishlist:getLootAlert()
    return self.db.profiles[self.db:GetCurrentProfile()]["showLootAlert"] or false
end

function ItemWishlist:setOptions()
    local options = {
        name = "ItemWishlist",
        handler = ItemWishlist,
        type = 'group',
        args = {
            text = {
                order = 1,
                type = 'group',
                name = 'Text',
                desc = 'Text Options',
                args = {
                    tooltipColor = {
                        type = 'color',
                        name = 'tooltip color',
                        set = function(info, r,g,b,a) ItemWishlist:setTooltipColor(r,g,b,a, "tooltipColor") end,
                        get = function(info) return ItemWishlist:getTooltipColor("tooltipColor") end,
                    },
                    tooltipTagColor = {
                        type = 'color',
                        name = 'tooltip tag color',
                        set = function(info, r,g,b,a) ItemWishlist:setTooltipColor(r,g,b,a, "tooltipTagColor") end,
                        get = function(info) return ItemWishlist:getTooltipColor("tooltipTagColor") end,
                    },
                },
            },
            --loot = {
            --    order = 2,
            --    type = 'group',
            --    name = "Loot options",
            --    desc = "Loot options",
            --    args = {
             --       lootAlert = {
            --          type = 'toggle',
            --          name = "display loot alert",
            --          set = function(info, checked) ItemWishlist:setLootAlert(checked) end,
            --          get = function(info) return ItemWishlist:getLootAlert() end,
             --       },
             --   },
           -- },
            dressUp = {
                order = 3,
                type = 'group',
                name = "Dressing Room",
                desc = "Dressing Room Options",
                args = {
                    onlySelectetItem = {
                        type = 'toggle',
                        name = "show only selected item",
                        set = function(info, checked) ItemWishlist:setOnlySelectetItem(checked) end,
                        get = function(info) return ItemWishlist:getOnlySelectetItem() end,
                    },
                },
            },
        },
    }
    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(ItemWishlist.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("ItemWishlist", options)
    LibDualSpec:EnhanceOptions(options.args.profile, self.db)
end

function ItemWishlist:OnInitialize()
    self.instanceDifficulty = "0"
    self.mainFrame = nil
    self.itemContainer = nil

    self.defaults = {
        profile = {
            itemList = {},
            tooltipColor = {
                r = 0.4,
                g = 1,
                b = 0.4,
                a = 1},
            tooltipTagColor = {
                r = 0.4,
                g = 1,
                b = 0.4,
                a = 1},
            showOnlySelectetItem = false,
        }
    }
    self.db = LibStub:GetLibrary("AceDB-3.0"):New("ItemWishlistDB",self.defaults, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "refreshConfig")
--    self.db.RegisterCallback(self, "OnProfileReset", "refreshConfig")

    LibDualSpec:EnhanceDatabase(self.db, "ItemWishlist")

    ItemWishlist:setOptions()

    self:RegisterChatCommand("iwl", "ToggleFrame")
    self:RegisterChatCommand("itemwishlist", "ToggleFrame")

    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ItemWishlist", "ItemWishlist")
end

function ItemWishlist:OnEnable()
    if not self.db["profiles"][self.db:GetCurrentProfile()] then
        self.db["profiles"][self.db:GetCurrentProfile()] = {}
        self.db.profiles[self.db:GetCurrentProfile()]["itemList"] = {}
    end
end

local function parseInput(inputValue, instanceDifficulty)
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType,
        itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice =
        GetItemInfo(inputValue)

    if not instanceDifficulty == "0" then
        itemLink = strsplit(":", itemLink)
        itemLink[15] = instanceDifficulty
        itemLink = strjoin(":", itemLink)
    end

    return itemName, itemLink
end

function ItemWishlist:IsOpen()
    return self.mainFrame and self.mainFrame:IsVisible()
end

function ItemWishlist:AddItemToList(itemLink, instanceDifficulty, notes, group, tag)

    local itemName, newItemLink = parseInput(itemLink, instanceDifficulty)
        if itemName then
        local activeProfile = self.db:GetCurrentProfile()
        self.db.profiles[activeProfile]["itemList"][itemName] = {itemLink=newItemLink, notes=notes,
                                                                instanceDifficulty=instanceDifficulty,
                                                                group=group, tooltipTag=tag}
        self.editbox:SetText("")
        ItemWishlist:PopulateEntries(activeProfile)
    else
        ItemWishlist:ErrorMessage("IWL ERROR: invalid input.")
    end
end

function ItemWishlist:ErrorMessage(msg)
    UIErrorsFrame:AddMessage(msg, 1.0, 0.0, 0.0, 53, 5)
    print("|cffffa000ItemWishlist|r: " .. msg)
end

function ItemWishlist:GetItemList()
    local activeProfile = self.db:GetCurrentProfile()
    if self.db.profiles[activeProfile] then
        local itemList = self.db.profiles[activeProfile]["itemList"]
        local result = {}

        if itemList and tablelength(itemList) >0 then
            for itemName,itemData in pairsByKeys(itemList) do
                result[itemName] = itemData["itemLink"]
            end
        end
        return result
    end
end

------------------------------------------------------------------------------------------------
-- Data broker
function dataobj:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Item wishlist.", 0, 1, 1)
    GameTooltip:AddLine("Left-Click to toggle item wishlist", 0, 0.7, 1)
    GameTooltip:AddLine("Right-click to open menu", 0, 0.7, 1)

    local activeProfile = ItemWishlist.db:GetCurrentProfile()
    if activeProfile and ItemWishlist.db.profiles[activeProfile]["itemList"] then
        local itemList = ItemWishlist.db.profiles[activeProfile]["itemList"]
        GameTooltip:AddLine("\n")
        for itemName, data in pairs(itemList) do
            GameTooltip:AddLine(itemList[itemName].itemLink)
            if itemList[itemName].tooltipTag and itemList[itemName].tooltipTag ~= "" then
                local r,g,b = ItemWishlist:getTooltipColor("tooltipTagColor")
                GameTooltip:AddLine("-> " .. itemList[itemName].tooltipTag, r, g, b, true)
            end
        end
    end
    GameTooltip:Show()
end

function dataobj:OnLeave()
    GameTooltip:Hide()
end

function dataobj:OnClick(button)
    if button == "LeftButton" then
        if not ItemWishlist:IsOpen() then
            ItemWishlist:CreateFrame()
        else
            ItemWishlist:closeWindow()
        end
    else if button == "RightButton" then
            InterfaceOptionsFrame_OpenToCategory("ItemWishlist")
        end
    end
end

------------------------------------------------------------------------------------------------
-- event handler
local iconFrame = nil
local function addIconToTooltip(link)

    iconFrame = CreateFrame("Frame",nil,GameTooltip,"IconIntroTemplate")
    iconFrame:SetSize(36,36)
    iconFrame:SetPoint("BOTTOMLEFT",GameTooltip,"TOPLEFT",1,-1)
    iconFrame.texture = iconFrame:CreateTexture(nil,"BACKGROUND")
    iconFrame.texture:SetAllPoints(iconFrame)
    iconFrame.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    local texture = select(10,GetItemInfo(link)) or ""

    if texture then
        iconFrame.texture:SetTexture(texture)
        iconFrame:Show()
    else
        iconFrame:Hide()
    end
end

local function SetTooltip_Hook(self, ...)
    local itemName, link = self:GetItem()
    local db = ItemWishlist.db
    if db["profiles"][db:GetCurrentProfile()] then
        local itemList = db.profiles[db:GetCurrentProfile()]["itemList"]
        if itemList then
            local itemData = itemList[itemName]
            if itemData then
                local r,g,b = ItemWishlist:getTooltipColor("tooltipColor")
                self:AddLine("On Wishlist", r, g, b, true)
                if itemData.tooltipTag then
                    self:AddLine(itemData.tooltipTag, r, g, b, true)
                end
            end
        end
    end
end

GameTooltip:HookScript("OnTooltipSetItem", SetTooltip_Hook)

function ItemWishlist:SetInstanceDifficulty(instanceDiff)
    self.instanceDifficulty = instanceDiff
end

local function deleteItem(itemName)
    ItemWishlist.db.profiles[ItemWishlist.db:GetCurrentProfile()]["itemList"][itemName] = nil
    local activeProfile = ItemWishlist.db:GetCurrentProfile()

    ItemWishlist.itemInfoFrame:SetText("")
    ItemWishlist.itemInfoFrame:SetLabel("")
    ItemWishlist.tooltipTagInputField:SetText("")
    ItemWishlist.itemLabel:SetText("<Select Item>")
    GameTooltip:ClearLines()
    GameTooltip:Hide()
    ItemWishlist:PopulateEntries(activeProfile)
end

function ItemWishlist:DislpayNotes(widget, event, button)
    local itemName = widget.userdata.itemName
    local itemData = ItemWishlist.db.profiles[ItemWishlist.db:GetCurrentProfile()]["itemList"][itemName]

    ItemWishlist.itemInfoFrame:SetLabel(itemName)
    ItemWishlist.itemInfoFrame:SetText(itemData.notes)
    ItemWishlist.tooltipTagInputField:SetText(itemData.tooltipTag)
    ItemWishlist.itemLabel:SetText(itemName)

    ItemWishlist.itemInfoFrame.userdata.itemName = itemName
    ItemWishlist.itemGroupInputField.userdata.itemName = itemName
    ItemWishlist.tooltipTagInputField.userdata.itemName = itemName
end

local function itemLabelOnClick(widget, event, button)
    if button == "RightButton" then
        deleteItem(widget.userdata.itemName)
    elseif button == "LeftButton" then
        if IsControlKeyDown() and IsDressableItem(widget.userdata.itemLink) then
            DressUpItemLink(widget.userdata.itemLink)
            if ItemWishlist:getOnlySelectetItem() then
                DressUpModel:Undress()
                DressUpModel:TryOn(widget.userdata.itemLink)
            end
        else
            ItemWishlist:DislpayNotes(widget, event, button)
        end
    end
end

local function onEnter(widget)
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(widget.frame, "ANCHOR_LEFT")
    GameTooltip:SetHyperlink(widget.userdata.itemLink)
    GameTooltip:Show()
    addIconToTooltip(widget.userdata.itemLink)
end

local function onLeave()
    if iconFrame ~= nil then
        iconFrame:Hide()
    end
    GameTooltip:Hide()
end

function ItemWishlist:closeWindow()
    local activeProfile = ItemWishlist.db:GetCurrentProfile()
    local point, relativeTo, relativePoint, xoffset, yoffset = ItemWishlist.mainFrame:GetPoint()
    AceGUI:Release(ItemWishlist.mainFrame)
end

function ItemWishlist:refreshConfig()

    local activeProfile = self.db:GetCurrentProfile()

    if not ItemWishlist.db.profiles[activeProfile] then
        ItemWishlist.db.profiles[activeProfile] = {
            itemList = {},
        }
    else
        if not ItemWishlist.db.profiles[activeProfile]["itemList"] then
            ItemWishlist.db.profiles[activeProfile]["itemList"] = {}
        end
    end
end

local function saveInfoFrameChanges(widget, notes)
    local activeProfile = ItemWishlist.db:GetCurrentProfile()
    local itemName = widget.userdata.itemName
    if not itemName then
        ItemWishlist:ErrorMessage("No item selected!")
        return false
    end
    ItemWishlist.db.profiles[activeProfile]["itemList"][itemName].notes = notes
end

local function saveItemGroup(widget, group)
    local activeProfile = ItemWishlist.db:GetCurrentProfile()
    local itemName = widget.userdata.itemName
    if not itemName then
        ItemWishlist:ErrorMessage("No item selected!")
        return false
    end
    ItemWishlist.db.profiles[activeProfile]["itemList"][itemName].group = trim(group)
    widget:SetText("")
    ItemWishlist:PopulateEntries(activeProfile)
end

local function saveTooltipTag(widget, tag)
    local activeProfile = ItemWishlist.db:GetCurrentProfile()
    local itemName = widget.userdata.itemName
    if not itemName then
        ItemWishlist:ErrorMessage("No item selected!")
        return false
    end
    ItemWishlist.db.profiles[activeProfile]["itemList"][itemName].tooltipTag = trim(tag)
    ItemWishlist:PopulateEntries(activeProfile)
end

------------------------------------------------------------------------------------------------
-- Create frame
function ItemWishlist:CreateFrame()
    self.mainFrame = AceGUI:Create("Frame")
    self.mainFrame:SetTitle("Item Wishlist")
    self.mainFrame:SetStatusText("")
    self.mainFrame:SetCallback("OnClose", function() self.closeWindow() end)
    self.mainFrame:SetLayout("Flow")
    self.mainFrame:SetWidth(500)
    self.mainFrame:SetHeight(550)

    local addGroup = AceGUI:Create("InlineGroup")
    addGroup:SetTitle("Add Item")
    addGroup:SetLayout("Flow")
    addGroup:SetRelativeWidth(1.0)

    -- text field item id or item link
    self.editbox = AceGUI:Create("EditBox")
    self.editbox:SetLabel("Insert ItemId or ItemLink:")
    self.editbox:SetRelativeWidth(0.5)
--    self.editbox:SetCallback("OnEnterPressed", function(widget, event, input) ItemWishlist:SetInputValue(input) end)
    addGroup:AddChild(self.editbox)

    -- select Instance difficulty
    local difficultyDropDown = AceGUI:Create("Dropdown")
    difficultyDropDown:SetLabel("Instance difficulty")
    difficultyDropDown:SetRelativeWidth(0.3)
    difficultyDropDown:SetList({["0"]= "----", ["1826"] = "normal", ["1726"] = "heroic", ["1727"] = "mythic"},
                                {"0","1826", "1726", "1727"})
    difficultyDropDown:SetCallback("OnValueChanged", function(widget, event, key)
                                    ItemWishlist:SetInstanceDifficulty(key) end)
    addGroup:AddChild(difficultyDropDown)

    -- add item to list button
    local addButton = AceGUI:Create("Button")
    addButton:SetText("Add Item")
    addButton:SetRelativeWidth(0.2)
    addButton:SetCallback("OnClick", function() ItemWishlist:AddItemToList(self.editbox:GetText(), self.instanceDifficulty, "", "None", "") end)
    addGroup:AddChild(addButton)

    self.mainFrame:AddChild(addGroup)

    local itemGroup = AceGUI:Create("InlineGroup")
    itemGroup:SetLayout("Flow")
    itemGroup:SetRelativeWidth(1.0)
    itemGroup:SetFullHeight(true)

    local listGroup = AceGUI:Create("InlineGroup")
    listGroup:SetFullHeight(true)
    listGroup:SetLayout("Fill")
    listGroup:SetRelativeWidth(0.5)

    local itemScrollFrame = AceGUI:Create("ScrollFrame")
    itemScrollFrame:SetLayout("Flow")
    listGroup:AddChild(itemScrollFrame)

    self.itemContainer = itemScrollFrame
    local activeProfile = self.db:GetCurrentProfile()
    ItemWishlist:PopulateEntries(activeProfile)

    local showGroup = AceGUI:Create("InlineGroup")
    showGroup:SetFullHeight(true)
    showGroup:SetRelativeWidth(0.5)
    showGroup:SetLayout("Flow")

    self.itemLabel = AceGUI:Create("Label")
    self.itemLabel:SetText("<Select Item>")

    showGroup:AddChild(self.itemLabel)

    self.itemGroupInputField = AceGUI:Create("EditBox")
    self.itemGroupInputField:SetLabel("Set Item Group")
    self.itemGroupInputField:SetWidth(200)
    self.itemGroupInputField:SetCallback("OnEnterPressed", function(widget, event, input) saveItemGroup(widget, input)  end)

    showGroup:AddChild(self.itemGroupInputField)

    self.itemInfoFrame = AceGUI:Create("MultiLineEditBox")
    self.itemInfoFrame:SetText("")
    self.itemInfoFrame:SetNumLines(10)
    self.itemInfoFrame:SetCallback("OnEnterPressed", function(widget, event, input) saveInfoFrameChanges(widget,input) end)

    showGroup:AddChild(self.itemInfoFrame)

    self.tooltipTagInputField = AceGUI:Create("EditBox")
    self.tooltipTagInputField:SetLabel("Set Tooltip Tag")
    self.tooltipTagInputField:SetWidth(200)
    self.tooltipTagInputField:SetMaxLetters(30)
    self.tooltipTagInputField:SetCallback("OnEnterPressed", function(widget, event, tag) saveTooltipTag(widget, tag)  end)

    showGroup:AddChild(self.tooltipTagInputField)
    showGroup:DoLayout()

    itemGroup:AddChild(listGroup)
    itemGroup:AddChild(showGroup)
    itemGroup:DoLayout()

    self.mainFrame:AddChild(itemGroup)

    self.mainFrame:Show()
end

function ItemWishlist:PopulateEntries(activeProfile)
    self.itemContainer:ReleaseChildren()

    if self.db.profiles[activeProfile] then
        local itemList = self.db.profiles[activeProfile]["itemList"]
        local itemGroups = {}
        local itemsWithoutGroups = {}
        if itemList and tablelength(itemList) >0 then
            for itemName,itemData in pairsByKeys(self.db.profiles[activeProfile]["itemList"]) do
                local labelGroup = AceGUI:Create("SimpleGroup")
                local label = AceGUI:Create("InteractiveLabel")
                label.width = "fill"
                local p, h, f = label.label:GetFont()
                label:SetFont(p, 12, f)
                label:SetCallback("OnEnter", onEnter)
                label:SetCallback("OnLeave", onLeave)
                label:SetCallback("OnClick", itemLabelOnClick)
                label:SetText(itemData["itemLink"])
                label.userdata.itemLink = itemData["itemLink"]
                label.userdata.itemName = itemName

                labelGroup:AddChild(label)
                if not itemData.group or itemData.group == "" then itemData.group = "None" end
                if not itemData.tooltipTag then itemData.tooltipTag="" end

                if itemData.group == "None" then
                    table.insert(itemsWithoutGroups, labelGroup)
                elseif not itemGroups[itemData.group] then
                    itemGroups[itemData.group] = {labelGroup}
                else
                    table.insert(itemGroups[itemData.group], labelGroup)
                end
            end

            for i, labelGroup in pairs(itemsWithoutGroups) do
                    self.itemContainer:AddChild(labelGroup)
            end

            for itemGroup, itemLabelGroups in pairsByKeys(itemGroups) do
                local group = AceGUI:Create("SimpleGroup")
                local label = AceGUI:Create("InteractiveLabel")
                label.width = "fill"
                local p, h, f = label.label:GetFont()
                label:SetFont(p, 14, f)
                label:SetColor(0.8, 0.6, 0)
                local textFiller = string.rep("-", 12-string.len(itemGroup)/2)
                label:SetText("\n"..textFiller .. itemGroup .. textFiller.."\n")
                group:AddChild(label)
                self.itemContainer:AddChild(group)

                for i,labelGroup in pairs(itemLabelGroups) do
                    self.itemContainer:AddChild(labelGroup)
                end
            end
        end
    end
end

------------------------------------------------------------------------------------------------
-- slash commands

-- Slash commands to toggle mainFrame
function ItemWishlist:ToggleFrame()
    if not ItemWishlist:IsOpen() then
        ItemWishlist:CreateFrame()
    else
        ItemWishlist:closeWindow()
    end
end
