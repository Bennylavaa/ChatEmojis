local addonName, addon = ...

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
                addon:UpdateCompletionTooltip(matches, currentIndex)
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
                        addon:CreateCompletionTooltip()
                    end

                    addon:UpdateCompletionTooltip(matches, currentIndex)
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

function addon:CreateCompletionTooltip()
    addon.emojiCompletionTooltip = CreateFrame("Frame", "ChatEmojisCompletionTooltip", UIParent)
    addon.emojiCompletionTooltip:SetFrameStrata("TOOLTIP")
    addon.emojiCompletionTooltip:SetFrameLevel(100)

    addon.emojiCompletionTooltip:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    addon.emojiCompletionTooltip:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    addon.emojiCompletionTooltip:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.9)

    addon.emojiCompletionTooltip.titleText = addon.emojiCompletionTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addon.emojiCompletionTooltip.titleText:SetPoint("TOP", addon.emojiCompletionTooltip, "TOP", 0, -12)
    addon.emojiCompletionTooltip.titleText:SetText("|cFF00CCFFEmoji|r |cFFFF6600Suggestions|r")

    addon.emojiCompletionTooltip.currentContainer = CreateFrame("Frame", nil, addon.emojiCompletionTooltip)
    addon.emojiCompletionTooltip.currentContainer:SetSize(300, 50)
    addon.emojiCompletionTooltip.currentContainer:SetPoint("TOP", addon.emojiCompletionTooltip.titleText, "BOTTOM", 0, -10)
    addon.emojiCompletionTooltip.currentContainer:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    addon.emojiCompletionTooltip.currentContainer:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
    addon.emojiCompletionTooltip.currentContainer:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.9)

    addon.emojiCompletionTooltip.currentIcon = addon.emojiCompletionTooltip.currentContainer:CreateTexture(nil, "ARTWORK")
    addon.emojiCompletionTooltip.currentIcon:SetSize(32, 32)
    addon.emojiCompletionTooltip.currentIcon:SetPoint("LEFT", addon.emojiCompletionTooltip.currentContainer, "LEFT", 12, 0)

    addon.emojiCompletionTooltip.currentText = addon.emojiCompletionTooltip.currentContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    addon.emojiCompletionTooltip.currentText:SetPoint("LEFT", addon.emojiCompletionTooltip.currentIcon, "RIGHT", 15, 0)
    addon.emojiCompletionTooltip.currentText:SetPoint("RIGHT", addon.emojiCompletionTooltip.currentContainer, "RIGHT", -12, 0)
    addon.emojiCompletionTooltip.currentText:SetJustifyH("LEFT")
    addon.emojiCompletionTooltip.currentText:SetTextColor(1, 1, 1)

    addon.emojiCompletionTooltip.actionHint = addon.emojiCompletionTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addon.emojiCompletionTooltip.actionHint:SetPoint("TOP", addon.emojiCompletionTooltip.currentContainer, "BOTTOM", 0, -8)
    addon.emojiCompletionTooltip.actionHint:SetText("|cFFFFD100Press Tab to cycle through options|r")
    addon.emojiCompletionTooltip.actionHint:SetTextColor(1, 0.8, 0)

    addon.emojiCompletionTooltip.otherOptionsTitle = addon.emojiCompletionTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addon.emojiCompletionTooltip.otherOptionsTitle:SetPoint("TOP", addon.emojiCompletionTooltip.actionHint, "BOTTOM", 0, -12)
    addon.emojiCompletionTooltip.otherOptionsTitle:SetText("Other matches:")
    addon.emojiCompletionTooltip.otherOptionsTitle:SetTextColor(0.8, 0.8, 0.8)

    addon.emojiCompletionTooltip.optionsContainer = CreateFrame("Frame", nil, addon.emojiCompletionTooltip)
    addon.emojiCompletionTooltip.optionsContainer:SetPoint("TOP", addon.emojiCompletionTooltip.otherOptionsTitle, "BOTTOM", 0, -8)
    addon.emojiCompletionTooltip.optionsContainer:SetPoint("LEFT", addon.emojiCompletionTooltip, "LEFT", 15, 0)
    addon.emojiCompletionTooltip.optionsContainer:SetPoint("RIGHT", addon.emojiCompletionTooltip, "RIGHT", -15, 0)
    addon.emojiCompletionTooltip.optionsContainer:SetHeight(120)

    addon.emojiCompletionTooltip.options = {}
    for i = 1, 8 do
        local option = CreateFrame("Frame", nil, addon.emojiCompletionTooltip.optionsContainer)
        option:SetSize(90, 30)

        local row = math.ceil(i / 4)
        local col = ((i - 1) % 4) + 1
        option:SetPoint("TOPLEFT", addon.emojiCompletionTooltip.optionsContainer, "TOPLEFT",
                       (col - 1) * 100, -(row - 1) * 33)

        option:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        option:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        option:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

        option:EnableMouse(true)
        option:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.3, 0.3, 0.3, 0.7)
            self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        end)
        option:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        end)

        option.icon = option:CreateTexture(nil, "ARTWORK")
        option.icon:SetSize(20, 20)
        option.icon:SetPoint("LEFT", option, "LEFT", 6, 0)

        option.text = option:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        option.text:SetPoint("LEFT", option.icon, "RIGHT", 6, 0)
        option.text:SetPoint("RIGHT", option, "RIGHT", -6, 0)
        option.text:SetJustifyH("LEFT")
        option.text:SetTextColor(1, 1, 1)

        addon.emojiCompletionTooltip.options[i] = option
    end

    addon.emojiCompletionTooltip.moreText = addon.emojiCompletionTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addon.emojiCompletionTooltip.moreText:SetPoint("TOP", addon.emojiCompletionTooltip.optionsContainer, "BOTTOM", 0, -8)
    addon.emojiCompletionTooltip.moreText:SetTextColor(0.7, 0.7, 0.7)

    addon.emojiCompletionTooltip:Hide()
end

function addon:UpdateCompletionTooltip(matches, currentIndex)
    if not addon.emojiCompletionTooltip then return end

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
    local containerHeight = math.max(rows * 33, 33)
    addon.emojiCompletionTooltip.optionsContainer:SetHeight(containerHeight)

    local tooltipHeight = 140 + containerHeight
    if moreCount > 0 then
        tooltipHeight = tooltipHeight + 25
    end

    addon.emojiCompletionTooltip:SetSize(420, tooltipHeight)
end