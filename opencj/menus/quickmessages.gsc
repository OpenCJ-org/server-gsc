onInit()
{
    precacheString(&"QUICKMESSAGE_YES_SIR");
    precacheString(&"QUICKMESSAGE_NO_SIR");
    precacheString(&"QUICKMESSAGE_FOLLOW_ME");
    precacheString(&"QUICKMESSAGE_IM_ON_MY_WAY");
    precacheString(&"QUICKMESSAGE_SORRY");
    precacheString(&"QUICKMESSAGE_HOLD_THIS_POSITION");
    precacheString(&"QUICKMESSAGE_ARE_YOU_CRAZY");	
    precacheString(&"QUICKMESSAGE_COME_ON");	
}

onPlayerConnected()
{
    self thread _menuResponse();
}

_menuResponse()
{
    self endon("disconnect");

    for(;;)
    {
        self waittill("menuresponse", menu, response);
    	if (!isDefined(self.pers["team"]) || (self.sessionState == "spectator") || isDefined(self.quickMessageSpamDelay))
        {
            continue;
        }

        self thread _handleQuickMessage(response);
    }
}

_handleQuickMessage(response)
{
    self.quickMessageSpamDelay = true;

    sayText = undefined;
    soundAlias = undefined;
    prefix = "US_";

    switch(response)
    {
        case "qm_yes":
        {
            soundAlias = "mp_rsp_yessir";
            sayText = &"QUICKMESSAGE_YES_SIR";
        } break;
        case "qm_no":
        {
            soundAlias = "mp_rsp_nosir";
            sayText = &"QUICKMESSAGE_NO_SIR";
        } break;
        case "qm_followme":
        {
            soundAlias = "mp_cmd_followme";
            sayText = &"QUICKMESSAGE_FOLLOW_ME";
        } break;
        case "qm_onmyway":
        {
            soundAlias = "mp_rsp_onmyway";
            sayText = &"QUICKMESSAGE_IM_ON_MY_WAY";
        } break;
        case "qm_sorry":
        {
            soundAlias = "mp_rsp_sorry";
            sayText = &"QUICKMESSAGE_SORRY";
        } break;
        case "qm_stayhere":
        {
            soundAlias = "mp_cmd_holdposition";
            sayText = &"QUICKMESSAGE_HOLD_THIS_POSITION";
        } break;
        case "qm_crazy":
        {
            prefix = "AB_";
            soundAlias = "mp_rsp_areyoucrazy";
            sayText = &"QUICKMESSAGE_ARE_YOU_CRAZY";
        } break;
        case "qm_comeon":
        {
            soundAlias = "mp_rsp_comeon";
            sayText = &"QUICKMESSAGE_COME_ON";
        } break;
        default:
        {
            continue; // Nothing to do (could be response of another menu)
        }
    }

    // Actually perform the quick message
    self playSound(prefix + soundAlias);
    self sayAll(sayText);

    // Don't allow spam
    wait 2;
    self.quickMessageSpamDelay = undefined;
}