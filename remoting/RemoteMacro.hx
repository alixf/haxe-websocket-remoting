package remoting;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
import haxe.macro.Type;

class RemoteMacro
{
	macro static public function buildRemote() : Array<Field>
	{
		var pos = Context.currentPos();
		
		var targetType = TypeTools.getClass(Context.getLocalClass().get().superClass.params[0]);
		var targetFields = targetType.fields.get();
		var buildFields = Context.getBuildFields();
		
		for (field in targetFields)
		{
			if (field.isPublic && field.kind.match(FMethod(MethNormal)))
			{
				var functionField : TFunc = switch(field.expr().expr)
				{
					case TFunction(ff) : ff;
					default : throw "error, method is not a function";
				}
				
				// define arguments
				var args = new Array<FunctionArg>();
				for (arg in functionField.args)
					args.push( { value : null, type : TypeTools.toComplexType(arg.v.t), opt : false, name : arg.v.name } );
					
				// define callback
				var callbackHasParam = false;
				var retType : ComplexType = TypeTools.toComplexType(functionField.t);
				var callback = macro function() : $retType -> Void { };
				if (retType.match(TPath( { name : "StdTypes", pack : [], params : [], sub : "Void" } )))
				{
					var callback = macro function() { };
					args.push( { value : null, type :  macro : Void -> Void, opt : true, name : "callback" } );
					var callbackHasParam = false;
				}
				else
				{
					var callback = macro function() : $retType -> Void { };
					args.push( { value : null, type : callback.expr.getParameters()[1].ret, opt : true, name : "callback" } );
					var callbackHasParam = true;
				}
				
				// define field
				var newField = 
				{
					name : field.name,
					doc : field.doc,
					meta : [],
					access : [APublic],
					kind : FFun(
					{
						args : args,
						ret : macro : Void,
						expr : buildFunctionBody(field.name, functionField.args, callbackHasParam)
					}),
					pos : pos,
				};
				buildFields.push(newField);
			}
		}
		
		// Add constructor
		var newField = { name : "new",doc : "", meta : [], access : [APublic], kind : FFun({args : [], ret : null, expr : macro {}}), pos : pos}
		buildFields.push(newField);
		
		// Return build fields
		return buildFields;
	}
	
	public static function buildFunctionBody(name : String, args : Array<{v : TVar, value : Null<TConstant>}>, callbackHasParam : Bool) : Expr
	{
		var exprs = new Array<Expr>();
		var pos = Context.currentPos();
		
		exprs.push(Context.parse('registerCallback(callback, ${callbackHasParam})',pos));
		exprs.push(Context.parse('var params = new Array<Dynamic>()', pos));
		exprs.push(Context.parse('params.push("$name")', pos));
		exprs.push(Context.parse('params.push(callback == null ? 0 : this.callId)',pos));
		for (arg in args)
			exprs.push(Context.parse('params.push(${arg.v.name})', pos));
		exprs.push(Context.parse('this.socket.emit("remoting-call", haxe.Json.stringify(params))', pos));
		
		return { expr : EBlock(exprs), pos : pos };
	}
}