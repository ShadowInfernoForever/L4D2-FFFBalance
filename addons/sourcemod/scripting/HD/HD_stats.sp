new _nbNormalInfectedSpawned = 0;
new _nbHuntersSpawned = 0;
new _nbSmokersSpawned = 0;
new _nbBoomersSpawned = 0;

public addSpawnToStats(String:cmdact[])
{
  if(StrEqual(cmdact, "z_spawn", false))
  {
    _nbNormalInfectedSpawned++;
  }
  else if(StrEqual(cmdact, "z_spawn hunter", false))
  {
    _nbHuntersSpawned++;
  }
  else if(StrEqual(cmdact, "z_spawn smoker", false))
  {
    _nbSmokersSpawned++;
  }
  else if(StrEqual(cmdact, "z_spawn boomer", false))
  {
    _nbBoomersSpawned++;
  }
}

public initStats()
{
	_nbNormalInfectedSpawned = 0;
	_nbHuntersSpawned = 0;
	_nbSmokersSpawned = 0;
	_nbBoomersSpawned = 0;
}

public displayStats()
{
  new String:name[32];
  GetClientName(_directorID, name, sizeof(name));
  //Stats
 // PrintToChatAll(_HD_STATS_TITLE);
 //PrintToChatAll(_HD_GAME_DIRECTED_BY, name);
 // PrintToChatAll(_HD_NB_NORMAL_INFECTED, _nbNormalInfectedSpawned);
 // PrintToChatAll(_HD_NB_HUNTERS, _nbHuntersSpawned);
 // PrintToChatAll(_HD_NB_SMOKERS, _nbSmokersSpawned);
 // PrintToChatAll(_HD_NB_BOOMERS, _nbBoomersSpawned);
}
