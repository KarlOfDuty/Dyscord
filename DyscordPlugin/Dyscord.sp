#include <sourcemod>
#include <socket>
#include <sdktools_functions>

public Plugin myinfo =
{
	name = "Dyscord",
	author = "KarlOfDuty",
	description = "This plugin bridges a Discord chat and the Dystopia in-game chat.",
	version = "0.1.1",
	url = "https://karlofduty.com"
};

public Handle datsocket;
public bool disconnected = false;
public bool firstTimeSteup = true;

///////////////////////////////////////
//                                   //
//         ConVars                   //
//                                   //
///////////////////////////////////////

ConVar:convar_hostname;
char serverName[128];
ConVar:convar_server_ip;
char serverIP[32];
ConVar:convar_server_port;
char serverPort[32];
ConVar:convar_bot_ip;
ConVar:convar_bot_port;
ConVar:convar_announcement;
ConVar:convar_announcement_link;
ConVar:convar_announcement_rate;

///////////////////////////////////////
//                                   //
//         Utility functions         //
//                                   //
///////////////////////////////////////
bool StartsWith(String:sourceString[], int sourceLength, String:searchTermString[], int searchTermLength)
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

char[] WeaponTagToName(const char[] tag)
{
	char output[64];
	if(StrEqual("MachPistol", tag, false))
	{
		output = "Machine Pistol";
	}
	else if(StrEqual("Crowbar", tag, false))
	{
		output = "Light Katana";
	}
	else if(StrEqual("Player", tag, false))
	{
		output = "K";
	}
	else if(StrEqual("MK808", tag, false))
	{
		output = "MK808 Rifle";
	}
	else if(StrEqual("Assault", tag, false))
	{
		output = "Assault Rifle";
	}
	else if(StrEqual("BoltGun", tag, false))
	{
		output = "Boltgun";
	}
	else if(StrEqual("RocketLauncher", tag, false))
	{
		output = "Rocket Launcher";
	}
	else if(StrEqual("SpiderGrenade", tag, false))
	{
		output = "Spider Grenade";
	}
	else if(StrEqual("SmartLocks", tag, false))
	{
		output = "SmartLock Pistols";
	}
	else if(StrEqual("GrenLauncher", tag, false))
	{
		output = "Grenade Launcher";
	}
	else if(StrEqual("Tesla", tag, false))
	{
		output = "Tesla Rifle";
	}
	else if(StrEqual("LaserRifle", tag, false))
	{
		output = "Laser Rifle";
	}
	else if(StrEqual("Ion", tag, false))
	{
		output = "Ion Cannon";
	}
	else
	{
		strcopy(output, sizeof(output), tag);
	}
	return output;
}

char[] GetUptime()
{
	char output[64];

	int theTime = RoundToZero(GetGameTime());
	int days = theTime / 86400;
	int hours = (theTime - (days * 86400)) / 3600;
	int minutes = (theTime - (days * 86400) - (hours * 3600)) / 60;

	Format(output, sizeof(output), "%id %ih %im\0", days, hours, minutes);
	return output;
}
///////////////////////////////////////
//                                   //
//         Repeating events          //
//                                   //
///////////////////////////////////////
public Action UpdateStatus(Handle timer)
{
	if(disconnected)
	{
		datsocket = SocketCreate(SOCKET_TCP, OnSocketError);
		char ip[64];
		convar_bot_ip.GetString(ip, sizeof(ip));
		SocketConnect(datsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, ip, convar_bot_port.IntValue);
		disconnected = false;
		return Plugin_Continue;
	}
	disconnected = true;

	int maxPlayers = GetMaxHumanPlayers();
	int currentPlayers = GetClientCount();

	char activity[64];
	Format(activity, sizeof(activity), "botactivity%i / %i\0", currentPlayers, maxPlayers);
	SocketSend(datsocket, activity, sizeof(activity));

	char topic[1000];
	Format(topic, sizeof(topic), "channeltopic000000000000000000Server name: \"%s\" Online players: %i/%i Server Uptime: %s IP: %s:%s\0", serverName, currentPlayers, maxPlayers, GetUptime(), serverIP, serverPort);
	SocketSend(datsocket, topic, sizeof(topic));

	disconnected = false;
	return Plugin_Continue;
}

