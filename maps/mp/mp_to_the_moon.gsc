// OpenCJ: preserve route and secret mechanics; fix legacy mod dependency and trigger safety.
main()
{

    maps\mp\_load::main();

    game["allies"] = "marines";
    game["axis"] = "opfor";
    game["attackers"] = "axis";
    game["defenders"] = "allies";
    game["allies_soldiertype"] = "desert";
    game["axis_soldiertype"] = "desert";

    setdvar( "r_specularcolorscale", "9" );

    setdvar("r_glowbloomintensity0",".25");
    setdvar("r_glowbloomintensity1",".25");
    setdvar("r_glowskybleedintensity0",".3");
    setdvar("compassmaxrange","1800");

    level.msg_block = false;
    thread endofmap();
    thread endofmap1();
    thread run_msg_2();
    thread run_msg_3();
    thread run_msg_4();

    thread reset();
    thread speed();
    thread speed2();
    thread speed3();
    thread endofmap2();

}

endofmap()
{
    trigger = getent("end","targetname");
    if (!isDefined(trigger))
    return;

    while (1)
    {
        trigger waittill ("trigger", user );
        if (!isDefined(user) || !isPlayer(user) || !isAlive(user))
        continue;
        if ( isPlayer( user ) && isAlive( user ) && isdefined( user.moonDoneAdvanced ) )
        {
            wait 0.5;
        }
        else
        {
            iprintlnbold ("Congratulations, " + user.name + ", you have completed mp_to_the_moon ^5Advanced!!");
            user iprintlnbold ("Map created by ^1=.VaRtaZiaN.=");
            user.moonDoneAdvanced = true;
        }
    }
}
run_msg_2()
{
    var_msg_2 = getent("message2","targetname");
    if ( isdefined(var_msg_2) )
    {
        while(true)
        {
            var_msg_2 waittill ("trigger", user);
            if(isDefined(user) && isPlayer(user) && isAlive(user) && !level.msg_block)
            {
                level.msg_block = true;
                iprintlnbold ("^4 Map by: ^1=.VaRtaZiaN.=");
                wait 2;
                level.msg_block = false;
            }
        }
    }
}
run_msg_3()
{
    var_msg_3 = getent("message3","targetname");
    if ( isdefined(var_msg_3) )
    {
        while(true)
        {
            var_msg_3 waittill ("trigger", user);
            if(isDefined(user) && isPlayer(user) && isAlive(user) && !level.msg_block)
            {
                level.msg_block = true;
                iprintlnbold ("" + user.name + " ^7is ^3better than you");
                wait 2;
                level.msg_block = false;
            }
        }
    }
}
run_msg_4()
{
    var_msg_4 = getent("message4","targetname");
    if ( isdefined(var_msg_4) )
    {
        while(true)
        {
            var_msg_4 waittill ("trigger", user);
            if(isDefined(user) && isPlayer(user) && isAlive(user) && !level.msg_block)
            {
                level.msg_block = true;
                iprintlnbold ("^1Another secret bounce?  ^3U Jelly Brah!!");
                wait 2;
                level.msg_block = false;
            }
        }
    }
}

endofmap1()
{
    trigger = getent("end1","targetname");
    if (!isDefined(trigger))
    return;

    while (1)
    {
        trigger waittill ("trigger", user );
        if (!isDefined(user) || !isPlayer(user) || !isAlive(user))
        continue;
        if ( isPlayer( user ) && isAlive( user ) && isdefined( user.moonDoneBasic ) )
        {
            wait 0.5;
        }
        else
        {
            user iprintlnbold ("Congratulations, " + user.name + ", you have completed Basic way of mp_to_the_moon!! Now go try Intermediate ;)");
            user iprintlnbold ("Map created by ^1=.VaRtaZiaN.=");
            user.moonDoneBasic = true;
        }
    }
}
reset()
{
    ent_ResetLoad = getentarray("reset","targetname");
    if(isdefined(ent_ResetLoad))
    {
        for(lp=0;lp<ent_ResetLoad.size;lp++)
        ent_ResetLoad[lp] thread _ResetLoad();
    }
}

_ResetLoad()
{
    self endon("disconnect");
    self endon("killed_player");
    self endon("joined_spectators");

    while(true)
    {
        self waittill("trigger",other);

        wait(0.10);
        if (isDefined(other) && isPlayer(other) && isAlive(other))
        other openCJ\events\eventHandler::onLoadPositionRequest(0);
        wait(0.10);
    }
}

speed()
{
    trigger = getent("svt_accelerate_1", "targetname");
    if (!isDefined(trigger))
    return;
    for (;;)
    {
        trigger waittill("trigger", player);
        if (isDefined(player) && isPlayer(player) && isAlive(player))
        player thread moonBoost();
    }
}

speed2()
{
    trigger = getent("svt_accelerate_2", "targetname");
    if (!isDefined(trigger))
    return;
    for (;;)
    {
        trigger waittill("trigger", player);
        if (isDefined(player) && isPlayer(player) && isAlive(player))
        player thread moonBoost();
    }
}

speed3()
{
    trigger = getent("svt_accelerate_3", "targetname");
    if (!isDefined(trigger))
    return;
    for (;;)
    {
        trigger waittill("trigger", player);
        if (isDefined(player) && isPlayer(player) && isAlive(player))
        player thread moonBoost();
    }
}
endofmap2()
{
    trigger = getent("end2","targetname");
    if (!isDefined(trigger))
    return;

    while (1)
    {
        trigger waittill ("trigger", user );
        if (!isDefined(user) || !isPlayer(user) || !isAlive(user))
        continue;
        if ( isPlayer( user ) && isAlive( user ) && isdefined( user.moonDoneIntermediate ) )
        {
            wait 0.5;
        }
        else
        {
            user iprintlnbold ("Congratulations, " + user.name + ", you have completed Intermediate way of mp_to_the_moon!! Now go try Hard way ;)");
            user iprintlnbold ("Map created by ^1=.VaRtaZiaN.=");
            user.moonDoneIntermediate = true;
        }
    }
}

// Retain the original 12x launch-pad speed and two-second cooldown,
// without letting one player block the pad for everyone else.
moonBoost()
{
    self endon("disconnect");
    if (isDefined(self.moonBoostActive))
    return;
    self.moonBoostActive = true;
    while (isAlive(self) && self.sessionstate == "playing" && self isOnGround())
    {
        self SetMoveSpeedScale(12);
        wait 0.05;
    }
    self SetMoveSpeedScale(1);
    wait 2;
    self.moonBoostActive = undefined;
}
