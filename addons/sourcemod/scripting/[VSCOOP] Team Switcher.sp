#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
    name        = "ForceAllInfected",
    author      = "Shadow",
    description = "Pasa automaticamente a todos los jugadores a infectados cada 5 segundos",
    version     = "1.1"
};

public void OnMapStart()
{
    // Timer infinito, cada 5 segundos
    CreateTimer(5.0, Timer_ConvertToInfected, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ConvertToInfected(Handle timer)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;

        int team = GetClientTeam(i);

        // Si ya es infectado, no se toca
        if (team == 3)
            continue;

        ChangeClientTeam(i, 3);
    }

    // No spameamos chat para no molestar
    // Si quieres mensaje cada X segundos lo podemos agregar

    return Plugin_Continue; // Repite infinito
}