#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

#define Advert_1 "insanity/z_horde_alarm.mp3"
#define Advert_2 "insanity/z_horde_alarm2.mp3"
#define sColor "255,255,25"
#define RadioChance 50

//#pragma newdecls required

public Plugin myinfo = 
{
    name = "Car Alarm Inform",
    author = "Eyal282",
    description = "Announces who triggered the car alarm, either for griefing or for spawning a Tank.",
    version = "3.0",
    url = "<- URL ->"
}

GlobalForward g_fwOnCarAlarm;

int g_iLastTriggerUserId;
char g_sLastTriggerName[64];
bool g_bAlarmWentOff;

public void OnPluginStart()
{
    HookEvent("create_panic_event", Event_CreatePanicEvent, EventHookMode_Post);
    HookEvent("triggered_car_alarm", Event_TriggeredCarAlarm, EventHookMode_Pre);

    g_fwOnCarAlarm = CreateGlobalForward("Plugins_OnCarAlarmPost", ET_Ignore, Param_Cell);
}

public void OnMapStart()
{
    PrecacheSound(Advert_1, true);
    PrecacheSound(Advert_2, true);

    AddFileToDownloadsTable("sound/insanity/z_horde_alarm.mp3");
    AddFileToDownloadsTable("sound/insanity/z_horde_alarm2.mp3");
}

public Action Event_TriggeredCarAlarm(Handle hEvent, char[] Name, bool dontBroastcast)
{
    g_bAlarmWentOff = true;

    return Plugin_Continue;
}
public Action Event_CreatePanicEvent(Handle hEvent, char[] Name, bool dontBroastcast)
{
    int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    
    if(client == 0) // Console panic events.
        return Plugin_Continue;
        
    else if(GetClientTeam(client) != 2) // Better safe than sorry.
        return Plugin_Continue;
    
    GetClientName(client, g_sLastTriggerName, sizeof(g_sLastTriggerName));

    g_iLastTriggerUserId = GetClientUserId(client);

    RequestFrame(CheckAlarm);

    return Plugin_Continue;
}

public void CheckAlarm() // Zero is basically a null variable, I didn't need to pass a variable but I'm forced to.
{
    if(!g_bAlarmWentOff)
        return;

    g_bAlarmWentOff = false;

    if( GetRandomInt(1, 100) <= RadioChance ){
        CreateTimer(3.5, LoadStuff);
    }

    decl String:randmessage[][] = {
            {"{blue}%s {default}has earned the archivement {olive}El Pelotudo de la alarma"},
            {"{blue}%s {default}has earned the archivement {olive}El Conchasuvida de la alarma"},
            {"{blue}%s {default}has earned the archivement {olive}El Mogolico de la alarma"},
            {"{blue}%s {default}has earned the archivement {olive}El Pajero de la alarma"},
            {"{blue}%s {default}has earned the archivement {olive}El Weon de la alarma"},
    };

    for (new i = 1; i <= MaxClients; i++)

    {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {
            CPrintToChat(i, randmessage[GetRandomInt(0, sizeof(randmessage) - 1)], g_sLastTriggerName, i);
        }
        
    }

    Call_StartForward(g_fwOnCarAlarm);

    Call_PushCell(g_iLastTriggerUserId);

    Call_Finish();
}

public Action LoadStuff(Handle timer)
{
    decl String:randsound[][] = {
            {"insanity/z_horde_alarm.mp3"},
            {"insanity/z_horde_alarm2.mp3"},
    };

    for (new i = 1; i <= MaxClients; i++)

    {
        if (IsClientInGame(i) && !IsFakeClient(i) )
        {
            EmitSoundToClient(i, randsound[GetRandomInt(0, sizeof(randsound) - 1)] );
        }
        
    }
}