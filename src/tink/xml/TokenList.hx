package tink.xml;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;
using StringTools;
#else
@:genericBuild(tink.xml.TokenList.build())
#end
class TokenList<Const> {
	#if macro
	static public function build() 
		return
			switch Context.getLocalType() {
				case TInst(_, [TInst(_.get().kind => KExpr( { expr: EConst(CString(v)) } ), _)]): 
					if (v == '')
						Context.currentPos().error('Empty string not allowed');
					var name = 'tink.xml.TokenList';
					for (i in 0...v.length)
						name += v.charCodeAt(i).hex(2);
						
					var ret = name.asComplexType();
					var exists = 
						try {
							Context.getType(name);
							true;
						}
						catch (e:Dynamic) {
							false;
						}
					if (!exists) {
						var type = macro class {
							public var length(get, never):Int;
								inline function get_length()
									return this.length; 
							
							public inline function iterator()
								return this.iterator();
									
							@:arrayAccess function get(index:Int)
								return this[index];
								
							@:to public function toString():String
								return if (this == null) null else this.join('$v');
							@:from static function ofString(s:String):$ret 
								return s.split('$v');
						}
						var parts = name.split('.');
						var array = macro : Array<String>;
						type.name = parts.pop();
						type.pack = parts;
						type.kind = TDAbstract(array, [array, array]);
						Context.defineModule(name, [type]);
					}
					//throw v;
					ret;
				case v: 
					Context.currentPos().error('wrong usage');
			}
	#end
}