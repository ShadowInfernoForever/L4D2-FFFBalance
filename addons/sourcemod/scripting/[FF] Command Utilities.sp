#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION "1.0"
//#define DEATH "weapons/shotgun_chrome/gunfire/shotgun_fire_1.wav"
//#define DEATH2 "level/loud/climber.wav"
#define Advert_4 "ui/alert_clink.wav"

#define DEFAULT_MAX_PLAYERS 4

ConVar g_cvMaxPlayers;

public Plugin:myinfo = 
	{
		name = "[L4D] Commands Handler",
		author = "Shadow",
		description = "To Allow Comands in chat!",
		version = PLUGIN_VERSION,
		url = ""
	}

public OnPluginStart()
{
		//RegConsoleCmd("sm_explode", Kill_Me);
        RegConsoleCmd("sm_ping", ShowPing);
        RegConsoleCmd("sm_grupo", group);
        RegConsoleCmd("sm_slots", slots);
        RegConsoleCmd("sm_jugadores", slots);
        RegConsoleCmd("sm_discord", discord);
        RegConsoleCmd("sm_cmds", cmds);

        // fun shit
        RegConsoleCmd("sm_kill", Kill_Me);
        RegConsoleCmd("sm_buy", buy);
        RegConsoleCmd("sm_laser", laser);
        RegConsoleCmd("sm_katana", katana);

        // fun infected changer

        //RegConsoleCmd("sm_smoker", smoker);
        //RegConsoleCmd("sm_boomer", boomer);
        //RegConsoleCmd("sm_hunter", hunter);
        //RegConsoleCmd("sm_spitter", spitter);
        //RegConsoleCmd("sm_jockey", jockey);
        //RegConsoleCmd("sm_charger", charger);
        //RegConsoleCmd("sm_tank", tank);

        //RegConsoleCmd("sm_t1", team1);
        //RegConsoleCmd("sm_t2", team2);
        //RegConsoleCmd("sm_t3", team3);


        // Get the server's max players ConVar
        g_cvMaxPlayers = FindConVar("sv_maxplayers");
    
        if(g_cvMaxPlayers == null)
        {
         LogError("Failed to find sv_maxplayers ConVar!");
         return;
        }
}

public void OnMapStart()
    {
		//PrecacheSound(DEATH, true);
		//PrecacheSound(DEATH2, true);
        PrecacheSound(Advert_4, true);
	}

public Action:group(int client, int args)
{
    for (new i = 1; i <= MaxClients; i++)
        {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {

            CPrintToChat(i,"{green} ➤ [Grupo]{default}: https://steamcommunity.com/groups/asado-con-los-pibe");

            CPrintToChat(i,"{olive} ★ [Grupo]{default}: Hay un grupo, pildoras, droga y escabio!!");
            
        
            EmitSoundToClient(i, Advert_4); 
        } 
    }
}

public Action:Kill_Me(int client, int args)
{
    ForcePlayerSuicide(client);

    decl String:person[128];
    GetClientName(client, person, sizeof(person));

    char buffer[512];
    Format(buffer, sizeof(buffer), "Your name is: %s", person);

    // Mensajes de muerte
    decl String:randstartMsg[][] = {
        "{default} ☠ *DEAD* {teamcolor}%s{default}: Dice Adiós mundo cruel!",
        "{default} ☠ *DEAD* {teamcolor}%s{default} Se voló la tapa del zapallo",
        "{default} ☠ *DEAD* {teamcolor}%s{default} Ha Dejado de Existir",
        "{default} ☠ *DEAD* {teamcolor}%s{default} Se fué con jesucito"
    };

    // Selecciona un mensaje al azar
    int randomIndex = GetRandomInt(0, sizeof(randstartMsg) - 1);
    CPrintToChatAllEx(client, randstartMsg[randomIndex], person);

    // Itera por todos los jugadores
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            // Emitir sonidos si se necesitan
            // EmitSoundToClient(i, DEATH);
            // EmitSoundToClient(i, DEATH2);
        }
    }
}


