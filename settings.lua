local addonName, addon = ...

function addon:CreateOptions()
    local panel = CreateFrame("Frame")
    panel.name = "ChatEmojis"

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(panel)
    bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    bg:SetVertexColor(0.1, 0.1, 0.1, 0.9)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", panel, "TOP", 0, -20)
    title:SetText("|cFF00CCFFChat|r|cFFFF6600Emojis|r |cFFFFFFFFSettings|r")
    title:SetShadowOffset(2, -2)
    title:SetShadowColor(0, 0, 0, 1)

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -5)
    subtitle:SetText("|cFFAAAAAACustomize your emoji experience|r")

    local checkboxFrame = CreateFrame("Frame", nil, panel)
    checkboxFrame:SetPoint("TOP", subtitle, "BOTTOM", 0, -30)
    checkboxFrame:SetSize(400, 80)
    checkboxFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    checkboxFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    checkboxFrame:SetBackdropBorderColor(1, 1, 1, 0.6)

    local function StyleCheckbox(checkbox, text, tooltip)
        checkbox:SetSize(24, 24)

        local bg = checkbox:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(checkbox)
        bg:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")

        local textObj = _G[checkbox:GetName() .. "Text"]
        if textObj then
            textObj:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            textObj:SetTextColor(0.9, 0.9, 0.9, 1)
            textObj:SetText(text)
        end

        checkbox.tooltipText = tooltip

        checkbox:SetScript("OnEnter", function(self)
            if textObj then
                textObj:SetTextColor(1, 1, 1, 1)
            end
        end)

        checkbox:SetScript("OnLeave", function(self)
            if textObj then
                textObj:SetTextColor(0.9, 0.9, 0.9, 1)
            end
        end)
    end

    local enableCheckbox = CreateFrame("CheckButton", "ChatEmojisEnableCheckbox", checkboxFrame, "InterfaceOptionsCheckButtonTemplate")
    enableCheckbox:SetPoint("TOPLEFT", checkboxFrame, "TOPLEFT", 20, -15)
    StyleCheckbox(enableCheckbox, "Enable ChatEmojis", "Enable or disable all ChatEmojis")
    enableCheckbox:SetChecked(ChatEmojisDB.enabled)
    enableCheckbox:SetScript("OnClick", function(self)
        ChatEmojisDB.enabled = self:GetChecked()
    end)

    local bubbleCheckbox = CreateFrame("CheckButton", "ChatEmojisBubbleCheckbox", checkboxFrame, "InterfaceOptionsCheckButtonTemplate")
    bubbleCheckbox:SetPoint("TOPRIGHT", checkboxFrame, "TOPRIGHT", -160, -15)
    StyleCheckbox(bubbleCheckbox, "Chat Bubble", "Show emojis in chat bubbles above characters")
    bubbleCheckbox:SetChecked(ChatEmojisDB.bubbleEmojis)
    bubbleCheckbox:SetScript("OnClick", function(self)
        ChatEmojisDB.bubbleEmojis = self:GetChecked()
        addon:ToggleBubbleProcessing(ChatEmojisDB.bubbleEmojis)
    end)

    local textEmotesCheckbox = CreateFrame("CheckButton", "ChatEmojisTextEmotesCheckbox", checkboxFrame, "InterfaceOptionsCheckButtonTemplate")
    textEmotesCheckbox:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -10)
    StyleCheckbox(textEmotesCheckbox, "Enable Text Emoticons", "Enable or disable conversion of text emoticons like :) to emojis")
    textEmotesCheckbox:SetChecked(ChatEmojisDB.textEmotes)
    textEmotesCheckbox:SetScript("OnClick", function(self)
        ChatEmojisDB.textEmotes = self:GetChecked()
        addon:UpdateEmojiMappings()
    end)

    local sliderFrame = CreateFrame("Frame", nil, panel)
    sliderFrame:SetPoint("TOP", checkboxFrame, "BOTTOM", 0, -20)
    sliderFrame:SetSize(350, 80)
    sliderFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    sliderFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    sliderFrame:SetBackdropBorderColor(1, 1, 1, 0.6)

    local sizeSlider = CreateFrame("Slider", "ChatEmojisSizeSlider", sliderFrame, "OptionsSliderTemplate")
    sizeSlider:SetPoint("CENTER", sliderFrame, "CENTER", 0, -5)
    sizeSlider:SetMinMaxValues(1, 3)
    sizeSlider:SetValueStep(1)
    sizeSlider:SetWidth(200)

    -- Map slider values to actual emoji sizes
    local sizeMappings = {
        [1] = 8,   -- Small
        [2] = 16,  -- Medium
        [3] = 24   -- Large
    }

    local initialSize = ChatEmojisDB.emojiSize
    local initialValue = 2  -- Default to medium
    for k, v in pairs(sizeMappings) do
        if v == initialSize then
            initialValue = k
            break
        end
    end

    sizeSlider:SetValue(initialValue)

    -- Set initial text label based on the actual slider value
    local sizeLabels = {
        [1] = "Small",
        [2] = "Medium",
        [3] = "Large"
    }
    ChatEmojisSizeSliderText:SetText(sizeLabels[initialValue])

    local sliderTitle = sliderFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    sliderTitle:SetPoint("TOP", sliderFrame, "TOP", 0, -10)
    sliderTitle:SetText("|cFFFFFFFFEmoji Size|r")
    sliderTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")

    ChatEmojisSizeSliderLow:SetText("|cFF888888Small|r")
    ChatEmojisSizeSliderHigh:SetText("|cFF888888Large|r")
    ChatEmojisSizeSliderText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    ChatEmojisSizeSliderText:SetTextColor(0.8, 0.9, 1, 1)

    sizeSlider:SetScript("OnValueChanged", function(self, value)
        value = floor(value + 0.5)
        local emojiSize = sizeMappings[value]

        ChatEmojisDB.emojiSize = emojiSize
        addon.currentSize = emojiSize

        local sizeLabels = {
            [1] = "Small",
            [2] = "Medium",
            [3] = "Large"
        }

        ChatEmojisSizeSliderText:SetText(sizeLabels[value])

        addon:UpdateEmojiMappings()
    end)

    local function StyleButton(button, color)
        button:SetNormalFontObject("GameFontNormal")
        button:SetHighlightFontObject("GameFontHighlight")

        local normalTexture = button:CreateTexture(nil, "BACKGROUND")
        normalTexture:SetAllPoints(button)
        normalTexture:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        normalTexture:SetTexCoord(0, 0.625, 0, 0.6875)
        button:SetNormalTexture(normalTexture)

        local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
        highlightTexture:SetAllPoints(button)
        highlightTexture:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
        highlightTexture:SetTexCoord(0, 0.625, 0, 0.6875)
        highlightTexture:SetBlendMode("ADD")
        button:SetHighlightTexture(highlightTexture)

        if color then
            normalTexture:SetVertexColor(color.r, color.g, color.b, 1)
        end
    end

    local buttonFrame = CreateFrame("Frame", nil, panel)
    buttonFrame:SetPoint("TOP", sliderFrame, "BOTTOM", 0, -30)
    buttonFrame:SetSize(400, 50)

    local applyButton = CreateFrame("Button", "ChatEmojisApplyButton", buttonFrame, "UIPanelButtonTemplate")
    applyButton:SetPoint("RIGHT", buttonFrame, "CENTER", -10, 0)
    applyButton:SetSize(80, 25)
    applyButton:SetText("Apply")
    applyButton:SetScript("OnClick", function()
        addon:UpdateEmojiMappings()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFFChat|r|cFFFF6600Emojis|r: Settings applied!")
    end)

    local defaultsButton = CreateFrame("Button", "ChatEmojisDefaultsButton", buttonFrame, "UIPanelButtonTemplate")
    defaultsButton:SetPoint("LEFT", buttonFrame, "CENTER", 10, 0)
    defaultsButton:SetSize(80, 25)
    defaultsButton:SetText("Defaults")
    defaultsButton:SetScript("OnClick", function()
        for key, value in pairs(addon.defaults) do
            ChatEmojisDB[key] = value
        end

        enableCheckbox:SetChecked(ChatEmojisDB.enabled)
        textEmotesCheckbox:SetChecked(ChatEmojisDB.textEmotes)

        local sliderValue = 2
        for k, v in pairs({[1] = 8, [2] = 16, [3] = 24}) do
            if v == ChatEmojisDB.emojiSize then
                sliderValue = k
                break
            end
        end

        sizeSlider:SetValue(sliderValue)

        local sizeLabels = {
            [1] = "|cFFFF9999Small|r",
            [2] = "|cFFFFFF99Medium|r",
            [3] = "|cFF99FF99Large|r"
        }
        ChatEmojisSizeSliderText:SetText(sizeLabels[sliderValue])

        addon.currentSize = ChatEmojisDB.emojiSize
        addon:UpdateEmojiMappings()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFFChat|r|cFFFF6600Emojis|r: Settings reset to defaults!")
    end)

    local clearFavoritesButton = CreateFrame("Button", "ChatEmojisClearFavoritesButton", buttonFrame, "UIPanelButtonTemplate")
    clearFavoritesButton:SetPoint("TOP", buttonFrame, "BOTTOM", 0, -5)
    clearFavoritesButton:SetSize(120, 22)
    clearFavoritesButton:SetText("Clear Favorites")
    clearFavoritesButton:SetScript("OnClick", function()
        StaticPopupDialogs["CHATEMOJIS_CLEAR_FAVORITES"] = {
            text = "Are you sure you want to clear all favorite emojis?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                ChatEmojisDB.favorites = {}
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFFChat|r|cFFFF6600Emojis|r: All favorites cleared!")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("CHATEMOJIS_CLEAR_FAVORITES")
    end)

    -- local donationFrame = CreateFrame("Frame", nil, panel)
    -- donationFrame:SetPoint("TOP", clearFavoritesButton, "BOTTOM", 0, -10)
    -- donationFrame:SetSize(400, 40)
    -- donationFrame:SetBackdrop({
        -- bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        -- edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        -- tile = true, tileSize = 16, edgeSize = 16,
        -- insets = { left = 4, right = 4, top = 4, bottom = 4 }
    -- })
    -- donationFrame:SetBackdropColor(0.1, 0.05, 0.1, 0.9)
    -- donationFrame:SetBackdropBorderColor(1, 0.8, 0.4, 0.8)

    -- local pepeBitcoin = donationFrame:CreateTexture(nil, "ARTWORK")
    -- pepeBitcoin:SetSize(32, 32)
    -- pepeBitcoin:SetPoint("LEFT", donationFrame, "LEFT", 15, 0)
    -- pepeBitcoin:SetTexture(addon.M .. "PepeEmojis\\PepeBitcoin.blp")

    -- local donationText = donationFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    -- donationText:SetPoint("CENTER", donationFrame, "CENTER", 10, 0)
    -- donationText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    -- donationText:SetText("|cFFFFFFFFLike this addon? Send some gold to |cFFFF6600shadowtoots|r")
    -- donationText:SetShadowOffset(1, -1)
    -- donationText:SetShadowColor(0, 0, 0, 0.8)

    -- local heart1 = donationFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    -- heart1:SetPoint("LEFT", donationText, "LEFT", -15, 0)
    -- heart1:SetText("|cFFFF6699<3|r")

    -- local heart2 = donationFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    -- heart2:SetPoint("RIGHT", donationText, "RIGHT", 15, 0)
    -- heart2:SetText("|cFFFF6699<3|r")

    InterfaceOptions_AddCategory(panel)

    return panel
end

-- Initialize saved variables
function addon:InitSettings()
    if not ChatEmojisDB then
        ChatEmojisDB = {}
    end

    for key, value in pairs(self.defaults) do
        if ChatEmojisDB[key] == nil then
            ChatEmojisDB[key] = value
        end
    end

    -- Initialize favorites if it doesn't exist
    if not ChatEmojisDB.favorites then
        ChatEmojisDB.favorites = {}
    end

    -- Current size is used during the current session
    self.currentSize = ChatEmojisDB.emojiSize
end

-- Register slash commands for settings
function addon:SetupSettingsCommands()
    SLASH_CHATEMOJIS1 = "/emoji"
    SLASH_CHATEMOJIS2 = "/emojis"
    SLASH_CHATEMOJIS3 = "/chatemojis"
    SLASH_CHATEMOJIS4 = "/ce"

    SlashCmdList["CHATEMOJIS"] = function(msg)
        InterfaceOptionsFrame_OpenToCategory("ChatEmojis")
    end
end