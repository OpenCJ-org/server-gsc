onInit()
{
    level.motd_title = "Beta";
    level.motd_content = "OpenCJ is a work-in-progress open-source CoDJumper mod for CoD4." +
                         " Anyone can contribute via Pull Requests on GitHub (opencj-org). " +
                         "The Beta helps us find crashes and game-breaking bugs. " +
                         "Our website is opencj.org. " +
                         "Join our Discord at discord.opencj.org for updates.";
    level.motd_date = "September 28th, 2026";
}

onPlayerConnected()
{
    prefix = "opencj_ui_ig_motd_";
    self setClientCvar(prefix + "title", level.motd_title);
    self setClientCvar(prefix + "content", level.motd_content);
    self setClientCvar(prefix + "date", level.motd_date);
}
