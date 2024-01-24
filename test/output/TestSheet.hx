package output;

import uncastled.model.*;

class TestSheet {
	public var rows:Array<TestSheet_Row> = [];
	public var rowsById:Map<TestSheet_RowUUID, TestSheet_Row> = [];

	public function get(id:TestSheet_RowUUID):TestSheet_Row {
		return rowsById[id];
	}

	public function new() {}

	public function addRow(row:TestSheet_Row):Void {
		rows.push(row);
		rowsById[row.getUUID()] = row;
	}
}
