package tink.xml;

using StringTools;

@:forward
abstract Source(ISource) from ISource {
	
	@:from static public function fromString(s:String):Source 
		return 
			try 
				fromXml(Xml.parse(s))
			catch (e:Dynamic) 
				new InvalidSource(s, e);
	
	@:from static public function fromXml(x:Xml):Source
		return new XmlSource(switch x.nodeType {
			case Document: x.firstElement();
			case _: x;
		});
		
	#if js
	@:from static public function fromDom(e:js.html.Element):Source
		return new DomSource(e);
	#end
}

interface ISource {
	var name(get, never):NodeName;
	function getText():Text;
	function getAttribute(name:String):Null<Text>;
	function elements():Iterator<Source>;
	function toString():String;
}

#if js
private class DomSource implements ISource {
	public var name(get, never):NodeName;
		inline function get_name():NodeName
			return target.nodeName;
	
	var target:js.html.Element;
	
	public function new(target)
		this.target = target;
		
	public function getText():Text
		return target.innerHTML;
		
	public function getAttribute(name:String):Null<Text> 
		return target.getAttribute(name);
		
	public function elements():Iterator<Source> {
		var ret = 0...target.children.length;
		return {
			hasNext: function () return ret.hasNext(),
			next: function () return new DomSource(target.children[ret.next()])
		}		
	}
	
	public function toString():String
		return target.outerHTML;
}
#end
private class InvalidSource implements ISource {
	
	public var name(get, never):NodeName;
		function get_name()
			return throw error;
			
	var error:ReaderError;
	var source:String;
	
	public function new(source:String, error:Dynamic) {
		this.source = source;
		this.error = new ReaderError('Failed to parse Xml because $error', this);
	}
		
	public function getText():Text
		return throw error;
		
	public function getAttribute(name:String):Null<Text>
		return throw error;
		
	public function elements():Iterator<Source>
		return throw error;
		
	public function toString():String
		return source;
}

private class XmlSource implements ISource {
	var x:Xml;
	
	public var name(get, never):NodeName;
		inline function get_name()
			return (x.nodeName : NodeName);
				
	public function getText()
		return [for (c in x) if (c.nodeType != Xml.Comment) try c.nodeValue catch (e:Dynamic) c.toString()].join('');
				
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