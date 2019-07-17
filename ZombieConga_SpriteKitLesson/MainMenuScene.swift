//
//  MainMenuScene.swift
//  ZombieConga_SpriteKitLesson
//
//  Created by Doug Wagner on 7/15/19.
//  Copyright © 2019 Doug Wagner. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenuScene: SKScene {
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "MainMenu.png")
        
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        self.addChild(background)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        sceneTapped()
    }
    
    func sceneTapped() {
        let scene = GameScene(size: self.size)
        scene.scaleMode = self.scaleMode
        let reveal = SKTransition.doorway(withDuration: 1.5)
        self.view?.presentScene(scene, transition: reveal)
    }
}
