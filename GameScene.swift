//
//  GameScene.swift
//  Oldxcodefirstgame
//
//  Created by Colton Booth on 2017-06-10.
//  Copyright © 2017 Colton Booth. All rights reserved.
//


struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Monster   : UInt32 = 0b1       // 1
    static let Projectile: UInt32 = 0b10      // 2
}

import SpriteKit

//Operator Overloading
//////////////////////
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}
/////////////////////////////////////
/////////////////////////////////////

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    
    var scoreLabel: SKLabelNode!
    
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var background = SKSpriteNode(imageNamed: "background")
    
    // Declare private constant for player. Pass name of image to use to create sprite
    let player = SKSpriteNode(imageNamed: "whitehouse")
    
    
    //move function
    override func didMove(to view: SKView) {
        

        physicsWorld.gravity = CGVector(dx:0, dy: 0)
        physicsWorld.contactDelegate = self
        
        let gravityVector = vector_float3(0,-1,0)
        
        let gravityNode = SKFieldNode.linearGravityField(withVector: gravityVector)
        
        gravityNode.strength = 25
        
        gravityNode.zPosition = 0
        
        addChild(gravityNode)
        
        
        
        //physicsWorld.gravity = CGVector(dx:1.0, dy: 9.8)
        //physicsWorld.contactDelegate = self
        
        // position sprite 10% vertically and centered horizontally
        player.position = CGPoint(x: size.width * 0.2, y: size.height * 0.2)
        // add sprite as child of scene to make sprite appear
        player.zPosition = 1
        addChild(player)
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addMonster),
                SKAction.wait(forDuration: 1.0)
                ])
        ))
        
        
        let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
        
        background.zPosition = 0
        background.position = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        addChild(background)
        
        scoreLabel = SKLabelNode(fontNamed: "Verdana")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: size.width * 0.90, y: size.height * 0.05)
        scoreLabel.zPosition = 1
        scoreLabel.fontColor = SKColor.black
        addChild(scoreLabel)
        
        
        
    }
    
    
    //random generator function. determine where to create, and set the position
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    
    //Add monster functionality
    func addMonster() {
        
        // Create sprite
        let monster = SKSpriteNode(imageNamed: "isisnuke")
        
        // Determine where to spawn the monster along the Y axis
        let actualY = random(min: size.height * 0.4, max: size.height - monster.size.height/2)
        
        // Position the monster slightly off-screen along the right edge,
        // and along a random position along the Y axis as calculated above
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
        
        // Add the monster to the scene
        monster.zPosition = 1
        addChild(monster)
        
        // Determine speed of the monster
        let actualDuration = random(min: CGFloat(1.0), max: CGFloat(3.0))
        
        
        // -monster.size.width/2, y: actualY
        // Create the actions
        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        monster.run(SKAction.sequence([actionMove, actionMoveDone]))
        
        
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size) // 1
        monster.physicsBody?.isDynamic = true // 2
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster // 3
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile // 4
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
        
        let loseAction = SKAction.run() {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
        
        
        
    }

    
    //Touches functionality
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // 1 - Choose one of the touches to work with
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        
        // 2 - Set up initial location of projectile
        let projectile = SKSpriteNode(imageNamed: "fireball")
        projectile.position = player.position
        
        // 3 - Determine offset of location to projectile
        let offset = touchLocation - projectile.position
        
        // 4 - Bail out if you are shooting down or backwards
        //if (offset.x < 0) { return }
        
        // 5 - OK to add now - you've double checked position
        projectile.zPosition = 1
        addChild(projectile)
        
        // 6 - Get the direction of where to shoot
        let direction = offset.normalized()
        
        // 7 - Make it shoot far enough to be guaranteed off screen
        let shootAmount = direction * 1000
        
        // 8 - Add the shoot amount to the current position
        let realDest = shootAmount + projectile.position
        
        // 9 - Create the actions
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        
        
        run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
        
        
    }
    
    
    func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
        run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
        print("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
        score += 1
        if (score > 30) {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
            }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // 2
        if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
            if let monster = firstBody.node as? SKSpriteNode, let
                projectile = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithMonster(projectile: projectile, monster: monster)
            }
        }
        
    }
    
    
        
    }
    
    
    
    
