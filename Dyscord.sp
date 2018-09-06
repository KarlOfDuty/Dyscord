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
	// create a new tcp socket
	datsocket = SocketCreate(SOCKET_TCP, OnSocketError);

	// connect the socket
	SocketConnect(datsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "localhost", 8888);
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
    SocketSend(datsocket, "CONNECTIBOI");
    return true;
}

public OnSocketConnected(Handle:socket, any:arg)
{
	// socket is connected, send the http request

	SocketSend(socket, "HELLO GAIS");
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