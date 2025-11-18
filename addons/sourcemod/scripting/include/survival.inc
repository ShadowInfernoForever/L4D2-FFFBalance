#if defined _survival_included
 #endinput
#endif
#define _survival_included

public SharedPlugin __pl_survival = 
{
    name = "survival",
    file = "survival.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_survival_SetNTVOptional()
{

}
#endif

/**
 * @brief Called when a team has won the game
 *
 * @param team  team index. 1 if green, 2 if yellow
 *
 * @noreturn
 */
forward void Survival_OnWin(int team);

/**
 * @brief Get whether or not if a client has swap the team
 *
 * @param client    client index
 *
 * @return  true if is
 */
native bool Survival_HasSwapTeam(int client);
