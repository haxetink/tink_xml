# Tinkerbell XML Library

This library aims to make XML parsing in Haxe pleasant, by allowing to express complex XML structures as Haxe types.

Take this example atom feed from wikipedia:

```xml
<?xml version="1.0" encoding="utf-8"?>
 
<feed xmlns="http://www.w3.org/2005/Atom">
 
  <title>Example Feed</title>
  <subtitle>A subtitle.</subtitle>
  <link href="http://example.org/feed/" rel="self" />
  <link href="http://example.org/" />
  <id>urn:uuid:60a76c80-d399-11d9-b91C-0003939e0af6</id>
  <updated>2003-12-13T18:30:02Z</updated> 
 
  <entry>
    <title>Atom-Powered Robots Run Amok</title>
    <link href="http://example.org/2003/12/13/atom03" />
    <link rel="alternate" type="text/html" href="http://example.org/2003/12/13/atom03.html"/>
    <link rel="edit" href="http://example.org/2003/12/13/atom03/edit"/>
    <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
    <updated>2003-12-13T18:30:02Z</updated>
    <summary>Some text.</summary>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">
        <p>This is the entry content.</p>
      </div>
    </content>
    <author>
      <name>John Doe</name>
      <email>johndoe@example.com</email>
    </author>
  </entry>
 
</feed>
```

It can be parsed like so (code is not checked against the atom spec!):
  
```haxe
package atom;

typedef Entity = {
  var title:String;
  var id:String;
  var updated:String;
  @:list('link') var links:Array<{
    @:attr var href:String;
    @:optional @:attr var rel:String;
    @:optional @:attr var type:String;
  }>;
  
  @:optional var author:{
    var name:String;
    var email:String;
    @:optional var uri:String;
  };
}

typedef Feed = {>Entity,
  @:optional @:tag var subtitle:String;
  @:list('entry') var entries:Array<Entry>;
}

typedef Entry = {>Entity,
  var summary:String;
  var content:{
    @:attr var type:String;
    @:content var content:String;
  };
}

//And now:
  
switch new tink.xml.Structure<atom.Feed>().read('example.xml') {
  case Success(feed):
    trace('Loaded ${feed.entries.length} entries from feed ${feed.title}');
  case Failure(e):
    trace('error reading feed: $e');
}
```

Kabooom! It's parsed. How? The `tink.xml.Structure` is a `@:genericBuild` type that will create the necessary validating parser at compile time.

# XML API

The `tink_xml` library brings its own small XML API defined like so:

```haxe
abstract Source {
  public var name(get, never):NodeName;
  
  public function getText():Text;
  public function getAttribute(name:String):Null<Text>;
  public function elements():Iterator<Source>;
  public function toString():String;
  
  @:from static public function fromString(s:String):Source;
  @:from static public function fromXml(x:Xml):Source;
  @:from static public function fromDom(e:js.html.Element):Source;
}  

abstract NodeName to String {
  
  @:from static inline function ofString(s:String):NodeName;
  @:commutative @:op(a == b) static public inline function equalsString(a:NodeName, b:String):Bool;     
  @:op(a == b) static public inline function equalsName(a:NodeName, b:NodeName):Bool; 
}

abstract Text from String to String {
  @:to inline function toInt():Int;
  @:to inline function toFloat():Float;    
  @:to inline function toBool():Bool;
}
```

Nothing fancy. The main reason is that this library should work on the DOM all the same. Also, small interfaces rock.
Please do note that `NodeName` is case insensitive.

# Supported types

## Anonymous objects

Anonymous objects are what you will use most of the time to represent tags.

Their fields may have the following metadata (the name parameter always being optional and defaulting to the field name):
  
- `@:attr(name)` reads an attribute
- `@:tag(name)` reads a single tag - this is also the default
- `@:list(name)` reads all children named `name`
- `@:nth(pos)` reads the element at position `pos` (this is still a little quirky. using anything but `@:nth(1)` is currently not recommended)
- `@:children` reads all other children
- `@:name` reads the element's name
- `@:content` reads all of the element's content (think `innerHTML`)

Additionally, `@:attr` and `@:tag` may be `@:optional` with a default value, e.g.:

```haxe
{
  @:optional('xhtml')
  @:attr var type:String;
  @:content var content:String;
}
```

## Enums

Enums can also be matched against tags, considering the following:
  
1. Every constructor must have exactly one argument (that should have the type of the element)
2. The tag is matched like so:
  
  - if prefixed by `@:default` (allowed only once per enum) it is matched against when no other constructor matches
  - if prefixed by `@:tag(name)` then it is matched against if the element's name is `name`
  - if prefixed by `@:if(condition)` then it is matched if condition evaluates to true, where `x` is the currently parsed element represented as `tink.xml.Source` (see below)
  - if no metadata is specified, then all except one leading capital letters of the constructor name are removed and the rest is matched against the element name, e.g. TDClass is matched against "class".

Matching is done in order of appearence, except for `@:default` which always goes last.

Here is an example:

```haxe
enum Element {
  @:tag(a) EAnchor(a:Anchor);
  @:default EAny(n:Any);
}

typedef Base = {
  @:children var children:Array<Element>;
}

typedef Anchor = {>Base,
  @:optional @:attr var href: String; 
  @:optional @:attr var title: String; 
  @:optional @:attr var name: String; 
}
typedef Any = {>Base,
  @:name var nodeName:String,
}
```

You could read an XHTML document with this and you would get a tree, where anchors are parsed and extract them.

## Arrays

An array is read by reading each child as the array type. Booooring.

## Primitives

Currently `Int`, `String`, `Float` and `Bool` are supported.  
These strings are considered `false` (case insensitively): `''`, `'0'`, `'false'` and `'null'`.

## Source

A `Source` is passed as is. Example:
  
```haxe
typedef Entry = {>Entity,
  var summary:String;
  var content:tink.xml.Source;//will simply contain the child node called 'content', e.g. in the above example `<content type="xhtml">...</content>`
}
```

## Abstracts and Classes

Both abstracts and classes can be read if the have a static `readXml` method, with one single argument, that must have a valid type for `tink_xml` (could be a `Source`, but could also be an anonymous object or what not). The return type must be the type itself.

# TokenList

There is a special `TokenList` type, that allows you to easily parse token lists, e.g `TokenList<' '>` will result in the following abstract:
  
```haxe
abstract TokenList20(Array<String>) from Array<String> to Array<String> {
  public var length(get, never):Int;
  
  public inline function iterator():Iterator<String>;
  
  @:arrayAccess function get(index:Int):String;
  
  @:to public function toString():String;
  
  @:from static function ofString(s:String):TokenList20;
}
```
