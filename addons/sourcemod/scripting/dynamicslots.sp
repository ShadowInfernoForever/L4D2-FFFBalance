/**
 * =============================================================================
 * Ready Up - Dynamic Server Slots w/ reserve (C)2015 Jessica "jess" Henderson
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 */

#define PLUGIN_VERSION "reloaded alpha 1 hotfix 2"
#include <sourcemod>

public Plugin:myinfo = { name = "dynamic server slots", author = "url", description = "dynamic server slots w/ reserve plugin", version = PLUGIN_VERSION, url = "url", };

new Handle:playableSlots, Handle:reserveSettings;
new String:t_kickText[64];

public OnPluginStart() {

	CreateConVar("sm_dynamicslots_version", PLUGIN_VERSION, "version header");
	playableSlots	= CreateConVar("sm_dynamicslots_playable","12","the number of playable slots on the server. There is always 1 additional slot for reserve player connections.");
	reserveSettings	= CreateConVar("sm_dynamicslots_kicking","1","if 1, it will kick the player with the shortest play time to make room, otherwise the player with the longest playtime, who isn't a reserve player.");

	HookEvent("player_disconnect", eventPlayerDisconnect);

	LoadTranslations("dynamicslots.phrases");

	AutoExecConfig(true, "sm_dynamicslots.cfg");
}

public OnConfigsExecuted() { AutoExecConfig(true, "sm_dynamicslots"); }

public Action:eventPlayerDisconnect(Handle:event, const String:event_name[], bool:dontBroadcast) {

	new client	= GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || !IsClientAuthorized(client)) { UpdateDynamicSlots(); }
}

public OnClientPostAdminCheck(client) {

	UpdateDynamicSlots();		// Whenever a client connects, quickly update the slots.

	/*

		We can now check if the player has reserve privileges, but we only do this if the playableslots are full.
	
	*/
	new clients		= 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && client != i) { clients++; }
	}
	if (clients >= GetConVarInt(playableSlots) + GetSpectatorCount()) {

		/*

			The server is full of playable slots, so let's find out of the player has the reserve flag.
			Note	: If the player does not have the reserve flag, the player will be immediately dropped from the server.

		*/
		if (!IsReserve(client, "a") && !IsReserve(client, "z")) {

			Format(t_kickText, sizeof(t_kickText), "%T", "no playable slots", client);
			KickClient(client, t_kickText);
		}
		else {

			/*
				It's unfortunate, but the server has no playable slots and the connecting player has reserve access.
				I'm going to try to find a player to remove from the server, but if I can't, this player will be
				disconnected, anyway.
			*/
			FindKickableClient(client);
		}
	}
}

stock FindKickableClient(client) {

	Format(t_kickText, sizeof(t_kickText), "%T", "reserve player kick", client);
	if (GetConVarInt(reserveSettings) == 0) {

		for (new i = 1; i <= MaxClients; i++) {

			if (IsClientInGame(i) && !IsFakeClient(i) && i != client && !IsReserve(i, "a") && !IsReserve(i, "z")) {

				KickClient(i, t_kickText);
				return;
			}
		}
	}
	else {

		for (new i = MaxClients; i > 0; i--) {

			if (IsClientInGame(i) && !IsFakeClient(i) && i != client && !IsReserve(i, "a") && !IsReserve(i, "z")) {

				KickClient(i, t_kickText);
				return;
			}
		}
	}
	/*

		There are no players that can be removed for this reserved player, so unfortunate the player will
		be removed from the server, because the server is simply full.

	*/
	Format(t_kickText, sizeof(t_kickText), "%T", "no playable slots", client);
	KickClient(client, t_kickText);
}

stock bool:IsReserve(client, String:permissions[]) {

	decl flags;
	flags = GetUserFlagBits(client);
	decl cflags;
	cflags = ReadFlagString(permissions);
	
	if (flags & cflags) return true;
	return false;
}

stock UpdateDynamicSlots() {

	SetConVarInt(FindConVar("sv_maxplayers"), GetConVarInt(playableSlots) + 1 + GetSpectatorCount());
	SetConVarInt(FindConVar("sv_visiblemaxplayers"), GetConVarInt(playableSlots) + 1 + GetSpectatorCount());
	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, true, GetConVarInt(playableSlots) * 1.0);
	SetConVarBounds(FindConVar("survivor_limit"), ConVarBound_Upper, true, GetConVarInt(playableSlots) * 1.0);
	SetConVarInt(FindConVar("z_max_player_zombies"), GetConVarInt(playableSlots));
	SetConVarInt(FindConVar("survivor_limit"), GetConVarInt(playableSlots));
}

stock GetSpectatorCount() {

	new count	= 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 1) { count++; }
	}
	return count;
}