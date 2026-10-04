#include openCJ\util;

_configureMinimap()
{
    level.minimapMaxRange = 2500;
    if(!isDefined(getConfigStringByIndex(823))) // 823 is minimap config string number
    {
        setconfigstringbyindex(822, "90"); // Sets north yaw so we can calculate things with it

        minimapTileCount = 2.5; // TODO: dynamically per map
        minimapTileSize = level.minimapMaxRange / minimapTileCount / 2;
        northvector = (cos(getnorthyaw()), sin(getnorthyaw()), 0);
        eastvector = (northvector[1], 0 - northvector[0], 0);
        northwest = VectorScale(northvector, minimapTileSize) + VectorScale(eastvector, -1 * minimapTileSize) + level.spawnpoints_player[0].origin;
        southeast = VectorScale(northvector, -1 * minimapTileSize) + VectorScale(eastvector, minimapTileSize) + level.spawnpoints_player[0].origin;

        setMiniMap("opencj_minimapbg", northwest[0], northwest[1], southeast[0], southeast[1]);
    }
}

onInit()
{
    if(getCodVersion() == 4)
        precacheMenu("opencj_graphics");

    // If map doesn't have a custom minimap, then we set a default
    if(getCodVersion() == 4)
    {
        _configureMinimap();
    }

    underlyingCmd = openCJ\settings::addSettingInt("fov", 13, 160, 90, "Set your field-of-view. Usage: !fov [value between 13 and 160]", ::_onSettingFOV);
    underlyingCmd = openCJ\settings::addSettingBool("fullbright", false, "Enable/disable fullbright. Usage: !fullbright [on/off]", ::_onSettingFullbright);
    underlyingCmd = openCJ\settings::addSettingBool("hidecollidingplayers", false, "Hide colliding players. Usage: !hidecollidingplayers [on/off]");
    underlyingCmd = openCJ\settings::addSettingBool("viewbob", false, "Change view bobbing. Usage: !viewbob [on/off]", ::_onSettingViewBob);
    underlyingCmd = openCJ\settings::addSettingBool("fx", true, "fx_enable. Usage: !fx [on/off]", ::_onSettingFX);
    openCJ\settings::addSettingInt("gfx_specular", -1, 2, -1, "Graphics menu: specular", ::_gfx_specular);
    openCJ\settings::addSettingInt("gfx_shadows", -1, 2, -1, "Graphics menu: shadows", ::_gfx_shadows);
    openCJ\settings::addSettingInt("gfx_glow", -1, 1, -1, "Graphics menu: glow", ::_gfx_glow);
    openCJ\settings::addSettingInt("gfx_dof", -1, 1, -1, "Graphics menu: dof", ::_gfx_dof);
    openCJ\settings::addSettingInt("gfx_decals", -1, 1, -1, "Graphics menu: decals", ::_gfx_decals);
    openCJ\settings::addSettingInt("gfx_fog", -1, 1, -1, "Graphics menu: fog", ::_gfx_fog);
    openCJ\settings::addSettingInt("gfx_sun", -1, 1, -1, "Graphics menu: sun", ::_gfx_sun);
    openCJ\settings::addSettingInt("gfx_water", -1, 1, -1, "Graphics menu: water", ::_gfx_water);
    openCJ\settings::addSettingInt("gfx_normal", -1, 1, -1, "Graphics menu: normal", ::_gfx_normal);
    openCJ\settings::addSettingInt("gfx_detail", -1, 1, -1, "Graphics menu: detail", ::_gfx_detail);
    openCJ\settings::addSettingInt("gfx_blur", -1, 1, -1, "Graphics menu: blur", ::_gfx_blur);
    openCJ\settings::addSettingInt("gfx_entities", -1, 1, -1, "Graphics menu: entities", ::_gfx_entities);
    openCJ\settings::addSettingInt("gfx_distance", -1, 131072, -1, "Graphics menu: distance", ::_gfx_distance);
    openCJ\settings::addSettingInt("gfx_lod", -1, 2, -1, "Graphics menu: model detail", ::_gfx_lod);

}

onPlayerConnected()
{
    if(getCodVersion() == 4)
    {
        self setClientCvar("compassMaxRange", level.minimapMaxRange);
        self setClientCvar("opencj_gfx_fov", self openCJ\settings::getSetting("fov"));
        self setClientCvar("opencj_gfx_hideradius", self openCJ\settings::getSetting("hideradius"));
        self setClientCvar("opencj_gfx_specular", -1);
        self setClientCvar("opencj_gfx_shadows", -1);
        self setClientCvar("opencj_gfx_blur", 1);
        mode = 0;
        if(self openCJ\settings::getSetting("hideall")) mode = 2;
        else if(self openCJ\settings::getSetting("hidenear")) mode = 1;
        self setClientCvar("opencj_gfx_hidemode", mode);
        // Map defaults are captured by the acknowledged client startup menu.
        self thread _graphicsMenuResponses();
    }
}

_onSettingFOV(newVal)
{
    self setClientCvar("opencj_gfx_fov", newVal);
    if(newVal > 80)
    {
        self setClientCvar("cg_fovscale", (newVal / 80));
        self setClientCvar("cg_fov", 80);
    }
    else if(newVal < 65)
    {
        self setClientCvar("cg_fovscale", (newVal / 65));
        self setClientCvar("cg_fov", 65);
    }
    else
    {
        self setClientCvar("cg_fovscale", 1);
        self setClientCvar("cg_fov", newVal);
    }
}

_onSettingFullbright(newVal)
{
    if(newVal > 0)
    {
        newVal = 1;
    }
    self setClientCvar("r_fullbright", newVal);
}

