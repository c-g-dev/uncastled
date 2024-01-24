package output;

import uncastled.model.*;
import haxe.Json;
import haxe.EnumTools;

class Test extends CastleDbDatabase {
	public static var TestSheet = new TestSheet();

	public function new() {}

	public static function load(fileContents:String) {
		var dbObject = Json.parse(fileContents);
		for (sheetObject in (cast dbObject.sheets : Array<Dynamic>)) {
			if (sheetObject.name == "TestSheet") {
				var sheet = new TestSheet();
				for (eachRow in (cast sheetObject.lines : Array<Dynamic>)) {
					var row = new TestSheet_Row();
					row.TableId = EnumTools.createByName(TestSheet_RowUUID, eachRow.TableId, []);
					row.Data = eachRow.Data;
					row.ExtraData = new TestSheet_ExtraData();
					for (eachRow_sub in (cast eachRow.ExtraData : Array<Dynamic>)) {
						var row_TestSheet_ExtraData_Row = new TestSheet_ExtraData_Row();
						row_TestSheet_ExtraData_Row.Seller = eachRow_sub.Seller;
						row.ExtraData.addRow(row_TestSheet_ExtraData_Row);
					}
					row.Image = new HeapsImageHandler(eachRow.Image, "Test");
					sheet.addRow(row);
				}

				TestSheet = sheet;
			}
		}
		runPostLoad();
	}

	static var callbacks:Array<() -> Void> = [];

	public static function addPostLoad(func:() -> Void) {
		callbacks.push(func);
	}

	public static function runPostLoad() {
		for (eachCallback in callbacks) {
			eachCallback();
		}
	}
}
