#include openCJ\util;

initBoard(shortName, fullName, menuName, fetchDataFunc, sortChangeFunc)
{
    // Example:
    // shortName = lb
    // fullName = "leaderboard"
    // menuName = "opencj_leaderboard"
    // fetchDataFunc = ::fetchUpdatedValues
    // sortChangeFunc = ::onBoardSortChange

    if (!isDefined(level.route))
    {
        level.route = [];
        level.route["maxEntriesPerPage"] = 7;
        // Fill in available routes upon init since it does not differ per player and is constant during the map
        // TODO fill in routes?
    }
    if (!isDefined(level.boards))
    {
        level.boards = [];
        level.boardsDvarPrefix = "opencj_ui_board_";
    }

    // Menu hardcoded values
    level.boards[shortName] = [];
    level.boards[shortName]["updateFunc"] = fetchDataFunc;
    level.boards[shortName]["sortChangeFunc"] = sortChangeFunc;
    level.boards[shortName]["menu"] = menuName;
    level.boards[shortName]["maxEntriesPerPage"] = 10;
    level.boards[shortName]["filterNames"] = [];
    level.boards[shortName]["filterNames"]["ele"] = shortName + "filterele";
    level.boards[shortName]["filterNames"]["any"] = shortName + "filteranypct";
    level.boards[shortName]["filterNames"]["hb"]  = shortName + "filterhalfbeat";
    level.boards[shortName]["filterNames"]["tas"] = shortName + "filtertas";
    level.boards[shortName]["filterNames"]["fps"] = shortName + "filterfps";

    precacheMenu(level.boards[shortName]["menu"]);
    
    // Hidden settings that are changed purely via menu
    openCJ\settings::addSettingBool(level.boards[shortName]["filterNames"]["ele"], false, "Set " + fullName + " ele filter", ::_onEleFilterSet);
    openCJ\settings::addSettingBool(level.boards[shortName]["filterNames"]["any"], false, "Set " + fullName + " shortcuts filter", ::_onAnyPctFilterSet);
    openCJ\settings::addSettingBool(level.boards[shortName]["filterNames"]["hb"], false, "Set " + fullName + " halfbeat filter", ::_onHalfBeatFilterSet);
    openCJ\settings::addSettingBool(level.boards[shortName]["filterNames"]["tas"], false, "Set " + fullName + " TAS filter", ::_onTASFilterSet);
    openCJ\settings::addSettingString(level.boards[shortName]["filterNames"]["fps"], 3, 8, "any", "Set " + fullName + " FPS filter", ::_onFPSFilterChange); // min len 3: 125, mix, hax
}

_onEleFilterSet(newVal)
{
    self.currentBoard["filter"]["ele"] = newVal;
}
_onAnyPctFilterSet(newVal)
{
    self.currentBoard["filter"]["any"] = newVal;
}
_onHalfBeatFilterSet(newVal)
{
    self.currentBoard["filter"]["hb"] = newVal;
}
_onTASFilterSet(newVal)
{
    self.currentBoard["filter"]["tas"] = newVal;
}
_onFPSFilterChange(newStr)
{
    allowed = false;
    newStr = tolower(newStr);
    switch (newStr)
    {
        case "125": // Fallthrough
        case "mix": // Fallthrough
        case "hax": // Fallthrough
        {
            allowed = true;
        } break;
    }

    if (allowed)
    {
        self.currentBoard["filter"]["fps"] = newStr;
    }

    return allowed; // Other values are not allowed
}

