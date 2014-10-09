package ;

import tink.xml.Decode.parseXml;

using tink.CoreApi;

typedef Example = {
	
	@:list('palette') var palettes:Array<{
		@:attr var version:Int;
		@:attr var mode:String;
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
	function test() {
		assertStructEq(
			Success({ foo: 5 }),
			parseXml(('<x><foo>5</foo></x>' : { foo : Int }))
		);
    
		assertStructEq(
			Failure(cast { message : 'missing element bar' }),
			parseXml(('<x><foo>5</foo></x>' : { bar : Int }))
		);
		
		var example = haxe.Resource.getString('example1');
		assertEquals('a87700ff', parseXml((example : Example)).sure().palettes[0].colors[2].value);
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
      parseXml((scxml : Scxml)).sure()
    );
	}
}