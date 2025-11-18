#if defined _4v4_arena_included
 #endinput
#endif
#define _4v4_arena_included

public SharedPlugin __pl_4v4_arena = 
{
    name = "4v4_arena",
    file = "4v4_arena.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_4v4_arena_SetNTVOptional()
{
    MarkNativeAsOptional("SurvivorArena_GetTeam");
}
#endif

/**
 * @brief Called when someone try to give pill/adrenaline across team but blocked
 *
 * @param giver     client index who try to give
 * @param receiver  client index who try to receive
 * @param entity    pill/adrenaline index
 *
 * @noreturn
 */
forward void SurvivorArena_OnTakePillsBack(int giver, int receiver, int entity);

/**
 * @brief Get the current arena team of a client
 *
 * @param client    client index
 *
 * @return  0 if no team, 1 if green, 2 if yellow
 *
 */
native int SurvivorArena_GetTeam(int client);
