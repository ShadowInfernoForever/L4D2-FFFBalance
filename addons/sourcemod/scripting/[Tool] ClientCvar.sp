#include <sourcemod>

public Plugin myinfo =
{
    name = "[L4D2] Client Console Command Executor",
    author = "Shadow",
    description = "Executes a console command for a specific client.",
    version = "1.0",
    url = ""
};

public void OnPluginStart() {
    RegConsoleCmd("sm_ccvar", Command_sm_ccvar, "Executes a console command for a specific client.");
}

public Action Command_sm_ccvar(int client, int args) {
    if (args < 2) {
        PrintToChat(client, "Usage: sm_ccvar <name> <cvar> [value]");
        return Plugin_Handled; // Not enough arguments
    }

    char targetName[64];
    GetCmdArg(1, targetName, sizeof(targetName)); // Get the player name

    // Find the client by name
    int targetClient = FindClientByName(targetName);
    if (targetClient == 0) {
        PrintToChat(client, "No player with the name '%s' found.", targetName);
        return Plugin_Handled;
    }

    // Create a buffer for the command
    char command[256];
    command[0] = '\0'; // Initialize the string

    // Get the cvar
    char cvar[128];
    GetCmdArg(2, cvar, sizeof(cvar)); // Get the console variable

    // Start building the command
    Format(command, sizeof(command), "%s", cvar); // Initialize with cvar

    // Check if there's a value
    if (args > 3) {
        char value[128];
        GetCmdArg(3, value, sizeof(value)); // Get the value if provided
        Format(command, sizeof(command), "%s %s", command, value); // Append value
    }

    // Print feedback to the original client
    PrintToChat(client, "Executing command '%s' for client '%s'.", command, targetName);
    
    // Execute the command for the targeted client
    ClientCommand(targetClient, command);

    return Plugin_Handled;
}

// Helper function to find a client by name
int FindClientByName(const char[] name) {
    char clientName[64];
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            GetClientName(i, clientName, sizeof(clientName)); // Get the client's name
            if (StrEqual(clientName, name, false)) {
                return i; // Return the client index
            }
        }
    }
    return 0; // Not found
}