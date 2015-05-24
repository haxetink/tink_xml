package tink.xml;

import tink.core.Outcome;

class Reader<T> {

	public function new() {}
	
	function doRead(x:Source):T 
		throw 'abstract';
		
	public function read(x:Source):Outcome<T, ReaderError> 
		return
			try {
				Success(doRead(x));
			}
			catch (e:ReaderError)
				Failure(e)
			catch (e:Dynamic)
				Failure(new ReaderError('error "$e"', x));
}