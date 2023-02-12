package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;

class EndState extends FlxState {
	var daysSurvived:Int;
	var retryButton:FlxButton;
	var endText:FlxText;

	override public function new(x:Int) {
		this.daysSurvived = x;
		super();
	}

	override public function create():Void {
		retryButton = new FlxButton(0, 0, "Try Again", clickPlay);
		retryButton.screenCenter();
		add(retryButton);
		endText = new FlxText("You survived for " + Std.string(daysSurvived) + " days");
		endText.screenCenter();
		endText.y -= 40;
		add(endText);
		super.create();
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}

	function clickPlay():Void {
		FlxG.switchState(new PlayState());
	}
}
