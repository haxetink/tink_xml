package;

import tink.xml.Source;
import tink.xml.TokenList;

typedef Rtti = Array<TypeInfo>;

enum TypeInfo {
	IClass(c:ClassInfo);
	IAbstract(c:AbstractInfo);
	IEnum(c:EnumInfo);
	ITypedef(c:TypedefInfo);
}

typedef HasMeta = {
	@:optional([]) 
	@:tag var meta:Array<Meta>;
	
	@:optional('')
	@:tag var haxe_doc:String;
}

typedef Params = TokenList<':'>;

typedef Path = TokenList<'.'>;

typedef BaseInfo = {>HasMeta,
	
	@:optional(false) 
	@:attr('private') var isPrivate:Bool;
	
	@:attr var file:String;
	
	@:attr var params:Params;
	
	@:attr var path:Path;
		
	@:optional(ret.path) 
	@:attr var module:Path;
	
}

typedef Meta = { 
	@:attr(n) var name:String; 
	@:children var params:Array<String>; 
}

typedef FunctionInfo = {
	@:attr('a') var params:Params;
	@:children var types:Array<TypeRef>;
}

enum TypeRef {
	@:tag(c) TClass(c:TypePath<ClassInfo>);
	@:tag(e) TEnum(e:TypePath<EnumInfo>);
	@:tag(f) TFunction(f:FunctionInfo);
	@:tag(x) TAbstract(a:TypePath<AbstractInfo>);
	@:tag(t) TTypedef(t:TypePath<TypedefInfo>);
	@:tag(d) TDynamic(_: { } );
	@:tag(a) TAnonymous(fields:Array<FieldInfo>);
	TUnknown(_: { } );
}

typedef ImplicitCast = {
	@:optional 
	@:attr var field:String;
	@:nth(1) var type:TypeRef;
}

typedef AbstractInfo = {>BaseInfo,
	@:tag('this') var abstracted: { 
		@:nth(1) var over:TypeRef; 
	};
	@:optional([]) @:tag var from:Array<ImplicitCast>;
	@:optional([]) @:tag var to:Array<ImplicitCast>;
	
	@:optional @:tag('impl') var implemented:{ 
		@:tag('class') var by:ClassInfo;
	};
	
	@:children var fields:Array<FieldInfo>;
}

typedef TypePath<T> = {
	@:attr var path:String;
	@:children var params:Array<TypeRef>;
}

typedef FieldInfo = {>HasMeta,
	@:optional(false) 
	@:attr('private') var isPrivate:Bool;
	
	@:name var name:String;
	
	@:optional @:attr var line:Int;
	
	@:optional @:attr var get:String;
	
	@:optional @:attr var set:String;
	
	@:optional(false) 
	@:attr('public') var isPublic:Bool;
	
	@:optional(false) 
	@:attr('static') var isStatic:Bool;
	
	@:nth(1) var type:TypeRef;
	
}

typedef ClassInfo = {>BaseInfo,
	@:optional(false)
	@:attr('extern') var isExtern : Bool;
	
	@:list('implements') var interfaces:Array<TypePath<ClassInfo>>;
	
	@:optional 
	@:tag('extends') var base:TypePath<ClassInfo>;
	
	@:children var fields:Array<FieldInfo>;
}

typedef TypedefInfo = {>BaseInfo,
	@:nth(1) var target:TypeRef;
}

typedef EnumInfo = {> BaseInfo,
	@:optional(false)
	@:attr('extern') var isExtern : Bool;
	@:children var constructors:Array < {
		>HasMeta,
		@:name var name:String;
		@:optional
		@:attr('a') var params:Params;
		@:children var types:Array<TypeRef>;
		
	}>;
}