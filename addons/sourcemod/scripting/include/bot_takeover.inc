#if defined _bot_takeover_included
 #endinput
#endif
#define _bot_takeover_included

public SharedPlugin __pl_bot_takeover = 
{
    name = "bot_takeover",
    file = "bot_takeover.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_bot_takeover_SetNTVOptional()
{
    MarkNativeAsOptional("BotTakeOver_IsInTaking");
}
#endif

/**
 * @brief Return whether or not a survivor is in taking bot
 *
 * @param client	client index to check
 *
 * @return  true if is
 *
 */
native bool BotTakeOver_IsInTaking(int client);
