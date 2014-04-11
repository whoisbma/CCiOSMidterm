//
//  BMAMyScene.m
//  CCiOSMidterm
//
//  Created by Bryan Ma on 3/25/14.
//  Copyright (c) 2014 Bryan Ma. All rights reserved.
//
// ADD ENDING SCREEN + RESTART
// ADD START SCREEN

//refactor? make new classes?

//black holes only attract within certain distances?
//asteroids catch on fire?

//no movement when any controlled object at edge of screen?
//or... wrap screen?!??

//bumping into stuff makes people fall off? twinkly stars to pick up?


#import "BMAMyScene.h"
#import "Physics.h"
#import "SKTUtils.h"

@interface BMAMyScene() <SKPhysicsContactDelegate>  //protocol defines two methods to implement - didBeginContact and didEndContact
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
    
    int _currentLevel;
    int _fuel;
    int _swipeCounter;
    float _newX;
    float _newY;
    int _timer;
    
    CGPoint _touchLocation;
    CGPoint _releaseLocation;
    CGVector _velocity;
    
    NSMutableArray *_blackHoleLoc;
    NSMutableArray *_newBlackHoleLoc;
    NSMutableArray *_newBlackHoleSize;
    
    SKLabelNode *_earthPopulationLabel;
    NSMutableArray *_populationLabels;
    NSMutableArray *_colonyPlanets;
    
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
    
    _blackHoleLoc = [[NSMutableArray alloc] init];  //for storing locations of black holes
    _newBlackHoleLoc = [[NSMutableArray alloc]init];  //for updating black hole loc positions
    _newBlackHoleSize = [[NSMutableArray alloc]init];
    _populationLabels = [[NSMutableArray alloc]init]; // for storing all planet population labels
    _colonyPlanets = [[NSMutableArray alloc]init];  // for keeping array of all the colony planets to use with the labels

    [self addShipAtPosition:CGPointMake(self.size.width/2,self.size.height/2-100)]; //adds ship at center
    [self addAsteroidAtPosition:CGPointMake(100, 100) withSize:CGSizeMake(16, 16)];
    [self addAsteroidAtPosition:CGPointMake(250, 200) withSize:CGSizeMake(24, 24)];
    [self addAsteroidAtPosition:CGPointMake(280, 350) withSize:CGSizeMake(32, 32)];
    [self addBlueSunAtPosition:CGPointMake(100, 400) withSize:CGSizeMake(24, 24)];
    [self addSunAtPosition:CGPointMake(190, 330) withSize:CGSizeMake(100, 100)];
    [self addColonyPlanetAtPosition:CGPointMake(50, 200) withSize: CGSizeMake(24,24)];
    [self addColonyPlanetAtPosition:CGPointMake(250, 500) withSize: CGSizeMake(48,48)];
    [self addBlackHoleAtPosition:CGPointMake(50, 470) withSize:CGSizeMake(12, 12)];
    [self addBlackHoleAtPosition:CGPointMake(280, 40) withSize:CGSizeMake(8, 8)];
    
    SKSpriteNode * _vignette = [SKSpriteNode spriteNodeWithImageNamed:@"vignette"];
    _vignette.position = CGPointMake(self.size.width/2, self.size.height/2);
    _vignette.size = CGSizeMake(self.size.width, self.size.height);
    [_gameNode addChild:_vignette];
    
    //NSLog(@"array objects: %@", [self getObjectsOfName:@"blackHole" inNode:self]);
}

//make the player ship
- (void) addShipAtPosition:(CGPoint)pos
{
    _shipNode = [SKSpriteNode spriteNodeWithImageNamed:@"earth"];
    _shipNode.name = @"earth";
    _shipNode.position = pos;
    _shipNode.size = CGSizeMake(16.0, 16.0);
    
    [_gameNode addChild:_shipNode];
    
    _shipNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:7];
    _shipNode.physicsBody.linearDamping = 0.9;
    _shipNode.physicsBody.angularDamping = 0.9;
    _shipNode.physicsBody.categoryBitMask = PhysicsCategoryShip;
    _shipNode.physicsBody.contactTestBitMask = PhysicsCategorySun | PhysicsCategoryColony | PhysicsCategoryControlColony | PhysicsCategoryBlackHole;
    
    _shipNode.userData = [[NSMutableDictionary alloc] init];
    
    [_shipNode.userData setObject:[NSNumber numberWithInt:160] forKey:@"maxPopulation"];
    [_shipNode.userData setObject:[NSNumber numberWithInt:80] forKey:@"population"];

    //NSLog(@"population = %@", [_shipNode.userData valueForKey:@"population"]);
    //NSLog(@"earth population (by starting userData)= %i", [_shipNode.userData[@"population"] intValue]);
    
    //SKLabelNode *popUI;
    _earthPopulationLabel = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Regular"];
    _earthPopulationLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    _earthPopulationLabel.fontSize = 10.0;
    _earthPopulationLabel.color = [SKColor whiteColor];
    [_shipNode addChild:_earthPopulationLabel];
    _earthPopulationLabel.text = [NSString stringWithFormat:@"%i", [_shipNode.userData[@"population"] intValue] ];

    //NSLog(@"earth population = %i", [_shipNode.userData[@"population"] intValue]);
    //NSLog(@"earth max population = %@", [_shipNode.userData valueForKey:@"maxPopulation"]);
    
}

