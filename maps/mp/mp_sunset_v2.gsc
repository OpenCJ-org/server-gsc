main()
{
	maps\mp\_load::main();
	
	game["allies"] = "marines";
	game["axis"] = "opfor";
	game["attackers"] = "axis";
	game["defenders"] = "allies";
	game["allies_soldiertype"] = "desert";
	game["axis_soldiertype"] = "desert";

	thread connectListener();
	
	thread remake_end();
    thread hard_end();
    thread hardplus_end();
    thread int_end();
    thread intplus_end();
    thread ez_end();
    thread adv_end();
    thread adv_roof();
    thread beamed_end();
    thread beamed_roof();
    thread beamedplus_end();
    thread bonuseasy_end();
    thread bonuseasy_roof();
    thread bonuseasy_rooftop();
    thread bonusinter_end();
    thread bonusinter_roof();
    thread bonushard_end();
    thread bonushard_roof();
	
	teles = GetEntArray("teleport", "targetname");
    for(i = 0; i < teles.size; i++)
        teles[i] thread teleporter();
}

connectListener()
{
    level endon("game_ended");
    while (1) {
        level waittill("connected", player);
        player thread onPlayerSpawned();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
    while (1)
    {
        self waittill("spawned_player");
        self iprintln("Welcome to ^3mp_sunset_v2, created by ^2Toxic!"); 
        self iprintln("^7Special thanks to: ^1Sycotic, Sep, toXijeE, Skazy, Treaxer, Straub, Funk^7"); 
    }
}

remake_end()
{
    trigger = getEnt ("remake_end","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunFinishedRemake))
        {
            iprintln("^5"+player.name+"^7 finished ^3Remake^7!");
            player.sunFinishedRemake = true;
        }
    }
}

hard_end()
{
    trigger = getEnt ("hard_end","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunFinishedHard))
        {
            iprintln("^5"+player.name+"^7 finished ^1Hard^7!");
            player.sunFinishedHard = true;
        }
    }
}

hardplus_end()
{
    trigger = getEnt ("hardplus_end","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunFinishedHardPlus))
        {
            iprintln("^5"+player.name+"^7 finished ^1Hard+^7!");
            player.sunFinishedHardPlus = true;
        }
    }
}

int_end()
{
    trigger = getEnt ("int_end","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunFinishedInter))
        {
            iprintln("^5"+player.name+"^7 finished ^4Inter^7!");
            player.sunFinishedInter = true;
        }
    }
}

intplus_end()
{
    trigger = getEnt ("int+_end","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunFinishedInterPlus))
        {
            iprintln("^5"+player.name+"^7 finished ^4Inter+^7!");
            player.sunFinishedInterPlus = true;
        }
    }
}

ez_end()
{
    trigger = getEnt ("ez_end","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunFinishedEasy))
        {
            iprintln("^5"+player.name+"^7 finished ^2Easy^7!");
            player.sunFinishedEasy = true;
        }
    }
}

adv_end()
{
    trigger = getEnt ("adv_end","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunFinishedAdvanced))
        {
            iprintln("^5"+player.name+"^7 finished ^6Advanced!!");
            player.sunFinishedAdvanced = true;
        }
    }
}

adv_roof()
{
    trigger = getEnt ("adv_roof","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunLandedAdvancedRoof))
        {
            iprintln("^5"+player.name+"^7 landed ^6Advanced Roof!!");
            player.sunLandedAdvancedRoof = true;
        }
    }
}

beamed_end()
{
    trigger = getEnt ("beamed_end","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunFinishedBeamed))
        {
            iprintln("^5"+player.name+"^7 finished ^6Beamed!!");
            player.sunFinishedBeamed = true;
        }
    }
}

beamed_roof()
{
    trigger = getEnt ("beamed_roof","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunFinishedBeamedRoof))
        {
            iprintln("^5"+player.name+"^7 landed ^6Beamed Roof!!");
            player.sunFinishedBeamedRoof = true;
        }
    }
}

beamedplus_end()
{
    trigger = getEnt ("beamedplus_end","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunFinishedBeamedPlus))
        {
            iprintln("^5"+player.name+"^7 finished ^6Beamed+");
            player.sunFinishedBeamedPlus = true;
        }
    }
}

bonuseasy_end()
{
    trigger = getEnt ("bonuseasy_end","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunFinishedBonusEasy))
        {
            iprintln("^5"+player.name+"^7 finished ^2Bonus Easy^7!");
            player.sunFinishedBonusEasy = true;
        }
    }
}

bonuseasy_roof()
{
    trigger = getEnt ("bonuseasy_roof","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunLandedBonusEasyRoof))
        {
            iprintln("^5"+player.name+"^7 landed ^2Bonus Easy Roof^7!");
            player.sunLandedBonusEasyRoof = true;
        }
    }
}

bonuseasy_rooftop()
{
    trigger = getEnt ("bonuseasy_rooftop","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunLandedBonusEasyRoofTop))
        {
            iprintln("^5"+player.name+"^7 landed ^2Bonus Easy Roof Top^7!");
            player.sunLandedBonusEasyRoofTop = true;
        }
    }
}

bonusinter_end()
{
    trigger = getEnt ("bonusinter_end","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunFinishedBonusInter))
        {
            iprintln("^5"+player.name+"^7 finished ^4Bonus Inter^7!");
            player.sunFinishedBonusInter = true;
        }
    }
}

bonusinter_roof()
{
    trigger = getEnt ("bonusinter_roof","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunLandedBonusInterRoof))
        {
            iprintln("^5"+player.name+"^7 landed ^4Bonus Inter Roof^7!");
            player.sunLandedBonusInterRoof = true;
        }
    }
}

bonushard_end()
{
    trigger = getEnt ("bonushard_end","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunFinishedBonusHard))
        {
            iprintln("^5"+player.name+"^7 finished ^1Bonus Hard^7!");
            player.sunFinishedBonusHard = true;
        }
    }
}

bonushard_roof()
{
    trigger = getEnt ("bonushard_roof","targetname");
    while(1)
    {
        trigger waittill ("trigger", player);
        if (!isDefined(player.sunLandedBonusHardRoof))
        {
            iprintln("^5"+player.name+"^7 landed ^1Bonus Hard Roof^7!");
            player.sunLandedBonusHardRoof = true;
        }
    }
}


teleporter()
{
    target = getent(self.target, "targetname");
    while(true)
    {
        self waittill("trigger", player);
        player setorigin(target.origin);
        player setplayerangles(target.angles);
        wait 0.1;
    }
}