//
//  Game.swift
//  PenguinNinja
//
//  Created by Ahmed Mgua on 02/09/2021.
//

import Foundation
protocol GameDelegate	{
	func didUpdateScore(_ score: Int)
	func didLoseLife(_ lives: Int)
	func didChooseEnemy(_ enemyType: Int)
	func didEndGame(triggeredByBomb: Bool)
}
class Game	{
	var delegate: GameDelegate?
	private var score = 0	{
		didSet	{
			delegate?.didUpdateScore(score)
		}
	}
	private(set) var isGameEnded = false
	private var lives = 3
	private(set) var popupTime = 0.9
	private var sequence = [SequenceType]()
	private var sequencePosition = 0
	private var chainDelay = 3.0
	private(set) var nextSequenceQueued = true
	
	
	func increaseScore()	{
		score += 1
	}
	func endGame(triggeredByBomb: Bool)	{
		if isGameEnded	{
			return
		}
		
		isGameEnded = true
		delegate?.didEndGame(triggeredByBomb: triggeredByBomb)
	}
	func loseLife()	{
		lives -= 1
		delegate?.didLoseLife(lives)
	}
	func chooseEnemyType(forceBomb: ForceBomb = .random)	{
		delegate?.didChooseEnemy(forceBomb.enemyType)
		
	}
	func makeSequence()	{
		sequence = [.oneNoBomb, .oneNoBomb, .twoWithOneBomb, .twoWithOneBomb, .three, .one, .chain]
		for _ in 0...1000	{
			if let nextSequence = SequenceType.allCases.randomElement()	{
				sequence.append(nextSequence)
			}
		}
	}
	
	func queueNextSequence()	{
		nextSequenceQueued = true
	}
	
	func tossEnemies()	{
		if isGameEnded	{
			return
		}
		popupTime *= 0.991
		chainDelay *= 0.99
		
		let sequenceType = sequence[sequencePosition]
		
		switch sequenceType	{
		case .one, .two, .three, .four:
			chooseEnemyType()
		case .oneNoBomb:
			chooseEnemyType(forceBomb: .never)
		case .twoWithOneBomb:
			chooseEnemyType(forceBomb: .never)
			chooseEnemyType(forceBomb: .always)
		case .chain:
			chooseEnemyType()
			for i in 1...4	{
				DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5 * Double(i))) { [weak self] in
					self?.chooseEnemyType()
				}
			}
		case .fastChain:
			chooseEnemyType()
			for i in 1...4	{
				DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10 * Double(i))) { [weak self] in
					self?.chooseEnemyType()
				}
			}
		}
		
		sequencePosition += 1
		nextSequenceQueued = false
	}
}


extension Game	{
	enum ForceBomb: Int	{
		case never,
			 always,
			 random
		
		var enemyType: Int	{
			switch self {
			case .always:
				return 0
			case .never:
				return 1
			case .random:
				return Int.random(in: 0...6)
			}
		}
	}
	
	enum SequenceType: CaseIterable	{
		case one,
			 two,
			 three,
			 four,
			 oneNoBomb,
			 twoWithOneBomb,
			 chain,
			 fastChain
	}
	
}
