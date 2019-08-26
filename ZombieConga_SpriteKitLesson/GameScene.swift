//
//  GameScene.swift
//  ZombieConga_SpriteKitLesson
//
//  Created by Doug Wagner on 6/26/19.
//  Copyright © 2019 Doug Wagner. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    let playableRect: CGRect
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    let trainMovePointsPerSec: CGFloat = 480.0
    let zombieRotateRadiansPerSec = π * 4.0
    var velocity = CGPoint.zero
    var touchStoppingPoint: CGPoint?
    let zombieAnimation: SKAction
    let catCollisionSound = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
    var zombieInvincibleDueToHit = false
    let cameraNode = SKCameraNode()
    let cameraMovePointsPerSec: CGFloat = 200.0
    let livesLabel = SKLabelNode(fontNamed: "Glimstick")
    let catLabel = SKLabelNode(fontNamed: "Glimstick")
    
    var cameraRect: CGRect {
        let x = cameraNode.position.x - size.width/2 + (size.width - playableRect.width)/2
        let y = cameraNode.position.y - size.height/2 + (size.height - playableRect.height)/2
        return CGRect(x: x, y: y, width: playableRect.width, height: playableRect.height)
    }
    
    var lives = 5
    var gameOver = false
    
    override init(size: CGSize) {
        let maxAspectRatio : CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight) / 2.0
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
        
        var textures:[SKTexture] = []
        
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        
        textures.append(textures[2])
        textures.append(textures[1])
        
        zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        
        super.init(size: size)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented.")
    }
    
    override func update(_ currentTime: TimeInterval) {
        zombie.zPosition = 100
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
//        print("\(dt*1000) milliseconds since last update.")
        
        //        This is a very simple way of implementing movement, but it can lead to jittery and choppy movements
        //        zombie.position = CGPoint(x: zombie.position.x + 8, y: zombie.position.y)
        
        //        move(sprite: zombie, velocity: CGPoint(x: zombieMovePointsPerSec, y: 0))  // gives a constant, hard coded velocity
        
//        if let stoppingPoint = touchStoppingPoint {
//            let stopDistance = stoppingPoint - zombie.position
//
//            if stopDistance.length() <= zombieMovePointsPerSec * CGFloat(dt) {
//                velocity = CGPoint.zero
//                stopZombieAnimation()
//                zombie.position = stoppingPoint
//            } else {
                rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
                move(sprite: zombie, velocity: velocity)
//            }
//        }
        
        checkBounds()
//        checkCollisions()  //moved to didEvaluateActions because this causes renders to be one frame behind
        moveTrain()
        moveCamera()
        
        if lives <= 0 && !gameOver {
            gameOver = true
            print("You Lose!")
            backgroundMusicPlayer.stop()
            
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode(rect: playableRect)
        shape.strokeColor = .red
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        
//        let background = SKSpriteNode(imageNamed: "background1")
//        background.position = CGPoint(x: size.width/2,
//                                      y: size.height/2)
//        background.zPosition = -1
//        anchorPoint is where the anchor is placed on the image, in this case it's 0,0.
//        Typically it'll be 0.5,0.5 which is the center of the image.
//        background.anchorPoint = CGPoint.zero
//        background.position = CGPoint.zero
//        background.zRotation = CGFloat.pi / 8                // 22.5 degrees
        for i in 0...1 {
            let background = backgroundNode()
            background.position = CGPoint.zero
            background.position = CGPoint(x: CGFloat(i) * background.size.width, y: 0)
            background.zPosition = -1
            addChild(background)
        }
        
        zombie.position = CGPoint(x: 400, y: 400)
//        zombie.alpha = 0.05        // Stealth Zombie
//        zombie.setScale(2)         // Giant Zombie
        zombie.zPosition = 100
        addChild(zombie)
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run()
                { [weak self] in
                    self?.spawnEnemy()
                },
                SKAction.wait(forDuration: 2.0)])))
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() { [weak self] in
                self?.spawnCat()
                },
                SKAction.wait(forDuration: 1.0)])))
        
