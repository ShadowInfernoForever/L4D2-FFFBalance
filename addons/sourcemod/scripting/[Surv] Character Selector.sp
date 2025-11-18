#pragma semicolon 1

#include <sourcemod>  
#include <sdktools>  

#define MODEL_BILL "models/survivors/survivor_namvet.mdl" 
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl" 
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl" 
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl" 

#define MODEL_NICK "models/survivors/survivor_gambler.mdl" 
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl" 
#define MODEL_COACH "models/survivors/survivor_coach.mdl" 
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl" 


// Custom From Here
#define MODEL_ADAWONG "models/survivors/survivor_adawong.mdl"
#define MODEL_REBEL "models/survivors/rebel_ellis.mdl"
#define MODEL_JAGUAR "models/survivors/jaguar_francis.mdl"
#define MODEL_SELLIS "models/survivors/serious_ellis.mdl"
#define MODEL_CCOACH "models/survivors/clubbin_coach.mdl"
#define MODEL_FREEMAN "models/survivors/freeman.mdl"
#define MODEL_GRUNNER "models/survivors/gunrunner_nick.mdl"
#define MODEL_MRDEATH "models/survivors/mrdeath.mdl"
#define MODEL_TZOEY "models/survivors/tacticalzoey.mdl"

#define     NICK     0 
#define     ROCHELLE    1 
#define     COACH     2 
#define     ELLIS     3 
#define     BILL     4 
#define     ZOEY     5 
#define     FRANCIS     6 
#define     LOUIS     7 

static g_iSelectedClient;
static bool:g_bAdminsOnly; 

public Plugin:myinfo =  
{  
    name = "Survivor Chat Select (AdaWong Version)",  
    author = "DeatChaos25 & Mi123456",  
    description = "Select a survivor character by typing their name into the chat (AdaWong Version)",  
    version = "1.4",  
}  

public OnPluginStart()  
{
    RegConsoleCmd("sm_zoey", ZoeyUse, "Changes your survivor character into Zoey");  
    RegConsoleCmd("sm_nick", NickUse, "Changes your survivor character into Nick");  
    RegConsoleCmd("sm_ellis", EllisUse, "Changes your survivor character into Ellis");  
    RegConsoleCmd("sm_coach", CoachUse, "Changes your survivor character into Coach");  
    RegConsoleCmd("sm_rochelle", RochelleUse, "Changes your survivor character into Rochelle");  
    RegConsoleCmd("sm_bill", BillUse, "Changes your survivor character into Bill");  
    RegConsoleCmd("sm_francis", BikerUse, "Changes your survivor character into Francis");  
    RegConsoleCmd("sm_louis", LouisUse, "Changes your survivor character into Louis");  
    
    RegConsoleCmd("sm_adawong", AdaWongUse, "Changes your survivor character into Rochelle");  
    RegConsoleCmd("sm_Rebel", RebelUse, "Changes your survivor character into Ellis");  
    RegConsoleCmd("sm_Jaguar", JaguarUse, "Changes your survivor character into Ellis"); 
    RegConsoleCmd("sm_SEllis", SEllisUse, "Changes your survivor character into SEllis");  
    
    RegConsoleCmd("sm_z", ZoeyUse, "Changes your survivor character into Zoey");  
    RegConsoleCmd("sm_n", NickUse, "Changes your survivor character into Nick");  
    RegConsoleCmd("sm_e", EllisUse, "Changes your survivor character into Ellis");  
    RegConsoleCmd("sm_c", CoachUse, "Changes your survivor character into Coach");  
    RegConsoleCmd("sm_r", RochelleUse, "Changes your survivor character into Rochelle");  
    RegConsoleCmd("sm_b", BillUse, "Changes your survivor character into Bill");  
    RegConsoleCmd("sm_f", BikerUse, "Changes your survivor character into Francis");  
    RegConsoleCmd("sm_l", LouisUse, "Changes your survivor character into Louis"); 
    
    RegConsoleCmd("sm_a", AdaWongUse, "Changes your survivor character into AdaWong"); 
    RegConsoleCmd("sm_re", RebelUse, "Changes your survivor character into Rebel"); 
    RegConsoleCmd("sm_j", JaguarUse, "Changes your survivor character into Jaguar Francis");
    RegConsoleCmd("sm_cc", CCoachUse, "Changes your survivor character into Clubbin Coach");
    RegConsoleCmd("sm_fr", FreemanUse, "Changes your survivor character into Freeman");  
    RegConsoleCmd("sm_g", GunRunnerUse, "Changes your survivor character into Gunrunner Nick");  
    RegConsoleCmd("sm_m", MrDeathUse, "Changes your survivor character into MrDeath");  
    RegConsoleCmd("sm_tz", TZoeyUse, "Changes your survivor character into Tactical Zoey");  
    
    RegAdminCmd("sm_csc", InitiateMenuAdmin, ADMFLAG_GENERIC, "Brings up a menu to select a client's character"); 
    RegConsoleCmd("sm_csm", ShowMenu, "Brings up a menu to select a client's character");
    
    
    new Handle:AdminsOnly = CreateConVar("l4d_csm_admins_only", "0","Changes access to the sm_csm command. 1 = Admin access only.",FCVAR_SPONLY,true, 0.0, true, 1.0);
    g_bAdminsOnly = GetConVarBool(AdminsOnly);
    HookConVarChange(AdminsOnly, _ConVarChange__AdminsOnly);
    
    AutoExecConfig(true, "l4dscs");
}  


