#include openCJ\util;

onInit()
{
    if(getCodVersion() == 4)
    {
        _removePickups();
        _removeTurrets();
        _removeWeapons();
        setCvar("clientSideEffects", 0);
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