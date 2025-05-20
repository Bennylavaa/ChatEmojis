local addonName, addon = ...

-- Default settings
addon.defaults = {
    emojiSize = 16,
    enabled = true,
    textEmotes = true,
}

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

    -- Current size is used during the current session
    self.currentSize = ChatEmojisDB.emojiSize
end

-- Get current emoji size with formatting
function addon:GetEmojiSizeString()
    return ":" .. self.currentSize .. ":" .. self.currentSize
end

-- Media path
local M = [[Interface\AddOns\ChatEmojis\Media\]]

-- Storage for our emoji mappings
addon.Smileys = {}

-- Function to add emoji mappings
function addon:AddSmiley(key, texture)
    if key and (type(key) == "string") and texture then
        self.Smileys[key] = texture
    end
end

-- Function to remove emoji mappings if needed
function addon:RemoveSmiley(key)
    if key and (type(key) == "string") then
        self.Smileys[key] = nil
    end
end

-- Function to create texture strings
function addon:TextureString(texString, dataString)
    return "|T"..texString..(dataString or "").."|t"
end

-- Process chat message to insert emojis
function addon:InsertEmotions(msg)
    if not ChatEmojisDB.enabled then return msg end

    for word in string.gmatch(msg, "%s-(%S+)%s*") do
        local pattern = addon:EscapeString(word)
        local emoji

        -- If it looks like an emoji code (:word:), try lowercase matching
        if string.match(word, "^:[%w_]+:$") then
            local lowercaseWord = string.lower(word)
            local lowercasePattern = addon:EscapeString(lowercaseWord)
            emoji = self.Smileys[lowercasePattern]
        else
            emoji = self.Smileys[pattern]
        end

        if emoji then
            pattern = string.format("%s%s%s", "([%s%p]-)", pattern, "([%s%p]*)")

            if string.match(msg, pattern) then
                if LibBase64 and string.find(word, "^:[%w_]+:$") then
                    local base64 = LibBase64:Encode(word)
                    if base64 then
                        msg = string.gsub(msg, pattern, string.format("%s%s%s%s%s", "%1|Helvmoji:%%", base64, "|h|cFFffffff|r|h", emoji, "%2"))
                    else
                        msg = string.gsub(msg, pattern, string.format("%s%s%s", "%1", emoji, "%2"))
                    end
                else
                    msg = string.gsub(msg, pattern, string.format("%s%s%s", "%1", emoji, "%2"))
                end
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

-- Update emoji mappings with current size
function addon:UpdateEmojiMappings()
    wipe(self.Smileys)
    self:SetupDefaultEmojis()
end

