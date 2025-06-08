-- AutoQuestAccept - Automatically accepts and completes quests
-- Compatible with World of Warcraft 1.12 (Vanilla)

-- Variables
local enabled = true
local debug = false
local autoComplete = true -- New variable for auto-complete functionality

-- Create the main frame
local AutoQuestAccept = CreateFrame("Frame", "AutoQuestAcceptFrame")

-- Function to safely print debug messages
local function DebugPrint(msg)
    if debug and msg then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[AutoQuestAccept]|r " .. tostring(msg))
    end
end

-- Function to print messages to chat
local function Print(msg)
    if msg then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[AutoQuestAccept]|r " .. tostring(msg))
    end
end

-- Function to auto-accept quests when Accept/Decline dialog is open
local function AutoAcceptQuest()
    if not enabled then
        return
    end
    
    -- Check if quest dialog is open with Accept/Decline buttons
    if QuestFrame and QuestFrame:IsVisible() and QuestFrameAcceptButton then
        if QuestFrameAcceptButton:IsVisible() and QuestFrameAcceptButton:IsEnabled() then
            local questTitle = GetTitleText() or "Unknown Quest"
            DebugPrint("Auto-accepting quest: " .. questTitle)
            AcceptQuest()
        end
    end
end

-- Function to auto-complete quests when Complete Quest dialog is open
local function AutoCompleteQuest()
    if not enabled or not autoComplete then
        return
    end
    
    DebugPrint("Checking for quest completion...")
    
    -- Check if quest dialog is open
    if not (QuestFrame and QuestFrame:IsVisible()) then
        return
    end
    
    -- Get quest info to help determine state
    local questTitle = GetTitleText() or "Unknown Quest"
    local numChoices = GetNumQuestChoices()
    local numRewards = GetNumQuestRewards()
    
    DebugPrint("Quest: " .. questTitle .. " | Choices: " .. tostring(numChoices) .. " | Rewards: " .. tostring(numRewards))
    
    -- Priority 1: Check for "Continue" button (dialogue/story quests)
    if QuestFrameContinueButton and QuestFrameContinueButton:IsVisible() and QuestFrameContinueButton:IsEnabled() then
        DebugPrint("Found Continue button - clicking it")
        QuestFrameContinueButton:Click()
        return
    end
    
    -- Priority 2: Check for "Complete Quest" button (quest selection phase)
    if QuestFrameCompleteButton and QuestFrameCompleteButton:IsVisible() and QuestFrameCompleteButton:IsEnabled() then
        DebugPrint("Found Complete Quest button - clicking it")
        QuestFrameCompleteButton:Click()
        return
    end
    
    -- Priority 3: We're in the final reward phase - check if we should auto-complete
    if GetQuestReward then
        -- Don't auto-complete if there are multiple reward choices
        if numChoices and numChoices > 1 then
            DebugPrint("Multiple reward choices (" .. numChoices .. "), skipping auto-complete")
            return
        end
        
        -- Check if we're actually in a completion state by testing if GetQuestReward works
        DebugPrint("Attempting GetQuestReward() - Final completion phase")
        GetQuestReward()
        return
    end
    
    DebugPrint("No completion action available")
end

-- Minimap button
local minimapButton = CreateFrame("Button", "AutoQuestAcceptMinimapButton", Minimap)
minimapButton:SetWidth(20)
minimapButton:SetHeight(20)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)

-- Set button textures (smaller icon)
minimapButton:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")
minimapButton:SetPushedTexture("Interface\\Icons\\INV_Misc_QuestionMark")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Make the textures fit the smaller button
local normalTexture = minimapButton:GetNormalTexture()
if normalTexture then
    normalTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Crop edges for cleaner look
end

local pushedTexture = minimapButton:GetPushedTexture()
if pushedTexture then
    pushedTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
end

-- Position on minimap (initial position on the edge)
local angle = math.rad(45) -- 45 degrees (top-right)
local x = math.cos(angle) * 80
local y = math.sin(angle) * 80
minimapButton:SetPoint("CENTER", "Minimap", "CENTER", x, y)

-- Make it draggable around the minimap
minimapButton:EnableMouse(true)
minimapButton:SetMovable(true)
minimapButton:RegisterForDrag("LeftButton")

