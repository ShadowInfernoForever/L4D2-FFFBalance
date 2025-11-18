// HD_event.sp
// Regroupe les fonctions évenements.
//////////


// Fin du round.
public eventRoundFin(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Ne pas toucher l'evenement : Voir la fonction suivante.
	roundEnd();
}


// Debut du round.
public eventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Ne pas toucher l'evenement : Voir la fonction suivante.
	roundStart();
}


// Mort d'un infecte (NPC et joueurs)
public eventInfecteMort(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(_pluginActiverModification)
	{
		if(_spawnLimitNumberActuel > 0)
		{
			_spawnLimitNumberActuel--;
		}
	}
}


// Spawn d'un joueur
public eventJoueurSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(_pluginActiverModification)
	{
		new player = GetClientOfUserId(GetEventInt(event, "userid"));
	
		if(GetClientTeam(player) == TEAM_INFECTED)
		{
			// Régler le bug des 1HP au spawn des speciaux
			executeNoCheat(player, "give health");
		}
	}
}


// Quand un joueur rejoind la partie
public OnClientPutInServer(client)
{
	if(_pluginActiverModification)
	{
		PrintToChat(client, _HD_WELCOME_START);
	}
}


// A la deconnection d'un joueur
public OnClientDisconnect(client)
{
	if(_pluginActiverModification)
	{
		if(client == _directorID)
		{
			directorStop();
			//PrintToChatAll(_HD_DIRECTOR_LEFT);
		}
	}
}


// Spawn d'un tank
public eventTankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	_hConvar = FindConVar("sv_cheats");
	new cheat = GetConVarInt(_hConvar); // 0 = no cheat, rajouter le NOT.

	if(_pluginActiverModification && !cheat)
	{
		CreateTimer(5.0, kickTankBot);
	}
}