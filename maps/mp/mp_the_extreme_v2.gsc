
//scripts by  Arkani, Blade and Fr33g !t, thanks to IzNoGoD too!
//visit vistic-clan.net and 3xp-clan.com

//map by Arkani 
// My Steam http://steamcommunity.com/id/rextrus

//thanks to Ultimate for permission to create a second version
// His Steam: http://steamcommunity.com/id/LitkuReiska


#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

main()
{
    maps\mp\_load::main();
    maps\mp\mp_the_extreme_v2_cameras::init();
    maps\mp\mp_the_extreme_v2_leaderboard::init();
    maps\mp\mp_the_extreme_v2_motions::init();
    maps\mp\mp_the_extreme_v2_music::init();

    game["allies"] = "marines";
    game["axis"] = "opfor";
    game["attackers"] = "allies";
    game["defenders"] = "axis";
    game["allies_soldiertype"] = "desert";
    game["axis_soldiertype"] = "desert";

    level.letters = 0;
    level.lettera = 0;
    level.letterr = 0;
    level.letterk = 0;
    level.lettera2 = 0;
    level.lettern = 0;
    level.letteri = 0;
    level.hawkbrush = 0;

    setdvar("r_specularcolorscale","5");
    setdvar("r_glowbloomintensity0",".25");
    setdvar("r_glowbloomintensity1",".25");
    setdvar("r_glowskybleedintensity0",".3");
    setdvar("compassmaxrange","1800");
    
    setdvar("jump_slowdownenable","0");
    setDvar("bg_fallDamageMaxHeight", 9999);
    setDvar("bg_fallDamageMinHeight", 9998);

    thread teleporter();
    thread connectListener();
    thread endmessages();
    thread easy_roof();
    thread bouncer("speed", 13);
    thread bouncer("speed2", 14); 
    thread bouncer("speed3", 5);
    thread bouncer("speed4", 9);
    thread bouncer("speed8", 7);
    thread bouncer("speed7", 2);

    bounce  = getEntArray("speed5", "targetname");
    
    for(i = 0;i < bounce.size;i++)
        bounce[i] thread bounce();


    thread potato_secret();
    thread pro();
    thread fin_funk();
    thread explus();
    thread explusend();

    thread key1();
    thread key2();
    thread key3();
    thread door1();
    thread door2();
    thread door3();

    thread cheater();
    thread eztp("bringtotop", "top_origin");
    thread eztp("bringtobottom", "bot_origin");
    thread extopreset();
    thread exbottomland();
    thread extopland();
    thread intertopreset();
    thread interbottomland();
    thread intertopland();
    thread detroit();
    thread end_interpluslastTOP();
}
addletter(which)
{
   letter = getent(which, "targetname");

    for(;;)
    {
        letter movez(20, 1, 0.3, 0.3);
        letter waittill("movedone");
        letter  movez(-20, 1, 0.3, 0.3);
        letter waittill("movedone");
    }
}
intertopreset()
{
    reset = getent("interreset", "targetname");

    for(;;)
    {
        reset waittill("trigger", who);

        if(isdefined(who.int_bot) && who.int_bot == true)
            who.int_bot = false;
    }
}
interbottomland()
{
    bottom = getent("interbot", "targetname");

    for(;;)
    {
        bottom waittill("trigger", who);

        if(isdefined(who.int_bot) && !who.int_bot)
            who.int_bot = true;
    }
}
intertopland()
{
    top = getent("intertop", "targetname");

    for(;;)
    {
        top waittill("trigger", who);

        if(isDefined(who.int_top) && !who.int_top && !who.int_bot)
        {
            iprintln(who.name+" has landed ^5Inter Roof!");
            who.int_top = true;
        }
    }
}
extopreset()
{
    reset = getent("extremetopreset", "targetname");

    for(;;)
    {
        reset waittill("trigger", who);

        if(isdefined(who.ex_bot) && who.ex_bot == true)
            who.ex_bot = false;
    }
}
exbottomland()
{
    bottom = getent("extremebot", "targetname");

    for(;;)
    {
        bottom waittill("trigger", who);

        if(isdefined(who.ex_bot) && !who.ex_bot)
            who.ex_bot = true;
    }
}
extopland()
{
    top = getent("extremetop", "targetname");

    for(;;)
    {
        top waittill("trigger", who);

        if(isDefined(who.ex_top) && !who.ex_top && !who.ex_bot)
        {
            iprintln(who.name+" has landed ^5Extreme Roof!");
            who.ex_top = true;
        }
    }
}
calculateTimes(time)
{
    fintime = [];
   fintime["min"] = int(time / 1000 / 60);
   fintime["sec"] = int((time - fintime["min"] * 60 * 1000) / 1000);
   if(fintime["sec"] < 10){
        temp = fintime["sec"];
        fintime["sec"] = "0";
        fintime["sec"] += temp;
   }

   fintime["msec"] = int((time - (fintime["min"] * 60 * 1000) - (int(fintime["sec"]) * 1000)));
    return fintime;
}
explus()
{
  trig = getEnt("extrplus", "targetname");

  for(;;)
    {
        trig waittill( "trigger", who );

        if(!isdefined(who.extrplus) || !who.extrplus)
        {
          who.timestart = getTime();
          who.extrplus=true;
          who.extrplusfin = false;
        }
        wait .05;
    }
}

