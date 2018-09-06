#include <sourcemod>
#include <socket>

public Plugin myinfo =
{
	name = "Dyscord",
	author = "KarlOfDuty",
	description = "This plugin bridges a Discord chat and the Dystopia in-game chat.",
	version = "0.0.1",
	url = "https://karlofduty.com"
};

public Handle datsocket;

public OnPluginStart()
{
	PrintToServer("Dyscord plugin activated.");
	// create a new tcp socket
	datsocket = SocketCreate(SOCKET_TCP, OnSocketError);

	// connect the socket
	SocketConnect(datsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "localhost", 8888);

	CreateTimer(5.0, UpdateActivity, _, TIMER_REPEAT);
}

public Action UpdateActivity(Handle timer)
{
	int maxPlayers = GetMaxHumanPlayers();
	int currentPlayers = GetClientCount();

	char message[1000];
	Format(message, sizeof(message), "botactivity%i / %i", currentPlayers, maxPlayers);
	SocketSend(datsocket, message);
	return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	char name[128];
	GetClientName(client, name, sizeof(name));
	char message[1000];
	Format(message, sizeof(message), "000000000000000000%s [U:1:%i]: %s", name, sArgs);
	SocketSend(datsocket, message);
}

public void OnClientAuthorized(int client, const char[] auth)
{
	char name[128];
	GetClientName(client, name, sizeof(name));

	int steamid = GetSteamAccountID(client, true);

	char message[1000];
	Format(message, sizeof(message), "000000000000000000**%s [U:1:%i] joined the game.**", name, steamid);
	SocketSend(datsocket, message);
}

public void OnClientDisconnect(int client)
{
	char name[128];
	GetClientName(client, name, sizeof(name));
	
	int steamid = GetSteamAccountID(client, true);

	char message[1000];
	Format(message, sizeof(message), "000000000000000000**%s [U:1:%i] left the game.**", name, steamid);
	SocketSend(datsocket, message);
}

public OnSocketConnected(Handle:socket, any:arg)
{
	// socket is connected, send the http request

	SocketSend(socket, "000000000000000000**Plugin connected.**");
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile)
{
	ServerCommand(receiveData);
}

public OnSocketDisconnected(Handle:socket, any:hFile)
{
	// Connection: close advises the webserver to close the connection when the transfer is finished
	// we're done here
	CloseHandle(socket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile)
{
	// a socket error occured

	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}