//        debugDrawPlayableArea()
        playBackgroundMusic(filename: "backgroundMusic.mp3")
        
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
        
        livesLabel.text = "Lives: \(lives)"
        livesLabel.fontColor = .black
        livesLabel.fontSize = 100
        livesLabel.zPosition = 150
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.verticalAlignmentMode = .bottom
        livesLabel.position = CGPoint(x: -playableRect.size.width/2 + CGFloat(20),
                                      y: -playableRect.size.height/2 + CGFloat(20))
        cameraNode.addChild(livesLabel)
        
        catLabel.text = "Cats: 0"
        catLabel.fontColor = .black
        catLabel.fontSize = 100
        catLabel.zPosition = 150
        catLabel.horizontalAlignmentMode = .right
        catLabel.verticalAlignmentMode = .bottom
//        catLabel.position = CGPoint.zero
        catLabel.position = CGPoint(x: playableRect.size.width/2 - CGFloat(20),
                                    y: -playableRect.size.height/2 + CGFloat(20))
        cameraNode.addChild(catLabel)
    }
    
    func backgroundNode() -> SKSpriteNode {
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.name = "background"
        
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPoint.zero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPoint.zero
        background2.position = CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        
        backgroundNode.size = CGSize(width: background1.size.width + background2.size.width,
                                     height: background1.size.height)
        return backgroundNode
    }
    
    func moveCamera () {
        let backgroundVelocity = CGPoint(x: cameraMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        cameraNode.position += amountToMove
        
        enumerateChildNodes(withName: "background") { node, _ in
            let background = node as! SKSpriteNode
            if background.position.x + background.size.width < self.cameraRect.origin.x {
                background.position = CGPoint(x: background.position.x + background.size.width*2,
                                              y: background.position.y)
            }
        }
    }
    
    func move(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt)
//        print("Amount to move: \(amountToMove)")
        sprite.position += amountToMove
        
    }
    
    func moveZombieToward(location: CGPoint) {
        startZombieAnimation()
        let offset = location - zombie.position
        let direction = offset.normalized()
        velocity = direction * CGFloat(zombieMovePointsPerSec)
    }
    
    func sceneTouched(touchLocation: CGPoint) {
        moveZombieToward(location: touchLocation)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        touchStoppingPoint = touchLocation
        sceneTouched(touchLocation: touchLocation)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        touchStoppingPoint = touchLocation
        sceneTouched(touchLocation: touchLocation)
    }
    
    func checkBounds() {
        let bottomLeft = CGPoint(x: cameraRect.minX, y: cameraRect.minY)
        let topRight = CGPoint(x: cameraRect.maxX, y: cameraRect.maxY)
        
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = abs(velocity.x)
        }
        
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    func checkToStop() {
        guard let stoppingPoint = touchStoppingPoint else {
            return
        }
        
        let stopDistance = stoppingPoint - zombie.position
        
        if stopDistance.length() <= zombieMovePointsPerSec * CGFloat(dt) {
            velocity = CGPoint.zero
            zombie.position = stoppingPoint
        }
    }
    
    func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: direction.angle)
        let amountToRotate = rotateRadiansPerSec * CGFloat(dt)
        if abs(shortest) < amountToRotate {
            sprite.zRotation += shortest
        } else {
            sprite.zRotation += amountToRotate * shortest.sign()
        }
    }
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        enemy.position = CGPoint(x: cameraRect.maxX + enemy.size.width/2,
                                 y: CGFloat.random(min: cameraRect.minY + enemy.size.height/2,
                                                   max: cameraRect.maxY - enemy.size.height/2))
        enemy.zPosition = 50
        addChild(enemy)
        
        let actionMove = SKAction.moveTo(x: cameraRect.minX - enemy.size.width/2, duration: 1.5)
        let actionRemove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
    }
    
    func startZombieAnimation() {
        if zombie.action(forKey: "animation") == nil {
            zombie.run(SKAction.repeatForever(zombieAnimation),
                       withKey: "animation")
        }
    }
    
    func stopZombieAnimation() {
        zombie.removeAction(forKey: "animation")
    }
    
    func spawnCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        cat.position = CGPoint(
            x: CGFloat.random(min: cameraRect.minX, max: cameraRect.maxX),
            y: CGFloat.random(min: cameraRect.minY, max: cameraRect.maxY))
        cat.zPosition = 50
        cat.setScale(0)
        addChild(cat)
        
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        let disappear = SKAction.scale(to: 0.0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotate(byAngle: π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        let actions = [appear, groupWait, disappear, removeFromParent]
        cat.run(SKAction.sequence(actions))
    }
    
    func zombieHit(cat: SKSpriteNode) {
        run(catCollisionSound)
        cat.name = "train"
        cat.removeAllActions()
        cat.run(SKAction.scale(to: 1.0, duration: 0.2))
        cat.zRotation = 0
        cat.run(SKAction.colorize(with: .green, colorBlendFactor: 1.0, duration: 0.2))
    }
    
    func zombieHit(enemy: SKSpriteNode) {
//        enemy.removeFromParent()
        run(enemyCollisionSound)
        
        let blinkTimes = 6.0
        let duration = 3.0
        let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice)
            node.isHidden = remainder > slice / 2
        }
        let switchZombieInvincibility = SKAction.run() {
            self.zombieInvincibleDueToHit = !self.zombieInvincibleDueToHit
        }
        let hardTrueHidden = SKAction.run() {
            self.zombie.isHidden = false
        }
        let fullBlinkAction = SKAction.sequence([switchZombieInvincibility, blinkAction, switchZombieInvincibility, hardTrueHidden])
        zombie.run(fullBlinkAction)
        
        lives -= 1
        loseCats()
    }
    
    func checkCollisions() {
        var hitCats: [SKSpriteNode] = []
        enumerateChildNodes(withName: "cat") { node, _ in
            let cat = node as! SKSpriteNode
            if cat.frame.insetBy(dx: 15, dy: 15).intersects(self.zombie.frame.insetBy(dx: 30, dy: 30)) {
                hitCats.append(cat)
            }
        }
        for cat in hitCats {
            zombieHit(cat: cat)
        }
        
        if !zombieInvincibleDueToHit {
            var hitEnemies: [SKSpriteNode] = []
            enumerateChildNodes(withName: "enemy") { node, _ in
                let enemy = node as! SKSpriteNode
                if node.frame.insetBy(dx: 50, dy: 50).intersects(self.zombie.frame.insetBy(dx: 30, dy: 30)) {
                    hitEnemies.append(enemy)
                }
            }
            for enemy in hitEnemies {
                zombieHit(enemy: enemy)
                zombie.isHidden = true
            }
        }
    }
    
    func moveTrain() {
        var targetPosition = zombie.position
        var trainCount = 0
        
        enumerateChildNodes(withName: "train") { node, stop in
            trainCount += 1
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.trainMovePointsPerSec
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveBy(x: amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.run(moveAction)
            }
            targetPosition = node.position
        }
        
        catLabel.text = "Cats: \(trainCount)"
        
        if trainCount >= 15 && !gameOver {
            gameOver = true
            print("You Win!")
            backgroundMusicPlayer.stop()
            
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func loseCats() {
        var loseCount = 0
        enumerateChildNodes(withName: "train") { node, stop in
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            
            node.name = ""
            node.run(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.rotate(byAngle: π*4, duration: 1.0),
                        SKAction.move(to: randomSpot, duration: 1.0),
                        SKAction.scale(to: 0, duration: 1.0)]),
                    SKAction.removeFromParent()]))
            loseCount += 1
            if loseCount >= 2 {
                stop[0] = true
            }
        }
    }
}
