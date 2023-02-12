package;

import Board.Node;
import BoardSprite.MemberState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import interfaces.BoardMember;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;

enum Direction {
	UP;
	DOWN;
	LEFT;
	RIGHT;
}

class PlayState extends FlxState {
	var board:Board;
	var player:Player;
	var goal:BoardSprite;
	var nextGoal:BoardSprite;
	var enemies:FlxTypedGroup<Enemy>;
	var isPlayersTurn:Bool;
	var explosionSprites:FlxGroup;
	var aiTimer:FlxTimer;
	var numLives:Int;
	var livesIcons:Array<FlxSprite>;
	var levelNumber:Int;
	var levelText:FlxText;
	var aiTurnHasBegun:Bool;

	override public function create() {
		isPlayersTurn = true;
		aiTimer = new FlxTimer();
		FlxG.watch.add(aiTimer, "timeLeft");
		FlxG.watch.add(aiTimer, "active");
		FlxG.watch.addFunction("aiTurnHasBegun", () -> {
			return aiTurnHasBegun;
		});
		FlxG.watch.addFunction("isPlayersTurn", () -> {
			return isPlayersTurn;
		});
		FlxG.game.stage.quality = StageQuality.LOW;
		FlxG.camera.antialiasing = false;
		FlxG.game.setFilters([new ShaderFilter(new FlxShader())]);
		FlxG.fullscreen = true;
		aiTurnHasBegun = false;
		board = new Board(8, 8);
		add(board);
		player = new Player();
		addBoardMember(player);
		goal = new BoardSprite(board.rows - 1, board.rows - 1, GOAL);
		addBoardMember(goal);
		enemies = new FlxTypedGroup<Enemy>();
		nextGoal = new BoardSprite(0, board.rows - 1, GOAL);
		setNextMember(nextGoal);
		createInitalEnemies();
		explosionSprites = new FlxGroup(30);
		add(explosionSprites);
		FlxG.scaleMode = new RatioScaleMode();
		bgColor = FlxColor.BLACK;
		numLives = 5;
		livesIcons = [];
		for (i in 0...numLives) {
			var icon:FlxSprite = new FlxSprite(130 + i * 20, 16);
			icon.loadGraphic("assets/images/LivesIcon.png", false, 0, 0);
			livesIcons.push(icon);
			add(icon);
		}
		levelNumber = 0;
		levelText = new FlxText(130, 48, 0, "You have been here...\n...for 0 days");
		add(levelText);
		super.create();
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		updatePlayerMovement();
		if (!isPlayersTurn && player.state == IDLE && aiTurnHasBegun == false) {
			aiTurnHasBegun = true;
			beginAITurn();
		}
	}

	private function createInitalEnemies() {
		var enemy:Enemy = new Enemy(2, 4);
		enemies.add(enemy);
		addBoardMember(enemy);
	}

	function endLevel() {
		FlxG.switchState(new EndState(levelNumber));
	}

	private function onAITurnEnd(_:FlxTimer):Void {
		isPlayersTurn = false;
	}

