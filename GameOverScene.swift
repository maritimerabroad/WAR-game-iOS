//
//  GameOverScene.swift
//  Oldxcodefirstgame
//
//  Created by Colton Booth on 2017-06-10.
//  Copyright © 2017 Colton Booth. All rights reserved.
//


import Foundation
import SpriteKit

class GameOverScene: SKScene {
    
    //var background = SKSpriteNode(imageNamed: "background")
    
    init(size: CGSize, won:Bool) {
        
        super.init(size: size)
        
        if won {
            let background = SKSpriteNode(imageNamed: "won")
            background.zPosition = 0
            background.position = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
            addChild(background)
        } else {
            let background = SKSpriteNode(imageNamed: "lost")
            background.zPosition = 0
            background.position = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
            addChild(background)
            
        }
        run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.run() {
                // 5
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                let scene = GameScene(size: size)
                self.view?.presentScene(scene, transition:reveal)
            }
            ]))
    }    
    // 6
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
