#pragma semicolon 1
#include <sourcemod>  
#include <sdktools>   
#include <sdkhooks>
#include <colors>

ConVar TIME;
Handle TIMER = INVALID_HANDLE;
new Handle:message1 = INVALID_HANDLE;
new Handle:trigger1 = INVALID_HANDLE;

new Handle:message2 = INVALID_HANDLE;
new Handle:trigger2 = INVALID_HANDLE;

public Plugin myinfo = {
 name = "[L4D2] Chat Publicity",
 author = "Foxhound27",
 description = "Displays colored publicity as chat message",
 version = "1.0",
 url = " ><> "
};

#define Advert_1 "physics/concrete/rock_impact_hard4.wav"
#define Advert_2 "physics/concrete/rock_impact_hard5.wav"
#define Advert_3 "physics/concrete/rock_impact_hard6.wav"
#define Advert_4 "ui/alert_clink.wav"
//#define ROUND_START1 "insanity/z_Escalation1.mp3"
//#define ROUND_START2 "insanity/z_ETrShift.mp3"
#define ROUND_START3 "insanity/z_re1_new.mp3"
#define ROUND_START4 "insanity/z_re2_new.mp3"
#define ROUND_START5 "insanity/z_re3_new.mp3"
#define ROUND_START6 "insanity/z_kf1.mp3"
#define ROUND_START7 "insanity/z_kf2.mp3"
#define ROUND_START8 "insanity/z_kf3.mp3"
#define ROUND_START9 "insanity/z_kf4.mp3"
#define ROUND_START10 "insanity/z_kf5.mp3"

public void OnPluginStart() {
 char PATH[24];
 GetGameFolderName(PATH, sizeof(PATH));
 if (!StrEqual(PATH, "left4dead2", false)) SetFailState("Sorry my plugin was made for L4D2");
 else 

 TIME = CreateConVar("FF_news_time", "140", "How long must wait to display each publicity (default 2 min = 120 seconds)");
 TIME.AddChangeHook(OnCvarChange);

 message1 = CreateConVar("FF_news_message1", "!discord", " Message #1 ");
 trigger1 = CreateConVar("FF_news_trigger1", "!discord", " Chat string trigger for message #1. Exact string match.", FCVAR_SPONLY|FCVAR_NOTIFY);

 message2 = CreateConVar("FF_news_message2", "!cmds", " Message #2 ");
 trigger2 = CreateConVar("FF_news_trigger2", "!cmds", " Chat string trigger for message #2. Exact string match.", FCVAR_SPONLY|FCVAR_NOTIFY);
   
 HookEvent("player_say", Event_PlayerSay);
 HookEvent("round_start", Event_RoundStart);

}


public void OnCvarChange(ConVar convar, char[] oldValue, char[] newValue)
{
    if (convar == TIME)
    {
    	KillTimer(TIMER);
        TIMER = CreateTimer(1.0 * GetConVarInt(TIME), DisplayPublicity,_, TIMER_REPEAT);
    }
}



public void OnMapStart(){

TIMER = CreateTimer(1.0 * GetConVarInt(TIME), DisplayPublicity,_, TIMER_REPEAT);

PrecacheSound(Advert_1, true);
PrecacheSound(Advert_2, true);
PrecacheSound(Advert_3, true);
PrecacheSound(Advert_4, true);
//PrecacheSound(ROUND_START1, true);
//PrecacheSound(ROUND_START2, true);
PrecacheSound(ROUND_START3, true);
PrecacheSound(ROUND_START4, true);
PrecacheSound(ROUND_START5, true);
PrecacheSound(ROUND_START6, true);
PrecacheSound(ROUND_START7, true);
PrecacheSound(ROUND_START8, true);
PrecacheSound(ROUND_START9, true);
PrecacheSound(ROUND_START10, true);

//AddFileToDownloadsTable("sound/insanity/z_Escalation1.mp3");
//AddFileToDownloadsTable("sound/insanity/z_ETrShift.mp3");
AddFileToDownloadsTable("sound/insanity/z_re1_new.mp3");
AddFileToDownloadsTable("sound/insanity/z_re2_new.mp3");
AddFileToDownloadsTable("sound/insanity/z_re3_new.mp3");
AddFileToDownloadsTable("sound/insanity/z_kf1.mp3");
AddFileToDownloadsTable("sound/insanity/z_kf2.mp3");
AddFileToDownloadsTable("sound/insanity/z_kf3.mp3");
AddFileToDownloadsTable("sound/insanity/z_kf4.mp3");
AddFileToDownloadsTable("sound/insanity/z_kf5.mp3");

}

