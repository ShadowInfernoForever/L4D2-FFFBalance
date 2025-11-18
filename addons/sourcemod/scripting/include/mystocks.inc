
#if defined _mystocks_included_
	#endinput
#endif
#define _mystocks_included_

/******************************************************************************
                   STOCKS
******************************************************************************/


/**
* Checks several parameters to see if the specified client is a valid user.
*
* @param client index
* @param Allow bots? (False)
* @param Allow dead? (True)
* @return true if valid
*/
stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}

/**
* Checks all players on the server to find the closest match of the argument.
*
* @param The argument number to fetch name from. From 1 and up!
* @param client index of the command executor
* @return client index of the most suitable target
*/
stock int GetTargetFromArg(int argument, int client) {
	char arg[64];
	GetCmdArg(argument, arg, sizeof(arg));
	
	int finalTarget;
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if((target_count = ProcessTargetString(arg, client, target_list, sizeof(target_list), COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
		return false;
	}
	
	for(int usr = 0; usr < target_count; usr++) {
		if(!IsValidClient(target_list[usr]))
			continue;
		finalTarget = target_list[usr];
	}
	
	return finalTarget;
}