onBoardOpen(shortName)
{
    if (!isDefined(shortName))
    {
        return;
    }

    // Function to obtain the latest value for this specific board
    self.currentBoard["updateFunc"] = level.boards[shortName]["updateFunc"];
    // Some boards may specify a callback when sorting is changed
    self.currentBoard["sortChangeFunc"] = level.boards[shortName]["sortChangeFunc"];

    // Number of routes can differ between board. For example, runs board adds "Any route" to click on for runs filtering.
    fakeRoutes = [];
    if (shortName == "rn")
    {
        fakeRoutes[0] = "Unspecified";
    }

    self.currentBoard["routes"] = [];
    // Add fake routes
    for (i = 0; i < fakeRoutes.size; i++)
    {
        self.currentBoard["routes"][i] = fakeRoutes[i];
    }

    // Add real routes
    keys = getArrayKeys(level.routeEnders);
    for (i = fakeRoutes.size; i < (keys.size + fakeRoutes.size); i++)
    {
        self.currentBoard["routes"][i] = keys[i - fakeRoutes.size];
        printf("- added route: " + self.currentBoard["routes"][i] + "\n");
    }

    // Route information
    self.currentBoard["route"] = [];
    self.currentBoard["route"]["curPage"] = 1;
    self.currentBoard["route"]["maxPage"] = int(self.currentBoard["routes"].size / level.route["maxEntriesPerPage"]) + 1;

    // Number of entries
    self.currentBoard["maxEntriesPerPage"] = level.boards[shortName]["maxEntriesPerPage"];
    self.currentBoard["nrEntriesThisPage"] = 0; // How many entries are available for the current page
    self.currentBoard["nrTotalEntries"] = 0;

    // Sorting
    if (shortName == "lb")
    {
        // Leaderboard has persistent sorting: sortType:sortOrder
        lbSort = toLower(self openCJ\settings::getSetting("lbsort"));
        arr = strTok(lbSort, ":");
        self.currentBoard["sortBy"] = arr[0];
        if (arr[1] == "asc")
        {
            self.currentBoard["sort"] = 1; // Ascending
        }
        else
        {
            self.currentBoard["sort"] = 2; // Descending
        }
    }
    else
    {
        self.currentBoard["sortBy"] = "time";
        self.currentBoard["sort"] = 1; // Ascending
    }

    // Paging
    self.currentBoard["page"] = [];
    self.currentBoard["page"]["cur"] = 1;
    self.currentBoard["page"]["max"] = 1;

    // Filter names
    self.currentBoard["filterNames"] = [];
    self.currentBoard["filterNames"]["ele"] = level.boards[shortName]["filterNames"]["ele"];
    self.currentBoard["filterNames"]["any"] = level.boards[shortName]["filterNames"]["any"];
    self.currentBoard["filterNames"]["hb"]  = level.boards[shortName]["filterNames"]["hb"];
    self.currentBoard["filterNames"]["tas"] = level.boards[shortName]["filterNames"]["tas"];
    self.currentBoard["filterNames"]["fps"] = level.boards[shortName]["filterNames"]["fps"];

    // Filter settings
    self.currentBoard["filter"] = [];
    self.currentBoard["filter"]["ele"] = self openCJ\settings::getSetting(self.currentBoard["filterNames"]["ele"]);
    self.currentBoard["filter"]["any"] = self openCJ\settings::getSetting(self.currentBoard["filterNames"]["any"]);
    self.currentBoard["filter"]["hb"]  = self openCJ\settings::getSetting(self.currentBoard["filterNames"]["hb"]);
    self.currentBoard["filter"]["tas"] = self openCJ\settings::getSetting(self.currentBoard["filterNames"]["tas"]);
    self.currentBoard["filter"]["fps"] = self openCJ\settings::getSetting(self.currentBoard["filterNames"]["fps"]);
    self.currentBoard["filter"]["route"] = 1; // Select first route by default

    // These are dvars for each entry
    self.currentBoard["cols"] = [];
    for (i = 0; i < self.currentBoard["maxEntriesPerPage"]; i++)
    {
        self.currentBoard["cols"][i] = [];
    }

    // Set filter dvars
    keys = getArrayKeys(self.currentBoard["filter"]);
    for (i = 0; i < keys.size; i++)
    {
        if (keys[i] == "route")
        {
            continue; // Not a real filter
        }
        self setClientCvar(level.boardsDvarPrefix + keys[i] + "_allow", self.currentBoard["filter"][keys[i]]);
    }

    // Set currently selected FPS filter
    self setClientCvar(level.boardsDvarPrefix + "fpsselected", "^5" + dbFPSToFullName(self.currentBoard["filter"]["fps"]) + "^7");

    // Fill in the routes
    self updateRoutes();
    self setClientCvar(level.boardsDvarPrefix + "rtpagemax", self.currentBoard["route"]["maxPage"]);

    // Fill in the values for default selections and current filters
    self thread updateBoard();
}