public Action:ZoeyUse(client, args)  
{
	if (!IsSurvivor(client)){
		PrintToChat(client, "You must be in the survivor team to use this command!");
		return;
	}
	SetEntProp(client, Prop_Send, "m_survivorCharacter", ZOEY);  
	SetEntityModel(client, MODEL_ZOEY);
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Zoey");
	}
}  

public Action:NickUse(client, args)  
{
	if (!IsSurvivor(client)){
		PrintToChat(client, "You must be in the survivor team to use this command!");
		return;
	} 
	SetEntProp(client, Prop_Send, "m_survivorCharacter", NICK);  
	SetEntityModel(client, MODEL_NICK);
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Nick");
	}
}  

public Action:EllisUse(client, args)  
{
	if (!IsSurvivor(client)){
		PrintToChat(client, "You must be in the survivor team to use this command!");
		return;
	} 
	SetEntProp(client, Prop_Send, "m_survivorCharacter", ELLIS);  
	SetEntityModel(client, MODEL_ELLIS);
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Ellis");
	}
}  

public Action:CoachUse(client, args)  
{
	if (!IsSurvivor(client)){
		PrintToChat(client, "You must be in the survivor team to use this command!");
		return;
	}
	SetEntProp(client, Prop_Send, "m_survivorCharacter", COACH);  
	SetEntityModel(client, MODEL_COACH);
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Coach");
	}
}  

public Action:RochelleUse(client, args)  
{
	if (!IsSurvivor(client)){
		PrintToChat(client, "You must be in the survivor team to use this command!");
		return;
	}
	SetEntProp(client, Prop_Send, "m_survivorCharacter", ROCHELLE);  
	SetEntityModel(client, MODEL_ROCHELLE);  
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Rochelle");
	}
}  

public Action:BillUse(client, args)  
{
	if (!IsSurvivor(client)){
		PrintToChat(client, "You must be in the survivor team to use this command!");
		return;
	}
	SetEntProp(client, Prop_Send, "m_survivorCharacter", BILL);  
	SetEntityModel(client, MODEL_BILL);
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Bill");
	}
}  

public Action:BikerUse(client, args)  
{
	if (!IsSurvivor(client)){
		PrintToChat(client, "You must be in the survivor team to use this command!");
		return;
	}
	SetEntProp(client, Prop_Send, "m_survivorCharacter", FRANCIS);  
	SetEntityModel(client, MODEL_FRANCIS); 
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Francis");
	}
}  

public Action:LouisUse(client, args)  
{  
	if (!IsSurvivor(client)){
		PrintToChat(client, "You must be in the survivor team to use this command!");
		return;
	}
	SetEntProp(client, Prop_Send, "m_survivorCharacter", LOUIS);  
	SetEntityModel(client, MODEL_LOUIS);  
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Louis");
	}
}  
public Action:AdaWongUse(client, args)  
{
	if (!IsSurvivor(client)){
		PrintToChat(client, "You must be in the survivor team to use this command!");
		return;
	}
	SetEntProp(client, Prop_Send, "m_survivorCharacter", ROCHELLE);  
	SetEntityModel(client, MODEL_ADAWONG);
	{
		//SetClientInfo(client, "name", "AdaWong");
	}
} 

