// HD_convar.sp
// Regroupe les fonctions liées aux modifications des variables et convars
//////////


// Background à 0 ou 1 (spawné sur toute la map ou non)
public setBackground(num)
{
	if(GetConVarInt(_cvDebug)) PrintToServer("DEBUG[HUMAN DIRECTOR] - BackGround a %i", num);
	SetConVarInt(_hBackground, num);
}


// Initialisation des convar
public initConVar(bool:activer)
{
	for(new num = 0; num < _nombreConVar; num++)
	{
		_hConvar = FindConVar(_nomConVar[num]);
		if(activer == true) SetConVarInt(_hConvar, _valeurConVar[num]);
		else  SetConVarInt(_hConvar, _valeurConVarDefault[num]);
	}
}


// Limit de spawn
public initSpawnLimit(bool:activer)
{
	if(activer == true)
	{
		_spawnLimitWitch = _spawnLimitWitchMax;
		_spawnLimitTank = _spawnLimitTankMax;
		_spawnLimitHorde = true;
		_spawnLimitHunter = true;
		_spawnLimitSmoker = true;
		_spawnLimitBoomer = true;
	}
	else
	{
		_spawnLimitWitch = 0;
		_spawnLimitTank = 0;
		_spawnLimitHorde = false;
		_spawnLimitHunter = false;
		_spawnLimitSmoker = false;
		_spawnLimitBoomer = false;
	}
}


// Remettre en place les convar si le sv_cheats est a 0.
public testSvCheatsReset()
{
	_hConvar = FindConVar("sv_cheats");
	new cheat = GetConVarInt(_hConvar); // 0 = no cheat, donc devra preciser un NOT lors du test
	
	if(_pluginActiverModification && !cheat)
	{
		initConVar(true);
	}
}