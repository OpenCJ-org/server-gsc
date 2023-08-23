#include maps\mp\mp_glados;
// map + scripts by Rextrus (steam: "/id/rextrus")
// Rextrus.com
init() {   

    // effects
    
    level.portal_adv_way = getEnt("circle_adv_way", "targetname");
    level.portal_adv_end = getEnt("portal_adv_end", "targetname");

    triggerCustomFX("laser_orange", (17048, 8024, 3080), (0,90,0), 0);
    triggerCustomFX("laser_small_orange_big", level.portal_adv_way.origin, (0,90,0), 0);
    triggerCustomFX("laser_small_orange", level.portal_adv_end.origin, (0,90,0), 0);
    triggerCustomFX("laser_blue", (16264, 10088, 2920), (0,90,0), 0);
    triggerCustomFX("laser_small_blue", (11298, 10828, 78), (0,90,0), 0);

    // stairs 
    thread addstairs("hardStair_trig", "hardStair", 10, 30, 7, 16, -16, 0);

    // easy way
    thread startWay("AdvancedStartTrigger", "^1Advanced", 3);
    thread startWay("ChallengeStartTrigger", "^1Challenge", 5);

    // finishWay(trigger, way, var, finishName, finishdvar, finishdvarvalue, speedName, speeddvar, speeddvarvalue, achievementTime)
    thread finishWay("AdvancedFinishTrigger", "^1Advanced", 3, "", "", -1, "", "", -1, -1);

    thread finishWay("ChallengeFinishTrigger", "^1Challenge", 5, "", "", -1, "", "", -1, -1);

    thread topLandPreset("Advanced_preset", 3);
    thread topLandCheck("Advanced_bot", 3);
    thread topLand("Advanced_top", 3, "^1Advanced", "Over the Clouds", "", 1);


    // the launcher into the big tube
    thread flyUp();

    // motions
    thread brushMoveZ("pyramid1", 50, 2, 1.2, 0.3);
    thread rotateSquareLower("square_lower", 1);
    thread rotateSquareLower("square_lower2", -1);
    thread rotateSquareUpper("square_upper", 1);
    thread rotateSquareUpper("square_upper2", -1);
    thread AdvancedWayRotatingCircle();
    thread sinusWaveInit();

    // secrets 
    thread smileySecret();
}

flyUp() {
    trigger = getent ("flyup","targetname");
    glow = getent ("pos1_jump","targetname");
    air1 = getent ("air1_jump","targetname");
    air2 = getent ("air2_jump","targetname");
    air3 = getent ("air3_jump","targetname");
    air4 = getent ("air4_jump","targetname");

    time = 1;
    for(;;) {
        trigger waittill ("trigger",player);
        if (player istouching(trigger)) {
            //throw = user.origin + (100, 100, 0);
            air = spawn("script_model",(0,0,0));
            air.origin = player.origin;
            air.angles = player.angles;
            player linkto(air);
            air moveto (air1.origin, time);
            wait time;
            air moveto (air2.origin, time);
            wait time;
            air moveto (air3.origin, time);
            wait time;
            air moveto (air4.origin, time);
            if (isDefined(player))
                player unlink();
            wait 1;
        }
    }
}

brushMoveZ(brush, height, timeup, timedown, acc) {
    brush = getent(brush, "targetname");
    height2 = height * (-1);
    while(1) {
        brush movez(height2, timedown, acc, acc);
        brush waittill("movedone");
        brush movez(height, timeup, acc, acc);
        brush waittill("movedone");
    }
}


rotateSquareLower(brushLower, rotationDirection) {
    brushLower = getent(brushLower, "targetname");

    direction = ((rotationDirection)*180);
    brushLower movez(16, 1);
    brushLower waittill("movedone");
    wait 10;

    while(1) {
        brushLower movez(-40, 5, 2.5, 2.5);
        brushLower rotateYaw(-1*direction, 5, 2.5, 2.5);
        brushLower waittill("movedone");
        brushLower movez(40, 5, 2.5, 2.5);
        brushLower rotateYaw(direction, 5, 2.5, 2.5);
        brushLower waittill("movedone");
        brushLower movez(16, 1, 0.5, 0.5);
        brushLower waittill("movedone");
        brushLower movez(-16, 1, 0.5, 0.5);
        brushLower waittill("movedone");
    }
}
rotateSquareUpper(brushUpper, rotationDirection) {
    brushUpper = getent(brushUpper, "targetname");

    brushUpper movez(-16, 1);
    brushUpper waittill("movedone");
    wait 10;

    while(1) {
        brushUpper movez(40, 5, 2.5, 2.5);
        brushUpper rotateYaw(rotationDirection*180, 5, 2.5, 2.5);
        brushUpper  waittill("movedone");
        brushUpper movez(-40, 5, 2.5, 2.5);
        brushUpper rotateYaw(rotationDirection*-180, 5, 2.5, 2.5);
        brushUpper  waittill("movedone");
        brushUpper movez(-16, 1, 0.5, 0.5);
        brushUpper  waittill("movedone");
        brushUpper movez(16, 1, 0.5, 0.5);
        brushUpper  waittill("movedone");
    }
}


AdvancedWayRotatingCircle() {
    brush = getent("AdvancedWayRotatingCircle", "targetname");
    ball_origin = getent("ball_origin","targetname");

    brush moveto(ball_origin.origin, 1);
    brush waittill("movedone");
    wait 1;

    while(1) {
        brush movez(-80, 5, 0.3, 0.8);
        brush rotateYaw(360, 8);
        brush waittill("movedone");
        brush movez(80, 4, 0.3, 0.8);
        brush rotateYaw(360, 8);
        brush waittill("movedone");
    }

}


sinElemMove(distance, time) {
    halfDist = distance * 0.5;
    halfTime = time * 0.5;
    halfVelo = halfTime * 0.4;

    while(1) {
        self moveZ(halfDist, halfTime, halfVelo, halfVelo);
        wait halfTime - 0.05;

        self moveZ(halfDist * -1.0, halfTime, halfVelo, halfVelo);
        wait halfTime - 0.05;
    }
}

sinusWaveInit() {
    sinElems = 26;
    sinDist = 240.0;
    sinFullTime = 2.0;
    sinWait = 2 / sinElems;

    sinus = [];
    for(i = 0; i < sinElems; i++) {
        sinus[i] = getent("sinus"+i, "targetname");
        sinus[i] thread sinElemMove(sinDist, sinFullTime);
        wait sinWait;
    }
}


smileySecret() {
    brushLip = getent("smileyLip", "targetname");
    brushCheeks = getent("smileyCheeks", "targetname");
    trigger = getent("smiley", "targetname");

    while(1) {
        trigger waittill("trigger", player);
        if(isDefined(level.smiley) && !level.smiley) {
            level.smiley = true;
            player iprintlnbold("^5sad ^7 life, isnt it?");
            brushLip movez(32, 1);
            brushCheeks movez(-32, 1);
            wait 5; 
            brushLip movez(-32, 1);
            brushCheeks movez(32, 1);
            wait 1;
            level.smiley = false;
        }
    }
}