public Action:RebelUse(client, args)  
{
    if (!IsSurvivor(client)){
        PrintToChat(client, "You must be in the survivor team to use this command!");
        return;
    }
    SetEntProp(client, Prop_Send, "m_survivorCharacter", ELLIS);  
    SetEntityModel(client, MODEL_REBEL);
    {
        //SetClientInfo(client, "name", "Rebel");
    }
}

public Action:JaguarUse(client, args)  
{
    if (!IsSurvivor(client)){
        PrintToChat(client, "You must be in the survivor team to use this command!");
        return;
    }
    SetEntProp(client, Prop_Send, "m_survivorCharacter", FRANCIS);  
    SetEntityModel(client, MODEL_JAGUAR);
    {
        //SetClientInfo(client, "name", "Jaguarmeister Francis");
    }
} 

public Action:SEllisUse(client, args)  
{
    if (!IsSurvivor(client)){
        PrintToChat(client, "You must be in the survivor team to use this command!");
        return;
    }
    SetEntProp(client, Prop_Send, "m_survivorCharacter", ELLIS);  
    SetEntityModel(client, MODEL_SELLIS);
    {
       // SetClientInfo(client, "name", "Serious Ellis");
    }
} 

public Action:CCoachUse(client, args)  
{
    if (!IsSurvivor(client)){
        PrintToChat(client, "You must be in the survivor team to use this command!");
        return;
    }
    SetEntProp(client, Prop_Send, "m_survivorCharacter", COACH);  
    SetEntityModel(client, MODEL_CCOACH);
    {
       // SetClientInfo(client, "name", "Serious Ellis");
    }
} 

public Action:FreemanUse(client, args)  
{
    if (!IsSurvivor(client)){
        PrintToChat(client, "You must be in the survivor team to use this command!");
        return;
    }
    SetEntProp(client, Prop_Send, "m_survivorCharacter", NICK);  
    SetEntityModel(client, MODEL_FREEMAN);
    {
       // SetClientInfo(client, "name", "Serious Ellis");
    }
} 

public Action:GunRunnerUse(client, args)  
{
    if (!IsSurvivor(client)){
        PrintToChat(client, "You must be in the survivor team to use this command!");
        return;
    }
    SetEntProp(client, Prop_Send, "m_survivorCharacter", NICK);  
    SetEntityModel(client, MODEL_GRUNNER);
    {
       // SetClientInfo(client, "name", "Serious Ellis");
    }
}

public Action:MrDeathUse(client, args)  
{
    if (!IsSurvivor(client)){
        PrintToChat(client, "You must be in the survivor team to use this command!");
        return;
    }
    SetEntProp(client, Prop_Send, "m_survivorCharacter", ELLIS);  
    SetEntityModel(client, MODEL_MRDEATH);
    {
       // SetClientInfo(client, "name", "Serious Ellis");
    }
}

public Action:TZoeyUse(client, args)  
{
    if (!IsSurvivor(client)){
        PrintToChat(client, "You must be in the survivor team to use this command!");
        return;
    }
    SetEntProp(client, Prop_Send, "m_survivorCharacter", ZOEY);  
    SetEntityModel(client, MODEL_TZOEY);
    {
       // SetClientInfo(client, "name", "Serious Ellis");
    }
}



public OnMapStart() 
{     
	SetConVarInt(FindConVar("precache_all_survivors"), 1); 
	
	if (!IsModelPrecached("models/survivors/survivor_teenangst.mdl"))    PrecacheModel("models/survivors/survivor_teenangst.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_biker.mdl"))     PrecacheModel("models/survivors/survivor_biker.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_manager.mdl"))    PrecacheModel("models/survivors/survivor_manager.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_namvet.mdl"))     PrecacheModel("models/survivors/survivor_namvet.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_gambler.mdl"))    PrecacheModel("models/survivors/survivor_gambler.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_coach.mdl"))     PrecacheModel("models/survivors/survivor_coach.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_mechanic.mdl"))    PrecacheModel("models/survivors/survivor_mechanic.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_producer.mdl"))     PrecacheModel("models/survivors/survivor_producer.mdl", false); 
	if (!IsModelPrecached("models/survivors/survivor_adawong.mdl"))     PrecacheModel("models/survivors/survivor_adawong.mdl", false);

} 

