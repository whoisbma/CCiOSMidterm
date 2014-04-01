//
//  BMAMyScene.m
//  CCiOSMidterm
//
//  Created by Bryan Ma on 3/25/14.
//  Copyright (c) 2014 Bryan Ma. All rights reserved.
//

#import "BMAMyScene.h"
#import "Physics.h"
#import "SKTUtils.h"

@interface BMAMyScene() <SKPhysicsContactDelegate>
//protocol defines two methods to implement - didBeginContact and didEndContact
@end


@implementation BMAMyScene
{
    SKNode *_gameNode;
    SKSpriteNode *_shipNode;
    SKSpriteNode *_asteroidNode;
    SKSpriteNode *_sunNode;
    SKSpriteNode *_blueSunNode;
    SKSpriteNode *_colonyPlanetNode;
    SKSpriteNode *_blackHoleNode;
    SKLabelNode *_fuelUI;
    SKLabelNode *_popUI;
    
    int _currentLevel;
    int _fuel;
    int _swipeCounter;
    float _newX;
    float _newY;
    int _timer;
    
    CGPoint _touchLocation;
    CGPoint _releaseLocation;
    CGVector _velocity;
    
    CGPoint _holeLoc;
}


- (instancetype)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size]) {
        [self initializeScene];
    }
    return self;
}

//initialize scene
- (void) initializeScene
{
    self.backgroundColor = [SKColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
    _gameNode = [SKNode node];
    [self addChild:_gameNode];
    self.physicsWorld.gravity = CGVectorMake(0, 0); //set gravity to zero
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsWorld.contactDelegate = self;
    [self addShipAtPosition:CGPointMake(self.size.width/2,self.size.height/2-100)]; //adds ship at center
    [self addAsteroidAtPosition:CGPointMake(100, 100) withSize:CGSizeMake(16, 16)];
    [self addAsteroidAtPosition:CGPointMake(250, 200) withSize:CGSizeMake(24, 24)];
    [self addAsteroidAtPosition:CGPointMake(280, 350) withSize:CGSizeMake(32, 32)];
    [self addBlueSunAtPosition:CGPointMake(100, 400) withSize:CGSizeMake(24, 24)];
    [self addSunAtPosition:CGPointMake(190, 330) withSize:CGSizeMake(100, 100)];
    [self addColonyPlanetAtPosition:CGPointMake(50, 200) withSize: CGSizeMake(24,24)];
    [self addColonyPlanetAtPosition:CGPointMake(250, 500) withSize: CGSizeMake(48,48)];
    [self addBlackHoleAtPosition:CGPointMake(50, 470) withSize:CGSizeMake(16, 16)];
    [self addBlackHoleAtPosition:CGPointMake(280, 40) withSize:CGSizeMake(16, 16)];
    
    _fuelUI = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Regular"];
    _fuelUI.fontSize = 12.0;
    _fuelUI.color = [SKColor whiteColor];
    [_gameNode addChild:_fuelUI];
    _fuelUI.position = CGPointMake(40, 20);
    _fuel = 1000;
    
    _popUI = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Regular"];
    _popUI.fontSize = 8.0;
    _popUI.color = [SKColor whiteColor];
    [_gameNode addChild:_popUI];
    _popUI.text = @"1000";
    
    SKSpriteNode * _vignette = [SKSpriteNode spriteNodeWithImageNamed:@"vignette"];
    _vignette.position = CGPointMake(self.size.width/2, self.size.height/2);
    _vignette.size = CGSizeMake(self.size.width, self.size.height);
    [_gameNode addChild:_vignette];
}

//make the player ship
- (void) addShipAtPosition:(CGPoint)pos
{
    _shipNode = [SKSpriteNode spriteNodeWithImageNamed:@"earth"];
    _shipNode.position = pos;
    _shipNode.size = CGSizeMake(16.0, 16.0);
    
    [_gameNode addChild:_shipNode];
    
    _shipNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:7];
    _shipNode.physicsBody.linearDamping = 0.9;
    _shipNode.physicsBody.angularDamping = 0.9;
    _shipNode.physicsBody.categoryBitMask = PhysicsCategoryShip;
    _shipNode.physicsBody.contactTestBitMask = PhysicsCategorySun | PhysicsCategoryColony | PhysicsCategoryControlColony | PhysicsCategoryBlackHole;
}

