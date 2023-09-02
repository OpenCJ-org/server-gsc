// This file contains functions usable from any map GSC

// Protect a moving platform against being blocked
// name: base name of the entity to protect, for example "stairs"
// idxBegin: if intending to protect multiple entities with same base name but with a number: the first number
// idxEnd:   if intending to protect multiple entities with same base name but with a number: the last number
//
// Example: openCJ\mapApi::protectMovingPlatform("yellow", 1, 2); // This will protect 'yellow', 'yellow1', 'yellow2'
//
protectMovingPlatform(name, idxBegin, idxEnd)
{
    // Always try to add the "base" named entity
    openCJ\cheating::addProtectedMovingPlatform(name);

    // Add all the numbered entities
    if (isDefined(idxBegin) && isDefined(idxEnd))
    {
        for (i = idxBegin; i < idxEnd; i++)
        {
            openCJ\cheating::addProtectedMovingPlatform(name + i);
        }
    }
}

// Emulate knockback instead of using exploitable global g_knockback dvar
// dmg: finishPlayerDamage: <Damage>
// dir: finishPlayerDamage: <Direction>
// g_knockback_val: the value that scripts usually set g_knockback dvar to
//
// Example: self openCJ\mapApi::emulateKnockback((speed*9)-3000, (trigger.origin - target.origin), (speed*9)-3000);
//
emulateKnockback(dmg, dir, g_knockback_val)
{
    //not taking stance into account
    //adjust dmg if player is always crouching
    dmg *= 0.3;
    if (dmg > 60)
    {
        dmg = 60;
    }
    knockback = dmg * g_knockback_val / 250.0;
    self addVelocity(vectorScale(vectorNormalize(dir), knockback));
    if (self getPMTime() == 0)
    {
        maxDmg = 2 * dmg;
        if (maxDmg < 50)
        {
            maxDmg = 50;
        }
        if (maxDmg > 200)
        {
            maxDmg = 200;
        }

        flagTimeKnockback = 256; // https://github.com/xoxor4d/iw3xo-dev/blob/develop/src/components/modules/movement.cpp
        flags = self getPMFlags() | flagTimeKnockback;
        flags |= flagTimeKnockback;

        self setPMFlags(flags, maxDmg);
    }
}

// Delete an entity by a property, such as classname or targetname
// name: Name of the entity (array)
// property: for example "classname" or "targetname"
// isArray: can be undefined. if true: delete all entries in the entity array, otherwise delete entity
//
// Example: openCJ\mapApi::deleteByProperty("test7", "targetname");
//
deleteByProperty(name, property, isArray)
{
    if (!isDefined(isArray) || !isArray)
    {
        ent = getEnt(name, property);
        if (isDefined(ent))
        {
            ent delete();
        }
    }
    else
    {
        entArray = getEntArray(name, property);
        if (isDefined(entArray))
        {
            if (entArray.size <= 0)
            {
                return;
            }
            for (i = entArray.size - 1; i >= 0; i--)
            {
                entArray[i] delete();
            }
        }
    }
}
