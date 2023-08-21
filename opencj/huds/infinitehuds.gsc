#include openCJ\util;

onInit()
{
    level.infiniteHudStrings = [];
}

initInfiniteHud(name)
{
    num = level.infiniteHudStrings.size;
    localizedString = findLocalizedString(num);
    if (!isDefined(localizedString))
    {
        // No room left, trigger crash to indicate
        crashVariable = undefined;
        crashVariable setText("Failed to make infinite HUD");
    }
    level.infiniteHudStrings[name] = spawnStruct();
    level.infiniteHudStrings[name].num = num;
    level.infiniteHudStrings[name].localizedString = localizedString;
    level.infiniteHudStrings[name].string = constructMessage(level.infiniteHudStrings[name].localizedString);
    precacheString(level.infiniteHudStrings[name].localizedString);
    level.infiniteHudStrings[name].configstringIndex = G_LocalizedStringIndex(level.infiniteHudStrings[name].string);
}

onPlayerConnected()
{
    keys = getArrayKeys(level.infiniteHudStrings);
    for(i = 0; i < keys.size; i++)
    {
        self SV_GameSendServerCommand("d " + level.infiniteHudStrings[keys[i]].configstringIndex + " ", true);
    }
}

createInfiniteStringHud(name)
{
    hud = newClientHudElem(self);
    hud.configstringIndex = level.infiniteHudStrings[name].configstringIndex;
    hud setText(level.infiniteHudStrings[name].localizedString);
    hud.lastText = "";
    self SV_GameSendServerCommand("d " + hud.configstringIndex + " ", true);
    hud.archived = false;
    return hud;
}

setInfiniteHudText(text, player, reliable)
{
    if(!isDefined(reliable))
    {
        reliable = false;
    }

    if(!player.isFirstSpawn && (text == self.lastText)) // If player hadn't spawned yet, then the existing value may have been set 'too early'
    {
        return;
    }

    self.lastText = text;
    player SV_GameSendServerCommand("d " + self.configstringIndex + " " + text, reliable);
}

findLocalizedString(num)
{
    switch(num)
    {
        case 0: return &"openCJPlaceHolderString0";
        case 1: return &"openCJPlaceHolderString1";
        case 2: return &"openCJPlaceHolderString2";
        case 3: return &"openCJPlaceHolderString3";
        case 4: return &"openCJPlaceHolderString4";
        case 5: return &"openCJPlaceHolderString5";
        case 6: return &"openCJPlaceHolderString6";
        case 7: return &"openCJPlaceHolderString7";
        case 8: return &"openCJPlaceHolderString8";
        case 9: return &"openCJPlaceHolderString9";
        case 10: return &"openCJPlaceHolderString10";
        case 11: return &"openCJPlaceHolderString11";
        case 12: return &"openCJPlaceHolderString12";
        case 13: return &"openCJPlaceHolderString13";
        case 14: return &"openCJPlaceHolderString14";
        case 15: return &"openCJPlaceHolderString15";
        case 16: return &"openCJPlaceHolderString16";
        default: return undefined;
    }
}