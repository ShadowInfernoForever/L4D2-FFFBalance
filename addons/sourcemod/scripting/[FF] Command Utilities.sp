    #include <sourcemod>
    #include <sdktools>
    #include <colors>
    #include <builtinvotes>
    #include <left4dhooks>

    Handle g_hCustomVote = INVALID_HANDLE;

    #define PLUGIN_VERSION "1.2"
    #define Advert_4 "ui/alert_clink.wav"
    #define DEFAULT_MAX_PLAYERS 4

    ConVar g_cvMaxPlayers;
    ConVar cVarMinUpdateRate = null;
    ConVar cVarMaxUpdateRate = null;
    ConVar cVarMinInterpRatio = null;
    ConVar cVarMaxInterpRatio = null;

    public Plugin myinfo = 
    {
        name = "[L4D] Commands Handler",
        author = "Shadow",
        description = "To Allow Comands in chat con Lerp Real!",
        version = PLUGIN_VERSION,
        url = ""
    }

    public void OnPluginStart()
    {
        RegConsoleCmd("sm_ping", ShowPing);
        RegConsoleCmd("sm_lerp", ShowMyLerp);
        RegConsoleCmd("sm_lerps", ShowAllLerps);
        RegConsoleCmd("sm_balance", Command_Balance);
        RegConsoleCmd("sm_slots", slots);
        RegConsoleCmd("sm_jugadores", slots);
        RegConsoleCmd("sm_kill", Kill_Me);
        RegConsoleCmd("sm_progreso", ShowProgression);
        RegConsoleCmd("sm_mvote", Command_MVote);

        g_cvMaxPlayers = FindConVar("sv_maxplayers");
        
        cVarMinUpdateRate = FindConVar("sv_minupdaterate");
        cVarMaxUpdateRate = FindConVar("sv_maxupdaterate");
        cVarMinInterpRatio = FindConVar("sv_client_min_interp_ratio");
        cVarMaxInterpRatio = FindConVar("sv_client_max_interp_ratio");

        if(g_cvMaxPlayers == null)
        {
            LogError("Failed to find sv_maxplayers ConVar!");
        }
    }

    public void OnMapStart()
    {
        PrecacheSound(Advert_4, true);
    }

    public Action ShowProgression(int client, int args)
    {
        char mapName[64];
        GetCurrentMap(mapName, sizeof(mapName));

        int currentChapter = L4D_GetCurrentChapter();
        int maxChapters = L4D_GetMaxChapters();

        float maxMapFlow = L4D2Direct_GetMapMaxFlowDistance();
        float highestClientFlow = 0.0;

        if (maxMapFlow > 0.0)
        {
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
                {
                    float clientFlow = L4D2Direct_GetFlowDistance(i);
                    if (clientFlow > highestClientFlow)
                    {
                        highestClientFlow = clientFlow;
                    }
                }
            }
        }

        float progressPercent = 0.0;
        if (maxMapFlow > 0.0 && highestClientFlow > 0.0)
        {
            progressPercent = (highestClientFlow / maxMapFlow) * 100.0;
            if (progressPercent > 100.0) 
                progressPercent = 100.0;
        }

        CPrintToChatAllEx(client, "<{olive}Progreso{default}> Mapa: {teamcolor}%s{default} @ Capítulo {olive}%d{default} / {olive}%d", mapName, currentChapter, maxChapters);
        
        CPrintToChatAllEx(client, "<{olive}Avance{default}> Distancia del equipo: {green}%.1f%%{default}", progressPercent);

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                EmitSoundToClient(i, Advert_4); 
            } 
        }
        return Plugin_Handled;
    }

    public Action ShowPing(int client, int args)
    {
        float pingReal = GetClientAvgLatency(client, NetFlow_Both) * 1000.0;
        
        int scoreboardEntity = GetPlayerResourceEntity();
        int scoreboardPing = GetEntProp(scoreboardEntity, Prop_Send, "m_iPing", _, client);

        float packets = GetClientAvgPackets(client, NetFlow_Both);
        float loss = GetClientAvgLoss(client, NetFlow_Both);
        float choke = GetClientAvgChoke(client, NetFlow_Both);

        CPrintToChatAllEx(client, "<{olive}Ping{default}> {teamcolor}%N{default} @ {teamcolor}%.0f{default} - {teamcolor}Real", client, pingReal);
        CPrintToChatAllEx(client, "<{olive}ScPing{default}> {teamcolor}%N{default} @ {green}%d{default} - {olive}Scoreboard", client, scoreboardPing);
        CPrintToChatAllEx(client, "<{olive}Packets{default}> {teamcolor}%N{default} @ {teamcolor}%f", client, packets);
        CPrintToChatAllEx(client, "<{olive}Loss{default}> {teamcolor}%N{default} @ {teamcolor}%f", client, loss);
        CPrintToChatAllEx(client, "<{olive}Choke{default}> {teamcolor}%N{default} @ {teamcolor}%f", client, choke);

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                EmitSoundToClient(i, Advert_4); 
            } 
        }
        return Plugin_Handled;
    }

    public Action ShowMyLerp(int client, int args)
    {
        if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
        {
            float clientLerp = GetExactLerpTime(client);
            CPrintToChatAllEx(client, "<{olive}Lerp{default}> {teamcolor}%N{default} @ {green}%.1f ms", client, (clientLerp * 1000.0) + 0.05);
            
            EmitSoundToClient(client, Advert_4);
        }
        return Plugin_Handled;
    }

    public Action ShowAllLerps(int client, int args)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                float clientLerp = GetExactLerpTime(i);
                CPrintToChatAllEx(i, "<{olive}Lerp{default}> {teamcolor}%N{default} @ {green}%.1f ms", i, (clientLerp * 1000.0) + 0.05);
            }
        }

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                EmitSoundToClient(i, Advert_4); 
            } 
        }
        return Plugin_Handled;
    }

    // Lerp calculation logic, extracted from lerpmonitor++
    float GetExactLerpTime(int client)
    {
        char buffer[64];

        if (!GetClientInfo(client, "cl_updaterate", buffer, sizeof(buffer))) {
            buffer = "";
        }
        int updateRate = StringToInt(buffer);
        
        float minUpdateRate = (cVarMinUpdateRate != null) ? cVarMinUpdateRate.FloatValue : 20.0;
        float maxUpdateRate = (cVarMaxUpdateRate != null) ? cVarMaxUpdateRate.FloatValue : 100.0;
        updateRate = RoundFloat(Math_Clamp(float(updateRate), minUpdateRate, maxUpdateRate));

        if (!GetClientInfo(client, "cl_interp_ratio", buffer, sizeof(buffer))) {
            buffer = "";
        }
        float flLerpRatio = StringToFloat(buffer);

        if (cVarMinInterpRatio != null && cVarMaxInterpRatio != null && cVarMinInterpRatio.FloatValue != -1.0) {
            flLerpRatio = Math_Clamp(flLerpRatio, cVarMinInterpRatio.FloatValue, cVarMaxInterpRatio.FloatValue);
        }

        if (!GetClientInfo(client, "cl_interp", buffer, sizeof(buffer))) {
            buffer = "";
        }
        float flLerpAmount = StringToFloat(buffer);

        if (updateRate <= 0) updateRate = 20;

        return Math_Max(flLerpAmount, flLerpRatio / updateRate);
    }

    float Math_Max(float a, float b)
    {
        return (a > b) ? a : b;
    }

    float Math_Clamp(float inc, float low, float high)
    {
        return (inc > high) ? high : ((inc < low) ? low : inc);
    }

    public Action Command_Balance(int client, int args)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                CPrintToChat(i, "{green} ➤ [FFTotalGameBalance]{default}: https://github.com/ShadowInfernoForever/L4D2-FFFBalance");
                EmitSoundToClient(i, Advert_4); 
            } 
        }
        return Plugin_Handled;
    }

    public Action Command_MVote(int client, int args)
    {
        if (args < 1)
        {
            PrintToChat(client, "Uso: !mvote <mensaje>");
            return Plugin_Handled;
        }

        if (g_hCustomVote != INVALID_HANDLE)
        {
            PrintToChat(client, "Ya hay un voto en curso.");
            return Plugin_Handled;
        }

        char voteText[256];
        GetCmdArgString(voteText, sizeof(voteText));
        StripQuotes(voteText);

        g_hCustomVote = CreateBuiltinVote(CustomVote_Handler, BuiltinVoteType_Custom_YesNo);
        SetBuiltinVoteArgument(g_hCustomVote, voteText);
        SetBuiltinVoteInitiator(g_hCustomVote, client);
        DisplayBuiltinVoteToAll(g_hCustomVote, 20);

        return Plugin_Handled;
    }

    public int CustomVote_Handler(Handle vote, BuiltinVoteAction action, int param1, int param2)
    {
        switch (action)
        {
            case BuiltinVoteAction_End:
            {
                g_hCustomVote = INVALID_HANDLE;
            }
            case BuiltinVoteAction_VoteEnd:
            {
                if (param1 == BUILTINVOTES_VOTE_YES)
                {
                    CPrintToChatAll("{green}✔ Votación aprobada.");
                }
                else
                {
                    CPrintToChatAll("{red}✘ Votación rechazada.");
                }
            }
        }
        return 0;
    }

    public Action Kill_Me(int client, int args)
    {
        if (!IsPlayerAlive(client)) return Plugin_Handled;

        ForcePlayerSuicide(client);

        char person[128];
        GetClientName(client, person, sizeof(person));

        char randstartMsg[][] = {
            "{default} ☠ *DEAD* {teamcolor}%s{default}: Dice Adiós mundo cruel!",
            "{default} ☠ *DEAD* {teamcolor}%s{default} Se voló la tapa del zapallo",
            "{default} ☠ *DEAD* {teamcolor}%s{default} Ha Dejado de Existir",
            "{default} ☠ *DEAD* {teamcolor}%s{default} Se fué con jesucito"
        };

        int randomIndex = GetRandomInt(0, sizeof(randstartMsg) - 1);
        CPrintToChatAllEx(client, randstartMsg[randomIndex], person);
        return Plugin_Handled;
    }

    public Action slots(int client, int args)
    {
        int playerCount = 0;
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsClientConnected(i) && !IsFakeClient(i))
            {
                playerCount++;
            }
        }

        int maxSlots = g_cvMaxPlayers.IntValue;
        if(maxSlots <= 0)
        {
            maxSlots = DEFAULT_MAX_PLAYERS;
        }

        CPrintToChatAllEx(client, "<{olive}Jugadores{default}> {teamcolor}%d{default} / {olive}%d max", playerCount, maxSlots);
        return Plugin_Handled;
    }