public Action DiscordAnnouncement(Handle timer)
{
	char message[1000];
	convar_announcement.GetString(message, sizeof(message));
	char link[64];
	convar_announcement_link.GetString(link, sizeof(link));
	PrintToChatAll(message);
	PrintToChatAll(link);
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
	convar_server_ip = CreateConVar("dyscord_server_ip", "Set this in the Dyscord config", "The global IP of this server. Used in game invite links in Discord.");
	convar_bot_ip = CreateConVar("dyscord_bot_ip", "127.0.0.1", "The ip of the bot application.");
	convar_bot_port = CreateConVar("dyscord_bot_port", "8888", "The ip of the bot application.");
	convar_announcement = CreateConVar("dyscord_announcement", "Join the Discord server!", "A short message to go before a link to the Discord server.");
	convar_announcement_link = CreateConVar("dyscord_announcement_link", "Tell your admin to put a link here!", "Link to the Discord server.");
	convar_announcement_rate = CreateConVar("dyscord_announcement_rate", "1200.0", "How often the announcement is sent in seconds.");
	AutoExecConfig(true, "dyscord");
}

public OnConfigsExecuted()
{
	if(firstTimeSteup)
	{
		convar_hostname = FindConVar("hostname");
		convar_hostname.GetString(serverName, sizeof(serverName));
		convar_server_ip = FindConVar("dyscord_server_ip");
		convar_server_ip.GetString(serverIP, sizeof(serverIP));
		convar_server_port = FindConVar("hostport");
		convar_server_port.GetString(serverPort, sizeof(serverPort));
		convar_bot_ip = FindConVar("dyscord_bot_ip");
		convar_bot_port = FindConVar("dyscord_bot_port");
		convar_announcement = FindConVar("dyscord_announcement");
		convar_announcement_link = FindConVar("dyscord_announcement_link");
		convar_announcement_rate = FindConVar("dyscord_announcement_rate");

		// Connecting TCP socket
		datsocket = SocketCreate(SOCKET_TCP, OnSocketError);

		char botIP[64];
		convar_bot_ip.GetString(botIP, sizeof(botIP));
		SocketConnect(datsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, botIP, convar_bot_port.IntValue);
		PrintToServer("Connecting to Discord Bot. IP: %s Port: %i", botIP, convar_bot_port.IntValue);

		// Set automated events
		CreateTimer(10.0, UpdateStatus, _, TIMER_REPEAT);
		CreateTimer(convar_announcement_rate.FloatValue, DiscordAnnouncement, _, TIMER_REPEAT);

		// Hook game events
		HookEvent("player_death", OnPlayerDeath);
		//HookEvent("player_class", OnPlayerClass);
		HookEvent("player_team", OnPlayerTeam);
		HookEvent("dys_changemap", OnChangemap);
		HookEvent("objective", OnObjective);
		HookEvent("round_restart", OnRoundRestart);

		// Register command
		RegAdminCmd("discord_reconnect", CommandReconnect, ADMFLAG_CHAT);
		firstTimeSteup = false;
	}
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
	GetClientName(attackerClient, attackerName, sizeof(attackerName));

	char message[1000];
	if(playerSteamID == attackerSteamID)
	{
		Format(message, sizeof(message), "000000000000000000%s [U:1:%i] killed themselves using %s.\0", playerName, playerSteamID, WeaponTagToName(weapon));
	}
	else
	{
		Format(message, sizeof(message), "000000000000000000%s [U:1:%i] was killed by %s [U:1:%i] using %s.\0", playerName, playerSteamID, attackerName, attackerSteamID, WeaponTagToName(weapon));
	}
	SocketSend(datsocket, message, sizeof(message));
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
	SocketSend(datsocket, message, sizeof(message));
}

