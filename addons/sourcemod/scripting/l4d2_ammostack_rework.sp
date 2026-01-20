#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>

#define sColor   "255,255,255"
#define sColor_Warning   "50,255,50"

public Plugin myinfo =
{
	name = "Ammo Stack Rework",
	author = "bullet28, edited by Shadow",
	description = "Creates ammo piles where upgrade packs are deployed and allows pickup for grenade launcher",
	version = "1",
	url = ""
}

// List of ammo models
#define MODEL_AMMO1 "models/props/terror/ammo_stack.mdl"
#define MODEL_AMMO2 "models/props_unique/spawn_apartment/coffeeammo.mdl"
#define GrabbedAmmo "ui/gift_pickup.wav"

public void OnMapStart() {
	if (!IsModelPrecached(MODEL_AMMO1)) PrecacheModel(MODEL_AMMO1);
	if (!IsModelPrecached(MODEL_AMMO2)) PrecacheModel(MODEL_AMMO2);
	PrecacheSound(GrabbedAmmo);
}

public OnPluginStart() {
}

public void OnEntityCreated(int entity, const char[] classname) {
	if (StrContains(classname, "upgrade_ammo_") != -1) {
		SDKHook(entity, SDKHook_SpawnPost, OnPostUpgradeSpawn);
	}
	if (StrEqual(classname, "upgrade_ammo_explosive")) {
		SDKHook(entity, SDKHook_Use, OnUpgradeUse);
	}
}

public Action OnUpgradeUse(int entity, int activator, int caller, UseType type, float value) {
	if (!isValidEntity(entity)) return Plugin_Continue;

	int client = caller;
	new weaponIndex = GetPlayerWeaponSlot(client, 0);
	if(weaponIndex == -1) return Plugin_Continue;

	char classname[64];
	GetEdictClassname(weaponIndex, classname, sizeof(classname));

	float positionVector[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", positionVector);

	// Only the grenade launcher
	if(StrEqual(classname, "weapon_grenade_launcher")) {
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

	int ammoStack = CreateEntityByName("weapon_ammo_spawn");
	if (ammoStack <= 0) return;

	DispatchKeyValue(ammoStack, "targetname", "ammoStack_explosive");

	origin[0] -= 10.0;
	origin[1] -= 10.0;
	TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);

	origin[0] += 20.0;
	origin[1] += 20.0;
	TeleportEntity(ammoStack, origin, NULL_VECTOR, NULL_VECTOR);

	// Modelo aleatorio
	switch(GetRandomInt(1,2)) {
		case 1: SetEntityModel(ammoStack, MODEL_AMMO1);
		case 2: SetEntityModel(ammoStack, MODEL_AMMO2);
	}

	DispatchSpawn(ammoStack);

	// Glowing effect
	SetEntProp(ammoStack, Prop_Send, "m_CollisionGroup", 0);
	SetEntProp(ammoStack, Prop_Send, "m_nGlowRange", 500);
	SetEntProp(ammoStack, Prop_Send, "m_iGlowType", 3);
	SetEntProp(ammoStack, Prop_Send, "m_glowColorOverride", sColor);
	SetEntProp(ammoStack, Prop_Send, "m_bFlashing", 0);
	AcceptEntityInput(ammoStack, "StartGlowing");

	CreateTimer(17.0, Timer_DesintegrateAmmoStack, ammoStack);
	CreateTimer(1.0, Timer_StartGlowEffect, ammoStack);
}

public Action:Timer_DesintegrateAmmoStack(Handle timer, ammoStack) {
	if (IsValidEntity(ammoStack)) {
		float origin[3];
		GetEntPropVector(ammoStack, Prop_Send, "m_vecOrigin", origin);
		L4D_Dissolve(ammoStack);
	}
	return Plugin_Stop;
}

public Action:Timer_StartGlowEffect(Handle timer, ammoStack) {
	if (!IsValidEntity(ammoStack)) return Plugin_Continue;

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
