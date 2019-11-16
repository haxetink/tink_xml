import tink.xml.*;

using tink.CoreApi;

class TestIssue6 extends Base {
  function assertFail<X>(message:String, o:Outcome<X, ReaderError>, ?pos)
    assertEquals(message, switch o {
      case Success(_): 'no error';
      case Failure(e): e.message;
    }, pos);

  function test() {

    var x = new Structure<Strict<{
      @:attr var foo:Int;
      @:optional @:attr var _foo:Int;
      @:child var bar:String;
      @:optional @:child var _bar:String;
    }>>();

    assertStructEq(
      Success( { foo: 123, bar: 'yo' } ),
      x.read('<x foo="123"><bar>yo</bar></x>')
    );

    assertStructEq(
      Success( { foo: 123, _foo: 321, bar: 'yo', _bar: 'nay' } ),
      x.read('<x foo="123" _foo="321"><bar>yo</bar><_bar>nay</_bar></x>')
    );

    assertFail('Missing attribute "foo"', x.read('<x><bar>yo</bar></x>'));
    assertFail('Missing element "bar"', x.read('<x foo="123" />'));

    assertFail('Unknown attribute "boo"', x.read('<x foo="123" boo="321"><bar>yo</bar></x>'));
    assertFail('Unknown element "FAR"', x.read('<x foo="123"><bar>yo</bar><far>nay</far></x>'));
  }
}