- (void) addColonyPlanetAtPosition:(CGPoint)pos withSize:(CGSize)size
{
    _colonyPlanetNode = [SKSpriteNode spriteNodeWithImageNamed:@"greenPlanet"];
    _colonyPlanetNode.name = @"colonyPlanet";
    _colonyPlanetNode.position = pos;
    _colonyPlanetNode.size = size;
    
    [_gameNode addChild:_colonyPlanetNode];
    
    _colonyPlanetNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:size.width/2 - 1];
    _colonyPlanetNode.physicsBody.linearDamping = 0.9;
    _colonyPlanetNode.physicsBody.angularDamping = 0.9;
    _colonyPlanetNode.physicsBody.categoryBitMask = PhysicsCategoryColony;
    _colonyPlanetNode.physicsBody.contactTestBitMask = PhysicsCategoryShip | PhysicsCategorySun | PhysicsCategoryColony | PhysicsCategoryControlColony | PhysicsCategoryBlackHole;

    _colonyPlanetNode.userData = [[NSMutableDictionary alloc] init];
    [_colonyPlanetNode.userData setObject:[NSNumber numberWithInt:size.width*10] forKey:@"maxPopulation"];
    [_colonyPlanetNode.userData setObject:[NSNumber numberWithInt:0] forKey:@"population"];
    
    //NSLog(@"colony population = %i", [_colonyPlanetNode.userData[@"population"] intValue]);
    //NSLog(@"colony max population = %@", [_colonyPlanetNode.userData valueForKey:@"maxPopulation"]);
    
    SKLabelNode * popUI;
    popUI = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Regular"];
    popUI.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    popUI.fontSize = 10.0;
    popUI.color = [SKColor whiteColor];
    popUI.text = [NSString stringWithFormat:@"%i", [_colonyPlanetNode.userData[@"population"] intValue] ];
    [_populationLabels addObject:popUI];   //add label to label array for updating population value onscreen
    [_colonyPlanetNode addChild:popUI];
    [_colonyPlanets addObject:_colonyPlanetNode];
}

- (void) addAsteroidAtPosition:(CGPoint)pos withSize:(CGSize)size
{
    _asteroidNode = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid"];
    _asteroidNode.name = @"asteroid";
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
    _sunNode.name = @"sun";
    _sunNode.position = pos;
    _sunNode.size = size;
    SKAction *action = [SKAction rotateByAngle:M_PI duration:10];
    [_sunNode runAction:[SKAction repeatActionForever:action]];
    
    [_gameNode addChild:_sunNode];
    
    _sunNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius: size.width/2 - 1 ];
    _sunNode.physicsBody.dynamic = NO;
    _sunNode.physicsBody.categoryBitMask = PhysicsCategorySun;
    _sunNode.physicsBody.contactTestBitMask = PhysicsCategoryControlColony;
    
    //CERTAIN KINDS OF SUNS GROW WHEN THEY SWALLOW MASS? THEY CAN BECOME A BLACK HOLE OR EXPLODE?
    //will need to have a 'resting state?' or natural lifecycle?
}

- (void) addBlueSunAtPosition:(CGPoint)pos withSize:(CGSize)size
{
    _blueSunNode = [SKSpriteNode spriteNodeWithImageNamed:@"blueSun"];
    _blueSunNode.name = @"blueSun";
    _blueSunNode.position = pos;
    _blueSunNode.size = size;
    
    [_gameNode addChild:_blueSunNode];
    
    _blueSunNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius: size.width/2 - 1];
    _blueSunNode.physicsBody.dynamic = NO;
}

