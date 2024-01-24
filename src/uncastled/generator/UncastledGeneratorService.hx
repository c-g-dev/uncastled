package uncastled.generator;

import uncastled.generator.Templates.STATIC_TEMPLATES;
import haxe.Template;
import haxe.crypto.Base64;
import haxe.Exception;
import sys.io.File;
import haxe.Json;
import sys.FileSystem;

using StringTools;

class UncastledDbInfo {
    public var name: String;
    public var resourcePath: String;
    public var sheets: Array<UncastledDbInfo_Sheet> = [];
    public var images: Array<UncastledDbInfo_Image> = [];

    public function new() {}
    public function getSheetByName(name: String): UncastledDbInfo_Sheet {
        for(eachSheet in sheets){
            if(eachSheet.name == name){
                return eachSheet;
            }
        }
        return null;
    }
}

class UncastledDbInfo_Image {
    public var md5: String;
    public var base64: String;

    public function new() {}
}


class UncastledDbInfo_Sheet {
    public var name: String;
    public var isTransientSheet: Bool = false;
    public var columns: Array<UncastledDbInfo_Column> = [];
    public var rows: Array<Map<String, String>> = [];

    public function needsEnum(): Bool {
        for(eachCol in columns){
            switch(eachCol.type){
                case UNIQUE_ID: {
                    return true;
                }
                default:
            }
        }
        return false;
    }

    public function new() {}
}

class UncastledDbInfo_Column {
    public var type: UncastledDbInfo_ColumnType;
    public var name: String;

    public function new() {}
}


enum UncastledDbInfo_ColumnType {
    UNIQUE_ID;
    TEXT;
    IMAGE;
    REFERENCE(sheet: String);
    ENUM(enumName: String, vals: Array<String>);
    INT;
    ARRAY(kind: String);
}

enum EnumDef {
    Enum(name: String, fields: Array<String>);
}


class UncastledGeneratorService {

    var enumTypes: Array<UncastledDbInfo_ColumnType> = [];
    public var enumWriters: Array<Dynamic -> EnumDef> = [];

    public function new() {}