local isDragging = false

-- Update minimap button position when dragging
local function UpdateMinimapButtonPosition()
    local button = minimapButton
    if not button then return end
    
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    
    px, py = px / scale, py / scale
    
    local angle = math.atan2(py - my, px - mx)
    local x = math.cos(angle) * 80 -- Distance from center
    local y = math.sin(angle) * 80
    
    button:ClearAllPoints()
    button:SetPoint("CENTER", "Minimap", "CENTER", x, y)
end

minimapButton:SetScript("OnDragStart", function()
    isDragging = true
    this:SetScript("OnUpdate", UpdateMinimapButtonPosition)
end)

minimapButton:SetScript("OnDragStop", function()
    isDragging = false
    this:SetScript("OnUpdate", nil)
end)

-- Configuration panel
local configFrame = CreateFrame("Frame", "AutoQuestAcceptConfig", UIParent)
configFrame:SetWidth(300)
configFrame:SetHeight(250) -- Increased height for new option
configFrame:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)
configFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
configFrame:SetBackdropColor(0, 0, 0, 1)
configFrame:Hide()
configFrame:SetMovable(true)
configFrame:EnableMouse(true)
configFrame:SetScript("OnMouseDown", function() configFrame:StartMoving() end)
configFrame:SetScript("OnMouseUp", function() configFrame:StopMovingOrSizing() end)

-- Config frame title
local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", configFrame, "TOP", 0, -15)
title:SetText("AutoQuestAccept Configuration")

-- Enable/Disable checkbox
local enableCheck = CreateFrame("CheckButton", "AutoQuestAcceptEnableCheck", configFrame, "UICheckButtonTemplate")
enableCheck:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, -50)
enableCheck:SetWidth(24)
enableCheck:SetHeight(24)
enableCheck:SetChecked(enabled)

local enableLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
enableLabel:SetPoint("LEFT", enableCheck, "RIGHT", 5, 0)
enableLabel:SetText("Enable Auto Quest Accept")

enableCheck:SetScript("OnClick", function()
    enabled = this:GetChecked()
    if enabled then
        Print("Auto quest accept enabled")
    else
        Print("Auto quest accept disabled")
    end
end)

-- Auto Complete checkbox
local completeCheck = CreateFrame("CheckButton", "AutoQuestCompleteCheck", configFrame, "UICheckButtonTemplate")
completeCheck:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, -80)
completeCheck:SetWidth(24)
completeCheck:SetHeight(24)
completeCheck:SetChecked(autoComplete)

local completeLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
completeLabel:SetPoint("LEFT", completeCheck, "RIGHT", 5, 0)
completeLabel:SetText("Enable Auto Quest Complete")

completeCheck:SetScript("OnClick", function()
    autoComplete = this:GetChecked()
    if autoComplete then
        Print("Auto quest complete enabled")
    else
        Print("Auto quest complete disabled")
    end
end)

-- Debug checkbox
local debugCheck = CreateFrame("CheckButton", "AutoQuestAcceptDebugCheck", configFrame, "UICheckButtonTemplate")
debugCheck:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, -110)
debugCheck:SetWidth(24)
debugCheck:SetHeight(24)
debugCheck:SetChecked(debug)

local debugLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
debugLabel:SetPoint("LEFT", debugCheck, "RIGHT", 5, 0)
debugLabel:SetText("Enable Debug Messages")

debugCheck:SetScript("OnClick", function()
    debug = this:GetChecked()
    if debug then
        Print("Debug mode enabled")
    else
        Print("Debug mode disabled")
    end
end)

-- Test accept button
local testAcceptButton = CreateFrame("Button", "AutoQuestAcceptTestButton", configFrame, "UIPanelButtonTemplate")
testAcceptButton:SetWidth(100)
testAcceptButton:SetHeight(24)
testAcceptButton:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, -140)
testAcceptButton:SetText("Test Accept")
testAcceptButton:SetScript("OnClick", function()
    Print("Testing manual quest accept...")
    AutoAcceptQuest()
end)

