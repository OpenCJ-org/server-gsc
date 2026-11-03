// Whole entity checkpoints. Store a stable map reference, never an entity slot.
// Brush model numbers belong to the map; script models require a unique targetname.
reference(ent)
{
    if (!isDefined(ent) || getCodVersion() != 4) return undefined;
    if (ent.classname != "script_brushmodel" && ent.classname != "script_model") return undefined;
    info = platformEntityInfo(ent getEntityNumber());
    if (!isDefined(info)) return undefined;
    if (info[0] > 0) key = "b" + info[0];
    else
    {
        if (!isDefined(ent.targetname) || ent.targetname.size == 0 || ent.targetname.size > 100) return undefined;
        // Draft delimiters must never become part of an entity reference.
        for (i = 0; i < ent.targetname.size; i++)
            if (!isSubStr("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-", ent.targetname[i])) return undefined;
        matches = getEntArray(ent.targetname, "targetname");
        if (matches.size != 1) return undefined;
        key = "n" + ent.targetname;
    }
    resolved = resolve(key);
    if (!isDefined(resolved) || resolved != ent) return undefined;
    return key;
}

resolve(key)
{
    if (!isDefined(key) || key == "" || getCodVersion() != 4) return undefined;
    if (!isDefined(level.checkpointMovingCache)) level.checkpointMovingCache = [];
    cached = level.checkpointMovingCache[key];
    if (isDefined(cached))
    {
        if (isDefined(cached.ent)) return cached.ent;
        if (getTime() - cached.checked < 1000) return undefined;
    }
    cached = spawnStruct(); cached.checked = getTime();
    level.checkpointMovingCache[key] = cached;
    if (key[0] == "n")
    {
        ents = getEntArray(getSubStr(key, 1), "targetname");
        if (ents.size == 1 && ents[0].classname == "script_model") cached.ent = ents[0];
    }
    else if (key[0] == "b" && isValidInt(getSubStr(key, 1)))
    {
        index = int(getSubStr(key, 1));
        if (index <= 0) return undefined;
        ents = getEntArray("script_brushmodel", "classname");
        for (i = 0; i < ents.size; i++)
        {
            info = platformEntityInfo(ents[i] getEntityNumber());
            if (!isDefined(info) || info[0] != index) continue;
            // A cloned brush is ambiguous: do not bind to an arbitrary instance.
            if (isDefined(cached.ent)) { cached.ent = undefined; return undefined; }
            cached.ent = ents[i];
        }
    }
    return cached.ent;
}

isMoving(cp)
{
    return isDefined(cp.platformRef) && cp.platformRef != "";
}

// The outline denotes the whole object's bounds; it is not used for collision.
points(cp)
{
    if (!isMoving(cp)) return cp.points;
    ent = resolve(cp.platformRef);
    if (!isDefined(ent)) return [];
    info = platformEntityInfo(ent getEntityNumber());
    if (!isDefined(info)) return [];
    lo = info[1]; hi = info[2];
    local = []; local[0] = (lo[0],lo[1],hi[2]); local[1] = (hi[0],lo[1],hi[2]);
    local[2] = (hi[0],hi[1],hi[2]); local[3] = (lo[0],hi[1],hi[2]);
    world = [];
    forward = anglesToForward(ent.angles); right = anglesToRight(ent.angles); up = anglesToUp(ent.angles);
    for (i = 0; i < 4; i++)
        world[i] = ent.origin + vectorScale(forward,local[i][0]) - vectorScale(right,local[i][1]) + vectorScale(up,local[i][2]);
    return world;
}

center(cp)
{
    p = points(cp);
    if (!p.size) return undefined;
    return vectorScale(p[0]+p[1]+p[2]+p[3],0.25);
}

// Called on a player. No geometry traces or polygon transforms during contact.
touches(cp, grounded, groundEntity)
{
    ent = resolve(cp.platformRef);
    if (!isDefined(ent)) return false;
    if (cp.onGround) return grounded && isDefined(groundEntity) && groundEntity == ent;
    return self isTouching(ent);
}

valid(cp)
{
    if (!isMoving(cp)) return openCJ\checkpointArea::validate(cp.points);
    if (cp.alternatives.size) return "A whole moving platform cannot have alternative areas yet";
    if (!isDefined(resolve(cp.platformRef))) return "Moving platform cannot be found uniquely in this map";
    return "";
}
