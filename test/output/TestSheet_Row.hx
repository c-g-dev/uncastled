package output;

import uncastled.model.*;

class TestSheet_Row extends CastleDbRow {
	public var TableId:TestSheet_RowUUID;
	public var Data:String;
	public var ExtraData:TestSheet_ExtraData;
	public var Image:HeapsImageHandler;

	public function new() {}

	public function getUUID():TestSheet_RowUUID {
		return TableId;
	}
}
