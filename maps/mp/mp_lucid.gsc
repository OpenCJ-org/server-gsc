main()
{
	maps\mp\_load::main();
	//maps\mp\_teleport::main();

	game["allies"] = "marines";
	game["axis"] = "opfor";
	game["attackers"] = "allies";
	game["defenders"] = "axis";
	game["allies_soldiertype"] = "desert";
	game["axis_soldiertype"] = "desert";
	
	setdvar( "r_specularcolorscale", "8" );


	thread txt1();
	thread txt2();
	thread txt3();
	thread txt4();
	thread txt5();
	thread easycong();
	thread intercong();
	thread funcong();
	thread hardcong();
	thread teleport();
}

//******************************************************************************
// txt1
//******************************************************************************

txt1()
{
	trigger = getent ("txt1","targetname");
	for(;;)
	{
		trigger waittill ("trigger",user);
			user iPrintLnBold("^0Thx to ^6Funk, ^5Noob, ^1AlterEgo, and ^4Boat ^0for Radiant help!");
			wait 5;
	}
}

//******************************************************************************
// txt2
//******************************************************************************

txt2()
{
	trigger = getent ("txt2","targetname");
	for(;;)
	{
		trigger waittill ("trigger",user);
			user iPrintLnBold("^0Thx to ^6Funk, ^5Noob, and ^4Boat ^0for mapping help!");
			wait 5;
	}
}


//******************************************************************************
// txt3
//******************************************************************************

txt3()
{
	trigger = getent ("txt3","targetname");
	for(;;)
	{
		trigger waittill ("trigger",user);
			user iPrintLnBold("^0Thx to all who tested");
			wait 5;
	}
}

//******************************************************************************
// txt4
//******************************************************************************

txt4()
{
	trigger = getent ("txt4","targetname");
	for(;;)
	{
		trigger waittill ("trigger",user);
			user iPrintLnBold("^3Unique Funk Noob AlterEgo Tuatara Treaxer Viruz GBR_ Megan FraMe Pawnz Drizzjeh NoobAim Alex_Yar Fee4ka");
			wait 5;
	}
}

//******************************************************************************
// txt5
//******************************************************************************

txt5()
{
	trigger = getent ("txt5","targetname");
	for(;;)
	{
		trigger waittill ("trigger",user);
			user iPrintLnBold("^0Map By ^7Enter1337");
			wait 5;
	}
}




//******************************************************************************
// teleport
//******************************************************************************
teleport()
{
	entTransporter = getentarray( "enter", "targetname" );
	if(isdefined(entTransporter))
		for( i = 0; i < entTransporter.size; i++ )
			entTransporter[i] thread transporter();
}

transporter()
{
	for(;;)
	{
		self waittill( "trigger", player );
		entTarget = getEnt( self.target, "targetname" );
		wait 0.1;
        if (isDefined(player))
        {
            player setOrigin( entTarget.origin );
            player setplayerangles( entTarget.angles );
        }
		wait 0.1;
	}
}


//******************************************************************************
// hardcong	
//******************************************************************************


		hardcong() {
	t = getent("hardcong","targetname");
	while(1) {
		t waittill ("trigger", p);
      	if (!isdefined(p.finished_hard)) {
          	iprintln ("^5" + p.name + " ^7finished ^1Hard!");   
         	p.finished_hard = true; 
      	}
	}
}


//******************************************************************************
// intercong
//******************************************************************************

		intercong() {
	t = getent("intercong","targetname");
	while(1) {
		t waittill ("trigger", p);
      	if (!isdefined(p.finished_inter)) {
          	iprintln ("^5" + p.name + " ^7finished ^4Inter!");   
         	p.finished_inter = true; 
      	}
	}
}

//******************************************************************************
// funcong
//******************************************************************************


		funcong() {
	t = getent("funcong","targetname");
	while(1) {
		t waittill ("trigger", p);
      	if (!isdefined(p.finished_fun)) {
          	iprintln ("^5" + p.name + " ^7finished ^6Fun!");   
         	p.finished_fun = true; 
      	}
	}
}



//******************************************************************************
// easycong	
//******************************************************************************


		easycong() {
	t = getent("easycong","targetname");
	while(1) {
		t waittill ("trigger", p);
      	if (!isdefined(p.finished_easy)) {
          	iprintln ("^5" + p.name + " ^7finished ^2Easy!");   
         	p.finished_easy = true; 
      	}
	}
}