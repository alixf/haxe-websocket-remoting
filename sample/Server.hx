import js.Node.NodeHttp;
import js.Node.NodeHttpServer;
import js.Node.NodeHttpServerReq;
import js.Node.NodeHttpServerResp;
import js.node.SocketIo;
import js.node.SocketIoClient.Socket;
import remoting.Remote;

class ClientRemote extends Remote<Client> { }

typedef ServerClient = 
{
	var remote : ClientRemote;
}

class Server
{
	private var clients = new Map<Socket, ServerClient>();
	private var currentClient : ServerClient;
	
	public static function main()
	{
		new Server();
	}
	
	public function new()
	{
		var http : NodeHttp = js.Node.http;
		function handler(req : NodeHttpServerReq, resp : NodeHttpServerResp) { resp.end(); }
		var httpServer = http.createServer(handler);
		httpServer.listen(11258);
		
		var io = js.Node.require("socket.io")(httpServer);
		io.on('connection', function (socket : Socket)
		{
			var remote = new ClientRemote();
			remote.socket = socket;
			clients.set(socket, { remote : remote } );
			remote.bar("called on connection", function() { trace('bar finished.'); } );
			
			socket.on(Remote.callEvent, function (data)
			{
				currentClient = clients.get(socket);
				Remote.handleRequest(this, data, socket);
			});
		});
	}
	
	@:keep public function foo(arg1 : Int)
	{
		trace('function foo called on server with arg1 = $arg1');
		currentClient.remote.bar("called on foo", function() { trace('bar finished.'); } );
	}
}