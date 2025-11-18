#include <sourcemod>
#include <sdktools>

#define BOOST_MULTIPLIER 2.0 // Adjust for the amount of speed boost
#define BOOST_COOLDOWN 0.2   // Time in seconds before another boost is allowed

new Float:g_LastJump[MAXPLAYERS+1]; // Tracks the last jump time for each player

public Plugin:myinfo = 
{
    name = "Bunny Hop Boost",
    author = "Your Name",
    description = "Facsimile bunny hopping with a manual boost",
    version = "1.4",
    url = ""
};

public void OnPlayerRunCmdPost(int client, int buttons, int impulse)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    if (buttons & IN_JUMP)
    {
        HandleBunnyHop(client);
    }
}

stock void HandleBunnyHop(int client)
{
    if (IsPlayerGrounded(client))
    {
        return; // Player is on the ground; no boost
    }

    // Check for cooldown
    float currentTime = GetGameTime();
    if (currentTime - g_LastJump[client] < BOOST_COOLDOWN)
    {
        return; // Still in cooldown
    }

    // Apply momentum boost
    float velocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
    ScaleVector(velocity, BOOST_MULTIPLIER); // Increase speed
    SetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

    // Update last jump time
    g_LastJump[client] = currentTime;
}

// Function to check if the player is grounded
stock bool IsPlayerGrounded(int client)
{
    float origin[3], ground[3];
    GetEntPropVector(client, Prop_Data, "m_vecOrigin", origin);

    // Define the ray trace target point slightly below the player
    ground[0] = origin[0];
    ground[1] = origin[1];
    ground[2] = origin[2] - 5.0;

    // Perform the trace
    TR_TraceRay(origin, ground, MASK_SOLID, RayType_EndPoint);

    // Check if the trace hit anything
    return TR_DidHit();
}
