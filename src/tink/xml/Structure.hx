package tink.xml;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using tink.MacroApi;
using tink.CoreApi;
#else
@:genericBuild(tink.xml.Structure.build())
#end
class Structure<T> {
	#if macro 
	static var counter = 0;
	static var map = new Map();
		
	static function anon(fields:Array<ClassField>, type:Type):Expr {
		var obj = [];
		
		var ret = ['ret'.define(EObjectDecl(obj).at(), type.toComplex())];
		
		var childloop = [];
		
		ret.push(macro for (x in x.elements()) $b{childloop});
		
		for (f in fields) {
			var fieldName = f.name,
					meta = f.meta.get();
					
			var defaultValue = None; 
			for (m in meta) 
				if (m.name == ':optional')
					if (defaultValue == None) {
						defaultValue = switch m.params {
							case []: Some(Left(m.pos));
							case [v]: Some(Right(v));
							case v: v[1].reject('too many parameters');							
						}
					}
					else m.pos.error('can only have one @:optional meta');
				
			function attribute(name:String) { 
				
				var ifNotFound =
					switch defaultValue {
						case None:
							macro throw new ReaderError('Missing attribute "$name"', x);
						case Some(Right(v)):
							//macro @:pos(f.pos) ret.$fieldName = $v; <-- this seems to mess up positions
							'ret.$fieldName'.resolve(f.pos).assign(v, v.pos);
						default:
							[].toBlock();
					}
					
				if (defaultValue == None)
					obj.push( { field: name, expr: macro null } );
				
				ret.push(macro @:pos(f.pos) switch x.getAttribute($v{name}) {
					case null:
						$ifNotFound;
					case v:
						ret.$fieldName = v;
				});
			}
			
			function name() { 
				obj.push({ field: fieldName, expr: macro x.name });
			}
			
			function children() { 
				obj.push( { field: fieldName, expr: macro [] } );
				var type = 
					switch f.type.reduce() {
						case TInst(_.toString() => 'Array', [t]):
							t;
						default:
							f.pos.error('@:children must always be Array');
					}				
					
				
			}
			
			function content() { 
				obj.push( { field: fieldName, expr: macro x.getText() } );
			}
			
			function list(name:String) { 
				obj.push( { field: fieldName, expr: macro [] } );
				var type = 
					switch f.type.reduce() {
						case TInst(_.toString() => 'Array', [t]):
							t;
						default:
							f.pos.error('@:list must always be Array');
					}
				
				switch defaultValue {
					case None:
					case Some(Left(pos)):
						pos.error('@:list may not have @:optional tag');
					case Some(Right(v)):
						v.reject('@:list may not have default value');
				}
				childloop.push(macro if (x.name == $v{name}) {
					ret.$fieldName.push($p{readerForType(type).split('.')}.inst.doRead(x));
					continue;
				});
			}
			
			function tag(name:String) { 
				if (defaultValue == None)
					obj.push( { field: fieldName, expr: macro null } );
					
				switch defaultValue {
					case None:
						ret.push(macro if (ret.$fieldName == null) 
							throw new ReaderError('Missing element "$name"', x)
						);
					case Some(Right(v)):
						ret.push(macro if (ret.$fieldName == null) 
							ret.$fieldName = $v
						);
					default:
				}
				
				childloop.unshift(macro if (x.name == $v{name}) {
					if (ret.$fieldName == null)
						ret.$fieldName = $p{readerForType(f.type).split('.')}.inst.doRead(x);
					continue;
				});
			}
			
			var fieldKinds:Map<String, Either<String->Void, Void->Void>> = [
				':attr' => Left(attribute),
				':name' => Right(name),
				':children' => Right(children),
				':content' => Right(content),
				':list' => Left(list),
				':tag' => Left(tag),
			];
			
			var found = false;
			
			for (tag in f.meta.get()) 
				switch fieldKinds[tag.name] {
					case null:
					case _ if (found): tag.pos.error('only one of @${[for (k in fieldKinds.keys()) k].join(", @")} per field');
					case Left(withName):
						var name = 
							switch tag.params {
								case []: f.name;
								case [v]: v.getName().sure();
								case v: v[1].reject('no more than one parameter allowed');
							}
							
						withName(name);
						found = true;
					case Right(withoutName):
						if (tag.params.length > 0)
							tag.params[0].reject('no parameter allowed');
							
						withoutName();
						found = true;
				}
			
			if (!found) 
				tag(f.name);
		}
		
		
		ret.push(macro ret);
		return ret.toBlock();
	}
	static function readerForType(type:Type):String {
		var signature = Context.signature(type.toComplex());
		if (!map.exists(signature))
			map[signature] = counter++;
			
		var name = 'tink.xml.Parser_'+map[signature];
		
		var exists = 
			try {
				Context.getType(name);
				true;
			}
			catch (e:Dynamic) false;
			
		if (!exists) {
			var body = 
				switch type.getID() {
					case 'Int' | 'Float' | 'String' | 'Bool' : 
						macro x.getText();
					case 'Array':
						switch type.reduce() {
							case TInst(_.toString() => 'Array', [t]):
								macro {
									var reader = $p{readerForType(t).split('.')}.inst;
									[for (x in x.elements()) reader.doRead(x)];
								}
							default: throw 'assert';
						}
					default:
						switch type.reduce() {
							case TAnonymous(_.get() => { fields: fields } ):
								anon(fields, type);
							case v:
								Context.currentPos().error('cannot handle $v');
						}					
				}
				
			var main = name.split('.').pop(),
					ct = type.toComplex();
					
			Context.defineModule(name, [macro class $main extends Reader<$ct> {
				override function doRead(x:Source):$ct return $body;
				static public var inst(default, null) = ${main.instantiate()};
			}]);
		}
		return name;
	}
	static function build():ComplexType 
		return
			switch Context.getLocalType() {
				case TInst(_, [type]):
					readerForType(type).asComplexType();
				default:
					throw 'assert';
			}
	#end
}