- (void) addColonyPlanetAtPosition:(CGPoint)pos withSize:(CGSize)size
{
    _colonyPlanetNode = [SKSpriteNode spriteNodeWithImageNamed:@"greenPlanet"];
    _colonyPlanetNode.position = pos;
    _colonyPlanetNode.size = size;
    
    [_gameNode addChild:_colonyPlanetNode];
    
    _colonyPlanetNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:size.width/2 - 1];
    _colonyPlanetNode.physicsBody.linearDamping = 0.9;
    _colonyPlanetNode.physicsBody.angularDamping = 0.9;
    _colonyPlanetNode.physicsBody.categoryBitMask = PhysicsCategoryColony;
    _colonyPlanetNode.physicsBody.contactTestBitMask = PhysicsCategoryShip | PhysicsCategorySun | PhysicsCategoryColony | PhysicsCategoryControlColony | PhysicsCategoryBlackHole;
}

- (void) addAsteroidAtPosition:(CGPoint)pos withSize:(CGSize)size
{
    _asteroidNode = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid"];
    _asteroidNode.position = pos;
    _asteroidNode.size = size;
    
    [_gameNode addChild:_asteroidNode];
    
    _asteroidNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius: (size.width/2-1)];
    _asteroidNode.physicsBody.categoryBitMask = PhysicsCategoryAsteroid;
    _asteroidNode.physicsBody.contactTestBitMask = PhysicsCategoryBlackHole | PhysicsCategorySun;
}

- (void) addSunAtPosition:(CGPoint)pos withSize:(CGSize)size
{
    _sunNode = [SKSpriteNode spriteNodeWithImageNamed:@"sun"];
    _sunNode.position = pos;
    _sunNode.size = size;
    SKAction *action = [SKAction rotateByAngle:M_PI duration:10];
    [_sunNode runAction:[SKAction repeatActionForever:action]];
    
    [_gameNode addChild:_sunNode];
    
    _sunNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius: size.width/2 - 1 ];
    _sunNode.physicsBody.dynamic = NO;
    _sunNode.physicsBody.categoryBitMask = PhysicsCategorySun;
    
    //CERTAIN KINDS OF SUNS GROW WHEN THEY SWALLOW MASS? THEY CAN BECOME A BLACK HOLE OR EXPLODE?
    //will need to have a 'resting state?' or natural lifecycle?
}

- (void) addBlueSunAtPosition:(CGPoint)pos withSize:(CGSize)size
{
    _blueSunNode = [SKSpriteNode spriteNodeWithImageNamed:@"blueSun"];
    _blueSunNode.position = pos;
    _blueSunNode.size = size;
    
    [_gameNode addChild:_blueSunNode];
    
    _blueSunNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius: size.width/2 - 1];
    _blueSunNode.physicsBody.dynamic = NO;
}

- (void) addBlackHoleAtPosition:(CGPoint)pos withSize:(CGSize)size{
    _blackHoleNode = [SKSpriteNode spriteNodeWithImageNamed:@"alienPlanet"];
    _blackHoleNode.position = pos;
    _blackHoleNode.size = size;
    SKAction *action = [SKAction rotateByAngle:M_PI duration:0.3];
    [_blackHoleNode runAction:[SKAction repeatActionForever:action]];
    [_gameNode addChild:_blackHoleNode];
    
    _blackHoleNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius: size.width/2 - 1];
    _blackHoleNode.physicsBody.dynamic = NO;
    _blackHoleNode.physicsBody.categoryBitMask = PhysicsCategoryBlackHole;
    
    //BLACK HOLE EXPLODES WHEN TOUCHED BY SOMETHING? FIRES FORCE OUTWARDS?
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        _touchLocation = location;
        _swipeCounter = 0;
        //NSLog(@"touch location: %@", NSStringFromCGPoint(_touchLocation));
        