explusend()
{
    trigger = getent("explusend", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", player);
        
        if(!player.extrplusfin)
        {
            player.extrplusfin = true;
            player.timeend = getTime() - player.timestart;
            player.timeend = calculateTimes(player.timeend);
            iprintln(player.name+" ^7 has finished ^5Extreme PLUS ^7Way in " + player.timeend["min"] + ":" +player.timeend["sec"] + "!");
            wait 1;
            if (isDefined(player))
            {
                player.extrplus=false;
            }
        }
    }
}
bounce()
{
    for(;;)
    {
        self waittill("trigger", p);
        
        if(!isDefined(p.bouncing))
            p thread player_bounce(self);
    }
}

player_bounce(trigger)
{
    self endon("disconnect");
    self.bouncing = true;
    
    level.knockback = getDvar("g_knockback");
    
    vel = self getVelocity();

    temp0 = (((vel[0] < 350 && vel[0] > 0) || (vel[0] > -350 && vel[0] < 0)));
    temp1 = (((vel[1] < 350 && vel[1] > 0) || (vel[1] > -350 && vel[1] < 0)));

    if((!temp0 && !temp1) || vel[2] > -350)
    {
        wait 1;
        
        self.bouncing = undefined;
        return;
    }

    self emulateKnockback(1000, (0,0,1), (vel[2]*-9)-500);

    while(self isTouching(trigger))
        wait 0.05;

    self.bouncing = undefined;
}

emulateKnockback(dmg, dir, g_knockback_val)
{
    //not taking stance into account
    //adjust dmg if player is always crouching
    dmg *= 0.3;
    if(dmg > 60)
        dmg = 60;
    knockback = dmg * g_knockback_val / 250;
    self addVelocity(vectorscale(dir, knockback));

	//for reference, this should also be executed according to cod2rev_server code
	//pm_time might be nonzero due to jump though
	// if ( !ent->client->ps.pm_time )
	// {
	// 	maxDmg = 2 * minDmg;

	// 	if ( 2 * minDmg <= 49 )
	// 		maxDmg = 50;

	// 	if ( maxDmg > 200 )
	// 		maxDmg = 200;

	// 	ent->client->ps.pm_time = maxDmg;
	// 	ent->client->ps.pm_flags |= 0x400u;
	// }
}

eztp(trig, orig)
{
    trigger = getent(trig,"targetname");
    origin = getent(orig,"targetname");

    while(1)
    { 
        trigger waittill("trigger",user);
        user setOrigin(origin getOrigin());
    }
}
bouncer(which, height)
{
    trigger = getEnt (which, "targetname");

    while(1)
    {
        trigger waittill ("trigger", who);

        oldpos = who.origin;
        strenght = height;
        who setClientDvars( "bg_viewKickMax", 0, "bg_viewKickMin", 0, "bg_viewKickRandom", 0, "bg_viewKickScale", 0, "ui_hardcore_hud", 1 );

        for(i=0;i<strenght;i++)
        {
            who.health += 1000000;
            who.maxhealth += 1000000;
            who finishPlayerDamage(who, who, 160, 0, "MOD_UNKNOWN", "bounce", who.origin, AnglesToForward((-90,0,0)), "none", 0);
        }
    }
}

