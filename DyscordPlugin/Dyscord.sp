#include <sourcemod>
#include <socket>
#include <sdktools_functions>

public Plugin myinfo =
{
	name = "Dyscord",
	author = "KarlOfDuty",
	description = "This plugin bridges a Discord chat and the Dystopia in-game chat.",
	version = "0.0.2",
	url = "https://karlofduty.com"
};

public Handle datsocket;
public bool disconnected = false;

///////////////////////////////////////
//                                   //
//         ConVars                   //
//                                   //
///////////////////////////////////////

ConVar:convar_ip;
ConVar:convar_port;

///////////////////////////////////////
//                                   //
//         Utility functions         //
//                                   //
///////////////////////////////////////
public bool StartsWith(String:sourceString[], int sourceLength, String:searchTermString[], int searchTermLength)
{
	if(sourceLength < searchTermLength)
	{
		return false;
	}

	for(int i = 0; i < searchTermLength; i++)
	{
		if(sourceString[i] != searchTermString[i])
		{
			return false;
		}
	}
	return true;
}


///////////////////////////////////////
//                                   //
//         Repeating events          //
//                                   //
///////////////////////////////////////
public Action UpdateActivity(Handle timer)
{
	if(disconnected)
	{
		datsocket = SocketCreate(SOCKET_TCP, OnSocketError);
		char ip[64];
		convar_ip.GetString(ip, sizeof(ip));
		SocketConnect(datsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, ip, convar_port.IntValue);
		disconnected = false;
		return Plugin_Continue;
	}
	disconnected = true;
	int maxPlayers = GetMaxHumanPlayers();
	int currentPlayers = GetClientCount();

	char message[1000];
	Format(message, sizeof(message), "botactivity%i / %i\0", currentPlayers, maxPlayers);
	SocketSend(datsocket, message);
	disconnected = false;
	return Plugin_Continue;
}

///////////////////////////////////////
//                                   //
//          Initialization           //
//                                   //
///////////////////////////////////////
public OnPluginStart()
{
	PrintToServer("Dyscord plugin activated.");

	// Registering ConVars
	convar_ip = CreateConVar("discord_bot_ip", "127.0.0.1", "The ip of the bot application.", FCVAR_PROTECTED);
	convar_port = CreateConVar("discord_bot_port", "8888", "The ip of the bot application.", FCVAR_PROTECTED);

	// Connecting TCP socket
	datsocket = SocketCreate(SOCKET_TCP, OnSocketError);

	char ip[64];
	convar_ip.GetString(ip, sizeof(ip));
	SocketConnect(datsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, ip, convar_port.IntValue);

	// Set automated events
	CreateTimer(5.0, UpdateActivity, _, TIMER_REPEAT);

	// Hook game events
	HookEvent("player_death", OnPlayerDeath);
	//HookEvent("player_class", OnPlayerClass);
	HookEvent("player_team", OnPlayerTeam);
	HookEvent("dys_changemap", OnChangemap);
	HookEvent("objective", OnObjective);

	// Register command
	RegAdminCmd("discord_reconnect", CommandReconnect, ADMFLAG_CHAT);
}

///////////////////////////////////////
//                                   //
//          Game events              //
//                                   //
///////////////////////////////////////
public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int playerClient = GetClientOfUserId(event.GetInt("userid"));

	int attackerClient = GetClientOfUserId(event.GetInt("attacker"));

	char weapon[64]
	event.GetString("weapon", weapon, sizeof(weapon));

	int playerSteamID = GetSteamAccountID(playerClient, true);
	int attackerSteamID = GetSteamAccountID(attackerClient, true);

	char playerName[64];
	GetClientName(playerClient, playerName, sizeof(playerName));

	char attackerName[64];
	GetClientName(attackerClient, playerName, sizeof(playerName));

	char message[1000];
	Format(message, sizeof(message), "000000000000000000%s [U:1:%i] was killed by %s [U:1:%i].\0", playerName, playerSteamID, attackerName, attackerSteamID);
	SocketSend(datsocket, message);
}

public void OnPlayerClass(Event event, const char[] name, bool dontBroadcast)
{
	int playerClient = GetClientOfUserId(event.GetInt("userid"));

	char class[64];
	event.GetString("class", class, sizeof(class));

	int playerSteamID = GetSteamAccountID(playerClient, true);

	char playerName[64];
	GetClientName(playerClient, playerName, sizeof(playerName));

	char message[1000];
	Format(message, sizeof(message), "000000000000000000%s [U:1:%i] switched class to %s.\0", playerName, playerSteamID, class);
	SocketSend(datsocket, message);
}

