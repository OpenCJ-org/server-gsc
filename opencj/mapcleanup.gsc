#include openCJ\util;

onInit()
{
    if(getCodVersion() == 4)
    {
        _removePickups();
        _removeTurrets();
        _removeWeapons();
        setCvar("clientSideEffects", 0);
        thread _stopMapAmbient();
    }
    else
    {
        _removeTurrets();
        //_showClassnames();
    }
}

_removeWeapons()
{
    ents = getEntArray(); // Gets all entities
    if (ents.size <= 0)
    {
        return;
    }
    for (i = ents.size - 1; i >= 0; i--)
    {
        if (getSubStr(ents[i].classname, 0, 7) == "weapon_")
        {
            ents[i] delete();
        }
    }
}

_removePickups()
{
    pickups = getentarray("oldschool_pickup", "targetname");

    for(i = 0; i < pickups.size; i++)
    {
        if(isdefined(pickups[i].target))
        {
            getent(pickups[i].target, "targetname") delete();
        }

        pickups[i] delete();
    }
}

_removeTurrets()
{
    turrets = getentarray("misc_turret", "classname");
    mg42s = getentarray("misc_mg42", "classname");
    for(i = 0; i < turrets.size; i++)
    {
        turrets[i] delete();
    }
    for(i = 0; i < mg42s.size; i++)
    {
        mg42s[i] delete();
    }
}

_showClassnames()
{
    ents = getEntArray();
    for(i = 0; i < ents.size; i++)
    {
        if(isDefined(ents[i].className))
        {
            printf(ents[i].className + "\n");
        }
    }
}
// Map main() may start its ambient track after the gametype callback. Stop it
// after initialization, without muting player weapons, footsteps or UI sounds.
_stopMapAmbient()
{
    wait 0.05;
    ambientStop();
    _normalizeMapHints();
}

// BSP trigger hints may contain raw prose instead of a localization key.
// Configstrings 277..308 are CoD4's 32 hint slots (G_GetHintStringIndex).
_normalizeMapHints()
{
    repaired=0;
    for(i=277;i<309;i++)
    {
        hint=sv_getconfigstring(i);
        fixed=_literalMapHint(hint);
        if(fixed!=hint)
        {
            setConfigStringByIndex(i,fixed);
            repaired++;
        }
    }
    if(repaired)printf("OpenCJ: normalized "+repaired+" literal map hint(s).\n");
}

_literalMapHint(hint)
{
    if(hint=="" || (!isSubStr(hint," ") && getSubStr(hint,0,1)!="^"))return hint;
    literal=getSubStr(constructMessage("x"),0,1);
    localized=getSubStr(constructMessage("x", &"PLATFORM_USE"),2,3);
    // Preserve proper literal/localized mixtures and avoid adding markers twice.
    if(isSubStr(hint,literal) || isSubStr(hint,localized))return hint;
    return constructMessage(hint);
}
