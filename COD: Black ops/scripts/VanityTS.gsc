#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
/*
    Mod: VanityTS
    Client: Call of Duty: Black ops
    Developed by @DoktorSAS

    General:
    - It is possible to change class in any moments during the game
    - If you land on ground the shot it will not count
    - The minmum distance to hit a valid shot is 10m
    - Bots can spawn with and without bot warfare mod,
      without the mod the bot will have no logic
        https://github.com/ineedbots/bo1_bot_warfare
    - Its possible to teleport to some spots inside and outside of the map

    Search & Destroy:
    - Players will be placed everytime in the attackers teams
    - 2 bots will automaticaly spawn
    - The menu will not display FFA options such as Fastlast

    Free for all:
    - Lobby will be filled with bots untill there not enough players
    - The menu will display FFA options such as Fastlast
    - Once miss a miniute from the endgame all players will set to last

    Team deathmatch:
    - Can be played as a normal match untill last or can be instant set at last or one kill from last
*/

init()
{
    level thread onPlayerConnect();
    level thread onEndGame();

    setDvar("bots_main_menu", 0);
    setDvar("bots_main_chat", 0);
    setDvar("bots_play_obj", 0);
    setDvar("bots_play_killstreak", 0);
    setDvar("bots_loadout_allow_op", 0);

    if (!level.teambased)
    {
        level thread serverBotFill();
    }
    if (level.teambased)
    {
        if (getDvar("g_gametype") == "sd" || getDvar("g_gametype") == "sr")
        {
            setDvar("scr_" + getDvar("g_gametype") + "_roundswitch", 0);
        }

        setdvar("bots_team", game["defenders"]);
        setdvar("players_team", game["attackers"]);
        level thread inizializeBots();
    }

    setdvar("pm_bouncing", 1);
    setdvar("pm_bouncingAllAngles", 1);
    setdvar("g_playerCollision", 0);
    setdvar("g_playerEjection", 0);

    setDvar("perk_bulletPenetrationMultiplier", 30);
    setDvar("perk_armorPiercing", 9999);
    setDvar("bullet_ricochetBaseChance", 0.95);
    setDvar("bullet_penetrationMinFxDist", 1024);


    game["strings"]["change_class"] = undefined; // Removes the class text if changing class midgame
}

main()
{
    replaceFunc(maps\mp\gametypes\_globallogic_score::_setPlayerScore, ::_setPlayerScore);
}

