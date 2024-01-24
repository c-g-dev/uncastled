$assetsPath = "./assets/"
$templateFile = "./src/uncastled/generator/Templates.hx"
$templateMap = "package uncastled.generator;

var STATIC_TEMPLATES: Map<String, String> = ["

Get-ChildItem -Path $assetsPath -File | ForEach-Object {
    $filename = $_.Name
    $content = Get-Content -Path $_.FullName -Raw
    $escapedContent = $content 
    $templateMap += "`n    '$filename' => '$escapedContent',"
}

$templateMap = $templateMap.TrimEnd(',') # Remove the trailing comma
$templateMap += "`n];"

Set-Content -Path $templateFile -Value $templateMap