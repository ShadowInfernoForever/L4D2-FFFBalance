// HD_ressource.sp
// Regroupe les fonctions liées aux ressources
//////////


// Affiche les ressources
public ressourceAfficher()
{
	if (_directorID > 0)
	{
		PrintCenterText(_directorID, _HD_RESSOURCES_AMOUNT, _ressource);
	}
}


// Ajout des ressources
public ressourceAjout()
{
	new vie = 0;
	// On calcul les points de vies des survivants
	for (new player=1; player<=_maxClients; player++)
	{
		if (IsClientInGame(player) && GetClientTeam(player) == TEAM_SURVIVOR)
		{
			vie = vie + GetClientHealth(player);
		}
	}
	
	if(vie > 0) vie = vie / 2;
	new gainRessource = _baseRessource + vie;
	gainRessource = gainRessource / 10;
	gainRessource = gainRessource * RoundFloat(_timerTick);
	
	
	_ressource = _ressource + gainRessource;
		
	if(_ressource > _ressourceMax)
	{
		_ressource = _ressourceMax;
	}
}
