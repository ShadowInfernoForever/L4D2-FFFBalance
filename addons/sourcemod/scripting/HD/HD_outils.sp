// HD_outils.sp
// Regroupe les fonctions annexes, autres.
//////////


// Affiche l'aide au joueur.
public aide(client)
{
	for(new i = 0; i < _nombreHelp; i++)
	{
		new nombre = strlen(_HD_HELP[i]);
		new String:message[nombre + 1];
		strcopy(message, nombre+1, _HD_HELP[i]);
		
		PrintToChat(client, message);
	}
}


// Execute une commande console en retirant le flag SV_CHEATS
public executeNoCheat(client, String:cmd[])
{
	new nombre = textePremierMot(cmd);
	new String:cmdbase[nombre];
	
	StrCat(cmdbase, nombre, cmd);
	
	new flags = GetCommandFlags(cmdbase);
	SetCommandFlags(cmdbase, flags & ~FCVAR_CHEAT);
	
	FakeClientCommand(client, cmd);
	
	SetCommandFlags(cmdbase, flags);
}


// Affiche un message pour une equipe donnée, s'il est important ou non, et destiné ou non au Director.
public afficherTexteAEquipe(equipe, String:msg[], bool:important, bool:avecDirector)
{
	for (new player=1; player<=_maxClients; player++)
	{
		if (IsClientInGame(player) && GetClientTeam(player) == equipe)
		{
			// Soit on autorise le directeur, ou on refuse et on doit comparer les ID. Ca passe automatiquement si l'equipe est survivant.
			if(avecDirector == true || player != _directorID)
			{
				// Limité a 90 caracteres les messages importants !!
				if(important == true) PrintHintText(player, msg);
				else PrintToChat(player, msg);
			}
		}
	}
}


// Recupere le premier mot d'une phrase, avant le premier blanc.
public textePremierMot(String:texte[])
{
	new nombre = strlen(texte);
	new num = 0;
	new bool:trouver = false;
	
	while(num < nombre && trouver == false)
	{
		if(IsCharSpace(texte[num]))
		{
			trouver = true;
		}
		else
		{
			num++;
		}
	}
	
	return(num + 1);
}


// Calcul la distance entre 2 entités
public Float:calculDistance(Float:emeteur[3], Float:recepteur[3])
{
	new Float:x = emeteur[0] - recepteur[0];
	new Float:y = emeteur[1] - recepteur[1];
	new Float:z = emeteur[2] - recepteur[2];
	
	// On facilite le spawn en hauteur
	z = z * 3;

	// racine	
	new Float:distanceResultat = SquareRoot(x * x + y * y + z * z);
	
	if (distanceResultat < 0) 
	{
		distanceResultat = -1 * distanceResultat;
	}

	return distanceResultat;
}


// Empêche le rayon de toucher soit même
public bool:testEntityPlayer(entity, mask, any:data)
{
	if(entity == data) // Check if the TraceRay hit the itself.
	{
		return false; // Don't let the entity be hit
	}
	return true; // It didn't hit itself
}


// Les infectés passent dans l'equipe spectateur, apres etre noté, sauf l'un d'eux (généralement, celui qui va être invoqué)
public setSpectateurSaufElu(id)
{
		// On initialise
		_joueurInfecte[0] = -1;
		_joueurInfecte[1] = -1;
		_joueurInfecte[2] = -1;
		_joueurInfecte[3] = -1;
		
		new i = 0;
		
		
		// On enregistre leurs positions et on les teleports
		for (new player=1; player<=_maxClients; player++)
		{
			if (IsClientInGame(player) && GetClientTeam(player) == TEAM_INFECTED && !IsPlayerAlive(player) && player != id)
			{
				_joueurInfecte[i] = player;
				GetClientEyePosition(player, _joueurPosition[i]);
				GetClientEyeAngles(player, _joueurAngle[i]);
				i++;
				
				ChangeClientTeam(player, TEAM_SPECTATOR);
			}
		}
}


// Remet les infectés notés dans leur propre equipe, et remet en place la vue du spectateur.
public resetInfecte()
{
		// On les remet en places.
		for(new i = 0; i < 4; i++)
		{
			if(_joueurInfecte[i] != -1)
			{
				ChangeClientTeam(_joueurInfecte[i], TEAM_INFECTED);
				TeleportEntity(_joueurInfecte[i], _joueurPosition[i], _joueurAngle[i], NULL_VECTOR);
				
				_joueurInfecte[i] = -1;
			}
		}
}


// Gel les survivants.
public freezeSurvivor(bool:freeze)
{
	for (new player=1; player<=_maxClients; player++)
		{
			if (IsClientInGame(player) && GetClientTeam(player) == TEAM_SURVIVOR)
			{
				if(freeze == true)
				{
					SetEntityMoveType(player, MOVETYPE_NONE);
				}
				else
				{
					SetEntityMoveType(player, MOVETYPE_WALK);
					
					// Eviter les abus des infectés qui spawn a coté des survivants
					executeNoCheat(player, "give health");
				}
			}
		}
}


