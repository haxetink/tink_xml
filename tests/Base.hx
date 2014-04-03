package ;

import haxe.PosInfos;
import haxe.unit.TestCase;
import haxe.unit.TestResult;
import haxe.unit.TestStatus;
import tink.core.Either;

abstract PhysicalType<T>(Either<Class<T>, Enum<T>>) {
	
	function new(v) this = v;
	
	public function toString() 
		return 
			switch this {
				case Left(c): Type.getClassName(c);
				case Right(e): Type.getEnumName(e);
			}
			
	public function check(v:T) 
		return 
			Std.is(v, this.getParameters()[0]);
	
	@:from static public function ofClass<C>(c:Class<C>) 
		return new PhysicalType(Left(c));
		
	@:from static public function ofEnum<E>(e:Enum<E>) 
		return new PhysicalType(Right(e));
}
//TODO: this helper should go somewhere
class Base extends TestCase {
	
	function fail(msg:String, ?c : PosInfos) {
		currentTest.done = true;
		currentTest.success = false;
		currentTest.error = msg;
		currentTest.posInfos = c;
		throw currentTest;
	}
	
	function assertStructEq<A>(expected:A, found:A) {
		function compare(e:Dynamic, f:Dynamic):Bool
			return {
				var ret = 
				switch Type.typeof(e) {
					case TNull, TInt, TBool, TFloat, TUnknown, TClass(String): e == f;
					case TObject:
						var ret = true;
						//TODO: consider checking surplus fields
						for (field in Reflect.fields(e)) 
							if (field != '__id__' && !compare(Reflect.field(e, field), Reflect.field(f, field))) {
								ret = false;
								break;
							}
						ret;
					case TEnum(enm):
						Std.is(f, enm) 
						&& 
						compare(Type.enumIndex(e), Type.enumIndex(f))
						&&
						compare(Type.enumParameters(e), Type.enumParameters(f));
					case TClass(Array):
						var ret = compare(e.length, f.length);
						if (ret)
							for (i in 0...e.length)
								if (!compare(e[i], f[i])) {
									ret = false;
									break;
								}
						ret;
					case TClass(_) if (Std.is(e, Map.IMap)):
						var e:Map.IMap<Dynamic, Dynamic> = e,
							f:Map.IMap<Dynamic, Dynamic> = f;
							
						var ret = true;
						function find(orig:Dynamic) {
							for (copy in f.keys())
								if (compare(orig, copy)) 
									return copy;
							return orig;
						}
						if (ret)
							for (k in e.keys())
								if (!compare(e.get(k), f.get(find(k)))) {
									ret = false;
									break;
								}
						e.toString();
						ret;
					default:
						throw 'assert';
				}
				ret;
			}	
		if (compare(expected, found)) assertTrue(true);
		else fail('expected something like $expected, found $found');
	}
	
	function throws<A>(f:Void->Void, t:PhysicalType<A>, ?check:A->Bool, ?pos:PosInfos):Void {
		try f()
		catch (e:Dynamic) {
			if (!t.check(e)) fail('Exception $e not of type $t', pos);
			if (check != null && !check(e)) fail('Exception $e does not satisfy condition', pos);
			assertTrue(true);
			return;
		}
		fail('no exception thrown', pos);
	}
}