public Action:ShowPing(int client, int args)
{

    float packets;
    float choke;
    float ping;
    float loss;

    ping = GetClientAvgLatency(client, NetFlow_Both);
    ping = ping * 1000.0;
    float adjustmentFactor;
    if (ping <= 40) 
    {
    adjustmentFactor = 0.60; // 60% para pings bajos
    } 
    else if (ping <= 50) 
    {
       adjustmentFactor = 0.53; // 53% para pings medios
    }
    else if (ping <= 100) 
    {
    adjustmentFactor = 0.30; // 30% para pings medios
    } 
    else {
    adjustmentFactor = 0.25; // 25% para pings altos
    }

float scoreboardPing = ping - (ping * adjustmentFactor);
    packets = GetClientAvgPackets(client, NetFlow_Both);
    loss = GetClientAvgLoss(client, NetFlow_Both);
    choke = GetClientAvgChoke(client, NetFlow_Both);

    // Separate into two chat messages
    CPrintToChatAllEx(client, "<{olive}Ping{default}> {teamcolor}%N{default} @ {teamcolor}%.0f{default} - {teamcolor}Real", client, ping);
    CPrintToChatAllEx(client, "<{olive}ScPing{default}> {teamcolor}%N{default} @ {green}%.0f{default} - {olive}Scoreboard", client, scoreboardPing);

    // Additional information
    CPrintToChatAllEx(client, "<{olive}Packets{default}> {teamcolor}%N{default} @ {teamcolor}%f", client, packets);
    CPrintToChatAllEx(client, "<{olive}Loss{default}> {teamcolor}%N{default} @ {teamcolor}%f", client, loss);
    CPrintToChatAllEx(client, "<{olive}Choke{default}> {teamcolor}%N{default} @ {teamcolor}%f", client, choke);

    for (new i = 1; i <= MaxClients; i++)
        {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {
            EmitSoundToClient(i, Advert_4); 
        } 
    }


}

public Action:slots(int client, int args)
{

    //int maxplayers;
    //int players;

    // Get current player count (excluding bots)
    int playerCount = 0;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientConnected(i) && !IsFakeClient(i))
        {
            playerCount++;
        }
    }

    // Get max slots from sv_maxplayers
    int maxSlots = g_cvMaxPlayers.IntValue;
    
    // Default to 4 players if sv_maxplayers is -1
    if(maxSlots <= 0)
    {
        maxSlots = DEFAULT_MAX_PLAYERS;
    }

    //maxplayers = GetMaxHumanPlayers();
    //players = GetClientCount();
    

    CPrintToChatAllEx(client, "<{olive}Jugadores{default}> {teamcolor}%d{default} / {olive}%d max", playerCount, maxSlots);

}

public Action:discord(int client, int args)
{

for (new i = 1; i <= MaxClients; i++)
        {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {

            CPrintToChat(i,"{green} ➤ [Discord]{default}: {default}https://discord.gg/a7KTtWUfJA");
            CPrintToChat(i,"{olive} ★ [Discord]{default}: {default} Únite a la familia, no seas gil hermano!");
        
            EmitSoundToClient(i, Advert_4); 
     }   
}

}

public Action:cmds(int client, int args)
{

      for (new i = 1; i <= MaxClients; i++)
        {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {
            CPrintToChat(i,"{red} ★ {default} Acá tus comandos pelotudito {green}➤");
            CPrintToChat(i,"{red} • {default} !drop");
            CPrintToChat(i,"{red} • {default} !discord");
            CPrintToChat(i,"{red} • {default} !grupo");
            CPrintToChat(i,"{red} • {default} !kill");
            CPrintToChat(i,"{red} • {default} !survivors");
            CPrintToChat(i,"{red} • {default} !afk");
            CPrintToChat(i,"{red} • {default} !ping");
            CPrintToChat(i,"{red} • {default} !slots");
        
            EmitSoundToClient(i, Advert_4); 
        }   
      }

}

public Action:buy(int client, int args)
{

for (new i = 1; i <= MaxClients; i++)
        {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {

            CPrintToChat(i,"{default}¿Qué? ¿{green}COMPRAR{default}? ¿Por qué mejor no te {green}COMPRAS {default}una {green}VIDA");
        
            EmitSoundToClient(i, Advert_4); 
     }   
}

}

