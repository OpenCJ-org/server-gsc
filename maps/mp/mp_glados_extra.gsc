#include maps\mp\mp_glados;
// map + scripts by Rextrus (steam: "/id/rextrus")
// Rextrus.com
init() {   

    // effects
    
    // level.portal_adv_way = getEnt("circle_adv_way", "targetname");
    // level.portal_adv_end = getEnt("portal_adv_end", "targetname");

    // triggerCustomFX("laser_orange", (17048, 8024, 3080), (0,90,0), 0);
    // triggerCustomFX("laser_small_orange_big", level.portal_adv_way.origin, (0,90,0), 0);
    // triggerCustomFX("laser_small_orange", level.portal_adv_end.origin, (0,90,0), 0);
    // triggerCustomFX("laser_blue", (16264, 10088, 2920), (0,90,0), 0);
    // triggerCustomFX("laser_small_blue", (11298, 10828, 78), (0,90,0), 0);


    thread startWay("vertexStartTrigger", "^1Vertex", 6);
    thread finishWay("vertexFinishTrigger", "^1Vertex", 6, "", "", -1, "", "", -1, -1);

    thread sinusWaveInitExtra();

    thread extraAnticheat();

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

sinusWaveInitExtra() {
    sinus = [];
    sinus = getentarray("extrasinus", "targetname");

    sinDist = 240.0;
    sinFullTime = 2.0;
    sinWait = 2 / sinus.size;

    for(i = 0; i < sinus.size; i++) {
        sinus[i] thread sinElemMove(sinDist, sinFullTime);
        wait sinWait;
    }
}

extraAnticheat() {
    trigger = getent("extra_anticheat", "targetname");

    while(1) {
        trigger waittill ("trigger", player);

        velocity = player getVelocity();
        player.speed = int(sqrt((velocity[0]*velocity[0])+(velocity[1]*velocity[1])));

        if(isdefined(player.speed) && player.speed < 800) {
            player freezeControls(1);
            wait 0.05;
            player freezeControls(0);
            wait 1.5;
        }
        wait 0.1;
    }
}