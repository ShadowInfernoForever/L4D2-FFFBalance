#pragma semicolon 1
#pragma tabsize 0
#include <sourcemod>  
#include <sdktools>   
#include <sdkhooks>
#include <colors>


ConVar TIME;
Handle TIMER = INVALID_HANDLE;

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
/*#define ROUND_START1 "insanity/z_startaction_01_new.mp3"
#define ROUND_START2 "insanity/z_startaction_01_new.mp3"
#define ROUND_START3 "insanity/z_startaction_02_new.mp3"
#define ROUND_START4 "insanity/z_startaction_03_new.mp3"
#define ROUND_START5 "insanity/z_startaction_04_new.mp3"
#define ROUND_START6 "insanity/z_startaction_05_new.mp3"
#define ROUND_START7 "insanity/z_startaction_06_new.mp3"
#define ROUND_START8 "insanity/z_startaction_07_new.mp3"
#define ROUND_START9 "insanity/z_re1_new.mp3"
#define ROUND_START10 "insanity/z_re2_new.mp3"*/

#define ROUND_START1 "ambient/weather/thunderstorm/lightning_strike_1.wav"
#define ROUND_START2 "ambient/weather/thunderstorm/lightning_strike_2.wav"
#define ROUND_START3 "ambient/weather/thunderstorm/lightning_strike_3.wav"
#define ROUND_START4 "ambient/weather/thunderstorm/lightning_strike_4.wav"

public void OnPluginStart() {
 char PATH[24];
 GetGameFolderName(PATH, sizeof(PATH));
 if (!StrEqual(PATH, "left4dead2", false)) SetFailState("Sorry my plugin was made for L4D2");
 else 

 TIME = CreateConVar("FF_news_time", "140", "How long must wait to display each publicity (default 2 min = 120 seconds)");
 TIME.AddChangeHook(OnCvarChange);

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
PrecacheSound(ROUND_START1, true);
PrecacheSound(ROUND_START2, true);
PrecacheSound(ROUND_START3, true);
PrecacheSound(ROUND_START4, true);
/*PrecacheSound(ROUND_START5, true);
PrecacheSound(ROUND_START6, true);
PrecacheSound(ROUND_START7, true);
PrecacheSound(ROUND_START8, true);
PrecacheSound(ROUND_START9, true);
PrecacheSound(ROUND_START10, true);*/

//Unused for now
//AddFileToDownloadsTable("sound/insanity/z_Escalation1.mp3");
//AddFileToDownloadsTable("sound/insanity/z_ETrShift.mp3");
//AddFileToDownloadsTable("sound/insanity/z_re3_new.mp3"); 

//Used
//AddFileToDownloadsTable("sound/insanity/z_re1_new.mp3");
//AddFileToDownloadsTable("sound/insanity/z_re2_new.mp3");
//AddFileToDownloadsTable("sound/insanity/z_startaction_01_new.mp3");
//AddFileToDownloadsTable("sound/insanity/z_startaction_02_new.mp3");
//AddFileToDownloadsTable("sound/insanity/z_startaction_03_new.mp3");
//AddFileToDownloadsTable("sound/insanity/z_startaction_04_new.mp3");
//AddFileToDownloadsTable("sound/insanity/z_startaction_05_new.mp3");
//AddFileToDownloadsTable("sound/insanity/z_startaction_06_new.mp3");
//AddFileToDownloadsTable("sound/insanity/z_startaction_07_new.mp3");

}

public void OnMapEnd(){

KillTimer(TIMER);

}


