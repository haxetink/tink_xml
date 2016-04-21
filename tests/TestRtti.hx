package;

import haxe.Resource;
import haxe.unit.TestCase;
import tink.xml.Structure;

class TestRtti extends TestCase {
  
  function test() {
    var s = Resource.getString('rtti');
    
    switch new Structure<Rtti>().read(s) {
      case Success(data):
        //
        for (d in data)
          switch d {
            case IClass( { path: _.toString() => 'haxe.ds.EnumValueMap', isExtern: false, isInterface: false, interfaces: v, params: { length: 2} }):
              assertEquals(1, v.length);
              assertEquals('haxe.IMap', v[0].path.toString());
            default:
          }
      case Failure(e):
        var x:Xml = cast e.data;
        trace(e.message, x);
    }    
  }
  
}