	/**
		Process the movement for the AI (enemies).
	**/
	function beginAITurn() {
		if (enemies.countLiving() == 0) {
			aiTurnHasBegun = false;
			isPlayersTurn = true;
			return;
		} else {
			aiTimer.start(0.15, (_) -> {
				isPlayersTurn = true;
				aiTurnHasBegun = false;
			});
		}
		enemies.forEachAlive((enemy:Enemy) -> {
			enemy.calcNextPositionToPlayer();
		});
		// BFS from player outward, to move enemies closest to player first.
		board.clearVisited();
		board.getNodeAtCoords(player.xCoord, player.yCoord).visited = true;
		var queue:Array<Node> = [board.getNodeAtCoords(player.xCoord, player.yCoord)];
		var curr:Node = null;
		while (queue.length > 0) {
			curr = queue.shift();
			var neighbors:Array<FlxPoint> = board.neigboringCells(curr.x, curr.y);
			for (neighbor in neighbors) {
				var neighborNode:Node = board.getNodeAtCoords(Std.int(neighbor.x), Std.int(neighbor.y));
				if (!neighborNode.visited) {
					neighborNode.visited = true;
					queue.push(neighborNode);
				}
			}
			var member:BoardSprite = board.getMemberAtCoords(curr.x, curr.y);
			if (member != null && member.type == ENEMY) {
				var enemy:Enemy = cast member;
				var nextPos:FlxPoint = enemy.nextPosition;
				var occupant:BoardSprite = board.getMemberAtCoords(Std.int(nextPos.x), Std.int(nextPos.y));
				if (occupant == null) {
					moveMember(enemy, Std.int(nextPos.x), Std.int(nextPos.y));
					var bombOccupant = board.getBombAtCoords(Std.int(nextPos.x), Std.int(nextPos.y));
					if (bombOccupant != null) {
						var bombChain:Array<BoardSprite> = board.getConnectedBombs(bombOccupant);
						explodeBombs(bombChain);
					}
				} else if (occupant.type == PLAYER) {
					trace("Player was hurt by an enemy");
					removeLife();
				}
			}
		}
	}

	function updatePlayerMovement() {
		var up:Bool = false;
		var down:Bool = false;
		var left:Bool = false;
		var right:Bool = false;
		var space:Bool = false;

		up = FlxG.keys.anyJustPressed([UP, W]);
		down = FlxG.keys.anyJustPressed([DOWN, S]);
		left = FlxG.keys.anyJustPressed([LEFT, A]);
		right = FlxG.keys.anyJustPressed([RIGHT, D]);
		space = FlxG.keys.anyJustPressed([SPACE]);

		if (up || down || left || right) {
			if (up)
				movePlayer(Direction.UP);
			else if (down)
				movePlayer(Direction.DOWN);
			else if (left)
				movePlayer(Direction.LEFT);
			else
				movePlayer(Direction.RIGHT);
		} else if (space) {
			dropBomb();
		}
	}

