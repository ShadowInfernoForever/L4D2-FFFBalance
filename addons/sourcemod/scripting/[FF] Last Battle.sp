#pragma semicolon 1   // preprocessor?  whatever, no idea what it does. but im leaving it
#include <sourcemod>  //  bleh. i figure i need this.
#include <sdktools>   // not even sure i need this, but im leaving it
#include <sdkhooks>
#include <colors>

public Plugin myinfo = {
 name = "[L4D2] Chat Publicity",
 author = "Foxhound27",
 description = "Displays colored publicity as chat message",
 version = "1.0",
 url = " ><> "
};


#define Final1 "insanity/z_equipoLG.mp3"
#define Final2 "insanity/z_radioevac.mp3"
#define Final3 "insanity/z_radioevac2.mp3"
#define sColor "25,255,25"


public void OnPluginStart() {

HookEntityOutput("trigger_finale", "FinaleStart", OnFinaleStart);

}

public void OnMapStart() 
{

PrecacheSound(Final1, true);
PrecacheSound(Final2, true);
PrecacheSound(Final3, true);
AddFileToDownloadsTable("sound/insanity/z_equipoLG.mp3");
AddFileToDownloadsTable("sound/insanity/z_radioevac.mp3");
AddFileToDownloadsTable("sound/insanity/z_radioevac2.mp3");

}


void OnFinaleStart(const char[] output, int caller, int activator, float delay)
{

    new Handle:event = CreateEvent("instructor_server_hint_create", true);
    SetEventString(event, "hint_name", "RandomHint");
    SetEventString(event, "hint_replace_key", "RandomHint");
    SetEventInt(event, "hint_target", 1);
    SetEventInt(event, "hint_activator_userid", 0);
    SetEventInt(event, "hint_timeout", 6 );
    SetEventString(event, "hint_icon_onscreen", "icon_skull");
    SetEventString(event, "hint_icon_offscreen", "icon_skull");
    SetEventString(event, "hint_caption", "-=Transmisión Delta07=-");
    SetEventString(event, "hint_color", sColor);
    SetEventFloat(event, "hint_icon_offset", 0.0 );
    SetEventFloat(event, "hint_range", 0.0 );
    SetEventInt(event, "hint_flags", 1);// Change it..
    SetEventString(event, "hint_binding", "");
    SetEventBool(event, "hint_allow_nodraw_target", true);
    SetEventBool(event, "hint_nooffscreen", false);
    SetEventBool(event, "hint_forcecaption", false);
    SetEventBool(event, "hint_local_player_only", false);
    SetEventBool(event, "hint_shakeoption", 2);
    FireEvent(event);

    decl String:randsound[][] = {
            {"insanity/z_equipoLG.mp3"},
            {"insanity/z_radioevac.mp3"},
            {"insanity/z_radioevac2.mp3"},
    };


    for (new i = 1; i <= MaxClients; i++)

    {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {

            //CPrintToChat(i,"{red} ➤ [FINAL]{default}: {default} PREPAREN LA COLA, BITCHESS! ");
        
            EmitSoundToClient(i, randsound[GetRandomInt(0, sizeof(randsound) - 1)] );
            
        }
        
    }
}