onPlayerConnected()
{
    // Default information
    self.currentBoard = [];

    // Handle menu responses of the player
    self thread onMenuResponse();
}

onMenuResponse()
{
    self endon("disconnect");
    level endon("game_ended");

    for(;;)
    {
        self waittill("menuresponse", menu, response);

        // Only handle the response if a board-type menu is currently open
        if ((self.currentMenu != "opencj_leaderboard") && (self.currentMenu != "opencj_runsboard"))
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
            if ((button == "time") || (button == "rpgs") || (button == "loads") || (button == "date")) // Sorting
            {
                self handleSortChange(button);
            }
            else if (isSubStr(button, "loadrun")) // Runs board has clickable 'name' to restore the run
            {
                self openCJ\menus\runsboard::handleRestoreRun(button);
            }
            else if (isSubStr(button, "page")) // Route or board previous/next page
            {
                self handlePageChange(button);
            }
            else if ((button == "ele") || (button == "any") || (button == "hb") || (button == "tas")) // Filter pressed
            {
                self handleFilterChange(button);
            }
            else if (isSubStr(button, "fps_")) // FPS filter selection pop menu button was clicked
            {
                self handleFilterChange(button);
            }
            else if (isSubStr(button, "route"))
            {
                self handleRouteSelection(button);
            }
        }
    }
}

/// ===================================================== Update functions =====================================================

updateBoard()
{
    // Gets values and puts them in self vars
    self [[self.currentBoard["updateFunc"]]]();

    // Update all dvars
    self.currentBoard["page"]["max"] = max(1, ceil(self.currentBoard["nrTotalEntries"] / self.currentBoard["maxEntriesPerPage"]));

    // Update page text dvars after updating board
    self setClientCvar(level.boardsDvarPrefix + "pagetxt", self.currentBoard["page"]["cur"] + "/" + self.currentBoard["page"]["max"]);
    self setClientCvar(level.boardsDvarPrefix + "page", self.currentBoard["page"]["cur"]);
    self setClientCvar(level.boardsDvarPrefix + "pagemax", self.currentBoard["page"]["max"]);

    // Update sorting dvars
    // First, clear all previous sorting dvars
    self setClientCvar(level.boardsDvarPrefix + "sort_time", 0);
    self setClientCvar(level.boardsDvarPrefix + "sort_rpgs", 0);
    self setClientCvar(level.boardsDvarPrefix + "sort_loads", 0);
    self setClientCvar(level.boardsDvarPrefix + "sort_date", 0);

    self setClientCvar(level.boardsDvarPrefix + "sort_" + self.currentBoard["sortBy"], self.currentBoard["sort"]);

    // And now the actual board data
    keys = getArrayKeys(self.currentBoard["cols"][0]); // Although empty when i >= self.currentBoard["nrEntriesThisPage"], can still be used for getArrayKeys
    dvars = [];
    dvars["count"] = self.currentBoard["nrEntriesThisPage"];
    for (j = 0; j < keys.size; j++)
    {
        key = keys[j];
        dvars[key] = "";
        for (i = 0; i < self.currentBoard["nrEntriesThisPage"]; i++)
        {
            val = self.currentBoard["cols"][i][key];

            // Special conversion(s) without updating the original
            if (key == "time")
            {
                val = timeToString(int((val / 1000) + 0.5)); // Round the time and convert it to a nicely readable string
            }
            /*
            else if (key == "date")
            {
                val = convertDate(val);
            }
            */

            dvars[key] += val + "\n";
        }
    }

    // Update client dvars with above determined values
    keys = getArrayKeys(dvars);
    for (i = 0; i < keys.size; i++)
    {
        self setClientCvar(level.boardsDvarPrefix + keys[i], dvars[keys[i]]);
    }
}

