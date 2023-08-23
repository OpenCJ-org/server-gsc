#include maps\mp\mp_glados;
// map + scripts by Rextrus (steam: "/id/rextrus")
// Rextrus.com
init() {   

    thread startWay("interStartTrigger", "^5Inter", 1);


    thread finishWay("interFinishTrigger", "^5Inter", 1, -1, "", -1, "", "", -1, -1);

    thread topLandPreset("Inter_preset", 1);
    thread topLandCheck("interFinishTrigger", 1);
    thread topLand("Inter_top", 1, "^5Inter", "Higher than Snoopy", "glados_S2J88iEQjLN8SDOILcDcd55SH8XC058MEErnOXXuLAgZnPo5xjqaHJGnxsigW9pAWVjLZPtsgJ074sRv6Q9cP1QgIoPNRgNL5AC7", 1);

    thread topLandPreset("Inter_preset2", 4);
    thread topLandCheck("inter_bot", 4);
    thread topLandSec("Inter_top2", 4, "Shortcut", "glados_Odx2oVarGASLgYijOgzvhmeH4iBqmYjf3GLewASvUlPPdfDbeBQPvpzjDjnRIwNqFIvTNRTpNG6KaSUkd8g3IGv6z9M9KYIwdDe6", 1);


    level.portal_inter_end = getEnt("portal_inter_end", "targetname");

    triggerCustomFX("laser_small_blue", level.portal_inter_end.origin, (0,90,0), 0);

    thread initDoener();
}

initDoener() {
    brush = getEnt("doener", "targetname");

    while(1) {
        brush rotateYaw(360, 30);
        wait 30;
    }
}
topLandSec(trigger, var, achievementName, dvar, dvarvalue) {
    trig = getent(trigger, "targetname");

    while(1) {
        trig waittill("trigger", player);

        if(isDefined(player.top[var]) && !player.top[var] && !player.bot[var]) {
            iPrintLnBold("^5" + player.name + "^7 found a shortcut");
            player.top[var] = true;
        }
    }
}
