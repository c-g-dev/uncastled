package uncastled.generator;

var STATIC_TEMPLATES: Map<String, String> = [
    'DatabaseTemplate.txt' => 'package <PACKAGE>;

import uncastled.model.*;
import haxe.Json;

import haxe.EnumTools;

class <CLASSNAME> {

    <SHEETS>

    public function new() {}

    public static function load(fileContents: String) {
        var dbObject = Json.parse(fileContents);
        for (sheetObject in (cast dbObject.sheets: Array<Dynamic>)) {
            <SHEET_PARSE_LOGIC>
        }
        runPostLoad();
    }

    static var callbacks: Array<() -> Void> = [];
    public static function addPostLoad(func: () -> Void) {
        callbacks.push(func);
    }

    public static function runPostLoad() {
        for(eachCallback in callbacks){
            eachCallback();
        }
    }
}',
    'getUUIDRowFunctionTemplate.txt' => 'public function getUUID(): <ENUM_NAME> {
    return <UUID_NAME>;
}',
    'RowTemplate.txt' => 'package <PACKAGE>;

import uncastled.model.*;

class <CLASSNAME> {

    <FIELDS>

    public function new() {}

    <GET_UUID>
}',
    'SheetParseLogic.txt' => 'if(sheetObject.name == "<sheet_name>"){
    var sheet = new <sheet_name>();
    for(eachRow in (cast sheetObject.lines: Array<Dynamic>)){
        var row = new <row_name>();
        <FIELD_ASSIGNMENT>
        sheet.addRow(row);
    }
    <sheet_name> = sheet;
}',
    'SheetTemplate.txt' => 'package <PACKAGE>;

import uncastled.model.*;

class <CLASSNAME> {

    public var rows: Array<%ROWTYPE%> = [];
    <OPTIONAL_ROWMAP_DEFINITION>

    public function new() {}
    public function addRow(row: %ROWTYPE%): Void {
        rows.push(row);
        <OPTIONAL_ROWMAP_PUSH>
    }

}',
    'SheetUniqueIdTemplate.txt' => 'package <PACKAGE>;

enum <SHEETNAME>_Id {
    <ENUM_DEFINITIONS>
}'
];
