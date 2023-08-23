//scripts by  Blade and Fr33g !t, big thanks to IzNoGoD as well!
//visit vistic-clan.net and 3xp-clan.com

//map by Arkani 
// My Steam http://steamcommunity.com/id/rextrus

//thanks to Ultimate for the permission to create a second version
// His Steam: http://steamcommunity.com/id/LitkuReiska

init()
{

    level.stairs = [];
    thread addstairs("interplusStairs_trig", "interplusstep_", 43, 30, 7, 2, -2);
    thread addstairs("interStairs_trig", "interstep_", 43, 30, 7, 2, -2);
    thread addstairs("easy_stairs_trig", "easy_stairs_", 30, 30, 5, 3, -3);
    //thread add_door(trigger, brushmodel);
    thread add_door("elesec1", "sec_door_1");
    thread add_door("door_endroom_trig", "door_endroom");
    thread add_door("e_secretdoor_1_trig", "e_secretdoor_1");
    thread add_garage("secret_door_1_2_trig", "secret_door_1");
    thread add_garage("secret_door_2_2_trig", "secret_door_lobby2");
    thread add_garage("secret_door_3_2_trig", "secret_door_lobby3");
    thread add_door("asecret_dooor", "secret_dooor");

    thread lift_lobby();
    thread lift_secret();
    thread office_door();

}

office_door()
{
    trigger = getent("office_door_trig", "targetname");
    door1 = getent("office_door1", "targetname");
    door2 = getent("office_door2", "targetname");

    for(;;)
    {
        trigger waittill("trigger", player);

        if(isdefined(player.blade) && !player.blade)
        {
            player iprintlnbold("VC' Blade working on scripts in here.. :D");
            player.blade = true;
            wait 0.5;
        }
        //door1 playSound("door1");
        door1 rotateyaw(90, 1.5, 0.7, 0.7);
        door2 rotateyaw(-90, 1.5, 0.7, 0.7);
        wait 10;
        door1 rotateyaw(-90, 1.5, 0.7, 0.7);
        door2 rotateyaw(90, 1.5, 0.7, 0.7);
        wait 2;
    }
}
addstairs(trigger, stairs, steps, time, cooldown, up, down)
{
    trig = getent(trigger, "targetname");

    for(;;)
    {
        trig waittill("trigger", who);

        if(!isdefined(level.stairs[stairs]) || !level.stairs[stairs])
        {
            level.stairs[stairs] = true;
            for(i=0; i<steps; i++)
            {
                step[i] = getent(stairs+i,"targetname");
                step[i] movez(i*up, .5 + (.1 * i));
            }
        }
        wait time;
        for(i=0; i<steps; i++)
        {
            step[i] = getent(stairs+i,"targetname");
            step[i] movez(i*down, .5 + (.1 * i));
        }
        wait 7;
        level.stairs[stairs] = false;
    }
}

openDoor(whichdoor)
{    
    whichdoor rotateyaw(80, 1.5, 0.7, 0.7);
    whichdoor waittill("rotatedone");
    self iprintln("^5Door ^7opened");
    wait 3; 
    whichdoor rotateyaw(-80, 1.5, 0.7, 0.7);
    whichdoor waittill("rotatedone");
    wait 1;
}
openGarage(whichdoor)
{
    whichdoor moveZ(248, 4, 0.7, 0.7);
    whichdoor waittill("movedone");
    wait 3; 
    whichdoor moveZ(-248, 4, 0.7, 0.7);
    whichdoor waittill("movedone");
    wait 1;
}

add_door(trigger, brush)
{
    trigger = getent(trigger, "targetname");
    brush = getent(brush, "targetname");
    while (1)
    {
        trigger waittill("trigger", player);
        thread openDoor(brush);
    }
}
add_garage(trigger, brush)
{
    trigger = getent(trigger, "targetname");
    brush = getent(brush, "targetname");
    while (1)
    {
        trigger waittill("trigger", player);
        thread openGarage(brush);
    }
}
lift_secret()
{
    trig = getent("secret_door_1_trig", "targetname");
    brush = getent("secret_door_1", "targetname");

    for(;;)
    {
        trig waittill("trigger");
        if(!isdefined(level.sec_lift) || !level.sec_lift)
        {
            level.sec_lift = true;
            brush movez(250, 3, 1, 1);
            wait 13;
            brush movez(-250, 3, 1, 1);
            wait 3;
            level.sec_lift = false;
        }
    }
}
lift_lobby()
{
    trig = getent("lift_lobby_trig", "targetname");
    brush = getent("lift_lobby", "targetname");

    for(;;)
    {
        trig waittill("trigger", who);
        if(!isdefined(level.lift_up) || !level.lift_up)
        {
            level.lift_up = true;
            brush movez(465, 3, 1, 1);
            wait 13;
            brush movez(-465, 3, 1, 1);
            wait 3;
            level.lift_up = false;
        }
    }
}