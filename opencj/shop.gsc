#include openCJ\util;

// Preview catalogue. Stable keys will also identify ownership when sales launch.
onInit()
{
    if(getCodVersion()!=4)return;
    precacheMenu("opencj_shop");
    precacheMenu("opencj_shop_confirm");
    precacheMenu("opencj_shop_inspect");
    level.shopItems=[];
    for(i=0;i<12;i++)
    {
        add("pistol.preview"+i,1,"Desert Eagle "+(i+1),"weapon_desert_eagle", "deserteagle_mp", "default");
        add("rpg.preview"+i,2,"RPG "+(i+1),"weapon_rpg7", "rpg_mp", "default");
    }
    openCJ\commands_base::registerCommand("shop","!shop",::command,0,0,0);
}
add(key,category,name,image,slot,resource)
{
    item=spawnStruct();item.key=key;item.category=category;item.name=name;
    item.image=image;item.price=9999;item.available=false;item.resource=resource;item.slot=slot;
    openCJ\mySQL::mysqlSyncQuery("INSERT INTO shopCatalog(itemKey,category,slot,price,available) VALUES ('"+key+"',"+category+",'"+slot+"',"+item.price+","+int(item.available)+") ON DUPLICATE KEY UPDATE category=VALUES(category),slot=VALUES(slot),price=VALUES(price),available=VALUES(available)");
    level.shopItems[level.shopItems.size]=item;
}
onPlayerConnected()
{
    if(getCodVersion()!=4)return;
    self.shopTab=1;
    self.shopLoaded=false;
    self thread responses();
}
command(args){self openMenu("opencj_shop");}
availablePoints(total,spent)
{
    remaining=total-spent;
    if(remaining<0)return 0;
    return remaining;
}
responses()
{
    self endon("disconnect");
    for(;;)
    {
        self waittill("menuresponse",menu,response);
        if(menu!="opencj_shop" && menu!="opencj_shop_confirm" && menu!="opencj_shop_inspect")continue;
        if(response=="close")
        {
            self closeInGameMenu();self closeMenu();
            self.shopOpen=false;
            self stopInspect();
            self notify("shop_refresh");
            self.shopSelection=undefined;
            continue;
        }
        if(response=="inspect_done"){self stopInspect();continue;}
        if(isDefined(self.shopRequestAt) && getTime()-self.shopRequestAt<200)continue;
        self.shopRequestAt=getTime();
        if(response=="open"){self.shopOpen=true;self stopInspect();self.shopSelection=undefined;self thread show();}
        else if(response=="0" || response=="1" || response=="2")
        {self.shopTab=int(response);self.shopSelection=undefined;self thread show();}
        else if(response=="confirm" || response=="equip")self thread purchase(response=="equip");
        else if(response=="inspect")self inspect();
        else if(getSubStr(response,0,5)=="item:")
        {
            index=getSubStr(response,5);
            if(!isValidInt(index))continue;
            index=int(index);
            if(!isDefined(self.shopRows) || index<0 || index>=self.shopRows.size)continue;
            item=self.shopRows[index];
            self.shopSelection=item.key;
            self setClientCvar("ocj_shop_detail_error", "");
            self setClientCvar("ocj_shop_confirm_name",item.name);
            self setClientCvar("ocj_shop_confirm_owned",int(isDefined(self.shopOwned[item.key])));
            self setClientCvar("ocj_shop_confirm_equipped",int(isDefined(self.shopEquipped) && isDefined(self.shopEquipped[item.slot]) && self.shopEquipped[item.slot]==item.key));
            self setClientCvar("ocj_shop_confirm_buy",int(item.available && !isDefined(self.shopOwned[item.key])));
            self setClientCvar("ocj_shop_confirm_cost",item.price+" points");
            self closeInGameMenu();
            self closeMenu();
            self openMenu("opencj_shop_confirm");
        }
    }
}
show()
{
    self endon("disconnect");
    self notify("shop_refresh");self endon("shop_refresh");
    self setClientCvar("ocj_shop_busy",1);
    self setClientCvar("ocj_shop_error","");
    if(!level.challengesReady || !self openCJ\login::isLoggedIn())
    {self setClientCvar("ocj_shop_error","Your account is loading. Reopen the shop in a moment.");return;}
    id=self openCJ\login::getPlayerID();
    totals=self openCJ\mySQL::mysqlAsyncQuery("SELECT (SELECT COALESCE(SUM(c.points),0) FROM challengeCompletions a JOIN challenges c ON c.challengeKey=a.challengeKey AND c.active=1 WHERE a.playerID="+id+"),(SELECT COALESCE(SUM(pointsSpent),0) FROM shopPurchases WHERE playerID="+id+")");
    owned=self openCJ\mySQL::mysqlAsyncQuery("SELECT itemKey FROM shopPurchases WHERE playerID="+id);
    if(!isDefined(totals) || !totals.size || !isDefined(owned))
    {self setClientCvar("ocj_shop_error","Shop data is unavailable. Please try again later.");return;}
    total=int(totals[0][0]);spent=int(totals[0][1]);
    self.shopOwned=[];
    for(i=0;i<owned.size;i++)self.shopOwned[owned[i][0]]=true;
    self.shopRows=[];values=[];
    values["ocj_shop_tab"]=self.shopTab;
    values["ocj_shop_balance"]=availablePoints(total,spent)+" points available";
    values["ocj_shop_totals"]="Total earned: "+total+"  |  Spent: "+spent;
    for(i=0;i<level.shopItems.size;i++)
    {
        item=level.shopItems[i];if(item.category!=self.shopTab)continue;
        row=self.shopRows.size;self.shopRows[row]=item;prefix="ocj_shop_"+row+"_";
        purchased=isDefined(self.shopOwned[item.key]);state="Currently unavailable";
        if(purchased)state="Purchased";
        if(isDefined(self.shopEquipped) && isDefined(self.shopEquipped[item.slot]) && self.shopEquipped[item.slot]==item.key)state="Purchased / Equipped";
        values[prefix+"name"]=item.name;
        values[prefix+"price"]=item.price+" points";
        values[prefix+"image"]=item.image;
        values[prefix+"state"]=state;
        values[prefix+"owned"]=int(purchased);
        values[prefix+"buy"]=int(item.available && !purchased);
    }
    values["ocj_shop_rows"]=self.shopRows.size;
    self openCJ\scoreboard::sendChanged(values);
    self setClientCvar("ocj_shop_busy",0);
}

