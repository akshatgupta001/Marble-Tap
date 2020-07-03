//
//  GameScene.swift
//  MovingMarbles
//
//  Created by Akshat Gupta on 01/07/20.
//  Copyright © 2020 coded. All rights reserved.
//
import CoreMotion
import SpriteKit
 
class Ball : SKSpriteNode {}

class GameScene: SKScene {
    
    var balls = ["ballBlue","ballGreen","ballGrey","ballPurple","ballYellow","ballRed","ballCyan"]
    var motionManager : CMMotionManager?
    
    let scoreLabel = SKLabelNode(fontNamed: "HelveticaNeue-Thin")
    var matchedBalls = Set<Ball>()
    
    var score = 0 {
        didSet {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let formattedScore = formatter.string(from: score as NSNumber) ?? "0"
            scoreLabel.text = "Score : \(formattedScore)"
        }
    }
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "checkerboard")
        background.position = CGPoint(x:frame.midX, y : frame.midY)
        background.alpha = 0.2
        background.zPosition = -1
        addChild(background)
        
        scoreLabel.fontSize = 72
        scoreLabel.position = CGPoint(x:20, y:20)
        scoreLabel.text = "Score : 0"
        scoreLabel.zPosition = 100
        scoreLabel.horizontalAlignmentMode = .left
        addChild(scoreLabel)
        
        let ball = SKSpriteNode(imageNamed: "ballBlue")
        let ballRadius = ball.frame.width/2.0
        
        for i in stride(from: ballRadius, to: view.bounds.width-ballRadius, by: ball.frame.width){
            for j in stride(from: 100, to: view.bounds.height-ballRadius, by: ball.frame.height){
                let ballType = balls.randomElement()!
                let ball = Ball(imageNamed: ballType)
                ball.position = CGPoint(x: i, y: j)
                ball.name = ballType
                
                ball.physicsBody = SKPhysicsBody(circleOfRadius: ballRadius)
                ball.physicsBody?.allowsRotation = false
                ball.physicsBody?.restitution = 0
                ball.physicsBody?.friction = 0
                
                addChild(ball)
            }
        }
        
        let uniforms : [SKUniform] = [
            SKUniform(name: "u_speed", float : 1),
            SKUniform(name: "u_frequency", float: 20 ),
            SKUniform(name: "u_strength",float: 3)
        ]
        
        let shader = SKShader(fileNamed: "Background")
        shader.uniforms = uniforms
        background.shader = shader
        
        background.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 10)))
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame.inset(by: UIEdgeInsets(top: 100, left: 0, bottom: 0, right: 0)))
        
        motionManager = CMMotionManager()
        motionManager?.startAccelerometerUpdates()
    }
    

    override func update(_ currentTime: TimeInterval) {
        if let accelerometerData = motionManager?.accelerometerData{
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50)
        }
    }
    
    //standard method but strict
//    func getMatches(from node:Ball){
//        for body in node.physicsBody!.allContactedBodies(){
//            guard let ball = body.node as? Ball else {continue}
//            guard ball.name == node.name else {continue}
//
//            if !matchedBalls.contains(ball){
//                matchedBalls.insert(ball)
//                getMatches(from: ball)
//            }
//        }
//    }
    
    //more relaxed matching
    func getMatches(from startBall : Ball){
        let matchWidth =  startBall.frame.width * startBall.frame.width + 1.1
        
        for node in children{
            guard let ball = node as? Ball else {continue}
            guard ball.name == startBall.name else {continue}
            
            let dist = distance(from: startBall, to: ball)
            guard dist < matchWidth else {continue}
            
            if !matchedBalls.contains(ball){
                matchedBalls.insert(ball)
                getMatches(from: ball)
            }
        }
        
    }
    
    func distance(from : Ball, to : Ball) -> CGFloat {
        let dis = (from.position.x - to.position.x) * (from.position.x - to.position.x) + (from.position.y - to.position.y) * (from.position.y - to.position.y)
        return dis
    }
    
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard let position = touches.first?.location(in: self) else {return}
        guard let tappedBall = nodes(at: position).first(where: { $0 is Ball}) as? Ball else {return}
        
        matchedBalls.removeAll(keepingCapacity: true)
        
        getMatches(from: tappedBall)
        
        if matchedBalls.count >= 3{
            score += Int(pow(2, 2*Double(min(matchedBalls.count,16))))
            for ball in matchedBalls{
                if let particle = SKEmitterNode(fileNamed: "Explosion"){
                    particle.position = ball.position
                    addChild(particle)
                    
                    let removeAfterDead = SKAction.sequence([SKAction.wait(forDuration: 3),SKAction.removeFromParent()])
                    particle.run(removeAfterDead)
                }
                
                ball.removeFromParent()
            }
        }
        
        if matchedBalls.count >= 5 {
            let omg = SKSpriteNode(imageNamed: "omg")
            omg.position = CGPoint(x: frame.midX, y : frame.midY)
            omg.zPosition = 100
            omg.xScale = 0.001
            omg.yScale = 0.001
            addChild(omg)
            
            let appear = SKAction.group([SKAction.scale(to: 1, duration: 0.25), SKAction.fadeIn(withDuration: 0.25)])
            let disapper = SKAction.group([SKAction.scale(to: 2, duration: 0.25), SKAction.fadeOut(withDuration: 0.25)])
            let sequence  = SKAction.sequence([appear, SKAction.wait(forDuration: 0.25), disapper])
            omg.run(sequence)
        }
        
    }
    
}
