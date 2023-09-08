onInit()
{
    // All maps for alpha right now
    level.maps = [];

    level thread fetchAllMaps();
}

fetchAllMaps()
{
    query = "SELECT mapname, releaseDate FROM mapids WHERE inRotation = '1' ORDER BY mapname ASC";
    rows = opencj\mysql::mysqlAsyncQuery(query);
    if (isDefined(rows) && isDefined(rows[0]) && isDefined(rows[0][0]))
    {
        maxVal = rows.size;
        for(i = 0; i < rows.size; i++)
        {
            level.maps[i] = [];
            level.maps[i]["name"] = toLower(rows[i][0]);
            creationDateStr = "Unknown";
            if (isDefined(rows[i][1]))
            {
                creationDateStr = toLower(rows[i][1]);
            }
            level.maps[i]["date"] = creationDateStr;
            level.maps[i]["desc"] = ""; // TODO
            level.maps[i]["author"] = "Unknown"; // TODO
        }
    }
    else
    {
        printf("ERROR: could not get random maps for end map vote...\n");
    }

    // Call other scripts that depend on this variable
    thread openCJ\menus\endMapVote::fillRandomMaps();
}