package;

import uncastled.generator.UncastledGeneratorService;

class Main {
    static function main() {
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
    }
}