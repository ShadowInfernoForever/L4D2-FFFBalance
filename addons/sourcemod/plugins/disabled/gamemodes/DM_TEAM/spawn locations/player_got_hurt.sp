public Action:Player_Got_Hurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new player_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));		//This will return ClientID
	new player_victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon))
	//PrintToChatAll("Attacker Client Id is %i and Victim Client id is %i", player_attacker, player_victim);
	if (	(IsValidClient(player_attacker)) && (GetClientTeam(player_attacker) == TEAM_SURVIVOR) && (IsPlayerAlive(player_attacker)) && (!IsFakeClient(player_attacker)) )
	{
		if (IsPlayerAlive(player_victim))
		{
			new victim_health = GetClientHealth(player_victim);
			new Float:victim_temp_health = GetEntPropFloat(player_victim, Prop_Send, "m_healthBuffer");
			if (victim_health > 12)
			{
				SetEntityHealth(player_victim, (victim_health -12));
			}
			else if ( (victim_health > 1) && (victim_health <= 12) )
			{
				SetEntityHealth(player_victim, 1);
				//DamageEffect(player_victim);
				//FakeClientCommand(player_victim, "sm_slay #%i", player_attacker);
			}
			
			
			if (victim_temp_health > 12)
			{
				SetEntPropFloat(player_victim, Prop_Send, "m_healthBuffer", (victim_temp_health -12));
				//SetEntityHealth(player_victim, (victim_temp_health -12));
			}
			else if ( (victim_temp_health > 1) && (victim_temp_health <= 12) )
			{
				SetEntPropFloat(player_victim, Prop_Send, "m_healthBuffer", 1.0);
				//FakeClientCommand(player_victim, "sm_slay #%i", player_attacker);
				//DamageEffect(player_victim);
				//SetEntityHealth(player_victim, 1);
			}
			
			
			//DamageEffect(player_victim);
		}
		//new victim_health = GetClientHealth(player_victim);
	}
}
