#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#define SMOKER_TONGUE_DELAY 0.1

static ConVar g_hCvarEnable, g_hCvarTongueDancing;
static bool g_bCvarEnable, g_bCvarTongueDancing;

static float 
    g_fAttack2[MAXPLAYERS+1];

void Smoker_OnModuleStart() {

    g_hCvarEnable 		  = CreateConVar( "AI_HardSI_Smoker_enable",   "1",   "0=Improves the Smoker behaviour off, 1=Improves the Smoker behaviour on.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarTongueDancing  = CreateConVar( "ai_Tongue_dancing_enable",         "1",    "If 1, Smoker do scratch animation when tongueting", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    GetCvars();
    g_hCvarEnable.AddChangeHook(ConVarChanged_EnableCvars);
    g_hCvarTongueDancing.AddChangeHook(ConVarChanged_EnableCvars);

    if(g_bCvarEnable) _OnModuleStart();
}

static void _OnModuleStart()
{
    if(g_bPluginEnd) return;
}

void Smoker_OnModuleEnd() 
{

}

static void ConVarChanged_EnableCvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
    GetCvars();

    if(g_bCvarEnable)
    {
        _OnModuleStart();
    }
    else
    {
        Smoker_OnModuleEnd();
    }
}

static void GetCvars()
{
    g_bCvarEnable = g_hCvarEnable.BoolValue;
    g_bCvarTongueDancing = g_hCvarTongueDancing.BoolValue;
}

// Actions API--------------

stock void AI_Smoker_OnActionCreated(BehaviorAction action, const char[] name)
{
    //if (!strcmp(name[6], "Behavior"))
    //{
    //	action.InitialContainedAction = SmokerBehavior_InitialContainedAction;
    //	action.InitialContainedActionPost = SmokerBehavior_InitialContainedAction_Post;
    //}

    if (strcmp(name[6], "Attack") == 0)
    {
        action.OnCommandAssault = SmokerAttack_OnCommandAssault;
    }
}

stock Action Smoker_OnPlayerRunCmd(int smoker, int &buttons ) { 
    if(!g_bCvarEnable) return Plugin_Continue;

    bool bHasSight = view_as<bool>(GetEntProp(smoker, Prop_Send, "m_hasVisibleThreats")); //Line of sight to survivors

    float now = GetEngineTime();
    if (g_bCvarTongueDancing == true && bHasSight && g_fAttack2[smoker] < now) 
    {
        buttons |= IN_ATTACK2;
        g_fAttack2[smoker] = GetEngineTime() + 0.2;
    }

    return Plugin_Changed;
}

static Action SmokerAttack_OnCommandAssault(any action, int actor, ActionDesiredResult result)
{
	// 保護smoker不受到nb_assault影響產生bug
	// 當Smoker的舌頭斷掉之後，站在原地不動不撤退 (nb_assault的bug)
	return Plugin_Handled;
}