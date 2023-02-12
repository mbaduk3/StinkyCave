package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import interfaces.BoardMember;

var tileSize:Int = 14;
var separationPixels:Int = 2;
var topBuffer:Int = 16;

class Board extends FlxTypedSpriteGroup<FlxSprite> {
	public var data:Array<Array<BoardSprite>>;
	public var nextData:Array<Array<BoardSprite>>;
	public var nodeArr:Array<Array<Node>>;
	public var spriteArray:Array<Array<FlxSprite>>;
	public var indicatorArray:Array<Array<FlxSprite>>;
	public var bombArray:Array<Array<BoardSprite>>;
	public var rows:Int;
	public var cols:Int;

	public function new(rows:Int, cols:Int) {
		super();
		this.rows = rows;
		this.cols = cols;
		data = [];
		nextData = [];
		nodeArr = [];
		spriteArray = [];
		bombArray = [];
		indicatorArray = [];
		for (i in 0...rows) {
			final row:Array<BoardSprite> = [];
			final nextRow:Array<BoardSprite> = [];
			final nodeRow:Array<Node> = [];
			final bombRow:Array<BoardSprite> = [];
			for (j in 0...cols) {
				row.push(null);
				nextRow.push(null);
				nodeRow.push(new Node(j, i));
				bombRow.push(null);
			}
			data.push(row);
			nextData.push(nextRow);
			nodeArr.push(nodeRow);
			bombArray.push(bombRow);
		}
		refreshBoardDisplay();
		// for (i in 0...data.length) {
		// 	final row:Array<BoardSprite> = data[i];
		// 	for (j in 0...row.length) {
		// 		if (nextData[i][j] != null) {
		// 			drawIndicator(spriteArray[i][j], nextData[i][j].type);
		// 		}
		// 	}
		// }
	}

	public function refreshBoardDisplay() {
		clear();
		var offset:Int = tileSize + separationPixels;
		for (i in 0...data.length) {
			final row:Array<BoardSprite> = data[i];
			final spriteRow:Array<FlxSprite> = [];
			final indicatorRow:Array<FlxSprite> = [];
			for (j in 0...row.length) {
				var square:FlxSprite = new FlxSprite(j * offset, i * offset + topBuffer);
				// square.offset = FlxPoint.weak(tileSize / 2.0, tileSize / 2.0);
				// square.makeGraphic(tileSize, tileSize, FlxColor.BROWN, true);
				square.loadGraphic("assets/images/Tile.png", true, 16, 16);
				square.animation.add("idle", [0, 1, 2], 5);
				square.animation.play("idle");
				add(square);
				spriteRow.push(square);
				indicatorRow.push(null);
			}
			spriteArray.push(spriteRow);
			indicatorArray.push(indicatorRow);
		}
	}

	// public function drawIndicator(square:FlxSprite, type:MemberType) {
	// 	FlxSpriteUtil.drawRect(square, 0, 0, square.width / 5, square.height / 5, memberColorMap[type]);
	// }

	public function getIndicatorAtCoords(x:Int, y:Int):FlxSprite {
		return indicatorArray[y][x];
	}

	public function setIndicatorAtCoords(indicator:FlxSprite, x:Int, y:Int) {
		indicatorArray[y][x] = indicator;
	}

	public function removeIndicatorAtCoords(x:Int, y:Int) {
		indicatorArray[y][x] = null;
	}

	/**
		Returns centered pixel coordinates of a gived board coordinate.
		@param x 	the x-coord (board)
		@param y 	the y-coord (board)
		@return  	the center pixel-coords of that board member
	**/
	public function coordsToPixels(x:Int, y:Int):FlxPoint {
		var offset:Int = tileSize + separationPixels;
		var xWrapped:Int = (x + rows) % rows;
		var yWrapped:Int = (y + cols) % cols;
		// return FlxPoint.get(xWrapped * offset + (tileSize / 2), yWrapped * offset + (tileSize / 2));
		return FlxPoint.get(xWrapped * offset, yWrapped * offset + topBuffer);
	}

	/**
		Returns the member on the board at the given coordinates.
		@param x 	the x-coord (board)
		@param y 	the y-coord (board)
		@return  	the board member at the given coordinates 
	**/
	public function getMemberAtCoords(x:Int, y:Int):Null<BoardSprite> {
		return data[y][x];
	}

