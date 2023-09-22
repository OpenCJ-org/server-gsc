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

        if (!isSubStr(response, "qm_"))
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
        // No localized strings here, because it is also transmitted to Discord
        case "qm_yes":
        {
            soundAlias = "mp_rsp_yessir";
            sayText = "Roger.";
        } break;
        case "qm_no":
        {
            soundAlias = "mp_rsp_nosir";
            sayText = "Negative.";
        } break;
        case "qm_followme":
        {
            soundAlias = "mp_cmd_followme";
            sayText = "On me!";
        } break;
        case "qm_onmyway":
        {
            soundAlias = "mp_rsp_onmyway";
            sayText = "Moving.";
        } break;
        case "qm_sorry":
        {
            soundAlias = "mp_rsp_sorry";
            sayText = "Sorry.";
        } break;
        case "qm_stayhere":
        {
            soundAlias = "mp_cmd_holdposition";
            sayText = "Hold this position!";
        } break;
        case "qm_crazy":
        {
            prefix = "AB_";
            soundAlias = "mp_rsp_areyoucrazy";
            sayText = "Are you crazy?";
        } break;
        case "qm_comeon":
        default:
        {
            soundAlias = "mp_rsp_comeon";
            sayText = "Come on.";
        } break;
    }

    // Actually perform the quick message
    self playSound(prefix + soundAlias);
    // Inject into the chat message callback so that it works for mute, ignore, Discord and whatever else
    // This could also be done by calling SayAll and wrapping PlayerCmd_SayAll and redirecting it to..
    // ..SV_ExecuteClientCommand (which calls onChatMessage from CodeCallback_PlayerCommand), but y'know. Effort.
    args = [];
    args[0] = "say_team"; // Team say because otherwise it goes into cross-server chat
    args[args.size] = sayText;
    self openCJ\chat::onChatMessage(args);

    // Don't allow spam
    wait 2;
    self.quickMessageSpamDelay = undefined;
}