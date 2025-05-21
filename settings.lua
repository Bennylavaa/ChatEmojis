local addonName, addon = ...

function addon:CreateOptions()
    local panel = CreateFrame("Frame")
    panel.name = "ChatEmojis"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cFF00CCFFChat|r|cFFFF6600Emojis|r")

    local enableCheckbox = CreateFrame("CheckButton", "ChatEmojisEnableCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
    enableCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    ChatEmojisEnableCheckboxText:SetText("Enable |cFF00CCFFChat|r|cFFFF6600Emojis|r")
    enableCheckbox.tooltipText = "Enable or disable all |cFF00CCFFChat|r|cFFFF6600Emojis|r"
    enableCheckbox:SetChecked(ChatEmojisDB.enabled)
    enableCheckbox:SetScript("OnClick", function(self)
        ChatEmojisDB.enabled = self:GetChecked()
    end)

    local textEmotesCheckbox = CreateFrame("CheckButton", "ChatEmojisTextEmotesCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
    textEmotesCheckbox:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -10)
    ChatEmojisTextEmotesCheckboxText:SetText("Enable Text Emoticons (:), :D, etc.)")
    textEmotesCheckbox.tooltipText = "Enable or disable conversion of text emoticons like :) to emojis"
    textEmotesCheckbox:SetChecked(ChatEmojisDB.textEmotes)
    textEmotesCheckbox:SetScript("OnClick", function(self)
        ChatEmojisDB.textEmotes = self:GetChecked()
        addon:UpdateEmojiMappings()
    end)

    local sizeSlider = CreateFrame("Slider", "ChatEmojisSizeSlider", panel, "OptionsSliderTemplate")
    sizeSlider:SetPoint("TOPLEFT", textEmotesCheckbox, "BOTTOMLEFT", 0, -40)
    sizeSlider:SetMinMaxValues(8, 64)
    sizeSlider:SetValueStep(1)
    sizeSlider:SetWidth(200)
    sizeSlider:SetValue(ChatEmojisDB.emojiSize)
    ChatEmojisSizeSliderLow:SetText("8")
    ChatEmojisSizeSliderHigh:SetText("64")
    ChatEmojisSizeSliderText:SetText("Emoji Size: " .. ChatEmojisDB.emojiSize)

    sizeSlider:SetScript("OnValueChanged", function(self, value)
        value = floor(value + 0.5)
        ChatEmojisDB.emojiSize = value
        ChatEmojisSizeSliderText:SetText("Emoji Size: " .. value)
        addon.currentSize = value
    end)

    local previewTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    previewTitle:SetPoint("TOPLEFT", sizeSlider, "BOTTOMLEFT", 0, -30)
    previewTitle:SetText("Preview:")

    local previewFrame = CreateFrame("Frame", "ChatEmojisPreviewFrame", panel)
    previewFrame:SetPoint("TOPLEFT", previewTitle, "BOTTOMLEFT", 0, -10)
    previewFrame:SetSize(200, 120)  -- Increase height from 80 to 120 for larger emoji
    previewFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })

    local function UpdatePreview()
        if previewFrame.emojis then
            for _, emoji in pairs(previewFrame.emojis) do
                emoji:Hide()
            end
        end

        previewFrame.emojis = {}

        local emojiList = {
            { code = ":smile:", label = ":smile:" }
        }

        for i, emojiData in ipairs(emojiList) do
            local emoji = previewFrame:CreateTexture("ChatEmojisPreview" .. i, "OVERLAY")
            local size = ChatEmojisDB.emojiSize
            emoji:SetSize(size, size)
            emoji:SetPoint("TOP", previewFrame, "TOP", 0, -20)

            local emojiName = string.match(emojiData.code, ":([%w_]+):")
            if emojiName then
                local path = addon.M .. "Emojis\\" .. emojiName:gsub("_", "") .. ".tga"
                emoji:SetTexture(path)
            end

            local label = previewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            label:SetPoint("BOTTOM", emoji, "BOTTOM", 0, -15)
            label:SetText(emojiData.label)

            table.insert(previewFrame.emojis, emoji)
            table.insert(previewFrame.emojis, label)
        end
    end

    local applyButton = CreateFrame("Button", "ChatEmojisApplyButton", panel, "UIPanelButtonTemplate")
    applyButton:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -20, 20)
    applyButton:SetSize(100, 22)
    applyButton:SetText("Apply")
    applyButton:SetScript("OnClick", function()
        addon:UpdateEmojiMappings()
        UpdatePreview()
    end)

    panel:SetScript("OnShow", function()
        UpdatePreview()
    end)

    local defaultsButton = CreateFrame("Button", "ChatEmojisDefaultsButton", panel, "UIPanelButtonTemplate")
    defaultsButton:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 20, 20)
    defaultsButton:SetSize(100, 22)
    defaultsButton:SetText("Defaults")
    defaultsButton:SetScript("OnClick", function()
        for key, value in pairs(addon.defaults) do
            ChatEmojisDB[key] = value
        end

        enableCheckbox:SetChecked(ChatEmojisDB.enabled)
        textEmotesCheckbox:SetChecked(ChatEmojisDB.textEmotes)
        sizeSlider:SetValue(ChatEmojisDB.emojiSize)
        ChatEmojisSizeSliderText:SetText("Emoji Size: " .. ChatEmojisDB.emojiSize)

        addon.currentSize = ChatEmojisDB.emojiSize
        addon:UpdateEmojiMappings()
        UpdatePreview()
    end)

    -- Add a "Clear Favorites" button
    local clearFavoritesButton = CreateFrame("Button", "ChatEmojisClearFavoritesButton", panel, "UIPanelButtonTemplate")
    clearFavoritesButton:SetPoint("BOTTOM", panel, "BOTTOM", 0, 20)
    clearFavoritesButton:SetSize(120, 22)
    clearFavoritesButton:SetText("Clear Favorites")
    clearFavoritesButton:SetScript("OnClick", function()
        StaticPopupDialogs["CHATEMOJIS_CLEAR_FAVORITES"] = {
            text = "Are you sure you want to clear all favorite emojis?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                ChatEmojisDB.favorites = {}
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFFChat|r|cFFFF6600Emojis|r: All favorites cleared")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("CHATEMOJIS_CLEAR_FAVORITES")
    end)

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