public Action DisplayPublicity(Handle timer) {

decl String:randMelonMsg[] = {
    // **Pro-TIP** Messages: General Gameplay Tips
    {"{olive} ➤ [Pro-TIP]: {default} No mueras para no morir... arhe"},
    {"{olive} ➤ [Pro-TIP]: {default} Separación = Muerte. ¡Mantente cerca de tu equipo para aumentar tus posibilidades de supervivencia!"},
    {"{olive} ➤ [Pro-TIP]: {default} La tacticidad hace que un equipo sea imparable. Juega en equipo y cubre las debilidades."},
    {"{olive} ➤ [Pro-TIP]: {default} El balance perfecto es ser {red}táctico{default} y {red}agresivo{default}, ¡pero nunca pierdas el enfoque!"},
    {"{olive} ➤ [Pro-TIP]: {default} Todas las armas son {green}buenas{default}, pero la habilidad del jugador es lo que marca la diferencia."},

    // **Info** Messages: General Knowledge
    {"{green} ➤ [Info]: {default} Abre bien los ojos, siempre hay cosas escondidas por ahí, podrías encontrar {olive}PILDORAS! {default}:D"},
    {"{green} ➤ [Info]: {default} Mantente cerca de tu equipo para que la supervivencia no dependa solo de ti"},
    {"{green} ➤ [Info]: {default} Recuerda que, mientras más sean en tu equipo, mayores son las {red}posibilidades{default}."},
    {"{green} ➤ [Info]: {default} ¡No te olvides de compartir tus {red}curaciones{default}! ¡Es crucial para la supervivencia del equipo!"},
    {"{green} ➤ [Info]: {default} Explora el mapa, puedes encontrar {red}items{default} ocultos que marcarán la diferencia."},
    {"{green} ➤ [Info]: {default} ¡Recuerda que el éxito depende de la cooperación!"},
    {"{green} ➤ [Info]: {default} Los zombis no son la única amenaza. ¡Tus compañeros siempre son los verdaderos enemigos!"},
    {"{green} ➤ [Info]: {default} La cooperación es clave. ¡No dejes a nadie atrás!"},
    {"{green} ➤ [Info]: {default} ¡Nunca subestimes el poder de un {red}equipo {default}bien coordinado! El tank se derrite si {red}Todos {default}le disparan."},

    // **News/Storyline Messages**: Lore and Game World Context
    {"{blue} ➤ [Noticias]: {default} La {olive}Gripe Verde{default} es conocida por su rápida propagación... ¡Mantente alerta!"},
    {"{blue} ➤ [Noticias]: {default} Los síntomas de la {olive}Gripe Verde{default} incluyen: {red}agresividad{default}, y {red}pérdida de razón{default}."},
    {"{blue} ➤ [Noticias]: {default} Las zonas de cuarentena han caído. La infección se extiende rápidamente."},
    {"{blue} ➤ [Noticias]: {default} ¿Sabías que la {olive}Gripe Verde{default} tiene mutaciones inesperadas? ¡Prepárate para lo peor!"},
    {"{blue} ➤ [Noticias]: {default} La Gripe Verde se transmite por aire y contacto. ¡Evita el contacto cercano!"},
    {"{blue} ➤ [Noticias]: {default} La amenaza de los {olive}infectados{default} sigue creciendo."},

    // **Humorous or Lighthearted Messages**
    {"{green} ➤ [Info]: {default} ¡Cuidado con los zombies que te siguen! Son más persistentes que el WiFi de tu casa."},
    {"{green} ➤ [Info]: {default} Si ves un Tank, ve a darle un abrazo, te dará vida extra"},
    {"{blue} ➤ [Noticias]: {default} ¿Alguna vez has visto un {blue}Churger{default}? Se dice que mató a un Tank con solo un golpe."},
    {"{blue} ➤ [Noticias]: {default} El futuro de la humanidad está condenada... ¡pero eso no significa que no podamos divertirnos, yuuju!"},
    
    // **Special Situations or Mechanics
    {"{green} ➤ [Info]: {default} Si matas un {red}Tank{default}, ¡podrías encontrar un {olive}suministro {default}aéreo cerca!"},

    // **Tips for Specific Infected**
    {"{red} ➤ [TIP]: {default} Los {red}Boomers{default} pueden cubrirte de {green}vomito{default}. ¡Mantén tu distancia!"},
    {"{red} ➤ [TIP]: {default} ¡No dejes que un {red}Hunter{default} te agarre! Cualquier sobreviviente atrapado muere en 5 segundos."},
    {"{red} ➤ [TIP]: {default} ¡Cuidado con los {red}Smokers{default}, su lengua puede atraparte a larga distancia!"},

    // **Fun Messages / Playful / Random**
    //{"{green} ➤ [Info]: {default} ¡Si te suicidas escribiendo {red}!kill{default}, recuerda que no todo está perdido... ¡es solo un juego!"},
    //{"{green} ➤ [Info]: {default} ¡Nunca subestimes el poder de un equipo bien coordinado! El Tank no sabe lo que le espera."},
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

            CPrintToChat(i, GetRandomMelonMessage());

            EmitSoundToClient(i, randsound[GetRandomInt(0, sizeof(randsound) - 1)] );


        }
        
    }

}

stock String:GetRandomMelonMessage() {
    new randArray = GetRandomInt(0, 1); // Adjust based on the number of arrays
    switch (randArray) {
        case 0: return randMelonTips1[GetRandomInt(0, sizeof(randMelonTips1) - 1)];
        case 1: return randMelonTips2[GetRandomInt(0, sizeof(randMelonTips2) - 1)];
    }
    return ""; // Fallback in case of an error
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

/*decl String:randstartsound[][] = {
            {ROUND_START1},
            {ROUND_START2},
            {ROUND_START3},
            {ROUND_START4},
            {ROUND_START5},
            {ROUND_START6},
            {ROUND_START7},
            {ROUND_START8},
            {ROUND_START9},
            {ROUND_START10},
};*/

decl String:randstartsound[][] = {
            {ROUND_START1},
            {ROUND_START2},
            {ROUND_START3},
            {ROUND_START4},
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


    // Color Correction Like CS:GO

    int entcol = CreateEntityByName("color_correction");
    if( entcol == -1 ) 
    {
        LogError("Failed to create 'color_correction'");
        return;
    }
    else
    {
        //g_iInfectedMind[index][1] = EntIndexToEntRef(entity);

        DispatchKeyValue(entcol, "filename", "materials/correction/dlc3_river03_outro.pwl.raw");
        //DispatchKeyValue(entcol, "spawnflags", "2");
        DispatchKeyValue(entcol, "maxweight", "0.8");
        DispatchKeyValue(entcol, "fadeInDuration", "2");
        DispatchKeyValue(entcol, "fadeOutDuration", "6");
        DispatchKeyValue(entcol, "maxfalloff", "-1");
        DispatchKeyValue(entcol, "minfalloff", "-1");
        DispatchKeyValue(entcol, "StartDisabled", "1");
        DispatchKeyValue(entcol, "exclusive", "1");

        DispatchSpawn(entcol);
        ActivateEntity(entcol);
        AcceptEntityInput(entcol, "Enable");
        DispatchKeyValue(entcol, "targetname", "saferoomcorrection");
    }

    CreateTimer(3.0, remove_entcolor, entcol);
                
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

public Action remove_entcolor(Handle Timer, int entcol) {

    if(IsValidEdict(entcol)) {
        AcceptEntityInput(entcol, "Disable");
    } else {
        int found = -1;
        while ((found = FindEntityByClassname(found, "color_correction")) != -1)
            if (IsValidEdict(found))
                AcceptEntityInput(found, "Disable");
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