public void OnMapEnd(){

KillTimer(TIMER);

}


public Action DisplayPublicity(Handle timer) {

decl String:randMelonMsg[][] = {
            {"{olive} ➤ [Pro-TIP]: {default} No mueras para no morir"},
            {"{olive} ➤ [Pro-TIP]: {default} Separación = Muerte, no te alejes de tu equipo."},
            {"{olive} ➤ [Pro-TIP]: {default} la tacticidad hace que un equipo sea imparable."},
            {"{olive} ➤ [Pro-TIP]: {default} El balance perfecto es ser {red}táctico {default}y {red}rushero"},
            {"{olive} ➤ [Pro-TIP]: {default} Todas las armas son {red}buenas{default}, la eficacia está en el jugador"},
            {"{green} ➤ [Info]: {default} Abre bien los ojos, siempre hay cosas escondidas por ahí.."},
            {"{green} ➤ [Info]: {default} Mantenerte cerca de tu equipo es esencial para no morir"},
            {"{green} ➤ [Info]: {default} No te alejes demasiado del grupo para evitar ser atacado solo."},
            {"{green} ➤ [Info]: {default} Recuerda que, mientras más sean en tu equipo, mayores son las {red}posibilidades!"},
            {"{green} ➤ [Info]: {default} Recuerda compartir tus {red}✚curaciones{default} con tu equipo, te lo agradecerán."},
            {"{green} ➤ [Info]: {default} Recuerda que puedes encontrar {red}items {default}exparcidos por el mapa!"},
            {"{green} ➤ [Info]: {default} Hay varios {red}items {default}exparcidos por el mapa!"},
            {"{green} ➤ [Info]: {default} Deathmatch es el único gamemode que puede darte {red}XP{default}."},
            {"{green} ➤ [Info]: {default} El tank se endurece con la cantidad de jugadores en la partida!"},
            {"{green} ➤ [Info]: {default} Puedes {red}droppear {default}tu objeto actual escribiendo {red}!drop {default}en el chat."},
            {"{green} ➤ [Info]: {default} Puedes suicidarte escribiendo {red}!kill {default}en el chat."},
            {"{green} ➤ [Info]: {default} Puedes ver stats de tu conexión poniendo {blue}!ping {default}en el chat."},
            {"{green} ➤ [Info]: {default} Estate atento cuando mates un tank, pueden tirar un suministro aéreo!"},
            {"{green} ➤ [Info]: {default} Date un rodeo por el mapa de vez en cuando, quien sabe, podrias encontrar ¡{red}Pildoras{default}!"},
            {"{green} ➤ [Info]: {default} En este servidor se fácilitan los {red}skeets {default}y {red}leveleos {default}hacia la {green}IA."},
            {"{green} ➤ [Info]: {default} Cada persona tiene su rol en el equipo."},
            {"{green} ➤ [Info]: {default} Recuerda que la {red}cooperación {default}es lo principal para ganar!"},
            {"{green} ➤ [Info]: {default} La Unión hace la fuerza, reúne tantos {red}sobrevivientes {default}cuantos puedas!"},
            {"{green} ➤ [Info]: {default} La Unión hace la fuerza, reúne tantos {red}aliados {default}cuantos puedas!"},
            {"{green} ➤ [Info]: {default} Comunícate con tu equipo para coordinar estrategias y compartir recursos.."},
            //{"{green} ➤ [Info]: {default} Estate atento por las {green}Zonas Amarillas {default}del mapa, tienen objetos valiosos!"},
            //{"{green} ➤ [Info]: {default} Recuerda que la supervivencia está en ti mismo, nada de trucos ni habilidades."},
            //{"{green} ➤ [Info]: {default} Cuidado Con las anomalias, si te acercas mucho pueden electrocutarte!"},
            {"{blue} ➤ [Noticias]: {default} La {olive}Gripe Verde{default} es conocida por su rápida propagación..."},
            {"{blue} ➤ [Noticias]: {default} La {olive}Gripe Verde{default} es conocida por sus rápidas mutaciones en el cuerpo."},
            {"{blue} ➤ [Noticias]: {default} La {olive}Gripe Verde{default} es conocida por su parecido a la 'Rabia'"},
            {"{blue} ➤ [Noticias]: {default} La {olive}Gripe Verde{default} aunque tenga ciertos parecidos con la rabia, no es rabia."},
            {"{blue} ➤ [Noticias]: {default} La {olive}Gripe Verde{default} es un virus transmitido por aire"},
            {"{blue} ➤ [Noticias]: {default} La {olive}Gripe Verde{default} es un virus transmitido por contacto"},
            {"{blue} ➤ [Noticias]: {default} Los sintomas de la {olive}Gripe Verde{default} pueden ser: Agresividad, Perdida de la razón."},
            {"{blue} ➤ [Noticias]: {default} La mayoria de las zonas de cuarentena han sido eliminadas por la infección zombie."},
            {"{blue} ➤ [Noticias]: {default} ¿Nunca has visto a un {blue}Churger{default}? se dice que mato a un tank de un solo golpe."},
            {"{blue} ➤ [Noticias]: {default} Las optimizaciones de código son frecuentes, porfavor reporta cualquier bug!"},
            //{"{blue} ➤ [Noticias]: {default} Se están creando nuevos mapas para el modo Deathmatch!"},
            //{"{blue} ➤ [Noticias]: {default} La muerte es inevitable mi amigo, cuidado con los necroticos, JA JA!"},
            //{"{blue} ➤ [Noticias]: {default} La perdición está cerca, nadie sobrevive para siempre."},
            //{"{blue} ➤ [Noticias]: {default} El destino final está cerca, nadie sobrevive para siempre."},
            //{"{blue} ➤ [Noticias]: {default} Nadie Sobrevive para siempre."},
            //{"{blue} ➤ [Noticias]: {default} Pronto... la humanidad dejará de existir, y los no muertos reinaran."},
            //{"{blue} ➤ [Noticias]: {default} ¿Alguna vez has visto un {blue}zombine {default}en patineta?"},
};

decl String:randsound[][] = {
            {"physics/concrete/rock_impact_hard4.wav"},
            {"physics/concrete/rock_impact_hard5.wav"},
            {"physics/concrete/rock_impact_hard6.wav"},
};


 for (new i = 1; i <= MaxClients; i++)

    {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {

            CPrintToChat(i, randMelonMsg[GetRandomInt(0, sizeof(randMelonMsg) - 1)] );

            EmitSoundToClient(i, randsound[GetRandomInt(0, sizeof(randsound) - 1)] );


        }
        
    }

}

