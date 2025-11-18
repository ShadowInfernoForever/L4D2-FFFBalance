// HD_startEndRound.sp
// Regroupe les fonctions de début et fin de rounds/maps.
//////////


// Debut d'un round.
public roundStart()
{
	setBackground(0);
	
	initStats();
	
	// On netoye les actions/ordres enregistrés dans les derniers rounds
	for(new i = 1; i <= _maxClients; i++)
	{
		_spawnCommand[i] = "";
	}
	//Reinitialisation des stats
	_nbNormalInfectedSpawned = 0;
	_nbHuntersSpawned = 0;
	_nbSmokersSpawned = 0;
	_nbBoomersSpawned = 0;
	
	// On reinitialise la variable _maxClients (en cas de modifications). Info : cette variable permet d'optimiser les boucles.
	_maxClients = GetMaxClients();
	
	testActivation();
	
	
	// Enfin, debut du round
	if(_pluginActiverModification)
	{
		if(GetConVarInt(_cvDebug)) PrintToServer(_HD_DEBUG_START_ROUND);
		//PrintToChatAll(_HD_WELCOME_START);
		//PrintToChatAll(_HD_WELCOME_NO_DIRECTOR);
	   
		initConVar(true);
		
		// On empeche le lame du Director en bloquant les gros spawn. Seul les infectés normaux peuvent etre spawn.
		_spawnLimitNumberActuel = 0;
		initSpawnLimit(false);
		
		_startUnFreeze = false;
		_directorID = -1;
		_roundStarted = false;
		
		
		_ressource = _baseRessource;
		freezeSurvivor(true);
		CreateTimer(_timerFreezeTimerAction, freezeTimerDebut);
	}
	else
	{
		// on remet en place la partie normal
		initConVar(false);
	}
}


// Fin du round.
public roundEnd()
{
	setBackground(0);
	
	displayStats();
  
	if(_pluginActiverModification)
	{
	   if(GetConVarInt(_cvDebug)) PrintToServer(_HD_DEBUG_END_ROUND);
	   
	   _directorID = -1;
	   _roundStarted = false;
   }
}
