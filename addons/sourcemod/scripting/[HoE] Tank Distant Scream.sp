//Tank Notification for L4D/L4d2
//Prints a message and plays a sound when a tank spawns, music is unreliable.
//2022-4-2 Weld Inclusion

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>
#define VERSION "1.1"


//new bool:   g_bIsTankInPlay             = false;

public Plugin:myinfo =
{
	name = "Tank Distant Scream",
	author = "Shadow",
	description = "Plays a distant tank scream on spawn, similar to special infected bacterias",
	version = VERSION,
	url = ""
}

#define TANK_SCREAM "insanity/tank_spawn_event01.mp3"
#define TANK_SCREAM2 "insanity/tank_spawn_event02.mp3"

public void OnMapStart() 
{
	PrecacheSound(TANK_SCREAM);
    PrecacheSound(TANK_SCREAM2);
    AddFileToDownloadsTable("sound/insanity/tank_spawn_event01.mp3");
    AddFileToDownloadsTable("sound/insanity/tank_spawn_event02.mp3");
}

public void OnPluginStart () 
{
  // g_bIsTankInPlay = false;
   HookEvent("tank_spawn", TankNotify);
   HookEvent("round_start", Event_RoundStart);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
   // g_bIsTankInPlay = false;
}

public void TankNotify(Event event, const char[] name, bool dontBroadcast)
{

//if (g_bIsTankInPlay) return; // Tank passed

//g_bIsTankInPlay = true;

int colorcorrect_ent = CreateEntityByName("color_correction");
    if( colorcorrect_ent == -1 ) 
    {
        LogError("Failed to create 'color_correction'");
        return;
    }
    else
    {
        //g_iInfectedMind[index][1] = EntIndexToEntRef(entity);

        DispatchKeyValue(colorcorrect_ent, "filename", "materials/correction/urban_night_red.pwl.raw");
        //DispatchKeyValue(colorcorrect_ent, "spawnflags", "2");
        DispatchKeyValue(colorcorrect_ent, "maxweight", "1.7");
        DispatchKeyValue(colorcorrect_ent, "fadeInDuration", "1.3");
        DispatchKeyValue(colorcorrect_ent, "fadeOutDuration", "2.0");
        DispatchKeyValue(colorcorrect_ent, "maxfalloff", "-1");
        DispatchKeyValue(colorcorrect_ent, "minfalloff", "-1");
        DispatchKeyValue(colorcorrect_ent, "StartDisabled", "1");
        DispatchKeyValue(colorcorrect_ent, "exclusive", "1");

        DispatchSpawn(colorcorrect_ent);
        ActivateEntity(colorcorrect_ent);
        AcceptEntityInput(colorcorrect_ent, "Enable");
        DispatchKeyValue(colorcorrect_ent, "targetname", "tankcorrection");
    }
    CreateTimer(1.3, remove_colorent, colorcorrect_ent);

decl String:randsound[][] = {
            {TANK_SCREAM},
            {TANK_SCREAM2},
};

    for (new i = 1; i <= MaxClients; i++)

    {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {

            EmitSoundToClient(i, randsound[GetRandomInt(0, sizeof(randsound) - 1)] );
        }
    }
}

public Action remove_colorent(Handle Timer, int colorcorrect_ent) {

    if(IsValidEdict(colorcorrect_ent)) {
        AcceptEntityInput(colorcorrect_ent, "Disable");
    } else {
        int found = -1;
        while ((found = FindEntityByClassname(found, "color_correction")) != -1)
            if (IsValidEdict(found))
                AcceptEntityInput(found, "Disable");
    } 
    return Plugin_Continue;
}