updateRoutes()
{
    // Start by updating the client's selected route visibility based on current page
    absRouteNr = self.currentBoard["filter"]["route"]; // Not normalized
    self updateSelectedRoute(absRouteNr);

    // Then update all the route dvars based on current page
    firstItemNrCurrentPage = getAbsFirstItemNrCurrentPage(self.currentBoard["route"]["curPage"], level.route["maxEntriesPerPage"]);
    remainingEntries = self.currentBoard["routes"].size - firstItemNrCurrentPage + 1; // +1 because we also need to update the first item
    for (i = 0; i < level.route["maxEntriesPerPage"]; i++) // We also need to clear the ones that shouldn't be visible (anymore)
    {
        itemNr = (i+1); // Route dvars, like others, start at 1

        dvar = level.boardsDvarPrefix + "route" + itemNr;
        if (itemNr <= remainingEntries)
        {
            self setClientCvar(dvar, self.currentBoard["routes"][(firstItemNrCurrentPage-1) + i]); // Starts at [0] not at [1], so -1
        }
        else
        {
            self setClientCvar(dvar, ""); // Not ^7 because we don't want to show the cell as empty, we want to actually hide it
        }
    }

    self setClientCvar(level.boardsDvarPrefix + "rtpage", self.currentBoard["route"]["curPage"]);
    self setClientCvar(level.boardsDvarPrefix + "rtpagetxt", self.currentBoard["route"]["curPage"] + "/" + self.currentBoard["route"]["maxPage"]);
}

updateSelectedRoute(absRouteNr)
{
    selectedRouteDvar = level.boardsDvarPrefix + "rtselected";
    if (isAbsItemNrOnCurrentPage(absRouteNr, self.currentBoard["route"]["curPage"], level.route["maxEntriesPerPage"], self.currentBoard["routes"].size))
    {
        // Currently selected route is visible on current page
        self setClientCvar(selectedRouteDvar, toRelItemNr(absRouteNr, self.currentBoard["route"]["curPage"], level.route["maxEntriesPerPage"]));
    }
    else
    {
        // Not visible on current page
        self setClientCvar(selectedRouteDvar, "");
    }
}

// ===================================================== Database helper functions =====================================================

getFPSModeStr(fpsFilter)
{
    allowedFpsEntries = "(";
    switch (fpsFilter)
    {
        default:
        {
            printf("WARNING: FPS filter: " + fpsFilter + " invalid\n");
        } // Fallthrough to allow all types of FPS
        case "hax":
        {
            allowedFpsEntries += dbStr("hax") + ", "; // 'All' in menu is called 'hax' in db
        } // Fallthrough
        case "mix":
        {
            allowedFpsEntries += dbStr("mix") + ", "; // Standard mode on CoD4 is called mix in db
        } // Fallthrough
        case "125":
        {
            allowedFpsEntries += dbStr("125"); // 125 is called 125
        } break;
    }
    allowedFpsEntries += ")";

    return allowedFpsEntries;
}

isValidSortCol(col)
{
    col = toLower(col);
    switch(col)
    {
        case "time":
        case "rpgs":
        case "loads":
        case "saves":
        case "startdate":
        case "finishdate":
        {
            return true;
        }
        default:
        {
            return false;
        }
    }
}

convertSortCol(col, orderStr) // Also used by leaderboard.gsc to do top right records sorting
{
    col = toLower(col);
    orderStr = toLower(orderStr);
    if (orderStr == "desc")
    {
        // Valid value
    }
    else
    {
        orderStr  = "asc"; // Default to asc
    }

    str = "";
    if (!isValidSortCol(col))
    {
        str = "timePlayed"; // Default to timePlayed
    }
    else
    {
        switch(col)
        {
            case "time":
            {
                str += "timePlayed";
            } break;
            case "rpgs":
            {
                str += "explosiveJumps";
            } break;
            case "loads":
            {
                str += "loadCount";
            } break;
            case "saves":
            {
                str += "saveCount";
            } break;
            case "startdate":
            {
                str += "startTimeStamp";
            } break;
            case "finishdate":
            {
                str += "finishTimeStamp";
            } break;
            default:
            {

            } break;
        }
    }

    return str + " " + toUpper(orderStr);
}