public Action:laser(int client, int args)
{

for (new i = 1; i <= MaxClients; i++)
        {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {

            CPrintToChat(i,"{green}¡Wow! {default}piensa que con laser va a pegar algo... MANCO, JA!");
        
            EmitSoundToClient(i, Advert_4); 
     }   
}

}

public Action:katana(int client, int args)
{

for (new i = 1; i <= MaxClients; i++)
        {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {

            CPrintToChat(i,"¿te crees un {green}samurái {default}o qué? Aprende a usarla primero.");
        
            EmitSoundToClient(i, Advert_4); 
     }   
}

}

public Action:tropezarse(int client, int args)
{

SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1);
SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
SetEntProp(client, Prop_Send, "m_iHealth", 300);

}

public Action:caerse(int client, int args)
{

SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 1);

}

// Smoker command
public Action:smoker(int client, int args)
{
    SetEntProp(client, Prop_Send, "m_iTeamNum", 3); // Infected team
    SetEntProp(client, Prop_Send, "m_zombieClass", 1); // Smoker class
    SetEntityModel(client, "models/infected/smoker.mdl");
    GivePlayerItem(client, "smoker_claw");
    return Plugin_Handled;
}

// Boomer command
public Action:boomer(int client, int args)
{
    SetEntProp(client, Prop_Send, "m_iTeamNum", 3); // Infected team
    SetEntProp(client, Prop_Send, "m_zombieClass", 2); // Boomer class
    SetEntityModel(client, "models/infected/boomer.mdl");
    GivePlayerItem(client, "boomer_claw");
    return Plugin_Handled;
}

// Hunter command
public Action:hunter(int client, int args)
{
    SetEntProp(client, Prop_Send, "m_iTeamNum", 3); // Infected team
    SetEntProp(client, Prop_Send, "m_zombieClass", 3); // Hunter class
    SetEntityModel(client, "models/infected/hunter.mdl");
    GivePlayerItem(client, "hunter_claw");
    return Plugin_Handled;
}

// Spitter command
public Action:spitter(int client, int args)
{
    SetEntProp(client, Prop_Send, "m_iTeamNum", 3); // Infected team
    SetEntProp(client, Prop_Send, "m_zombieClass", 4); // Spitter class
    SetEntityModel(client, "models/infected/spitter.mdl");
    GivePlayerItem(client, "spitter_claw");
    return Plugin_Handled;
}

// Jockey command
public Action:jockey(int client, int args)
{
    SetEntProp(client, Prop_Send, "m_iTeamNum", 3); // Infected team
    SetEntProp(client, Prop_Send, "m_zombieClass", 5); // Jockey class
    SetEntityModel(client, "models/infected/jockey.mdl");
    GivePlayerItem(client, "jockey_Claw");
    return Plugin_Handled;
}

// Charger command
public Action:charger(int client, int args)
{
    SetEntProp(client, Prop_Send, "m_iTeamNum", 3); // Infected team
    SetEntProp(client, Prop_Send, "m_zombieClass", 6); // Charger class
    SetEntityModel(client, "models/infected/charger.mdl");
    GivePlayerItem(client, "charger_claw");
    return Plugin_Handled;
}


// Tank command
public Action:tank(int client, int args)
{
    SetEntProp(client, Prop_Send, "m_iTeamNum", 3); // Infected team
    SetEntProp(client, Prop_Send, "m_zombieClass", 8); // Tank class
    SetEntityModel(client, "models/infected/tank.mdl");
    GivePlayerItem(client, "tank_claw");
    return Plugin_Handled;
}

public Action:team1(int client, int args)
{

SetEntProp(client, Prop_Send, "m_iTeamNum", 1);

}

public Action:team2(int client, int args)
{

SetEntProp(client, Prop_Send, "m_iTeamNum", 2);

}

public Action:team3(int client, int args)
{

SetEntProp(client, Prop_Send, "m_iTeamNum", 3);

}


