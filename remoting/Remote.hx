package remoting;

import haxe.Json;

typedef Socket =
{
	on : String -> (Dynamic -> Void) -> Void,
	emit : String -> Dynamic -> Void
}

@:autoBuild(remoting.RemoteMacro.buildRemote())
class Remote<T>
{
	public static var callEvent = "remoting-call";
	public static var resultEvent = "remoting-result";
	
	private var callbackMap = new Map<Int, {func : Dynamic, hasParam : Bool}>();
	private var callId = 0;
	public var socket(default, set) : Socket;
	public function set_socket(s : Socket)
	{
		this.socket = s;
		socket.on(resultEvent, function (data : Dynamic)
		{
			var dataArray : Array<Dynamic> = cast Json.parse(data);
			callCallback(dataArray[0], dataArray[1]);
		});
		return socket;
	}
	
	private function registerCallback(callback : Dynamic, hasParam : Bool):Void
	{
		if (callback != null)
		{
			callId++;
			callbackMap.set(callId, {func : callback, hasParam : hasParam});	
		}
	}
	
	public function callCallback(callId : Int, ?param : Dynamic = null)
	{
		var callback = callbackMap.get(callId);
		if (callback != null)
		{
			callbackMap.remove(callId);
			if (callback.hasParam)
			{
				var typedCallback : Void -> Void = cast callback.func;
				typedCallback();
			}
			else
			{
				var typedCallback : Dynamic -> Void = cast callback.func;
				typedCallback(param);
			}
		}
	}
	
	public static function handleRequest(o : Dynamic, data : Dynamic, socket : Socket)
	{
		var args : Array<Dynamic> = cast Json.parse(data);
		
		var result = Reflect.callMethod(o, Reflect.field(o, args[0]), args.slice(2));
		
		var callId : Int = cast args[1];
		if(callId > 0)
			socket.emit(resultEvent, Json.stringify([callId, result]));
	};
}