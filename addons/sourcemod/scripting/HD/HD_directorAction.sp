// HD_directorAction.sp
// Regroupe les fonctions liées au Director
//////////


// Tests les conditions d'un spawn.
public directorSpawn(client, num)
{	
	new String:cmdact[strlen(_directorAction[num])+1];
	strcopy(cmdact, strlen(_directorAction[num]) + 1, _directorAction[num]);
	
	new point = _directorCout[num];
	
	// Test du nombres de NPC sur le terrain (testé uniquement avec le spawn d'un infecte simple)
	if ((!StrEqual(cmdact, "z_spawn", false) && !StrEqual(cmdact, "spawn10Infected", false)) || _spawnLimitNumberActuel < _spawnLimitNumberMax)
	{
		// Test du distance de spawn (meme pour les speciaux, pour eviter les abus)
		if((IsSpecialInfectedSpawn(cmdact) || StrEqual(cmdact, "director_force_panic_event", false)) || testDistance(_directorID))
		{
			// Test du spawn (a faire en dernier !! Le test décrémente les limites en même temps)
			if(isCanSpawn(client, cmdact, point))
			{	
				// Cas d'un spawn de groupe
				if(StrEqual(cmdact, "spawnGroupeSpecial", false))
				{
					for (new player=1; player<=_maxClients; player++)
					{
					
						if (IsClientInGame(player) && GetClientTeam(player) == TEAM_INFECTED && player != _directorID && !IsPlayerAlive(player) && StrEqual(_spawnCommand[player], "", false))
						{
							if(_specialClassSpawn == 1)
							{
								directorExecutionSpawn(player, "z_spawn hunter");
							}
							else if(_specialClassSpawn == 2)
							{
								directorExecutionSpawn(player, "z_spawn smoker");
							}
							else if(_specialClassSpawn == 3)
							{
								directorExecutionSpawn(player, "z_spawn boomer");
							}
							
							_specialClassSpawn++;
							if(_specialClassSpawn >= 4) _specialClassSpawn = 1;
						}
					}
					
					// Pour diversifier le prochain spawn de groupe
					_specialClassSpawn++;
					if(_specialClassSpawn >= 4) _specialClassSpawn = 1;
				}
				// Cas d'un spawn de 10 infecté
				else if(StrEqual(cmdact, "spawn10Infected", false))
				{
					for(new i = 0; i < 10; i++)
					{
					   directorExecutionSpawn(client, "z_spawn");
					}
				}
				else
				{
					directorExecutionSpawn(client, cmdact);
				}
				
				_ressource = _ressource - point;
			}
		}
	}
	else 
	{
		PrintToChat(_directorID, _HD_FULL_ZOMBIZ);
		actionSound(client, false);
	}
	
	
	// On affiche les tableau des spawns des joueurs infect"és.
	if(IsSpecialInfectedSpawn(cmdact))
	{
		tableauSpawnSpeciaux();
	}
	
	ressourceAfficher();
}


// Execute la commande de spawn (pour les joueurs et NPC)
public directorExecutionSpawn(client, String:cmdact[])
{	
	addSpawnToStats(cmdact);
	if(StrEqual(cmdact, "z_spawn smoker", false) || StrEqual(cmdact, "z_spawn boomer", false) || StrEqual(cmdact, "z_spawn hunter", false) || StrEqual(cmdact, "z_spawn tank", false))
	{
		// Spawn speciaux
		actionSound(_directorID, true);
		actionSound(client, true);
		_problemeSpawnSpecial = false;
		
		new nombre = strlen(cmdact);
		strcopy(_spawnCommand[client], nombre+1, cmdact);
		
		new String:classe[10] = "";
		strcopy(classe, sizeof(classe), _directorActionNom[findIndexInSpawnArray(_spawnCommand[client])]);
		
		PrintToChat(client, _HD_CAN_RESPAWN_AS, classe);
		PrintToChat(client, _HD_CAMERALIBRE);
		PrintToChat(client, _HD_CAMERALIBRE_DEUX);
		
		new String:name[32];
		GetClientName(client, name, sizeof(name));
		PrintToChat(_directorID, _HD_HAS_RECEIVED_SPAWN_ORDER, name);
	}
	else
	{
		actionSound(_directorID, true);
	
		// Les infectés normaux spawneront a la position du Director
		_spawnLimitNumberActuel++;
		
		_problemeSpawn = false;
		executeNoCheat(client, cmdact);
		
	}
}


