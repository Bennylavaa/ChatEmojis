local addonName, addon = ...
addon.M = [[Interface\AddOns\ChatEmojis\Media\]]

-- Default settings
addon.defaults = {
    emojiSize = 16,
    enabled = true,
    textEmotes = true,
    bubbleEmojis = true,
}

-- Get current emoji size with formatting
function addon:GetEmojiSizeString()
    local size = ChatEmojisDB and ChatEmojisDB.emojiSize or 16
    return ":" .. size .. ":" .. size
end

-- Storage for our emoji mappings
addon.Smileys = {}

-- Function to create texture strings
function addon:TextureString(texString, dataString)
    return "|T"..texString..(dataString or "").."|t"
end

-- Process chat message to insert emojis
function addon:InsertEmotions(msg)
    if not ChatEmojisDB.enabled then return msg end

    local Smileys = self.Smileys
    local EscapeString = self.EscapeString
    local matches = {}
    local totalEmojiCount = 0

    for word in string.gmatch(msg, "%s-(%S+)%s*") do
        local lowerWord = string.lower(word)
        local pattern = EscapeString(self, lowerWord)
        local emoji = Smileys[pattern]

        if emoji then
            totalEmojiCount = totalEmojiCount + 1
            table.insert(matches, {word = word, emoji = emoji})
        end
    end

    if totalEmojiCount == 0 then return msg end

    local emojiSize = self:GetSmartDynamicEmojiSize(totalEmojiCount)

    local sizeData = string.format(":%d:%d", emojiSize, emojiSize)

    for _, match in ipairs(matches) do
        local base = match.emoji:match("|T(.-):%d+:%d+|t")
        if base then
            local replacement = "|T" .. base .. sizeData .. "|t"
            local pattern = EscapeString(self, match.word)
            msg = string.gsub(msg, pattern, replacement)
        end
    end

    return msg
end

function addon:GetAdvancedDynamicEmojiSize(count)
    local baseSize
    local userSize = ChatEmojisDB and ChatEmojisDB.emojiSize or 16

    if count == 1 then
        baseSize = userSize  -- Full size for single emoji
    elseif count == 2 then
        baseSize = math.floor(userSize * 0.875)  -- 87.5% for 2 emojis
    elseif count == 3 then
        baseSize = math.floor(userSize * 0.75)   -- 75% for 3 emojis
    elseif count <= 5 then
        baseSize = math.floor(userSize * 0.625)  -- 62.5% for 4-5 emojis
    elseif count <= 8 then
        baseSize = math.floor(userSize * 0.5)    -- 50% for 6-8 emojis
    elseif count <= 12 then
        baseSize = math.floor(userSize * 0.375)  -- 37.5% for 9-12 emojis
    else
        baseSize = math.floor(userSize * 0.25)   -- 25% for emoji spam (13+)
    end

    return math.max(baseSize, 6)
end

function addon:GetSmartDynamicEmojiSize(count, approximateLineWidth)
    local userSize = ChatEmojisDB and ChatEmojisDB.emojiSize or 16
    local maxEmojiWidth = approximateLineWidth or 400

    local idealSizeForLine = math.floor(maxEmojiWidth / (count * 1.2))

    local dynamicSize = self:GetAdvancedDynamicEmojiSize(count)
    local finalSize = math.min(dynamicSize, idealSizeForLine)

    return math.max(finalSize, 6)
end

-- Helper function to escape special characters
function addon:EscapeString(str)
    return string.gsub(str, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
end

-- Process the entire message for emojis
function addon:GetSmileyReplacementText(msg)
    if not ChatEmojisDB.enabled or not msg then return msg end

    -- Skip processing for certain types of messages
    if string.find(msg, "/run") or string.find(msg, "/dump") or string.find(msg, "/script") then
        return msg
    end

    local origlen = string.len(msg)
    local startpos = 1
    local outstr = ""
    local _, pos, endpos

    while startpos <= origlen do
        pos = string.find(msg, "|H", startpos, true)
        endpos = pos or origlen
        outstr = outstr .. self:InsertEmotions(string.sub(msg, startpos, endpos))
        startpos = endpos + 1

        if pos then
            _, endpos = string.find(msg, "|h.-|h", startpos)
            endpos = endpos or origlen

            if startpos < endpos then
                outstr = outstr .. string.sub(msg, startpos, endpos)
                startpos = endpos + 1
            end
        end
    end

    return outstr
end

-- Main chat filter function to intercept and process messages
function addon:ChatFilter(frame, event, msg, author, ...)
    if not ChatEmojisDB.enabled or not msg or msg == "" then
        return false, msg, author, ...
    end

    msg = addon:GetSmileyReplacementText(msg)
    return false, msg, author, ...
end

-- Initialize the addon
function addon:Initialize()
    self:InitSettings()

    -- Setup emojis and options
    self:SetupDefaultEmojis()
    self:CreateOptions()
    self:SetupSettingsCommands()
    self:SetupChatAutoCompletion()
    self:InitializeBubbleProcessing()

    -- Register chat events
    local events = {
        "CHAT_MSG_WHISPER",
        "CHAT_MSG_WHISPER_INFORM",
        "CHAT_MSG_BN_WHISPER",
        "CHAT_MSG_BN_WHISPER_INFORM",
        "CHAT_MSG_GUILD",
        "CHAT_MSG_OFFICER",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_RAID_WARNING",
        "CHAT_MSG_BATTLEGROUND",
        "CHAT_MSG_BATTLEGROUND_LEADER",
        "CHAT_MSG_CHANNEL",
        "CHAT_MSG_SAY",
        "CHAT_MSG_YELL",
        "CHAT_MSG_EMOTE",
        "CHAT_MSG_TEXT_EMOTE",
        "CHAT_MSG_AFK",
        "CHAT_MSG_DND"
    }

    for _, event in ipairs(events) do
        ChatFrame_AddMessageEventFilter(event, function(...)
            return addon:ChatFilter(...)
        end)
    end

    local setupFrame = CreateFrame("Frame")
    setupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    setupFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            local timerFrame = CreateFrame("Frame")
            timerFrame.elapsed = 0
            timerFrame:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = self.elapsed + elapsed
                if self.elapsed > 1 then
                    addon:CreateChatFrameButton()
                    self:SetScript("OnUpdate", nil)
                end
            end)
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        end
    end)