- (void) addBlackHoleAtPosition:(CGPoint)pos withSize:(CGSize)size{
    _blackHoleNode = [SKSpriteNode spriteNodeWithImageNamed:@"alienPlanet"];
    _blackHoleNode.name = @"blackHole";
    _blackHoleNode.position = pos;
    _blackHoleNode.size = size;
    SKAction *action = [SKAction rotateByAngle:M_PI duration:0.3];
    [_blackHoleNode runAction:[SKAction repeatActionForever:action]];
    [_gameNode addChild:_blackHoleNode];
    
    _blackHoleNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius: size.width/2 - 1];
    _blackHoleNode.physicsBody.dynamic = NO;
    _blackHoleNode.physicsBody.categoryBitMask = PhysicsCategoryBlackHole;
    [_blackHoleLoc addObject:[NSValue valueWithCGPoint:pos]];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        _touchLocation = location;
        _swipeCounter = 0;
        //NSLog(@"touch location: %@", NSStringFromCGPoint(_touchLocation));
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
        
        if ( [_shipNode.userData[@"population"] intValue] > 0 ) {
            [_shipNode.physicsBody applyForce: CGVectorMake(_newX, _newY)];
            int newPop = [_shipNode.userData[@"population"] intValue];
            newPop -= 5;
            [_shipNode.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
        }
        //for (SKSpriteNode *node in _gameNode.children) {
        
        [_gameNode enumerateChildNodesWithName:@"controlColony" usingBlock:^(SKNode *node, BOOL *stop) {
            //if (node.physicsBody.categoryBitMask == PhysicsCategoryControlColony) {
            if ([node.userData[@"population"] intValue] > 0 ) {
                [node.physicsBody applyForce: CGVectorMake(_newX, _newY)];
                int newPop = [node.userData[@"population"] intValue];
                newPop -= 5;
                //NSLog(@"colony population = %i", [node.userData[@"population"] intValue]);
                //node.userData = [@{@"population":@(newPop)} mutableCopy];
                [node.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
            }
   //         }
//        }
         }];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"array objects: %@", _blackHoleLoc);
}