-- Test complete button
local testCompleteButton = CreateFrame("Button", "AutoQuestCompleteTestButton", configFrame, "UIPanelButtonTemplate")
testCompleteButton:SetWidth(100)
testCompleteButton:SetHeight(24)
testCompleteButton:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 130, -140)
testCompleteButton:SetText("Test Complete")
testCompleteButton:SetScript("OnClick", function()
    Print("Testing manual quest complete...")
    
    -- Use the same logic as the automatic version but simpler
    if QuestFrame and QuestFrame:IsVisible() then
        -- First check for Continue button
        if QuestFrameContinueButton and QuestFrameContinueButton:IsVisible() and QuestFrameContinueButton:IsEnabled() then
            DebugPrint("Clicking Continue button")
            QuestFrameContinueButton:Click()
        -- If we're in quest selection phase, click Complete Quest button
        elseif QuestFrameCompleteButton and QuestFrameCompleteButton:IsVisible() and QuestFrameCompleteButton:IsEnabled() then
            DebugPrint("Clicking Complete Quest button")
            QuestFrameCompleteButton:Click()
        -- If we're in reward phase, call GetQuestReward
        elseif GetQuestReward then
            DebugPrint("Calling GetQuestReward()")
            GetQuestReward()
        end
    else
        Print("No quest dialog open")
    end
end)

-- Close button
local closeButton = CreateFrame("Button", "AutoQuestAcceptCloseButton", configFrame, "UIPanelButtonTemplate")
closeButton:SetWidth(60)
closeButton:SetHeight(24)
closeButton:SetPoint("BOTTOM", configFrame, "BOTTOM", 0, 20)
closeButton:SetText("Close")
closeButton:SetScript("OnClick", function()
    configFrame:Hide()
end)

-- Function to toggle config panel
local function ToggleConfigPanel()
    if configFrame:IsVisible() then
        configFrame:Hide()
    else
        configFrame:Show()
        -- Update checkbox states
        enableCheck:SetChecked(enabled)
        completeCheck:SetChecked(autoComplete)
        debugCheck:SetChecked(debug)
    end
end

-- Enhanced OnUpdate handler to check for both quest accept and complete dialogs
local function OnUpdate()
    if not enabled then
        AutoQuestAccept.lastAcceptCheck = false
        AutoQuestAccept.lastActionTime = nil
        return
    end
    
    if QuestFrame and QuestFrame:IsVisible() then
        local currentTime = GetTime()
        
        -- Check for quest accept
        if QuestFrameAcceptButton and QuestFrameAcceptButton:IsVisible() and QuestFrameAcceptButton:IsEnabled() then
            if not AutoQuestAccept.lastAcceptCheck then
                AutoQuestAccept.lastAcceptCheck = true
                AutoAcceptQuest()
            end
        else
            AutoQuestAccept.lastAcceptCheck = false
        end
        
        -- Check for quest complete with throttling
        if autoComplete then
            -- Only check every 0.5 seconds to avoid spam
            if not AutoQuestAccept.lastActionTime or (currentTime - AutoQuestAccept.lastActionTime) > 0.5 then
                -- Check if any completion action is needed
                local needsAction = false
                
                if QuestFrameContinueButton and QuestFrameContinueButton:IsVisible() and QuestFrameContinueButton:IsEnabled() then
                    needsAction = true
                    DebugPrint("OnUpdate: Continue button available")
                elseif QuestFrameCompleteButton and QuestFrameCompleteButton:IsVisible() and QuestFrameCompleteButton:IsEnabled() then
                    needsAction = true
                    DebugPrint("OnUpdate: Complete Quest button available")
                elseif GetQuestReward then
                    -- Check if we're in final completion state
                    local questTitle = GetTitleText()
                    local numChoices = GetNumQuestChoices()
                    if questTitle and questTitle ~= "" and (not numChoices or numChoices <= 1) then
                        needsAction = true
                        DebugPrint("OnUpdate: Final completion state detected")
                    end
                end
                
                if needsAction then
                    AutoQuestAccept.lastActionTime = currentTime
                    AutoCompleteQuest()
                end
            end
        end
    else
        AutoQuestAccept.lastAcceptCheck = false
        AutoQuestAccept.lastActionTime = nil
    end
end