public void OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int playerClient = GetClientOfUserId(event.GetInt("userid"));

	char team[64];
	GetTeamName(event.GetInt("team"), team, sizeof(team));

	char oldTeam[64];
	GetTeamName(event.GetInt("oldteam"), oldTeam, sizeof(oldTeam));

	if(StrEqual(oldTeam, "Unassigned", false) || StrEqual(team, "Unassigned", false))
	{
		return;
	}

	int playerSteamID = GetSteamAccountID(playerClient, true);

	char playerName[64];
	GetClientName(playerClient, playerName, sizeof(playerName));

	char message[1000];
	if(StrEqual(oldTeam, "Spectator", false))
	{
		Format(message, sizeof(message), "000000000000000000%s [U:1:%i] joined team %s.\0", playerName, playerSteamID, team);
	}
	else if(StrEqual(team, "Spectator", false))
	{
		Format(message, sizeof(message), "000000000000000000%s [U:1:%i] became a spectator.\0", playerName, playerSteamID);
	}
	else
	{
		Format(message, sizeof(message), "000000000000000000%s [U:1:%i] switched team to %s.\0", playerName, playerSteamID, team);
	}
	SocketSend(datsocket, message, sizeof(message));
}

public void OnRoundRestart(Event event, const char[] name, bool dontBroadcast)
{
	char message[1000];
	Format(message, sizeof(message), "000000000000000000**%s Round has started.**\0");
	SocketSend(datsocket, message, sizeof(message));
}

public void OnChangemap(Event event, const char[] name, bool dontBroadcast)
{
	char map[64];
	event.GetString("newmap", map, sizeof(map));

	char message[1000];
	Format(message, sizeof(message), "000000000000000000**Map has changed to %s**\0", map);
	SocketSend(datsocket, message, sizeof(message));
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
	Format(message, sizeof(message), "000000000000000000**The objective \"%s\" has been captured by %s [U:1:%i]**\0", objective, playerName, playerSteamID);
	SocketSend(datsocket, message, sizeof(message));
}

///////////////////////////////////////
//                                   //
//         SourceMod Events          //
//                                   //
///////////////////////////////////////
public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(StrEqual("say_team", command))
	{
		return;
	}

	char name[128];
	GetClientName(client, name, sizeof(name));

	int steamid = GetSteamAccountID(client, true);

	char message[1000];
	Format(message, sizeof(message), "000000000000000000%s [U:1:%i]: %s\0", name, steamid, sArgs);
	SocketSend(datsocket, message, sizeof(message));
}

public void OnClientAuthorized(int client, const char[] auth)
{
	char name[128];
	GetClientName(client, name, sizeof(name));

	int steamid = GetSteamAccountID(client, true);

	char message[1000];
	Format(message, sizeof(message), "000000000000000000**%s [U:1:%i] joined the game.**\0", name, steamid);
	SocketSend(datsocket, message, sizeof(message));
}

public void OnClientDisconnect(int client)
{
	char name[128];
	GetClientName(client, name, sizeof(name));
	
	int steamid = GetSteamAccountID(client, true);

	char message[1000];
	Format(message, sizeof(message), "000000000000000000**%s [U:1:%i] left the game.**\0", name, steamid);
	SocketSend(datsocket, message, sizeof(message));
}

public OnPluginEnd()
{
	SocketDisconnect(datsocket);
	CloseHandle(datsocket);
}
///////////////////////////////////////
//                                   //
//             Commands              //
//                                   //
///////////////////////////////////////
public Action CommandReconnect(int client, int args)
{
	CloseHandle(datsocket);

	datsocket = SocketCreate(SOCKET_TCP, OnSocketError);
	char ip[64];
	convar_bot_ip.GetString(ip, sizeof(ip));
	SocketConnect(datsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, ip, convar_bot_port.IntValue);
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
	char message[64] = "000000000000000000```diff\n+ Dystopia connected.```\0";
	SocketSend(socket, message, sizeof(message));
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
	convar_bot_ip.GetString(ip, sizeof(ip));
	SocketConnect(datsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, ip, convar_bot_port.IntValue);
}
////////////////////////////////////////
