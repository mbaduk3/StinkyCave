/**
	Represents an FlxSprite which can be used as a member on the Board.
**/

import PlayState.Direction;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import interfaces.BoardMember;

enum MemberState {
	IDLE;
	MOVING;
}

class BoardSprite extends FlxSprite implements BoardMember {
	public var xCoord:Int;
	public var yCoord:Int;
	public var type:MemberType;
	public var board:Board;
	public var direction:Direction;
	public var tween:FlxTween;
	public var state:MemberState;

	public function new(xCoord:Int, yCoord:Int, type:MemberType) {
		super();
		this.xCoord = xCoord;
		this.yCoord = yCoord;
		this.type = type;
		this.state = IDLE;
		setDirection(Direction.DOWN);
		this.tween = null;
		if (type == GOAL) {
			loadGraphic("assets/images/Goal.png", true, 16, 16);
			animation.add("idle", [0, 1, 2, 3, 4, 5, 6, 7, 8], 5);
			animation.play("idle");
			offset.set(0, 7);
		} else if (type == WALL) {
			loadGraphic("assets/images/Wall.png", true, 16, 16);
			animation.add("idle", [0, 1, 2], 5);
			animation.play("idle");
			offset.set(0, 2);
		} else if (type == BOMB) {
			loadGraphic("assets/images/Bomb.png", true, 16, 16);
			animation.add("idle", [0, 1, 2], 5);
			animation.play("idle");
			offset.set(0, 2);
		}
		// makeGraphic(Board.tileSize, Board.tileSize, memberColorMap[type]);
		// FlxSpriteUtil.drawRect(this, this.width / 2 - 3, this.height - 6, 6, 6, FlxColor.BLACK);
	}

	public function setDirection(dir:Direction) {
		this.direction = dir;
		// var newAngle:Int = 0;
		// switch (dir) {
		// 	case DOWN:
		// 		newAngle = 0;
		// 	case UP:
		// 		newAngle = 180;
		// 	case LEFT:
		// 		newAngle = 90;
		// 	case RIGHT:
		// 		newAngle = 270;
		// }
		// this.angle = newAngle;
	}
}
