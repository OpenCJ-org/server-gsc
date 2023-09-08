#include openCJ\util;

onInit()
{
    precacheMenu("opencj_maplist");

    level.mapListDvarPrefix = "opencj_ui_maplist_";
    level.mapListUniqueHandle = "maplist";
    level.mapListMaxEntriesPerPage = 20; // Hardcoded in menu
}

onPlayerConnected()
{
    // Default information
    self.mapList = [];
    self.mapList["selected"] = -1;

    // TODO: paging could be abstracted so it reduces duplicate code between board_base and maplist
    self.mapList["curPage"] = 1;
    self.mapList["maxPage"] = max(1, ceil(level.maps.size / level.mapListMaxEntriesPerPage)); // Isn't a level variable because level.maps.size might not be ready in time for onInit()

    // Start setting the map list cvars because they shouldn't be changing during the game
    cvars = [];
    cvars[level.mapListDvarPrefix + "page"] = self.mapList["curPage"];
    cvars[level.mapListDvarPrefix + "pagemax"] = self.mapList["maxPage"];
    cvars[level.mapListDvarPrefix + "pagetxt"] = self.mapList["curPage"] + "/" + self.mapList["maxPage"];
    cvars[level.mapListDvarPrefix + "loadimage"] = "default";
    cvars[level.mapListDvarPrefix + "selected"] = self.mapList["selected"];
    cvars[level.mapListDvarPrefix + "date"] = "";
    cvars[level.mapListDvarPrefix + "author"] = "";
    cvars[level.mapListDvarPrefix + "desc"] = "";

    for (i = 0; i < level.mapListMaxEntriesPerPage; i++)
    {
        dvarName = level.mapListDvarPrefix + "map" + i;
        if (i < level.maps.size)
        {
            cvars[dvarName] = level.maps[i]["name"];
        }
        else
        {
            cvars[dvarName] = ""; 
        }
    }

    // Set the dvars over time, which is fine because player just connected and hasn't opened map list yet
    self thread _detectCvarsLoaded();
    self thread setALotOfCvars(cvars, level.mapListUniqueHandle);

    // Handle menu responses and search text of the player
    self thread onMenuResponse();
    self thread onSearchText();
}

_detectCvarsLoaded()
{
    self endon("disconnect");

    self.mapListCvarsLoaded = false;
    self waittill("setalot_" + level.mapListUniqueHandle);
    self.mapListCvarsLoaded = true;
}

onSearchText()
{
    self setClientCvar(level.mapListDvarPrefix + "textfield", "");
    for(;;)
    {
        self waittill("inputkey_done");
        self setClientCvar(level.mapListDvarPrefix + "textfield", self.searchText);
    }
}

onMenuResponse()
{
    self endon("disconnect");
    level endon("game_ended");

    for(;;)
    {
        self waittill("menuresponse", menu, response);

        // Wait until cvars are loaded before allowing player to click things.
        // TODO: this could be made smarter
        if (!self.mapListCvarsLoaded)
        {
            continue;
        }

        if (self.currentMenu != "opencj_maplist")
        {
            continue;
        }

        button = undefined;
        if (isSubStr(response, "click_"))
        {
            button = getSubStr(response, 6); 
        }
        if (isDefined(button)) // A button on the current board was clicked
        {
            if (button == "maplist_extendtime") // Vote for more time for current map
            {
                self _handleVote("extend");
            }
            else if (button == "maplist_vote") // Vote for a new map
            {
                self _handleVote("map");
            }
            else if (button == "maplist_end") // Vote for ending current map and going to end map vote
            {
                self _handleVote("end");
            }
            else if (button == "maplist_nominate")
            {
                // Not implemented yet
            }
            else if (button == "maplist_showrecords")
            {
                // Not implemented yet
            }
            else if (isSubStr(button, "page")) // Route or board previous/next page
            {
                self _handlePageChange(button);
            }
            else if (isSubStr(button, "map")) // Should be last check, because this string overlaps with some others
            {
                self _handleSelectionChange(getSubStr(button, 3));
            }
        }
    }
}

_handleSelectionChange(newIdx)
{
    if (isValidInt(newIdx) && (newIdx < level.maps.size))
    {
        self.mapList["selected"] = int(newIdx);
        self _updateMapList();
    }
}

_handleVote(typeStr)
{
    args = [];
    if (typeStr == "extend")
    {
        args[0] = "extend";
    }
    else if (typeStr == "map")
    {
        if (!isDefined(self.mapList["selected"]) || (self.mapList["selected"] == -1))
        {
            return;
        }

        args[0] = "map";
        args[1] = self.mapList["selected"];
    }
    else
    {
        if (typeStr == "end")
        {
            // Not implemented yet
        }
        return;
    }

    self closeMenu();
    self openCJ\vote::vote(args);
}

_handlePageChange(button)
{
    isPrevPage = isSubStr(button, "prev");
    page = self.mapList["curPage"];
    if (isPrevPage)
    {
        if (self.mapList["curPage"] > 1)
        {
            self.mapList["curPage"]--;
        }
    }
    else // Next page
    {
        if (self.mapList["curPage"] < self.mapList["maxPage"])
        {
            self.mapList["curPage"]++;
        }
    }

    if (page != self.mapList["curPage"])
    {
        self.mapList["selected"] = -1; // Reset selection if page changed
        self _setMapsForCurrentPage();
        self _updateMapList();
    }
}

_setMapsForCurrentPage()
{
    offset = (self.mapList["curPage"] - 1) * level.mapListMaxEntriesPerPage;
    nrMaps = level.maps.size - offset;
    for (i = 0; i < level.mapListMaxEntriesPerPage; i++)
    {
        dvarName = level.mapListDvarPrefix + "map" + i;
        if (i < nrMaps)
        {
            self setClientDvar(dvarName, level.maps[i + offset]["name"]);
        }
        else
        {
            self setClientDvar(dvarName, ""); 
        }
    }
}

_updateMapList()
{
    // Update page text dvars
    self setClientCvar(level.mapListDvarPrefix + "pagetxt", self.mapList["curPage"] + "/" + self.mapList["maxPage"]);
    self setClientCvar(level.mapListDvarPrefix + "page", self.mapList["curPage"]);
    self setClientCvar(level.mapListDvarPrefix + "pagemax", self.mapList["maxPage"]);

    // Dvars for the selected map
    self setClientCvar(level.mapListDvarPrefix + "selected", self.mapList["selected"]);
    if (self.mapList["selected"] != -1)
    {
        map = level.maps[self.mapList["selected"]];
        self setClientCvar(level.mapListDvarPrefix + "date", map["date"]);
        self setClientCvar(level.mapListDvarPrefix + "author", map["author"]);
        self setClientCvar(level.mapListDvarPrefix + "desc", map["desc"]);
        self setClientCvar(level.mapListDvarPrefix + "loadimage", "loadscreen_" + map["name"]);
    }
}
