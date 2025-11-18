// HD_test.sp
// Regroupe les fonctions de tests des conditions.
//////////


// Test de spawn
public isCanSpawn(client, String:cmd[], point)
{
	// Ressources
	if (_ressource < point)
	{
		PrintToChat(_directorID, _HD_NOT_ENOUGH_MONEY);
		return actionSound(_directorID, false);
	}
	
	// Spawn Witch
	if(StrEqual(cmd, "z_spawn witch", false))
	{
		if(_spawnLimitWitch <= 0)
		{
			PrintToChat(_directorID, _HD_TOO_MANY_WITCHES);
			return actionSound(_directorID, false);
		}
		else
		{
			_spawnLimitWitch --;
			PrintToChat(_directorID, _HD_REMAINING_WITCHES, _spawnLimitWitch);
			afficherTexteAEquipe(TEAM_INFECTED, _HD_WITCH_SPAWN, true, true);
			return true;
		}
	}
	
	// Spawn Tank
	if(StrEqual(cmd,"z_spawn tank", false))
	{
		if(_spawnLimitTank <= 0)
		{
			PrintToChat(_directorID, _HD_TOO_MANY_TANKS);
			return actionSound(_directorID, false);
		}
		else 
		{
			_spawnLimitTank --;
			PrintToChat(_directorID, _HD_REMAINING_TANKS, _spawnLimitTank);
			afficherTexteAEquipe(TEAM_INFECTED, _HD_TANK_SPAWN, true, true);
			return true;
		}
		
	}
	
	// Spawn Horde
	if(StrEqual(cmd,"director_force_panic_event", false))
	{
		if(_spawnLimitHorde == false)
		{
			PrintToChat(_directorID, _HD_NO_HORDE);
			return actionSound(_directorID, false);
		}
		else
		{
			CreateTimer(_timerReHorde, reHorde);
			_spawnLimitHorde = false;
			PrintToChat(_directorID, _HD_WAIT_TIME_FOR_HORDE);
			afficherTexteAEquipe(TEAM_INFECTED, _HD_HORDE_INCOMING, true, true);
			return true;
		}
	}
	
	// Spawn Special
	if(StrEqual(cmd,"z_spawn hunter", false) || StrEqual(cmd,"z_spawn boomer", false) || StrEqual(cmd,"z_spawn smoker", false))
	{
		if(StrEqual(cmd,"z_spawn hunter", false))
		{
			if(_spawnLimitHunter == false)
			{
				PrintToChat(_directorID, _HD_WAIT_FOR_ANOTHER_HUNTER);
				return actionSound(_directorID, false);
			}
			else
			{
				_spawnLimitHunter = false;
				CreateTimer(_timerReSpecialClassUniqueSpawn, reHunter);
				return true;
			}
		}
		else if(StrEqual(cmd,"z_spawn boomer", false))
		{
			if(_spawnLimitBoomer == false)
			{
				PrintToChat(_directorID, _HD_WAIT_FOR_ANOTHER_BOOMER);
				return actionSound(_directorID, false);
			}
			else
			{
				_spawnLimitBoomer = false;
				CreateTimer(_timerReSpecialClassUniqueSpawn, reBoomer);
				return true;
			}
		}
		else if(StrEqual(cmd,"z_spawn smoker", false))
		{
			if(_spawnLimitSmoker == false)
			{
				PrintToChat(_directorID, _HD_WAIT_FOR_ANOTHER_SMOKER);
				return actionSound(_directorID, false);
			}
			else
			{
				_spawnLimitSmoker = false;
				CreateTimer(_timerReSpecialClassUniqueSpawn, reSmoker);
				return true;
			}
		}
	}
	
	
	//Spawn du groupe de special
	if(StrEqual(cmd,"spawnGroupeSpecial", false))
	{
		if(_spawnLimitHunter == false || _spawnLimitBoomer == false || _spawnLimitSmoker == false)
		{
			PrintToChat(_directorID, _HD_CANT_SPAWN_ANY_SPECIAL);
			return actionSound(_directorID, false);
		}
		else
		{
			// On allege cette condition de spawn : le test est validé même si un joueur est en vie ou avec un ordre.
			new bool:UnSpecialTest = false;
			for (new player=1; player<=_maxClients; player++)
			{
				if (IsClientInGame(player) && GetClientTeam(player) == TEAM_INFECTED && (IsPlayerAlive(player) || !StrEqual(_spawnCommand[player], "", false)))
				{
					if(UnSpecialTest == false)
					{
						UnSpecialTest = true;
					}
					else
					{
						PrintToChat(_directorID, _HD_ALL_INFECTED_ALIVE);
						tableauSpawnSpeciaux();
						return actionSound(_directorID, false);
					}
				}
			}
			
			_spawnLimitHunter = false;
			CreateTimer(_timerReSpecialClassUniqueSpawn, reHunter);
			_spawnLimitSmoker = false;
			CreateTimer(_timerReSpecialClassUniqueSpawn, reSmoker);
			_spawnLimitBoomer = false;
			CreateTimer(_timerReSpecialClassUniqueSpawn, reBoomer);
			
			return true;
		}
	}	
	
	return true;
}


