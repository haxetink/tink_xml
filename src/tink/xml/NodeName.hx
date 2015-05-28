package tink.xml;

abstract NodeName(String) to String {
	inline function new(s:String) this = s.toUpperCase();
	
	@:from static inline function ofString(s:String) 
		return new NodeName(s);
		
	@:commutative @:op(a == b) static public inline function equalsString(a:NodeName, b:String) 
		return equalsName(a, b);
		
	@:op(a == b) static public inline function equalsName(a:NodeName, b:NodeName) 
		return (a : String) == (b : String);
}