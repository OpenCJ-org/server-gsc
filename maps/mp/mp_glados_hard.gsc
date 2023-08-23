#include maps\mp\mp_glados;
// map + scripts by Rextrus (steam: "/id/rextrus")
// Rextrus.com
init() {   

    // effects 11216 -5504 -928
    triggerCustomFX("laser_purple", (3472, -5504, -928), (0,0,0), 0);

    // stairs 
    thread addstairs("harderStair_trig", "harderStair", 11, 30, 7, 16, -16, 3);
    thread initBall();

    // easy way
    thread startWay("HArdStartTrigger", "^6Hard", 2);

    // finishWay(trigger, way, var, finishName, finishdvar, finishdvarvalue, speedName, speeddvar, speeddvarvalue, achievementTime)
    thread finishWay("HardFinishTrigger", "^6Hard", 2, "", "", -1, "", "", -1, -1);

    // thread topLandPreset("Advanced_preset", 3);
    // thread topLandCheck("Advanced_bot", 3);
    // thread topLand("Advanced_top", 3, "^6Hard", "Over the Clouds", "glados_Advanced_finish_Roof", 1);

    level.portal_hard_end = getEnt("portal_hard_end", "targetname");

    triggerCustomFX("laser_small_purple", level.portal_hard_end.origin, (0,90,0), 0);
}

initBall() {
// Speed  = Distance / Time => Time = Distance/speed; quik maffs
    speed = 350;  

    ball = [];
    for(i=0; i<6; i++) {
        ball[i] = getent("movingBall"+i,"targetname");
    }

    while(1) {
        k = randomInt(5);
        ball[k] movingBall(1, speed);
    }
}

movingBall(x, speed) {
    self movez(64, .001);
    self waittill("movedone");
    self movey(x*-512, 512/speed);
    self waittill("movedone");
    self movex(x*128, 128/speed);
    self waittill("movedone");
    self movey(x*384, 384/speed);
    self waittill("movedone");
    self movex(x*288, 288/speed);
    self waittill("movedone");
    self movey(x*-320, 320/speed);
    self waittill("movedone");
    self movex(x*-224, 224/speed);
    self waittill("movedone");
    self movey(x*-160, 160/speed);
    self waittill("movedone");
    self movex(x*320, 320/speed);
    self waittill("movedone");
    self movey(x*608, 608/speed);
    self waittill("movedone");
    self movex(x*-512, 512/speed);
    self waittill("movedone");
    self movez(-64, .001);
    self waittill("movedone");
}