/* This Admin Menu was taken from csm, all credits go to Mi123645 */ 
public Action:InitiateMenuAdmin(client, args)  
{ 
    if (client == 0)  
    { 
        ReplyToCommand(client, "Menu is in-game only."); 
        return; 
    } 
    
    decl String:name[MAX_NAME_LENGTH], String:number[10]; 
    
    new Handle:menu = CreateMenu(ShowMenu2); 
    SetMenuTitle(menu, "Select a client:"); 
    
    for (new i = 1; i <= MaxClients; i++) 
    { 
        if (!IsClientInGame(i)) continue; 
        if (GetClientTeam(i) != 2) continue; 
        if (i == client) continue; 
        
        Format(name, sizeof(name), "%N", i); 
        Format(number, sizeof(number), "%i", i); 
        AddMenuItem(menu, number, name); 
    } 
    
    
    SetMenuExitButton(menu, true); 
    DisplayMenu(menu, client, MENU_TIME_FOREVER); 
} 

public ShowMenu2(Handle:menu, MenuAction:action, param1, param2)  
{ 
    switch (action)  
    { 
        case MenuAction_Select:  
        { 
            decl String:number[4]; 
            GetMenuItem(menu, param2, number, sizeof(number)); 
            
            g_iSelectedClient = StringToInt(number); 
            
            new args; 
            ShowMenuAdmin(param1, args); 
        } 
        case MenuAction_Cancel: 
        { 
            
        } 
        case MenuAction_End:  
        { 
            CloseHandle(menu); 
        } 
    } 
} 