	/**
		Sets the member on the board at the given coordinates.
		@param member 	board member at the given coordinates 
		@param x 		the x-coord (board)
		@param y 		the y-coord (board)

	**/
	public function setMemberAtCoords(member:BoardSprite, x:Int, y:Int) {
		data[y][x] = member;
	}

	public function removeMember(member:BoardSprite) {
		data[member.yCoord][member.xCoord] = null;
	}

	/**
		Moves the member at the given coordinates to the new coordinates
		@param xFrom 	the original x-coord
		@param yFrom 	the original y-coord
		@param xTo 		the new x-coord
		@param yTo 		the new y-coord
	**/
	public function moveMember(xFrom:Int, yFrom:Int, xTo:Int, yTo:Int) {
		if (xFrom < 0 || xFrom >= cols)
			// throw new Exception('xFrom is out of bounds!');
			return;
		if (yFrom < 0 || xFrom >= rows)
			// throw new Exception('yFrom is out of bounds!');
			return;
		if (xTo < 0 || xTo >= cols)
			// throw new Exception('xTo is out of bounds!');
			return;
		if (yTo < 0 || yTo >= rows)
			// throw new Exception('yTo is out of bounds!');
			return;
		final member:BoardSprite = data[yFrom][xFrom];
		data[yFrom][xFrom] = null;
		data[yTo][xTo] = member;
	}

	/**
		Returns the next member on the board at the given coordinates.
		@param x 	the x-coord (board)
		@param y 	the y-coord (board)
		@return  	the next board member at the given coordinates 
	**/
	public function getNextMemberAtCoords(x:Int, y:Int):BoardSprite {
		return nextData[y][x];
	}

	public function getNodeAtCoords(x:Int, y:Int):Node {
		return nodeArr[y][x];
	}

	public function getBombAtCoords(x:Int, y:Int):BoardSprite {
		return bombArray[y][x];
	}

	public function setBomb(bomb:BoardSprite) {
		bombArray[bomb.yCoord][bomb.xCoord] = bomb;
	}

	public function removeBomb(bomb:BoardSprite) {
		bombArray[bomb.yCoord][bomb.xCoord] = null;
	}

