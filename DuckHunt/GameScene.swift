//
//  GameScene.swift
//  DuckHunt
//
//  Created by Tim on 07.12.2022.
//

import SpriteKit
import GameplayKit

final class GameScene: SKScene {
    
    private enum Reason {
        case hitTop, hitBottom, hitLeft, hitRight
    }
    private var width: Int!
    var height: Int!
    
    private var sky: SKSpriteNode!
    private var tree1: SKSpriteNode!
    private var tree2: SKSpriteNode!
    private var hills: SKSpriteNode!
    private var bullets = [SKSpriteNode]()
    
    private var textureAtlas: SKTextureAtlas!
    private var textureArray = [SKTexture]()
    
    private var scoreLabel: SKLabelNode!
    private var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
            if score % 20 == 0 && score != 0 {
                level += 1
            }
        }
    }
    private var level = 1 {
        didSet {
            levelUp()
        }
    }
    private var interval: TimeInterval = 1
    private var enemyWave = 5
    private var allowedToShoot = true
    private var bulletsLeft = 6 {
        didSet {
            if bulletsLeft == 0 {
                allowedToShoot = false
                reloadBullets()
            }
        }
    }
    private var timer = Timer()
    
    override func didMove(to view: SKView) {
        width = Int(view.bounds.width)
        height = Int(view.bounds.height)
    
        sky = SKSpriteNode(imageNamed: "sky")
        sky.zPosition = -1
        sky.size = CGSize(width: width , height: height)
        sky.position = CGPoint(x: width / 2, y: height / 2)
        sky.blendMode = .replace
        addChild(sky)
        
        hills = SKSpriteNode(imageNamed: "hills")
        hills.zPosition = 1
        hills.size = CGSize(width: width , height: width / 6)
        hills.position = CGPoint(x: width / 2, y: width / 12)
        addChild(hills)
        
        tree1 = SKSpriteNode(imageNamed: "tree1")
        tree1.zPosition = 2
        tree1.size = CGSize(width: 110 , height: 210)
        tree1.position = CGPoint(x: 55, y: 190)
        addChild(tree1)
        
        tree2 = SKSpriteNode(imageNamed: "tree2")
        tree2.zPosition = 2
        tree2.size = CGSize(width: 150 , height: 150)
        tree2.position = CGPoint(x: width - 95, y: 200)
        addChild(tree2)
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.position = CGPoint(x: width - 80, y: height - 40)
        scoreLabel.fontColor = .black
        scoreLabel.zPosition = 2
        scoreLabel.fontSize = 22
        addChild(scoreLabel)

        score = 0
        level = 1
        
        textureAtlas = SKTextureAtlas(named: "duck")
        for i in 1...textureAtlas.textureNames.count { textureArray.append(SKTexture(imageNamed: "\(i).png"))}
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, allowedToShoot else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)
        bulletsLeft -= 1
        bullets.popLast()?.removeFromParent()
        
        for node in tappedNodes {
            if node.name == "duck" {
                let deadDuck = SKSpriteNode(texture: SKTexture(imageNamed: "dead"), size: CGSize(width: 50, height: 50))
                deadDuck.name = "deadDuck"
                deadDuck.position = node.position
                node.removeFromParent()
                addChild(deadDuck)
                deadDuck.run(SKAction.moveTo(y: 0, duration: 1))
                
                let hit = SKEmitterNode(fileNamed: "explosion")!
                hit.position = location
                hit.setScale(0.4)
                hit.name = "hit"
                addChild(hit)
                
                score += 1
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        for node in children {
            switch node.name {
            case "hit":
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    node.removeFromParent()
                }
            case "deadDuck":
                if node.position.y == 0 {
                    node.removeFromParent()
                }
            case "duck":
                if node.position.x < -24 {
                    changeDirection(of: node, for: .hitLeft)
                } else if node.position.x > 877 {
                    changeDirection(of: node, for: .hitRight)
                } else if node.position.y > 393 {
                    changeDirection(of: node, for: .hitTop)
                } else if node.position.y < 100 {
                    changeDirection(of: node, for: .hitBottom)
                }
            default:
                continue
            }
        }
    }
    
    @objc private func createDuck() {
        guard enemyWave != 0 else {
            if !children.contains(where: {$0.name == "duck"}) {
                DispatchQueue.main.asyncAfter(deadline: .now() + interval - 0.1) { [weak self] in
                    if let level = self?.level {
                        self?.enemyWave = level + 4
                    }
                }
            }
            return
        }
        enemyWave -= 1
        
        let xPos = [-24, width + 24].randomElement()!
        
        let duck = Duck(texture: textureArray[0])
        duck.name = "duck"
        duck.size = CGSize(width: 50, height: 50)
        duck.position = CGPoint(x: xPos, y: Int.random(in: 100...height - 50))
        
        var vector = CGVector(dx: Int.random(in: 10...40), dy: Int.random(in: -20...20))
        addChild(duck)
        if xPos > 0 {
            duck.xScale = -duck.xScale
            vector = CGVector(dx: -Int.random(in: 10...40), dy: Int.random(in: -40...40))
        }
        
        duck.run(SKAction.repeatForever(SKAction.move(by: vector, duration: 0.2)))
        duck.run(SKAction.repeatForever(SKAction.animate(with: textureArray, timePerFrame: 0.05)))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            duck.isFlyingAway = true
        }
    }
    
    private func changeDirection(of duck: SKNode, for reason: Reason) {
        guard let duck = duck as? Duck, !duck.isFlyingAway else {
            duck.removeFromParent()
            return
        }
        duck.removeAllActions()
        var vector = CGVector()
            
        switch reason {
        case .hitTop:
            if duck.xScale > 0 {
                vector = CGVector(dx: Int.random(in: 10...40), dy: -Int.random(in: 10...40))
            } else {
                vector = CGVector(dx: -Int.random(in: 10...40), dy: -Int.random(in: 10...40))
            }
            duck.position.y = 393
        case .hitBottom:
            if duck.xScale > 0 {
                vector = CGVector(dx: Int.random(in: 10...40), dy: Int.random(in: 10...40))
            } else {
                vector = CGVector(dx: -Int.random(in: 10...40), dy: Int.random(in: 10...40))
            }
            duck.position.y = 100
        case .hitLeft:
            duck.xScale = -duck.xScale
            vector = CGVector(dx: Int.random(in: 10...40), dy: Int.random(in: -20...20))
            duck.position.x = -24
        case .hitRight:
            duck.xScale = -duck.xScale
            vector = CGVector(dx: -Int.random(in: 10...40), dy: Int.random(in: -20...20))
            duck.position.x = 877
        }
        duck.run(SKAction.repeatForever(SKAction.move(by: vector, duration: 0.2)))
        duck.run(SKAction.repeatForever(SKAction.animate(with: textureArray, timePerFrame: 0.05)))
    }
    
    private func reloadBullets() {
        let reloadMessage = SKLabelNode(fontNamed: "Chalkduster")
        reloadMessage.text = "RELOAD"
        reloadMessage.fontSize = 26
        reloadMessage.fontColor = .black
        reloadMessage.zPosition = 3
        reloadMessage.position = CGPoint(x: 100, y: 30)
        addChild(reloadMessage)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            reloadMessage.removeFromParent()
            guard let self else { return }
            self.allowedToShoot = true
            self.bulletsLeft = self.level + 5
            self.placeBullets()
        }
    }
    
    private func placeBullets() {
        for bullet in 1...bulletsLeft {
            let image = SKSpriteNode(imageNamed: "bulletBlack")
            image.size = CGSize(width: 10, height: 26)
            image.position = CGPoint(x: 40 + (15 * bullet), y: 40)
            image.zPosition = 3
            addChild(image)
            bullets.append(image)
        }
    }
    
    private func levelUp() {
        let levelLabel = SKLabelNode(fontNamed: "Chalkduster")
        levelLabel.text = "LEVEL \(level)"
        levelLabel.fontSize = 40
        levelLabel.fontColor = .black
        levelLabel.zPosition = 3
        levelLabel.position = CGPoint(x: width / 2, y: height / 2)
        addChild(levelLabel)
        
        reloadBullets()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            levelLabel.removeFromParent()
            guard let self else { return }
            
            self.timer.invalidate()
            self.enemyWave = self.level + 4
            self.timer = Timer.scheduledTimer(timeInterval: self.interval, target: self, selector: #selector(self.createDuck), userInfo: nil, repeats: true)
                
            guard self.interval > 0.1 else { return }
            self.interval -= 0.1
        }
    }
}

