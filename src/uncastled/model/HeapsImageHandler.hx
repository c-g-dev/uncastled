package uncastled.model;

import h2d.Tile;
import hxd.res.Image;
import haxe.Exception;

class HeapsImageHandler {
	public var md5Hash:String;
	public var assetPath:String;

	public function new(md5Hash:String, assetPath:String) {
		this.md5Hash = md5Hash;
		this.assetPath = assetPath;
	}

	public function loadTile(): Tile {
		var loaded = hxd.Res.loader.load(assetPath + "/" + md5Hash + ".jpg");
		return loaded.toTile();
	}
}
