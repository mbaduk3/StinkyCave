package;

import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite {
	public function new() {
		super();
		addChild(new FlxGame(240, 160, MenuState, 60, 60, true, false));
		FlxG.mouse.useSystemCursor = true;
	}
}
