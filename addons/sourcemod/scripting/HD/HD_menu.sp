// HD_menu.sp
// Regroupe les fonctions liées aux menus.
//////////


// Test des menus
public directorMenuTest(client)
{
	if(_directorID == client)
	{ 
		if(_menuDejaOuvert == false)
		{
			_menuDejaOuvert = true;
			afficherTexteAEquipe(TEAM_INFECTED, _HD_HELP_TEXT, true, true);
			PrintToChatAll(_HD_CAMERALIBRE);
			PrintToChatAll(_HD_CAMERALIBRE_DEUX);
		}
		
		menuDirector(client);
	}
	else
	{
		if(GetClientTeam(client) == TEAM_INFECTED)
		{
			if(_directorID == -1)
			{
				PrintToChat(client, _HD_DIRECTOR_NOT_ASSIGNED)
				actionSound(client, false);
			}
			else
			{
				new String:name[32]
				GetClientName(_directorID, name, sizeof(name))

				PrintToChat(client, _HD_YOU_ARE_NOT_DIRECTOR, name)
				actionSound(client, false);
			}
		}
		else
		{
			PrintToChat(client, _HD_NO_MENU_CAUSE_SURVIVOR)
			actionSound(client, false);
		}
	}
}


// Menu de base
public menuDirector(client)
{
	new Handle:menu = CreateMenu(menuBase);
	SetMenuTitle(menu, _HD_WELCOME_DIRECTOR_MENU);

	AddMenuItem(menu, "menuSpawn", _HD_MENU_SPAWN);
	AddMenuItem(menu, "directorDemission", _HD_DEMISSION);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 100);
	
}


public menuBase(Handle:menu, MenuAction:action, param1, param2)
{
	//param1 : Client
	//param2 : Numeros de l'objet de la liste
	//found : Si l'objet existe
	//info : Donnée de l'objet
	if (param1 == _directorID)
	{
		if (action == MenuAction_Select)
		{
			new String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			if(StrEqual(info, "menuSpawn", false))
			{
				menuSpawn(param1);
			}
			else if(StrEqual(info, "directorDemission", false))
			{
				directorDemission(param1);
			}
			else
			{
				menuDirector(param1);
			}
		}
		else if (action == MenuAction_End)
		{
			CloseHandle(menu);
		}
	}
}



// Menu d'invocation
public menuSpawn(client)
{
	new Handle:menu = CreateMenu(menuBaseSpawn);
	SetMenuTitle(menu, _HD_MENU_SPAWN);

	for(new num=0; num < _nombreTypeSpawn; num++)
	{
		new String:info[32];
		IntToString(num, info, sizeof(info));
		
		new String:prix[10];
		new String:affichage[32];
		new String:chardeb[] = " (";
		new String:charfin[] = ")";
		
		IntToString(_directorCout[num], prix, sizeof(prix));
		strcopy(affichage, sizeof(affichage), _directorActionNom[num]);
		StrCat(affichage, sizeof(affichage), chardeb);
		StrCat(affichage, sizeof(affichage), prix);
		StrCat(affichage, sizeof(affichage), charfin);

		AddMenuItem(menu, info, affichage);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 100);
}


public menuBaseSpawn(Handle:menu, MenuAction:action, param1, param2)
{
	if (param1 == _directorID)
	{
		if (action == MenuAction_Select)
		{	
			new String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			new num = StringToInt(info);
			
			if(_directorActionIsSpecial[num])
			{
				rouletteSpawnJoueur(num);
				menuSpawn(param1);
			}
			else
			{
				directorSpawn(param1, num);
				menuSpawn(param1);
			}
		}
		else if (action == MenuAction_End)
		{
			CloseHandle(menu);
		}
	}
}
