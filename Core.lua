local addonName, addon = ...
addon.M = [[Interface\AddOns\ChatEmojis\Media\]]

local emojiBrowser
local searchBox
local scrollFrame
local emojiContainer
local MAX_EMOJIS_PER_ROW = 10
local EMOJI_BUTTON_SIZE = 32
local EMOJI_PADDING = 5

-- Default settings
addon.defaults = {
    emojiSize = 16,
    enabled = true,
    textEmotes = true,
}

-- Get current emoji size with formatting
function addon:GetEmojiSizeString()
    return ":" .. self.currentSize .. ":" .. self.currentSize
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

    -- Cache table lookups for better performance
    local Smileys = self.Smileys
    local EscapeString = self.EscapeString

    for word in string.gmatch(msg, "%s-(%S+)%s*") do
        local pattern = EscapeString(self, word)
        local emoji

        -- If it looks like an emoji code (:word:), try lowercase matching
        if string.match(word, "^:[%w_]+:$") then
            local lowercaseWord = string.lower(word)
            local lowercasePattern = EscapeString(self, lowercaseWord)
            emoji = Smileys[lowercasePattern]
        else
            emoji = Smileys[pattern]
        end

        if emoji then
            pattern = string.format("%s%s%s", "([%s%p]-)", pattern, "([%s%p]*)")

            if string.match(msg, pattern) then
                msg = string.gsub(msg, pattern, string.format("%s%s%s", "%1", emoji, "%2"))
            end
        end
    end

    return msg
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
                if self.elapsed > 1 then  -- 1 second delay
                    addon:CreateChatFrameButton()
                    self:SetScript("OnUpdate", nil)
                end
            end)
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        end
    end)

    -- Add button to game menu
    if GameMenuFrame then
        local button = CreateFrame("Button", "GameMenuButtonEmojiBrowser", GameMenuFrame, "GameMenuButtonTemplate")
        button:SetText("|cFF00CCFFEmoji|r |cFFFF6600Browser|r")

        local macrosButton = GameMenuButtonMacros
        if macrosButton then
            button:SetPoint("TOP", macrosButton, "BOTTOM", 0, -1)
            local logoutButton = GameMenuButtonLogout

            if logoutButton then
                local point, relativeTo, relativePoint, xOffset, yOffset = logoutButton:GetPoint()
                logoutButton:ClearAllPoints()
                logoutButton:SetPoint("TOP", button, "BOTTOM", 0, -1)

                local exitButton = GameMenuButtonExitGame or GameMenuButtonQuit
                if exitButton and exitButton ~= logoutButton then
                    exitButton:ClearAllPoints()
                    exitButton:SetPoint("TOP", logoutButton, "BOTTOM", 0, -1)
                end
            end

            button:SetWidth(macrosButton:GetWidth())
            button:SetHeight(macrosButton:GetHeight())
        else
            local width, height = 0, 0
            local referenceButton

            for _, btnName in ipairs({"GameMenuButtonOptions", "GameMenuButtonUIOptions", "GameMenuButtonKeybindings", "GameMenuButtonLogout"}) do
                referenceButton = _G[btnName]
                if referenceButton then
                    width = referenceButton:GetWidth()
                    height = referenceButton:GetHeight()
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

        button:SetScript("OnClick", function()
            PlaySound("igMainMenuOption")
            HideUIPanel(GameMenuFrame)
            addon:ToggleEmojiBrowser()
        end)

        local height = GameMenuFrame:GetHeight()
        GameMenuFrame:SetHeight(height + button:GetHeight() + 1)
    end

    -- Print loading message
    print("|cFF00CCFFChat|r|cFFFF6600Emojis|r: Addon loaded!")
end

-- Slash commands
SLASH_CHATEMOJIS1 = "/emoji"
SLASH_CHATEMOJIS2 = "/emojis"
SLASH_CHATEMOJIS3 = "/chatemojis"
SLASH_CHATEMOJIS4 = "/ce"

SlashCmdList["CHATEMOJIS"] = function(msg)
    InterfaceOptionsFrame_OpenToCategory("ChatEmojis")
end

