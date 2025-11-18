#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>

#define sColor   "255,255,255"
#define sColor_Warning   "50,255,50"

#define MAX_SAFEROOMS 10
#define SAFEROOM_DISTANCE_THRESHOLD 500.0

public Plugin myinfo =
{
	name = "Ammo Stack Rework",
	author = "bullet28, edited by ShadowInferno",
	description = "Creates ammo pile at the place where the upgrade pack was deployed, also you can now pickup bullets for the m60 and grenade launcher with explosive ammo",
	version = "1",
	url = ""
}

// List of ammo models
#define MODEL_AMMO1 "models/props/terror/ammo_stack.mdl"
#define MODEL_AMMO2 "models/props_unique/spawn_apartment/coffeeammo.mdl"
#define GrabbedAmmo "ui/gift_pickup.wav"

new bool:bM60Patch = false;
new Address:patchAddr;
new savedBytes[2];
new iOffset;

float g_SaferoomPositions[MAX_SAFEROOMS][3];
int g_SaferoomCount = 0;

public void OnMapStart() {
	if (!IsModelPrecached(MODEL_AMMO1)) {
		PrecacheModel(MODEL_AMMO1);
	}
	if (!IsModelPrecached(MODEL_AMMO2)) {
		PrecacheModel(MODEL_AMMO2);
	}
	PrecacheSound(GrabbedAmmo);

	// Find and store saferoom positions
    g_SaferoomCount = 0;

    for (int i = 0; i < GetMaxEntities(); i++) {
        if (!IsValidEdict(i)) continue;

        char classname[64];
        GetEdictClassname(i, classname, sizeof(classname));

        // Example: Find saferoom doors or trigger entities
        if (StrEqual(classname, "prop_door_rotating_checkpoint")) {
            float origin[3];
            GetEntPropVector(i, Prop_Send, "m_vecOrigin", origin);

            if (g_SaferoomCount < MAX_SAFEROOMS) {
                g_SaferoomPositions[g_SaferoomCount][0] = origin[0];
                g_SaferoomPositions[g_SaferoomCount][1] = origin[1];
                g_SaferoomPositions[g_SaferoomCount][2] = origin[2];
                g_SaferoomCount++;
            }
        }
    }
}

public OnPluginStart()
{
	//HookEvent("ammo_pile_weapon_cant_use_ammo", OnWeaponDosntUseAmmo, EventHookMode_Pre);
	PatchM60Drop();
}

public OnPluginEnd()
{
	UnPatchM60Drop();
}

public void OnEntityCreated(int entity, const char[] classname) {
	if (StrContains(classname, "upgrade_ammo_") != -1) {
		SDKHook(entity, SDKHook_SpawnPost, OnPostUpgradeSpawn);
	}
	if  (StrEqual(classname, "upgrade_ammo_explosive")) {
		SDKHook(entity, SDKHook_Use, OnUpgradeUse);
	}
	if  (StrEqual(classname, "weapon_ammo_spawn")) {
		SDKHook(entity, SDKHook_Use, OnUsePost);
	}
}

