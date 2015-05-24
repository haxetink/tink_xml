package tink.xml;

import tink.core.Error;

class ReaderError extends TypedError<Source> {
  public function new(msg:String, data, ?pos) {
    super(UnprocessableEntity, msg, pos);
    this.data = data;
  }
  override function toString() {
    return '$message at element:' + data.toString();
  }
}