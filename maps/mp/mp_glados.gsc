#include maps\mp\_utility;
#include common_scripts\utility;
// map & scripts by Rextrus (steam: "/id/rextrus")
// Rextrus.com
main()
{
    maps\mp\_load::main();

    level._effect["laser_orange"] = loadfx("glados/laser_orange");
    level._effect["laser_blue"] = loadfx("glados/laser_blue");
    level._effect["laser_purple"] = loadfx("glados/laser_purple");
    level._effect["laser_small_purple"] = loadfx("glados/laser_small_purple");
    level._effect["laser_small_orange"] = loadfx("glados/laser_small_orange");
    level._effect["laser_small_orange_big"] = loadfx("glados/laser_small_orange_big");
    level._effect["laser_small_blue"] = loadfx("glados/laser_small_blue");
    level._effect["laser_small_green"] = loadfx("glados/laser_small_green");
    level._effect["red_light"] = loadfx("glados/red_light");
    level._effect["gear_smoke"] = loadfx("glados/gear_smoke");

    level.smiley = false;
    level.lobbySecret = false;

    // Light at the end of easy way
    level.lightsOn = [];
    level.lightsOn[0] = false;
    level.lightsOn[1] = false;
    level.lightsOn[2] = false;
    level.lightsOn[3] = false;
    level.lightsOn[4] = false;

    // stairs movement
    level.stairs = [];
    level.stairs[0] = false; // Advanced way
    level.stairs[1] = false; // Easy way
    level.stairs[2] = false; // Easy way (the second)
    level.stairs[3] = false; // Hard way

    // artifact door variable
    level.art1 = false;
    level.art1_open = false;

    level.isDoorMoving = [];
    level.isDoorMoving[0] = false;
    level.isDoorMoving[1] = false;

    level.secretMovementDone = false;

    game["allies"] = "marines";
    game["axis"] = "opfor";
    game["attackers"] = "allies";
    game["defenders"] = "axis";
    game["allies_soldiertype"] = "desert";
    game["axis_soldiertype"] = "desert";

    setdvar("env_fog", "0");
    setdvar("r_glowbloomintensity0",".1");
    setdvar("r_glowbloomintensity1",".1");
    setdvar("r_glowskybleedintensity0",".1");
    setdvar("compassmaxrange","1900");
    setdvar( "r_specularcolorscale", "1.86" );
    setdvar("jump_slowdownenable","0");
    setDvar("bg_fallDamageMaxHeight", 9999);
    setDvar("bg_fallDamageMinHeight", 9998);

    maps\mp\mp_glados_easy::init();
    maps\mp\mp_glados_hard::init();
    maps\mp\mp_glados_bonus::init();
    maps\mp\mp_glados_inter::init();
    maps\mp\mp_glados_advanced::init();
    maps\mp\mp_glados_extra::init();

    // main lobby
    level.portal_inter_lobby = getEnt("portal_inter_lobby", "targetname");
    level.portal_easy_lobby = getEnt("portal_easy_lobby", "targetname");
    level.portal_adv_lobby = getEnt("portal_adv_lobby", "targetname");
    level.portal_hard_lobby = getEnt("portal_hard_lobby", "targetname");

    triggerCustomFX("laser_small_orange", level.portal_adv_lobby.origin, (0,90,0), 0);
    triggerCustomFX("laser_small_purple", level.portal_hard_lobby.origin, level.portal_hard_lobby.angles, 0);
    triggerCustomFX("laser_small_blue", level.portal_inter_lobby.origin, (0,90,0), 0);
    triggerCustomFX("laser_small_green", level.portal_easy_lobby.origin, (0,90,0), 0);

    thread lobbySecretDoor();

    thread startWay("beach_start", "^3Beach", 4);
    thread finishWay("beach_fin", "^3Beach", 4, "Beach", "", 1, "", "", -1, -1);

    thread onPlayerConnect();
    thread teleporter();
}

onPlayerConnect() {
    level endon("game_ended");

    while(1) {
        level waittill("connected", player);

        player thread initPlayerStuff();
    }
}