-- Set up all emoticons
function addon:SetupDefaultEmojis()
    local x = self:GetEmojiSizeString()

    -- Normal Emojis
    self:AddSmiley(":angry:", self:TextureString(M..[[Emojis\Angry.tga]], x))
    self:AddSmiley(":blush:", self:TextureString(M..[[Emojis\Blush.tga]], x))
    self:AddSmiley(":broken_heart:", self:TextureString(M..[[Emojis\BrokenHeart.tga]], x))
    self:AddSmiley(":call_me:", self:TextureString(M..[[Emojis\CallMe.tga]], x))
    self:AddSmiley(":cry:", self:TextureString(M..[[Emojis\Cry.tga]], x))
    self:AddSmiley(":grin:", self:TextureString(M..[[Emojis\Grin.tga]], x))
    self:AddSmiley(":heart:", self:TextureString(M..[[Emojis\Heart.tga]], x))
    self:AddSmiley(":heart_eyes:", self:TextureString(M..[[Emojis\HeartEyes.tga]], x))
    self:AddSmiley(":joy:", self:TextureString(M..[[Emojis\Joy.tga]], x))
    self:AddSmiley(":middle_finger:", self:TextureString(M..[[Emojis\MiddleFinger.tga]], x))
    self:AddSmiley(":ok_hand:", self:TextureString(M..[[Emojis\OkHand.tga]], x))
    self:AddSmiley(":open_mouth:", self:TextureString(M..[[Emojis\OpenMouth.tga]], x))
    self:AddSmiley(":poop:", self:TextureString(M..[[Emojis\Poop.tga]], x))
    self:AddSmiley(":rage:", self:TextureString(M..[[Emojis\Rage.tga]], x))
    self:AddSmiley(":scream:", self:TextureString(M..[[Emojis\Scream.tga]], x))
    self:AddSmiley(":scream_cat:", self:TextureString(M..[[Emojis\ScreamCat.tga]], x))
    self:AddSmiley(":semi_colon:", self:TextureString(M..[[Emojis\SemiColon.tga]], x))
    self:AddSmiley(":slight_frown:", self:TextureString(M..[[Emojis\SlightFrown.tga]], x))
    self:AddSmiley(":smile:", self:TextureString(M..[[Emojis\Smile.tga]], x))
    self:AddSmiley(":smirk:", self:TextureString(M..[[Emojis\Smirk.tga]], x))
    self:AddSmiley(":sob:", self:TextureString(M..[[Emojis\Sob.tga]], x))
    self:AddSmiley(":stuck_out_tongue:", self:TextureString(M..[[Emojis\StuckOutTongue.tga]], x))
    self:AddSmiley(":stuck_out_tongue_closed_eyes:", self:TextureString(M..[[Emojis\StuckOutTongueClosedEyes.tga]], x))
    self:AddSmiley(":sunglasses:", self:TextureString(M..[[Emojis\Sunglasses.tga]], x))
    self:AddSmiley(":thinking:", self:TextureString(M..[[Emojis\Thinking.tga]], x))
    self:AddSmiley(":thumbs_up:", self:TextureString(M..[[Emojis\ThumbsUp.tga]], x))
    self:AddSmiley(":wink:", self:TextureString(M..[[Emojis\Wink.tga]], x))
    self:AddSmiley(":zzz:", self:TextureString(M..[[Emojis\ZZZ.tga]], x))

    -- Pepe Emojis
    self:AddSmiley(":peepoalliance:", self:TextureString(M..[[PepeEmojis\PeepoAlliance.tga]], x))
    self:AddSmiley(":peepohorde:", self:TextureString(M..[[PepeEmojis\PeepoHorde.tga]], x))
    self:AddSmiley(":pepepanties:", self:TextureString(M..[[PepeEmojis\PepePanties.tga]], x))
    self:AddSmiley(":pepewarlock:", self:TextureString(M..[[PepeEmojis\PepeWarlock.tga]], x))

    -- Discord Emojis
    self:AddSmiley(":4head:", self:TextureString(M..[[DiscordEmojis\4Head.tga]], x))
    self:AddSmiley(":5head:", self:TextureString(M..[[DiscordEmojis\5Head.tga]], x))
    self:AddSmiley(":ambessalove:", self:TextureString(M..[[DiscordEmojis\AmbessaLove.tga]], x))
    self:AddSmiley(":andalusiancrush:", self:TextureString(M..[[DiscordEmojis\AndalusianCrush.tga]], x))
    self:AddSmiley(":anele:", self:TextureString(M..[[DiscordEmojis\ANELE.tga]], x))
    self:AddSmiley(":anotherrecord:", self:TextureString(M..[[DiscordEmojis\AnotherRecord.tga]], x))
    self:AddSmiley(":argieb8:", self:TextureString(M..[[DiscordEmojis\ArgieB8.tga]], x))
    self:AddSmiley(":arsonnosexy:", self:TextureString(M..[[DiscordEmojis\ArsonNoSexy.tga]], x))
    self:AddSmiley(":asexualpride:", self:TextureString(M..[[DiscordEmojis\AsexualPride.tga]], x))
    self:AddSmiley(":asianglow:", self:TextureString(M..[[DiscordEmojis\AsianGlow.tga]], x))
    self:AddSmiley(":babyrage:", self:TextureString(M..[[DiscordEmojis\BabyRage.tga]], x))
    self:AddSmiley(":bangboobounce:", self:TextureString(M..[[DiscordEmojis\BangbooBounce.tga]], x))
    self:AddSmiley(":batchest:", self:TextureString(M..[[DiscordEmojis\BatChest.tga]], x))
    self:AddSmiley(":bcwarrior:", self:TextureString(M..[[DiscordEmojis\BCWarrior.tga]], x))
    self:AddSmiley(":begwan:", self:TextureString(M..[[DiscordEmojis\BegWan.tga]], x))
    self:AddSmiley(":bigbrother:", self:TextureString(M..[[DiscordEmojis\BigBrother.tga]], x))
    self:AddSmiley(":bigphish:", self:TextureString(M..[[DiscordEmojis\BigPhish.tga]], x))
    self:AddSmiley(":bigsad:", self:TextureString(M..[[DiscordEmojis\BigSad.tga]], x))
    self:AddSmiley(":bisexualpride:", self:TextureString(M..[[DiscordEmojis\BisexualPride.tga]], x))
    self:AddSmiley(":blacklivesmatter:", self:TextureString(M..[[DiscordEmojis\BlackLivesMatter.tga]], x))
    self:AddSmiley(":blargnaut:", self:TextureString(M..[[DiscordEmojis\BlargNaut.tga]], x))
    self:AddSmiley(":bleedpurple:", self:TextureString(M..[[DiscordEmojis\BleedPurple.tga]], x))
    self:AddSmiley(":bloodtrail:", self:TextureString(M..[[DiscordEmojis\BloodTrail.tga]], x))
    self:AddSmiley(":bop:", self:TextureString(M..[[DiscordEmojis\BOP.tga]], x))
    self:AddSmiley(":brain:", self:TextureString(M..[[DiscordEmojis\Brain.tga]], x))
    self:AddSmiley(":brainslug:", self:TextureString(M..[[DiscordEmojis\BrainSlug.tga]], x))
    self:AddSmiley(":bratchat:", self:TextureString(M..[[DiscordEmojis\BratChat.tga]], x))
    self:AddSmiley(":brokeback:", self:TextureString(M..[[DiscordEmojis\BrokeBack.tga]], x))
    self:AddSmiley(":buddhabar:", self:TextureString(M..[[DiscordEmojis\BuddhaBar.tga]], x))
    self:AddSmiley(":caitlyns:", self:TextureString(M..[[DiscordEmojis\Caitlyns.tga]], x))
    self:AddSmiley(":caitthinking:", self:TextureString(M..[[DiscordEmojis\CaitThinking.tga]], x))
    self:AddSmiley(":carlsmile:", self:TextureString(M..[[DiscordEmojis\CarlSmile.tga]], x))
    self:AddSmiley(":cheffrank:", self:TextureString(M..[[DiscordEmojis\ChefFrank.tga]], x))
    self:AddSmiley(":chewyyay:", self:TextureString(M..[[DiscordEmojis\ChewyYAY.tga]], x))
    self:AddSmiley(":cinheimer:", self:TextureString(M..[[DiscordEmojis\Cinheimer.tga]], x))
    self:AddSmiley(":cmonbruh:", self:TextureString(M..[[DiscordEmojis\CmonBruh.tga]], x))
    self:AddSmiley(":coolcat:", self:TextureString(M..[[DiscordEmojis\CoolCat.tga]], x))
    self:AddSmiley(":coolstorybob:", self:TextureString(M..[[DiscordEmojis\CoolStoryBob.tga]], x))
    self:AddSmiley(":copythis:", self:TextureString(M..[[DiscordEmojis\CopyThis.tga]], x))
    self:AddSmiley(":corgiderp:", self:TextureString(M..[[DiscordEmojis\CorgiDerp.tga]], x))
    self:AddSmiley(":crreamawk:", self:TextureString(M..[[DiscordEmojis\CrreamAwk.tga]], x))
    self:AddSmiley(":crythumbsup:", self:TextureString(M..[[DiscordEmojis\CryThumbsUp.tga]], x))
    self:AddSmiley(":cuckcru:", self:TextureString(M..[[DiscordEmojis\CuckCru.tga]], x))
    self:AddSmiley(":curselit:", self:TextureString(M..[[DiscordEmojis\CurseLit.tga]], x))
    self:AddSmiley(":d8style:", self:TextureString(M..[[DiscordEmojis\D8style.tga]], x))
    self:AddSmiley(":daesupply:", self:TextureString(M..[[DiscordEmojis\DAESupply.tga]], x))
    self:AddSmiley(":dansgame:", self:TextureString(M..[[DiscordEmojis\DansGame.tga]], x))
    self:AddSmiley(":darkknight:", self:TextureString(M..[[DiscordEmojis\DarkKnight.tga]], x))
    self:AddSmiley(":darkmode:", self:TextureString(M..[[DiscordEmojis\DarkMode.tga]], x))
    self:AddSmiley(":datsheffy:", self:TextureString(M..[[DiscordEmojis\DatSheffy.tga]], x))
    self:AddSmiley(":dendiface:", self:TextureString(M..[[DiscordEmojis\DendiFace.tga]], x))
    self:AddSmiley(":dinodance:", self:TextureString(M..[[DiscordEmojis\DinoDance.tga]], x))
    self:AddSmiley(":dogface:", self:TextureString(M..[[DiscordEmojis\DogFace.tga]], x))
    self:AddSmiley(":doritoschip:", self:TextureString(M..[[DiscordEmojis\DoritosChip.tga]], x))
    self:AddSmiley(":dududu:", self:TextureString(M..[[DiscordEmojis\duDudu.tga]], x))
    self:AddSmiley(":dxcat:", self:TextureString(M..[[DiscordEmojis\DxCat.tga]], x))
    self:AddSmiley(":facepalm:", self:TextureString(M..[[DiscordEmojis\Facepalm.tga]], x))
    self:AddSmiley(":gigachad:", self:TextureString(M..[[DiscordEmojis\GigaChad.tga]], x))
    self:AddSmiley(":gorlock:", self:TextureString(M..[[DiscordEmojis\Gorlock.tga]], x))
    self:AddSmiley(":harold:", self:TextureString(M..[[DiscordEmojis\Harold.tga]], x))
    self:AddSmiley(":huh:", self:TextureString(M..[[DiscordEmojis\Huh.tga]], x))
    self:AddSmiley(":jebaited:", self:TextureString(M..[[DiscordEmojis\Jebaited.tga]], x))
    self:AddSmiley(":kappa:", self:TextureString(M..[[DiscordEmojis\Kappa.tga]], x))
    self:AddSmiley(":kekw:", self:TextureString(M..[[DiscordEmojis\Kekw.tga]], x))
    self:AddSmiley(":meaw:", self:TextureString(M..[[DiscordEmojis\Meaw.tga]], x))
    self:AddSmiley(":pog:", self:TextureString(M..[[DiscordEmojis\Pog.tga]], x))
    self:AddSmiley(":pogchamp:", self:TextureString(M..[[DiscordEmojis\PogChamp.tga]], x))
    self:AddSmiley(":pogging:", self:TextureString(M..[[DiscordEmojis\Pogging.tga]], x))
    self:AddSmiley(":sadkitty:", self:TextureString(M..[[DiscordEmojis\SadKitty.tga]], x))
    self:AddSmiley(":shocked:", self:TextureString(M..[[DiscordEmojis\Shocked.tga]], x))
    self:AddSmiley(":thonkers:", self:TextureString(M..[[DiscordEmojis\Thonkers.tga]], x))
    self:AddSmiley(":troll:", self:TextureString(M..[[DiscordEmojis\Troll.tga]], x))

    -- Warcraft Emojis
    self:AddSmiley(":alliance:", self:TextureString(M..[[WoWEmojis\Alliance.tga]], x))
    self:AddSmiley(":disenchant:", self:TextureString(M..[[WoWEmojis\Disenchant.tga]], x))
    self:AddSmiley(":druid:", self:TextureString(M..[[WoWEmojis\Druid.tga]], x))
    self:AddSmiley(":feelshordeman:", self:TextureString(M..[[WoWEmojis\FeelsHordeMan.tga]], x))
    self:AddSmiley(":femaledwarf:", self:TextureString(M..[[WoWEmojis\FemaleDwarf.tga]], x))
    self:AddSmiley(":femalegnome:", self:TextureString(M..[[WoWEmojis\FemaleGnome.tga]], x))
    self:AddSmiley(":femalehuman:", self:TextureString(M..[[WoWEmojis\FemaleHuman.tga]], x))
    self:AddSmiley(":femalenightelf:", self:TextureString(M..[[WoWEmojis\FemaleNightelf.tga]], x))
    self:AddSmiley(":femaleorc:", self:TextureString(M..[[WoWEmojis\FemaleOrc.tga]], x))
    self:AddSmiley(":femaletauren:", self:TextureString(M..[[WoWEmojis\FemaleTauren.tga]], x))
    self:AddSmiley(":femaletroll:", self:TextureString(M..[[WoWEmojis\FemaleTroll.tga]], x))
    self:AddSmiley(":femaleundead:", self:TextureString(M..[[WoWEmojis\FemaleUndead.tga]], x))
    self:AddSmiley(":gryphon:", self:TextureString(M..[[WoWEmojis\Gryphon.tga]], x))
    self:AddSmiley(":hogger:", self:TextureString(M..[[WoWEmojis\Hogger.tga]], x))
    self:AddSmiley(":horde:", self:TextureString(M..[[WoWEmojis\Horde.tga]], x))
    self:AddSmiley(":hunter:", self:TextureString(M..[[WoWEmojis\Hunter.tga]], x))
    self:AddSmiley(":kekdwarf:", self:TextureString(M..[[WoWEmojis\KekDwarf.tga]], x))
    self:AddSmiley(":mage:", self:TextureString(M..[[WoWEmojis\Mage.tga]], x))
    self:AddSmiley(":maledwarf:", self:TextureString(M..[[WoWEmojis\MaleDwarf.tga]], x))
    self:AddSmiley(":malegnome:", self:TextureString(M..[[WoWEmojis\MaleGnome.tga]], x))
    self:AddSmiley(":malehuman:", self:TextureString(M..[[WoWEmojis\MaleHuman.tga]], x))
    self:AddSmiley(":malenightelf:", self:TextureString(M..[[WoWEmojis\MaleNightelf.tga]], x))
    self:AddSmiley(":malenightelf2:", self:TextureString(M..[[WoWEmojis\MaleNightelf2.tga]], x))
    self:AddSmiley(":maleorc:", self:TextureString(M..[[WoWEmojis\MaleOrc.tga]], x))
    self:AddSmiley(":maletauren:", self:TextureString(M..[[WoWEmojis\MaleTauren.tga]], x))
    self:AddSmiley(":maletroll:", self:TextureString(M..[[WoWEmojis\MaleTroll.tga]], x))
    self:AddSmiley(":maleundead:", self:TextureString(M..[[WoWEmojis\MaleUndead.tga]], x))
    self:AddSmiley(":metzen:", self:TextureString(M..[[WoWEmojis\Metzen.tga]], x))
    self:AddSmiley(":moonkin:", self:TextureString(M..[[WoWEmojis\Moonkin.tga]], x))
    self:AddSmiley(":murloc:", self:TextureString(M..[[WoWEmojis\Murloc.tga]], x))
    self:AddSmiley(":omegawow:", self:TextureString(M..[[WoWEmojis\Omegawow.tga]], x))
    self:AddSmiley(":paladin:", self:TextureString(M..[[WoWEmojis\Paladin.tga]], x))
    self:AddSmiley(":priest:", self:TextureString(M..[[WoWEmojis\Priest.tga]], x))
    self:AddSmiley(":rogue:", self:TextureString(M..[[WoWEmojis\Rogue.tga]], x))
    self:AddSmiley(":samwise:", self:TextureString(M..[[WoWEmojis\Samwise.tga]], x))
    self:AddSmiley(":shaman:", self:TextureString(M..[[WoWEmojis\Shaman.tga]], x))
    self:AddSmiley(":teldrachad:", self:TextureString(M..[[WoWEmojis\TeldraChad.tga]], x))
    self:AddSmiley(":uwutuskarr:", self:TextureString(M..[[WoWEmojis\UwuTuskarr.tga]], x))
    self:AddSmiley(":warcraft:", self:TextureString(M..[[WoWEmojis\Warcraft.tga]], x))
    self:AddSmiley(":warlock:", self:TextureString(M..[[WoWEmojis\Warlcok.tga]], x))
    self:AddSmiley(":warrior:", self:TextureString(M..[[WoWEmojis\Warrior.tga]], x))

    -- Epoch Emojis
    self:AddSmiley(":epog:", self:TextureString(M..[[EpochEmojis\Epog.tga]], x))

    -- Gnome Emojis
    self:AddSmiley(":gnomebatman:", self:TextureString(M..[[GnomeEmojis\GnomeBatman.tga]], x))
    self:AddSmiley(":gnomebender:", self:TextureString(M..[[GnomeEmojis\GnomeBender.tga]], x))
    self:AddSmiley(":gnomecandle:", self:TextureString(M..[[GnomeEmojis\GnomeCandle.tga]], x))
    self:AddSmiley(":gnomecandleman:", self:TextureString(M..[[GnomeEmojis\GnomeCandleman.tga]], x))
    self:AddSmiley(":gnomechad:", self:TextureString(M..[[GnomeEmojis\GnomeChad.tga]], x))
    self:AddSmiley(":gnomeclown:", self:TextureString(M..[[GnomeEmojis\GnomeClown.tga]], x))
    self:AddSmiley(":gnomedevil:", self:TextureString(M..[[GnomeEmojis\GnomeDevil.tga]], x))
    self:AddSmiley(":gnomedracula:", self:TextureString(M..[[GnomeEmojis\GnomeDracula.tga]], x))
    self:AddSmiley(":gnomedragonborn:", self:TextureString(M..[[GnomeEmojis\GnomeDragonborn.tga]], x))
    self:AddSmiley(":gnomedruid:", self:TextureString(M..[[GnomeEmojis\GnomeDruid.tga]], x))
    self:AddSmiley(":gnomeexistential:", self:TextureString(M..[[GnomeEmojis\GnomeExistential.tga]], x))
    self:AddSmiley(":gnomeexoticmonk:", self:TextureString(M..[[GnomeEmojis\GnomeExoticMonk.tga]], x))
    self:AddSmiley(":gnomefelguard:", self:TextureString(M..[[GnomeEmojis\GnomeFelguard.tga]], x))
    self:AddSmiley(":gnomeforsaken:", self:TextureString(M..[[GnomeEmojis\GnomeForsaken.tga]], x))
    self:AddSmiley(":gnomegarithos:", self:TextureString(M..[[GnomeEmojis\GnomeGarithos.tga]], x))
    self:AddSmiley(":gnomegoblin:", self:TextureString(M..[[GnomeEmojis\GnomeGoblin.tga]], x))
    self:AddSmiley(":gnomegodfather:", self:TextureString(M..[[GnomeEmojis\GnomeGodfather.tga]], x))
    self:AddSmiley(":gnomegon:", self:TextureString(M..[[GnomeEmojis\GnomeGon.tga]], x))
    self:AddSmiley(":gnomeguts:", self:TextureString(M..[[GnomeEmojis\GnomeGuts.tga]], x))
    self:AddSmiley(":gnomehoplite:", self:TextureString(M..[[GnomeEmojis\GnomeHoplite.tga]], x))
    self:AddSmiley(":gnomeillidan:", self:TextureString(M..[[GnomeEmojis\GnomeIllidan.tga]], x))
    self:AddSmiley(":gnomeironman:", self:TextureString(M..[[GnomeEmojis\GnomeIronman.tga]], x))
    self:AddSmiley(":gnomejoker:", self:TextureString(M..[[GnomeEmojis\GnomeJoker.tga]], x))
    self:AddSmiley(":gnomejudge:", self:TextureString(M..[[GnomeEmojis\GnomeJudge.tga]], x))
    self:AddSmiley(":gnomekratos:", self:TextureString(M..[[GnomeEmojis\GnomeKratos.tga]], x))
    self:AddSmiley(":gnomeloki:", self:TextureString(M..[[GnomeEmojis\GnomeLoki.tga]], x))
    self:AddSmiley(":gnomemage:", self:TextureString(M..[[GnomeEmojis\GnomeMage.tga]], x))
    self:AddSmiley(":gnomemanhattan:", self:TextureString(M..[[GnomeEmojis\GnomeManhattan.tga]], x))
    self:AddSmiley(":gnomemario:", self:TextureString(M..[[GnomeEmojis\GnomeMario.tga]], x))
    self:AddSmiley(":gnomemickey:", self:TextureString(M..[[GnomeEmojis\GnomeMickey.tga]], x))
    self:AddSmiley(":gnomemonk:", self:TextureString(M..[[GnomeEmojis\GnomeMonk.tga]], x))
    self:AddSmiley(":gnomenaga:", self:TextureString(M..[[GnomeEmojis\GnomeNaga.tga]], x))
    self:AddSmiley(":gnomeninja:", self:TextureString(M..[[GnomeEmojis\GnomeNinja.tga]], x))
    self:AddSmiley(":gnomeorc:", self:TextureString(M..[[GnomeEmojis\GnomeOrc.tga]], x))
    self:AddSmiley(":gnomeorochimaru:", self:TextureString(M..[[GnomeEmojis\GnomeOrochimaru.tga]], x))
    self:AddSmiley(":gnomeshaman:", self:TextureString(M..[[GnomeEmojis\GnomeShaman.tga]], x))
    self:AddSmiley(":gnomesonic:", self:TextureString(M..[[GnomeEmojis\GnomeSonic.tga]], x))
    self:AddSmiley(":gnomespace:", self:TextureString(M..[[GnomeEmojis\GnomeSpace.tga]], x))
    self:AddSmiley(":gnomesquidward:", self:TextureString(M..[[GnomeEmojis\GnomeSquidward.tga]], x))
    self:AddSmiley(":gnometemplar:", self:TextureString(M..[[GnomeEmojis\GnomeTemplar.tga]], x))
    self:AddSmiley(":gnomethor:", self:TextureString(M..[[GnomeEmojis\GnomeThor.tga]], x))
    self:AddSmiley(":gnometoji:", self:TextureString(M..[[GnomeEmojis\GnomeToji.tga]], x))
    self:AddSmiley(":gnomeultramarine:", self:TextureString(M..[[GnomeEmojis\GnomeUltramarine.tga]], x))
    self:AddSmiley(":gnomewitcher:", self:TextureString(M..[[GnomeEmojis\GnomeWitcher.tga]], x))
    self:AddSmiley(":gnomewolverine:", self:TextureString(M..[[GnomeEmojis\GnomeWolverine.tga]], x))

    -- Pony Emojis
    self:AddSmiley(":ponysylvy:", self:TextureString(M..[[PonyEmojis\PonySylvy.tga]], x))
    self:AddSmiley(":ponywhitemane:", self:TextureString(M..[[PonyEmojis\PonyWhitemane.tga]], x))
    self:AddSmiley(":ponygarithos:", self:TextureString(M..[[PonyEmojis\PonyGarithos.tga]], x))

    -- Only add text emoticons if enabled
    if ChatEmojisDB.textEmotes then
        self:AddSmiley(">:%(", self:TextureString(M..[[Emojis\Rage.tga]], x))
        self:AddSmiley(":%$", self:TextureString(M..[[Emojis\Blush.tga]], x))
        self:AddSmiley("<\\3", self:TextureString(M..[[Emojis\BrokenHeart.tga]], x))
        self:AddSmiley(":\'%)", self:TextureString(M..[[Emojis\Joy.tga]], x))
        self:AddSmiley(";\'%)", self:TextureString(M..[[Emojis\Joy.tga]], x))
        self:AddSmiley(",,!,,", self:TextureString(M..[[Emojis\MiddleFinger.tga]], x))
        self:AddSmiley("D:<", self:TextureString(M..[[Emojis\Rage.tga]], x))
        self:AddSmiley(":o3", self:TextureString(M..[[Emojis\ScreamCat.tga]], x))
        self:AddSmiley("XP", self:TextureString(M..[[Emojis\StuckOutTongueClosedEyes.tga]], x))
        self:AddSmiley("8%-%)", self:TextureString(M..[[Emojis\Sunglasses.tga]], x))
        self:AddSmiley("8%)", self:TextureString(M..[[Emojis\Sunglasses.tga]], x))
        self:AddSmiley(":%+1:", self:TextureString(M..[[Emojis\ThumbsUp.tga]], x))
        self:AddSmiley(":;:", self:TextureString(M..[[Emojis\SemiColon.tga]], x))
        self:AddSmiley(";o;", self:TextureString(M..[[Emojis\Sob.tga]], x))
        self:AddSmiley(":%-@", self:TextureString(M..[[Emojis\Angry.tga]], x))
        self:AddSmiley(":@", self:TextureString(M..[[Emojis\Angry.tga]], x))
        self:AddSmiley(":%-%)", self:TextureString(M..[[Emojis\Smile.tga]], x))
        self:AddSmiley(":%)", self:TextureString(M..[[Emojis\Smile.tga]], x))
        self:AddSmiley(":D", self:TextureString(M..[[Emojis\Grin.tga]], x))
        self:AddSmiley(":%-D", self:TextureString(M..[[Emojis\Grin.tga]], x))
        self:AddSmiley(";%-D", self:TextureString(M..[[Emojis\Grin.tga]], x))
        self:AddSmiley(";D", self:TextureString(M..[[Emojis\Grin.tga]], x))
        self:AddSmiley("=D", self:TextureString(M..[[Emojis\Grin.tga]], x))
        self:AddSmiley("xD", self:TextureString(M..[[Emojis\Grin.tga]], x))
        self:AddSmiley("XD", self:TextureString(M..[[Emojis\Grin.tga]], x))
        self:AddSmiley(":%-%(", self:TextureString(M..[[Emojis\SlightFrown.tga]], x))
        self:AddSmiley(":%(", self:TextureString(M..[[Emojis\SlightFrown.tga]], x))
        self:AddSmiley(":o", self:TextureString(M..[[Emojis\OpenMouth.tga]], x))
        self:AddSmiley(":%-o", self:TextureString(M..[[Emojis\OpenMouth.tga]], x))
        self:AddSmiley(":%-O", self:TextureString(M..[[Emojis\OpenMouth.tga]], x))
        self:AddSmiley(":O", self:TextureString(M..[[Emojis\OpenMouth.tga]], x))
        self:AddSmiley(":%-0", self:TextureString(M..[[Emojis\OpenMouth.tga]], x))
        self:AddSmiley(":P", self:TextureString(M..[[Emojis\StuckOutTongue.tga]], x))
        self:AddSmiley(":%-P", self:TextureString(M..[[Emojis\StuckOutTongue.tga]], x))
        self:AddSmiley(":p", self:TextureString(M..[[Emojis\StuckOutTongue.tga]], x))
        self:AddSmiley(":%-p", self:TextureString(M..[[Emojis\StuckOutTongue.tga]], x))
        self:AddSmiley("=P", self:TextureString(M..[[Emojis\StuckOutTongue.tga]], x))
        self:AddSmiley("=p", self:TextureString(M..[[Emojis\StuckOutTongue.tga]], x))
        self:AddSmiley(";%-p", self:TextureString(M..[[Emojis\StuckOutTongueClosedEyes.tga]], x))
        self:AddSmiley(";p", self:TextureString(M..[[Emojis\StuckOutTongueClosedEyes.tga]], x))
        self:AddSmiley(";P", self:TextureString(M..[[Emojis\StuckOutTongueClosedEyes.tga]], x))
        self:AddSmiley(";%-P", self:TextureString(M..[[Emojis\StuckOutTongueClosedEyes.tga]], x))
        self:AddSmiley(";%-%)", self:TextureString(M..[[Emojis\Wink.tga]], x))
        self:AddSmiley(";%)", self:TextureString(M..[[Emojis\Wink.tga]], x))
        self:AddSmiley(":S", self:TextureString(M..[[Emojis\Smirk.tga]], x))
        self:AddSmiley(":%-S", self:TextureString(M..[[Emojis\Smirk.tga]], x))
        self:AddSmiley(":,%(", self:TextureString(M..[[Emojis\Cry.tga]], x))
        self:AddSmiley(":,%-%(", self:TextureString(M..[[Emojis\Cry.tga]], x))
        self:AddSmiley(":\'%(", self:TextureString(M..[[Emojis\Cry.tga]], x))
        self:AddSmiley(":\'%-%(", self:TextureString(M..[[Emojis\Cry.tga]], x))
        self:AddSmiley(":F", self:TextureString(M..[[Emojis\MiddleFinger.tga]], x))
        self:AddSmiley("<3", self:TextureString(M..[[Emojis\Heart.tga]], x))
        self:AddSmiley("</3", self:TextureString(M..[[Emojis\BrokenHeart.tga]], x))
    end