connectListener()
{
    while (1) 
    {
        level waittill("connecting", player);

        wait 3;
        if (isDefined(player))
        {
            player.keys = 0;
            player.key1 = 0;
            player.key2 = 0;
            player.key3 = 0;
            player.key1found = false;
            player.key2found = false;
            player.key3found = false;
            player.door1 = false;
            player.door2 = false;
            player.door3 = false;
            player.easy_roof = false;
            player.pj = false;
            player.pro = false;
            player.m2 = false;
            player.end_interpluslastTOP = false;
            player.fin_funk = false;
            player.ex_bot = false;
            player.ex_top = false;
            player.int_bot = false;
            player.int_top = false;
            player.blade = false;
            player.sexy = false; // haha
            player.potato_secret = false;
            player thread onPlayerConnect();
        }
    }
}
onPlayerConnect()
{
    level endon("game_ended");
    self waittill("spawned_player");


    mapname = getDvar("mapname");

    notifyData = spawnStruct();
    notifyData.titleText = "Welcome ^5"+self.name+"^7 to "+mapname+"!";
    notifyData.notifyText = "Map by Arkani";
    notifyData.duration = 3;
    maps\mp\gametypes\_hud_message::notifyMessage(notifyData);

    if(!isDefined(self.messageMutex))
        self.messageMutex = [];

    self.extrplus = false;
}
endMessages()
{
    for(i=0;i<20;i++)
    {
        ent = getent("message_"+i,"targetname");
        //Ent Should be defined, but we check if it exists, just in case ;-)
        if(!isDefined(ent))
            continue;

        ent thread waitfortrigger(i);
    }
}

waitForTrigger(i)
{
    while(1)
    {
        self waittill("trigger", player);
        //Lock the mutex to get a message cooldown
        if(!isDefined(player.messageMutex) 
            || !isDefined(player.messageMutex[i]) 
            || !player.messageMutex[i])
        {
            player thread displayMessage(i);
        }
    }
}

displayMessage(i)
{
    self.messageMutex[i] = true;

    switch(i)
    {
        case 0:
            what = "Thanks to ^5Moug^7 for creating jumps with me!";
            break;
        case 1:
            what = "Thanks to ^5Fr33g !t^7, ^5Blade ^7and ^5IzNoGoD^7 for script helping!";
            break;
        case 5:
            what = "^5Special ^7Thanks: ^1Funk ^7for doing ^6Walkthroughs^7 and ^5Map Trailer^7!";
            break;
        case 6:
            what = "Thanks to the ^1CoD^7Jumper Community for being active!";
            break;
        case 7:
            what = "Map by ^5Arkani ^7\n My Steam ID: ^5rextrus";
            break;
        case 8:
            what = "^5Special ^7Thanks: ^1Drizzjeh ^7 and ^1Xploz ^7for doing ^6Walkthroughs^7!";
            break;
        case 9:
            what = "Thanks for playing this map! I hope you enjoyed ^2mp_the_extreme_v2^7!";
            break;
        case 10:
            what = "You have landed ^2Easy^7 Roof!";
            break;
        default:
            what = "";
    }
    
    self iprintln(what);

    wait 3;
    self.messageMutex[i] = false;
}

potato_secret()
{
    trigger = getent("potato_secret", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(isDefined(who.potato_secret) && !who.potato_secret)
        {
            who.potato_secret = true;
            iprintln(who.name+" found the ^3Potato ^7Secret!");
            wait 1;
        }
    }
}

pro()
{
    trigger = getent("pro", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(isDefined(who.pro) && !who.pro)
        {
            who.pro = true;
            iprintln(who.name+" is ^5Pro^7!");
            wait 1;
        }
    }
}

