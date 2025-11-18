#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <l4d2util>
#undef REQUIRE_PLUGIN
#include <l4d2_lagcomp_manager>

#define PLUGIN_VERSION "1.0"
#define GIVE_RANGE 150.0
#define HINT_TIMEOUT 8.0

public Plugin myinfo =
{
    name = "Incap Pill/Adrenaline Pass & Drop",
    author = "Shadow + Adapted from Pill Passer",
    description = "Allows incapacitated players to give pills/adrenaline to a teammate or drop them on the ground",
    version = PLUGIN_VERSION,
    url = ""
};

// Track last button state
static int lastButtons[MAXPLAYERS+1];
static int g_iPasser = -1;

// ------------------------- PLUGIN START -------------------------
public void OnPluginStart()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
            SDKHook(i, SDKHook_PostThinkPost, OnPostThink);
    }
}

public void OnClientPutInServer(int client)
{
    if (!IsFakeClient(client))
        SDKHook(client, SDKHook_PostThinkPost, OnPostThink);
}

// ------------------------- POST THINK -------------------------
// Handles giving or dropping pills/adrenaline when incapacitated
public void OnPostThink(int client)
{
    if (!IsValidClient(client) || !IsPlayerIncap(client))
        return;

    int buttons = GetClientButtons(client);
    int pressed = buttons & ~lastButtons[client];
    lastButtons[client] = buttons;

    // Only respond to Mouse3 (IN_ZOOM)
    if (!(pressed & IN_ZOOM))
        return;

    // Slot 4 = pills/adrenaline
    int itemSlot = GetPlayerWeaponSlot(client, 4);
    if (itemSlot == -1 || !IsValidEntity(itemSlot))
        return;

    char classname[64];
    GetEntityClassname(itemSlot, classname, sizeof(classname));

    if (!StrEqual(classname, "weapon_adrenaline", false) &&
        !StrEqual(classname, "weapon_pain_pills", false))
        return;

    // Trace player in front
    int target = GetPlayerInFront(client, GIVE_RANGE);

    // Ignore self, incapacitated players, or players who already have pills/adrenaline
    if (IsValidClient(target) && target != client && !HasPillsOrAdrenaline(target) && !IsPlayerIncap(target))
    {
        // Start lag compensation if available
        if (LibraryExists("l4d2_lagcomp_manager"))
        {
            g_iPasser = client;
            L4D2_LagComp_StartLagCompensation(client, LAG_COMPENSATE_BOUNDS);
        }

        // Give item to target
        int newItem = GivePlayerItem(target, classname);
        if (newItem > 0)
        {
            RemovePlayerItem(client, itemSlot);

            // Fire event "weapon_given"
            Handle hFakeEvent = CreateEvent("weapon_given");
            SetEventInt(hFakeEvent, "userid", GetClientUserId(target));
            SetEventInt(hFakeEvent, "giver", GetClientUserId(client));
            SetEventString(hFakeEvent, "weapon_class", classname);
            SetEventInt(hFakeEvent, "weaponentid", newItem);
            FireEvent(hFakeEvent);

            // Show instructor hints for both players
            ShowInstructorHint(client, "You gave %s to %N", classname, target);
            ShowInstructorHint(target, "%N gave you %s", client, classname);
        }
        else
        {
            ShowInstructorHint(client, "Failed to give %s to %N", classname, target);
        }

        // Finish lag compensation
        if (g_iPasser == client)
        {
            L4D2_LagComp_FinishLagCompensation(client);
            g_iPasser = -1;
        }
    }
    else
    {
        // Drop item if no valid target
        DropItemIncap(client, classname);

        // Show instructor hint for the player
        ShowInstructorHint(client, "You dropped your %s", classname);
    }
}

// ------------------------- CHECK PLAYER STATUS -------------------------
bool HasPillsOrAdrenaline(int client)
{
    int slot = GetPlayerWeaponSlot(client, 4);
    if (slot == -1 || !IsValidEntity(slot))
        return false;

    char classname[64];
    GetEntityClassname(slot, classname, sizeof(classname));

    return (StrEqual(classname, "weapon_pain_pills", false) ||
            StrEqual(classname, "weapon_adrenaline", false));
}

bool IsPlayerIncap(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 1);
}

