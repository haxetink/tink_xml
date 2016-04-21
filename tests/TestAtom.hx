package;

import haxe.Resource;
import haxe.unit.TestCase;
import tink.xml.Structure;

class TestAtom extends TestCase {

  function test() {
    switch new Structure<Feed>().read(Resource.getString('atom')) {
      case Success( { entries: [ { links : links } ] } ):
        assertEquals(3, links.length);
        assertEquals('text/html', links[1].type);
      default:
    }
  }
  
}

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