	/**
		Moves the player by one tile in a given direction.
		Updates the player sprite and Board coordinates.
		Will not move if direction exceeds the dimensions of the Board. 
		@param dir 		the direction to move in
	**/
	function movePlayer(dir:Direction) {
		if (!isPlayersTurn)
			return;
		var newCoords:FlxPoint = FlxPoint.weak(player.xCoord, player.yCoord);
		switch (dir) {
			case Direction.UP:
				newCoords += FlxPoint.weak(0, -1);
			case Direction.DOWN:
				newCoords += FlxPoint.weak(0, 1);
			case Direction.LEFT:
				newCoords += FlxPoint.weak(-1, 0);
			case Direction.RIGHT:
				newCoords += FlxPoint.weak(1, 0);
		}
		if (newCoords.x < 0 || newCoords.x >= board.cols || newCoords.y < 0 || newCoords.y >= board.rows)
			return;
		// if (dir != player.direction) {
		// 	var nextDirCoords:FlxPoint;
		// 	switch (player.direction) {
		// 		case(UP):
		// 			nextDirCoords = FlxPoint.weak(player.xCoord, player.yCoord - 1);
		// 		case(DOWN):
		// 			nextDirCoords = FlxPoint.weak(player.xCoord, player.yCoord + 1);
		// 		case(LEFT):
		// 			nextDirCoords = FlxPoint.weak(player.xCoord - 1, player.yCoord);
		// 		case(RIGHT):
		// 			nextDirCoords = FlxPoint.weak(player.xCoord + 1, player.yCoord);
		// 	}
		// 	if (board.isCoordInBounds(Std.int(nextDirCoords.x), Std.int(nextDirCoords.y))) {
		// 		var conflictMember:BoardSprite = board.getNextMemberAtCoords(Std.int(nextDirCoords.x), Std.int(nextDirCoords.y));
		// 		if (conflictMember == null || conflictMember.type != GOAL) {
		// 			var newWall:BoardSprite = new BoardSprite(Std.int(nextDirCoords.x), Std.int(nextDirCoords.y), WALL);
		// 			board.setNextMemberAtCoords(newWall, newWall.xCoord, newWall.yCoord);
		// 		}
		// 	}
		// }
		final occupant:BoardSprite = board.getMemberAtCoords(Std.int(newCoords.x), Std.int(newCoords.y));
		if (occupant != null) {
			if (occupant.type == GOAL) {
				removeBoardMemeber(occupant);
				goToNextBoard();
				player.state = MemberState.MOVING;
				moveMember(player, Std.int(newCoords.x), Std.int(newCoords.y));
				goal = nextGoal;
				nextGoal = chooseNextGoal(goal);
				setNextMember(nextGoal);
				var conflictMember = board.getMemberAtCoords(nextGoal.xCoord, nextGoal.yCoord);
				if (conflictMember != null && conflictMember.type != PLAYER) {
					removeBoardMemeber(conflictMember);
				}
				isPlayersTurn = true;
			} else if (occupant.type == ENEMY) {
				trace("Trying to hit an enemy");
				// removeBoardMemeber(occupant);
				// var newWall:BoardSprite = new BoardSprite(occupant.xCoord, occupant.yCoord, WALL);
				// board.setNextMemberAtCoords(newWall, newWall.xCoord, newWall.yCoord);
				// moveMember(player, Std.int(newCoords.x), Std.int(newCoords.y));
				// isPlayersTurn = false;
			} else if (occupant.type == WALL) {
				removeBoardMemeber(occupant);
				var newEnemy:Enemy = new Enemy(occupant.xCoord, occupant.yCoord);
				setNextMember(newEnemy);
				// moveMember(player, Std.int(newCoords.x), Std.int(newCoords.y));
				isPlayersTurn = false;
			} else {
				player.state = MemberState.MOVING;
				moveMember(player, Std.int(newCoords.x), Std.int(newCoords.y));
				isPlayersTurn = false;
			}
		} else {
			player.state = MemberState.MOVING;
			moveMember(player, Std.int(newCoords.x), Std.int(newCoords.y));
			final bombOccupant:BoardSprite = board.getBombAtCoords(Std.int(newCoords.x), Std.int(newCoords.y));
			if (bombOccupant != null) {
				var bombChain:Array<BoardSprite> = board.getConnectedBombs(bombOccupant);
				explodeBombs(bombChain);
			}
			isPlayersTurn = false;
		}
	}

	function dropBomb() {
		if (board.getBombAtCoords(player.xCoord, player.yCoord) == null) {
			var bomb:BoardSprite = new BoardSprite(player.xCoord, player.yCoord, BOMB);
			board.setBomb(bomb);
			add(bomb);
			bomb.board = board;
			final pixelPos:FlxPoint = board.coordsToPixels(bomb.xCoord, bomb.yCoord);
			bomb.setPosition(pixelPos.x, pixelPos.y);
		} else {
			trace("There's already a bomb here...");
		}
	}

	function explodeBombs(chain:Array<BoardSprite>) {
		for (i in 0...chain.length) {
			var bomb:BoardSprite = chain[i];
			// trace("Exploding bomb at coords: (" + Std.string(bomb.xCoord) + ", " + Std.string(bomb.yCoord) + ")");
			for (j in 0...3) {
				for (k in 0...3) {
					var xI:Int = bomb.xCoord + k - 1;
					var yI:Int = bomb.yCoord + j - 1;
					if (board.isCoordInBounds(xI, yI)) {
						var occupant:BoardSprite = board.getMemberAtCoords(xI, yI);
						var explosionSprite:FlxSprite = cast explosionSprites.getFirstDead();
						if (explosionSprite == null) {
							explosionSprite = new FlxSprite();
						} else {
							explosionSprite.revive();
						}
						explosionSprite.loadGraphic("assets/images/Explosion.png", true, 16, 16);
						explosionSprite.animation.add("idle", [0, 1, 2, 3, 4, 5, 6], 10, false);
						explosionSprite.animation.play("idle");
						explosionSprite.animation.finishCallback = (_) -> {
							trace("Animation finished");
							explosionSprite.kill();
						};
						var pos = board.coordsToPixels(xI, yI);
						explosionSprite.setPosition(pos.x, pos.y);
						explosionSprites.add(explosionSprite);
						// add(explosionSprite);
						if (occupant != null) {
							if (occupant.type == ENEMY) {
								var nextOccupant:BoardSprite = board.getNextMemberAtCoords(occupant.xCoord, occupant.yCoord);
								if (nextOccupant == null) {
									var newWall = new BoardSprite(occupant.xCoord, occupant.yCoord, WALL);
									setNextMember(newWall);
								}
								removeBoardMemeber(occupant);
							} else if (occupant.type == WALL) {
								removeBoardMemeber(occupant);
							} else if (occupant.type == PLAYER) {
								trace("Player was hurt by a bomb!");
								removeLife();
							}
						}
					}
				}
			}
			remove(bomb);
			board.removeBomb(bomb);
			bomb.destroy();
		}
	}

