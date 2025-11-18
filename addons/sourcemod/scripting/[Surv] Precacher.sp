#include <sourcemod>
#include <sdktools>
 
public Plugin myinfo =
{
	name = "Survivor-FilePrecacher",
	author = "Shadow",
	description = "Just Precaches some files, nothing game breaking",
	version = "1.0.0.0",
	url = ""
}

public OnMapStart()
{
	PrecacheModel("models/survivors/rebel_ellis.mdl");
	PrecacheModel("models/survivors/jaguar_francis.mdl");
	PrecacheModel("models/survivors/clubbin_coach.mdl");
	PrecacheModel("models/survivors/freeman.mdl");
	PrecacheModel("models/survivors/gunrunner_nick.mdl");
	PrecacheModel("models/survivors/serious_ellis.mdl");
	PrecacheModel("models/survivors/mrdeath.mdl");
	PrecacheModel("models/survivors/tacticalzoey.mdl");
}