// Choisie un joueur infecté aléatoirement, et permet de déterminer s'il y a au moins un joueur de disponible
public rouletteSpawnJoueur(numAction)
{
	new memoirePosition = _idJoueurMemo;
	
	do
	{
		_idJoueurMemo++;
		if(_idJoueurMemo > _maxClients) _idJoueurMemo = 1;
		
		if (IsClientInGame(_idJoueurMemo) && GetClientTeam(_idJoueurMemo) == TEAM_INFECTED && _idJoueurMemo != _directorID && StrEqual(_spawnCommand[_idJoueurMemo], "", false) && !IsPlayerAlive(_idJoueurMemo))
		{
			directorSpawn(_idJoueurMemo, numAction);
			return true;
		}
	}
	while(_idJoueurMemo != memoirePosition)

	
	//Tout le monde est occupé
	_idJoueurMemo++;
	if(_idJoueurMemo > _maxClients) _idJoueurMemo = 1;
		
	PrintToChat(_directorID, _HD_REACHED_MAX_ZOMBIES_ON_MAP);
	return actionSound(_directorID, false);
}


// Execution d'un son + return
public bool:actionSound(client, bool:result)
{
	if(result == true)
	{
		return true;
	}
	else
	{
		ClientCommand(client, "play buttons/button11.wav");
		return false;
	}
}


// Retourner l'index dans le tableau d'instructions de spawn en fonction de cmdact.
public findIndexInSpawnArray(String:cmdact[])
{
	for(new i = 0; i < _nombreTypeSpawn; i++)
	{
		if(StrEqual(cmdact, _directorAction[i], false))
		{
			return (i);
		}
	}
	
	if(GetConVarInt(_cvDebug)) PrintToServer("DEBUG[HUMAN DIRECTOR] - Commande non traduite : %s", cmdact);
	return 0;
}


// Afficher le tableau des spawns
public tableauSpawnSpeciaux()
{
	for(new player=1; player <= _maxClients; player++)
	{
		if(IsClientInGame(player) && GetClientTeam(player) == TEAM_INFECTED && player != _directorID)
		{
			new String:playerName[32];
			GetClientName(player, playerName, sizeof(playerName));
			
			new String:situation[128];
			if(strlen(_spawnCommand[player]) != 0)
			{//Si sa spawnCommand n'est pas vide, il est en mode spawning 
				situation = _HD_STATUS_ABLE_TO_SPAWN;
				StrCat(situation, sizeof(situation), _directorActionNom[findIndexInSpawnArray(_spawnCommand[player])]);
			}
			else
			{
				if(IsPlayerAlive(player))
				{
					situation = _HD_STATUS_ALIVE;
				}
				else 
				{
					situation = _HD_STATUS_WAITING;
				}
			}
			PrintToChat(_directorID, _HD_STATUS_FINAL_TEXT, playerName, situation);
		}
	}
}


// Changer d'equipe.
public changeEquipe(idplayerorteam, teamdestination, bool:team)
{
	if(team == true)
	{
		for(new player=1; player <= _maxClients; player++)
		{
			if(IsClientInGame(player) && GetClientTeam(player) == idplayerorteam)
			{
				ChangeClientTeam(player, teamdestination);
			}
		}
	}
	else
	{
		ChangeClientTeam(idplayerorteam, teamdestination);
	}
}


// Test activation du plugin
public testActivation()
{
	if(GetConVarInt(_cvDebug)) PrintToServer("DEBUG[HUMAN DIRECTOR] - Test Activation...");
	_pluginActiverModification = _pluginActiver
	
	// On verifie si on est sur une coop ou non (en regardant les premieres caracteres du nom de la map). Le test s'applique apres verification de l'activation/desactivation du plugin (et seul "_pluginActiverModification" sera modifié)
	new String:currentMap[100];
	new String:currentMod[10];
	
	GetCurrentMap(currentMap, sizeof(currentMap));
	SplitString(currentMap[0], currentMap[6], currentMod, sizeof(currentMod));

	if(!StrEqual(currentMod, "l4d_vs", false))
    {
		// 1 = coop, donc on desactive le plugin
		if(GetConVarInt(_cvDebug)) PrintToServer("DEBUG[HUMAN DIRECTOR] - Map no versus => plugin [HUMAN DIRECTOR] off");
		_pluginActiverModification = false;
    }
	
	PrintToServer("DEBUG[HUMAN DIRECTOR] - Fin Test Activation : activation = %b , result = %b", _pluginActiver, _pluginActiverModification);
}


// Force Spawn
public forceSpawnSpecial()
{
	new memoirePosition = _idJoueurMemo;
	
	do
	{
		_idJoueurMemo++;
		if(_idJoueurMemo > _maxClients) _idJoueurMemo = 1;
		
		if (IsClientInGame(_idJoueurMemo) && GetClientTeam(_idJoueurMemo) == TEAM_INFECTED && _idJoueurMemo != _directorID && StrEqual(_spawnCommand[_idJoueurMemo], "", false) && !IsPlayerAlive(_idJoueurMemo))
		{
			// ID hunter = 4, smoker = 5, boomer = 6. Donc, Base : 3 (+1/2/3).
			// On prepare l'ID
			new num = 3 + _specialClassSpawn;
			_specialClassSpawn++;
			if(_specialClassSpawn >= 4) _specialClassSpawn = 1;
			
			// On force le spawn
			new String:cmdact[strlen(_directorAction[num])+1];
			strcopy(cmdact, strlen(_directorAction[num]) + 1, _directorAction[num]);
			directorExecutionSpawn(_idJoueurMemo, cmdact);
			
			// Probleme de spawn de speciaux toujours la !
			_problemeSpawnSpecial = true;
			
			// On retire 150 de ressources (au lieu de 100, pour punition). On fixe a 0 si pas assez.
			if(_ressource > 150) _ressource = _ressource - 150;
			else _ressource = 0;
			ressourceAfficher();
			
			PrintToChat(_directorID, _HD_SPAWN_FORCE_ALERT);
			
			return;
		}
	}
	while(_idJoueurMemo != memoirePosition)
}