_onSettingViewBob(newVal)
{
    if(newVal > 0)
    {
        newVal = 8;
    }
    self setClientCvar("bg_bobmax", newVal);
}

_onSettingFX(newVal)
{
    if(newVal > 0)
    {
        newVal = 1;
    }
    self setClientCvar("fx_enable", newVal);
}


// Changes remain pending until Apply. Reopening/Cancel drops the pending selection.
_graphicsMenuResponses()
{
    self endon("disconnect");
    pending = [];
    for(;;)
    {
        self waittill("menuresponse", menu, response);
        if(toLower(menu) != "opencj_graphics")
            continue;
        if(response == "begin" || response == "cancel")
        {
            pending = [];
            continue;
        }
        if(response == "apply")
        {
            if(!self openCJ\settings::areSettingsLoaded())
            {
                pending = [];
                continue;
            }
            keys = getArrayKeys(pending);
            for(i = 0; i < keys.size; i++)
                if(isDefined(pending[keys[i]]))
                    self openCJ\settings::setSettingByScript(keys[i], pending[keys[i]]);
            pending = [];
            continue;
        }
        parts = strTok(response, ":");
        if(parts.size != 2 || !isValidInt(parts[1]))
            continue;
        key = parts[0];
        if(key == "gfx_hidemode")
        {
            mode = int(parts[1]);
            if(mode >= 0 && mode <= 2)
            {
                pending["hideall"] = (mode == 2);
                pending["hidenear"] = (mode == 1);
            }
            continue;
        }
        if(key != "fullbright" && key != "fx" && key != "viewbob" && key != "fov" && key != "hideradius" &&
           key != "gfx_specular" && key != "gfx_shadows" && key != "gfx_glow" &&
           key != "gfx_dof" && key != "gfx_decals" && key != "gfx_fog" &&
           key != "gfx_sun" && key != "gfx_water" && key != "gfx_lod" &&
           key != "gfx_normal" && key != "gfx_detail" && key != "gfx_blur" &&
           key != "gfx_entities" && key != "gfx_distance")
            continue;
        // Zero remains readable for old saved settings, but is not a menu choice.
        if(key == "hideradius" && int(parts[1]) < 1)
            continue;
        if(key == "gfx_lod" && parts[1] == "3")
        {
            pending[key] = undefined;
            continue;
        }
        value = openCJ\settings::parseSettingValue(level.settings[key], parts[1]);
        if(isDefined(value))
            pending[key] = value;
    }
}

_gfx_specular(value)
{
    if(value < 0) return; // No override until the player chooses one.
    self setClientCvar("opencj_gfx_specular", value);
    self setClientCvar("r_specular", value != 0);
    if(value == 2)
        self setClientCvar("r_specularMap", "White");
    else
        self setClientCvar("r_specularMap", "Unchanged");
}

_gfx_shadows(value)
{
    if(value < 0) return; // No override until the player chooses one.
    self setClientCvar("opencj_gfx_shadows", value);
    self setClientCvar("sm_enable", value != 0);
    if(value == 2)
    {
        self setClientCvar("sm_sunEnable", 1);
        self setClientCvar("sm_spotEnable", 1);
    }
    else
        self execClientCmd("setfromdvar sm_sunEnable opencj_gfx_map_sunShadow; setfromdvar sm_spotEnable opencj_gfx_map_spotShadow");
}

_gfx_glow(value)
{
    if(value < 0) return; // No override until the player chooses one.
    self setClientCvar("r_glow_allowed", value);
}

_gfx_dof(value)
{
    if(value < 0) return; // No override until the player chooses one.
    self setClientCvar("r_dof_enable", value);
}

_gfx_decals(value)
{
    if(value < 0) return; // No override until the player chooses one.
    self setClientCvar("r_drawDecals", value);
    self setClientCvar("fx_marks", value);
}

_gfx_fog(value)
{
    if(value < 0) return; // No override until the player chooses one.
    self setClientCvar("r_fog", value);
}

_gfx_sun(value)
{
    if(value < 0) return; // No override until the player chooses one.
    self setClientCvar("r_drawSun", value);
}

_gfx_water(value)
{
    if(value < 0) return; // No override until the player chooses one.
    self setClientCvar("r_drawWater", value);
}

_gfx_lod(value)
{
    if(value < 0) return;
    rigidScale = 1;
    skinnedScale = 1;
    rigidBias = 0;
    skinnedBias = 0;
    if(value == 1)
    {
        rigidScale = 1.5;
        skinnedScale = 2;
    }
    else if(value == 2)
    {
        rigidScale = 2;
        skinnedScale = 4;
        rigidBias = -100;
        skinnedBias = -200;
    }
    self setClientCvar("r_lodScaleRigid", rigidScale);
    self setClientCvar("r_lodScaleSkinned", skinnedScale);
    self setClientCvar("r_lodBiasRigid", rigidBias);
    self setClientCvar("r_lodBiasSkinned", skinnedBias);
}

_gfx_normal(value)
{
    if(value < 0) return;
    self setClientCvar("r_normal", value);
}

_gfx_detail(value)
{
    if(value < 0) return;
    self setClientCvar("r_detail", value);
}

_gfx_entities(value)
{
    if(value < 0) return;
    self setClientCvar("dynEnt_active", value);
}

_gfx_distance(value)
{
    if(value < 0) return;
    self setClientCvar("r_zfar", value);
}

_gfx_blur(value)
{
    if(value < 0) return;
    self setClientCvar("opencj_gfx_blur", value);
    if(value == 0)
        self setClientCvar("r_blur", 0);
    else
        self execClientCmd("setfromdvar r_blur opencj_gfx_map_blur");
}