	function removeLife() {
		if (numLives > 1) {
			numLives--;
			var icon = livesIcons.pop();
			remove(icon);
			icon.destroy();
		} else {
			endLevel();
		}
	}

	function setNextMember(member:BoardSprite) {
		board.setNextMemberAtCoords(member, member.xCoord, member.yCoord);
		var oldIndicator:FlxSprite = board.getIndicatorAtCoords(member.xCoord, member.yCoord);
		if (oldIndicator != null) {
			remove(oldIndicator);
			oldIndicator.destroy();
		}
		var worldCoords:FlxPoint = board.coordsToPixels(member.xCoord, member.yCoord);
		var indicator:FlxSprite = new FlxSprite(worldCoords.x, worldCoords.y);
		if (member.type == GOAL) {
			indicator.loadGraphic("assets/images/GoalIndicator.png", true, 16, 16);
			indicator.animation.add("idle", [0, 1, 2, 3, 4, 5, 6, 7], 10);
			indicator.animation.play("idle");
			indicator.offset.set(0, 3);
		} else if (member.type == WALL) {
			indicator.loadGraphic("assets/images/WallIndicator.png", false, 16, 16);
		} else if (member.type == ENEMY) {
			indicator.loadGraphic("assets/images/EnemyIndicator.png", true, 16, 16);
			indicator.animation.add("idle", [0, 1, 2, 3, 4, 5, 6, 7], 10);
			indicator.animation.play("idle");
			indicator.offset.set(0, 3);
		}
		board.setIndicatorAtCoords(indicator, member.xCoord, member.yCoord);
		add(indicator);
	}

	/**
		Adds a BoardSprite to this state, as well as adding it to the board.
		@param member 	the BoardMember to add
	**/
	function addBoardMember(member:BoardSprite) {
		add(member);
		member.board = board;
		board.setMemberAtCoords(member, member.xCoord, member.yCoord);
		final pixelPos:FlxPoint = board.coordsToPixels(member.xCoord, member.yCoord);
		member.setPosition(pixelPos.x, pixelPos.y);
		member.visible = true;
	}

	function removeBoardMemeber(member:BoardSprite) {
		remove(member);
		board.removeMember(member);
		member.destroy();
	}

	/**
		Moves the BoardMember to the indicated Board coordinates
		@param member 	the BoardMember to move
		@param toX		the target x-coord
		@param toY 		the target y-coord
	**/
	function moveMember(member:BoardSprite, toX:Int, toY:Int) {
		board.moveMember(member.xCoord, member.yCoord, toX, toY);
		if (member.xCoord < toX)
			member.setDirection(RIGHT);
		else if (member.xCoord > toX)
			member.setDirection(LEFT);
		else if (member.yCoord < toY)
			member.setDirection(DOWN);
		else if (member.yCoord > toY)
			member.setDirection(UP);
		member.xCoord = toX;
		member.yCoord = toY;
		final pixelPos:FlxPoint = board.coordsToPixels(member.xCoord, member.yCoord);
		// member.setPosition(pixelPos.x, pixelPos.y);
		if (member.tween != null) {
			member.tween.cancel();
		}
		member.tween = FlxTween.tween(member, {x: pixelPos.x, y: pixelPos.y}, 0.2, {
			ease: FlxEase.circOut,
			onComplete: (_) -> {
				member.state = IDLE;
			}
		});
	}

