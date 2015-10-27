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
  
  static function oneOf(m:Metadata, metas:Array<String>) {
    var ret = null;
    
    var metas = metas.join(', ') + ', ';
    
    for (tag in m)
      if (metas.indexOf('@'+tag.name+', ') != -1) {
        if (ret == null)
          ret = tag;
        else
          tag.pos.error('Can only have one of $metas');
      }
      
    return ret;
  }
  static function baseReader(t:Type, b:BaseType) {
    
    var func = b.module+'.' + b.name+'.readXml';
    
    var call = macro @:pos(b.pos) @:privateAccess $p{func.split('.')}; 
    
    return
      switch call.typeof() {
        case Success(TFun([x], y)) if (Context.unify(t, y)):
          
          macro @:pos(b.pos) 
            $call($p{readerForType(x.t).split('.')}.inst.doRead(x));
            
        case Success(v):
          b.pos.errorExpr('Invalid type for $func');
          
        case Failure(f): 
          b.pos.errorExpr(f.message);
      }
  }
  static function enumReader(e:EnumType):Expr {
    var cases = new Array<Case>();
    var def = null;
    for (name in e.names) {
      var ctor = e.constructs[name];
      switch ctor.type {
        case TFun([ { t: t } ], _):
          var reader = macro $p{(e.module+'.' + e.name+'.' + ctor.name).split('.')}(${getReader(t)}.doRead(x));
          if (ctor.meta.has(':default')) {
            if (def != null)
              ctor.pos.error('Only one @:default rule allowed');
            def = reader;
          }
          else {
            var name = ctor.name;
            
            while (name.length > 1 && name.charAt(1).toUpperCase() == name.charAt(1))
              name = name.substr(1);
            
            var condition = 
              switch [ctor.meta.extract(':if'), ctor.meta.extract(':tag')] {
                case [[], []]:
                  macro x.name == $v{name};
                case [[v], []]: 
                  switch v.params {
                    case []:
                      v.pos.error('Condition missing');
                    case [v]:
                      v;
                    case v:
                      v[1].reject('Too many conditions');
                  }
                case [[], [v]]:
                  switch v.params {
                    case []:
                      v.pos.error('Tag name missing');
                    case [v]:
                      macro x.name == $v{v.getName().sure()};
                    case v:
                      v[1].reject('Too many tag names');
                  }
                default:
                  ctor.pos.error('Only one @:if or @:tag rule allowed');
              }
            
            cases.push( { 
              values: [macro x],
              guard: condition,
              expr: reader,
            });            
          }
          
        default:
          Context.currentPos().error('${e.name}.${ctor.name} must have exactly one argument for XML parsing');
      }
    }
    if (def == null)
      def = error('No matching rule found');
    return ESwitch(macro x, cases, def).at();
  }
  
  static function buildReader():Array<Field> {
    var type = Context.getLocalClass().get().superClass.params[0];
    var body = 
      switch type.getID() {
        case 'Int' | 'Float' | 'String' | 'Bool': 
          macro x.getText();
        case 'tink.xml.Source':
          macro x;
        case 'Array':
          switch type.reduce() {
            case TInst(_.toString() => 'Array', [t]):
              macro {
                var reader = ${getReader(t)};
                [for (x in x.elements()) reader.doRead(x)];
              }
            default: throw 'assert';
          }
        default:
          switch type.reduce() {
            case TEnum(_.get() => e, _):
              enumReader(e);
            case TAnonymous(_.get() => { fields: fields } ):
              anon(fields, type);
            case TAbstract(_.get() => a, _):
              baseReader(type, a);
            case TInst(_.get() => i, _):
              baseReader(type, i);
            case v:
              Context.currentPos().error('cannot handle $v');
          }          
      }  
      
    var ct = type.toComplex();  
    return Context.getBuildFields().concat((macro class {
      override function doRead(x:Source):$ct return $body;
    }).fields);
  }
  
  static function error(message:String)
    return macro throw new ReaderError($v{message}, x);
  
  static function anon(fields:Array<ClassField>, type:Type):Expr {
    var obj = [];
    
    var ret = ['ret'.define(EObjectDecl(obj).at(), type.toComplex())],
        byName = [],
        byIndex = [],
        rest = null;
    
    ret.push(macro var i = 0);
    ret.push(macro for (x in x.elements()) { var n = ++i; $b{byIndex}; $b{byName}; });
    
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
              error('Missing attribute "$name"');
            case Some(Right(v)):
              //macro @:pos(f.pos) ret.$fieldName = $v; <-- this seems to mess up positions
              'ret.$fieldName'.resolve(f.pos).assign(v, v.pos);
            default:
              [].toBlock();
          }
        //This is quirky. Find a way to init the field right away  
        if (defaultValue == None)
          obj.push( { field: fieldName, expr: macro cast null } );
        
        ret.push(macro @:pos(f.pos) switch x.getAttribute($v{name}) {
          case null:
            $ifNotFound;
          case v:
            ret.$fieldName = v;
        });
      }
      
      function name() 
        obj.push({ field: fieldName, expr: macro x.name });
      
      function children() { 
        if (rest != null)
          f.pos.error('Only one @:children tag allowed');
          
        obj.push( { field: fieldName, expr: macro [] } );
        var type = 
          switch f.type.reduce() {
            case TInst(_.toString() => 'Array', [t]):
              t;
            default:
              f.pos.error('@:children must always be Array');
          }        
        
        rest = macro @:pos(f.pos) ret.$fieldName.push(${getReader(type)}.doRead(x));
      }
      
      function content()
        obj.push( { field: fieldName, expr: macro x.getText() } );
      
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
        byName.push(macro if (x.name == $v{name}) {
          ret.$fieldName.push($p{readerForType(type).split('.')}.inst.doRead(x));
          continue;
        });
      }
      
      function tag(name:String) { 
        ret.unshift(fieldName.define(macro false));
        if (defaultValue == None) 
          obj.push( { field: fieldName, expr: macro cast null } );
          
        switch defaultValue {
          case None:
            ret.push(macro if (!$i{fieldName}) 
              ${error('Missing element "$name"')}
            );
          case Some(Right(v)):
            ret.push(macro if (!$i{fieldName}) 
              ret.$fieldName = $v
            );
          default:
        }
        var set = macro ret.$fieldName = $p{readerForType(f.type).split('.')}.inst.doRead(x);
        byName.unshift(macro if (x.name == $v{name}) {
          if (!$i{fieldName}) {
            $i{fieldName} = true;
            $set;
          }
          else
            ${
              if (f.meta.has(':useFirst')) macro $b{[]}
              else if (f.meta.has(':useLast')) set
              else error('Duplicate element "$name"')
            };
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
        ':nth' => null,//this is an exception as seen in the switch statement below
      ];
      
      var found = false;
      
      for (tag in f.meta.get()) 
        switch fieldKinds[tag.name] {
          case null:
            if (tag.name == ':nth') {
              switch tag.params {
                case []: 
                  tag.pos.error('parameter missing');
                case [{ expr: EConst(CInt(s)) }]:
                  obj.push({ field: fieldName, expr: macro null });
                  byIndex.push(macro if (n == ${tag.params[0]}) {
                    ret.$fieldName = ${getReader(f.type)}.doRead(x);
                    continue;
                  });
                  found = true;
                case v:
                  tag.pos.error('anything but a single integer constant as a parameter is currently not supported');
              }            
            }
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
    
    if (rest != null)
      byName.push(rest);
    ret.push(macro ret);
    return ret.toBlock();
  }
  
  static function getReader(type:Type)
    return macro $p{readerForType(type).split('.')}.inst;
    
  static function readerForType(type:Type):String {
    //var signature = Context.signature(type.toComplex());
    type = type.reduce();
    var signature = type.toComplex().toString();
    
    signature = Context.signature(signature);
    
    if (!map.exists(signature))
      map[signature] = counter++;
      
    var name = 'tink.xml.Parser_'+map[signature];
    
    var exists = 
      try {
        Context.getModule(name);
        true;
      }
      catch (e:Dynamic) false;
      
    if (!exists) {
      var main = name.split('.').pop(),
          ct = type.toComplex();
          
      var reader = macro class $main extends Reader<$ct> {
        static public var inst(default, null) = ${main.instantiate()};
      }
      
      reader.meta = [{ name : ':build', params: [macro tink.xml.Structure.buildReader()], pos: reader.pos }];
      
      Context.defineModule(name, [reader]);
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