// Le joueur infecté apparait sur le terrain.
public spawnAsSpecialInfected(client)
{
	  if(!StrEqual(_spawnCommand[client], "", false))
	  {
			// Les infectés speciaux spawneront a leur position
			if(testDistance(client))
			{
				// Pour cause d'un bug du z_spawn des speciaux, tout les infectés mort passent en spectateur, sauf celui qui spawnera.
				setSpectateurSaufElu(client);
			
				executeNoCheat(client, _spawnCommand[client]);
				_spawnCommand[client] = "";
				
				resetInfecte();
				actionSound(client, true);
				return;
			}
	  }
	  else
	  {
			PrintToChat(client, _HD_CANNOT_SPAWN_YET);
			actionSound(client, false);
			return;
	  }
}


// Le Director est nommé.
public directorStart(client)
{
	if(_directorID == -1 && IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED)
	{
		_menuDejaOuvert = false;
		_problemeSpawn = false;
		_problemeSpawnSpecial = false;
		
		_directorID = client;
		setBackground(1);
		
		new String:name[32];
		GetClientName(_directorID, name, sizeof(name));
			
		//PrintToChatAll(_HD_NEW_DIRECTOR_IS, name);
		if(!_roundStarted)
		{	
			initSpawnLimit(false);
			//PrintToChatAll(_HD_GAME_STARTING_IN_30S);		
			CreateTimer(_timerUnFreezeUnLimit, unFreezeUnLimit);
		}
	}
	else
	{
		if(_directorID >= 0)
		{
			new String:name[32];
			GetClientName(_directorID, name, sizeof(name));
			
			PrintToChat(client, _HD_DIRECTOR_ALREADY_AFFECTED, name);
			actionSound(client, false);
		}
		if(GetClientTeam(client) != TEAM_INFECTED)
		{
			PrintToChat(client, _HD_SURVIVOR_CANNOT_BE_DIRECTOR);
			actionSound(client, false);
		}
	}
}


// Le Director démissionne.
public directorDemission(client)
{
	if(_directorID == client)
	{ 
		new String:name[32];
		GetClientName(_directorID, name, sizeof(name));
		//PrintToChatAll(_HD_DEMISSION_INFO, name);
		
		directorStop();
	}
	else
	{
		if(GetClientTeam(client) == TEAM_INFECTED)
		{
			if(_directorID == -1)
			{
				PrintToChat(client, _HD_DEMISSION_MESSAGE);
				actionSound(client, false);
			}
			else
			{
				new String:name[32];
				GetClientName(_directorID, name, sizeof(name));

				PrintToChat(client, _HD_DEMISSION_BUT_NOT_DIRECTOR);
				actionSound(client, false);
			}
		}
		else
		{
			PrintToChat(client, _HD_DEMISSION_BUT_SURVIVOR);
			actionSound(client, false);
		}
	}
}


// Remet les variables importantes du Director en défaut.
public directorStop()
{
		setBackground(0);
		_directorID = -1;
}


// Qui est le director ?
public directorWho(client)
{
	if(_directorID > 0)
	{
		new String:name[32];
		GetClientName(_directorID, name, sizeof(name));
		
		PrintToChat(client, _HD_WHO_DIRECTOR, name);
	}
	else
	{
		PrintToChat(client, _HD_WHO_NO_DIRECTOR);
		actionSound(client, false);
	}
}