end

-- Main chat filter function to intercept and process messages
function addon:ChatFilter(frame, event, msg, author, ...)
    if not ChatEmojisDB.enabled or not msg or msg == "" then
        return false, msg, author, ...
    end

    msg = addon:GetSmileyReplacementText(msg)
    return false, msg, author, ...
end

-- Create options panel
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
                local path = M .. "Emojis\\" .. emojiName:gsub("_", "") .. ".tga"
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

    InterfaceOptions_AddCategory(panel)

    return panel
end

-- Initialize the addon
function addon:Initialize()
    self:InitSettings()

    if LibStub then
        local success, lib = pcall(LibStub, "LibBase64-1.0")
        if success then
            LibBase64 = lib
        end
    end

    self:SetupDefaultEmojis()

    self:CreateOptions()

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

    print("|cFF00CCFFChat|r|cFFFF6600Emojis|r: Addon loaded! Type emoji codes like |cFFFFD100:smile:|r in chat.")
end

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

-- Updater
function hcstrsplit(delimiter, subject)
  if not subject then return nil end
  local delimiter, fields = delimiter or ":", {}
  local pattern = string.format("([^%s]+)", delimiter)
  string.gsub(subject, pattern, function(c) fields[table.getn(fields)+1] = c end)
  return unpack(fields)