end_interpluslastTOP()
{
    trigger = getent("end_interpluslastTOP", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(isDefined(who.end_interpluslastTOP) && !who.end_interpluslastTOP)
        {
            who.end_interpluslastTOP = true;
            iprintln(who.name+" landed ^5Inter+ TOP ^7 \n how the fucking hell? ;)");
            wait 1;
        }
    }
}
fin_funk()
{
    trigger = getent("fin_funk", "targetname");
    brush = getent("hawk", "targetname");
    target = getent("ele1","targetname");
    
    for(;;)
    {
        trigger waittill("trigger", who);
        
        if(isDefined(who.fin_funk) && isDefined(level.hawkbrush) && !who.fin_funk && !level.hawkbrush)
        {
            who.fin_funk = true;
            iprintln(who.name+" found ^5F^7u^5n^7k ^5S^7e^5c^7r^5e^7t!");
            who iprintlnbold("Here you go with a nice picture of 3xP' Hawk!");
            wait 1;
            level.hawkbrush = true;
            brush movex(-3, 1);
            wait 10;
            brush movex(3, 1);
            level.hawkbrush = false;
        }
        wait 1;
        if (isDefined(who))
        {
            who freezecontrols(1);
            who setorigin(target.origin);
            who setplayerangles(target.angles);
        }
        wait 0.1;
        if (isDefined(who))
            who freezecontrols(0);
        wait 1;
    }
}

teleporter()
{
    teleports = getentarray("teleport","targetname");
    if(!isDefined(teleports))
    	return;

    for(i = 0; i < teleports.size; i++)
    	teleports[i] thread teleportListener();

    teleportsChecks = getentarray("teleport2","targetname");
    //iprintlnbold("Size &&1", teleportsChecks.size);
    if(!isDefined(teleportsChecks))
    	return;

    for(i = 0; i < teleportsChecks.size; i++)
    	teleportsChecks[i] thread telePortCheck();
}

teleportListener()
{
    target = getent(self.target,"targetname");
    if(!isDefined(target)) return;

    for(;;)
    {
        self waittill("trigger", player);
        wait .05;
        if (isDefined(player))
        {
            player setorigin(target.origin);
            player setplayerangles(target.angles);
        }
    }
}

telePortCheck(){

    target = getent(self.target,"targetname");
    if(!isDefined(target)) return;

    for(;;)
    {
        self waittill("trigger", player);
        player thread askForTeleport(target);
    }
}

askForTeleport(target){
    self endon("disconnect");

    if(isDefined(self.teleportMutex) && self.teleportMutex)
        return;

    self.teleportMutex = true;
    self.blockload = true;
    counter = 0;
    while(counter < 5){
        if(self useButtonPressed()){

            self iprintlnbold("Are you sure you want to ^5skip^7 the BHop?");
            wait 1;
            while(counter < 5){
                if(self useButtonPressed()){
                      self setorigin(target.origin);
                      self setplayerangles(target.angles);
                      iprintln(self.name+" is a noob");
                      break;
                }
                counter += 0.05;
                wait 0.05;
            }
            break;
        }
        counter += 0.05;
        wait 0.05;
    }

    self iprintln("Delay outtimed");
    self.blockload = false;
    self.teleportMutex = false;
}

