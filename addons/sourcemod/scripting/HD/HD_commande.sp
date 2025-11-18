// HD_commande.sp
// Regroupe les fonctions liées aux commandes utilisateurs/chat/administrateurs/consoles.
//////////


public Action:cmdDirector(client, args)
{
	if(_pluginActiverModification) directorStart(client);
	return Plugin_Handled
}

public Action:cmdDemission(client, args)
{
	if(_pluginActiverModification) directorDemission(client);
	return Plugin_Handled
}

public Action:cmdMenu(client, args)
{
	if(_pluginActiverModification) directorMenuTest(client);
	return Plugin_Handled
}

public Action:cmdSpawn(client, args)
{
	if(_pluginActiverModification) spawnAsSpecialInfected(client);
	return Plugin_Handled
}

public Action:cmdWhoDirector(client, args)
{
	if(_pluginActiverModification) directorWho(client);
	return Plugin_Handled
}

public Action:cmdStats(client, args)
{
	if(_pluginActiverModification) displayStats();
	return Plugin_Handled
}


// Commande admin : !hdon. Active le plugin.
public Action:cmdPluginActiver(args)
{
	if(_pluginActiver != true)
	{
		_pluginActiver = true;
		PrintToServer(_HD_PLUGIN_ACTIVE_SERVER);
		//PrintToChatAll(_HD_PLUGIN_ACTIVE_ALL);
	}
	else
	{
		PrintToServer(_HD_PLUGIN_ACTIVE_ALREADY);
	}
	
	return Plugin_Handled;
}


// Commande admin : !hdoff. Desactive le plugin.
public Action:cmdPluginDesactiver(args)
{
	if(_pluginActiver != false)
	{
		_pluginActiver = false;
		PrintToServer(_HD_PLUGIN_NOACTIVE_SERVER);
		//PrintToChatAll(_HD_PLUGIN_NOACTIVE_ALL);
	}
	else
	{
		PrintToServer(_HD_PLUGIN_NOACTIVE_ALREADY);
	}
	
	return Plugin_Handled;
}


// Commande : sm_hdkill
public Action:cmdSuicide(client, args)
{
	if(GetClientTeam(client) == TEAM_INFECTED && _pluginActiverModification) executeNoCheat(client, "kill");
	
	return Plugin_Handled;
}


// Commande : sm_hdhelp
public Action:cmdHelp(client, args)
{
	aide(client);
	
	return Plugin_Handled;
}


// Commande : !hdquickspawn
public Action:cmdQuickSpawn(client, args)
{
	if(_pluginActiverModification)
	{
		if(client == _directorID)
		{
			if (args != 1)
			{
				PrintToConsole(client, _HD_QUICKSPAWN_HELP);
				return Plugin_Handled
			}
		 
			new String:numtext[2];
			GetCmdArg(1, numtext, sizeof(numtext))

			new num = StringToInt(numtext);
			
			if(num < _nombreTypeSpawn)
			{
				if(_directorActionIsSpecial[num]) 
				{
					rouletteSpawnJoueur(num);
				}
				else
				{
					directorSpawn(client, num);
				}
			}
			else
			{
				PrintToConsole(client, _HD_QUICKSPAWN_HELP);
			}
		}
	}
	
	return Plugin_Handled
}


// Commande admin : !hdbot
public Action:cmdActiverBot(args)
{
	_hConvar = FindConVar("sb_all_bot_team");
	if(GetConVarInt(_hConvar) == 1)
	{
		SetConVarInt(_hConvar, 0);
		PrintToServer("HD bots => off");
	}
	else
	{
		SetConVarInt(_hConvar, 1);
		PrintToServer("HD bots => on");
	}
	
	return Plugin_Handled
}