end

local major, minor, fix = hcstrsplit(".", tostring(GetAddOnMetadata("ChatEmojis", "Version")))
fix = fix or 0 -- Set fix to 0 if it is nil

local alreadyshown = false
local localversion  = tonumber(major*10000 + minor*100 + fix)
local remoteversion = tonumber(gpiupdateavailable) or 0
local loginchannels = { "BATTLEGROUND", "RAID", "GUILD", "PARTY" }
local groupchannels = { "BATTLEGROUND", "RAID", "PARTY" }

gpiupdater = CreateFrame("Frame")
gpiupdater:RegisterEvent("CHAT_MSG_ADDON")
gpiupdater:RegisterEvent("PLAYER_ENTERING_WORLD")
gpiupdater:RegisterEvent("PARTY_MEMBERS_CHANGED")
gpiupdater:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local arg1, arg2 = ...
        if arg1 == "ChatEmojis" then
            local v, remoteversion = hcstrsplit(":", arg2)
            remoteversion = tonumber(remoteversion)
            if v == "VERSION" and remoteversion then
                if remoteversion > localversion then
                    gpiupdateavailable = remoteversion
                    if not alreadyshown then
                        print("|cFF00CCFFChat|r|cFFFF6600Emojis|r New version available! |cff66ccffhttps://github.com/Bennylavaa/ChatEmojis|r")
                        alreadyshown = true
                    end
                end
            end
            --This is a little check that I can use to see if people are actually using the addon.
            if v == "PING?" then
                for _, chan in ipairs(loginchannels) do
                    SendAddonMessage("ChatEmojis", "PONG!:"..GetAddOnMetadata("ChatEmojis", "Version"), chan)
                end
            end
            if v == "PONG!" then
                --print(arg1 .." "..arg2.." "..arg3.." "..arg4)
            end
        end

        if event == "PARTY_MEMBERS_CHANGED" then
            local groupsize = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers() > 0 and GetNumPartyMembers() or 0
            if (this.group or 0) < groupsize then
                for _, chan in ipairs(groupchannels) do
                    SendAddonMessage("ChatEmojis", "VERSION:" .. localversion, chan)
                end
            end
            this.group = groupsize
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if not alreadyshown and localversion < remoteversion then
            print("|cFF00CCFFChat|r|cFFFF6600Emojis|r New version available! |cff66ccffhttps://github.com/Bennylavaa/ChatEmojis|r")
            gpiupdateavailable = localversion
            alreadyshown = true
        end

        for _, chan in ipairs(loginchannels) do
            SendAddonMessage("ChatEmojis", "VERSION:" .. localversion, chan)
        end
    end
end)
