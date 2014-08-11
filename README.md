haxe-websocket-remoting
=======================

Haxe library to use remoting with websockets allowing full-duplex async calls

Install
-------

`haxelib git haxe-websocket-remoting https://github.com/eolhing/haxe-websocket-remoting.git`

Sample
------

This sample is located in the sample directory, you can build by running `haxe build.hxml` or by opening the FlashDevelop project

####Client.hx

```haxe
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
```

####Server.hx
```haxe
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
```