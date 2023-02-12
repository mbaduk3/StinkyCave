package;

import PlayState.Direction;

class Player extends BoardSprite {
	override public function new(xCoord:Int = 0, yCoord:Int = 0, pixelWidth:Int = 20, pixelHeight:Int = 20) {
		super(xCoord, yCoord, PLAYER);
		loadGraphic("assets/images/Player.png", true, 16, 16);
		setFacingFlip(LEFT, true, false);
		setFacingFlip(RIGHT, false, false);
		animation.add("idle_lr", [3, 4, 5], 5);
		animation.add("idle_up", [6, 7, 8], 5);
		animation.add("idle_down", [0, 1, 2], 5);
		animation.play("idle_down");
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	override function setDirection(dir:Direction) {
		super.setDirection(dir);
		switch (dir) {
			case UP:
				facing = UP;
				animation.play("idle_up");
			case DOWN:
				facing = DOWN;
				animation.play("idle_down");
			case LEFT:
				facing = LEFT;
				animation.play("idle_lr");
			case RIGHT:
				facing = RIGHT;
				animation.play("idle_lr");
		}
	}
}
