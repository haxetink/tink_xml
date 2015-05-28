package;

import haxe.Resource;
import haxe.unit.TestCase;
import tink.xml.Structure;

class TestRtti extends TestCase {
	
	function test() {
		var s = Resource.getString('rtti');
		//var p:Rtti.Path = [];
		switch new Structure<Rtti>().read(s) {
			case Success(data):
				//$type(data);
				
				for (d in data)
					switch d {
						case IClass( { path: _.toString() => 'flash.events.EventDispatcher', isExtern: true, isInterface: false, interfaces: [{ path: _.toString() => 'flash.events.IEventDispatcher' }] }):
							assertTrue(true);
						default:
					}
			case Failure(e):
				var x:Xml = cast e.data;
				trace(e.message, x);
		}		
	}
	
}