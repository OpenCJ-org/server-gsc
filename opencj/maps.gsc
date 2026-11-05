// Alpha roster approved for #209. Bonus/secret routes are outside acceptance.
alphaMapNames()
{
    return strTok("mp_dark mp_cj_sky_bounce mp_all_in mp_bouncer_training mp_futile_fixed mp_blue2 mp_descent_v2 mp_to_the_moon mp_galaxy mp_mystic_v3", " ");
}

isAlphaMap(name)
{
    names = alphaMapNames();
    for (i = 0; i < names.size; i++)
        if (name == names[i]) return true;
    return false;
}

canVoteMap(name, adminLevel)
{
    name = toLower(name);
    if (!openCJ\commands_base::isUberAdminLevel(adminLevel) && !isAlphaMap(name))
        return false;
    return opencjMapExists(name);
}

onInit()
{
    level.maps = [];
    level.mapNames = [];
    level thread fetchAllMaps();
}

fetchAllMaps()
{
    // Rotation flags are not the alpha allowlist. Preserve metadata for every
    // installed map, including maps outside rotation that uber-admins can vote.
    rows = openCJ\mysql::mysqlAsyncQuery("SELECT mapname, releaseDate FROM mapids ORDER BY mapname ASC");
    loadMapRows(rows);
    thread openCJ\menus\endMapVote::fillRandomMaps();
}

loadMapRows(rows)
{
    level.maps = [];
    level.mapNames = [];
    if (isDefined(rows))
    {
        for (i = 0; i < rows.size; i++)
        {
            _addMap(toLower(rows[i][0]), rows[i][1]);
            if (i % 100 == 99) wait 0.05;
        }
    }
    // Installed custom maps need not already have a database/rotation entry.
    _addUsermaps(getCvar("fs_basepath") + "/usermaps");
    _addUsermaps(getCvar("fs_homepath") + "/usermaps");
    // Stock maps may also be installed without database metadata.
    _addStockMaps(getCvar("fs_basepath") + "/zone");
    _addStockMaps(getCvar("fs_homepath") + "/zone");
    // Preserve the approved roster even if metadata loading was unavailable.
    names = alphaMapNames();
    for (i = 0; i < names.size; i++) _addMap(names[i], undefined);
}

_addUsermaps(path)
{
    entries = opencjScanDir(path);
    if (!isDefined(entries)) return;
    for (i = 0; i < entries.size; i++)
    {
        _addMap(toLower(entries[i]), undefined);
        if (i % 100 == 99) wait 0.05;
    }
}

_addStockMaps(path)
{
    directories = opencjScanDir(path);
    if (!isDefined(directories)) return;
    for (i = 0; i < directories.size; i++)
    {
        // Scan language folders; the native existence check below decides
        // whether the engine can actually load a candidate in this setup.
        entries = opencjScanDir(path + "/" + directories[i]);
        if (!isDefined(entries)) continue;
        for (j = 0; j < entries.size; j++)
        {
            filename = toLower(entries[j]);
            if (filename.size <= 6 || getSubStr(filename, 0, 3) != "mp_" ||
                getSubStr(filename, filename.size - 3) != ".ff") continue;
            _addMap(getSubStr(filename, 0, filename.size - 3), undefined);
            if (j % 100 == 99) wait 0.05;
        }
    }
}

_addMap(name, date)
{
    if (isDefined(level.mapNames[name]) || !opencjMapExists(name)) return;
    entry = [];
    entry["name"] = name;
    entry["date"] = "Unknown";
    if (isDefined(date)) entry["date"] = date;
    entry["desc"] = "";
    entry["author"] = "Unknown";
    level.maps[level.maps.size] = entry;
    level.mapNames[name] = true;
}

voteMaps(adminLevel)
{
    maps = [];
    if (!isDefined(level.maps)) return maps;
    for (i = 0; i < level.maps.size; i++)
        if (canVoteMap(level.maps[i]["name"], adminLevel)) maps[maps.size] = level.maps[i];
    return maps;
}