public Action OnUpgradeUse(int entity, int activator, int caller, UseType type, float value) {
	if (!isValidEntity(entity)) return Plugin_Continue;

    int client = caller;
	new weaponIndex = GetPlayerWeaponSlot(client, 0);
	
	if(weaponIndex == -1)
		return Plugin_Continue;
	
	new String:classname[64];
	
	GetEdictClassname(weaponIndex, classname, sizeof(classname));

	float positionVector[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", positionVector);
	
	if(StrEqual(classname, "weapon_grenade_launcher"))
	{
		new iClip1 = GetEntProp(weaponIndex, Prop_Send, "m_iClip1");
		new iPrimType = GetEntProp(weaponIndex, Prop_Send, "m_iPrimaryAmmoType");
		
		SetEntProp(client, Prop_Send, "m_iAmmo", ((30+1)-iClip1), _, iPrimType);

		EmitAmbientSound(GrabbedAmmo, positionVector, client, SNDLEVEL_NORMAL);

		RemoveEdict(entity);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnPostUpgradeSpawn(int entity) {
	if (!isValidEntity(entity)) return;

	char classname[32];
	GetEdictClassname(entity, classname, sizeof(classname));
	if (StrContains(classname, "upgrade_ammo_") == -1) return;

	float origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);

	// Check distance to saferooms
    for (int i = 0; i < g_SaferoomCount; i++) {
        float distance = GetVectorDistanceCustom(origin, g_SaferoomPositions[i]);
        if (distance < SAFEROOM_DISTANCE_THRESHOLD) {
            LogMessage("Prevented ammo spawn near saferoom at distance %.2f", distance);
            return;
        }
    }

	int ammoStack = CreateEntityByName("weapon_ammo_spawn");
	if (ammoStack <= 0) return;

	DispatchKeyValue(ammoStack, "targetname", "ammoStack_explosive");
	
	origin[0] -= 10.0;
	origin[1] -= 10.0;
	TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);

	origin[0] += 20.0;
	origin[1] += 20.0;
	TeleportEntity(ammoStack, origin, NULL_VECTOR, NULL_VECTOR);

	// Randomly select a model
	int randomModel = GetRandomInt(1, 2);
	switch (randomModel) {
		case 1:
			SetEntityModel(ammoStack, MODEL_AMMO1);
		case 2:
			SetEntityModel(ammoStack, MODEL_AMMO2);
	}

	DispatchSpawn(ammoStack);

	// Set glowing effect properties
	SetEntProp(ammoStack, Prop_Send, "m_CollisionGroup", 0);
	SetEntProp(ammoStack, Prop_Send, "m_nGlowRange", 500);
	SetEntProp(ammoStack, Prop_Send, "m_iGlowType", 3);
	SetEntProp(ammoStack, Prop_Send, "m_glowColorOverride", sColor);
	SetEntProp(ammoStack, Prop_Send, "m_bFlashing", 0);
	AcceptEntityInput(ammoStack, "StartGlowing");

	SDKHook(ammoStack, SDKHook_UsePost, OnUsePost);

	// Start timers
	CreateTimer(17.0, Timer_DesintegrateAmmoStack, ammoStack); // 17 sec until desintegration
	CreateTimer(1.0, Timer_StartGlowEffect, ammoStack); // 1 sec to give info about the stuff
}

void OnUsePost(int entity, int activator, int caller, UseType type, float value)
{
	int client = caller;
	new weapon = GetPlayerWeaponSlot(client, 0);

    if(weapon == -1)
		return;

	new String:classname[64];

	float positionVector[3];
        GetEntPropVector(weapon, Prop_Send, "m_vecOrigin", positionVector);

    GetEdictClassname(weapon, classname, sizeof(classname));
	if( StrEqual(classname, "weapon_rifle_m60") )
	{
		new iClip1 = GetEntProp(weapon, Prop_Send, "m_iClip1");
		new iPrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
		
		SetEntProp(client, Prop_Send, "m_iAmmo", ((50+100)-iClip1), _, iPrimType);

		EmitAmbientSound(GrabbedAmmo, positionVector, client, SNDLEVEL_NORMAL);

		// Mm... interesting idea, i may change opinion later, i don't know
		//RemoveEntity(entity);
	}
}


public Action:Timer_DesintegrateAmmoStack(Handle timer, ammoStack) {
    if (IsValidEntity(ammoStack)) {
        // Get the origin of the ammo stack
        float origin[3];
        GetEntPropVector(ammoStack, Prop_Send, "m_vecOrigin", origin);

        // Remove the ammo stack with cool effect
        L4D_Dissolve(ammoStack);
    }
    return Plugin_Stop;
}

public Action:Timer_StartGlowEffect(Handle timer, ammoStack) {
	if (IsValidEntity(ammoStack)) {
		SetEntProp(ammoStack, Prop_Send, "m_bFlashing", 1);

	int iEntity = CreateEntityByName("env_instructor_hint"); 
 
    DispatchKeyValue(iEntity, "hint_target", "ammoStack_explosive"); 
    DispatchKeyValue(iEntity, "hint_static", "0"); 
    DispatchKeyValue(iEntity, "hint_timeout", "10");  
    DispatchKeyValue(iEntity, "hint_nooffscreen", "0"); 
    DispatchKeyValue(iEntity, "hint_icon_offscreen", "icon_interact"); 
    DispatchKeyValue(iEntity, "hint_icon_onscreen", "icon_interact"); 
    DispatchKeyValue(iEntity, "hint_forcecaption", "1"); 
    DispatchKeyValue(iEntity, "hint_color", "150, 150, 150"); 
    DispatchKeyValue(iEntity, "hint_caption", " "); 
     
    DispatchSpawn(iEntity); 
    AcceptEntityInput(iEntity, "ShowHint");

	CreateTimer(10.0, DestroyInstructor, iEntity);

	}
	return Plugin_Continue;
}

bool isValidEntity(int entity) {
	return entity > 0 && entity <= 2048 && IsValidEdict(entity) && IsValidEntity(entity);
}

public Action DestroyInstructor(Handle Timer, int iEntity) {

    if(IsValidEdict(iEntity)) {
        AcceptEntityInput(iEntity, "Disable");
        AcceptEntityInput(iEntity, "Kill");
    }

    return Plugin_Continue;
}

stock PatchM60Drop()
{
	if(!bM60Patch)
	{
		new Handle:conf = LoadGameConfigFile("l4d2m60-patch.games");
		
		if(conf == INVALID_HANDLE)
		{
			LogError("Could not locate l4d2m60-patch.games gamedata");
			return;
		}
		
		patchAddr = GameConfGetAddress(conf, "CRifleM60::PrimaryAttack");
		iOffset = GameConfGetOffset(conf, "PrimaryAttackOffset");
		
		if(iOffset == -1)
		{
			LogError("Failed to get PrimaryAttackOffset");
		}
		else if(!patchAddr)
		{
			LogError("Failed to get Address");
		}
		else if(LoadFromAddress(patchAddr+Address:iOffset, NumberType_Int8) == 0x0F)
		{
			//Two byte jump
			savedBytes[0] = LoadFromAddress(patchAddr+Address:iOffset, NumberType_Int8);
			savedBytes[1] = LoadFromAddress(patchAddr+Address:(1+iOffset), NumberType_Int8);
			StoreToAddress(patchAddr+Address:iOffset, 0x90, NumberType_Int8);
			StoreToAddress(patchAddr+Address:(1+iOffset), 0xE9, NumberType_Int8);
		}
		else if(LoadFromAddress(patchAddr+Address:iOffset, NumberType_Int8) == 0x75 || LoadFromAddress(patchAddr+Address:iOffset, NumberType_Int8) == 0x74)
		{
			//One byte jump
			savedBytes[0] = LoadFromAddress(patchAddr+Address:iOffset, NumberType_Int8);
			StoreToAddress(patchAddr+Address:iOffset, 0xEB, NumberType_Int8);
		}
		else
		{
			LogError("Failed to patch M60 Drop invalid patch Address");
		}
		
		CloseHandle(conf);
	}
}
stock UnPatchM60Drop()
{
	if(!bM60Patch)
	{
		if(savedBytes[0] == 0x0F)
		{
			//Two byte jump
			StoreToAddress(patchAddr+Address:iOffset, savedBytes[0], NumberType_Int8);
			StoreToAddress(patchAddr+Address:(1+iOffset), savedBytes[1], NumberType_Int8);
		}
		else if(savedBytes[0] == 0x75 || savedBytes[0] == 0x74)
		{
			//One byte jump
			StoreToAddress(patchAddr+Address:iOffset, savedBytes[0], NumberType_Int8);
		}
	}
}

float GetVectorDistanceCustom(const float vec1[3], const float vec2[3]) {
    float dx = vec1[0] - vec2[0];
    float dy = vec1[1] - vec2[1];
    float dz = vec1[2] - vec2[2];

    return SquareRoot(dx * dx + dy * dy + dz * dz);
}