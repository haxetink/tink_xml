package tink.xml;

using StringTools;

abstract Text(String) from String to String {
	
	@:to inline function toFloat()
		return 
			if (this == null) Math.NaN;
			else 
				Std.parseFloat(this.trim());
		
	@:to inline function toInt()
		return 
			if (this == null) 0; 
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