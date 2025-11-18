#if defined _left4dragokas_included
 #endinput
#endif
#define _left4dragokas_included

/* ============================================================================
		Constants
============================================================================ */

#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

enum // ZOMBIECLASS
{
	ZOMBIECLASS_TANK_L4D1 = 5,
	ZOMBIECLASS_TANK_L4D2 = 8,
	ZOMBIECLASS_SMOKER = 1,
	ZOMBIECLASS_BOOMER = 2,
	ZOMBIECLASS_HUNTER = 3,
	ZOMBIECLASS_SPITTER = 4,
	ZOMBIECLASS_JOCKEY = 5,
	ZOMBIECLASS_CHARGER = 6
}

enum // DOOR_TYPE
{
	DOOR_TYPE_SAFEROOM = 1,
	DOOR_TYPE_FINAL
}

enum // DOOR_STATE
{
	DOOR_STATE_OPENING = 1,
	DOOR_STATE_CLOSING,
	DOOR_STATE_BLOCKED
}

/* ============================================================================
		Forwards
============================================================================ */

/**
 * Called whenever somebody used the saferoom or final door.
 *
 * @param doorEntity	Entity index of the door.
 * @param doorType		See DOOR_TYPE enum.
 * @param iCount		see DOOR_STATE enum.
 *
 * @noreturn
 */
forward void OnDoorUsed(int doorEntity, int /* DOOR_TYPE */ doorType, int /* DOOR_STATE */ doorState);

/**
 * Called when the number of tanks on the map is changed.
 * Note: it is not raised with zero value on round start.
 *
 * @param iCount		New number of tanks.
 *
 * @noreturn
 */
forward void OnTankCountChanged(int iCount);

/**
 * Called when the total number of tanks spawned during this round is changed.
 *
 * @param iCount		New number of tanks.
 *
 * @noreturn
 */
forward void OnTankCountSpawnedPerRoundChanged(int iCount);

/* ============================================================================
		Usefull stocks
============================================================================ */

stock bool IsPlayerIncapped(int client)
{
	if( GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) ) return true;
	return false;
}

stock bool IsClientRootAdmin(int client)
{
	return ((GetUserFlagBits(client) & ADMFLAG_ROOT) != 0);
}

stock bool IsPlayerPinned(int client)
{
	return GetPwnInfected(client) > 0;
}

stock int GetPwnInfected(int client)
{
	static bool L4D2;
	static EngineVersion engine;
	if( engine == Engine_Unknown )
	{
		engine = GetEngineVersion();
		L4D2 = engine == Engine_Left4Dead2;
	}
	int attacker;
	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker")) > 0 )
		return attacker;
	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner")) > 0 )
		return attacker;
	if( L4D2 )
	{
		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker")) > 0 )
			return attacker;
		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker")) > 0 )
			return attacker;
	}
	return 0;
}

stock void ForcePanicEvent(int client)
{
	char[] command = "director_force_panic_event";
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s", command);
	SetCommandFlags(command, flags);
}

stock int SpawnInfectedAt(float position[3], char[] sClass)
{
	int spawner = CreateEntityByName("commentary_zombie_spawner");
	if( spawner != -1 )
	{
		DispatchSpawn(spawner);
		ActivateEntity(spawner);
		DispatchKeyValue(spawner, "targetname", "drago_spawner");
		TeleportEntity(spawner, position, view_as<float>({0.0, 90.0, 0.0}), NULL_VECTOR);
		SetVariantString("OnSpawnedZombieDeath !self:Kill::5:-1");
		AcceptEntityInput(spawner, "AddOutput");
		SetVariantString(sClass);
		AcceptEntityInput(spawner, "SpawnZombie");
	}
	return spawner;
}

stock bool IsCommonInfected(int entity)
{
	if( GetEntProp(entity, Prop_Data, "m_iHammerID") == 66260 )
		return false;

	return true;
}

stock bool IsSurvivor(int client)
{
	return ( 0 < client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 );
}

stock bool IsWitch(int iEntity)
{
	if( iEntity && iEntity != -1 && IsValidEntity(iEntity) )
	{
		static char sClassname[32];
		GetEntityClassname(iEntity, sClassname, sizeof(sClassname));
		return strcmp(sClassname, "witch") == 0;
	}
	return false;
}

stock int GetCommonsCount()
{
	int ent = -1;
	int cnt;
	while( -1 != (ent = FindEntityByClassname(ent, "infected")))
	{
		cnt++;
	}
	return cnt;
}

stock void Chase(int target)
{
	bool bTeleported;
	float vPos[3];
	static int iChase = INVALID_ENT_REFERENCE;
	
	GetClientEyePosition(target, vPos);
	
	int entity = EntRefToEntIndex(iChase);
	if( !entity || entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity) )
	{
		entity = FindEntityByClassname(MaxClients + 1, "info_goal_infected_chase");
		if( !entity || entity == INVALID_ENT_REFERENCE )
		{
			entity = CreateEntityByName("info_goal_infected_chase");
			if( entity != -1 )
			{
				TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(entity);
				iChase = EntIndexToEntRef(entity);
				bTeleported = true;
			}
		}
	}
	if( entity != -1 )
	{
		if( !bTeleported )
		{
			AcceptEntityInput(entity, "Disable");
			AcceptEntityInput(entity, "ClearParent");
			TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		}
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", target);
		AcceptEntityInput(entity, "Enable");
	}
}

stock bool IsTank(int client)
{
	static int ZOMBIECLASS_TANK;
	if( ZOMBIECLASS_TANK == 0 )
	{
		ZOMBIECLASS_TANK = GetEngineVersion() == Engine_Left4Dead2 ? ZOMBIECLASS_TANK_L4D2 : ZOMBIECLASS_TANK_L4D1;
	}
	
	if( 1 <= client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		if( ZOMBIECLASS_TANK == GetEntProp(client, Prop_Send, "m_zombieClass") )
			return true;
	}
	return false;
}

stock bool IsBoomer(int client)
{
	if( 1 <= client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		if( ZOMBIECLASS_BOOMER == GetEntProp(client, Prop_Send, "m_zombieClass") )
			return true;
	}
	return false;
}

stock bool IsSmoker(int client)
{
	if( 1 <= client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		if( ZOMBIECLASS_SMOKER == GetEntProp(client, Prop_Send, "m_zombieClass") )
			return true;
	}
	return false;
}

stock bool IsHunter(int client)
{
	if( 1 <= client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		if( ZOMBIECLASS_HUNTER == GetEntProp(client, Prop_Send, "m_zombieClass") )
			return true;
	}
	return false;
}

stock bool IsCharger(int client)
{
	if( 1 <= client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		if( ZOMBIECLASS_CHARGER == GetEntProp(client, Prop_Send, "m_zombieClass") )
			return true;
	}
	return false;
}

stock bool IsJockey(int client)
{
	if( 1 <= client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		if( ZOMBIECLASS_JOCKEY == GetEntProp(client, Prop_Send, "m_zombieClass") )
			return true;
	}
	return false;
}

stock bool IsSpitter(int client)
{
	if( 1 <= client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		if( ZOMBIECLASS_SPITTER == GetEntProp(client, Prop_Send, "m_zombieClass") )
			return true;
	}
	return false;
}

stock bool IsValidEntRef(int entity)
{
	if( entity && entity != -1 && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}