public Action:Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)       // catches everything every player says
{
    new String:tempp[200];
    new String:temp1[200];
    new String:temp2[200];
    GetConVarString(trigger1, temp1, 200);
    GetConVarString(trigger2, temp2, 200);

    new client = GetClientOfUserId(GetEventInt(event, "userid"));       // find out who said what
    //new iCurrentTeam = GetClientTeam( client );        // what team were they on?

    new String:text[200];
    GetEventString(event, "text", text, 200);
    //new String:texted[200];
    
    decl String:player_authid[32];
    GetClientAuthString(client, player_authid, sizeof(player_authid));

    if (strcmp(text, temp1, false) == 0  )      
        {

        GetConVarString(message1, tempp, 200);
        
        for (new i = 1; i <= MaxClients; i++)
        {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {

            CPrintToChat(i,"{green} ➤ [Discord]{default}: {default}https://discord.gg/j8xaP3K5d7");
            CPrintToChat(i,"{olive} ★ [Discord]{default}: {default} Únite a la familia, no seas gil hermano!");
        
            EmitSoundToClient(i, Advert_4); 
        }   
       }
   }




        if (strcmp(text, temp2, false) == 0  )      
        {
            GetConVarString(message2, tempp, 200);

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
        
            EmitSoundToClient(i, Advert_4); 
        }   
      }

  }  
}