key1()
{
    trig = getEnt("art_acti1", "targetname");
    
    while(1)
    {
        trig waittill("trigger", player);
        
        if(!player.key1found)
        {
            player.key1 = 1;
            player.key1found = true;
            
            player iprintlnBold("^3Congratulations ^2" + player.name + " ^3you have found an ^5Artifact^1!");
            
            player.keys = player.key1 + player.key2 + player.key3;
            
            switch(player.keys)
            {
                case 1: player iprintlnBold("You have found ^51 ^7out of ^53 ^7Artifacts!"); break;
                case 2: player iprintlnBold("You have found ^52 ^7out of ^53 ^7Artifacts!"); break;
                case 3: player iprintlnBold("You have found ^53 ^7out of ^53 ^7Artifacts!"); break;
                default: break;
            }
        }
        else
            wait 0.05;
    }
}
key2()
{
    trig = getEnt("art_acti2", "targetname");
    
    while(1)
    {
        trig waittill("trigger", player);
        
        if(!player.key2found)
        {
            player.key2 = 1;
            player.key2found = true;
            
            player iprintlnBold("^3Congratulations ^2" + player.name + " ^3you have found an ^5Artifact^1!");
            
            player.keys = player.key1 + player.key2 + player.key3;
            
            switch(player.keys)
            {
                case 1: player iprintlnBold("You have found ^51 ^7out of ^53 ^7Artifacts!"); break;
                case 2: player iprintlnBold("You have found ^52 ^7out of ^53 ^7Artifacts!"); break;
                case 3: player iprintlnBold("You have found ^53 ^7out of ^53 ^7Artifacts!"); break;
                default: break;
            }
        }
        else
            wait 0.05;
    }
}
key3()
{
    trig = getEnt("art_acti3", "targetname");
    
    while(1)
    {
        trig waittill("trigger", player);
        
        if(!player.key3found)
        {
            player.key3 = 1;
            player.key3found = true;
            
            player iprintlnBold("^3Congratulations ^2" + player.name + " ^3you have found an ^5Artifact^1!");
            
            player.keys = player.key1 + player.key2 + player.key3;
            
            switch(player.keys)
            {
                case 1: player iprintlnBold("You have found ^51 ^7out of ^53 ^7Artifacts!"); break;
                case 2: player iprintlnBold("You have found ^52 ^7out of ^53 ^7Artifacts!"); break;
                case 3: player iprintlnBold("You have found ^53 ^7out of ^53 ^7Artifacts!"); break;
                default: break;
            }
        }
        else
            wait 0.05;
    }
}
door1()
{
    door = getent("secret_dooor", "targetname");
    trig = getent("art_secret", "targetname"); 
    
    while(1)
    {
        trig waittill("trigger", player);
        
        if(player.keys >= 1 || player.vip)
        {
            if(!player.door1)
            {
                if(player.keys == 1)
                    player iprintlnbold("You have found ^1" + player.keys + " ^7Artifact! Come on in!");
                else
                    player iprintlnbold("You have found ^1" + player.keys + " ^7Artifacts! Come on in!");
                player.door1 = true;
            }
            
            door rotateyaw(90, 1.5, 0.7, 0.7);
            door waittill("rotatedone");
            wait 2; 
            door rotateyaw(-90, 1.5, 0.7, 0.7);
            wait 1;
            door waittill("rotatedone");
        }
        else
        {
            player iprintlnbold("^7To open this door, you must find at least ^61 ^7hidden ^6Artifact!");
            wait 5;
        }
    }
}
door2()
{
    door = getent("secret_door_lobby2", "targetname");
    trig = getent("art_secret2", "targetname");
    
    while(1)
    {
        trig waittill("trigger", player);
        
        if(player.keys >= 2 || player.vip)
        {
            if(!player.door2)
            {
                player iprintlnbold("You have found ^1" + player.keys + " ^7Artifacts! Come on in!");
                player.door2 = true;
            }
            door moveZ(248, 4, 0.7, 0.7);
            door waittill("movedone");
            wait 3; 
            door moveZ(-248, 4, 0.7, 0.7);
            door waittill("movedone");
        }
        else
        {
            player iprintlnbold("^7To open this door, you must find at least ^62 ^7hidden ^6Artifacts!");
            wait 5;
        }
    }
}

door3()
{
    door = getent("secret_door_lobby3", "targetname"); 
    trig = getent("art_secret3", "targetname"); 
    
    while(1)
    {
        trig waittill("trigger", player);
        
        if(player.keys == 3 || player.vip)
        {
            if(!player.door3)
            {
                player iprintlnbold("You have found ^1" + player.keys + " ^7Artifacts! Come on in!");
                player.door3 = true;
            }
            
            door moveZ(248, 4, 0.7, 0.7);
            door waittill("movedone");
            wait 3;
            door moveZ(-248, 4, 0.7, 0.7);
            door waittill("movedone");
        }
        else
        {
            player iprintlnbold("^7To open this door, you must find ^63 ^7hidden ^6Artifacts!");
            wait 5;
        }
    }
}

easy_roof()
{
    trigger = getent("ez_roof", "targetname");
    
    for(;;)
    {
        trigger waittill("trigger", player);
        
        if(!player.easy_roof)
        {
            player.easy_roof = true;
            iprintln(player.name+" landed on ^2Easy ^7Way Roof!");
            wait 1;
        }
    }
}

cheater()
{
    trigger = getEnt("cheater", "targetname");
    target = getent("spawn_origin","targetname");
    
    while(1)
    {
        trigger waittill("trigger", player);

        if(player.keys == 0 && !player.vip)
        {
            player iPrintLnBold("^3You ^1tried to get into the secret room by cheating! NOOB!");
            player freezecontrols(1);
            player setorigin(target.origin);
            player setplayerangles(target.angles);
            wait 0.1;
            player freezecontrols(0);
            wait 1;
        }
        wait 0.05;
    }
}