// ------------------------- TRACE PLAYER -------------------------
int GetPlayerInFront(int client, float distance)
{
    float eyePos[3], eyeAng[3], fwd[3], endPos[3];
    GetClientEyePosition(client, eyePos);
    GetClientEyeAngles(client, eyeAng);
    GetAngleVectors(eyeAng, fwd, NULL_VECTOR, NULL_VECTOR);

    endPos[0] = eyePos[0] + fwd[0] * distance;
    endPos[1] = eyePos[1] + fwd[1] * distance;
    endPos[2] = eyePos[2] + fwd[2] * distance;

    Handle trace = TR_TraceRayFilterEx(eyePos, endPos, MASK_SOLID, RayType_EndPoint, TraceFilterPlayers, client);
    int ent = TR_GetEntityIndex(trace);
    CloseHandle(trace);

    return (IsValidClient(ent) ? ent : -1);
}

public bool TraceFilterPlayers(int entity, int mask, any data)
{
    int client = data;
    if (!IsValidClient(entity) || entity == client)
        return false;

    return true;
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

// ------------------------- DROP ITEM -------------------------
public void DropItemIncap(int client, const char[] classname)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return;

    int slot = GetPlayerWeaponSlot(client, 4);
    if (slot == -1 || !IsValidEntity(slot))
        return;

    RemovePlayerItem(client, slot);

    float pos[3], ang[3], fwd[3];
    GetClientEyePosition(client, pos);
    GetClientEyeAngles(client, ang);
    GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);

    int ent = CreateEntityByName(classname);
    if (ent == -1) return;

    DispatchSpawn(ent);
    TeleportEntity(ent, pos, ang, NULL_VECTOR);

    float velocity[3];
    velocity[0] = fwd[0] * 400.0;
    velocity[1] = fwd[1] * 400.0;
    velocity[2] = fwd[2] * 200.0 + 150.0;
    SetEntPropVector(ent, Prop_Data, "m_vecVelocity", velocity);
}

// ------------------------- INSTRUCTOR HINT -------------------------
void ShowInstructorHint(int client, const char[] fmt, any data1 = -1, any data2 = -1)
{
    char text[128];
    char name1[64];
    char name2[64];

    // If data1 is a client index, get their name
    if (data1 != -1 && IsValidClient(data1))
        GetClientName(data1, name1, sizeof(name1));
    else
        strcopy(name1, sizeof(name1), "");

    // If data2 is a client index, get their name
    if (data2 != -1 && IsValidClient(data2))
        GetClientName(data2, name2, sizeof(name2));
    else
        strcopy(name2, sizeof(name2), "");

    // Format the text properly
    if (name1[0] != '\0' && name2[0] != '\0')
        Format(text, sizeof(text), fmt, name1, name2);
    else if (name1[0] != '\0')
        Format(text, sizeof(text), fmt, name1);
    else
        strcopy(text, sizeof(text), fmt);

    // Create the hint entity
    int iEntity = CreateEntityByName("env_instructor_hint");
    if (iEntity == -1) return;

    // Set target as the client
    char sClient[8];
    IntToString(client, sClient, sizeof(sClient));
    DispatchKeyValue(iEntity, "hint_target", sClient);

    // Set properties
    DispatchKeyValue(iEntity, "hint_static", "1");

    char sTimeout[8];
    Format(sTimeout, sizeof(sTimeout), "%.2f", HINT_TIMEOUT);
    DispatchKeyValue(iEntity, "hint_timeout", sTimeout);

    DispatchKeyValue(iEntity, "hint_nooffscreen", "1");
    DispatchKeyValue(iEntity, "hint_icon_offscreen", "icon_tip");
    DispatchKeyValue(iEntity, "hint_icon_onscreen", "icon_tip");
    DispatchKeyValue(iEntity, "hint_forcecaption", "1");
    DispatchKeyValue(iEntity, "hint_color", "150, 150, 150");
    DispatchKeyValue(iEntity, "hint_caption", text);

    // Show hint
    DispatchSpawn(iEntity);
    AcceptEntityInput(iEntity, "ShowHint");

    CreateTimer(HINT_TIMEOUT, DestroyInstructor, iEntity);
}
public Action DestroyInstructor(Handle timer, any entity)
{
    if (IsValidEntity(entity))
        RemoveEdict(entity);
    return Plugin_Stop;
}