	/**
		Cycles the Board data to the next data layer.
	**/
	function goToNextBoard() {
		var enemyPositionsToPlant:Array<FlxPoint> = [];
		var wallsPositionsToPlant:Array<FlxPoint> = [];
		enemies.forEachAlive((enemy:BoardSprite) -> {
			enemyPositionsToPlant.push(FlxPoint.weak(enemy.xCoord, enemy.yCoord));
			enemy.destroy();
		});
		for (i in 0...board.rows) {
			for (j in 0...board.cols) {
				var occupant:BoardSprite = board.getMemberAtCoords(j, i);
				var indicator:FlxSprite = board.getIndicatorAtCoords(j, i);
				if (occupant != null) {
					if (occupant.type != WALL) {
						remove(occupant);
					} else {
						var newWallPosition = board.chooseNewWallPosition(occupant);
						if (newWallPosition != null) {
							wallsPositionsToPlant.push(newWallPosition);
						}
					}
				}
				if (indicator != null) {
					board.removeIndicatorAtCoords(j, i);
					remove(indicator);
					indicator.destroy();
				}
			}
		}
		board.cycleData();
		for (i in 0...board.rows) {
			for (j in 0...board.cols) {
				var occupant:BoardSprite = board.getMemberAtCoords(j, i);
				if (occupant != null) {
					moveMember(occupant, j, i);
					addBoardMember(occupant);
					if (occupant.type == ENEMY) {
						var enemy:Enemy = cast(occupant, Enemy);
						enemies.add(enemy);
					}
				}
			}
		}
		for (point in enemyPositionsToPlant) {
			var eX:Int = Std.int(point.x);
			var eY:Int = Std.int(point.y);
			var enemy:Enemy = new Enemy(eX, eY);
			setNextMember(enemy);
		}
		for (point in wallsPositionsToPlant) {
			var wX:Int = Std.int(point.x);
			var wY:Int = Std.int(point.y);
			var wall:BoardSprite = new BoardSprite(wX, wY, WALL);
			setNextMember(wall);
		}
		if (enemies.countLiving() == 0 && enemyPositionsToPlant.length == 0) {
			var nextPoint:Node = board.getRandomFreeNextCoord();
			var newEnemy:Enemy = new Enemy(nextPoint.x, nextPoint.y);
			setNextMember(newEnemy);
		}
		levelNumber++;
		levelText.text = "You have been here...\n...for " + Std.string(levelNumber) + " days";
	}

	function chooseNextGoal(currGoal:BoardSprite):BoardSprite {
		// trace("Current goal is at: (" + Std.string(currGoal.xCoord) + ", " + Std.string(currGoal.yCoord) + ")");
		var rand:Float = FlxG.random.float();
		var choices:Array<FlxPoint> = [
			FlxPoint.weak(0, 0),
			FlxPoint.weak(board.cols - 1, 0),
			FlxPoint.weak(0, board.rows - 1),
			FlxPoint.weak(board.cols - 1, board.rows - 1)
		];
		if (currGoal.xCoord == 0 && currGoal.yCoord == 0) {
			choices.splice(0, 1);
		} else if (currGoal.xCoord == 0 && currGoal.yCoord == board.rows - 1) {
			choices.splice(2, 1);
		} else if (currGoal.xCoord == board.cols - 1 && currGoal.yCoord == 0) {
			choices.splice(1, 1);
		} else {
			choices.splice(3, 1);
		}
		var choice:FlxPoint;
		if (rand > 2 / 3) {
			choice = choices[2];
		} else if (rand > 1 / 3) {
			choice = choices[1];
		} else {
			choice = choices[0];
		}
		// trace("Next goal will be at: (" + Std.string(choice.x) + ", " + Std.string(choice.y) + ")");
		return new BoardSprite(Std.int(choice.x), Std.int(choice.y), GOAL);
	}
}