_setPlayerScore( player, score )
{
	if ( score == player.pers["score"] || player isentityabot())
	{	
        return;
    }
    else
    {
        if ( !level.onlineGame || ( GetDvarInt( #"xblive_privatematch" ) && !GetDvarInt( #"xblive_basictraining" ) ) )
        {
            player thread maps\mp\gametypes\_rank::updateRankScoreHUD( score - player.pers["score"] );
        }

        player.pers["score"] = score;
        player.score = player.pers["score"];
        recordPlayerStats( player, "score" , player.pers["score"] );

        player notify ( "update_playerscore_hud" );
        if ( level.wagerMatch )
            player thread maps\mp\gametypes\_wager::playerScored();
        player thread maps\mp\gametypes\_globallogic::checkScoreLimit();
        player thread maps\mp\gametypes\_globallogic::checkPlayerScoreLimitSoon();
    }
}

codecallback_playerdamagedksas(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
    if (sMeansOfDeath == "MOD_MELEE")
        return 0;

    if (sMeansOfDeath == "MOD_TRIGGER_HURT" || sMeansOfDeath == "MOD_SUICIDE" || sMeansOfDeath == "MOD_FALLING")
    {
    }
    else
    {

        if (eAttacker isentityabot() && !self isentityabot())
        {
            iDamage = iDamage / 4;
        }
        else if (!(eAttacker isentityabot()) && maps\mp\gametypes\_missions::getWeaponClass(sWeapon) == "weapon_sniper")
        {
            iDamage = 999;
            if (!level.teambased)
            {
                scoreLimit = level.scorelimit;

                if (eAttacker.pers["score"] == scoreLimit - 5)
                {

                    if ((distance(self.origin, eAttacker.origin) * 0.0254) < 10)
                    {
                        iDamage = 0;
                        eAttacker iprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
                    }
                    else if (eAttacker isOnGround())
                    {
                        iDamage = 0;
                        eAttacker iprintln("Landed on the ground");
                    }
                    else
                    {
                        for (i = 0; i < level.players.size; i++)
                        {
                            player = level.players[i];
                            player iprintln("[^5" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "^7m]");
                        }
                    }
                }
            }
            else
            {
                if (getDvar("g_gametype") == "sd")
                {
                    if (level.alivecount[game["defenders"]] == 1)
                    {
                        if ((distance(self.origin, eAttacker.origin) * 0.0254) < 10)
                        {
                            iDamage = 0;
                            eAttacker iprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
                        }
                        else if (eAttacker isOnGround())
                        {
                            iDamage = 0;
                            eAttacker iprintln("Landed on the ground");
                        }
                        else
                        {
                            for (i = 0; i < level.players.size; i++)
                            {
                                player = level.players[i];
                                player iprintln("[^5" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "^7m]");
                            }
                        }
                    }
                }
                else if (getDvar("g_gametype") == "war")
                {
                    if (game["teamScores"][game["attackers"]] == level.scorelimit - 10)
                    {
                        if ((distance(self.origin, eAttacker.origin) * 0.0254) < 10)
                        {
                            iDamage = 0;
                            eAttacker iprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
                        }
                        else if (eAttacker isOnGround())
                        {
                            iDamage = 0;
                            eAttacker iprintln("Landed on the ground");
                        }
                        else
                        {
                            for (i = 0; i < level.players.size; i++)
                            {
                                player = level.players[i];
                                player iprintln("[^5" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "^7m]");
                            }
                        }
                    }
                }
            }
        }
        else if (!eAttacker isentityabot() && sWeapon == "throwingknife_mp")
        {
            iDamage = 999;
            if (isDefined(eAttacker.throwingknife_last_origin) && int(distance(self.origin, eAttacker.origin) * 0.0254) < 15)
            {
                iDamage = 0;
                eAttacker iprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
            }
        }
        else if (!eAttacker isentityabot())
        {
            iDamage = 0;
        }
    }

    [[level.callbackplayerdamage_stub]] (eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
}

onEndGame()
{
    level waittill("game_ended");
    for (i = 0; i < level.players.size; i++)
    {
        player = level.players[i];
        if (player isentityabot())
        {
        }
        else
        {
            player.menu["ui_title"] destroy();
            player.menu["ui_options"] destroy();
            player.menu["select_bar"] destroy();
            player.menu["top_bar"] destroy();
            player.menu["background"] destroy();
            player.menu["bottom_bar"] destroy();
            player.menu["ui_credits"] destroy();
        }
    }
}

onPlayerConnect()
{
    once = 1;
    for (;;)
    {
        level waittill("connected", player);
        if (once)
        {
            level.callbackplayerdamage_stub = level.callbackplayerdamage;
            level.callbackplayerdamage = ::codecallback_playerdamagedksas;
            once = 0;
        }

        if (player isentityabot())
        {
            player thread onBotSpawned();
        }
        else
        {
            player thread onPlayerSpawned();
        }

        if (level.teambased)
        {
            player thread onJoinedTeam();
        }
    }
}

onBotSpawned()
{
    level endon("game_ended");
    self endon("disconnect");
    for (;;)
    {
        self waittill("spawned_player");
        self unsetperk("specialty_pistoldeath");
        self unsetperk("specialty_armorvest");
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
    level endon("game_ended");

    self.__vars = [];
    self.__vars["level"] = 2;
    self.__vars["sn1buttons"] = 1;

    self.matchbonus = randomintrange(250, 2500);

    if (getdvar("g_gametype") == "dm")
    {
        self thread kickBotOnJoin();
    }

    self buildMenu();
    self thread initOverFlowFix();
    self thread changeClassAnytime();

    once = 1;
    for (;;)
    {
        self waittill("spawned_player");
        self unsetperk("specialty_pistoldeath");
        self unsetperk("specialty_armorvest");

        self freezeControls(0);
        if (once)
        {
            once = 0;
        }

        if (isdefined(self.spawn_origin))
        {
            wait 0.05;
            self setorigin(self.spawn_origin);
            self setPlayerAngles(self.spawn_angles);
        }
    }
}

// menu.gsc
buildMenu()
{
    title = "VanityTS";
    self.menu = [];
    self.menu["status"] = 1;
    self.menu["index"] = 0;
    self.menu["page"] = "";
    self.menu["options"] = [];
    self.menu["ui_options_string"] = "";
    self.menu["ui_title"] = self CreateString(title, "objective", 1.4, "CENTER", "CENTER", 0, -200, (1, 1, 1), 0, (0, 0, 0), 0.5, 5, 0);
    self.menu["ui_options"] = self CreateString("", "objective", 1.2, "LEFT", "CENTER", -55, -190, (1, 1, 1), 0, (0, 0, 0), 0.5, 5, 0);
    self.menu["ui_credits"] = self CreateString("Developed by ^5DoktorSAS", "objective", 1, "TOP", "CENTER", 0, -100, (1, 1, 1), 0, (0, 0, 0), 0.8, 5, 0);

    self.menu["select_bar"] = self DrawShader("white", 362.5 - 105, 58, 125, 13, GetColor("lightblue"), 0, 4, "TOP", "CENTER", 0);
    self.menu["top_bar"] = self DrawShader("white", 362.5 - 105, 25, 125, 25, GetColor("cyan"), 0, 3, "TOP", "CENTER", 0);
    self.menu["background"] = self DrawShader("black", 362.5 - 105, 40, 125, 40, GetColor("cyan"), 0, 1, "TOP", "CENTER", 0);
    self.menu["bottom_bar"] = self DrawShader("white", 362.5 - 105, 58, 125, 18, GetColor("cyan"), 0, 3, "TOP", "CENTER", 0);

    self thread handleMenu();
    self thread onDeath();
}

showMenu()
{
    buildOptions();
    self.menu["status"] = 1;

    self.menu["background"] setShader("black", 125, 55 + int(self.menu["options"].size / 2) + (self.menu["options"].size * 14));

    self.menu["ui_credits"].y = -169.5 + (self.menu["options"].size * 14.6 + 5);
    self.menu["bottom_bar"].y = 58 + (self.menu["options"].size * 14.6) + 14.6;

    self.menu["ui_title"] affectElement("alpha", 0.4, 1);
    self.menu["ui_options"] affectElement("alpha", 0.4, 1);
    self.menu["select_bar"] affectElement("alpha", 0.4, 0.8);
    self.menu["top_bar"] affectElement("alpha", 0.4, 1);
    self.menu["background"] affectElement("alpha", 0.4, 0.4);
    self.menu["bottom_bar"] affectElement("alpha", 0.4, 1);
    self.menu["ui_credits"] affectElement("alpha", 0.4, 1);
}

hideMenu()
{
    self.menu["ui_title"] affectElement("alpha", 0.4, 0);
    self.menu["ui_options"] affectElement("alpha", 0.4, 0);
    self.menu["select_bar"] affectElement("alpha", 0.4, 0);
    self.menu["top_bar"] affectElement("alpha", 0.4, 0);
    self.menu["background"] affectElement("alpha", 0.4, 0);
    self.menu["bottom_bar"] affectElement("alpha", 0.4, 0);
    self.menu["ui_credits"] affectElement("alpha", 0.4, 0);
    self.menu["status"] = 0;
}

onDeath()
{
    for (;;)
    {
        self waittill("death");
        if (self.__vars["status"] == 1)
        {
            self hideMenu();
        }
    }
}
goToNextOption()
{
    self.menu["index"]++;
    if (self.menu["index"] > self.menu["options"].size - 1)
    {
        self.menu["index"] = 0;
    }
    self.menu["select_bar"] affectElement("y", 0.1, 58 + (self.menu["index"] * 14.6));
    wait 0.1;
}

goToPreviusOption()
{
    self.menu["index"]--;
    if (self.menu["index"] < 0)
    {
        self.menu["index"] = self.menu["options"].size - 1;
    }
    self.menu["select_bar"] affectElement("y", 0.1, 58 + (self.menu["index"] * 14.6));
    wait 0.1;
}

handleMenu()
{
    level endon("game_ended");
    self endon("disconnect");
    for (;;)
    {
        if (isDefined(self.menu["status"]))
        {
            if (self.menu["status"])
            {
                if (self attackbuttonpressed())
                {
                    self goToNextOption();
                }
                else if (self adsbuttonpressed())
                {
                    self goToPreviusOption();
                }
                else if (self UseButtonPressed())
                {
                    index = self.menu["index"];
                    [[self.menu ["options"] [index].invoke]] (self.menu["options"][index].args);
                    wait 0.4;
                }
                else if (self meleeButtonPressed())
                {
                    self goToTheParent();
                    wait 0.5;
                }
            }
            else
            {
                if (self meleeButtonPressed() && self AdsButtonPressed())
                {
                    if (self.menu["page"] == "")
                    {
                        openSubmenu("default");
                    }
                    else
                    {
                        openSubmenu(self.menu["page"]);
                    }
                    self showMenu();
                    wait 0.5;
                }
            }
        }
        wait 0.05;
    }
}

addOption(lvl, parent, option, function, args)
{
    if (self.__vars["level"] >= lvl)
    {
        i = self.menu["options"].size;
        self.menu["options"][i] = spawnStruct();
        self.menu["options"][i].page = self.menu["page"];
        self.menu["options"][i].parent = parent;
        self.menu["options"][i].label = option;
        self.menu["options"][i].invoke = function;
        self.menu["options"][i].args = args;
        self.menu["ui_options_string"] = self.menu["ui_options_string"] + "^7\n" + self.menu["options"][i].label;
    }
}

goToTheParent()
{
    if (!isInteger(self.menu["page"]) && self.menu["page"] == self.menu["options"][self.menu["index"]].parent)
    {
        self hideMenu();
        return;
    }
    self.menu["page"] = self.menu["options"][self.menu["index"]].parent;
    buildOptions();

    if (self.menu["index"] > self.menu["options"].size - 1)
    {
        self.menu["index"] = 0;
    }
    if (self.menu["index"] < 0)
    {
        self.menu["index"] = self.menu["options"].size - 1;
    }
    self.menu["select_bar"] affectElement("y", 0.1, 58 + (self.menu["index"] * 14.6));

    self.menu["ui_credits"] affectElement("y", 0.12, -169.5 + (self.menu["options"].size * 14.6 + 5));
    self.menu["bottom_bar"] affectElement("y", 0.12, 58 + (self.menu["options"].size * 14.6) + 14.6);
    wait 0.1;
    self.menu["background"] setShader("black", 125, 55 + int(self.menu["options"].size / 2) + (self.menu["options"].size * 14));

    self.menu["ui_options"] setSafeText(self, self.menu["ui_options_string"]);

    if (self.menu["index"] > self.menu["options"].size - 1)
    {
        self.menu["index"] = 0;
    }
    if (self.menu["index"] < 0)
    {
        self.menu["index"] = self.menu["options"].size - 1;
    }
}

openSubmenu(page)
{
    self.menu["page"] = page;
    self.menu["index"] = 0;
    self.menu["select_bar"] affectElement("y", 0.1, 58 + (self.menu["index"] * 14.6));
    buildOptions();

    self.menu["ui_credits"] affectElement("y", 0.12, -169.5 + (self.menu["options"].size * 14.6 + 5));
    self.menu["bottom_bar"] affectElement("y", 0.12, 58 + (self.menu["options"].size * 14.6) + 14.6);
    wait 0.1;
    self.menu["background"] setShader("black", 125, 55 + int(self.menu["options"].size / 2) + (self.menu["options"].size * 14));

    self.menu["ui_options"] setSafeText(self, self.menu["ui_options_string"]);
}

buildOptions()
{
    if ((self.menu["options"].size == 0) || (self.menu["options"].size > 0 && self.menu["options"][0].page != self.menu["page"]))
    {
        self.menu["ui_options_string"] = "";
        self.menu["options"] = [];
        switch (self.menu["page"])
        {
        case "players":
            for (i = 0; i < level.players.size; i++)
            {
                player = level.players[i];
                addOption(2, "default", player.name, ::openSubmenu, i + 1);
            }
            break;
        case "killstreak":
            addOption(0, "default", "UAV", ::giveKillstreak, "radar_mp;UAV");
            addOption(0, "default", "Carepackage", ::giveKillstreak, "supply_drop_mp;Carepackage");
            break;
        case "trickshot":
            // addOption("default", "Random TS Class", ::testFunc);
            addOption(0, "default", "^2Set ^7Spawn", ::SetSpawn);
            addOption(0, "default", "^1Clear ^7Spawn", ::ClearSpawn);
            addOption(0, "default", "TP to Spawn", ::LoadSpawn);
            if (!level.teambased || getDvar("g_gametype") == "tdm")
            {
                addOption(1, "default", "Fastlast", ::doFastLast);
                addOption(1, "default", "Fastlast 2p", ::doFastLast2Pieces);
            }

            addOption(0, "default", "Canswap", ::canswap);
            addOption(0, "default", "Suicide", ::kys);
            addOption(0, "default", "UFO", ::JoinUFO);
            break;
        case "teleports":
            buildTeleportsOptions();
            break;
        case "default":
        default:
            if (isInteger(self.menu["page"]))
            {
                pIndex = int(self.menu["page"]) - 1;
                if (level.players[pIndex] isentityabot())
                {
                    addOption(2, "players", "Freeze", ::freeze, level.players[pIndex]);
                    addOption(2, "players", "Unfreeze", ::unfreeze, level.players[pIndex]);
                }
                addOption(2, "players", "Teleport to", ::teleportto, level.players[pIndex]);
                addOption(2, "players", "Teleport me", ::teleportme, level.players[pIndex]);
            }
            else
            {
                if (self.menu["page"] == "")
                {
                    self.menu["page"] = "default";
                }
                addOption(0, "default", "Trickshot", ::openSubmenu, "trickshot");
                addOption(0, "default", "Teleports", ::openSubmenu, "teleports");
                addOption(0, "default", "Killstreaks", ::openSubmenu, "killstreak");
                addOption(1, "default", "Players", ::openSubmenu, "players");
            }

            break;
        }
    }
}

testFunc()
{
    self iPrintLn("DoktorSAS!");
}
// utils.gsd

isInteger(value) // Check if the value contains only numbers
{
    new_int = int(value);

    if (value != "0" && new_int == 0) // 0 means its invalid
    {
        return 0;
    }

    if (new_int > 0)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}
isClientABot(entity)
{
    return isDefined(entity.pers["isBot"]) && entity.pers["isBot"];
}
SetDvarIfNotInizialized(dvar, value)
{
    if (!IsInizialized(dvar))
        setDvar(dvar, value);
}
IsInizialized(dvar)
{
    result = getDvar(dvar);
    return result != "";
}

gametypeToName(gametype)
{
    switch (tolower(gametype))
    {
    case "dm":
        return "Free for all";

    case "tdm":
        return "Team Deathmatch";

    case "sd":
        return "Search & Destroy";

    case "conf":
        return "Kill Confirmed";

    case "ctf":
        return "Capture the Flag";

    case "dom":
        return "Domination";

    case "dem":
        return "Demolition";

    case "gun":
        return "Gun Game";

    case "hq":
        return "Headquaters";

    case "koth":
        return "Hardpoint";

    case "oic":
        return "One in the chamber";

    case "oneflag":
        return "One-Flag CTF";

    case "sas":
        return "Sticks & Stones";

    case "shrp":
        return "Sharpshooter";
    }
    return "invalid";
}
isValidColor(value)
{
    return value == "0" || value == "1" || value == "2" || value == "3" || value == "4" || value == "5" || value == "6" || value == "7";
}
GetColor(color)
{
    switch (tolower(color))
    {
    case "red":
        return (0.960, 0.180, 0.180);

    case "black":
        return (0, 0, 0);

    case "grey":
        return (0.035, 0.059, 0.063);

    case "purple":
        return (1, 0.282, 1);

    case "pink":
        return (1, 0.623, 0.811);

    case "green":
        return (0, 0.69, 0.15);

    case "blue":
        return (0, 0, 1);

    case "lightblue":
    case "light blue":
        return (0.152, 0329, 0.929);

    case "lightgreen":
    case "light green":
        return (0.09, 1, 0.09);

    case "orange":
        return (1, 0662, 0.035);

    case "yellow":
        return (0.968, 0.992, 0.043);

    case "brown":
        return (0.501, 0.250, 0);

    case "cyan":
        return (0, 1, 1);

    case "white":
        return (1, 1, 1);
    }
}
// Drawing
CreateString(input, font, fontScale, align, relative, x, y, color, alpha, glowColor, glowAlpha, sort, isLevel, isValue)
{
    if (!isDefined(isLevel) || isLevel == 0)
        hud = self createFontString(font, fontScale);
    else
        hud = level createServerFontString(font, fontScale);
    if (!isDefined(isValue) || isValue == 0)
        hud setSafeText(self, input);
    else
        hud setValue(input);
    hud setPoint(align, relative, x, y);
    hud.color = color;
    hud.alpha = alpha;
    hud.glowColor = glowColor;
    hud.glowAlpha = glowAlpha;
    hud.sort = sort;
    hud.alpha = alpha;
    hud.archived = 0;
    hud.hideWhenInMenu = 0;
    return hud;
}
CreateRectangle(align, relative, x, y, width, height, color, shader, sort, alpha)
{
    boxElem = newClientHudElem(self);
    boxElem.elemType = "bar";
    boxElem.width = width;
    boxElem.height = height;
    boxElem.align = align;
    boxElem.relative = relative;
    boxElem.xOffset = 0;
    boxElem.yOffset = 0;
    boxElem.children = [];
    boxElem.sort = sort;
    boxElem.color = color;
    boxElem.alpha = alpha;
    boxElem setParent(level.uiparent);
    boxElem setShader(shader, width, height);
    boxElem.hidden = 0;
    boxElem setPoint(align, relative, x, y);
    boxElem.hideWhenInMenu = 0;
    boxElem.archived = 0;
    return boxElem;
}
CreateNewsBar(align, relative, x, y, width, height, color, shader, sort, alpha)
{ // Not mine
    barElemBG = newClientHudElem(self);
    barElemBG.elemType = "bar";
    barElemBG.width = width;
    barElemBG.height = height;
    barElemBG.align = align;
    barElemBG.relative = relative;
    barElemBG.xOffset = 0;
    barElemBG.yOffset = 0;
    barElemBG.children = [];
    barElemBG.sort = sort;
    barElemBG.color = color;
    barElemBG.alpha = alpha;
    barElemBG setParent(level.uiparent);
    barElemBG setShader(shader, width, height);
    barElemBG.hidden = 0;
    barElemBG setPoint(align, relative, x, y);
    barElemBG.hideWhenInMenu = 0;
    barElemBG.archived = 0;
    return barElemBG;
}
DrawText(text, font, fontscale, x, y, color, alpha, glowcolor, glowalpha, sort)
{
    hud = self createfontstring(font, fontscale);
    hud setSafeText(self, text);
    hud.x = x;
    hud.y = y;
    hud.color = color;
    hud.alpha = alpha;
    hud.glowcolor = glowcolor;
    hud.glowalpha = glowalpha;
    hud.sort = sort;
    hud.alpha = alpha;
    hud.hideWhenInMenu = 0;
    hud.archived = 0;
    return hud;
}
DrawShader(shader, x, y, width, height, color, alpha, sort, align, relative, isLevel)
{
    if (isDefined(isLevel) || isLevel == 0)
        hud = newhudelem();
    else
        hud = newclienthudelem(self);
    hud.elemtype = "icon";
    hud.color = color;
    hud.alpha = alpha;
    hud.sort = sort;
    hud.children = [];
    if (isDefined(align))
        hud.align = align;
    if (isDefined(relative))
        hud.relative = relative;
    // hud setparent(level.uiparent);
    hud.x = x;
    hud.y = y;
    hud setshader(shader, width, height);
    hud.hideWhenInMenu = 0;
    hud.archived = 0;
    return hud;
}
// Animations
affectElement(type, time, value)
{
    if (type == "x" || type == "y")
        self moveOverTime(time);
    else
        self fadeOverTime(time);
    if (type == "x")
        self.x = value;
    if (type == "y")
        self.y = value;
    if (type == "alpha")
        self.alpha = value;
    if (type == "width")
        self.width = value;
    if (type == "height")
        self.height = value;
    if (type == "color")
        self.color = value;
}
// functions.gsc

changeClassAnytime()
{
    self endon("disconnect");
    level endon("game_ended");
    for (;;)
    {
		self waittill("changed_class");
		self maps\mp\gametypes\_class::giveloadout( self.team, self.class );
        self setPerks();
    }
}

setPerks(){
    if( self hasPerk( "specialty_movefaster" ) ) 
    { //Lightweight
        self setPerk( "specialty_fallheight" );
    }

    if( self hasPerk( "specialty_scavenger" ) ) 
    { //Scavenger
        self setPerk( "specialty_extraammo" );
    }

    if( self hasPerk( "specialty_flakjacket" ) ) 
    { //Flak Jacket
        self setPerk( "specialty_fireproof" );
        self setPerk( "specialty_pin_back" );
    }

    if( self hasPerk( "specialty_killstreak" ) ) 
    { //Hardline
        self setPerk( "specialty_gambler" );
    }

    if( self hasPerk( "specialty_bulletpenetration" ) ) 
    { //Hardened
        self setPerk( "specialty_armorpiercing" );
        self setPerk( "specialty_bulletflinch" );
    }

    if( self hasPerk( "specialty_holdbreath" ) ) 
    { //Scout
        self setPerk( "specialty_fastweaponswitch" );
    }

    if( self hasPerk( "specialty_bulletaccuracy" ) ) 
    { //Steady Aim
        self setPerk( "specialty_sprintrecovery" );
        self setPerk( "specialty_fastmeleerecovery" );
    }

    if( self hasPerk( "specialty_fastreload" ) ) 
    { //Sleight of Hand
        self setPerk( "specialty_fastads" );
    }

    if( self hasPerk( "specialty_twoattach" ) ) 
    { //Warlord
        self setPerk( "specialty_twogrenades" );
    }

    if( self hasPerk( "specialty_longersprint" ) ) 
    { //Marathon
        self setPerk( "specialty_unlimitedsprint" );
    }

    if( self hasPerk( "specialty_quieter" ) ) 
    { //Ninja
        self setPerk( "specialty_loudenemies" );
    }
		
    if( self hasPerk( "specialty_detectexplosive" ) && self hasPerk( "specialty_showenemyequipment" ) ) 
    { //Hacker
        self setPerk( "specialty_disarmexplosive" );
         self setPerk( "specialty_nomotionsensor" );
    }

    if( self hasPerk( "specialty_gas_mask" ) ) 
    { //Tactical Mask
        self setPerk( "specialty_stunprotection" );
        self setPerk( "specialty_shades" );
    }
		
	// Always Have Deep Impact
	self setPerk( "specialty_bulletpenetration" );
	self setPerk( "specialty_armorpiercing" );
	self setPerk( "specialty_bulletflinch" );

	// Remove Final Stand
	self unsetPerk( "specialty_pistoldeath" );
	self unsetPerk( "specialty_finalstand" );
}
freeze(player)
{
    self iPrintLn(player.name + " ^5freezed");
    player FreezeControls(1);
}
unfreeze(player)
{
    self iPrintLn(player.name + " ^3unfreezed");
    player FreezeControls(0);
}
JoinUFO()
{
    if (!isDefined(self.__vars["ufo"]) || self.__vars["ufo"] == 0)
    {
        self iprintln("U.F.O is now ^2ON");
        self.__vars["ufo"] = 1;
        self allowspectateteam("freelook", 1);
        self.sessionstate = "spectator";
        self setcontents(0);
        self iPrintLn("Press ^3[{+melee}] ^7to leave UFO");
        while (!self meleeButtonPressed())
        {
            wait 0.05;
        }
        self iprintln("U.F.O is now ^1OFF");
        self.__vars["ufo"] = 0;
        self.sessionstate = "playing";
        self allowspectateteam("freelook", 0);
        self setcontents(100);
    }
}
SetScore(kills)
{
    self.pointstowin = kills;
	self.pers["pointstowin"] = self.pointstowin;
    self.extrascore0 = kills;
    self.pers["extrascore0"] = self.extrascore0;
    self.score = kills;
    self.pers["score"] = self.score;
    self.kills = kills;
    if (kills > 0)
    {
        self.deaths = randomInt(11) * 2;
        self.headshots = randomInt(7) * 2;
    }
    else
    {
        self.deaths = 0;
        self.headshots = 0;
    }
    self.pers["kills"] = self.kills;
    self.pers["deaths"] = self.deaths;
    self.pers["headshots"] = self.headshots;
}

doFastLast()
{
    if (getDvar("g_gametype") == "tdm")
    {
        [[level._setTeamScore]] (self.team, level.scoreLimit - 100);
        iPrintLn("Lobby at ^6last");
    }
    else
    {
        self SetScore(level.scoreLimit - 1);
        self iPrintLn("You are now at ^6last");
    }
}

doFastLast2Pieces()
{
    if (getDvar("g_gametype") == "tdm")
    {
        [[level._setTeamScore]] (self.team, level.scoreLimit - 200);
        iPrintLn("Lobby at ^61 ^7kill from ^6last");
    }
    else
    {
        self SetScore(level.scoreLimit - 2);
    }
}

SetSpawn()
{
    self.spawn_origin = self.origin;
    self.spawn_angles = self.angles;
    self iPrintln("Your spawn has been ^2SET");
}

ClearSpawn()
{
    self.spawn_origin = undefined;
    self.spawn_angles = undefined;
    self iPrintln("Your spawn has been ^1REMOVED");
}

LoadSpawn()
{
    self setorigin(self.spawn_origin);
    self setPlayerAngles(self.spawn_angles);
}

giveKillstreak(args)
{
    sas = strTok(args, ";");
    self maps\mp\gametypes\_hardpoints::giveKillstreak(sas[0]);
    self iprintln(sas[1] + " is now ^2available");
}

// Suicide
kys() { self suicide(); /*DoktorSAS*/ }

canswap()
{
    self iprintln("Canswap ^3Dropped");
    self giveweapon("ak47_mp");
    self dropitem("ak47_mp");
}
// Teleports
teleportto(player)
{
    if (isDefined(player))
    {
        self setOrigin(player.origin);
    }
    else
    {
        self iPrintLn("Player ^1not ^7existing!");
    }
}

teleportme(player)
{
    if (isDefined(player))
    {
        player setOrigin(self.origin);
    }
    else
    {
        self iPrintLn("Player ^1not ^7existing!");
    }
}

// overflowfix.gsc
// CMT Frosty Codes
initOverFlowFix()
{ // tables
    self.stringTable = [];
    self.stringTableEntryCount = 0;
    self.textTable = [];
    self.textTableEntryCount = 0;
    if (!isDefined(level.anchorText))
    {
        level.anchorText = createServerFontString("default", 1.5);
        level.anchorText setText("anchor");
        level.anchorText.alpha = 0;
        level.stringCount = 0;
        level thread monitorOverflow();
    }
}
// strings cache serverside -- all string entries are shared by every player
monitorOverflow()
{
    level endon("disconnect");
    for (;;)
    {
        if (level.stringCount >= 60)
        {
            level.anchorText clearAllTextAfterHudElem();
            level.stringCount = 0;
            for (i = 0; i < level.players.size; i++)
            {
                player = level.players[i];
                player purgeTextTable();
                player purgeStringTable();
                player recreateText();
            }
        }
        wait 0.05;
    }
}
setSafeText(player, text)
{
    stringId = player getStringId(text);
    // if the string doesn't exist add it and get its id
    if (stringId == -1)
    {
        player addStringTableEntry(text);
        stringId = player getStringId(text);
    }
    // update the entry for this text element
    player editTextTableEntry(self.textTableIndex, stringId);
    self setText(text);
}
recreateText()
{
    for (i = 0; i < self.textTable.size; i++)
    {
        entry = self.textTable[i];
        entry.element setSafeText(self, lookUpStringById(entry.stringId));
    }
}
addStringTableEntry(string)
{
    // create new entry
    entry = spawnStruct();
    entry.id = self.stringTableEntryCount;
    entry.string = string;

    self.stringTable[self.stringTable.size] = entry; // add new entry
    self.stringTableEntryCount++;
    level.stringCount++;
}
lookUpStringById(id)
{
    string = "";
    for (i = 0; i < self.textTable.size; i++)
    {
        entry = self.textTable[i];
        if (entry.id == id)
        {
            string = entry.string;
            break;
        }
    }
    return string;
}
getStringId(string)
{
    id = -1;
    for (i = 0; i < self.textTable.size; i++)
    {
        entry = self.textTable[i];
        if (entry.string == string)
        {
            id = entry.id;
            break;
        }
    }
    return id;
}
getStringTableEntry(id)
{
    stringTableEntry = -1;
    for (i = 0; i < self.textTable.size; i++)
    {
        entry = self.textTable[i];
        if (entry.id == id)
        {
            stringTableEntry = entry;
            break;
        }
    }
    return stringTableEntry;
}
purgeStringTable()
{
    stringTable = [];
    // store all used strings
    for (i = 0; i < self.textTable.size; i++)
    {
        entry = self.textTable[i];
        stringTable[stringTable.size] = getStringTableEntry(entry.stringId);
    }
    self.stringTable = stringTable;
    // empty array
}
purgeTextTable()
{
    textTable = [];
    for (i = 0; i < self.textTable.size; i++)
    {
        entry = self.textTable[i];
        if (entry.id != -1)
            textTable[textTable.size] = entry;
    }
    self.textTable = textTable;
}
addTextTableEntry(element, stringId)
{
    entry = spawnStruct();
    entry.id = self.textTableEntryCount;
    entry.element = element;
    entry.stringId = stringId;
    element.textTableIndex = entry.id;
    self.textTable[self.textTable.size] = entry;
    self.textTableEntryCount++;
}
editTextTableEntry(id, stringId)
{
    for (i = 0; i < self.textTable.size; i++)
    {
        entry = self.textTable[i];
        if (entry.id == id)
        {
            entry.stringId = stringId;
            break;
        }
    }
}
deleteTextTableEntry(id)
{
    for (i = 0; i < self.textTable.size; i++)
    {
        entry = self.textTable[i];
        if (entry.id == id)
        {
            entry.id = -1;
            entry.stringId = -1;
        }
    }
}
clear(player)
{
    if (self.type == "text")
        player deleteTextTableEntry(self.textTableIndex);
    self destroy();
}
// bots.gsc
inizializeBots()
{
    level waittill("connected", idc);
    wait 10;
    bots = 0;
    for (i = 0; i < level.players.size; i++)
    {
        player = level.players[i];
        if (player isentityabot())
        {
            bots++;
        }
    }

    if (bots == 0 && getDvar("g_gametype") == "sd" || getDvar("g_gametype") == "sr")
    {
        spawn_bots(2, game["defenders"]);
    }
    else if (bots == 0)
    {
        spawn_bots( int(getDvarInt("sv_maxclients") / 2), game["defenders"]);
    }
}
onPlayerSelectTeam()
{
    //  Move the player in the correct team
    if (!self isentityabot() && self.pers["team"] == game["defenders"])
    {
        switch (game["attackers"])
        {
        case "axis":
            self [[level.axis]] ();
            break;
        case "allies":
            self [[level.allies]] ();
            break;
        }
    }
    else if ((self isentityabot() && self.pers["team"] == game["attackers"]))
    {
        switch (game["defenders"])
        {
        case "axis":
            self [[level.axis]] ();
            break;
        case "allies":
            self [[level.allies]] ();
            break;
        }
    }
}
isentityabot()
{
    return (isSubStr(self getguid(), "bot")) || self isClientABot() || (isDefined(self.pers[ "isBot" ]) && self.pers[ "isBot" ]);
}
serverBotFill()
{
    level endon("game_ended");
    level waittill("connected", player);
    for (;;)
    {
        if (!level.teambased)
        {
            while (level.players.size < 14 && !level.gameended)
            {
                spawn_bots(1, "autoassign");
                wait 1;
            }
            if (level.players.size >= 17 && contBots() > 0)
                kickbot();
        }
        else
        {
            while (level.players.size < 9 && !level.gameended)
            {
                spawn_bots(1, game["defenders"]);
                wait 1;
            }
        }

        wait 0.05;
    }
}

contBots()
{
    bots = 0;
    for (i = 0; i < level.players.size; i++)
    {
        player = level.players[i];
        if (player isentityabot())
        {
            bots++;
        }
    }
    return bots;
}

spawn_bot(team)
{
    bot = AddTestClient();
    bot.pers["isBot"] = 1;
    bot thread maps\mp\gametypes\_bot::bot_spawn_think(team);
}
spawn_bots(a, team)
{
    // spawn_bots(a, "autoassign");
    while( a > 0 )
    {
        level thread spawn_bot(team);
        a--;
    }
}

kickbot()
{
    level endon("game_ended");
    for (i = 0; i < level.players.size; i++)
    {
        player = level.players[i];
        if (player isentityabot())
        {
            //setDvar("scr_bots_managed_all", getDvarInt("scr_bots_managed_all")-1);
            //setDvar("scr_bots_managed_spawn", getDvarInt("scr_bots_managed_all") );
            kick(player getEntityNumber(), "EXE_PLAYERKICKED");
            // player bot_drop();
            break;
        }
    }
}

kickBotOnJoin()
{
    level endon("game_ended");
    for (i = 0; i < level.players.size; i++)
    {
        player = level.players[i];
        if (player isentityabot())
        {
            //setDvar("scr_bots_managed_all", getDvarInt("scr_bots_managed_all")-1);
            //setDvar("scr_bots_managed_spawn", getDvarInt("scr_bots_managed_all") );
            kick(player getEntityNumber(), "EXE_PLAYERKICKED");
            // player bot_drop();
            break;
        }
    }
}
// sd.gsc
onJoinedTeam()
{
    level endon("game_ended");
    self endon("disconnect");
    for (;;)
    {
        self waittill("joined_team");
        self onPlayerSelectTeam();
    }
}

// teleports.gsc

teleportToCords( cords )
{
    self setOrigin( cords );
}

buildTeleportsOptions()
{
    mapname = GetDvar("mapname");
    switch(mapname){
        case "mp_russianbase":
            addOption(0, "default", "Main Spot", ::teleportToCords,(-1258.51, -8.61099, 452.314));
            addOption(0, "default", "Above Pipeline Spot", ::teleportToCords,(-627.341, -270.479, 259.133));
            addOption(0, "default", "Main Out of Map Spot", ::teleportToCords,(913.202, -1431.97, 486.125));
            addOption(0, "default", "Swaggy Out of Map", ::teleportToCords,(2480.48, 569.904, 112.125));
        break;
        case "mp_array":
            addOption(0, "default", "Out of Map Spawn Speznas", ::teleportToCords,(-3395.56, 3150.58, 785.488));
            addOption(0, "default", "Out of Map Main Spot", ::teleportToCords,(3023.98, -666.483, 471.506));
            addOption(0, "default", "On The Crane B-Bomb", ::teleportToCords,(-1013.16, 1813.07, 1556.52));
            addOption(0, "default", "Window Shot A-Bomb", ::teleportToCords,(313.119, 859.255, 536.125));
        break;
        case "mp_firingrange":
            addOption(0, "default", "Main Spot", ::teleportToCords,(523.395, 1126.86, 237.125));
            addOption(0, "default", "OP 40 Spawn House", ::teleportToCords,(1251.56, 1441.9, 94.125));
            addOption(0, "default", "Out of Map Hill", ::teleportToCords,(-1614.88, 725.109, 172.936));
            addOption(0, "default", "Out of Map Tower", ::teleportToCords,(-1515.57, -2473.18, 352.478));
        break;
        case "mp_duga":
            addOption(0, "default", "Main Spot", ::teleportToCords,(-757.982, -3316.58, 158.602));
            addOption(0, "default", "Car At Door", ::teleportToCords,(84.446, -4043.76, 88.3493));
            addOption(0, "default", "Spot At B-Bomb", ::teleportToCords,(-2565.27, -2848.57, 146.884));
            addOption(0, "default", "Out of Map Speznas Spawn", ::teleportToCords,(-1271.91, 264.732, 239.125));
        break;
        case "mp_cairo":
            addOption(0, "default", "Balcony OP 40 Spawn", ::teleportToCords,(-1412.37, -363.493, 186.125));
            addOption(0, "default", "Balcony Tropas Spawn", ::teleportToCords,(2316.44, 145.625, 124.125));
            addOption(0, "default", "Out of Map Tropas Spawn", ::teleportToCords,(1601.09, -1994.58, 160.009));
            addOption(0, "default", "Out of Map OP 40 Spawn", ::teleportToCords,(45.9224, 1673.46, 176.125));
        break;
        case "mp_havoc":
            addOption(0, "default", "Main Spot", ::teleportToCords,(1492.34, -929.483, 491.541));
            addOption(0, "default", "B-Bomb Spot", ::teleportToCords,(507.306, -1058.11, 296.125));
            addOption(0, "default", "Main Out of Map Spot", ::teleportToCords,(4245.53, -1702.96, 510.336));
            addOption(0, "default", "Bridge Spot", ::teleportToCords,(2670.06, -556.894, 323.125));
        break;
        case "mp_cosmodrome":
            addOption(0, "default", "Main Spot", ::teleportToCords,(1919.38, 1051.41, -7.875));
            addOption(0, "default", "Swag Spot Above A-Bomb", ::teleportToCords,(1929.64, 418.968, -179.875));
            addOption(0, "default", "Main Non-Suicide Spot", ::teleportToCords,(-916.997, 870.618, 58.125));
            addOption(0, "default", "Main Out of Map Spot", ::teleportToCords,(-323.979, -3861.04, 108.125));
        break;
        case "mp_nuked":
            addOption(0, "default", "Yellow House Garden", ::teleportToCords,(1220.31, 414.594, 77.125));
            addOption(0, "default", "Green House Garden", ::teleportToCords,(-469.666, 357.417, 75.125));
            addOption(0, "default", "Yellow House Balcony", ::teleportToCords,(510.921, 192.452, 78.7172));
            addOption(0, "default", "Out Of Map Puppy", ::teleportToCords,(-258.869, -1647.52, -0.871212));
        break;
        case "mp_radiation":
            addOption(0, "default", "Swag Spot at Spawn", ::teleportToCords,(330.275, 1373.53, 209.067));
            addOption(0, "default", "Suicide Spot", ::teleportToCords,(1853.79, -357.683, 260.125));
            addOption(0, "default", "Out of Map near Spawn", ::teleportToCords,(2103.93, 1473.43, 309.861));
            addOption(0, "default", "Out of Map on Roof", ::teleportToCords,(-2427.4, -2957.48, 511.597));
        break;
        case "mp_hanoi":
            addOption(0, "default", "Bus Spot", ::teleportToCords,(211.997, 722.346, 87.625));
            addOption(0, "default", "Balcony", ::teleportToCords,(-1409.81, -2742.48, 120.87));
        break;
        case "mp_villa":
            addOption(0, "default", "Balcony Main Spot", ::teleportToCords,(4138.47, 514.854, 456.125));
            addOption(0, "default", "B-Bomb Window Shot", ::teleportToCords,(2769.54, 1085.61, 376.125));
            addOption(0, "default", "Parasol Tropas Spawn", ::teleportToCords,(2437.06, -524.182, 354.286));
            addOption(0, "default", "Over The Wall Spot", ::teleportToCords,(4637.96, -263.679, 456.125));
        break;
        case "mp_cracked":
            addOption(0, "default", "Main Spot", ::teleportToCords,(-20.9289, -820.158, 80.125));
            addOption(0, "default", "Bus Spot", ::teleportToCords,(-1805.29, 422.32, -66.875));
            addOption(0, "default", "Roof A-Bomb", ::teleportToCords,(-1919.99, -1536.25, -44.5823));
            addOption(0, "default", "Out of Map A4", ::teleportToCords,(1468.56, -2003.31, 48.125));
        break;
        case "mp_crisis":
            addOption(0, "default", "Tower Spot", ::teleportToCords,(-2575, 50.3804, 307.125));
            addOption(0, "default", "A-Bomb Spot", ::teleportToCords,(-1677.62, 1689.4, 236.125));
            addOption(0, "default", "C3 Spot", ::teleportToCords,(405.961, 886.493, 311.96));
            addOption(0, "default", "Out of Map B-Bomb", ::teleportToCords,(-479.936, -367.641, 554.803));
        break;
        case "mp_mountain":
            addOption(0, "default", "On the radio antenna", ::teleportToCords,(1917.35, -344.632, 443.252));
            addOption(0, "default", "Near the cableway", ::teleportToCords,(1992.01, 965.471, 300.53));
            addOption(0, "default", "On the turbine", ::teleportToCords,(4051.73, -1160.64, 579.125));
            addOption(0, "default", "On the rock", ::teleportToCords,(3941.8, -3268.03, 604.612));
        break;
    }
}