// Test de distance (selon la position et la visée)
public testDistance(client)
{ 
	new bool:unSurvivantDejaTeste = false;

	new Float:angleVue[3];
	new Float:positionJoueur[3];
	new Float:positionVisee[3];
	
	GetClientEyeAngles(client, angleVue);
	GetClientEyePosition(client, positionJoueur);
    
	// On récupére la position visé
	new Handle:trace = TR_TraceRayFilterEx(positionJoueur, angleVue, MASK_SHOT, RayType_Infinite, testEntityPlayer);
	if(TR_DidHit(trace)) 
	{
		TR_GetEndPosition(positionVisee, trace);
	}
	CloseHandle(trace);
	
	
	// Test
	for (new player=1; player<=_maxClients; player++)
	{
		if (IsClientInGame(player) && IsPlayerAlive(player) && GetClientTeam(player) == TEAM_SURVIVOR)
		{
			// On récupére la position du Survivant
			new Float:posSurvivant[3];
			GetClientEyePosition(player, posSurvivant);
			
			// Test position
			new Float:distPos = calculDistance(positionJoueur, posSurvivant);
			new Float:distVisee = calculDistance(positionVisee, posSurvivant);
			
			// Distance critique à respecter
			if(distPos < _distanceStrictMinimum || distVisee < _distanceStrictMinimum)
			{
				if(GetConVarInt(_cvDebug))
				{
					new String:name[32];
					GetClientName(client, name, sizeof(name));
					PrintToServer("DEBUG[HUMAN DIRECTOR] - Joueur '%s' n'arrive pas a spawn (test STRICT) :", name);
					PrintToServer("Position/visee du test : %f et %f ", distPos, distVisee);
					PrintToServer("Position/visee du joueur : %f %f %f et %f %f %f ", positionJoueur[0], positionJoueur[1], positionJoueur[2], positionVisee[0], positionVisee[1], positionVisee[2]);
				}
			
			
				if(distPos < _distanceStrictMinimum) PrintToChat(client, _HD_GO_FURTHER);
				else PrintToChat(client, _HD_AIM_FURTHER);
				return actionSound(client, false);
			}
			else
			{
				if(distPos < _distancePositionMinimum || distVisee < _distanceViseeMinimum)
				{
					// Il faut au moins 2 survivants proche pour que le spawn ne soit pas prise en compte.
					if(unSurvivantDejaTeste == false)
					{
						unSurvivantDejaTeste = true;
					}
					else
					{
						if(GetConVarInt(_cvDebug))
						{
							new String:name[32];
							GetClientName(client, name, sizeof(name));
							PrintToServer("DEBUG[HUMAN DIRECTOR] - Joueur '%s' n'arrive pas a spawn (test normal) :", name);
							PrintToServer("Position/visee du test : %f et %f ", distPos, distVisee);
							PrintToServer("Position/visee du joueur : %f %f %f et %f %f %f ", positionJoueur[0], positionJoueur[1], positionJoueur[2], positionVisee[0], positionVisee[1], positionVisee[2]);
						}

				
						if(distPos < _distancePositionMinimum) PrintToChat(client, _HD_GO_FURTHER);
						else PrintToChat(client, _HD_AIM_FURTHER);
						return actionSound(client, false);
					}
				}
			}
			
			
			
		}
	}
	
	return true;
}

public IsSpecialInfectedSpawn(String:cmdact[])
{
	return (_directorActionIsSpecial[findIndexInSpawnArray(cmdact)]);
}