//        CGPoint location = [touch locationInNode:self];
//        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
//        sprite.position = location;
//        SKAction *action = [SKAction rotateByAngle:M_PI duration:1];
//        [sprite runAction:[SKAction repeatActionForever:action]];
//        [self addChild:sprite];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *) event
{
    //if (_swipeCounter < 10) {
        _swipeCounter++;
        _fuel -= 1;
        //NSLog(@"%i", _swipeCounter);
        for (UITouch *touch in touches) {
            CGPoint location = [touch locationInNode:self];
            _releaseLocation = location;
            _newX = (_releaseLocation.x - _touchLocation.x) * 0.04;//(_swipeCounter * 0.0001);
            _newY = (_releaseLocation.y - _touchLocation.y) * 0.04;//(_swipeCounter * 0.0001);
            [_shipNode.physicsBody applyForce: CGVectorMake(_newX, _newY)];
            
            for (SKSpriteNode *node in _gameNode.children) {
                if (node.physicsBody.categoryBitMask == PhysicsCategoryControlColony) {
                    [node.physicsBody applyForce: CGVectorMake(_newX, _newY)];
                }
            }
        
        }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{

}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    _fuelUI.text = [NSString stringWithFormat:@"fuel %i", _fuel];
    
    //maybe try something where an impulse gets applied here if the vel change is above a certain amount
    //or...move something around with finger and toss it?
    //apply the force when its at its maximum and then decrease it?
    //or just find the direction between the two points and add a constant force there? instead of an incrementing impulse?
    
    //move towards black hole? (make a black hole movement check function to encapsulate this.
    for (SKSpriteNode * node in _gameNode.children) {
        //for (SKPhysicsBody blackHoles in _gameNode.children)  //HOW TO DO THIS PROPERLY? I WANT TO GET THE FORCES OF ALL THE BLACK HOLES, NOT JUST ONE! USE A METHOD?!?
        if (node.physicsBody.categoryBitMask == PhysicsCategoryBlackHole) {
            _holeLoc = CGPointMake(node.position.x, node.position.y);
            //NSLog(@"%@", NSStringFromCGPoint(CGPointMake(holeLoc.x, holeLoc.y)));
            //NSLog(@"%f", node.position.x);
        }
        if (node.physicsBody.categoryBitMask == PhysicsCategoryShip | node.physicsBody.categoryBitMask == PhysicsCategoryControlColony) {
            //NSLog(@"%@", NSStringFromCGPoint(CGPointMake(holeForce.x, holeForce.y)));
            CGPoint offset = CGPointMake(_holeLoc.x - node.position.x, _holeLoc.y - node.position.y);
            CGFloat length = sqrtf(offset.x * offset.x + offset.y * offset.y);
            CGPoint direction = CGPointMake(offset.x / length, offset.y / length);
            //NSLog(@"%@", NSStringFromCGPoint(CGPointMake(direction.x, direction.y)));
            //NSLog(@"%f", length);
            [node.physicsBody applyForce: CGVectorMake(direction.x * 0.1, direction.y * 0.1)];
        }
    }
    
    //display population at each controlled planet?
    for (SKSpriteNode *node in _gameNode.children) {
        if (node.physicsBody.categoryBitMask == PhysicsCategoryShip | node.physicsBody.categoryBitMask == PhysicsCategoryControlColony) {
            
            _popUI.position = node.position;
            
        }
    }
}

- (void)didSimulatePhysics
{
    _newX = 0;
    _newY = 0;
    _velocity = _shipNode.physicsBody.velocity;
}

- (void)didBeginContact:(SKPhysicsContact *) contact
{
    uint32_t collision = (contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask);
    
    if (collision == (PhysicsCategoryShip | PhysicsCategorySun)) {
        NSLog(@"DEAAATHHHH");
        [contact.bodyA.node removeFromParent];
        
        NSLog(@"grow time!");
        //ENTER MYSTERY CODE HERE! contact.bodyB.node.size is no good.
        [contact.bodyB.node setScale:2.0];
    }
    
    else if (collision == (PhysicsCategoryControlColony | PhysicsCategorySun))
    {
        NSLog(@"Colony death");
        [contact.bodyB.node removeFromParent];
    }
    
    //ship turning colony into control colony
    else if (collision == (PhysicsCategoryShip | PhysicsCategoryColony))
    {
        contact.bodyB.categoryBitMask = PhysicsCategoryControlColony;
        NSLog(@"New colony");
    }
    
    //Colony turning into control colony
    else if (collision == (PhysicsCategoryControlColony | PhysicsCategoryColony))
    {
        contact.bodyB.categoryBitMask = PhysicsCategoryControlColony;
        contact.bodyA.categoryBitMask = PhysicsCategoryControlColony;
        NSLog(@"New colony");
    }
    
    //black hole force explosion and disappear
    else if ( (collision == (PhysicsCategoryShip | PhysicsCategoryBlackHole)) | (collision == (PhysicsCategoryControlColony | PhysicsCategoryBlackHole)) | (collision == (PhysicsCategoryAsteroid | PhysicsCategoryBlackHole)) )
    {
        NSLog(@"explodeytime!");
        for (SKSpriteNode *node in _gameNode.children)
        {
            CGPoint offset = CGPointMake(contact.bodyB.node.position.x - node.position.x, contact.bodyB.node.position.y - node.position.y);
            CGFloat length = sqrtf(offset.x * offset.x + offset.y * offset.y);
            CGPoint direction = CGPointMake(offset.x / length, offset.y / length);
            [node.physicsBody applyImpulse: CGVectorMake(-direction.x * 5, -direction.y * 5)];
        }
        [contact.bodyA.node removeFromParent];
        [contact.bodyB.node removeFromParent];
    }
    
}


@end