initPlayerStuff() {
    self endon("disconnect");

    // check if route already finished
    self.FinishedWay = [];
    self.FinishedWay[0] = true;  // Easy way
    self.FinishedWay[1] = true;  // Inter way
    self.FinishedWay[2] = true;  // Hard way
    self.FinishedWay[3] = true;  // Advanced way
    self.FinishedWay[4] = true;  // Secret way
    self.FinishedWay[5] = true;  // Challenge way
    self.FinishedWay[6] = true;  // vertex way
    // check if top is landed or not
    self.top = [];
    self.top[0] = false; // Easy way
    self.top[1] = false; // Inter way
    self.top[2] = false; // Hard way
    self.top[3] = false; // Advanced way
    self.top[4] = false; // 2nd inter
    self.top[6] = false; // vertex
    // check if player directly landed top 
    self.bot = [];
    self.bot[0] = false; // Easy way
    self.bot[1] = false; // Inter way
    self.bot[2] = false; // Hard way
    self.bot[3] = false; // Advanced way
    self.bot[4] = false; // 2nd inter
    // if player i getting teleported (important for getWalkedDistance)
    self.tpState = false;

    // also necessary without achievemnt system
    self.takenGun = [];
    self.takenGun[0] = false;
    self.takenGun[1] = false;
    self.takenGun[2] = false;
    self.trapSecret = 0;
    self.speedSecret = 0;
    self.edgeSecret = 0;

    //artifact script
    self.foundArt = [];
    self.foundArt[0] = false;
    self.foundArt[1] = false;

    wait 10;
    self iprintlnbold("Welcome to ^5mp_GLaDOS");
    wait 2;
    self iprintlnbold("Visit^5 Rextrus.com^7 to contact the mapper");
}

finishWay(trigger, way, var, finishName, finishdvar, finishdvarvalue, speedName, speeddvar, speeddvarvalue, achievementTime) {
    level endon("game_ended");

    // check if everything is defined
    parameters = [];
    parameters[0] = way;
    parameters[1] = var;
    parameters[2] = finishName;
    parameters[3] = finishdvar;
    parameters[4] = finishdvarvalue;
    parameters[5] = speedName;
    parameters[6] = speeddvar;
    parameters[7] = speeddvarvalue;
    parameters[8] = achievementTime;
    parameters[9] = trigger;

    for(i = 0; i < parameters.size; i++) {
        if(!isdefined(parameters[i])) {
            //iPrintLn(parameters[i] + " is not defined, could not print timer");
            return; 
        }
    }

    trig = getent(trigger, "targetname");
    
    while(1) {
        trig waittill("trigger", player);
        if(isdefined(player.FinishedWay[var]) && !player.FinishedWay[var]) {
            number = getTime() - player.waytime[var];
            iprintln("^5" + player.name + " ^7has finished " + way + " ^7way in ^5" + realtime(number));
            player.FinishedWay[var] = true;
            player.waytime[var] = undefined;
        }
    }
}

startWay(trigger, way, var) {
    level endon("game_ended");

    if(!isDefined(trigger) || !isDefined(way) || !isdefined(var))
        return;

    trig = getent(trigger, "targetname");

    while(1) {
        trig waittill("trigger", player);
        if(isdefined(player.FinishedWay[var]) && player.FinishedWay[var] == true) {
            player iprintln("You have chosen " + way + "^7 way");
            player iprintln("Have ^5Fun^7");
            player.waytime[var] = getTime();
            player.FinishedWay[var] = false;
        }
    }
}