getOffsetFromPage(page, maxEntriesPerPage)
{
    return getAbsFirstItemNrCurrentPage(page, maxEntriesPerPage) - 1;
}

// ===================================================== Functions called upon scriptMenuResponse =====================================================

handleSortChange(button)
{
    if (self.currentBoard["sortBy"] != button) // Will be sorting by something else now
    {
        self.currentBoard["sortBy"] = button;
        self.currentBoard["sort"] = 1; // Ascending by default
    }
    else // Sorting by same thing, so toggle between ascending and descending
    {
        if (self.currentBoard["sort"] == 1)
        {
            self.currentBoard["sort"] = 2;
        }
        else
        {
            self.currentBoard["sort"] = 1;
        }
    }

    if (isDefined(self.currentBoard["sortChangeFunc"]))
    {
        self [[self.currentBoard["sortChangeFunc"]]](self.currentBoard["sortBy"], self.currentBoard["sort"]);
    }

    // Sorting changed, so reset page
    self.currentBoard["page"]["cur"] = 1; // Reset page

    self thread updateBoard();
}

handlePageChange(button)
{
    isPrevPage = isSubStr(button, "prev");
    isRoutePage = isSubStr(button, "rt");

    if (isRoutePage)
    {
        if (isPrevPage)
        {
            if (self.currentBoard["route"]["curPage"] > 1)
            {
                self.currentBoard["route"]["curPage"]--;
            }
        }
        else // Next page
        {
            if (self.currentBoard["route"]["curPage"] < self.currentBoard["route"]["maxPage"])
            {
                self.currentBoard["route"]["curPage"]++;
            }
        }

        self updateRoutes();
    }
    else // Board page
    {
        if (isPrevPage)
        {
            if (self.currentBoard["page"]["cur"] > 1)
            {
                self.currentBoard["page"]["cur"]--;
            }
        }
        else // Next page
        {
            if (self.currentBoard["page"]["cur"] < self.currentBoard["page"]["max"])
            {
                self.currentBoard["page"]["cur"]++;
            }
        }

        self thread updateBoard();
    }
}

dbFPSToFullName(dbFPSName)
{
    switch(dbFPSName)
    {
        case "125": return "Classic";
        case "mix": return "Standard";
        case "hax": // Fallthrough
        default:    return "Any";
    }
}

handleFilterChange(button)
{
    if ((button == "ele") || (button == "any") || (button == "hb") || (button == "tas"))
    {
        // Filter: toggle allow ele
        // Filter: toggle allow any % (cuts)
        // Filter: toggle allow TAS (Tool Assisted Speedrun)
        self.currentBoard["filter"][button] = !self.currentBoard["filter"][button];
        self openCJ\settings::setSettingByScript(self.currentBoard["filterNames"][button], self.currentBoard["filter"][button]);
        self setClientCvar(level.boardsDvarPrefix + button + "_allow", self.currentBoard["filter"][button]);
    }
    else if (isSubStr(button, "fps_"))
    {
        fpsTokens = strTok(button, "_");
        if (fpsTokens.size > 1)
        {
            fpsFilter = toLower(fpsTokens[1]);

            // We map it to db names
            switch(fpsFilter)
            {
                case "125":
                {
                    self.currentBoard["filter"]["fps"] = "125";
                } break;
                case "standard": // Fallthrough
                case "mix":
                {
                    self.currentBoard["filter"]["fps"] = "mix";
                } break;
                case "any": // Fallthrough
                case "all": // Fallthrough
                case "hax":
                {
                    self.currentBoard["filter"]["fps"] = "hax";
                } break;
                default:
                {
                    printf("WARNING: Unknown FPS filter: " + fpsFilter + "\n");
                }
            }

            self openCJ\settings::setSettingByScript(self.currentBoard["filterNames"]["fps"], self.currentBoard["filter"]["fps"]);
            self setClientCvar(level.boardsDvarPrefix + "fpsselected", "^5" + dbFPSToFullName(self.currentBoard["filter"]["fps"]) + "^7");
        }
    }

    // Filtering changed, so reset page
    self.currentBoard["page"]["cur"] = 1;

    self thread updateBoard();
}

