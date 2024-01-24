package output;

import uncastled.model.*;

class TestSheet_ExtraData extends CastleDbSheet<TestSheet_ExtraData_Row> {
	public var rows:Array<TestSheet_ExtraData_Row> = [];

	public function new() {}

	public function addRow(row:TestSheet_ExtraData_Row):Void {
		rows.push(row);
	}
}
