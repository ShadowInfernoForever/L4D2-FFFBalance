#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define COLLISION_GROUP_DEBRIS_TRIGGER 2

public Plugin myinfo =
{
    name = "L4D2 Molotov 100 tickrate fix",
    author = "Shadow",
    description = "Fixes molotov getting stuck in a common infected",
    version = "1.0",
    url = ""
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "molotov_projectile"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnPostMolotovSpawn);
    }
}

public void OnPostMolotovSpawn(int entity)
{
    // Set collision group to allow passing through common infected
    SetEntProp(entity, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS_TRIGGER);

    // Optionally modify physics flags for better behavior
    SetEntProp(entity, Prop_Data, "m_fFlags", GetEntProp(entity, Prop_Data, "m_fFlags") | 1 << 10); // Modify flags (this might vary for L4D2)
}