import Board.Node;
import PlayState.Direction;
import flixel.math.FlxPoint;

class Enemy extends BoardSprite {
	public var nextPosition:FlxPoint;

	override public function new(xCoord:Int, yCoord:Int) {
		super(xCoord, yCoord, ENEMY);
		loadGraphic("assets/images/Enemy.png", true, 16, 16);
		setFacingFlip(LEFT, true, false);
		setFacingFlip(RIGHT, false, false);
		animation.add("idle_lr", [3, 4, 5], 5);
		animation.add("idle_up", [6, 7, 8], 5);
		animation.add("idle_down", [0, 1, 2], 5);
		animation.play("idle_down");
		offset.set(0, 4);
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

	/**
		Get the next position of the Enemy, given a target position.
	**/
	public function getNextPosition(xCoord:Int, yCoord:Int):FlxPoint {
		var xDiff:Int = xCoord - this.xCoord;
		var yDiff:Int = yCoord - this.yCoord;
		var nextPos:FlxPoint = FlxPoint.weak(this.xCoord, this.yCoord);
		if (xDiff != 0 && this.board.getMemberAtCoords(this.xCoord + sign(xDiff), this.yCoord) == null) {
			nextPos = FlxPoint.weak(this.xCoord + sign(xDiff), this.yCoord);
		} else if (yDiff != 0 && this.board.getMemberAtCoords(this.xCoord, this.yCoord + sign(yDiff)) == null) {
			nextPos = FlxPoint.weak(this.xCoord, this.yCoord + sign(yDiff));
		}
		return nextPos;
	}

	private function sign(num:Int):Int {
		if (num > 0)
			return 1;
		else if (num < 0)
			return -1;
		else
			return 0;
	}

	public function calcNextPositionToPlayer():Void {
		// trace("Looking for path to player, starting at: (" + Std.string(this.xCoord) + ", " + Std.string(this.yCoord) + ")");
		this.board.clearNodePaths();
		var output:FlxPoint = FlxPoint.weak(this.xCoord, this.yCoord);
		var queue:Array<Node> = [];
		var currNode:Node = null;
		var currPath:Array<Node> = null;
		var neighboringCoords:Array<FlxPoint> = board.neigboringCells(this.xCoord, this.yCoord);
		for (i in 0...neighboringCoords.length) {
			var coord:FlxPoint = neighboringCoords[i];
			var neighbor:Node = board.getNodeAtCoords(Std.int(coord.x), Std.int(coord.y));
			var occupant:BoardSprite = board.getMemberAtCoords(Std.int(coord.x), Std.int(coord.y));
			neighbor.parentPath = [neighbor];
			if (occupant == null || occupant.type == ENEMY) {
				queue.push(neighbor);
			} else if (occupant.type == PLAYER) {
				this.nextPosition = output;
				return;
			}
		}
		while (queue.length > 0) {
			currNode = queue.shift();
			// trace("Looking at node (" + Std.string(currNode.x) + ", " + Std.string(currNode.y) + ")");
			currPath = currNode.parentPath;
			var neighbors:Array<FlxPoint> = board.neigboringCells(Std.int(currNode.x), Std.int(currNode.y));
			for (i in 0...neighbors.length) {
				var point:FlxPoint = neighbors[i];
				if (board.isCoordInBounds(Std.int(point.x), Std.int(point.y))) {
					var occupant:BoardSprite = board.getMemberAtCoords(Std.int(point.x), Std.int(point.y));
					if (occupant == null || occupant.type == ENEMY) {
						var nextNode:Node = board.getNodeAtCoords(Std.int(point.x), Std.int(point.y));
						if (nextNode.parentPath == null) {
							nextNode.parentPath = currPath;
							queue.push(nextNode);
						}
					} else if (occupant.type == PLAYER) {
						// var targetNode:Node = currPath.length > 1 ? currPath[1] : currPath[0];
						var targetNode:Node = currPath[0];
						// trace("Found a path, starting with (" + Std.string(targetNode.x) + ", " + Std.string(targetNode.y) + ")");
						this.nextPosition = FlxPoint.weak(targetNode.x, targetNode.y);
						return;
					}
				}
			}
		}
		// trace("Could not find a path");
		this.nextPosition = output;
	}
}
