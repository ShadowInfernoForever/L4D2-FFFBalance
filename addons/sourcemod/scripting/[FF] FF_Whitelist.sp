// Include necessary SourceMod libraries
#include <sourcemod>
#include <clientprefs>
#include <cstrike>

// Remove redundant MAX_NAME_LENGTH definition (it's already defined in Sourcemod)
#if defined(MAX_NAME_LENGTH)
#undef MAX_NAME_LENGTH
#endif

#define MAX_NAME_LENGTH 64  // Re-define it here if needed

// Declare the menu and trusted players list
Handle g_Menu;
ArrayList g_TrustedPlayers;

// Declare the MenuHandler callback function before using it
public void MenuHandler(int client, int menu, int item);  // Declare the function prototype

// Initialize the trusted players list
public void OnPluginStart()
{
    g_TrustedPlayers = new ArrayList();

    // Register the console command for the whitelist
    RegConsoleCmd("sm_show_whitelist", Command_ShowWhitelist, "Show the whitelist menu");
}

// Command to show the whitelist menu
public Action Command_ShowWhitelist(int client, int args)
{
    // Check if the client is an admin
    if (!IsAdmin(client)) {
        PrintToChat(client, "You are not an admin and cannot access this menu.");
        return Plugin_Handled;
    }

    // Create the menu and set the callback function
    g_Menu = CreateMenu(MenuHandler);  // MenuHandler is passed here
    SetMenuTitle(g_Menu, "Whitelist Management");

    // Loop through all players and add them to the menu
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && IsClientConnected(i)) {
            char playerName[MAX_NAME_LENGTH];
            GetClientName(i, playerName, sizeof(playerName));

            // Use the player's client index for the item label
            char itemLabel[64];
            IntToString(i, itemLabel, sizeof(itemLabel));  // Using client index as item label
            AddMenuItem(g_Menu, itemLabel, playerName);  // Add player to the menu
        }
    }

    // Display the menu to the client
    DisplayMenu(g_Menu, client, 0);  // The 0 flag means no special menu flags
    return Plugin_Handled;
}

// Define the MenuHandler function correctly
public void MenuHandler(int client, int menu, int item)
{
    char playerName[MAX_NAME_LENGTH];

    // Get the selected player's name from the menu
    GetMenuItem(menu, item, playerName, sizeof(playerName));

    // Check if the selected player is in the trusted list
    if (IsTrustedPlayer(client)) {
        PrintToChat(client, "Player %s is already in the trusted list.", playerName);
    } else {
        // Add the player to the trusted list (this could be a Steam ID or client index)
        g_TrustedPlayers.Push(client);  // Store the client index in the trusted list
        PrintToChat(client, "Player %s added to the trusted list.", playerName);
    }
}

// Check if the player is in the trusted list
public bool IsTrustedPlayer(int client)
{
    // Loop through the trusted players list
    for (int i = 0; i < g_TrustedPlayers.Length; i++) {
        int trustedClient = g_TrustedPlayers.Get(i);  // Get the trusted client index
        if (trustedClient == client) {
            return true;  // Player found in the trusted list
        }
    }

    return false;  // Player not found
}

// IsAdmin function to check admin access
bool IsAdmin(int client) {
    return CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false);
}