-- Event handler for addon loading
local function OnEvent(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "AutoQuestAccept" then
        Print("Loaded! Type /aqa for commands.")
        DebugPrint("Addon loaded successfully")
        
        -- Show minimap button
        minimapButton:Show()
        Print("Minimap button created and shown")
    end
end

-- Register events and handlers
AutoQuestAccept:RegisterEvent("ADDON_LOADED")
AutoQuestAccept:SetScript("OnEvent", OnEvent)
AutoQuestAccept:SetScript("OnUpdate", OnUpdate)

-- Minimap button event handlers
minimapButton:SetScript("OnClick", function()
    if not isDragging then
        if arg1 == "LeftButton" then
            ToggleConfigPanel()
        elseif arg1 == "RightButton" then
            enabled = not enabled
            if enabled then
                Print("Auto quest accept/complete enabled")
            else
                Print("Auto quest accept/complete disabled")
            end
        end
    end
end)

minimapButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("AutoQuestAccept", 1, 1, 1)
    GameTooltip:AddLine("Left-click: Open config", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right-click: Toggle on/off", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Drag: Move around minimap", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Accept: " .. (enabled and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"), 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Complete: " .. (autoComplete and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"), 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

-- Enhanced slash command handler
local function SlashCommandHandler(msg)
    local command = ""
    if msg then
        command = string.lower(msg)
    end
    
    if command == "on" or command == "enable" then
        enabled = true
        Print("Auto quest accept/complete enabled")
        
    elseif command == "off" or command == "disable" then
        enabled = false
        Print("Auto quest accept/complete disabled")
        
    elseif command == "toggle" then
        enabled = not enabled
        if enabled then
            Print("Auto quest accept/complete enabled")
        else
            Print("Auto quest accept/complete disabled")
        end
        
    elseif command == "complete" then
        autoComplete = not autoComplete
        if autoComplete then
            Print("Auto quest complete enabled")
        else
            Print("Auto quest complete disabled")
        end
        
    elseif command == "debug" then
        debug = not debug
        if debug then
            Print("Debug mode enabled")
        else
            Print("Debug mode disabled")
        end
        
    elseif command == "config" or command == "show" then
        ToggleConfigPanel()
        
    elseif command == "minimap" then
        if minimapButton:IsVisible() then
            minimapButton:Hide()
            Print("Minimap button hidden")
        else
            minimapButton:Show()
            Print("Minimap button shown")
        end
        
    elseif command == "reset" then
        -- Reset to edge position (45 degrees)
        local angle = math.rad(45)
        local x = math.cos(angle) * 80
        local y = math.sin(angle) * 80
        minimapButton:ClearAllPoints()
        minimapButton:SetPoint("CENTER", "Minimap", "CENTER", x, y)
        minimapButton:Show()
        Print("Minimap button reset to default position")
        
    elseif command == "test" then
        Print("Testing manual quest accept...")
        AutoAcceptQuest()
        
    elseif command == "testcomplete" then
        Print("Testing manual quest complete...")
        AutoCompleteQuest()
        
    elseif command == "status" then
        local statusText = enabled and "enabled" or "disabled"
        local completeText = autoComplete and "enabled" or "disabled"
        local debugText = debug and "enabled" or "disabled"
        Print("Accept: " .. statusText)
        Print("Complete: " .. completeText)
        Print("Debug: " .. debugText)
        
    else
        Print("Commands:")
        Print("  /aqa on|enable - Enable auto quest accept/complete")
        Print("  /aqa off|disable - Disable auto quest accept/complete")
        Print("  /aqa toggle - Toggle on/off")
        Print("  /aqa complete - Toggle auto-complete only")
        Print("  /aqa config|show - Open configuration panel")
        Print("  /aqa minimap - Toggle minimap button")
        Print("  /aqa reset - Reset minimap button position")
        Print("  /aqa test - Manually test quest accept")
        Print("  /aqa testcomplete - Manually test quest complete")
        Print("  /aqa debug - Toggle debug messages")
        Print("  /aqa status - Show current status")
    end
end

-- Register slash commands
SLASH_AUTOQUESTACCEPT1 = "/aqa"
SLASH_AUTOQUESTACCEPT2 = "/autoquestaccept"
SlashCmdList["AUTOQUESTACCEPT"] = SlashCommandHandler