public Action:ShowMenuAdmin(client, args)  
{ 
    decl String:sMenuEntry[8]; 
    
    new Handle:menu = CreateMenu(CharMenuAdmin); 
    SetMenuTitle(menu, "Choose a character:"); 
    
    
    IntToString(NICK, sMenuEntry, sizeof(sMenuEntry)); 
    AddMenuItem(menu, sMenuEntry, "Nick"); 
    IntToString(ROCHELLE, sMenuEntry, sizeof(sMenuEntry)); 
    AddMenuItem(menu, sMenuEntry, "Rochelle"); 
    IntToString(COACH, sMenuEntry, sizeof(sMenuEntry)); 
    AddMenuItem(menu, sMenuEntry, "Coach"); 
    IntToString(ELLIS, sMenuEntry, sizeof(sMenuEntry)); 
    AddMenuItem(menu, sMenuEntry, "Ellis"); 
    
    IntToString(BILL, sMenuEntry, sizeof(sMenuEntry)); 
    AddMenuItem(menu, sMenuEntry, "Bill");     
    IntToString(ZOEY, sMenuEntry, sizeof(sMenuEntry)); 
    AddMenuItem(menu, sMenuEntry, "Zoey"); 
    IntToString(FRANCIS, sMenuEntry, sizeof(sMenuEntry)); 
    AddMenuItem(menu, sMenuEntry, "Francis"); 
    IntToString(LOUIS, sMenuEntry, sizeof(sMenuEntry)); 
    AddMenuItem(menu, sMenuEntry, "Louis");
    IntToString(8, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "AdaWong");
    IntToString(9, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Rebel"); 
    IntToString(10, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Jaguarmeister"); 
    IntToString(13, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Serious Ellis"); 
    IntToString(14, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Clubbin Coach");
    IntToString(15, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Gordon Freeman");
    IntToString(16, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "GunRunner Nick");
    IntToString(17, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Mr Death");
    IntToString(18, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Tactical Zoey");
    
    SetMenuExitButton(menu, true); 
    DisplayMenu(menu, client, MENU_TIME_FOREVER); 
} 

public CharMenuAdmin(Handle:menu, MenuAction:action, param1, param2)  
{ 
    switch (action)  
    { 
        case MenuAction_Select:  
        { 
            decl String:item[8]; 
            GetMenuItem(menu, param2, item, sizeof(item)); 
            
            switch(StringToInt(item))  
            { 
                case NICK:        {    NickUse(g_iSelectedClient, NICK);        }  
                case ROCHELLE:    {    RochelleUse(g_iSelectedClient, ROCHELLE);    }  
                case COACH:        {    CoachUse(g_iSelectedClient, COACH);        }  
                case ELLIS:        {    EllisUse(g_iSelectedClient, ELLIS);        }  
                case BILL:        {    BillUse(g_iSelectedClient, BILL);        }  
                case ZOEY:        {    ZoeyUse(g_iSelectedClient, ZOEY);        }  
                case FRANCIS:    {    BikerUse(g_iSelectedClient, FRANCIS);    }  
                case LOUIS:        {    LouisUse(g_iSelectedClient, LOUIS);        }  
                case 8:        {    AdaWongUse(g_iSelectedClient, ROCHELLE);        }  
                case 9:        {    RebelUse(g_iSelectedClient, ELLIS);        }
                case 10:        {    JaguarUse(g_iSelectedClient, FRANCIS);        } 
                case 13:        {    SEllisUse(g_iSelectedClient, ELLIS);        } 
                
            } 
        } 
        case MenuAction_Cancel: 
        { 
            
        } 
        case MenuAction_End:  
        { 
            //CloseHandle(menu); 
        } 
    } 
} 

public Action:ShowMenu(client, args) 
{
    if (client == 0) 
    {
        ReplyToCommand(client, "[CSM] Character Select Menu is in-game only.");
        return;
    }
    if (GetClientTeam(client) != 2)
    {
        ReplyToCommand(client, "[CSM] Character Select Menu is only available to survivors.");
        return;
    }
    if (!IsPlayerAlive(client)) 
    {
        ReplyToCommand(client, "[CSM] You must be alive to use the Character Select Menu!");
        return;
    }
    if (GetUserFlagBits(client) == 0 && g_bAdminsOnly)
    {
        ReplyToCommand(client, "[CSM] Character Select Menu is only available to admins.");
        return;
    }
    decl String:sMenuEntry[8];
    
    new Handle:menu = CreateMenu(CharMenu);
    SetMenuTitle(menu, "● Selecciona Tu Personaje:");
    
    
    IntToString(NICK, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Nick");
    IntToString(ROCHELLE, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Rochelle");
    IntToString(COACH, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Coach");
    IntToString(ELLIS, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Ellis");
    
    IntToString(BILL, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Bill");    
    IntToString(ZOEY, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Zoey");
    IntToString(FRANCIS, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Francis");
    IntToString(LOUIS, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Louis");
    IntToString(8, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Adawong");
    IntToString(9, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Resistance Ellis");
    IntToString(12, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Jaguarmeister Francis");
    IntToString(13, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Serious Ellis");
    IntToString(14, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Clubbin Coach");
    IntToString(15, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Gordon Freeman");
    IntToString(16, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "GunRunner Nick");
    IntToString(17, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Mr Death");
    IntToString(18, sMenuEntry, sizeof(sMenuEntry));
    AddMenuItem(menu, sMenuEntry, "Tactical Zoey");
    
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


public CharMenu(Handle:menu, MenuAction:action, param1, param2) 
{
    switch (action) 
    {
        case MenuAction_Select: 
        {
            decl String:item[8];
            GetMenuItem(menu, param2, item, sizeof(item));
            
            switch(StringToInt(item)) 
            {
                case NICK:        {    NickUse(param1, NICK);        }
                case ROCHELLE:    {    RochelleUse(param1, ROCHELLE);    }
                case COACH:        {    CoachUse(param1, COACH);        }
                case ELLIS:        {    EllisUse(param1, ELLIS);        }
                case BILL:        {    BillUse(param1, BILL);        }
                case ZOEY:        {    ZoeyUse(param1, ZOEY);        }
                case FRANCIS:    {    BikerUse(param1, FRANCIS);    }
                case LOUIS:        {    LouisUse(param1, LOUIS);        }
                case 8:        {    AdaWongUse(param1, ROCHELLE);        }
                case 9:        {    RebelUse(param1, ELLIS);        }
                case 12:        {    JaguarUse(param1, FRANCIS);        }
                case 13:        {    SEllisUse(param1, ELLIS);        }
                case 14:        {    CCoachUse(param1, COACH);        }
                case 15:        {    FreemanUse(param1, NICK);        }
                case 16:        {    GunRunnerUse(param1, NICK);        }
                case 17:        {    MrDeathUse(param1, ELLIS);        }
                case 18:        {    TZoeyUse(param1, ZOEY);        }
                
            }
        }
        case MenuAction_Cancel:
        {
            
        }
        case MenuAction_End: 
        {
            CloseHandle(menu);
        }
    }
}

public _ConVarChange__AdminsOnly(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
    g_bAdminsOnly = GetConVarBool(convar);
} 

static bool:IsSurvivor(iClient)
{
	if (iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || GetClientTeam(iClient) != 2)
		return false;
	
	return true;
}