public Event_RoundStart(Handle:event, String:event_name[], bool:dontBroadcast) {
    
    CreateTimer(1.0, TimerLeftSafeRoom, 0, TIMER_FLAG_NO_MAPCHANGE);    
    
}

public Action:TimerLeftSafeRoom(Handle:timer) {

decl String:randstartMsg[][] = {
            {"Mantente alerta y prepárate para sobrevivir!"},
            {"Prepárate para luchar por tu vida!"},
            {"Busquen Recursos y mantenganse alerta!"},
            {"Busquen Recursos y mantenganse en equipo!"},
            {"Quédate cerca de tu equipo o eres carne fresca!"},
            {"Los No-Muertos caminan sobre la tierra, Prepárate!"},
};

decl String:randstartsound[][] = {
            {ROUND_START3},
            {ROUND_START4},
            {ROUND_START5},
            {ROUND_START6},
            {ROUND_START7},
            {ROUND_START8},
            {ROUND_START9},
            {ROUND_START10},
};
 

    if (LeftStartArea()) 
    { 

        for (new i = 1; i <= MaxClients; i++)
        {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {

            EmitSoundToClient(i, randstartsound[GetRandomInt(0, sizeof(randstartsound) - 1)] );
        }   
    }

    int iEntity = CreateEntityByName("env_instructor_hint"); 
     
    // Target 
    DispatchKeyValue(iEntity, "hint_target", "0"); 
     
    // Static 
    DispatchKeyValue(iEntity, "hint_static", "1"); 
     
    // Timeout 
    DispatchKeyValue(iEntity, "hint_timeout", "8");  
     
    // Show off screen 
    DispatchKeyValue(iEntity, "hint_nooffscreen", "1"); 
     
    // Icons 
    DispatchKeyValue(iEntity, "hint_icon_offscreen", "icon_tip"); 
    DispatchKeyValue(iEntity, "hint_icon_onscreen", "icon_tip"); 
     
    // Show text behind walls  
    DispatchKeyValue(iEntity, "hint_forcecaption", "1"); 
     
    // Text color 
    DispatchKeyValue(iEntity, "hint_color", "150, 150, 150"); 
     
    //Text 
    DispatchKeyValue(iEntity, "hint_caption", randstartMsg[GetRandomInt(0, sizeof(randstartMsg) - 1)]); 
     
    DispatchSpawn(iEntity); 
    AcceptEntityInput(iEntity, "ShowHint");

    CreateTimer(8.0, DestroyInstructor, iEntity);
                
    }
    else
    {
        CreateTimer(2.0, TimerLeftSafeRoom, 0, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action DestroyInstructor(Handle Timer, int iEntity) {

    if(IsValidEdict(iEntity)) {
        AcceptEntityInput(iEntity, "Disable");
        AcceptEntityInput(iEntity, "Kill");
    }

    return Plugin_Continue;
}

stock bool:LeftStartArea() {

    new maxents = GetMaxEntities();
    
    for (new i = MaxClients + 1; i <= maxents; i++)
    {
        if (IsValidEntity(i))
        {
            decl String:netclass[64];
            
            GetEntityNetClass(i, netclass, sizeof(netclass));
            
            if (StrEqual(netclass, "CTerrorPlayerResource"))
            {
                if (GetEntProp(i, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
                {
                    return true;
                }
            }
        }
    }
    
    return false;
}