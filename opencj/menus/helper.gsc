onInit()
{
    level.searchTextDefault = "Type to search..";
}

onPlayerConnected(name)
{
    self.searchText = level.searchTextDefault;
    self.currentMenu = "";

    self thread onMenuResponse();
}

onMenuResponse()
{
    self endon("disconnect");
    level endon("game_ended");

    for(;;)
    {
        self waittill("menuresponse", menu, response);

        currentMenu = self.currentMenu;
        if ((menu == "opencj_leaderboard") && (response == "open_leaderboard")) // Leaderboard was opened
        {
            self.currentMenu = "opencj_leaderboard";
            self openCJ\menus\board_base::onBoardOpen("lb");
        }
        else if ((menu == "opencj_runsboard") && (response == "open_runsboard")) // Runsboard was opened
        {
            self.currentMenu = "opencj_runsboard";
            self openCJ\menus\board_base::onBoardOpen("rn");
        }
        else if ((menu == "opencj_maplist") && (response == "open_maplist")) // Maplist was opened
        {
            self.currentMenu = "opencj_maplist";
        }

        // Search text is used by various menus
        if (currentMenu != self.currentMenu)
        {
            self openCJ\menus\helper::clearSearchText();
        }
    }
}

onInputKey(keyName) // Called by playerCommand 'inputkey'
{
    keyName = toLower(keyName);

    // Simple cases: _ and 0-9a-zA-Z
    text = undefined;
    removeChar = false;
    if (keyName.size == 1)
    {
        if ((keyName == "_") || isAlphaNumeric(keyName))
        {
            text = keyName;
        }
    }
    else
    {
        // Special case(s)
        switch(keyName)
        {
            case "backspace":
            {
                if (self.searchText.size > 1)
                {
                    removeChar = true;
                }
            } break;
            default:
            {
                // Unhandled
            }
        }
    }

    if (removeChar)
    {
        self.searchText = getSubStr(self.searchText, 0, (self.searchText.size - 1));
    }
    else if (isDefined(text))
    {
        self.searchText += text;
    }

    // If search field is empty, show default explainer
    if (self.searchText.size == 0)
    {
        self.searchText = level.searchTextDefault;
    }

    // Let any menu scripts know that a character was typed
    self notify("inputkey_done");
}

clearSearchText()
{
    self.searchText = level.searchTextDefault;
    self notify("inputkey_done");
}