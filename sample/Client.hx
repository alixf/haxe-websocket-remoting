import js.node.SocketIoClient.Io;
import js.node.SocketIoClient.Socket;
import remoting.Remote;

class ServerRemote extends Remote<Server> { }

class Client
{
	public static function main()
	{
		new Client();
	}
	
	public function new()
	{
		var socket : Socket = cast Io.connect("http://localhost:11258");
		socket.on(Remote.callEvent, function (data) {
			Remote.handleRequest(this, data, socket);
		});
		
		var remote = new ServerRemote();
		remote.socket = socket;
		remote.foo(56, function() { trace("foo finished"); } );
	}
	
	@:keep public function bar(arg1 : String)
	{
		trace('function bar called on client with arg1 = $arg1');
	}
}