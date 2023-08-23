#include maps\mp\mp_glados;
// map + scripts by Rextrus (steam: "/id/rextrus")
// Rextrus.com
init() {
    
    level.Easy = "implemented";
    
    // Smoke between gears
    thread initSmokeOrigins("gear_smoke0"); 
    thread initSmokeOrigins("gear_smoke1"); 
    thread initSmokeOrigins("gear_smoke2"); 
    thread initSmokeOrigins("gear_smoke3"); 

    // Script for lights in the end floor
    //thread lightsOn("lightsOn0", "red_light1_", "red_light", 0);
    //thread lightsOn("lightsOn1", "red_light2_", "red_light", 1);
    //thread lightsOn("lightsOn2", "red_light3_", "red_light", 2);
    //thread lightsOn("lightsOn3", "red_light4_", "red_light", 3);
    //thread lightsOn("lightsOn4", "red_light5_", "red_light", 4);

    // stairs close to end
    thread addstairs("easyStair_trig01", "easy_step", 16, 30, 5, 4, -4, 1);
    thread addstairs("easyStair_trig02", "easy_steps", 16, 30, 5, 4, -4, 2);

    // easy way
    thread startWay("easyStartTrigger", "^2Easy", 0);
    // finishWay(trigger, way, var, finishName, finishdvar, finishdvarvalue, speedName, speeddvar, speeddvarvalue, achievementTime)
    thread finishWay("easyFinishTrigger", "^2Easy", 0, -1, "", -1, "", "", -1, -1);

    thread topLandPreset("easy_preset", 0);
    thread topLandCheck("easy_bot", 0);
    thread topLand("easy_top", 0, "^2Easy", "How's the weather up there?", "", 1);

    // the launcher from the big room with the big circle in it
    thread bouncer("boostEasy", 13);

    // motions
    thread rotateGear("gear1", 1, 6);
    thread rotateGear("gear2", -1, 6);
    thread rotateGear("gear3", 1, 6);
    thread rotateGear("gear4", -1, 6);
}

initSmokeOrigins(origin) {
    placement = getEnt(origin, "targetname");

    triggerCustomFX("gear_smoke", placement.origin, (0,90,0), 0);
}

bouncer(trigger, height) {
    trigger = getEnt (trigger, "targetname");

    while(1) {
        trigger waittill ("trigger", player);

        oldpos = player.origin;
        strenght = height;
        //player setClientDvars( "bg_viewKickMax", 0, "bg_viewKickMin", 0, "bg_viewKickRandom", 0, "bg_viewKickScale", 0, "ui_hardcore_hud", 1 );

        for(i=0;i<strenght;i++) {
            player.health += 1000000;
            player.maxhealth += 1000000;
            player finishPlayerDamage(player, player, 160, 0, "MOD_UNKNOWN", "bounce", player.origin, AnglesToForward((-90,0,0)), "none", 0);
        }
    }
}

rotateGear(brush, direction, time) {
    brush = getent(brush, "targetname");
    wait 3;

    while(1) {
        brush rotateRoll(direction*360, time);
        wait time;
    }
}

