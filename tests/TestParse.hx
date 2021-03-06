package ;

import tink.xml.Structure;

using tink.CoreApi;

typedef Example = {

  @:list('palette') var palettes:Array<{
    @:attr var version:Int;
    @:attr var mode:String;
    @:attr var value:Float;
    @:list('color') var colors:Array<{
      @:attr var value:String;
    }>;
  }>;

  @:list('item') var items:Array<{
    @:optional @:attr var scope:String;
    @:optional @:attr var definition:String;
    @:attr var colorsLight:String;
    @:attr var colorsDark:String;
    @:attr var traits:String;
  }>;
}

typedef Scxml = {
  @:attr var initial:String;
  @:list(state) var states:Array<{
    @:attr var id:String;
    @:list(transition) var transitions:Array<{
      @:attr var event:String;
      @:attr var target:String;
    }>;
  }>;
}

class TestParse extends Base {


  function testIssue7() {
    assertEquals(123, new Structure<{ x: Int }>().read('<root><X>123</X></root>').sure().x);// also testing case insensitivity here
  }

  function testIssue8() {
		var data = new tink.xml.Structure<{@:name var name:String;}>().read("<hello/>").sure();
		assertEquals('hello', data.name);
  }
  function test() {
    assertStructEq(
      Success( { foo: 5 } ),
      new Structure<{ foo : Int }>().read('<x><foo>5</foo></x>')
    );

    assertEquals(
      'Missing element "bar"',
      switch new Structure<{ bar : Int }>().read('<x><foo>5</foo></x>') {
        case Failure(f): f.message;
        default: null;
      }
    );

    var example = haxe.Resource.getString('example1');

    assertEquals('a87700ff', new Structure<Example>().read(example).sure().palettes[0].colors[2].value);
    assertEquals(3.1, new Structure<Example>().read(example).sure().palettes[0].value);
    var scxml = haxe.Resource.getString('scxml');

    assertStructEq(
      ({
        initial: 'ready',
        states: [
          {
            id:"ready",
            transitions:[
              { event:"watch.start", target:"running"}
            ]
          },
          {
            id:"running",
            transitions:[
              { event:"watch.split", target:"paused"},
              { event:"watch.stop", target:"stopped"}
            ]
          },
          {
            id:"paused",
            transitions:[
              { event:"watch.unsplit", target:"running"},
              { event:"watch.stop", target:"stopped"}
            ]
          },
          {
            id:"stopped",
            transitions:[
              { event:"watch.reset", target:"ready"}
            ]
          }
        ]
      } : Scxml),
      new Structure<Scxml>().read(scxml).sure()
    );
  }
}