package tink.xml;

using StringTools;

@:forward
abstract Source(ISource) from ISource {
	
	@:from static public function fromString(s:String):Source 
		return fromXml(Xml.parse(s));
	
	@:from static public function fromXml(x:Xml):Source
		return new XmlSource(switch x.nodeType {
			case Document: x.firstElement();
			case _: x;
		});
		
}

abstract Text(String) from String to String {
	
	@:to inline function toInt()
		return 
			if (this == null) 0; 
			else 
				Std.parseInt(this.trim());
		
	@:to inline function toFloat()
		return 
			if (this == null) Math.NaN;
			else 
				Std.parseInt(this.trim());
		
	@:to inline function toBool()
		return 
			if (this == null) false;
			else 
				switch this.trim().toLowerCase() {
					case '', '0', 'false', 'null': //And this is why "human readable" is a stupid idea
						false; 
					default: 
						true;
				}
}

interface ISource {
	var name(get, never):Text;
	function getText():Text;
	function getAttribute(name:String):Null<Text>;
	function elements():Iterator<Source>;
	function toString():String;
}

private class XmlSource implements ISource {
	var x:Xml;
	
	public var name(get, never):Text;
		inline function get_name()
			return x.nodeName;
				
	public function getText()
		return [for (c in x) try c.nodeValue catch (e:Dynamic) c.toString()].join('');
				
	public function new(x)
		this.x = x;
		
	public function getAttribute(name:String):Null<Text> 
		return x.get(name);
	
	public function elements():Iterator<ISource> {
		var ret = x.elements();
		return {
			hasNext: function () return ret.hasNext(),
			next: function () return new XmlSource(ret.next())
		}
	}
	public function toString():String
		return x.toString();
	
}