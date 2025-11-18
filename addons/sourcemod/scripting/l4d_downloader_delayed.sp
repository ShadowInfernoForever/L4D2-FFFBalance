#define PLUGIN_VERSION 		"1.0"

/*=======================================================================================
	Change Log:

1.0 (xx-Feb-2019)
	- Initial release.

=======================================================================================

	Credits:
	 - Dr. Api - for sm string table exmaples.
	 - Lux - for finding signatures for me.
	 - SilverShot - for finding signatures for me and dhook idea.
	 - Peace-Maker - for finding offset walkaround + signature and helping with understanding C++ call
	 - gubka - for stringtable SDKCall examples for CS:GO
	 - asherkin - for explanation about "read" and "offset" stuff in gamedata.
	
=======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

Handle sdkTableDeleteAllStrings;
Handle sdkTableServer;
Handle sdkFindTable;

char g_sItems[8192][PLATFORM_MAX_PATH];
int g_iItemsTotal;

public Plugin myinfo =
{
	name = "[L4D] Delayed Downloader",
	author = "Alex Dragokas",
	description = "Increases client's join speed by delaying file downloading to a later stage - on a map transition",
	version = PLUGIN_VERSION,
	url = "https://dragokas.com"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar(				"l4d_downloader_delayed_version",		PLUGIN_VERSION,	"Plugin version", FCVAR_DONTRECORD );
	
	// SDKCalls
	Handle hGameConf = LoadGameConfigFile("l4d_downloader_delayed");
	if( hGameConf == null )
		SetFailState("Couldn't find the offsets and signatures file. Please, check that it is installed correctly.");
	
	// ----------------------------------------------------------------------------------------------------
	
	// DeleteAllStrings
	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CNetworkStringTable::DeleteAllStrings") == false )
		SetFailState("Could not load the \"CNetworkStringTable::DeleteAllStrings\" gamedata signature.");
	
	sdkTableDeleteAllStrings = EndPrepSDKCall();
	if( sdkTableDeleteAllStrings == null )
		SetFailState("Could not prep the \"CNetworkStringTable::DeleteAllStrings\" function.");
	
	// ----------------------------------------------------------------------------------------------------
	
	/*
	// Table Server
	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CNetworkStringTable::Server") == false )
		SetFailState("Could not load the \"CNetworkStringTable::Server\" gamedata signature.");
	
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	sdkTableServer = EndPrepSDKCall();
	if( sdkTableServer == null )
		SetFailState("Could not prep the \"CNetworkStringTable::Server\" function.");
	
	// ----------------------------------------------------------------------------------------------------
	*/
	
	// FindTable
	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CNetworkStringTable::FindTable") == false )
		SetFailState("Could not load the \"CNetworkStringTable::FindTable\" gamedata signature.");
	
	// Adds a parameter to the calling convention. This should be called in normal ascending order
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	sdkFindTable = EndPrepSDKCall();
	if( sdkFindTable == null )
		SetFailState("Could not prep the \"CNetworkStringTable::FindTable\" function.");
	
	// ----------------------------------------------------------------------------------------------------
	
	
	delete hGameConf;
	
	// Service commands (use with caution and if you really understand what you do !!! )
	RegAdminCmd("sm_dump_st", 		Cmd_DumpStringtables, 		ADMFLAG_ROOT, 	"Dump the list of stringtables to console and ALL tables to log file. Set arg 1 - to dump user data as well");
	RegAdminCmd("sm_dump_sti",	 	Cmd_DumpStringtableItems, 	ADMFLAG_ROOT, 	"Dump the items of specified stringtable to console and log file");
	RegAdminCmd("sm_remove_st",	 	Cmd_RemoveDownloadables, 	ADMFLAG_ROOT, 	"Remove downloadables stringtable items");
	RegAdminCmd("sm_restore_st",	Cmd_RestoreDownloadables, 	ADMFLAG_ROOT, 	"Restore downloadables stringtable items");
}

public void OnMapStart()
{
	// let all plugins time to fill items in download table
	CreateTimer(1.0, Timer_SaveDownloadables, _, TIMER_FLAG_NO_MAPCHANGE);
	
	// code to wait all clients finish joining => next, call: sm_remove_st
	// https://forums.alliedmods.net/showthread.php?p=2633656
}

public Action Timer_SaveDownloadables(Handle timer)
{
	SaveDownloadables();
}

public Action Cmd_RemoveDownloadables(int client, int args)
{
	// networkstringtableserver.cpp
	// CNetworkStringTableContainer *networkStringTableContainerServer = &s_NetworkStringTableServer;
	
	Handle hGameConf = LoadGameConfigFile("l4d_downloader_delayed");
	Address iPtrNetworkStringTableContainer = GameConfGetAddress(hGameConf, "s_NetworkStringTable");
	delete hGameConf;
	
	ReplyToCommand(client, "CNetworkStringTableContainer ptr = %i", iPtrNetworkStringTableContainer);
	
	if(iPtrNetworkStringTableContainer == Address_Null)
	{
		ReplyToCommand(client, "Couldn't find CNetworkStringTableContainer instance pointer.");
		return Plugin_Handled;
	}
	else {
		ReplyToCommand(client, "CNetworkStringTableContainer ptr = %i", iPtrNetworkStringTableContainer);
	}
	
	// networkstringtable.cpp
	// INetworkStringTable *CNetworkStringTableContainer::FindTable( const char *tableName ) const
	
	int iPtrNetworkStringTable = SDKCall(sdkFindTable, iPtrNetworkStringTableContainer, "downloadables");
	if(iPtrNetworkStringTable == 0)
	{
		ReplyToCommand(client, "Couldn't call FindTable.");
		return Plugin_Handled;
	}
	else {
		ReplyToCommand(client, "CNetworkStringTableContainer ptr = %i", iPtrNetworkStringTable);
	}
	
	// networkstringtable.h
	// class CNetworkStringTable  : public INetworkStringTable
	// protected:
	// void			DeleteAllStrings( void );
	
	bool bState = LockStringTables(false);
	SDKCall(sdkTableDeleteAllStrings, iPtrNetworkStringTable);
	LockStringTables(bState);
	
	ReplyToCommand(client, "DeleteAllStrings call is successfull.");
	
	return Plugin_Handled;
}

