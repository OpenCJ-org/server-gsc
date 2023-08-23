//script by VC' Blade
//vistic-clan.net
init()
{

}
 
track1()
{
    trig=getent("title1","targetname");
    for(;;)
    {
        trig waittill("trigger",who);
        if(!isdefined(who.extremeMusic) || !who.extremeMusic)
            who musicSelected(true,"title1",false);
    }
}
 
track2()
{
    trig=getent("title2","targetname");
    for(;;)
    {
        trig waittill("trigger",who);
        if(!isdefined(who.extremeMusic) || !who.extremeMusic)
            who musicSelected(true,"title2",false);
    }
}
 
track3()
{
    trig=getent("title3","targetname");
    for(;;)
    {
        trig waittill("trigger",who);
        if(!isdefined(who.extremeMusic) || !who.extremeMusic)
            who musicSelected(true,"title3",false);
    }
}
 
track4()
{
    trig=getent("title4","targetname");
    for(;;)
    {
        trig waittill("trigger",who);
        if(!isdefined(who.extremeMusic) || !who.extremeMusic)
            who musicSelected(true,"title4",false);
    }
}

trackOff()
{
    trig=getent("musicstop","targetname");
    for(;;)
    {
        trig waittill("trigger",who);
        if(isdefined(who.extremeMusic) && who.extremeMusic==true)
        {
            who iprintln("^1Stopped ^7music");
            who.extremeMusic=false;

            if(isdefined(who.extremeMusicRdm))
                who.extremeMusicRdm=false;

            for(i=1;i<5;i++)
            {
                who stoplocalsound("title"+i);
                wait .05;
            }
        }
    }
}
 
playanddefine(what)
{
    self iprintln("Currently playing: ^1"+getsongname(what));
    self playlocalsound(what);
}
 
getsongname(song)
{
    switch(song)
    {
        case "title1":  song="Dance With The Dead - Invader";                   break;
        case "title2":  song="Jebroer - Kind van de Duivel";     break;
        case "title3":  song="Play N Skillz - Literally I can't ft. Redfoo, Lil Jon, Enertia McFly";        break;
        case "title4":  song="Skillet - Feel Invincible";               break;
    }
    return song;
}
 
getsonglenght(song)
{
    switch(song)
    {
        case "title1":  song=281;   break;
        case "title2":  song=203;   break;
        case "title3":  song=244;   break;
        case "title4":  song=228;   break;
    }
    return song;
}
 
musicSelected(state1,alias,state2)
{
    ambientstop();
    musicstop();
 
    self.extremeMusic=state1;
    self playlocalsound(alias);
    self iprintln("Currently playing: ^1"+getsongname(alias));
    wait getsonglenght(alias);
    self.extremeMusic=state2;
}
