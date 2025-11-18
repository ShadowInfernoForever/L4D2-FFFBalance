#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION "1.0"
#define Advert_4 "ui/alert_clink.wav"

public Plugin:myinfo = 
	{
		name = "[L4D] Commands Cheat",
		author = "Shadow",
		description = "To Allow Comands in chat!",
		version = PLUGIN_VERSION,
		url = ""
	}

public OnPluginStart()
{
		RegAdminCmd("sm_debug", Debug, ADMFLAG_ROOT, "");
}

public Action:Debug(int client, int args)
{

    decl String:randomthrow[][] = {
            {"weapon_vomitjar"},
            {"weapon_pipebomb"},
            {"weapon_molotov"}
        };
			GiveItem(client, randomthrow[GetRandomInt(0, sizeof(randomthrow) - 1)] );

    decl String:randommed[][] = {
            {"weapon_first_aid_kit"},
            {"weapon_defibrillator"}
    };
			GiveItem(client, randommed	[GetRandomInt(0, sizeof(randommed) - 1)] );

	decl String:randomutility[][] = {
            {"weapon_pain_pills"},
            {"weapon_adrenaline"}
    };
			GiveItem(client, randomutility[GetRandomInt(0, sizeof(randomutility) - 1)] );

}

void GiveItem(int client, char[] sItem)
{
    int flags = GetCommandFlags("give");
    SetCommandFlags("give", flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "give %s", sItem);
    SetCommandFlags("give", flags);
}