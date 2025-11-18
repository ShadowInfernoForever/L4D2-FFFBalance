// HD_timer.sp
// Regroupe les fonctions liées aux timers
//////////


// De nouveau possible d'appeller une horde.
public Action:reHorde(Handle:timer) 
{
	if(_pluginActiverModification)
	{
		_spawnLimitHorde = true;
		afficherTexteAEquipe(TEAM_INFECTED, _HD_HORDE_READY, true, true);
	}
}  


// De nouveau possible d'appeller un hunter.
public Action:reHunter(Handle:timer) 
{
	if(_pluginActiverModification)
	{
		_spawnLimitHunter = true;
	}
}  


// De nouveau possible d'appeller un smoker.
public Action:reSmoker(Handle:timer) 
{
	if(_pluginActiverModification)
	{
		_spawnLimitSmoker = true;
	}
}  


// De nouveau possible d'appeller un boomer.
public Action:reBoomer(Handle:timer) 
{
	if(_pluginActiverModification)
	{
		_spawnLimitBoomer = true;
	}
}  


// Reduis le nombre actuel d'infecté tout les X secondes.
public Action:cleanInfecte(Handle:timer) 
{
	if(_pluginActiverModification)
	{
		if(_spawnLimitNumberActuel > 0)
		{
			_spawnLimitNumberActuel--;
		}
	}
}  


// Defreeze les survivants, et retire les limites de spawn des infectes.
public Action:unFreezeUnLimit(Handle:timer) 
{
	if(_pluginActiverModification)
	{
		//PrintToChatAll(_HD_ROUND_START_UNFREEZE);
	
		initSpawnLimit(true);
		
		_startUnFreeze = true;
		_roundStarted = true;
		freezeSurvivor(false);
	}
	
}


// Informe les joueurs au debut du round (et gel les survivants)
public Action:freezeTimerDebut(Handle:timer) 
{
	if(_pluginActiverModification)
	{
		if(_startUnFreeze == false)
		{
			if(_directorID == -1)
			{
				// Aucun director choisie
				afficherTexteAEquipe(TEAM_INFECTED, _HD_INFECTED_NEED_DIRECTOR, true, true);
				afficherTexteAEquipe(TEAM_SURVIVOR, _HD_SURVIVOR_NEED_DIRECTOR, true, false);
			}
			else
			{
				// Le terrain se prepare
				afficherTexteAEquipe(TEAM_INFECTED, _HD_INFECTED_WAIT_DIRECTOR, true, false);
				afficherTexteAEquipe(TEAM_SURVIVOR, _HD_SURVIVOR_WAIT_DIRECTOR, true, false);
			}
		  
			freezeSurvivor(true);
			CreateTimer(_timerFreezeTimerAction, freezeTimerDebut);
		}
		else
		{
			freezeSurvivor(false);
		}
	}
	
}


// tick : Execute des fonctions tout les X secondes (defaut : 5 secondes)
public Action:tick(Handle:timer) 
{
	// On reinitialise la variable _maxClients (en cas de modifications). Info : cette variable permet d'optimiser les boucles.
	_maxClients = GetMaxClients();
	
	
	if(_pluginActiverModification)
	{
		// On vire le director s'il est du coté des survivants.
		if(_directorID > 0 && GetClientTeam(_directorID) == TEAM_SURVIVOR)
		{
			directorStop();
			//PrintToChatAll(_HD_DIRECTOR_WENT_SURVIVOR);
		}

		
		if (_directorID != -1)
		{		
			// On remet en place les convar si sv_cheats = 0 (aprés que ce dernié soit passé à 1)
			testSvCheatsReset();
			
			
			// On ajoute les ressources
			ressourceAjout();
			ressourceAfficher();
			
			
			// Prevenir des spawns
			for (new player=1; player<=_maxClients; player++)
			{
				if (IsClientInGame(player) && GetClientTeam(player) == TEAM_INFECTED && player != _directorID && !StrEqual(_spawnCommand[player],"", false))
				{																		  
					PrintHintText(player, _HD_INFECTED_CAN_SPAWN, _directorActionNom[findIndexInSpawnArray(_spawnCommand[player])]);
				}
			}
			
			
			// Si le director n'a pas encore ouvert une seule fois le menu, l'avertir de la commande.
			if(_menuDejaOuvert == false)
			{
				PrintHintText(_directorID, _HD_WELCOME_DIRECTOR);
			}
		}
		else
		{
			// Prevenir du manque du director (information court : tout les secondes)
			afficherTexteAEquipe(TEAM_INFECTED, _HD_INFECTED_NEED_DIRECTOR, true, false);
		}
	}
}


// Informe les infectes/directors tout les 30 secondes.
public Action:informationLong(Handle:timer) 
{
	if(_pluginActiverModification)
	{
		if(_directorID != -1)
		{
			// Placé dans l'ordre d'importance
			
			// Infecte speciaux controlables
			if(_problemeSpawnSpecial == true)
			{
				PrintHintText(_directorID, _HD_PROBLEM_SPAWN_SPECIAL);
				
				// Forcer le spawn (toutes les 30 secondes apres une minute d inactivité)
				if(GetConVarInt(_cvForceSpawn))
				{
					forceSpawnSpecial();
				}
			}
			else
			{
				_problemeSpawnSpecial = true;
				
				// Pas de probleme a spawn les speciaux controlables ==> Spawn infecte NPC
				if(_problemeSpawn == true)
				{
					PrintHintText(_directorID, _HD_PROBLEM_SPAWN);
				}
				else
				{
					_problemeSpawn = true;
					
					// Pas de probleme de spawn d'infecte NPC ==> Nombre d'infectes sur le terrain
					if(_spawnLimitNumberActuel <= 5)
					{
						PrintHintText(_directorID, _HD_WARN_NO_ZOMBIZ);
					}
				}
			}
			
		}
		else
		{
			_problemeSpawn = false;
			_problemeSpawnSpecial = false;
		}	
	}
}  


// Kicker le tank gérer par le Director AI (au bout de 5 secondes aprés son spawn)
public Action:kickTankBot(Handle:timer) 
{
	if(_pluginActiverModification)
	{
		ServerCommand("kick Tank");
	}
}
