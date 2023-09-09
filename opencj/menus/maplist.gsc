#include openCJ\util;

onInit()
{
    precacheMenu("opencj_maplist");

    level.mapListDvarPrefix = "opencj_ui_maplist_";
    level.mapListMaxEntriesPerPage = 20; // Hardcoded in menu
}

onPlayerConnected()
{
    // Default information
    self.mapList = [];
    self.mapList["selected"] = -1;

    self.mapList["curPage"] = 1;
    self.mapList["maxPage"] = max(1, ceil(level.maps.size / level.mapListMaxEntriesPerPage)); // Isn't a level variable because level.maps.size might not be ready in time for onInit()
    self.mapList["maxEntries"] = level.maps.size;

    self thread _updateMapList(false);

    // Handle menu responses and search text of the player
    self thread onMenuResponse();
    self thread onSearchText();
}

onOpen() // Map list menu is opened
{
    self thread _updateMapList(true);
}

onSearchText()
{
    self setClientCvar(level.mapListDvarPrefix + "textfield", "");
    for(;;)
    {
        self waittill("search_changed");
        self setClientCvar(level.mapListDvarPrefix + "textfield", self.searchText);
        self _updateMapList(true);
    }
}

onMenuResponse()
{
    self endon("disconnect");
    level endon("game_ended");

    for(;;)
    {
        self waittill("menuresponse", menu, response);

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
    if (isValidInt(newIdx))
    {
        newIdx = int(newIdx);
        if (newIdx < self.mapList["maxEntries"])
        {
            self.mapList["selected"] = int(newIdx);
            self _updateMapList(false);
        }
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
        args[1] = self.displayedMaps[self.mapList["selected"]]["name"];
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
        self _updateMapList(false);
    }
}

_calcMaxPage(nrEntriesThisPage, maxEntries)
{
    self.mapList["maxPage"] = max(1, ceil(maxEntries / level.mapListMaxEntriesPerPage));
}

_updateMapList(searchChanged)
{
    // Reset current page if anything related to search was done
    if (isDefined(searchChanged) && searchChanged)
    {
        self.mapList["selected"] = -1;
        self.mapList["curPage"] = 1;
    }

    // Determine the offset based on the user's current page
    offset = (self.mapList["curPage"] - 1) * level.mapListMaxEntriesPerPage;

    // Check if user is searching for a map
    totalEntries = undefined;
    if (isDefined(self.searchText) && (self.searchText.size > 0))
    {
        // There is a search text, only show maps that match the filter (and for current page)
        searchText = toLower(self.searchText);
        self.searchMatchedIndices = [];
        nrMatchedMaps = 0;
        skipped = 0;
        for (i = 0; i < level.maps.size; i++)
        {
            if (isSubStr(toLower(level.maps[i]["name"]), searchText))
            {
                // Only add results for current page
                if (skipped >= offset)
                {
                    if (self.searchMatchedIndices.size < level.mapListMaxEntriesPerPage)
                    {
                        self.searchMatchedIndices[self.searchMatchedIndices.size] = i;
                    }
                }
                else
                {
                    skipped++;
                }

                nrMatchedMaps++;
            }
        }

        // Total number of entries is now dependent on total matched search results
        totalEntries = nrMatchedMaps;
    }
    else
    {
        totalEntries = level.maps.size;
    }

    // Calculate number of entries on current page
    nrEntriesThisPage = min(totalEntries - offset, level.mapListMaxEntriesPerPage);

    // Calculate (new) max. number of pages because it can change based on search
    self _calcMaxPage(nrEntriesThisPage, totalEntries);

    // Update page text dvars
    self setClientCvar(level.mapListDvarPrefix + "pagetxt", self.mapList["curPage"] + "/" + self.mapList["maxPage"]);
    self setClientCvar(level.mapListDvarPrefix + "page", self.mapList["curPage"]);
    self setClientCvar(level.mapListDvarPrefix + "pagemax", self.mapList["maxPage"]);

    // And update all other maps
    self.displayedMaps = [];
    for (i = 0; i < level.mapListMaxEntriesPerPage; i++)
    {
        dvarName = level.mapListDvarPrefix + "map" + i;
        if (i < nrEntriesThisPage)
        {
            map = undefined;
            if (isDefined(self.searchMatchedIndices))
            {
                // Maps are dictated by search
                map = level.maps[self.searchMatchedIndices[i]];
                self setClientCvar(dvarName, map["name"]);
            }
            else
            {
                // No search filter for maps
                map = level.maps[i + offset];
                self setClientCvar(dvarName, map["name"]);
            }

            self.displayedMaps[self.displayedMaps.size] = map;
        }
        else
        {
            self setClientCvar(dvarName, ""); 
        }
    }
    self.searchMatchedIndices = undefined;

    // Update dvars for the selected map
    if (self.mapList["selected"] != -1)
    {
        selected = offset + self.mapList["selected"];
        selectedMap = self.displayedMaps[selected];
        self _updateSelectionDvars(selectedMap);
    }
    else
    {
        self _updateSelectionDvars(undefined);
    }
}

_updateSelectionDvars(map)
{
    if (isDefined(map))
    {
        self setClientCvar(level.mapListDvarPrefix + "selected", self.mapList["selected"]);
        self setClientCvar(level.mapListDvarPrefix + "selectedname", map["name"]);
        self setClientCvar(level.mapListDvarPrefix + "date", map["date"]);
        self setClientCvar(level.mapListDvarPrefix + "author", map["author"]);
        self setClientCvar(level.mapListDvarPrefix + "desc", map["desc"]);
        self setClientCvar(level.mapListDvarPrefix + "loadimage", "loadscreen_" + map["name"]);
    }
    else
    {
        self setClientCvar(level.mapListDvarPrefix + "selected", "");
        self setClientCvar(level.mapListDvarPrefix + "selectedname", "");
        self setClientCvar(level.mapListDvarPrefix + "date", "");
        self setClientCvar(level.mapListDvarPrefix + "author", "");
        self setClientCvar(level.mapListDvarPrefix + "desc", "");
        self setClientCvar(level.mapListDvarPrefix + "loadimage", "");
    }
}