detroit()
{
    thread arkani();
    thread addletter("lettera");
    thread addletter("letterr");
    thread addletter("letterk");
    thread addletter("lettera2");
    thread addletter("lettern");
    thread addletter("letteri");
    thread lettera("lettera");
    thread letterr("letterr");
    thread letterk("letterk");
    thread lettera2("lettera2");
    thread lettern("lettern");
    thread letteri("letteri");
}
arkani()
{
    trigger = getent("detroit_trig", "targetname");
    target = getent("detroit", "targetname");

    for(;;)
    {
        trigger waittill("trigger", who);

        level.letters = level.lettera + level.letterr + level.letterk + level.lettera2 + level.lettern + level.letteri;

        if(level.letters == 6 || getSubStr(who getGuid(), -8) == "91f89ba1" || getSubStr(who getGuid(),-8) == "73334129")
        {
            who iPrintLnBold("Congratulations, "+who.name+" you found all 6 Letters of ^5A.R.K.A.N.I!\n^7 You can now enter the^5 Secret^7 Room!");
            who setOrigin(target.origin);
            iprintln(who.name+" found the ^5Detroit Secret^7!");
            wait 1;
        }
        else
        {
            who iprintlnbold("To enter this funnel, you need to find ^5all 6^7 hidden letters on this map!");
            if(level.letters != 1)
                who iprintlnbold("^5"+level.letters+" ^7letters have been found already.");
            else
                who iprintlnbold("^5"+level.letters+" ^7letter has been found already.");
                wait 5;
        }
        wait 1;
    }
}
lettera(which)
{
    trig = getEnt("lettera_trig", "targetname");
    letter = getent(which, "targetname");
    while(1)
    {
        trig waittill("trigger", player);
        
        if(isDefined(level.lettera) && !level.lettera)
        {
            level.lettera = 1;
            
            iprintln(player.name+" found the letter ^5A^7!");
            wait .05;
        }
        else
        	player iprintlnBold("This letter has been ^1found^7 already!");
            wait .05;
    }
}
letterr(which)
{
    trig = getEnt("letterr_trig", "targetname");
    letter = getent(which, "targetname");
    while(1)
    {
        trig waittill("trigger", player);
        
        if(isDefined(level.letterr) && !level.letterr)
        {
            level.letterr = 1;
            
            iprintln(player.name+" found the letter ^5R^7!");
            wait .05;
        }
        else
        	player iprintlnBold("This letter has been ^1found^7 already!");
            wait 0.05;
    }
}
letterk(which)
{
    trig = getEnt("letterk_trig", "targetname");
    letter = getent(which, "targetname");
    while(1)
    {
        trig waittill("trigger", player);
        
        if(isDefined(level.letterk) && !level.letterk)
        {
            level.letterk = 1;
            
            iprintln(player.name+" found the letter ^5K^7!");
            wait .05;
        }
        else
        	player iprintlnBold("This letter has been ^1found^7 already!");
            wait 0.05;
    }
}
lettera2(which)
{
    trig = getEnt("lettera2_trig", "targetname");
    letter = getent(which, "targetname");
    while(1)
    {
        trig waittill("trigger", player);
        
        if(isDefined(level.lettera2) && !level.lettera2)
        {
            level.lettera2 = 1;
            
            iprintln(player.name+" found the letter ^5A^7!");
            wait .05;
        }
        else
        	player iprintlnBold("This letter has been ^1found^7 already!");
            wait 0.05;
    }
}
lettern(which)
{
    trig = getEnt("lettern_trig", "targetname");
    letter = getent(which, "targetname");
    while(1)
    {
        trig waittill("trigger", player);
        
        if(isDefined(level.lettern) && !level.lettern)
        {
            level.lettern = 1;

            iprintln(player.name+" found the letter ^5N^7!");
            wait .05;       
        }
        else
        	player iprintlnBold("This letter has been ^1found^7 already!");
            wait 0.05;
    }
}
letteri(which)
{
    trig = getEnt("letteri_trig", "targetname");
    letter = getent(which, "targetname");
    while(1)
    {
        trig waittill("trigger", player);
        
        if(isDefined(level.letteri) && !level.letteri)
        {
            level.letteri = 1;

            iprintln(player.name+" found the letter ^5I^7!");
            wait .05;
        }
        else
        	player iprintlnBold("This letter has been ^1found^7 already!");
            wait 0.05;
    }
}