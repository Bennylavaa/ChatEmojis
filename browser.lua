local addonName, addon = ...

-- Local variables for the emoji browser
local emojiBrowser
local searchBox
local scrollFrame
local emojiContainer
local MAX_EMOJIS_PER_ROW = 10
local EMOJI_BUTTON_SIZE = 32
local EMOJI_PADDING = 5

-- Create the emoji browser window
function addon:CreateEmojiBrowser()
    if emojiBrowser then return end

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

    local header = emojiBrowser:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetWidth(300)
    header:SetHeight(64)
    header:SetPoint("TOP", 0, 12)

    local title = emojiBrowser:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    title:SetText("|cFF00CCFFEmoji|r |cFFFF6600Browser")

    local closeButton = CreateFrame("Button", nil, emojiBrowser, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)

    local settingsButton = CreateFrame("Button", "ChatEmojisSettingsButton", emojiBrowser, "GameMenuButtonTemplate")
    settingsButton:SetSize(16, 16)
    settingsButton:SetPoint("TOPLEFT", emojiBrowser, "TOPLEFT", 12, -12)

    local iconTexture = settingsButton:CreateTexture(nil, "ARTWORK")
    iconTexture:SetSize(8, 8)
    iconTexture:SetPoint("CENTER")
    iconTexture:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")

    settingsButton:SetScript("OnClick", function()
        PlaySound("igMainMenuOption")
        InterfaceOptionsFrame_OpenToCategory("ChatEmojis")
        emojiBrowser:Hide()
    end)

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
        border:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
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
        selectedBg:SetTexture(0.2, 0.2, 0.3, 0.7)
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
                        btn.border:SetBackdropBorderColor(0.7, 0.6, 0.1, 0.9)
                    end
                else
                    btn.text:SetTextColor(1, 1, 1)
                    btn.selectedIndicator:Hide()
                    btn.selectedBg:Hide()
                    btn.bg:Show()
                    if btn.border then
                        btn.border:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
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
    emojiContainer:SetSize(scrollFrame:GetWidth(), 500)
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
        local children = { emojiContainer:GetChildren() }
        for _, child in ipairs(children) do
            if child:GetObjectType() == "Button" then
                child:SetScript("OnClick", nil)
                child:SetScript("OnEnter", nil)
                child:SetScript("OnLeave", nil)
                child:UnregisterAllEvents()
            end
            child:Hide()
            child:SetParent(nil)
        end

        emojiContainer:Hide()
        emojiContainer:SetParent(nil)
        emojiContainer = nil

        collectgarbage("collect")
    end

    emojiContainer = CreateFrame("Frame", nil, scrollFrame)
    emojiContainer:SetSize(scrollFrame:GetWidth(), 500)
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
            local button = CreateFrame("Button", nil, emojiContainer)
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