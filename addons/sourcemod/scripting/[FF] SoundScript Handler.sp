#include <sourcemod>
#include <loadsoundscript>
#include <sdktools_sound>

public Plugin myinfo = {
 name = "[FF Weapons Handler] SoundScript Handler",
 author = "Shadow",
 description = "Displays colored publicity as chat message",
 version = "1.0",
 url = "https://github.com/haxtonsale/LoadSoundScript"
};

public void OnPluginStart()
{
	// Path must be relative to the game folder
	LoadSoundScript("scripts/FF_Soundscripts.txt");
	RegConsoleCmd("soundscript_test", Cmd_SoundScriptTest);
}

public Action Cmd_SoundScriptTest(int client, int args)
{
	// Whichever sounds were in the file can now be emitted via EmitGameSound
	EmitGameSoundToClient(client, "MRevolver.Fire");
}