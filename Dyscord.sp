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

public OnPluginStart()
{
	// create a new tcp socket
	new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);

	// open a file handle for writing the result
	// new Handle:hFile = OpenFile("dl.htm", "wb");

	// pass the file handle to the callbacks
	//SocketSetArg(socket, hFile);
	// connect the socket
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "localhost", 8888);
}

public OnSocketConnected(Handle:socket, any:arg)
{
	// socket is connected, send the http request

	SocketSend(socket, "HELLO GAIS");
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile)
{
	// receive another chunk and write it to <modfolder>/dl.htm
	// we could strip the http response header here, but for example's sake we'll leave it in

	//WriteFileString(hFile, receiveData, false);
}

public OnSocketDisconnected(Handle:socket, any:hFile)
{
	// Connection: close advises the webserver to close the connection when the transfer is finished
	// we're done here

	//CloseHandle(hFile);
	CloseHandle(socket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile)
{
	// a socket error occured

	LogError("socket error %d (errno %d)", errorType, errorNum);
	//CloseHandle(hFile);
	CloseHandle(socket);
}