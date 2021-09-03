//
//  GameScene.swift
//  PenguinNinja
//
//  Created by Ahmed Mgua on 02/09/2021.
//

import AVFoundation
import GameplayKit
import SpriteKit

class GameScene: SKScene {
	let game = Game()
	var gameScore: SKLabelNode!
	var livesImages = [SKSpriteNode]()
	var activeSliceBG: SKShapeNode!
	var activeSliceFG: SKShapeNode!
	var activeSlicePoints = [CGPoint]()
	var activeEnemies = [SKSpriteNode]()
	var isSwooshSoundActive = false
	var bombSoundEffect: AVAudioPlayer?
	
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "sliceBackground")
		background.position = CGPoint(x: 512, y: 384)
		background.blendMode = .replace
		background.zPosition = -1
		addChild(background)
		
		physicsWorld.gravity = CGVector(dx: 0, dy: -6)
		physicsWorld.speed = 0.85
		
		createScoreLabel()
		createLivesLabel()
		createSlices()
		game.delegate = self
		game.makeSequence()
		DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
			self?.game.tossEnemies()
		}
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		
		activeSlicePoints.removeAll(keepingCapacity: true)
		let location = touch.location(in: self)
		activeSlicePoints.append(location)
		redrawActiveSlice()
		
		activeSliceBG.removeAllActions()
		activeSliceBG.alpha = 1
		
		activeSliceFG.removeAllActions()
		activeSliceFG.alpha = 1
		
    }
    
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		let location = touch.location(in: self)
		activeSlicePoints.append(location)
		redrawActiveSlice()
		if !isSwooshSoundActive	{
			playSwooshSound()
		}
		
		let nodesAtPoint = nodes(at: location)
		
		checkSlicedEnemies(in: nodesAtPoint)
		
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		activeSliceBG.run(SKAction.fadeOut(withDuration: 0.25))
		activeSliceFG.run(SKAction.fadeOut(withDuration: 0.25))
	}
    
    override func update(_ currentTime: TimeInterval) {
		if activeEnemies.count > 0	{
			for (index, node) in activeEnemies.enumerated().reversed()	{
				if node.position.y < -140	{
					node.removeAllActions()
					if node.name == "enemy"	{
						node.name = ""
						game.loseLife()
						node.removeFromParent()
						activeEnemies.remove(at: index)
					} else if node.name == "bombContainer"	{
						node.name = ""
						node.removeFromParent()
						activeEnemies.remove(at: index)
					}
				}
			}
		} else 	{
			if !game.nextSequenceQueued {
				DispatchQueue.main.asyncAfter(deadline: .now() + game.popupTime) { [weak game] in
					game?.tossEnemies()
				}
				game.queueNextSequence()
			}
		}
		
		
		var bombCount = 0
		for node in activeEnemies {
			if node.name == "bombContainer"	{
				bombCount += 1
				break
			}
		}
		if bombCount == 0	{
			bombSoundEffect?.stop()
			bombSoundEffect = nil
		}
    }
	
}

extension GameScene	{
	func createScoreLabel()	{
		gameScore = SKLabelNode(fontNamed: "Chalkduster")
		gameScore.horizontalAlignmentMode = .left
		gameScore.fontSize = 48
		gameScore.position = CGPoint(x: 8, y: 8)
		addChild(gameScore)
	}
	
	func createLivesLabel()	{
		for i in 0..<3	{
			let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
			spriteNode.position =	CGPoint(x: CGFloat(834 + (i * 70)), y: 720)
			addChild(spriteNode)
			livesImages.append(spriteNode)
		}
		
	}
	
	func createSlices()	{
		activeSliceBG = SKShapeNode()
		activeSliceBG.strokeColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
		activeSliceBG.lineWidth = 9
		activeSliceBG.zPosition = 2
		
		activeSliceFG = SKShapeNode()
		activeSliceFG.strokeColor = UIColor.white
		activeSliceFG.lineWidth = 5
		activeSliceFG.zPosition = 3
		
		addChild(activeSliceBG)
		addChild(activeSliceFG)
	}
	
	func redrawActiveSlice()	{
		guard activeSlicePoints.count >= 2 else {
			activeSliceBG.path = nil
			activeSliceFG.path = nil
			return
		}
		if activeSlicePoints.count > 12	{
			activeSlicePoints.removeFirst(activeSlicePoints.count - 12)
		}
		
		let path = UIBezierPath()
		path.move(to: activeSlicePoints[0])
		for i in 1	..<	activeSlicePoints.count	{
			path.addLine(to: activeSlicePoints[i])
		}
		
		activeSliceBG.path = path.cgPath
		activeSliceFG.path = path.cgPath
		
	}
	
	func playSwooshSound()	{
		isSwooshSoundActive = true
		
		let soundName = "swoosh\(Int.random(in: 1...3)).caf"
		let swooshSound = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
		
		run(swooshSound)	{	[weak self] in
			self?.isSwooshSoundActive = false
		}
	}
	
