// HD_BDD.sp
// Base de donnée. Regroupe les variables globaux et modifiables (en cas de réequilibrage par exemple)
//////////

//Variables Globaux
#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
new Handle:_hConvar = INVALID_HANDLE;
new Handle:_hBackground = INVALID_HANDLE;
new _maxClients = 0;


// Convars
new Handle:_cvDebug = INVALID_HANDLE;
new Handle:_cvForceSpawn = INVALID_HANDLE;


// Variable Timer
new Float:_timerTick = 5.0;
new Float:_timerUnFreezeUnLimit = 60.0;
new Float:_timerFreezeTimerAction = 10.0;
new Float:_timerReSpecialClassUniqueSpawn = 15.0;
new Float:_timerReHorde = 240.0;
new Float:_timerinformationLong = 30.0;
new Float:_timerCleanInfecte = 20.0;


// Activer/Desactiver
new bool:_pluginActiver = true; // Determiner si le plugin est activé ou non (attention : ce n'est pas à travers de cette variable que le plugin sera modifié ou non !)
new bool:_pluginActiverModification = true; // Le plugin sera modifié a travers de cette variable (qui dépendra des coop/versus, ainsi que de la variable d'au dessus). Il est modifié a chaque debut de round.


//Start/freeze
new bool:_startUnFreeze = false;
new bool:_roundStarted = false;


//Director
new _directorID = -1;


//Memoire spawn speciaux
new _idJoueurMemo = 1;
new _specialClassSpawn = 1; // 1 = hunter, 2 = smoker, 3 = boomer


//Gestion des spawns/cameras (lors d'un spawn)
new _joueurInfecte[4];
new Float:_joueurAngle[4][3];
new Float:_joueurPosition[4][3];


//Spawn Zombie/Speciaux
// Calculs : On a pris, comme base, un infecté normal avec un coût de 10. Sachant que le Director gagne en moyenne 200 res pour 10 secondes, et qu'il faut 30 secondes pour preparer un terrain, il aura donc 600 ressources à placer.
// Une zone est composé de 30 infecté (d'aprés AI Director) et de 3 spéciaux. 30*10 = 300. Il reste donc 300 ressources à placer pour les speciaux (donc 100 chacun).
// Les spawns de groupes coutent 20% plus cher. La horde, la witch, et le tank coutent moins cher (/2), car ils disposent d'une limite.
// Le prix de la witch et du tank dépend de leurs degats/hp/vitesse par rapport à un infecté normal.
new String:_directorActionNom[][]	= {"Infected"	, "10 infected"		, "Horde"						, "Special Group"		, "Hunter"			, "Smoker"			, "Boomer"			, "Charger"         , "jockey"         , "Spitter"         , "Witch"		  , "Tank"};
new String:_directorAction[][] 		= {"z_spawn"	, "spawn10Infected"	, "director_force_panic_event"	, "spawnGroupeSpecial"	, "z_spawn hunter" 	, "z_spawn smoker"	, "z_spawn boomer"  , "z_spawn charger" , "z_spawn jockey" , "z_spawn spitter" , "z_spawn witch" , "z_spawn tank"};
new bool:_directorActionIsSpecial[] = {false		, false				, false							, true			 		, true				, true 				, true				, true              , true             , true              , false			  , true};
new _directorCout[]					= {10			, 120				, 250							, 300					, 60				, 150				, 120				, 400               , 110              , 90                , 600			  , 1200};
new _nombreTypeSpawn = 9;


//Autorisations de spawn
new String:_spawnCommand[64][50];


//Spawn Limite
new _spawnLimitWitchMax = 1;
new _spawnLimitWitch = 1;
new _spawnLimitTankMax = 1;
new _spawnLimitTank = 1;
new bool:_spawnLimitHunter = true;
new bool:_spawnLimitSmoker = true;
new bool:_spawnLimitBoomer = true;
new bool:_spawnLimitHorde = true;
new _distanceStrictMinimum = 200;
new _distanceViseeMinimum = 500;
new _distancePositionMinimum = 200;
new _spawnLimitNumberMax = 60;
new _spawnLimitNumberActuel = 0;


// Ressource (pour 10 secondes)
// Ressources : 100 -> 300 (200 de base). Donc : 100 + (points de vies des survivants / 2).
new _ressource = 0;
new _baseRessource = 100; //
new _ressourceMax = 1200; //


//Informations Hint
new bool:_menuDejaOuvert = false;
new bool:_problemeSpawn = false;
new bool:_problemeSpawnSpecial = false;


//ConVar
new String:_nomConVar[][]	= {"director_no_bosses"	, "director_no_specials"	, "director_no_mobs" 	, "z_background_limit"};
new _valeurConVar[]  		= {0					, 0							, 0						, 10}
new _valeurConVarDefault[]  = {0					, 0							, 0						, 20};
new _nombreConVar = 4;