// Load before the spawn is created; never flash a default model while awaiting SQL.
loadEquipment()
{
    if(getCodVersion()!=4)return true;
    if(isDefined(self.shopLoaded) && self.shopLoaded)return true;
    rows=self openCJ\mySQL::mysqlAsyncQuery("SELECT 'ready','ready' UNION ALL SELECT e.slot,e.itemKey FROM shopEquipped e JOIN shopPurchases p ON p.playerID=e.playerID AND p.itemKey=e.itemKey WHERE e.playerID="+self openCJ\login::getPlayerID());
    if(!isDefined(rows) || !rows.size || rows[0][0]!="ready")return false;
    self.shopEquipped=[];
    for(i=1;i<rows.size;i++)self.shopEquipped[rows[i][0]]=rows[i][1];
    self.shopLoaded=true;
    return true;
}
findItem(key)
{
    for(i=0;i<level.shopItems.size;i++)if(level.shopItems[i].key==key)return level.shopItems[i];
    return undefined;
}
resource(slot)
{
    if(getCodVersion()!=4 || !isDefined(self.shopEquipped))return "default";
    key=self.shopEquipped[slot];
    if(!isDefined(key))return "default";
    item=findItem(key);
    if(!isDefined(item) || item.slot!=slot)return "default";
    return item.resource;
}
purchase(equipOnly)
{
    self endon("disconnect");
    if(isDefined(self.shopInspect) || (isDefined(self.shopPurchaseBusy) && self.shopPurchaseBusy))return;
    if(!self openCJ\login::isLoggedIn() || !isDefined(self.shopSelection))return;
    item=findItem(self.shopSelection);
    if(!isDefined(item) || (!equipOnly && !item.available))
    {self sendLocalChatMessage("This item is currently unavailable.");return;}
    self.shopPurchaseBusy=true;
    // Only a server-owned catalogue key and authenticated account ID reach SQL.
    rows=self openCJ\mySQL::mysqlAsyncQuery("CALL shopBuyOrEquip("+self openCJ\login::getPlayerID()+",'"+openCJ\mySQL::escapeString(item.key)+"',"+int(equipOnly)+","+item.price+")");
    if(isDefined(rows) && rows.size && rows[0][0]=="ok")
    {
        self.shopLoaded=false;
        self loadEquipment();
        self sendLocalChatMessage("Equipped "+item.name+". Your selection applies on your next spawn.");
    }
    else
    {
        message="Purchase could not be confirmed. Reopen the shop to check ownership and balance.";
        if(isDefined(rows) && rows.size && rows[0][0]=="balance")message="You do not have enough available points.";
        if(isDefined(rows) && rows.size && rows[0][0]=="price_changed")message="The price has changed. Reopen the shop before purchasing.";
        if(isDefined(rows) && rows.size && rows[0][0]=="owned")message="You already own this item.";
        self sendLocalChatMessage(message);
    }
    self.shopPurchaseBusy=false;
    self.shopRequestAt=undefined;
    if(isDefined(self.shopOpen) && self.shopOpen)
    {self closeInGameMenu();self closeMenu();self openMenu("opencj_shop");}
}
inspect()
{
    if(isDefined(self.shopInspect) || !isDefined(self.shopSelection) || (isDefined(self.shopPurchaseBusy) && self.shopPurchaseBusy))return;
    if(self.sessionState!="playing" || !self isOnGround() || isDefined(self.cpc) || self openCJ\demos::isPlayingDemo())
    {self setClientCvar("ocj_shop_detail_error", "Stand on a platform outside CPC/demo mode to inspect.");return;}
    item=findItem(self.shopSelection);
    if(!isDefined(item))return;
    weapon=undefined;
    if(item.category==1)weapon=level.weapons_loadouts[item.resource];
    if(item.category==2)weapon=level.weapons_rpgs[item.resource];
    if(item.category!=0 && !isDefined(weapon))return;
    state=spawnStruct();state.weapons=[];state.current=self getCurrentWeapon();
    list=self getWeaponsList();
    for(i=0;i<list.size;i++)
    {
        w=spawnStruct();w.name=list[i];w.clip=self getWeaponAmmoClip(list[i]);w.stock=self getWeaponAmmoStock(list[i]);
        state.weapons[state.weapons.size]=w;
    }
    self notify("shop_inspect_started");
    self.shopInspect=state;
    self freezeControls(true);
    self setVelocity((0,0,0));
    // Frozen controls block input; disableWeapons also hides the viewmodel.
    self enableWeapons();
    if(item.category==0)self openCJ\playerModels::_setModel(item.resource);
    else
    {
        self takeAllWeapons();self giveWeapon(weapon);self giveMaxAmmo(weapon);self setSpawnWeapon(weapon);self switchToWeaponSeamless(weapon);
    }
    self closeInGameMenu();self closeMenu();self openMenu("opencj_shop_inspect");
    self thread watchInspect();
}
stopInspect()
{
    if(!isDefined(self.shopInspect))return;
    self notify("shop_inspect_stopped");
    state=self.shopInspect;self.shopInspect=undefined;
    self takeAllWeapons();
    for(i=0;i<state.weapons.size;i++)
    {
        w=state.weapons[i];self giveWeapon(w.name);
        self setWeaponAmmoClip(w.name,w.clip);self setWeaponAmmoStock(w.name,w.stock);
    }
    if(state.current!="none")self setSpawnWeapon(state.current);
    self openCJ\playerModels::setPlayerModel();
    self freezeControls(false);self enableWeapons();
    self closeInGameMenu();self closeMenu();
}

watchInspect()
{
    self endon("disconnect");
    self endon("shop_inspect_stopped");
    started=getTime();
    while(isDefined(self.shopInspect))
    {
        if(self.sessionState!="playing" || isDefined(self.cpc) || getTime()-started>120000)
        {self thread stopInspect();return;}
        wait 0.1;
    }
}
