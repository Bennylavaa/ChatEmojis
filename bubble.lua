local addonName, addon = ...

-- Chat bubble emoji processing
function addon:ProcessChatBubbles()
    -- Hook the chat bubble creation function
    local originalChatBubble_OnLoad = ChatBubble_OnLoad
    
    -- Function to process existing chat bubbles
    local function ProcessExistingBubbles()
        -- Iterate through all world frames to find chat bubbles
        for i = 1, WorldFrame:GetNumChildren() do
            local frame = select(i, WorldFrame:GetChildren())
            
            if frame and frame:GetObjectType() == "Frame" and frame:IsVisible() then
                -- Check if this looks like a chat bubble
                if frame:GetNumChildren() > 0 then
                    local fontString = frame:GetChildren()
                    
                    if fontString and fontString:GetObjectType() == "FontString" then
                        local text = fontString:GetText()
                        
                        if text and text ~= "" then
                            -- Process the text for emojis
                            local processedText = addon:GetSmileyReplacementText(text)
                            
                            if processedText ~= text then
                                fontString:SetText(processedText)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Create a frame to monitor for new chat bubbles
    if not addon.bubbleFrame then
        addon.bubbleFrame = CreateFrame("Frame")
        addon.bubbleFrame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = (self.elapsed or 0) + elapsed
            
            -- Check for bubbles every 0.1 seconds
            if self.elapsed >= 0.1 then
                ProcessExistingBubbles()
                self.elapsed = 0
            end
        end)
    end
end

-- Alternative method using chat events for bubbles
function addon:SetupBubbleEventProcessing()
    -- Create frame to handle chat bubble events
    if not addon.bubbleEventFrame then
        addon.bubbleEventFrame = CreateFrame("Frame")
        addon.bubbleEventFrame:RegisterEvent("CHAT_MSG_SAY")
        addon.bubbleEventFrame:RegisterEvent("CHAT_MSG_YELL")
        addon.bubbleEventFrame:RegisterEvent("CHAT_MSG_EMOTE")
        addon.bubbleEventFrame:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
        
        addon.bubbleEventFrame:SetScript("OnEvent", function(self, event, message, sender, ...)
            -- Small delay to allow bubble to be created using classic timer method
            local timerFrame = CreateFrame("Frame")
            timerFrame.elapsed = 0
            timerFrame.targetTime = 0.05
            timerFrame.message = message
            timerFrame.sender = sender
            timerFrame:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = self.elapsed + elapsed
                if self.elapsed >= self.targetTime then
                    addon:ProcessRecentBubbles(self.message, self.sender)
                    self:SetScript("OnUpdate", nil)
                end
            end)
        end)
    end
end

function addon:ProcessRecentBubbles(originalMessage, sender)
    -- Look for chat bubbles that might contain this message
    for i = 1, WorldFrame:GetNumChildren() do
        local frame = select(i, WorldFrame:GetChildren())
        
        if frame and frame:GetObjectType() == "Frame" and frame:IsVisible() then
            local fontString = addon:FindFontStringInFrame(frame)
            
            if fontString then
                local bubbleText = fontString:GetText()
                
                if bubbleText and bubbleText == originalMessage then
                    local processedText = addon:GetSmileyReplacementText(bubbleText)
                    
                    if processedText ~= bubbleText then
                        fontString:SetText(processedText)
                        break
                    end
                end
            end
        end
    end
end

-- Helper function to find FontString in a frame hierarchy
function addon:FindFontStringInFrame(frame)
    if not frame then return nil end
    
    -- Check if the frame itself is a FontString
    if frame:GetObjectType() == "FontString" then
        return frame
    end
    
    -- Check children
    for i = 1, frame:GetNumChildren() do
        local child = select(i, frame:GetChildren())
        local result = addon:FindFontStringInFrame(child)
        if result then
            return result
        end
    end
    
    -- Check regions (for FontStrings that aren't children)
    for i = 1, frame:GetNumRegions() do
        local region = select(i, frame:GetRegions())
        if region and region:GetObjectType() == "FontString" then
            return region
        end
    end
    
    return nil
end

-- More robust bubble detection method
function addon:SetupAdvancedBubbleProcessing()
    -- Store original SetText function
    if not addon.originalSetText then
        addon.originalSetText = getmetatable(CreateFrame("Frame"):CreateFontString()).__index.SetText
        
        -- Hook into the SetText function of FontStrings
        getmetatable(CreateFrame("Frame"):CreateFontString()).__index.SetText = function(self, text)
            -- Check if this FontString might be part of a chat bubble
            if text and self:GetParent() and self:GetParent():GetParent() == WorldFrame then
                -- This might be a chat bubble
                if ChatEmojisDB and ChatEmojisDB.enabled and ChatEmojisDB.bubbleEmojis then
                    local processedText = addon:GetSmileyReplacementText(text)
                    addon.originalSetText(self, processedText)
                    return
                end
            end
            
            -- Call original function
            addon.originalSetText(self, text)
        end
    end
end

-- Initialize chat bubble processing
function addon:InitializeBubbleProcessing()
    if not ChatEmojisDB then return end
    
    -- Initialize bubble emoji setting if it doesn't exist
    if ChatEmojisDB.bubbleEmojis == nil then
        ChatEmojisDB.bubbleEmojis = true
    end
    
    -- Start bubble processing if enabled
    if ChatEmojisDB.bubbleEmojis then
        addon:ProcessChatBubbles()
        addon:SetupBubbleEventProcessing()
        addon:SetupAdvancedBubbleProcessing()
    end
end

-- Enable/disable bubble processing
function addon:ToggleBubbleProcessing(enable)
    if enable then
        addon:ProcessChatBubbles()
        addon:SetupBubbleEventProcessing()
        addon:SetupAdvancedBubbleProcessing()
    else
        -- Disable bubble processing
        if addon.bubbleFrame then
            addon.bubbleFrame:SetScript("OnUpdate", nil)
        end
        if addon.bubbleEventFrame then
            addon.bubbleEventFrame:UnregisterAllEvents()
        end
        
        -- Restore original SetText if we hooked it
        if addon.originalSetText then
            getmetatable(CreateFrame("Frame"):CreateFontString()).__index.SetText = addon.originalSetText
            addon.originalSetText = nil
        end
    end
end

-- Clean up bubble processing
function addon:CleanupBubbleProcessing()
    -- Restore original SetText function
    if addon.originalSetText then
        getmetatable(CreateFrame("Frame"):CreateFontString()).__index.SetText = addon.originalSetText
        addon.originalSetText = nil
    end
    
    -- Clean up frames
    if addon.bubbleFrame then
        addon.bubbleFrame:SetScript("OnUpdate", nil)
        addon.bubbleFrame = nil
    end
    
    if addon.bubbleEventFrame then
        addon.bubbleEventFrame:UnregisterAllEvents()
        addon.bubbleEventFrame = nil
    end
end