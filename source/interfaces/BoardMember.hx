package interfaces;

import flixel.util.FlxColor;

enum MemberType {
	PLAYER;
	GOAL;
	ENEMY;
	WALL;
	BOMB;
}

final memberColorMap:Map<MemberType, FlxColor> = [
	PLAYER => FlxColor.RED,
	GOAL => FlxColor.LIME,
	ENEMY => FlxColor.BLUE,
	WALL => FlxColor.GRAY,
	BOMB => FlxColor.ORANGE,
];

interface BoardMember {
	public var xCoord:Int;
	public var yCoord:Int;
	public var board:Board;
	public var type:MemberType;
}