-- Create the emoji browser window
function addon:CreateEmojiBrowser()
    if emojiBrowser then return end

    -- Main frame
    emojiBrowser = CreateFrame("Frame", "ChatEmojisEmojiFrame", UIParent)
    emojiBrowser:SetSize(400, 500)
    emojiBrowser:SetPoint("CENTER", UIParent, "CENTER")
    emojiBrowser:SetFrameStrata("DIALOG")
    emojiBrowser:SetFrameLevel(1)
    emojiBrowser:EnableMouse(true)
    emojiBrowser:SetMovable(true)
    emojiBrowser:SetClampedToScreen(true)
    emojiBrowser:RegisterForDrag("LeftButton")
    emojiBrowser:SetScript("OnDragStart", emojiBrowser.StartMoving)
    emojiBrowser:SetScript("OnDragStop", emojiBrowser.StopMovingOrSizing)
    emojiBrowser:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- Header
    local header = emojiBrowser:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetWidth(300)
    header:SetHeight(64)
    header:SetPoint("TOP", 0, 12)

    local title = emojiBrowser:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    title:SetText("|cFF00CCFFEmoji|r |cFFFF6600Browser")

    -- Close button
    local closeButton = CreateFrame("Button", nil, emojiBrowser, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)

    -- Settings button
    local settingsButton = CreateFrame("Button", "ChatEmojisSettingsButton", emojiBrowser, "GameMenuButtonTemplate")
    settingsButton:SetSize(16, 16)
    settingsButton:SetPoint("TOPLEFT", emojiBrowser, "TOPLEFT", 12, -12)

    local iconTexture = settingsButton:CreateTexture(nil, "ARTWORK")
    iconTexture:SetSize(8, 8)
    iconTexture:SetPoint("CENTER")
    iconTexture:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")  -- This is a cog/settings-like texture

    settingsButton:SetScript("OnClick", function()
        PlaySound("igMainMenuOption")
        InterfaceOptionsFrame_OpenToCategory("ChatEmojis")
        emojiBrowser:Hide()
    end)

    -- Search box
    local searchLabel = emojiBrowser:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    searchLabel:SetPoint("TOPLEFT", 20, -30)
    searchLabel:SetText("|cFFFFD100Search:|r")

    local searchBoxBg = CreateFrame("Frame", "ChatEmojisSearchBoxBg", emojiBrowser)
    searchBoxBg:SetPoint("TOPLEFT", searchLabel, "TOPRIGHT", 10, 2)
    searchBoxBg:SetPoint("RIGHT", emojiBrowser, "RIGHT", -30, 0)
    searchBoxBg:SetHeight(22)
    searchBoxBg:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    searchBoxBg:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    searchBoxBg:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)

    searchBox = CreateFrame("EditBox", "ChatEmojisSearchBox", searchBoxBg)
    searchBox:SetPoint("TOPLEFT", searchBoxBg, "TOPLEFT", 6, -1)
    searchBox:SetPoint("BOTTOMRIGHT", searchBoxBg, "BOTTOMRIGHT", -20, 1)
    searchBox:SetFontObject("GameFontHighlight")
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function()
        if scrollFrame and emojiContainer then
            addon:UpdateEmojiDisplay()
        end
    end)
    searchBox:SetScript("OnEscapePressed", function()
        searchBox:ClearFocus()
        emojiBrowser:Hide()
    end)
    searchBox:SetScript("OnEnterPressed", function()
        searchBox:ClearFocus()
    end)

    local searchIcon = searchBoxBg:CreateTexture(nil, "OVERLAY")
    searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    searchIcon:SetSize(14, 14)
    searchIcon:SetPoint("RIGHT", searchBoxBg, "RIGHT", -5, 0)
    searchIcon:SetVertexColor(0.8, 0.8, 0.8)

    -- Category buttons
    local categoryButtons = {}
    local categories = {
        {"All", nil},
        {"Favs", "Favorites"},
        {"Standard", "Emojis"},
        {"Discord", "DiscordEmojis"},
        {"Pepe", "PepeEmojis"},
        {"WoW", "WoWEmojis"},
        {"Gnome", "GnomeEmojis"},
        {"Pony", "PonyEmojis"}
    }

    local categoryContainer = CreateFrame("Frame", "ChatEmojisCategoryContainer", emojiBrowser)
    categoryContainer:SetPoint("TOPLEFT", searchLabel, "BOTTOMLEFT", 0, -10)
    categoryContainer:SetPoint("RIGHT", emojiBrowser, "RIGHT", -30, 0)
    categoryContainer:SetHeight(24)

    local categoryBg = categoryContainer:CreateTexture(nil, "BACKGROUND")
    categoryBg:SetAllPoints()
    categoryBg:SetTexture(0.1, 0.1, 0.1, 0.4)

    local containerWidth = categoryContainer:GetWidth()
    local buttonSpacing = 1
    local buttonWidth = (containerWidth - (buttonSpacing * (#categories - 1))) / #categories
    local buttonHeight = 22

    for i, catInfo in ipairs(categories) do
        local catName, catFolder = unpack(catInfo)

        local button = CreateFrame("Button", "ChatEmojisCategory"..i, categoryContainer)
        button:SetSize(buttonWidth, buttonHeight)

        if i == 1 then
            button:SetPoint("LEFT", categoryContainer, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", categoryButtons[i-1], "RIGHT", buttonSpacing, 0)
        end

        local bg = button:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(0.15, 0.15, 0.15, 0.7)
        button.bg = bg

        local border = CreateFrame("Frame", nil, button)
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        border:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8) -- Dark border
        button.border = border

        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture(0.3, 0.3, 0.3, 0.5)
        highlight:SetBlendMode("ADD")
        button:SetHighlightTexture(highlight)

        local btnText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        btnText:SetPoint("CENTER", 0, 0)
        btnText:SetText(catName)
        local fontName, fontSize = btnText:GetFont()
        if fontSize > 9 then
            btnText:SetFont(fontName, 9)
        end
        button.text = btnText

        button.category = catFolder

        local selectedIndicator = button:CreateTexture(nil, "OVERLAY")
        selectedIndicator:SetHeight(3)
        selectedIndicator:SetWidth(buttonWidth - 4)
        selectedIndicator:SetPoint("BOTTOM", button, "BOTTOM", 0, 0)
        selectedIndicator:SetTexture(1, 0.8, 0, 0.8)
        selectedIndicator:Hide()
        button.selectedIndicator = selectedIndicator

        local selectedBg = button:CreateTexture(nil, "BACKGROUND")
        selectedBg:SetAllPoints()
        selectedBg:SetTexture(0.2, 0.2, 0.3, 0.7) -- Slightly bluish dark background
        selectedBg:Hide()
        button.selectedBg = selectedBg

        button:SetScript("OnClick", function()
            addon.currentCategory = button.category
            if scrollFrame and emojiContainer then
                addon:UpdateEmojiDisplay()
            end

            for _, btn in ipairs(categoryButtons) do
                if btn == button then
                    btn.text:SetTextColor(1, 0.8, 0)
                    btn.selectedIndicator:Show()
                    btn.selectedBg:Show()
                    btn.bg:Hide()
                    if btn.border then
                        btn.border:SetBackdropBorderColor(0.7, 0.6, 0.1, 0.9) -- Gold border for selected
                    end
                else
                    btn.text:SetTextColor(1, 1, 1)
                    btn.selectedIndicator:Hide()
                    btn.selectedBg:Hide()
                    btn.bg:Show()
                    if btn.border then
                        btn.border:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8) -- Normal border
                    end
                end
            end
        end)

        table.insert(categoryButtons, button)
    end

    local contentBorder = CreateFrame("Frame", "ChatEmojisContentBorder", emojiBrowser)
    contentBorder:SetPoint("TOPLEFT", categoryContainer, "BOTTOMLEFT", 0, -5)
    contentBorder:SetPoint("BOTTOMRIGHT", emojiBrowser, "BOTTOMRIGHT", -30, 25)
    contentBorder:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    contentBorder:SetBackdropColor(0.1, 0.1, 0.1, 0.6)

    scrollFrame = CreateFrame("ScrollFrame", "ChatEmojisScrollFrame", contentBorder, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", contentBorder, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentBorder, "BOTTOMRIGHT", -26, 8)

    local scrollBar = _G["ChatEmojisScrollFrameScrollBar"]
    if scrollBar then
        scrollBar:SetWidth(16)
    end

    emojiContainer = CreateFrame("Frame", "ChatEmojisContainer", scrollFrame)
    emojiContainer:SetSize(scrollFrame:GetWidth(), 500) -- Initial height
    scrollFrame:SetScrollChild(emojiContainer)

    local instructionsText = emojiBrowser:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    instructionsText:SetPoint("BOTTOM", emojiBrowser, "BOTTOM", 0, 14)
    instructionsText:SetText("Left-click: Insert emoji | Right-click: Toggle favorite")
    instructionsText:SetTextColor(0.8, 0.8, 0.8)

    if categoryButtons and categoryButtons[1] then
        categoryButtons[1]:Click()
    end

    emojiBrowser:Hide()
end

function addon:UpdateEmojiDisplay()
    if not scrollFrame then
        print("|cFFFF0000ChatEmojis Error:|r Failed to update emoji display - scroll frame not initialized")
        return
    end

    if emojiContainer then
        emojiContainer:Hide()
    end

    emojiContainer = CreateFrame("Frame", "ChatEmojisContainer", scrollFrame)
    emojiContainer:SetSize(scrollFrame:GetWidth(), 500) -- Initial height
    scrollFrame:SetScrollChild(emojiContainer)

    local searchText = searchBox and string.lower(searchBox:GetText() or "") or ""
    local displayedEmojis = {}

    for code, texture in pairs(self.Smileys) do
        local emojiName = string.match(code, ":([%w_]+):")

        if emojiName then
            local category = self:GetEmojiCategory(emojiName)

            local categoryMatches = true
            if self.currentCategory == "Favorites" then
                categoryMatches = ChatEmojisDB.favorites[code] == true
            elseif self.currentCategory then
                categoryMatches = self.currentCategory == category
            end

            local searchMatches = searchText == "" or string.find(string.lower(code), searchText)

            if categoryMatches and searchMatches then
                table.insert(displayedEmojis, {code = code, texture = texture, category = category})
            end
        end
    end

    table.sort(displayedEmojis, function(a, b) return a.code < b.code end)

    if #displayedEmojis > 0 then
        local containerWidth = emojiContainer:GetWidth()
        local buttonSize = EMOJI_BUTTON_SIZE
        local padding = EMOJI_PADDING

        local availableWidth = containerWidth - (padding * 2)
        local maxButtonsPerRow = math.floor((availableWidth + padding) / (buttonSize + padding))

        local buttonsPerRow = math.min(maxButtonsPerRow, MAX_EMOJIS_PER_ROW)

        if buttonsPerRow < 5 then buttonsPerRow = 5 end

        local totalButtonWidth = buttonsPerRow * buttonSize + (buttonsPerRow - 1) * padding
        local leftPadding = math.floor((availableWidth - totalButtonWidth) / 2) + padding

        local xOffset = leftPadding
        local yOffset = -padding
        local rowCount = 1

        for i, emoji in ipairs(displayedEmojis) do
            local button = CreateFrame("Button", "ChatEmojisButton"..i, emojiContainer)
            button:SetSize(buttonSize, buttonSize)

            local col = (i - 1) % buttonsPerRow
            if col == 0 and i > 1 then
                xOffset = leftPadding
                yOffset = yOffset - (buttonSize + padding)
                rowCount = rowCount + 1
            else
                xOffset = xOffset + (col > 0 and (buttonSize + padding) or 0)
            end

            button:SetPoint("TOPLEFT", emojiContainer, "TOPLEFT", xOffset, yOffset)

            local bg = button:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture(0.1, 0.1, 0.1, 0.3)

            local border = button:CreateTexture(nil, "BORDER")
            border:SetPoint("TOPLEFT", -1, 1)
            border:SetPoint("BOTTOMRIGHT", 1, -1)
            border:SetTexture(0.3, 0.3, 0.3, 0.5)

            local texture = button:CreateTexture(nil, "ARTWORK")
            texture:SetPoint("TOPLEFT", 2, -2)
            texture:SetPoint("BOTTOMRIGHT", -2, 2)
            texture:SetTexCoord(0, 1, 0, 1)

            local path = string.match(emoji.texture, "Interface\\AddOns\\ChatEmojis\\Media\\([^|]+)")
            if path then
                texture:SetTexture("Interface\\AddOns\\ChatEmojis\\Media\\" .. path)
            end

            local isFavorite = ChatEmojisDB.favorites[emoji.code] or false
            local favTexture = button:CreateTexture(nil, "OVERLAY")
            favTexture:SetSize(16, 16)
            favTexture:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -1)

            if isFavorite then
                favTexture:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
                favTexture:SetVertexColor(1, 0.8, 0)
                favTexture:SetAlpha(1)
            else
                favTexture:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
                favTexture:SetVertexColor(0.5, 0.5, 0.5)
                favTexture:SetAlpha(0.3)
            end

            local highlight = button:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetTexture(1, 1, 1, 0.3)
            highlight:SetBlendMode("ADD")

            button.tooltipText = emoji.code .. (isFavorite and " |cFFC13D3D[Favorite]|r" or "")
            button:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.tooltipText)
                GameTooltip:AddLine("Right-click to " .. (isFavorite and "remove from" or "add to") .. " favorites", 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
            button:SetScript("OnLeave", GameTooltip_Hide)

            button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            button:SetScript("OnClick", function(self, mouseButton)
                if mouseButton == "LeftButton" then
                    local editBox = ChatEdit_GetActiveWindow()
                    if editBox and editBox:IsVisible() then
                        editBox:Insert(emoji.code .. " ")
                    else
                        ChatFrame_OpenChat(emoji.code .. " ")
                    end

                    local flashTexture = button:CreateTexture(nil, "OVERLAY")
                    flashTexture:SetAllPoints()
                    flashTexture:SetTexture(1, 1, 1, 0.5)
                    flashTexture:SetAlpha(0.8)
                    UIFrameFadeOut(flashTexture, 0.5, 0.8, 0)

                    local timerFrame = CreateFrame("Frame")
                    timerFrame.elapsed = 0
                    timerFrame:SetScript("OnUpdate", function(self, elapsed)
                        self.elapsed = self.elapsed + elapsed
                        if self.elapsed > 0.5 then
                            flashTexture:Hide()
                            self:SetScript("OnUpdate", nil)
                        end
                    end)

                elseif mouseButton == "RightButton" then
                    local newStatus = not ChatEmojisDB.favorites[emoji.code]
                    ChatEmojisDB.favorites[emoji.code] = newStatus

                    if newStatus then
                        favTexture:SetVertexColor(1, 0.8, 0)
                        favTexture:SetAlpha(1)
                    else
                        favTexture:SetVertexColor(0.5, 0.5, 0.5)
                        favTexture:SetAlpha(0.3)

                        if addon.currentCategory == "Favorites" then
                            button:Hide()
                        end
                    end

                    if addon.currentCategory == "Favorites" then
                        addon:UpdateEmojiDisplay()
                    end

                    self.tooltipText = emoji.code .. (newStatus and " |cFFC13D3D[Favorite]|r" or "")

                    if GameTooltip:IsOwned(self) then
                        GameTooltip:SetText(self.tooltipText)
                        GameTooltip:AddLine("Right-click to " .. (newStatus and "remove from" or "add to") .. " favorites", 0.8, 0.8, 0.8)
                        GameTooltip:Show()
                    end
                end
            end)
        end

        if scrollFrame then
            local totalHeight = math.max(rowCount * (buttonSize + padding) + padding, scrollFrame:GetHeight())
            emojiContainer:SetHeight(totalHeight)
        end
    else
        local noEmojisText = emojiContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        noEmojisText:SetPoint("CENTER", emojiContainer, "CENTER", 0, 0)

        if addon.currentCategory == "Favorites" then
            noEmojisText:SetText("No favorite emojis yet.\nRight-click on any emoji to add it to favorites.")
        else
            noEmojisText:SetText("No emojis match your search.")
        end

        noEmojisText:SetJustifyH("CENTER")
        noEmojisText:SetTextColor(0.7, 0.7, 0.7)

        emojiContainer:SetHeight(scrollFrame:GetHeight())
    end
end

function addon:ToggleEmojiBrowser()
    if not emojiBrowser then
        self:CreateEmojiBrowser()
    end

    if not emojiBrowser or not scrollFrame or not emojiContainer then
        print("|cFFFF0000ChatEmojis Error:|r Failed to initialize emoji browser")
        return
    end

    if emojiBrowser:IsShown() then
        emojiBrowser:Hide()
    else
        self:UpdateEmojiDisplay()
        emojiBrowser:Show()
        if searchBox then
            searchBox:SetFocus()
        end
    end
end

SLASH_EMOJIBROWSER1 = "/emojilist"
SLASH_EMOJIBROWSER2 = "/emojibrowser"
SlashCmdList["EMOJIBROWSER"] = function(msg)
    addon:ToggleEmojiBrowser()
end

-- Add a button to chat frame edit boxes
function addon:CreateChatFrameButton()
    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame"..i.."EditBox"]

        if editBox then
            local button = CreateFrame("Button", "ChatEmojisButton"..i, editBox)
            button:SetSize(18, 18)

            button:SetPoint("RIGHT", editBox, "LEFT", -5, 0)

            local bg = button:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture(0, 0, 0, 0.5)

            local border = button:CreateTexture(nil, "BORDER")
            border:SetPoint("TOPLEFT", -1, 1)
            border:SetPoint("BOTTOMRIGHT", 1, -1)
            border:SetTexture(0.5, 0.5, 0.5, 0.5)

            local texture = button:CreateTexture(nil, "ARTWORK")
            texture:SetPoint("TOPLEFT", 2, -2)
            texture:SetPoint("BOTTOMRIGHT", -2, 2)
            texture:SetTexture("Interface\\AddOns\\ChatEmojis\\Media\\Emojis\\Smile.tga")

            local highlight = button:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints(texture)
            highlight:SetTexture(1, 1, 1, 0.3)
            highlight:SetBlendMode("ADD")

            button:SetScript("OnClick", function()
                addon:ToggleEmojiBrowser()
            end)

            button:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Open Emoji Browser")
                GameTooltip:Show()
            end)
            button:SetScript("OnLeave", GameTooltip_Hide)
        end
    end
end

function addon:CreateEmojiPreview()
    local previewFrame = CreateFrame("Frame", "ChatEmojisPreviewFrame", UIParent)
    previewFrame:SetSize(200, 50)
    previewFrame:SetFrameStrata("TOOLTIP")
    previewFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    previewFrame:SetBackdropColor(0, 0, 0, 0.8)
    previewFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    previewFrame:Hide()

    local icon = previewFrame:CreateTexture("ChatEmojisPreviewIcon", "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("LEFT", previewFrame, "LEFT", 10, 0)

    local text = previewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    text:SetPoint("RIGHT", previewFrame, "RIGHT", -10, 0)
    text:SetJustifyH("LEFT")

    previewFrame.icon = icon
    previewFrame.text = text

    self.emojiPreviewFrame = previewFrame

    -- Hook all chat edit boxes
    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame"..i.."EditBox"]
        if editBox then
            editBox:HookScript("OnTextChanged", function(self)
                addon:UpdateEmojiPreview(self)
            end)

            editBox:HookScript("OnHide", function()
                if addon.emojiPreviewFrame then
                    addon.emojiPreviewFrame:Hide()
                end
            end)
        end
    end
end

-- Tab auto-completion
function addon:SetupChatAutoCompletion()
    local function OnTabPressed(editBox)
        if not ChatEmojisDB.enabled then return end

        local text = editBox:GetText()
        local cursorPosition = editBox:GetCursorPosition()

        if editBox.emojiCompletionActive then
            local matches = editBox.emojiCompletionMatches
            local currentIndex = editBox.emojiCompletionIndex or 0
            local startPos = editBox.emojiCompletionStartPos
            local beforeStart = editBox.emojiCompletionBeforeStart
            local afterCursor = editBox.emojiCompletionAfterCursor

            currentIndex = currentIndex + 1
            if currentIndex > #matches then currentIndex = 1 end
            editBox.emojiCompletionIndex = currentIndex

            local newText = beforeStart .. matches[currentIndex].code .. " " .. afterCursor
            editBox:SetText(newText)
            editBox:SetCursorPosition(startPos + string.len(matches[currentIndex].code) + 1)

            if addon.emojiCompletionTooltip then
                local currentMatch = matches[currentIndex]

                local texturePath
                if currentMatch.texture then
                    texturePath = string.match(currentMatch.texture, "Interface\\AddOns\\ChatEmojis\\Media\\([^|]+)")
                    if texturePath then
                        texturePath = "Interface\\AddOns\\ChatEmojis\\Media\\" .. texturePath
                    end
                end

                if texturePath then
                    addon.emojiCompletionTooltip.currentIcon:SetTexture(texturePath)
                    addon.emojiCompletionTooltip.currentIcon:Show()
                else
                    addon.emojiCompletionTooltip.currentIcon:Hide()
                end
                addon.emojiCompletionTooltip.currentText:SetText(currentMatch.code)

                for i = 1, #addon.emojiCompletionTooltip.options do
                    addon.emojiCompletionTooltip.options[i]:Hide()
                end

                local shownOptions = 0
                for i = 1, #matches do
                    if i ~= currentIndex and shownOptions < #addon.emojiCompletionTooltip.options then
                        shownOptions = shownOptions + 1
                        local option = addon.emojiCompletionTooltip.options[shownOptions]

                        local optionTexturePath
                        if matches[i].texture then
                            optionTexturePath = string.match(matches[i].texture, "Interface\\AddOns\\ChatEmojis\\Media\\([^|]+)")
                            if optionTexturePath then
                                optionTexturePath = "Interface\\AddOns\\ChatEmojis\\Media\\" .. optionTexturePath
                            end
                        end

                        if optionTexturePath then
                            option.icon:SetTexture(optionTexturePath)
                            option.icon:Show()
                        else
                            option.icon:Hide()
                        end
                        option.text:SetText(matches[i].code)
                        option:Show()
                    end
                end

                local moreCount = #matches - shownOptions - 1
                if moreCount > 0 then
                    addon.emojiCompletionTooltip.moreText:SetText("And " .. moreCount .. " more options...")
                    addon.emojiCompletionTooltip.moreText:Show()
                else
                    addon.emojiCompletionTooltip.moreText:Hide()
                end

                local rows = math.ceil(shownOptions / 4)
                local containerHeight = rows * 30
                addon.emojiCompletionTooltip.optionsContainer:SetHeight(containerHeight)

                local tooltipHeight = 180 + containerHeight
                if moreCount > 0 then
                    tooltipHeight = tooltipHeight + 20
                end
                addon.emojiCompletionTooltip:SetSize(450, tooltipHeight)
            end

            return true
        end

        local beforeCursor = string.sub(text, 1, cursorPosition)
        local afterCursor = string.sub(text, cursorPosition + 1)
        local startPos = string.find(beforeCursor, ":[^:%s]*$")

        if startPos then
            local partialCode = string.sub(beforeCursor, startPos)

            if string.match(partialCode, "^:[%w_]*$") then
                local searchText = string.sub(partialCode, 2)
                local matches = {}

                for code, texture in pairs(addon.Smileys) do
                    if string.match(code, "^:[%w_]+:$") then
                        local emojiName = string.match(code, ":([%w_]+):")
                        if emojiName and string.find(emojiName:lower(), searchText:lower(), 1, true) == 1 then
                            table.insert(matches, {code = code, texture = texture})
                        end
                    end
                end

                if #matches > 0 then
                    table.sort(matches, function(a, b) return a.code < b.code end)

                    local currentIndex = 1
                    editBox.emojiCompletionIndex = currentIndex

                    local newText = string.sub(beforeCursor, 1, startPos - 1) .. matches[currentIndex].code .. " " .. afterCursor
                    editBox:SetText(newText)
                    editBox:SetCursorPosition(startPos + string.len(matches[currentIndex].code) + 1)

                    editBox.emojiCompletionActive = true
                    editBox.emojiCompletionMatches = matches
                    editBox.emojiCompletionStartPos = startPos
                    editBox.emojiCompletionBeforeStart = string.sub(beforeCursor, 1, startPos - 1)
                    editBox.emojiCompletionAfterCursor = afterCursor

                    if not addon.emojiCompletionTooltip then
                        addon.emojiCompletionTooltip = CreateFrame("Frame", "ChatEmojisCompletionTooltip", UIParent)
                        addon.emojiCompletionTooltip:SetFrameStrata("TOOLTIP")
                        addon.emojiCompletionTooltip:SetBackdrop({
                            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                            tile = true, tileSize = 16, edgeSize = 16,
                            insets = { left = 4, right = 4, top = 4, bottom = 4 }
                        })
                        addon.emojiCompletionTooltip:SetBackdropColor(0, 0, 0, 0.8)
                        addon.emojiCompletionTooltip:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

                        local header = addon.emojiCompletionTooltip:CreateTexture(nil, "ARTWORK")
                        header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
                        header:SetWidth(250)
                        header:SetHeight(64)
                        header:SetPoint("TOP", 0, 12)

                        addon.emojiCompletionTooltip.titleText = addon.emojiCompletionTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        addon.emojiCompletionTooltip.titleText:SetPoint("TOP", header, "TOP", 0, -14)
                        addon.emojiCompletionTooltip.titleText:SetText("|cFF00CCFFEmoji|r |cFFFF6600Options|r")

                        addon.emojiCompletionTooltip.currentContainer = CreateFrame("Frame", nil, addon.emojiCompletionTooltip)
                        addon.emojiCompletionTooltip.currentContainer:SetSize(230, 40)
                        addon.emojiCompletionTooltip.currentContainer:SetPoint("TOP", addon.emojiCompletionTooltip.titleText, "BOTTOM", 0, -10)
                        addon.emojiCompletionTooltip.currentContainer:SetBackdrop({
                            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                            tile = true, tileSize = 16, edgeSize = 16,
                            insets = { left = 4, right = 4, top = 4, bottom = 4 }
                        })
                        addon.emojiCompletionTooltip.currentContainer:SetBackdropColor(0, 0, 0, 0.8)
                        addon.emojiCompletionTooltip.currentContainer:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

                        addon.emojiCompletionTooltip.currentIcon = addon.emojiCompletionTooltip.currentContainer:CreateTexture(nil, "ARTWORK")
                        addon.emojiCompletionTooltip.currentIcon:SetSize(32, 32)
                        addon.emojiCompletionTooltip.currentIcon:SetPoint("LEFT", addon.emojiCompletionTooltip.currentContainer, "LEFT", 10, 0)

                        addon.emojiCompletionTooltip.currentText = addon.emojiCompletionTooltip.currentContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        addon.emojiCompletionTooltip.currentText:SetPoint("LEFT", addon.emojiCompletionTooltip.currentIcon, "RIGHT", 10, 0)
                        addon.emojiCompletionTooltip.currentText:SetText("")

                        addon.emojiCompletionTooltip.actionHint = addon.emojiCompletionTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        addon.emojiCompletionTooltip.actionHint:SetPoint("TOP", addon.emojiCompletionTooltip.currentContainer, "BOTTOM", 0, -5)
                        addon.emojiCompletionTooltip.actionHint:SetText("|cFFFFD100Press Tab to cycle through options|r")

                        addon.emojiCompletionTooltip.otherOptionsTitle = addon.emojiCompletionTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        addon.emojiCompletionTooltip.otherOptionsTitle:SetPoint("TOP", addon.emojiCompletionTooltip.actionHint, "BOTTOM", 0, -10)
                        addon.emojiCompletionTooltip.otherOptionsTitle:SetText("Other matches:")

                        addon.emojiCompletionTooltip.optionsContainer = CreateFrame("Frame", nil, addon.emojiCompletionTooltip)
                        addon.emojiCompletionTooltip.optionsContainer:SetPoint("TOP", addon.emojiCompletionTooltip.otherOptionsTitle, "BOTTOM", 0, -5)
                        addon.emojiCompletionTooltip.optionsContainer:SetPoint("LEFT", addon.emojiCompletionTooltip, "LEFT", 15, 0)
                        addon.emojiCompletionTooltip.optionsContainer:SetPoint("RIGHT", addon.emojiCompletionTooltip, "RIGHT", -15, 0)
                        addon.emojiCompletionTooltip.optionsContainer:SetHeight(120) -- Will be adjusted based on content

                        addon.emojiCompletionTooltip.options = {}
                        for i = 1, 8 do
                            local option = CreateFrame("Frame", nil, addon.emojiCompletionTooltip.optionsContainer)
                            option:SetSize(100, 28)

                            if i <= 4 then -- First row
                                option:SetPoint("TOPLEFT", addon.emojiCompletionTooltip.optionsContainer, "TOPLEFT", (i-1) * 110, 0)
                            else -- Second row
                                option:SetPoint("TOPLEFT", addon.emojiCompletionTooltip.optionsContainer, "TOPLEFT", (i-5) * 110, -30)
                            end

                            option:SetBackdrop({
                                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                                tile = true, tileSize = 16, edgeSize = 16,
                                insets = { left = 4, right = 4, top = 4, bottom = 4 }
                            })
                            option:SetBackdropColor(0, 0, 0, 0.8)
                            option:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

                            option.icon = option:CreateTexture(nil, "ARTWORK")
                            option.icon:SetSize(20, 20)
                            option.icon:SetPoint("LEFT", option, "LEFT", 5, 0)

                            option.text = option:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                            option.text:SetPoint("LEFT", option.icon, "RIGHT", 5, 0)
                            option.text:SetPoint("RIGHT", option, "RIGHT", -5, 0)
                            option.text:SetJustifyH("LEFT")

                            addon.emojiCompletionTooltip.options[i] = option
                        end

                        addon.emojiCompletionTooltip.moreText = addon.emojiCompletionTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        addon.emojiCompletionTooltip.moreText:SetPoint("TOP", addon.emojiCompletionTooltip.optionsContainer, "BOTTOM", 0, -5)
                        addon.emojiCompletionTooltip.moreText:SetTextColor(0.7, 0.7, 0.7)
                    end

                    local currentMatch = matches[currentIndex]

                    local texturePath
                    if currentMatch.texture then
                        texturePath = string.match(currentMatch.texture, "Interface\\AddOns\\ChatEmojis\\Media\\([^|]+)")
                        if texturePath then
                            texturePath = "Interface\\AddOns\\ChatEmojis\\Media\\" .. texturePath
                        end
                    end

                    if texturePath then
                        addon.emojiCompletionTooltip.currentIcon:SetTexture(texturePath)
                        addon.emojiCompletionTooltip.currentIcon:Show()
                    else
                        addon.emojiCompletionTooltip.currentIcon:Hide()
                    end
                    addon.emojiCompletionTooltip.currentText:SetText(currentMatch.code)

                    for i = 1, #addon.emojiCompletionTooltip.options do
                        addon.emojiCompletionTooltip.options[i]:Hide()
                    end

                    local shownOptions = 0
                    for i = 1, #matches do
                        if i ~= currentIndex and shownOptions < #addon.emojiCompletionTooltip.options then
                            shownOptions = shownOptions + 1
                            local option = addon.emojiCompletionTooltip.options[shownOptions]

                            local optionTexturePath
                            if matches[i].texture then
                                optionTexturePath = string.match(matches[i].texture, "Interface\\AddOns\\ChatEmojis\\Media\\([^|]+)")
                                if optionTexturePath then
                                    optionTexturePath = "Interface\\AddOns\\ChatEmojis\\Media\\" .. optionTexturePath
                                end
                            end

                            if optionTexturePath then
                                option.icon:SetTexture(optionTexturePath)
                                option.icon:Show()
                            else
                                option.icon:Hide()
                            end
                            option.text:SetText(matches[i].code)
                            option:Show()
                        end
                    end

                    local moreCount = #matches - shownOptions - 1
                    if moreCount > 0 then
                        addon.emojiCompletionTooltip.moreText:SetText("And " .. moreCount .. " more options...")
                        addon.emojiCompletionTooltip.moreText:Show()
                    else
                        addon.emojiCompletionTooltip.moreText:Hide()
                    end

                    local rows = math.ceil(shownOptions / 4)
                    local containerHeight = rows * 30
                    addon.emojiCompletionTooltip.optionsContainer:SetHeight(containerHeight)

                    local tooltipHeight = 180 + containerHeight
                    if moreCount > 0 then
                        tooltipHeight = tooltipHeight + 20
                    end
                    addon.emojiCompletionTooltip:SetSize(450, tooltipHeight)

                    addon.emojiCompletionTooltip:ClearAllPoints()
                    addon.emojiCompletionTooltip:SetPoint("BOTTOM", editBox, "TOP", 0, 10)
                    addon.emojiCompletionTooltip:Show()

                    return true
                end
            end
        end

        if addon.emojiCompletionTooltip then
            addon.emojiCompletionTooltip:Hide()
        end
        editBox.emojiCompletionActive = nil
        editBox.emojiCompletionIndex = nil

        return false
    end

    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame"..i.."EditBox"]
        if editBox then
            editBox:HookScript("OnTabPressed", function(self)
                if OnTabPressed(self) then
                    return true
                end
            end)

            editBox:HookScript("OnEditFocusLost", function(self)
                self.emojiCompletionActive = nil
                self.emojiCompletionIndex = nil
                if addon.emojiCompletionTooltip then
                    addon.emojiCompletionTooltip:Hide()
                end
            end)

            editBox:HookScript("OnTextChanged", function(self, isUserInput)
                if isUserInput and self.emojiCompletionActive then
                    local cursorPosition = self:GetCursorPosition()
                    local matchIndex = self.emojiCompletionIndex or 1
                    local currentMatch = self.emojiCompletionMatches and self.emojiCompletionMatches[matchIndex]
                    local completionEnd = self.emojiCompletionStartPos + (currentMatch and string.len(currentMatch.code) or 0)

                    if cursorPosition < self.emojiCompletionStartPos or cursorPosition > completionEnd then
                        self.emojiCompletionActive = nil
                        self.emojiCompletionIndex = nil
                        if addon.emojiCompletionTooltip then
                            addon.emojiCompletionTooltip:Hide()
                        end
                    end
                end
            end)

            editBox:HookScript("OnChar", function(self)
                if self.emojiCompletionActive then
                    local text = self:GetText()
                    local matchIndex = self.emojiCompletionIndex or 1
                    local currentMatch = self.emojiCompletionMatches and self.emojiCompletionMatches[matchIndex]

                    if currentMatch then
                        local expectedEmoji = currentMatch.code
                        local start = self.emojiCompletionStartPos
                        local expectedEnd = start + string.len(expectedEmoji)

                        if expectedEnd <= string.len(text) then
                            local actualEmoji = string.sub(text, start, expectedEnd - 1)
                            if actualEmoji ~= expectedEmoji then
                                self.emojiCompletionActive = nil
                                self.emojiCompletionIndex = nil
                                if addon.emojiCompletionTooltip then
                                    addon.emojiCompletionTooltip:Hide()
                                end
                            end
                        end
                    end
                end
            end)

            editBox:HookScript("OnEscapePressed", function(self)
                self.emojiCompletionActive = nil
                self.emojiCompletionIndex = nil
                if addon.emojiCompletionTooltip then
                    addon.emojiCompletionTooltip:Hide()
                end
            end)
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        addon:Initialize()
    end
end)
