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

class TestParse extends Base {
	function test() {
		assertStructEq(
			Success({ foo: 5 }),
			parseXml(('<x><foo>5</foo></x>' : { foo : Int }))
		);
		assertStructEq(
			Failure(cast { data : { error: 'missing element bar' }}),
			parseXml(('<x><foo>5</foo></x>' : { bar : Int }))
		);
		
		var example = haxe.Resource.getString('example1');
		assertEquals('a87700ff', parseXml((example : Example)).sure().palettes[0].colors[2].value);
	}
}