-(void)update:(CFTimeInterval)currentTime {
    
    /* Called before each frame is rendered */
    
    //_fuelUI.text = [NSString stringWithFormat:@"fuel %i", _fuel];
    
    //get all blackhole positions to use for forces
    _newBlackHoleLoc = [[NSMutableArray alloc]init];
    [_gameNode enumerateChildNodesWithName:@"blackHole" usingBlock:^(SKNode *node, BOOL *stop) {
        [_newBlackHoleLoc addObject: [NSValue valueWithCGPoint:node.position]];
    }];
     //NSLog(@"array objects: %@", newArray);
    _blackHoleLoc = _newBlackHoleLoc;
    
    [_gameNode enumerateChildNodesWithName:@"blackHole" usingBlock:^(SKNode *node, BOOL *stop) {
        [_newBlackHoleSize addObject: [NSNumber numberWithFloat:node.frame.size.width]];
    }];
    
    for (SKSpriteNode * node in _gameNode.children) {
        if (node.physicsBody.categoryBitMask == PhysicsCategoryControlColony | node.physicsBody.categoryBitMask == PhysicsCategoryShip) {
            
            for (int i = 0; i < [_blackHoleLoc count]; i++) {
                CGPoint point = [(NSValue*) [_blackHoleLoc objectAtIndex:i] CGPointValue];
                CGPoint offset = CGPointMake(point.x - node.position.x, point.y - node.position.y);
                CGFloat length = sqrtf(offset.x * offset.x + offset.y * offset.y);
                CGPoint direction = CGPointMake(offset.x / length, offset.y / length);
                [node.physicsBody applyForce: CGVectorMake(direction.x * 0.01 * [[_newBlackHoleSize objectAtIndex:i] floatValue], direction.y * 0.01 * [[_newBlackHoleSize objectAtIndex:i] floatValue])];
                //NSLog(@"%@", NSStringFromCGPoint(CGPointMake(point.x, point.y)));
                //NSLog(@"%f", length);
            }
        }
    }
    
    if ( [_shipNode.userData[@"population"] intValue] < [_shipNode.userData[@"maxPopulation"] intValue] ) {
        int newPop = [_shipNode.userData[@"population"] intValue];
        newPop += 1;
        [_shipNode.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
    }
    
    [_gameNode enumerateChildNodesWithName:@"controlColony" usingBlock:^(SKNode *node, BOOL *stop) {
        if ([node.userData[@"population"] intValue] < [node.userData[@"maxPopulation"] intValue] ) {
            int newPop = [node.userData[@"population"] intValue];
            newPop += 1;
            [node.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
            
        }
    }];
    
    //NSLog(@"earth population = %i", [_shipNode.userData[@"population"] intValue]);
    //NSLog(@"earth max population = %i", [_shipNode.userData[@"maxPopulation"] intValue]);
    [_gameNode enumerateChildNodesWithName:@"controlColony" usingBlock:^(SKNode *node, BOOL *stop) {
        NSLog(@"colony population = %i", [node.userData[@"population"] intValue]);
        NSLog(@"colony max population = %i", [node.userData[@"maxPopulation"] intValue]);
        
    }];
    
    _earthPopulationLabel.text = [NSString stringWithFormat:@"%i", [_shipNode.userData[@"population"] intValue] ];
    for (int i = 0; i < [_populationLabels count]; i++) {
        SKLabelNode * label = _populationLabels[i];     //KILL THESE NEW INITIALIZATIONS WITH A PRIVATE VAR?
        SKSpriteNode * newColony = _colonyPlanets[i];
        label.text = [NSString stringWithFormat:@"%i", [newColony.userData[@"population"] intValue]];
        _populationLabels[i] = label;
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
    
    if (collision == (PhysicsCategoryShip | PhysicsCategorySun) ) {
        NSLog(@"DEAAATHHHH");
        [contact.bodyA.node removeFromParent];
        
        NSLog(@"grow time!");
        //ENTER MYSTERY CODE HERE! contact.bodyB.node.size is no good.
        //[contact.bodyB.node setScale:2.0];
        CGFloat absorbMass = contact.bodyA.node.frame.size.width * 0.01; //THIS SORT OF WORKS BUT I WANTED MASS
        NSLog(@"width: %f", absorbMass);
        SKAction *grow = [SKAction scaleTo:1.0+absorbMass duration:3.0]; //THIS ISN'T REALLY WORKING THE WAY I WANT IT TO, ESP WHEN IT STACKS
        SKAction *wait = [SKAction waitForDuration:5.0];
        SKAction *shrink = [SKAction scaleTo:1.0-absorbMass/2 duration:10.0]; //MATH ISN'T RIGHT FOR THE SHRINK
        
        [contact.bodyB.node runAction:
         [SKAction sequence:@[grow, wait, shrink]]];
    }
    
    else if (collision == (PhysicsCategoryControlColony | PhysicsCategorySun))
    {
        NSLog(@"Colony death");
        [contact.bodyB.node removeFromParent];
        
        SKAction *grow = [SKAction scaleTo:1.4 duration:3.0];
        SKAction *wait = [SKAction waitForDuration:10.0];
        SKAction *shrink = [SKAction scaleTo:1.0 duration:10.0];
        
        [contact.bodyA.node runAction:
         [SKAction sequence:@[grow, wait, shrink]]];
    }
    
    //ship turning colony into control colony
    else if (collision == (PhysicsCategoryShip | PhysicsCategoryColony))
    {
        contact.bodyB.categoryBitMask = PhysicsCategoryControlColony;
        NSLog(@"New colony");
        contact.bodyB.node.name = @"controlColony";
    }
    
    //Colony turning into control colony
    else if (collision == (PhysicsCategoryControlColony | PhysicsCategoryColony))
    {
        contact.bodyB.categoryBitMask = PhysicsCategoryControlColony;
        contact.bodyA.categoryBitMask = PhysicsCategoryControlColony;
        NSLog(@"New colony");
        contact.bodyB.node.name = @"controlColony";
        contact.bodyA.node.name = @"controlColony";
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
            [node.physicsBody applyImpulse: CGVectorMake(-direction.x * contact.bodyB.node.frame.size.width * 0.3, -direction.y * contact.bodyB.node.frame.size.width * 0.3)];
        }
        //NSValue * valToRemove = [NSValue valueWithCGPoint:contact.bodyB.node.position];
        //[_blackHoleLoc removeObjectIdenticalTo:valToRemove];
//        [_blackHoleLoc removeObjectIdenticalTo:[NSValue valueWithCGPoint:contact.bodyB.node.position]];
        [contact.bodyA.node removeFromParent];
        [contact.bodyB.node removeFromParent];
    }
    
}


@end