	func checkSlicedEnemies(in nodes: [SKNode])	{
		for case let node as SKSpriteNode in nodes	{
			if node.name == "enemy"	{
				handleSlice(node, emitterName: "sliceHitEnemy", soundFile: "whack.caf")
				game.increaseScore()
			}	else if node.name == "bomb"	{
				guard let bombContainer = node.parent as? SKSpriteNode else { continue }
				handleSlice(bombContainer, emitterName: "sliceHitBomb", soundFile: "explosion.caf")
				game.endGame(triggeredByBomb: true)
			}
		}
	}
	
	func handleSlice(_ node: SKSpriteNode, emitterName: String, soundFile: String)	{
		if let emitter = SKEmitterNode(fileNamed: emitterName)	{
			emitter.position = node.position
			addChild(emitter)
		}
		node.name = ""
		node.physicsBody?.isDynamic = false
		let scaleOut = SKAction.scale(to: 0.001, duration: 0.2)
		let fadeOut = SKAction.fadeOut(withDuration: 0.2)
		let group = SKAction.group([scaleOut, fadeOut])
		
		let sequence = SKAction.sequence([group, .removeFromParent()])
		node.run(sequence)
		
		if let index = activeEnemies.firstIndex(of: node)	{
			activeEnemies.remove(at: index)
		}
		
		run(SKAction.playSoundFileNamed(soundFile, waitForCompletion: false))
	}
	
}

extension GameScene: GameDelegate	{
	func didUpdateScore(_ score: Int) {
		gameScore.text = "Score: \(score)"
	}
	
	func didLoseLife(_ lives: Int) {
		run(SKAction.playSoundFileNamed("wrong", waitForCompletion: false))
		var lifeImage: SKSpriteNode
		if lives == 2	{
			lifeImage = livesImages[0]
		} else if lives == 1	{
			lifeImage = livesImages[1]
		} else {
			lifeImage = livesImages[2]
			game.endGame(triggeredByBomb: false)
		}
		lifeImage.texture = SKTexture(imageNamed: "sliceLifeGone")
		lifeImage.xScale = 1.3
		lifeImage.yScale = 1.3
		lifeImage.run(SKAction.scale(to: 1, duration: 0.1))
		
	}
	
	func didChooseEnemy(_ enemyType: Int)	{
		let enemy: SKSpriteNode
		
		if enemyType == 0 {
			enemy = SKSpriteNode()
			enemy.zPosition = 1
			enemy.name = "bombContainer"
			
			let bombImage = SKSpriteNode(imageNamed: "sliceBomb")
			bombImage.name = "bomb"
			enemy.addChild(bombImage)
			
			if bombSoundEffect != nil	{
				bombSoundEffect?.stop()
				bombSoundEffect = nil
			}
			
			if let path = Bundle.main.url(forResource: "sliceBombFuse", withExtension: "caf")	{
				if let sound = try? AVAudioPlayer(contentsOf: path)	{
					bombSoundEffect = sound
					sound.play()
				}
			}
			
			if let emitter = SKEmitterNode(fileNamed: "sliceFuse")	{
				emitter.position = CGPoint(x: 76, y: 64)
				enemy.addChild(emitter)
			}
		} else 	{
			enemy = SKSpriteNode(imageNamed: "penguin")
			run(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
			enemy.name = "enemy"
		}
		
		let position = CGPoint(x: Int.random(in: 64...960), y: -128)
		enemy.position = position
		
		let angularVelocity = CGFloat.random(in: -3...3)
		let xVelocity: Int
		
		if position .x < 256	{
			xVelocity = Int.random(in: 8...15)
		} else if position.x < 512 {
			xVelocity = Int.random(in: 3...15)
		} else if position.x < 768	{
			xVelocity = -Int.random(in: 3...15)
		} else {
			xVelocity = -Int.random(in: 8...15)
		}
		let yVelocity = Int.random(in: 24...32)
		
		enemy.physicsBody = SKPhysicsBody(circleOfRadius: 64)
		enemy.physicsBody?.velocity = CGVector(dx: xVelocity * 30, dy: yVelocity * 40)
		enemy.physicsBody?.angularVelocity = angularVelocity
		enemy.physicsBody?.collisionBitMask = 0
		
		addChild(enemy)
		activeEnemies.append(enemy)
		
	}
	
	func didEndGame(triggeredByBomb: Bool) {
		physicsWorld.speed = 0
		isUserInteractionEnabled = false
		bombSoundEffect?.stop()
		bombSoundEffect = nil
		
		if triggeredByBomb	{
			for lifeImage in livesImages	{
				lifeImage.texture = SKTexture(imageNamed: "sliceLifeGone")
			}
		}
	}
}
