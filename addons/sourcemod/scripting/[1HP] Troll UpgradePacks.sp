// [1HP] Troll UpgradePacks.sp

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MODEL_FIREWORKS "models/props_junk/explosive_box001.mdl"
#define MODEL_PROPANE   "models/props_junk/propanecanister001a.mdl"

ConVar g_hDelay;

public Plugin myinfo =
{
    name = "[1HP] Troll Upgrade Packs",
    author = "ShadowInferno",
    description = "Turns incendiary packs into fireworks and explosive packs into propane tanks that explode instantly.",
    version = "1.0",
    url = ""
};

public void OnPluginStart()
{
    g_hDelay = CreateConVar("ammo_upgrade_explode_delay", "0.1", "Delay before triggering explosion.", FCVAR_NOTIFY);

    PrecacheModel(MODEL_FIREWORKS, true);
    PrecacheModel(MODEL_PROPANE, true);
}

/* ---------------------------------------------------------
    ÚNICA FUNCIÓN OnEntityCreated — SIN CONFLICTOS
--------------------------------------------------------- */
public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity <= 0 || !IsValidEntity(entity))
        return;

    if (StrEqual(classname, "upgrade_ammo_incendiary"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawn_Incendiary);
    }
    else if (StrEqual(classname, "upgrade_ammo_explosive"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawn_Explosive);
    }
}

/* ---------------------------------------------------------
    SPAWN HOOKS → Cambian el upgrade por el prop
--------------------------------------------------------- */

public void OnSpawn_Incendiary(int entity)
{
    ReplaceUpgradePack(entity, MODEL_FIREWORKS);
}

public void OnSpawn_Explosive(int entity)
{
    ReplaceUpgradePack(entity, MODEL_PROPANE);
}

/* ---------------------------------------------------------
    Función que reemplaza el upgrade por el prop explosivo
--------------------------------------------------------- */

void ReplaceUpgradePack(int upgrade, const char[] newModel)
{
    if (!IsValidEntity(upgrade))
        return;

    float pos[3];
    GetEntPropVector(upgrade, Prop_Send, "m_vecOrigin", pos);

    // Remove original upgrade
    RemoveEdict(upgrade);

    // Create new prop
    int prop = CreateEntityByName("prop_physics");
    if (prop <= 0) return;

    DispatchKeyValue(prop, "model", newModel);
    DispatchSpawn(prop);
    TeleportEntity(prop, pos, NULL_VECTOR, NULL_VECTOR);

    // 0 HP so it breaks instantly
    SetEntProp(prop, Prop_Data, "m_iHealth", 0);

    // Trigger explosion after cvar delay
    float delay = g_hDelay.FloatValue;
    CreateTimer(delay, Timer_ExplodeEntity, prop);
}

/* ---------------------------------------------------------
    Timer que fuerza una explosión real
--------------------------------------------------------- */

public Action Timer_ExplodeEntity(Handle timer, int ent)
{
    if (!IsValidEntity(ent))
        return Plugin_Stop;

    // Multiple ways to force explosions depending on model
    AcceptEntityInput(ent, "Break");
    AcceptEntityInput(ent, "Ignite");
    AcceptEntityInput(ent, "Detonate");
    AcceptEntityInput(ent, "Explode");

    // Create an env_explosion for guaranteed boom
    float pos[3];
    GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);

    int boom = CreateEntityByName("env_explosion");
    if (boom > 0)
    {
        DispatchSpawn(boom);
        TeleportEntity(boom, pos, NULL_VECTOR, NULL_VECTOR);

        DispatchKeyValue(boom, "iMagnitude", "120");
        DispatchKeyValue(boom, "iRadiusOverride", "280");

        AcceptEntityInput(boom, "Explode");
        AcceptEntityInput(boom, "Kill");
    }

    return Plugin_Stop;
}
