#include <sourcemod>
#include <sdktools>
 
public Plugin myinfo =
{
	name = "ZContent-FilePrecacher",
	author = "Shadow",
	description = "Just Precaches some files, nothing game breaking",
	version = "1.0.0.0",
	url = ""
}

public OnMapStart()
{
	PrecacheSound("insanity/hitsound.mp3");
	PrecacheSound("insanity/slowdown65.mp3");
	PrecacheSound("insanity/boss_spawn.mp3");
	PrecacheSound("insanity/deadlife.mp3");
	PrecacheSound("insanity/deadlife_insane.mp3");
}