lobbySecretDoor() {
    trigger = getent("lobbySecTrigger", "targetname"); 

    while(1) {
        trigger waittill("trigger");
        if(isdefined(level.lobbySecret) && !level.lobbySecret) {
            level.lobbySecret = true;

            thread movementlobbySecretDoor("lobbySec1", 90, 2, 0.4, 0.4);
            wait 0.5;
            thread movementlobbySecretDoor("lobbySec2", 90, 2, 0.4, 0.4);
            wait 0.5;
            thread movementlobbySecretDoor("lobbySec3", 90, 2, 0.4, 0.4);
            wait 11;
            level.lobbySecret = false;
        }
    }
}
movementlobbySecretDoor(pillar, angle, time, acc, accs) {
    brush = getEnt(pillar, "targetname");

    brush rotatePitch(90, 2, 0.4, 0.4);
    brush movez(1, 2);
    wait 10;
    brush rotatePitch(-90, 2, 0.4, 0.4);
    brush movez(-1, 2);
}

addstairs(trigger, stair, steps, time, cooldown, up, down, stair_number) {
    trig = getent(trigger, "targetname");

    for(;;) {
        trig waittill("trigger");

        if(!isdefined(level.stairs[stair_number]) || !level.stairs[stair_number]) {
            level.stairs[stair_number] = true;
            for(i=0; i<steps; i++) {
                step[i] = getent(stair+i,"targetname");
                step[i] movez(i*up, .5 + (.1 * i));
            }
            wait time;
            for(i=0; i<steps; i++) {
                step[i] = getent(stair+i,"targetname");
                step[i] movez(i*down, .5 + (.1 * i));
            }
            wait 7;
            level.stairs[stair_number] = false;
        }
    }
}

triggerCustomFX(fxid, origin, angle, delay) {
    wait 0.05;
    if(delay > 0) wait delay;
 
    up = AnglesToUp(angle);
    forward = AnglesToForward(angle);
 
    level.fx = SpawnFX(level._effect[fxid], origin, forward, up);
    TriggerFX(level.fx);
}

teleporter() {
    tele = getentarray("teleport", "targetname");
    if(isdefined(tele)) {
        for(i=0;i<tele.size;i++)
            tele[i] thread portMe();
    }
}

portMe() {
    while(1) {
        self waittill("trigger", player);
        targ = getent(self.target,"targetname");
        player.tpState = true;
        player freezecontrols(1);
        player setorigin(targ.origin);
        player setplayerangles(targ.angles);
        wait .01;
        if (isDefined(player))
            player freezecontrols(0);
        wait 1.5;
        if (isDefined(player))
            player.tpState = false;
    }
}

realtime(number) {
    if(number == 999999999) {
        playertime = "???";
        return playertime;
    }
 
    seconds = int(number/1000);
    hours = int(seconds/3600);
    seconds = seconds%3600;
    minutes = int(seconds/60);
    seconds = seconds%60;
 
    if(seconds <= 9)
        seconds = "0" + seconds;
    if(minutes <= 9)
        minutes = "0" + minutes;
    if(hours <= 9)
        hours = "0" + hours;
 
     playertime =  "" + hours + ":" + minutes + ":" + seconds;
 
    return playertime;
}

topLandPreset(trigger, var) {
    trig = getent(trigger, "targetname");

    while(1) {
        trig waittill("trigger", player);

        if(isdefined(player.bot[var]) && player.bot[var])
            player.bot[var] = false;
    }
}

topLandCheck(trigger, var) {
    trig = getent(trigger, "targetname");

    while(1) {
        trig waittill("trigger", player);

        if(isdefined(player.bot[var]) && !player.bot[var])
            player.bot[var] = true;
    }
}

topLand(trigger, var, way, achievementName, dvar, dvarvalue) {
    trig = getent(trigger, "targetname");

    while(1) {
        trig waittill("trigger", player);

        if(isDefined(player.top[var]) && !player.top[var] && !player.bot[var]) {
            iPrintLn("^5" + player.name + "^7 has landed " + way + "^7 roof");
            player.top[var] = true;
        }
    }
}

topLandNoAchievement(trigger, var, way) {
    trig = getent(trigger, "targetname");

    while(1) {
        trig waittill("trigger", player);

        if(isDefined(player.top[var]) && !player.top[var]) {
            iPrintLn("^5" + player.name + "^7 has landed " + way + "^7 roof");
            player.top[var] = true;
        }
    }
}