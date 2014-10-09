package tink.xml;

#if macro
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;

using tink.CoreApi;
using tink.MacroApi;

private enum PropKind {
	Attr(name:String);
	Tag(name:String);
	List(name:String);
  Content;
}
#else
class ParseError extends tink.core.Error.TypedError<{ node:Xml, document:Xml }> {
  public function new(msg:String, data, ?pos) {
    super(UnprocessableEntity, msg, pos);
    this.data = data;
  }
  override function toString() {
    return '$message at element:' + data.node.toString();
  }
}
#end

class Decode {
	#if macro
	static var cache = new Map();
	static var ctx:Array<Field> = [];
	static function flush() {
		
	}
	static var VALUE = macro [for (c in x) try c.nodeValue catch (e:Dynamic) c.toString()].join('');
  
	static function getReader(type:Type, ?value):Expr {
		if (value == null) value = VALUE;
		return 
			switch (type.getID()) {
				case 'Array':
					var ct = type.toComplex();
					var et = (macro { var a : $ct = null; a[0]; } ).typeof().sure();
					var body = getReader(et);
					macro {
						var ret = [];
						for (x in x.elements()) 
							ret.push($body);
						ret;
					}
				case 'String':
					value;
				case 'Float':
					macro Std.parseFloat($value);
				case 'Int':
					macro Std.parseInt($value);
				case 'Bool':
					macro switch $value.toLowerCase() {
            case 'false', '0': false;
            default: true;
          }
				default:
					switch type.reduce() {
						case TAbstract(_.get() => t, _):
              var parseAs = t.type;
              
              if (t.meta.has(':parseAs'))
                switch t.meta.get().getValues(':parseAs') {
                  case [[v]]:
                    parseAs = Context.getType(v.getString().orUse(v.toString()));
                  default:
                    t.pos.error('invalid @:parseAs directive');
                }
              
              if (!parseAs.isSubTypeOf(type).isSuccess())
                Context.currentPos().error('$parseAs cannot be implicitly converted to $type');
              var ct = type.toComplex();  
              
              macro (${getReader(parseAs, value)} : $ct);
              
						case TAnonymous(anon):
							var id = anon.toString(),
							    anon = anon.get();
							
							cache[id] = [id];
							
							var obj = [];
							for (f in anon.fields) 
								obj.push( {
									field: f.name,
									expr: {
										var meta = f.meta.get().toMap();
										
										function getName(name)
											return 
												switch meta[name] {
													case [[e]]:  
                            e.getName().sure();
													default: f.name;
												}
										
										var kind = 
											if (meta.exists(':attr')) 
												Attr(getName(':attr'));
											else if (meta.exists(':list'))
												List(getName(':list'));
											else if (meta.exists(':tag'))
												Tag(getName(':tag'));
                      else if (meta.exists(':content'))
                        Content;
											else 
												Tag(f.name);
                        
										function error(msg:String) 
                      return macro throw new tink.xml.Decode.ParseError($v{msg}, { node: x, document: root });
                    
										var value = 
											switch kind {
												case List(_):
													var ct = f.type.toComplex();
													getReader((macro { var a : $ct = null; a[0]; } ).typeof().sure());
												case Attr(name):
													getReader(f.type, macro x.get($v{name}));
												case Tag(_), Content:
                          getReader(f.type);
											},
											missing =
												if (f.meta.has(':optional')) 
													macro null;
												else 
													switch kind {
														case Attr(name):
															error('missing attribute $name');
														case Tag(name):
															error('missing element $name');
														case List(_), Content:
															macro null;
													}
										
										switch kind {
											case Attr(name):
												macro 
													if (x.exists($v{name})) $value
													else $missing;
											case Tag(name):
												macro {
													var candidate:Xml = x.elementsNamed($v{name}).next();
													if (candidate == null) $missing;
													else {
                            var x = candidate;
                            $value;
                          }
												}
											case List(name):
												macro {
													[for (x in x.elementsNamed($v{name})) $value];
												}
                      case Content:
                        value;
										}
									}
								});
							EObjectDecl(obj).at();
						default: Context.currentPos().error('cannot handle type $type');
					}
			}
	}
	#end
	macro static public function parseXml(e) 
		return 
			switch e {
				case macro ($e : $t):
					var ret = getReader(t.toType().sure());
					flush();
					macro @:pos(e.pos) {
						var raw = $e;
						try { 
							var root = Xml.parse(raw).firstElement(); 
              var x = root;
							tink.core.Outcome.Success(($ret : $t)); 
						}
            catch (e:tink.xml.Decode.ParseError) {
              var e:tink.core.Error = e;
              tink.core.Outcome.Failure(e);
            }
						catch (e:Dynamic) {
							tink.core.Outcome.Failure(tink.core.Error.withData('TINK_XML:XML_PARSE_ERROR', { error: e, data: raw }));
						}
					}
				default:
					throw (e);
					e.reject('Expression must be ECheckType');
			}
	
}