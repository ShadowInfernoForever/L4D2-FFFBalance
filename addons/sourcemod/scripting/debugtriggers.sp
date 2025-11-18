#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define BEAM_SPRITE "sprites/laser.vmt"

int g_spriteIndex;

public void OnPluginStart()
{
    g_spriteIndex = PrecacheModel(BEAM_SPRITE, true);
    RegConsoleCmd("sm_debug_triggers", DebugTriggersCmd, "Draws beams for all triggers in a bounding box.");
    RegConsoleCmd("sm_draw_triggerbeam", Command_DrawTriggerBeam, "Draws a beam around a trigger box.");
}

Action DebugTriggersCmd(int client, int args)
{
    if (!IsClientInGame(client))
    {
        return Plugin_Handled;
    }

    if (args < 6)
    {
        PrintToChat(client, "[SM] Usage: sm_debug_triggers <min_x> <min_y> <min_z> <max_x> <max_y> <max_z>");
        return Plugin_Handled;
    }

    float min[3], max[3];
    for (int i = 0; i < 3; i++)
    {
        min[i] = GetCmdArgFloat(i + 1);
        max[i] = GetCmdArgFloat(i + 4);
    }

    DrawTriggerBeams(client, min, max);

    return Plugin_Handled;
}

void DrawTriggerBeams(int client, float min[3], float max[3])
{
    int triggerCount = 0;

    for (int entity = 0; entity < GetMaxEntities(); entity++)
    {
        if (!IsValidEntity(entity) || !IsTriggerEntity(entity))
        {
            continue;
        }

        float entMin[3], entMax[3];
        GetEntPropVector(entity, Prop_Send, "m_vecMins", entMin);
        GetEntPropVector(entity, Prop_Send, "m_vecMaxs", entMax);

        if (!BoundingBoxIntersects(min, max, entMin, entMax))
        {
            continue;
        }

        DrawBeam(client, entMin, entMax);
        triggerCount++;
    }

    PrintToChat(client, "[SM] Found %d triggers in the bounding box.", triggerCount);
}

public Action Command_DrawTriggerBeam(int client, int args)
{
    // Find the trigger entity by class (e.g., "trigger_multiple")
    int trigger_ent = FindEntityByClassname(-1, "trigger_hurt");

    if (trigger_ent == 0)
    {
        PrintToChat(client, "No trigger entity found.");
        return Plugin_Handled;
    }

    // Retrieve the vmin and vmax (trigger bounds)
    float vmin[3], vmax[3];
    GetEntPropVector(trigger_ent, Prop_Data, "m_vecMins", vmin);
    GetEntPropVector(trigger_ent, Prop_Data, "m_vecMaxs", vmax);

    // Set up beam properties
    float width = 5.0;  // Width of the beam
    float noise = 0.0;  // Beam noise
    int life = 2;       // Duration in seconds
    int red = 255, green = 0, blue = 0, alpha = 255;

    // Define color for the beam
    int color[4] = {255, 255, 255, 255};

    // Send the beam effect from vmin to vmax
    TE_SetupBeamPoints(vmin, vmax, g_spriteIndex, 0, 0, 0, width, noise, 0.0, life, 0.0, color, 0);
    TE_SendToClient(client);

    return Plugin_Handled;
}

bool IsTriggerEntity(int entity)
{
    static char className[64];
    GetEntityClassname(entity, className, sizeof(className));
    return StrContains(className, "trigger") != -1;
}

bool BoundingBoxIntersects(float box1Min[3], float box1Max[3], float box2Min[3], float box2Max[3])
{
    for (int i = 0; i < 3; i++)
    {
        if (box1Min[i] > box2Max[i] || box1Max[i] < box2Min[i])
        {
            return false;
        }
    }
    return true;
}

void DrawBeam(int client, float start[3], float end[3])
{
    float width = 5.0;    // Width of the beam
    float noise = 0.0;    // Beam noise
    int life = 2;         // Duration in seconds (casted to int)
    int red = 255, green = 0, blue = 0, alpha = 255;

    int color[4];
    color[0] = red;
    color[1] = green;
    color[2] = blue;
    color[3] = alpha;

    TE_SetupBeamPoints(
        start, 
        end, 
        g_spriteIndex, 
        0,            // Start frame
        0,            // Frame rate
        0,            // Flags
        width, 
        noise, 
        0.0,          // Randomness
        life,         // Directly pass the integer value
        0.0,          // Amplitude
        color, 
        0
    );
    TE_SendToClient(client);
}