	/**
		Sets the next member on the board at the given coordinates.
		@param member 	the BoardMember
		@param x 		the x-coord (board)
		@param y 		the y-coord (board)
		@return  		the next board member at the given coordinates 
	**/
	public function setNextMemberAtCoords(member:BoardSprite, x:Int, y:Int):Void {
		nextData[y][x] = member;
		// drawIndicator(spriteArray[y][x], member.type);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	/**
		Replaces the current Board data with the next data.
	**/
	public function cycleData() {
		for (i in 0...rows) {
			for (j in 0...cols) {
				var occupant:BoardSprite = data[i][j];
				if (occupant == null || (occupant.type != PLAYER && occupant.type != WALL)) {
					data[i][j] = nextData[i][j];
					nextData[i][j] = null;
					// spriteArray[i][j].makeGraphic(tileSize, tileSize, FlxColor.BROWN, true);
					// spriteArray[i][j].loadGraphic("assets/images/Tile.png", true, 16, 16);
					// square.animation.add("idle", [0, 1, 2], 5);
					// square.animation.play("idle");
				}
			}
		}
	}

	public function isCoordInBounds(x:Int, y:Int):Bool {
		if (x < 0 || x >= cols)
			return false;
		if (y < 0 || y >= rows)
			return false;
		return true;
	}

	/**
		Given a coordinate, returns all valid neighboring cells
		@param x 	the target x-coord
		@param y 	the target y-coord
		@return 	an array of neighboring coords
	**/
	public function neigboringCells(x:Int, y:Int):Array<FlxPoint> {
		final output:Array<FlxPoint> = [];
		if (x != 0)
			output.push(FlxPoint.weak(x - 1, y));
		if (x != cols - 1)
			output.push(FlxPoint.weak(x + 1, y));
		if (y != 0)
			output.push(FlxPoint.weak(x, y - 1));
		if (y != rows - 1)
			output.push(FlxPoint.weak(x, y + 1));
		return output;
	}

	public function clearNodePaths() {
		for (i in 0...nodeArr.length) {
			var row:Array<Node> = nodeArr[i];
			for (j in 0...row.length) {
				row[j].clearParent();
			}
		}
	}

	public function clearVisited() {
		for (i in 0...nodeArr.length) {
			var row:Array<Node> = nodeArr[i];
			for (j in 0...row.length) {
				row[j].clearVisited();
			}
		}
	}

	public function chooseNewWallPosition(member:BoardSprite):FlxPoint {
		if (member.type != WALL)
			return null;
		var freePositions:Array<FlxPoint> = [];
		var wallNeighborPositions:Array<FlxPoint> = [];
		var neighborPositions:Array<FlxPoint> = neigboringCells(member.xCoord, member.yCoord);
		for (neighbor in neighborPositions) {
			var occupant = getMemberAtCoords(Std.int(neighbor.x), Std.int(neighbor.y));
			var nextOccupant = getNextMemberAtCoords(Std.int(neighbor.x), Std.int(neighbor.y));
			if (occupant != null && occupant.type == WALL) {
				wallNeighborPositions.push(neighbor);
			} else if (occupant == null && nextOccupant == null) {
				var occupantNeighborPositions:Array<FlxPoint> = neigboringCells(Std.int(neighbor.x), Std.int(neighbor.y));
				var numOccNeighborWalls = 0;
				for (occNeighbor in occupantNeighborPositions) {
					var occNeighborMember:BoardSprite = getMemberAtCoords(Std.int(occNeighbor.x), Std.int(occNeighbor.y));
					if (occNeighborMember != null && occNeighborMember.type == WALL) {
						numOccNeighborWalls += 1;
					}
				}
				if (numOccNeighborWalls < 2) {
					freePositions.push(neighbor);
				}
			}
		}
		if (wallNeighborPositions.length < 2 && freePositions.length > 0) {
			return freePositions[FlxG.random.int(0, freePositions.length - 1)];
		}
		return null;
	}

	public function getConnectedBombs(bomb:BoardSprite):Array<BoardSprite> {
		clearVisited();
		var output:Array<BoardSprite> = [];
		var initalNode:Node = getNodeAtCoords(bomb.xCoord, bomb.yCoord);
		initalNode.visited = true;
		var queue:Array<Node> = [initalNode];
		var curr:Node;
		if (bomb == null || bomb.type != BOMB)
			return output;
		while (queue.length > 0) {
			curr = queue.shift();
			output.push(getBombAtCoords(curr.x, curr.y));
			for (i in 0...3) {
				for (j in 0...3) {
					var xI:Int = bomb.xCoord - 1 + j;
					var yI:Int = bomb.yCoord - 1 + i;
					if (isCoordInBounds(xI, yI)) {
						var sisterBomb:BoardSprite = getBombAtCoords(xI, yI);
						var sisterNode:Node = getNodeAtCoords(xI, yI);
						if (!sisterNode.visited && sisterBomb != null) {
							sisterNode.visited = true;
							queue.push(sisterNode);
						}
					}
				}
			}
		}
		return output;
	}

	public function getRandomFreeNextCoord():Node {
		var output:Node = null;
		var options:Array<Node> = [];
		for (i in 0...rows) {
			for (j in 0...cols) {
				var occupant:BoardSprite = getMemberAtCoords(j, i);
				var nextOccupant:BoardSprite = getNextMemberAtCoords(j, i);
				var bombOccupant:BoardSprite = getBombAtCoords(j, i);
				if (occupant == null && nextOccupant == null && bombOccupant == null) {
					options.push(getNodeAtCoords(j, i));
				}
			}
		}
		if (options.length > 0) {
			output = options[FlxG.random.int(0, options.length - 1)];
		}
		return output;
	}
}

class Node {
	public var x:Int;
	public var y:Int;
	public var parentPath:Array<Node>;
	public var visited:Bool;

	public function new(x:Int, y:Int) {
		this.x = x;
		this.y = y;
		visited = false;
	}

	public function clearParent() {
		this.parentPath = null;
	}

	public function clearVisited() {
		this.visited = false;
	}
}