end

function addon:CreateGameMenuButton()
    if not GameMenuFrame then
        return false
    end

    if _G["GameMenuButtonEmojiBrowser"] then
        return true
    end

    local button = CreateFrame("Button", "GameMenuButtonEmojiBrowser", GameMenuFrame, "GameMenuButtonTemplate")
    button:SetText("|cFF00CCFFEmoji|r |cFFFF6600Browser|r")

    -- List of known addon buttons that might exist
    local addonButtonNames = {
        "ElvUI_MenuButton",
        "GameMenuButtonRatings",
        "GameMenuButtonAddOns"
    }

    -- Find the last (visually lowest) addon button that exists
    local lowestAddonButton = nil
    local lowestY = math.huge

    for _, btnName in ipairs(addonButtonNames) do
        local btn = _G[btnName]
        if btn and btn:IsVisible() then
            local _, _, _, _, y = btn:GetPoint()
            if y and y < lowestY then
                lowestY = y
                lowestAddonButton = btn
            end
        end
    end

    local referenceButton = lowestAddonButton or GameMenuButtonMacros

    if referenceButton and referenceButton:IsVisible() then
        button:SetPoint("TOP", referenceButton, "BOTTOM", 0, -1)
        button:SetWidth(referenceButton:GetWidth())
        button:SetHeight(referenceButton:GetHeight())
    else
        local width, height = 0, 0
        for _, btnName in ipairs({"GameMenuButtonOptions", "GameMenuButtonUIOptions", "GameMenuButtonKeybindings", "GameMenuButtonLogout"}) do
            local refBtn = _G[btnName]
            if refBtn then
                width = refBtn:GetWidth()
                height = refBtn:GetHeight()
                break
            end
        end
        if width > 0 and height > 0 then
            button:SetSize(width, height)
        else
            button:SetSize(144, 16)
        end

        local logoutButton = GameMenuButtonLogout
        if logoutButton then
            button:SetPoint("BOTTOM", logoutButton, "TOP", 0, 1)
        else
            button:SetPoint("CENTER", GameMenuFrame, "CENTER", 0, -40)
        end
    end

    local logoutButton = GameMenuButtonLogout
    if logoutButton then
        logoutButton:ClearAllPoints()
        logoutButton:SetPoint("TOP", button, "BOTTOM", 0, -(button:GetHeight() + 1))

        local exitButton = GameMenuButtonExitGame or GameMenuButtonQuit
        if exitButton and exitButton ~= logoutButton then
            exitButton:ClearAllPoints()
            exitButton:SetPoint("TOP", logoutButton, "BOTTOM", 0, -1)
        end
    end

    button:SetScript("OnClick", function()
        PlaySound("igMainMenuOption")
        HideUIPanel(GameMenuFrame)
        addon:ToggleEmojiBrowser()
    end)

    GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + button:GetHeight() + 25)
    return true
end

local setupHookFrame = CreateFrame("Frame")
setupHookFrame.hooked = false
setupHookFrame:SetScript("OnUpdate", function(self, elapsed)
    if GameMenuFrame and not self.hooked then
        local originalShow = GameMenuFrame:GetScript("OnShow")
        GameMenuFrame:SetScript("OnShow", function(...)
            if originalShow then originalShow(...) end
            addon:CreateGameMenuButton()
        end)
        self.hooked = true
        self:SetScript("OnUpdate", nil)
    end
end)

-- Slash commands
SLASH_CHATEMOJIS1 = "/emoji"
SLASH_CHATEMOJIS2 = "/emojis"
SLASH_CHATEMOJIS3 = "/chatemojis"
SLASH_CHATEMOJIS4 = "/ce"

SlashCmdList["CHATEMOJIS"] = function(msg)
    InterfaceOptionsFrame_OpenToCategory("ChatEmojis")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        addon:Initialize()
    end
end)