    public function generate(dbFile: String, outputPath: String, outputPackage: String, resourceFolder: String) {
        if (!FileSystem.exists(outputPath)) {
            FileSystem.createDirectory(outputPath);
        }
    
        var dbInfo: UncastledDbInfo = parseDbFile(dbFile);
        dbInfo.resourcePath = dbInfo.name;
        var dbClass = printDbClass(dbInfo);
        dbClass = dbClass.replace("<PACKAGE>", outputPackage);
        writeFile(dbClass, outputPath, dbInfo.name);

        for (sheet in dbInfo.sheets) {
            var rowEnum = printRowIdEnum(sheet);
            var rowClass = printRowClass(sheet);
            var sheetClass = printSheetClass(sheet);
            rowEnum = rowEnum.replace("<PACKAGE>", outputPackage);
            rowClass = rowClass.replace("<PACKAGE>", outputPackage);
            sheetClass = sheetClass.replace("<PACKAGE>", outputPackage);
            if(sheet.needsEnum()){
                writeFile(rowEnum, outputPath, getEnumName(sheet));
            }
            writeFile(rowClass, outputPath, getRowName(sheet));
            writeFile(sheetClass, outputPath, getSheetName(sheet));
        }

        var dbContents = File.getContent(dbFile);
        var json = Castle2JSON.castle2Json(dbContents);
        for(eachWriter in enumWriters){
            var et = eachWriter(json);
            switch et {
                case Enum(name, fields): {
                    enumTypes.push(ENUM(name, fields));
                }
            }
            
        }

        for(eachEnum in enumTypes){
            switch (eachEnum){
                case ENUM(enumName, vals): {
                    var template = new Template("package ::pkg::;
        
                        enum ::enumName:: {
                            ::foreach enumVals::
                                ::__current__::;
                            ::end::
                        }
                    ");
                    
                    var context = {
                        pkg: outputPackage,
                        enumName: enumName,
                        enumVals: vals
                    }

                    var output = template.execute(context);
                    writeFile(output, outputPath, enumName);
                }
                default: throw new Exception("nonenum in enumTypes");
            }
        }

        Sys.command("haxelib run formatter -s " + outputPath);

        var imgPath = resourceFolder + "\\" + dbInfo.name;
        if (!FileSystem.exists(imgPath)) {
            FileSystem.createDirectory(imgPath);
        }
        else{
            deleteDirRecursively(imgPath);
            FileSystem.createDirectory(imgPath);
        }
        for(eachImage in dbInfo.images){
            var filepath = imgPath + "\\" + eachImage.md5 + ".jpg";
            var bytes = Base64.decode(eachImage.base64);
            File.saveBytes(filepath, bytes);
        }
    }

    private function deleteDirRecursively(path:String) : Void
        {
          if (sys.FileSystem.exists(path) && sys.FileSystem.isDirectory(path))
          {
            var entries = sys.FileSystem.readDirectory(path);
            for (entry in entries) {
              if (sys.FileSystem.isDirectory(path + '/' + entry)) {
                deleteDirRecursively(path + '/' + entry);
                sys.FileSystem.deleteDirectory(path + '/' + entry);
              } else {
                sys.FileSystem.deleteFile(path + '/' + entry);
              }
            }
          }
        }

    function writeFile(fileContents:String, outputPath:String, fileName: String) {
        var fullPath = haxe.io.Path.join([outputPath, fileName]); 
        File.saveContent(fullPath + ".hx", fileContents);
    }

    function getSheetName(sheet:UncastledDbInfo_Sheet): String {
        return sheet.name;
    }

    function getRowName(sheet:UncastledDbInfo_Sheet): String {
        return sheet.name + "_Row";
    }

    function getEnumName(sheet:UncastledDbInfo_Sheet): String {
        return sheet.name + "_RowUUID";
    }

    function getTemplate(s:String): String {
        return STATIC_TEMPLATES[s];
    }

    public function printDbClass(dbInfo: UncastledDbInfo): String {
        var dbTemplate = getTemplate("DatabaseTemplate.txt");
        var parseLogicTemplate = getTemplate("SheetParseLogic.txt");

        var db = "";
        var sheetFields: String = "";
        var sheetLogic: String = "";
        for(eachSheet in dbInfo.sheets){
            if(eachSheet.isTransientSheet){
                continue;
            }
            var eachSheetString =  parseLogicTemplate.replace("<sheet_name>", getSheetName(eachSheet));
            eachSheetString = eachSheetString.replace("<row_name>", getRowName(eachSheet));
            var fieldAssignment = getFieldAssignmentLogic(dbInfo, eachSheet);
            eachSheetString = eachSheetString.replace("<FIELD_ASSIGNMENT>", fieldAssignment);
            sheetLogic += eachSheetString + "\n";
            sheetFields += "public static var " + getSheetName(eachSheet) + " = new " + getSheetName(eachSheet) + "();\n";
        }
        db = dbTemplate.replace("<SHEET_PARSE_LOGIC>", sheetLogic);
        db = db.replace("<SHEETS>", sheetFields);
        db = db.replace("<DB_CLASS_NAME>", dbInfo.name);
        db = db.replace("<CLASSNAME>", dbInfo.name);
        
        return db;
    }

    public function getFieldAssignmentLogic(dbInfo: UncastledDbInfo, eachSheet: UncastledDbInfo_Sheet, ?targetRowName: String = "row", ?sourceRowName: String = "eachRow"): String {
        var fieldAssignment = "";

        for(eachColumn in eachSheet.columns){
            switch(eachColumn.type){
                case UNIQUE_ID: {
                    fieldAssignment += targetRowName + "." + eachColumn.name + " = EnumTools.createByName(" + getEnumName(eachSheet) + ", " + sourceRowName + "." + eachColumn.name + ", []); \n";
                }
                case IMAGE: {
                    fieldAssignment += targetRowName + "." + eachColumn.name + " = new HeapsImageHandler(" + sourceRowName + "." + eachColumn.name + ", \"" + dbInfo.resourcePath.replace("\\", "\\\\") + "\"); \n";
                }
                case ENUM(enumName, vals): {
                    fieldAssignment += targetRowName + "." + eachColumn.name + " = EnumTools.createByIndex(" + enumName + ", " + sourceRowName + "." + eachColumn.name + ", []); \n";
                }
                case REFERENCE(sheet): {
                    fieldAssignment += "addPostLoad(() -> {" + targetRowName + "." + eachColumn.name + " = " + sheet + ".rowsById[EnumTools.createByName(" + sheet + "_RowUUID, " + sourceRowName + "." + eachColumn.name + ", [])];});";
                }
                case ARRAY(kind): {
                    var templ = new Template("
                        ::targetRowName::.::colName:: = new ::sheetName::();
                        for(::sourceRowName::_sub in (cast ::sourceRowName::.::colName:: : Array<Dynamic>)){
                            var ::targetRowName::_::rowname:: = new ::rowname::();
                            ::fieldassignment::
                            ::targetRowName::.::colName::.addRow(::targetRowName::_::rowname::);
                        }
                    ");

                    var arrSheet = dbInfo.getSheetByName(kind);
                    var fa =  getFieldAssignmentLogic(dbInfo, arrSheet, targetRowName + "_" + getRowName(arrSheet), sourceRowName + "_sub");

                    var cntx = {
                        targetRowName: targetRowName,
                        sourceRowName: sourceRowName,
                        sheetName: getSheetName(arrSheet),
                        colName: eachColumn.name,
                        rowname: getRowName(arrSheet),
                        fieldassignment: fa
                    };

                    fieldAssignment += templ.execute(cntx);
                }
                default: {
                    fieldAssignment += targetRowName + "." + eachColumn.name + " = " + sourceRowName + "." + eachColumn.name +"; \n";
                }
            }
        }

        return fieldAssignment;
    }

    public function printSheetClass(sheet: UncastledDbInfo_Sheet): String {
        var rowType: String = getRowName(sheet);
        var className: String = getSheetName(sheet);
        var rowMapDefinition: String = "";
        var optionalRowmapPush: String = "";

        for(column in sheet.columns) {
            if(column.type == UNIQUE_ID) {
                rowMapDefinition = "\tpublic var rowsById: Map<" + getEnumName(sheet) + ", " + rowType + "> = [];\n";
                rowMapDefinition += "public function get(id: " + getEnumName(sheet) + "): " + getRowName(sheet) + "{\n";
                rowMapDefinition += "return rowsById[id]; \n}\n\n";
                optionalRowmapPush = "rowsById[row.getUUID()] = row;";
                break;
            }
        }

        var output: String = getTemplate("SheetTemplate.txt");
        output = output.split('%ROWTYPE%').join(rowType);
        output = output.split('<CLASSNAME>').join(className);
        output = output.split('<OPTIONAL_ROWMAP_DEFINITION>').join(rowMapDefinition);
        output = output.split('<OPTIONAL_ROWMAP_PUSH>').join(optionalRowmapPush);

        return output;
    }

    public function printRowIdEnum(sheet: UncastledDbInfo_Sheet): String {
        var uniqueIdColumnName:String = getUniqueIdColumnName(sheet);
        if (uniqueIdColumnName == null){
            return "";
        }
        
        var uniqueIdArray:Array<String> = [];
        for(row in sheet.rows) {
            uniqueIdArray.push(row[uniqueIdColumnName]);
        }
    
        return 'package <PACKAGE>;\n\nenum ' + getEnumName(sheet) + ' {\n\t' + uniqueIdArray.join(';\n\t') + ';\n}';
    }

    function getUniqueIdColumnName(sheet:UncastledDbInfo_Sheet) {
        for(eachColumn in sheet.columns){
            switch (eachColumn.type){
                case UNIQUE_ID:{
                    return eachColumn.name;
                }
                default:
            }
        }
        return null;
    }

    
    public function printRowClass(sheet: UncastledDbInfo_Sheet): String {
        var rowTemplate = getTemplate("RowTemplate.txt");

        var hasUUID: Bool = false;
        var uuidField: String = "null";
        var fields = "";

        
        for(eachColumn in sheet.columns){
            var template = "public var <NAME>: <TYPE>;";
            var t = "";
            switch(eachColumn.type){
                case UNIQUE_ID:{
                    t = getEnumName(sheet);
                    hasUUID = true;
                    uuidField = eachColumn.name;
                }
                case TEXT: {
                    t = "String";
                }
                case INT: {
                    t = "Int";
                }
                case IMAGE: {
                    t = "HeapsImageHandler";
                }
                case REFERENCE(sheet): {
                    t = sheet + "_Row";
                }
                case ENUM(en, vals): {
                    t = en;
                    enumTypes.push(eachColumn.type);
                }
                case ARRAY(kind): {
                    t =  kind;
                }
            }
            template = template.replace("<NAME>", eachColumn.name);
            template = template.replace("<TYPE>", t);
            fields = fields + template + "\n";
        }
        

        rowTemplate = rowTemplate.replace("<FIELDS>", fields);
        rowTemplate = rowTemplate.replace("<CLASSNAME>", getRowName(sheet));

        if(hasUUID){
            var funcTemplate = getTemplate("getUUIDRowFunctionTemplate.txt");
            funcTemplate = funcTemplate.replace("<ENUM_NAME>", getEnumName(sheet));
            funcTemplate = funcTemplate.replace("<UUID_NAME>", uuidField);
            rowTemplate = rowTemplate.replace("<GET_UUID>", funcTemplate);
        }
        else{
            rowTemplate = rowTemplate.replace("<GET_UUID>", "");
        }

        return rowTemplate;
    }

    public function parseDbFile(dbFile: String): UncastledDbInfo {
        var dbInfo: UncastledDbInfo = new UncastledDbInfo();
        var dbContents = File.getContent(dbFile);
        var dbObject = Json.parse(dbContents);
        
        dbInfo.name = getFileNameWithoutExt(dbFile);
        for (sheetObject in (cast dbObject.sheets: Array<Dynamic>)) {
            var sheet = new UncastledDbInfo_Sheet();
            sheet.name = sheetObject.name;
            if(sheet.name != null){
                if(sheet.name.contains("@")){
                    sheet.isTransientSheet = true;
                    sheet.name = sheet.name.replace("@", "_");
                }
            }

            for (columnObject in (cast sheetObject.columns: Array<Dynamic>)) {
                var column = new UncastledDbInfo_Column();
                column.name = columnObject.name;
                column.type = matchColumnType(sheet.name, column.name, columnObject.typeStr);
                
                sheet.columns.push(column);
            }

            for (lineItem in (cast sheetObject.lines: Array<Dynamic>)) {
                var map: Map<String, String> = new Map();

                for (key in Reflect.fields(lineItem)) {
                    var value: Dynamic = Reflect.field(lineItem, key);
                    if(value is String){
                        map[key] = value;
                    }
                    else if (value is Int){
                        map[key] = Std.string(value);
                    }
                }

                sheet.rows.push(map);
            }

            dbInfo.sheets.push(sheet);
        }

        parseImgDbFile(dbFile, dbInfo);

        return dbInfo;
    }

    function parseImgDbFile(dbFile: String, info: UncastledDbInfo) {
        var filename = dbFile.replace(".cdb", ".img");
        if(FileSystem.exists(filename)){
            var dbContents = File.getContent(filename);
            var dbObject = Json.parse(dbContents);
    
            for (eachField in Reflect.fields(dbObject)) {
                var item = new UncastledDbInfo_Image();
                item.md5 = eachField;
                item.base64 = Reflect.field(dbObject, eachField);
                var splits = item.base64.split("base64,");
                splits.shift();
                item.base64 = splits.join("");
                info.images.push(item);
            }
        }
    }

    function matchColumnType(sheetName:String, columnName: String, arg:String) {
        if(arg.contains(":")){
            switch(arg.split(":")){
                case ["6", refName]: {
                    return REFERENCE(refName);
                }
                case ["5", enumVals]: {
                    return ENUM(sheetName+"_"+columnName, enumVals.split(","));
                }
                default: throw Exception;
            }
        }
        switch (arg) {
            case "0": {
                return UNIQUE_ID;
            }
            case "7": {
                return IMAGE;
            }
            case "1": {
                return TEXT;
            }
            case "3": {
                return INT;
            }
            case "8": {
                return ARRAY(sheetName + "_" + columnName);
            }
            default: throw Exception;
        }
    }
    

    function getFileNameWithoutExt(filePath:String):String 
        {
            var startIndex = filePath.lastIndexOf("\\") + 1;
            var endIndex = filePath.lastIndexOf(".");
            if (endIndex == -1) 
            { 
                endIndex = filePath.length; 
            }
            var fileName = filePath.substring(startIndex, endIndex);
            return fileName;
        }
}