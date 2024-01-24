# Uncastled

A code generator which takes your CastleDB database and unrolls it into a class structure. This is effectively replacing the built-in CastleDB macros with a code generator.

## Justification

Out-of-the-box the CastleDB API requires you to use its macros to access your database info. This is very restrictive:

1) Macros are inherently janky and obscured -- if something isn't working then it is effectively impossible to inspect what is going on under the hood.
2) Macro access is simply unusable inside of other macros.
3) Strange and obstuse importing
4) Having macros build types according to a static files dependencies will cause a lot of headaches across multiple interdependent projects.
5) Cannot extend the functionality -- for example, the CastleDB macro API does not actually support image handling despite embedding images in rows is one of the main reasons to use CastleDB in the first place.

This approach trades automatic type building with macros for calling a code generator in your build pipeline. Benefits:

1) Type-safe data access
2) Logic is inspectable, editable and extendable
3) Effortlessly portable
4) Built in image handling

## Usage

Calling the generator:

```haxe
var service = new UncastledGeneratorService();
service.generate(<.cdb file>, <output folder>, <output base package>, <output res package (for images)>);
```

Loading the database (after generating):

```haxe
//TestDB.cdb was processed
var db = new TestDB();
db.load("TestDB.cdb");
var row: TestSheet_Row = db.MySheet.rowsById(MyRowIdentifier);
trace(row.MyColumnData);
```

Images are typed as "HeapsImageHandler" can be loaded like this:

```haxe
var row: TestSheet_Row = db.MySheet.rowsById(MyRowIdentifier);
var tile = row.MyImageData.loadTile();
```

The generator service also allows you to define "enum writers" which will generate custom enums from your static data. 

```haxe
        var service = new UncastledGeneratorService();
        service.enumWriters.push((jsob) -> {
            var fields = [];
            for(eachRow in (cast jsob.sheets.TestSheet: Array<Dynamic>)){
                for(eachExtra in (cast eachRow.ExtraData: Array<Dynamic>)){
                    var fieldName = "Seller_" + eachExtra.Seller.split(" ").join("_");
                    if(!fields.contains(fieldName)){
                        fields.push(fieldName);
                    }
                }
            }
            return Enum("Sellers", fields);
        });
        service.generate("Test.cdb", ".\\output\\", "output", ".\\output\\res\\");
```

The "jsob" applied to the callback is a dynamic JSON object representing the database data. This JSON object is enriched to simplify the data such that all enums values replaced with their enum instance names and arrays types are unrolled. For example:

```
{
  "sheets": {
    "MySheet": [
      {
        "Col1": "1",
        "EnumValue": "ENUM_NAME_1"
      },
      {
        "Col1": "2",
        "EnumValue": "ENUM_NAME_2"
      }
  }
}
```

