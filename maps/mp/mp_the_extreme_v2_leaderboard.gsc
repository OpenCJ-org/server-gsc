
/*

script by Sheep Wizard
taken from mp_race by Noob
Thanks for permission to use it!
*/

init()
{
    thread easyStart();
    thread easyEnd();
    thread interStart();
    thread interEnd();
    thread interplusStart();
    thread interplusEnd();
    thread hardStart();
    thread hardEnd();
    thread elevateStart();
    thread elevateEnd();
}   

checkpointreset()
{
    self.easychk1 = undefined;
    self.easychk2 = undefined;
    self.easychk3 = undefined;
    self.interchk1 = undefined;
    self.interchk2 = undefined;
    self.interchk3 = undefined;
    self.interpluschk1 = undefined;
    self.interpluschk2 = undefined;
    self.interpluschk3 = undefined;
    self.hardchk1 = undefined;
    self.hardchk2 = undefined;
    self.hardchk3 = undefined;
    self.elevatechk1 = undefined;
    self.elevatechk2 = undefined;
    self.elevatechk3 = undefined;
 
    self.easyEnd = undefined;
    self.startTimeEasy = undefined;
    self.interEnd = undefined;
    self.startTimeInter = undefined;
    self.interplusEnd = undefined;
    self.startTimeInterplus = undefined;
    self.hardEnd = undefined;
    self.startTimeHard = undefined;
    self.elevateEnd = undefined;
    self.startTimeelevate = undefined;
}  
//EASY TIMER
easyStart()
{
    level endon("game_ended");
   
    trigger = getent("easybegin", "targetname");
 
    while(1)
    {
        trigger waittill("trigger", player);
       
        if(player.sessionstate == "playing")
        {
            player checkpointreset();
            player.startTimeEasy = getTime();
            player.easyend = undefined;
            player thread easychk();
        }                      
    }
}
easyEnd()
{
    level endon("game_ended");
   
    trigger = getent("easyend", "targetname");
    while(1)
    {
        trigger waittill("trigger", player);
       
        if(player.sessionstate != "playing" || isDefined(player.easyend) || !isDefined(player.startTimeEasy))
            continue;
   
        else
        {
            if(isDefined(player.easychk1) && isDefined(player.easychk2) && isDefined(player.easychk3))
            {
                number = getTime() - player.startTimeEasy;
                iPrintLn(player.name + " ^5finished Easy in ^3" + realtime(number));
                player.easyEnd = true;
                player.startTimeEasy = undefined;
                player notify("easy_stop");
                player thread checkpointreset();
            }    
        }
       
    }
}
easychk()
{
    self notify("easy_stop");
    self endon("easy_stop");
    self endon("disconnect");
    trig1 = getEnt("easy_chk_1", "targetname");
    trig2 = getEnt("easy_chk_2", "targetname");
    trig3 = getEnt("easy_chk_3", "targetname");
 
    while(1)
    {
        if(!isDefined(self.easychk1) && self isTouching(trig1))
            self.easychk1 = true;
        if(!isDefined(self.easychk2) && self isTouching(trig2))
           self.easychk2 = true;
        if(!isDefined(self.easychk3) && self isTouching(trig3))
            self.easychk3 = true;
        wait 0.05;
    }
 
}
//INTER TIMER
interStart()
{
    level endon("game_ended");
   
    trigger = getent("interbegin", "targetname");
 
    while(1)
    {
        trigger waittill("trigger", player);
       
        if(player.sessionstate == "playing")
        {
            player checkpointreset();
            player.startTimeInter = getTime();
            player.interend = undefined;
            player thread interchk();
        }
                           
    }
}
interEnd()
{
    level endon("game_ended");
   
    trigger = getent("interend", "targetname");
    while(1)
    {
        trigger waittill("trigger", player);
       
        if(player.sessionstate != "playing" || isDefined(player.interend) || !isDefined(player.startTimeInter))
            continue;
   
        else
        {
            if(isDefined(player.interchk1) && isDefined(player.interchk2) && isDefined(player.interchk3))
            {
                number = getTime() - player.startTimeInter;
                iPrintLn(player.name + " ^5finished Inter in ^3" + realtime(number));
                player.interEnd = true;
                player.startTimeInter = undefined;
                player notify("inter_stop");
                player thread checkpointreset();
            }    
        }
       
    }
}
interchk()
{
    self notify("inter_stop");
    self endon("inter_stop");
    self endon("disconnect");
    trig1 = getEnt("inter_chk_1", "targetname");
    trig2 = getEnt("inter_chk_2", "targetname");
    trig3 = getEnt("inter_chk_3", "targetname");
 
    while(1)
    {
        if(!isDefined(self.interchk1) && self isTouching(trig1))
            self.interchk1 = true;
        if(!isDefined(self.interchk2) && self isTouching(trig2))
           self.interchk2 = true;
        if(!isDefined(self.interchk3) && self isTouching(trig3))
            self.interchk3 = true;
        wait 0.05;
    }
}
//INTERPLUS TIMER
interplusStart()
{
    level endon("game_ended");
   
    trigger = getent("interplusbegin", "targetname");
 
    while(1)
    {
        trigger waittill("trigger", player);
       
        if(player.sessionstate == "playing")
        {
            player checkpointreset();
            player.startTimeInterplus = getTime();
            player.interplusend = undefined;
            player thread interpluschk();
        }
                               
    }
}
interplusEnd()
{
    level endon("game_ended");
   
    trigger = getent("interplusend", "targetname");
    while(1)
    {
        trigger waittill("trigger", player);
       
        if(player.sessionstate != "playing" || isDefined(player.interplusend) || !isDefined(player.startTimeInterplus))
            continue;
   
        else
        {
            if(isDefined(player.interpluschk1) && isDefined(player.interpluschk2) && isDefined(player.interpluschk3))
            {
                number = getTime() - player.startTimeInterplus;
                iPrintLn(player.name + " ^5finished Inter+ in ^3" + realtime(number));
                player.interplusEnd = true;
                player.startTimeInterplus = undefined;
                player notify("interplus_stop");
                player thread checkpointreset();
            }    
        }
       
    }
}
interpluschk()
{
    self notify("interplus_stop");
    self endon("interplus_stop");
    self endon("disconnect");
    trig1 = getEnt("interplus_chk_1", "targetname");
    trig2 = getEnt("interplus_chk_2", "targetname");
    trig3 = getEnt("interplus_chk_3", "targetname");
 
    while(1)
    {
        if(!isDefined(self.interpluschk1) && self isTouching(trig1))
            self.interpluschk1 = true;
        if(!isDefined(self.interpluschk2) && self isTouching(trig2))
           self.interpluschk2 = true;
        if(!isDefined(self.interpluschk3) && self isTouching(trig3))
            self.interpluschk3 = true;
        wait 0.05;
    }
}
//HARD TIMER
hardStart()
{
    level endon("game_ended");
   
    trigger = getent("hardbegin", "targetname");
 
    while(1)
    {
        trigger waittill("trigger", player);
       
        if(player.sessionstate == "playing")
        {
            player checkpointreset();
            player.startTimeHard = getTime();
            player.hardend = undefined;
            player thread hardchk();
        }
                       
    }
}
hardEnd()
{
    level endon("game_ended");
   
    trigger = getent("hardend", "targetname");
    while(1)
    {
        trigger waittill("trigger", player);
       
        if(player.sessionstate != "playing" || isDefined(player.hardend) || !isDefined(player.startTimehard))
            continue;
   
        else
        {
            if(isDefined(player.hardchk1) && isDefined(player.hardchk2) && isDefined(player.hardchk3))
            {
                number = getTime() - player.startTimeHard;
                iPrintLn(player.name + " ^5finished Hard in ^3" + realtime(number));
                player.hardEnd = true;
                player.startTimeHard = undefined;
                player notify("hard_stop");
                player thread checkpointreset();
            }    
        }
       
    }
}
hardchk()
{
    self notify("hard_stop");
    self endon("hard_stop");
    self endon("disconnect");
    trig1 = getEnt("hard_chk_1", "targetname");
    trig2 = getEnt("hard_chk_2", "targetname");
    trig3 = getEnt("hard_chk_3", "targetname");
 
    while(1)
    {
        if(!isDefined(self.hardchk1) && self isTouching(trig1))
            self.hardchk1 = true;
        if(!isDefined(self.hardchk2) && self isTouching(trig2))
           self.hardchk2 = true;
        if(!isDefined(self.hardchk3) && self isTouching(trig3))
            self.hardchk3 = true;
        wait 0.05;
    }
}
//elevate TIMER
elevateStart()
{
    level endon("game_ended");
   
    trigger = getent("elevatebegin", "targetname");
 
    while(1)
    {
        trigger waittill("trigger", player);
       
        if(player.sessionstate == "playing")
        {
            player checkpointreset();
            player.startTimeelevate = getTime();
            player.elevateend = undefined;
            player thread elevatechk();
        }
                       
    }
}
elevateEnd()
{
    level endon("game_ended");
   
    trigger = getent("elevateend", "targetname");
    while(1)
    {
        trigger waittill("trigger", player);
        if(player.sessionstate != "playing" || isDefined(player.elevateend) || !isDefined(player.startTimeelevate))
            continue;
        else
        {
            if(isDefined(player.elevatechk1) && isDefined(player.elevatechk2) && isDefined(player.elevatechk3))
            {
                number = getTime() - player.startTimeelevate;
                iPrintLn(player.name + " ^5finished elevate in ^3" + realtime(number));
                player.elevateEnd = true;
                player.startTimeelevate = undefined;
                player notify("elevate_stop");
                player thread checkpointreset();
            }    
        }
       
    }
}
elevatechk()
{
    self notify("elevate_stop");
    self endon("elevate_stop");
    self endon("disconnect");
    trig1 = getEnt("elevate_chk_1", "targetname");
    trig2 = getEnt("elevate_chk_2", "targetname");
    trig3 = getEnt("elevate_chk_3", "targetname");
 
    while(1)
    {
        if(!isDefined(self.elevatechk1) && self isTouching(trig1))
            self.elevatechk1 = true;
        if(!isDefined(self.elevatechk2) && self isTouching(trig2))
           self.elevatechk2 = true;
        if(!isDefined(self.elevatechk3) && self isTouching(trig3))
            self.elevatechk3 = true;
        wait 0.05;
    }
}

//convert time to readable time
realtime(number)
{
    if(number == 999999999)
    {
        playertime = "???";
        return playertime;
    }
 
    seconds = int(number / 1000);
    hours = int(seconds/3600);
    seconds = seconds % 3600;
    minutes = int(seconds/60);
    seconds = seconds % 60;
 
    if(seconds <= 9)
        seconds = "0" + seconds;
    if(minutes <= 9)
        minutes = "0" + minutes;
    if(hours <= 9)
        hours = "0" + hours;
 
     playertime =  "" + hours + ":" + minutes + ":" + seconds;
 
    return playertime;
}