public void OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int playerClient = GetClientOfUserId(event.GetInt("userid"));

	char team[64];
	GetTeamName(event.GetInt("team"), team, sizeof(team));

	char oldTeam[64];
	GetTeamName(event.GetInt("oldteam"), oldTeam, sizeof(oldTeam));

	int playerSteamID = GetSteamAccountID(playerClient, true);

	char playerName[64];
	GetClientName(playerClient, playerName, sizeof(playerName));

	char message[1000];
	Format(message, sizeof(message), "000000000000000000%s [U:1:%i] switched team from %s to %s.\0", playerName, playerSteamID, oldTeam, team);
	SocketSend(datsocket, message);
}

public void OnRoundRestart(Event event, const char[] name, bool dontBroadcast)
{

}

public void OnChangemap(Event event, const char[] name, bool dontBroadcast)
{
	char map[64];
	event.GetString("newmap", map, sizeof(map));

	char message[1000];
	Format(message, sizeof(message), "000000000000000000**Map has changed to %s**\0", map);
	SocketSend(datsocket, message);
}

public void OnObjective(Event event, const char[] name, bool dontBroadcast)
{
	int playerClient = GetClientOfUserId(event.GetInt("userid"));
	int playerSteamID = GetSteamAccountID(playerClient, true);

	char playerName[64];
	GetClientName(playerClient, playerName, sizeof(playerName));

	char objective[64];
	event.GetString("objective", objective, sizeof(objective));

	char message[1000];
	Format(message, sizeof(message), "000000000000000000**The objcetive \"%s\" has been captured by %s [U:1:%i]**\0", objective, playerName, playerSteamID);
	SocketSend(datsocket, message);
}

///////////////////////////////////////
//                                   //
//         SourceMod Events          //
//                                   //
///////////////////////////////////////
public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	char name[128];
	GetClientName(client, name, sizeof(name));

	int steamid = GetSteamAccountID(client, true);

	char message[1000];
	Format(message, sizeof(message), "000000000000000000%s [U:1:%i]: %s\0", name, steamid, sArgs);
	SocketSend(datsocket, message);
}

public void OnClientAuthorized(int client, const char[] auth)
{
	char name[128];
	GetClientName(client, name, sizeof(name));

	int steamid = GetSteamAccountID(client, true);

	char message[1000];
	Format(message, sizeof(message), "000000000000000000**%s [U:1:%i] joined the game.**\0", name, steamid);
	SocketSend(datsocket, message);
}

public void OnClientDisconnect(int client)
{
	char name[128];
	GetClientName(client, name, sizeof(name));
	
	int steamid = GetSteamAccountID(client, true);

	char message[1000];
	Format(message, sizeof(message), "000000000000000000**%s [U:1:%i] left the game.**\0", name, steamid);
	SocketSend(datsocket, message);
}

///////////////////////////////////////
//                                   //
//          Socket events            //
//                                   //
///////////////////////////////////////
public Action CommandReconnect(int client, int args)
{
	CloseHandle(datsocket);

	datsocket = SocketCreate(SOCKET_TCP, OnSocketError);
	char ip[64];
	convar_ip.GetString(ip, sizeof(ip));
	SocketConnect(datsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, ip, convar_port.IntValue);
	return Plugin_Handled;
}

///////////////////////////////////////
//                                   //
//          Socket events            //
//                                   //
///////////////////////////////////////
public OnSocketConnected(Handle:socket, any:arg)
{
	// socket is connected, send the http request

	SocketSend(socket, "000000000000000000**Plugin connected.**\0");
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile)
{
	if(StartsWith(receiveData, strlen(receiveData), "command", 7))
	{
		strcopy(receiveData, strlen(receiveData), receiveData[7]);
		ServerCommand(receiveData);
		PrintToServer(receiveData);
	}
	else if(StartsWith(receiveData, strlen(receiveData), "message", 7))
	{
		strcopy(receiveData, strlen(receiveData), receiveData[7]);
		PrintToChatAll(receiveData);
		PrintToServer(receiveData);
	}
}

public OnSocketDisconnected(Handle:socket, any:hFile)
{
	// Connection: close advises the webserver to close the connection when the transfer is finished
	// we're done here
	CloseHandle(socket);
	disconnected = true;
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile)
{
 	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);

	char ip[64];
	convar_ip.GetString(ip, sizeof(ip));
	SocketConnect(datsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, ip, convar_port.IntValue);
}
////////////////////////////////////////