handleRouteSelection(button)
{
    if (button.size < 6)
    {
        return;
    }

    routeNr = int(getSubStr(button, 5)); // "route"
    if ((routeNr < 1) || (routeNr > level.route["maxEntriesPerPage"]))
    {
        return;
    }

    // Add proper offset to selected route, otherwise route will be highlighted on all pages (2 vs (maxEntries + 2))
    self.currentBoard["filter"]["route"] = toAbsItemNrOnCurrentPage(routeNr, self.currentBoard["route"]["curPage"], level.route["maxEntriesPerPage"], self.currentBoard["routes"].size);

    self updateSelectedRoute(self.currentBoard["filter"]["route"]);

    // Selected route changed, so we need to filter only the runs that are part of that route
    self thread updateBoard();
}

// ===================================================== Helper functions =====================================================

toAbsItemNrOnCurrentPage(itemNr, curPage, maxEntriesPerPage, maxEntries)
{
    itemNr += getAbsFirstItemNrCurrentPage(curPage, maxEntriesPerPage) - 1; // -1 because itemNr already starts at one
    if (itemNr > maxEntries)
    {
        itemNr = maxEntries;
    }

    return itemNr;
}

toRelItemNr(absItemNr, curPage, maxEntriesPerPage)
{
    relItemNr = (absItemNr % maxEntriesPerPage);
    if (relItemNr == 0)
    {
        relItemNr = maxEntriesPerPage;
    }
    return relItemNr;
}

isAbsItemNrOnCurrentPage(itemNr, curPage, maxEntriesPerPage, maxEntries)
{
    if (itemNr < 1)
    {
        return false;
    }

    pageFirstItemNr = getAbsFirstItemNrCurrentPage(curPage, maxEntriesPerPage);
    pageLastItemNr = getAbsLastItemNrCurrentPage(curPage, maxEntriesPerPage, maxEntries);

    if ((itemNr < pageFirstItemNr) || (itemNr > pageLastItemNr))
    {
        return false;
    }

    return true;
}

getAbsFirstItemNrCurrentPage(curPage, maxEntriesPerPage)
{
    pageIdx = (curPage - 1); // Page starts at 1
    firstItemNr = (pageIdx * maxEntriesPerPage) + 1; // + 1 because first item starts at 1

    return firstItemNr;
}

getAbsLastItemNrCurrentPage(curPage, maxEntriesPerPage, maxEntries)
{
    lastItemNrCurrentPage = getAbsFirstItemNrCurrentPage(curPage, maxEntriesPerPage) + maxEntriesPerPage;
    if (lastItemNrCurrentPage > maxEntries)
    {
        lastItemNrCurrentPage = maxEntries;
    }

    return lastItemNrCurrentPage;
}

timeToString(seconds)
{
    hours = int(seconds / 3600);
    seconds -= (hours * 3600);
    if (hours < 10) hours = "0" + hours;
    minutes = int(seconds / 60);
    seconds -= (minutes * 60);
    if (minutes < 10) minutes = "0" + minutes;
    if (seconds < 10) seconds = "0" + seconds;

    return hours + ":" + minutes + ":" + seconds;
}

/* Was used for test data. Might be useful in future if we get the date in days

convertDate(days)
{
    str = "";
    val = 0;
    if (days >= 365)
    {
        val = int(days / 365);
        str += val + " year";
    }
    else if (days >= 31)
    {
        val = int(days / 31);
        str += val + " month";
    }
    else if (days >= 7)
    {
        val = int(days / 7);
        str += val + " week";
    }
    else
    {
        val = int(days);
        str += days + " day";
    }
    
    if (val > 1)
    {
        str += "s";
    }
    
    str += " ago";
    return str;
}
*/