void SaveDownloadables()
{
	int iTable = FindStringTable("downloadables");
	if(iTable == INVALID_STRING_TABLE) {
		LogError("Cannot find 'downloadables' string table!");
		return;
	}
	
	g_iItemsTotal = 0;
	int iNum = GetStringTableNumStrings(iTable);

	for (int i = 0; i < iNum; i++)
	{
		ReadStringTable(iTable, i, g_sItems[g_iItemsTotal], sizeof(g_sItems[]));
		g_iItemsTotal++;
	}
}

public Action Cmd_RestoreDownloadables(int client, int args)
{
	if (g_iItemsTotal == 0) {
		ReplyToCommand(client, "Cannot restore. Downloadables string table is not saved. Use sm_remove_st first.");
		return Plugin_Handled;
	}
	
	for (int i = 0; i < g_iItemsTotal; i++)
	{
		if (strlen(g_sItems[i]))
			AddFileToDownloadsTable(g_sItems[i]);
	}
	return Plugin_Handled;
}

public Action Cmd_DumpStringtables(int client, int args)
{
	char sArg[4];
	int iDumpUserData = 0;
	if (args > 0) {
		GetCmdArgString(sArg, sizeof(sArg));
		iDumpUserData = StringToInt(sArg);
	}
	
	char sLogPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sLogPath, sizeof(sLogPath), "logs/StringTables.log");

	File hFile = OpenFile(sLogPath, "w");
	if( hFile == null )
	{
		ReplyToCommand(client, "Cannot open file for write access: %s", sLogPath);
	}
	else {
		hFile.WriteLine("String table list:");
		ReplyToCommand(client, "String table list is saved to: %s", sLogPath);
	}
	
	int iNum = GetNumStringTables();
	ReplyToCommand(client, "Listing %d stringtables:", iNum);
	char sName[64], sLine[128];
	for (int i = 0; i < iNum; i++)
	{
		GetStringTableName(i, sName, sizeof(sName));
		Format(sLine, sizeof(sLine), "%d. %s (%d/%d strings)", i, sName, GetStringTableNumStrings(i), GetStringTableMaxStrings(i));
		ReplyToCommand(client, sLine);
		hFile.WriteLine(sLine);
	}
	for (int i = 0; i < iNum; i++)
	{
		GetStringTableName(i, sName, sizeof(sName));
		DumpTable(client, sName, view_as<bool>(iDumpUserData), false);
	}
	FlushFile(hFile);
	hFile.Close();
	return Plugin_Handled;
}

public Action Cmd_DumpStringtableItems(int client, int args)
{
	if (args == 0) {
		ReplyToCommand(client, "Using: sm_dump_sti <string table name>");
		return Plugin_Handled;
	}
	
	char sStName[64];
	GetCmdArgString(sStName, sizeof(sStName));
	DumpTable(client, sStName);
	
	return Plugin_Handled;
}

bool DumpTable(int client, char[] sStName, bool bShowUserData = false, bool bShowCon = true)
{
	int iTable = FindStringTable(sStName);
	if(iTable == INVALID_STRING_TABLE)
	{
		ReplyToCommand(client, "Couldn't find %s stringtable.", sStName);
		return false;
	}
	
	char sLogPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sLogPath, sizeof(sLogPath), "logs/StringTable_%s.log", sStName);
	
	File hFile = OpenFile(sLogPath, "w");
	if( hFile == null )
	{
		ReplyToCommand(client, "Cannot open file for write access: %s", sLogPath);
		return false;
	}
	else {
		hFile.WriteLine("Contents of string table \"%s\":", sStName);
	}
	
	int iNum = GetStringTableNumStrings(iTable);
	char sName[PLATFORM_MAX_PATH];
	
	int iNumBytes;
	char sUserData[PLATFORM_MAX_PATH];
	
	for (int i = 0; i < iNum; i++)
	{
		ReadStringTable(iTable, i, sName, sizeof(sName));
		if (bShowUserData) {
			iNumBytes = GetStringTableData(iTable, i, sUserData, sizeof(sUserData));
			if (iNumBytes == 0)
				sUserData[0] = '\0';
			if (bShowCon)
				ReplyToCommand(client, "%d. %s (%s)", i, sName, sUserData);
			if (hFile != null)
				hFile.WriteLine("%s (%s)", sName, sUserData);
		}
		else {
			if (bShowCon)
				ReplyToCommand(client, "%d. %s", i, sName);
			if (hFile != null)
				hFile.WriteLine(sName);
		}
	}
	
	if (hFile != null) {
		FlushFile(hFile);
		hFile.Close();
		ReplyToCommand(client, "Dump is saved to: %s", sLogPath);
	}
	return true;
}