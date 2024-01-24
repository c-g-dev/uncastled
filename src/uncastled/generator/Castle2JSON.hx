package uncastled.generator;

import haxe.Json;

class Castle2JSON {
    public static function castle2Json(cdbContents: String): Dynamic {
        var jsob: Dynamic = haxe.Json.parse(cdbContents);
        var sheets: Map<String, DBSheet> = [];
        for(eachSheet in (cast jsob.sheets: Array<Dynamic>)) {
            var cols: Map<String, DBColumn> = [];
            for(eachCol in (cast eachSheet.columns: Array<Dynamic>)){
                cols[eachCol.name] = Column(eachCol.name, getColumnType(eachSheet.name, eachCol.name, eachCol.typeStr));
            }
            var vals: Array<DBColumn> = [];
            for(key => val in cols){
                vals.push(val);
            }
            sheets[eachSheet.name] = Sheet(eachSheet.name, vals);
        }
        var newLines: Map<String, Array<DbRow>> = [];
        for(eachSheet in (cast jsob.sheets: Array<Dynamic>)){
            for(eachLine in (cast eachSheet.lines: Array<Dynamic>)){
                var newRow: Array<DbCell> = [];
                for(eachField in Reflect.fields(eachLine)){
                    var fieldVal: Dynamic = Reflect.field(eachLine, eachField);
                    var tp: DBColumnType = null;
                    switch sheets[eachSheet.name] {
                        case Sheet(val, cols): {
                            for(eachCol in cols){
                                switch eachCol {
                                    case Column(name, t): {
                                        if (name == eachField){
                                            tp = t;
                                        }
                                        
                                    }
                                    default:
                                }
                            }
                        }
                    }
                    newRow.push(Cell(eachField, convertValue(fieldVal, tp, sheets)));
                    if(!newLines.exists(cast eachSheet.name)){
                        newLines[cast eachSheet.name] = [];
                    }
                }
                newLines[cast eachSheet.name].push(Row(newRow));
            }

        }
        var newObj: Dynamic = {};
        newObj.sheets = {};
        for(sheetname => rows in newLines){
            var newSheetObj: Dynamic = {};
            Reflect.setField(newObj.sheets, sheetname, []);
            for(eachRow in rows){
                var newLineObj = {};
                switch eachRow {
                    case Row(cells): {
                        for(eachCell in cells){
                            switch (eachCell){
                                case Cell(k, v): {
                                    Reflect.setField(newLineObj, k, v);
                                }
                            }
                        }        
                    }
                }
                Reflect.field(newObj.sheets, sheetname).push(newLineObj);
            }
        }
        return newObj;
    }

    static function getColumnType(sheetName: String, fieldName: String, typeStr:String): DBColumnType {
        if(typeStr.charAt(0) == "5"){
            return Enum(typeStr.substring(2, typeStr.length).split(","));
        }
        else if (typeStr.charAt(0) == "8"){
            return Array(sheetName + "@" + fieldName);
        }
        else{
            return Raw;
        }
    }


    static function convertValue(fieldVal: Dynamic, tp: DBColumnType, sheets: Map<String, DBSheet>): Dynamic {
        switch tp {
            case Raw: {
                return fieldVal;
            }
            case Enum(vals): {
                if(fieldVal is String){
                    return vals[Std.parseInt(cast fieldVal)];
                }
                else{
                    return vals[cast fieldVal];
                }
            }
            case Array(t): {
                var sheet = sheets[t];
                var cols: Map<String, DBColumnType> = [];

                switch sheet {
                    case Sheet(val, colsArg):{
                        for(eachCol in colsArg){
                            switch eachCol {
                                case Column(name, t): {
                                    cols.set(name, t);
                                }
                            }
                        }
                    }
                }

                var newArr: Array<Dynamic> = [];
                for(eachVal in (cast fieldVal: Array<Dynamic>)){
                    var newObj = {};
                    for(eachField in Reflect.fields(eachVal)){
                        var val: Dynamic = Reflect.field(eachVal, eachField);
                        Reflect.setField(newObj, eachField, convertValue(val, cols[eachField], sheets));
                    }
                    newArr.push(newObj);
                }
            
                return newArr;
            }
        }
    }
}

enum DbCell {
    Cell(key: String, val: Dynamic);
}

enum DbRow {
    Row(cells: Array<DbCell>);
}

enum DBSheet {
    Sheet(val: String, cols:  Array<DBColumn>);
}

enum DBColumn {
    Column(name: String, t: DBColumnType);
}

enum DBColumnType {
    Raw;
    Enum(vals: Array<String>);
    Array(t: String);
}