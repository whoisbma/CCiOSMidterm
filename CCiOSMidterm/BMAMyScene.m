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

//GAS PLANETS can turn into suns?

//certain hospitable planets do not regenerate if population drops below zero?

//bumping into stuff makes people fall off? twinkly stars to pick up?

//Make population shrink in hot or cold zone, and make earth blend red and blue respectively, maybe add particle effect?
// try to use the catnap design pattern to generate levels


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
    NSMutableArray *_eventHorizonShapes;
    NSMutableArray *_suns;
    //will need new arrays for:
    //hotZoneShapes
    //coldZoneShapes
    
}


- (instancetype)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size]) {
        [self initializeScene];
    }
    return self;
}

//______________________________________________________________________________________________________________
//|                                                                                                            |
//|                                                                                                            |
//|                                             INITIALIZE SCENE                                               |
//|                                                                                                            |
//|____________________________________________________________________________________________________________|

- (void) initializeScene
{
    self.backgroundColor = [SKColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
    _gameNode = [SKNode node];
    [self addChild:_gameNode];
    self.physicsWorld.gravity = CGVectorMake(0, 0); //set gravity to zero
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsWorld.contactDelegate = self;
    
    _blackHoleLoc = [[NSMutableArray alloc] init];  //for storing locations of black holes
    _newBlackHoleLoc = [[NSMutableArray alloc] init];  //for updating black hole loc positions
    _newBlackHoleSize = [[NSMutableArray alloc] init];
    _populationLabels = [[NSMutableArray alloc] init]; // for storing all planet population labels
    _colonyPlanets = [[NSMutableArray alloc]init];  // for keeping array of all the colony planets to use with the labels
    _eventHorizonShapes = [[NSMutableArray alloc]init];
    _suns = [[NSMutableArray alloc]init];

    [self addShipAtPosition:CGPointMake(self.size.width/2,self.size.height/2-100) withSize:CGSizeMake(16,16) withDensity:1.0]; //adds ship at center
    [self addAsteroidAtPosition:CGPointMake(100, 100) withSize:CGSizeMake(16, 16)];
    [self addAsteroidAtPosition:CGPointMake(250, 200) withSize:CGSizeMake(24, 24)];
    [self addAsteroidAtPosition:CGPointMake(280, 350) withSize:CGSizeMake(32, 32)];
    [self addBlueSunAtPosition:CGPointMake(100, 400) withSize:CGSizeMake(24, 24)];
    [self addSunAtPosition:CGPointMake(190, 330) withSize:CGSizeMake(100, 100)];
    [self addColonyPlanetAtPosition:CGPointMake(50, 200) withSize: CGSizeMake(24,24)];
    [self addColonyPlanetAtPosition:CGPointMake(250, 500) withSize: CGSizeMake(48,48)];
    [self addBlackHoleAtPosition:CGPointMake(50, 470) withSize:CGSizeMake(12, 12)];
    [self addBlackHoleAtPosition:CGPointMake(280, 40) withSize:CGSizeMake(8, 8)];
    //[self addSunAtPosition:CGPointMake(50, 470) withSize:CGSizeMake(48, 48)];
    
    SKSpriteNode * _vignette = [SKSpriteNode spriteNodeWithImageNamed:@"vignette"];
    _vignette.position = CGPointMake(self.size.width/2, self.size.height/2);
    _vignette.size = CGSizeMake(self.size.width, self.size.height);
    [_gameNode addChild:_vignette];
    
    //NSLog(@"array objects: %@", [self getObjectsOfName:@"blackHole" inNode:self]);
}

//______________________________________________________________________________________________________________
//|                                                                                                            |
//|                                                                                                            |
//|                                           CREATE GAME OBJECTS                                              |
//|                                                                                                            |
//|____________________________________________________________________________________________________________|

- (void) addShipAtPosition:(CGPoint)pos withSize:(CGSize)size withDensity:(CGFloat)density
{
    _shipNode = [SKSpriteNode spriteNodeWithImageNamed:@"earth"];
    _shipNode.name = @"earth";
    _shipNode.position = pos;
    _shipNode.size = size;
    
    [_gameNode addChild:_shipNode];
    
    _shipNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:size.width/2 ];
    _shipNode.physicsBody.linearDamping = 0.9;
    _shipNode.physicsBody.angularDamping = 0.9;
    _shipNode.physicsBody.categoryBitMask = PhysicsCategoryShip;
    _shipNode.physicsBody.contactTestBitMask = PhysicsCategoryColony | PhysicsCategoryControlColony | PhysicsCategoryBlackHole | PhysicsCategoryAsteroid | PhysicsCategorySun;
    _shipNode.physicsBody.density = density;
    
    _shipNode.userData = [[NSMutableDictionary alloc] init];
    [_shipNode.userData setObject:[NSNumber numberWithInt:size.width*10] forKey:@"maxPopulation"];
    [_shipNode.userData setObject:[NSNumber numberWithInt:size.width*5] forKey:@"population"];
    [_shipNode.userData setObject:[NSNumber numberWithBool:YES] forKey:@"canControl"];
    [_shipNode.userData setObject:[NSNumber numberWithInt:30] forKey:@"controlReturnCount"];
    [_shipNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isHot"];
    [_shipNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isCold"];

    //NSLog(@"population = %@", [_shipNode.userData valueForKey:@"population"]);
    //NSLog(@"earth population (by starting userData)= %i", [_shipNode.userData[@"population"] intValue]);
    
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
    
    _colonyPlanetNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:size.width/2];
    _colonyPlanetNode.physicsBody.linearDamping = 0.9;
    _colonyPlanetNode.physicsBody.angularDamping = 0.9;
    _colonyPlanetNode.physicsBody.categoryBitMask = PhysicsCategoryColony;
    _colonyPlanetNode.physicsBody.contactTestBitMask = PhysicsCategoryShip | PhysicsCategoryColony | PhysicsCategoryControlColony | PhysicsCategoryBlackHole | PhysicsCategoryAsteroid | PhysicsCategorySun;

    _colonyPlanetNode.userData = [[NSMutableDictionary alloc] init];
    [_colonyPlanetNode.userData setObject:[NSNumber numberWithInt:size.width*10] forKey:@"maxPopulation"];
    [_colonyPlanetNode.userData setObject:[NSNumber numberWithInt:0] forKey:@"population"];
    [_colonyPlanetNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
    [_colonyPlanetNode.userData setObject:[NSNumber numberWithInt:30] forKey:@"controlReturnCount"];
    [_colonyPlanetNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isHot"];
    [_colonyPlanetNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isCold"];
    
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
    
    _asteroidNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius: (size.width/2)];
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
    
    _sunNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius: size.width/2 ];
    _sunNode.physicsBody.dynamic = NO;
    _sunNode.physicsBody.categoryBitMask = PhysicsCategorySun;
    _sunNode.physicsBody.contactTestBitMask = PhysicsCategoryControlColony | PhysicsCategoryColony | PhysicsCategoryAsteroid;
    
    float eventHoriz = size.width * 3;
    float maxSize = size.width * 3;
    float hotZone = size.width * 2;
    float coldZone = size.width * 5;
    
    _sunNode.userData = [[NSMutableDictionary alloc] init];
    [_sunNode.userData setObject:[NSNumber numberWithInt:eventHoriz] forKey:@"eventHorizon"];
    [_sunNode.userData setObject:[NSNumber numberWithInt:maxSize] forKey:@"maxSize"];
    [_sunNode.userData setObject:[NSNumber numberWithInt:hotZone] forKey:@"hotZone"];
    [_sunNode.userData setObject:[NSNumber numberWithInt:coldZone] forKey:@"coldZone"];
    
    //CERTAIN KINDS OF SUNS GROW WHEN THEY SWALLOW MASS? THEY CAN BECOME A BLACK HOLE OR EXPLODE?
    //will need to have a 'resting state?' or natural lifecycle?
    
    /*CGRect eventHorizCircle = CGRectMake(pos.x - (eventHoriz/2), pos.y - (eventHoriz/2), eventHoriz, eventHoriz);
    SKShapeNode *eventHorizShapeNode = [[SKShapeNode alloc] init];
    eventHorizShapeNode.path = [UIBezierPath bezierPathWithOvalInRect:eventHorizCircle].CGPath;
    eventHorizShapeNode.fillColor = nil;
    eventHorizShapeNode.strokeColor = [SKColor colorWithRed:1.00 green:1.0 blue:1.0 alpha:0.5];
    eventHorizShapeNode.antialiased = NO;
    eventHorizShapeNode.lineWidth = 0.8;
    [self addChild:eventHorizShapeNode];
    [_eventHorizonShapes addObject:eventHorizShapeNode]; */
    
    CGRect hotZoneCircle = CGRectMake(pos.x - (hotZone/2), pos.y - (hotZone/2), hotZone, hotZone);
    SKShapeNode *hotZoneShapeNode = [[SKShapeNode alloc] init];
    hotZoneCircle = CGRectMake(pos.x - (hotZone/2), pos.y - (hotZone/2), hotZone, hotZone);
    hotZoneShapeNode.path = [UIBezierPath bezierPathWithOvalInRect:hotZoneCircle].CGPath;
    hotZoneShapeNode.fillColor = nil;
    hotZoneShapeNode.strokeColor = [SKColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
    hotZoneShapeNode.antialiased = NO;
    hotZoneShapeNode.lineWidth = 1;
    [self addChild:hotZoneShapeNode];
    
    CGRect coldZoneCircle = CGRectMake(pos.x - (coldZone/2), pos.y - (coldZone/2), coldZone, coldZone);
    SKShapeNode *coldZoneShapeNode = [[SKShapeNode alloc] init];
    coldZoneCircle = CGRectMake(pos.x - (coldZone/2), pos.y - (coldZone/2), coldZone, coldZone);
    coldZoneShapeNode.path = [UIBezierPath bezierPathWithOvalInRect:coldZoneCircle].CGPath;
    coldZoneShapeNode.fillColor = nil;
    coldZoneShapeNode.strokeColor = [SKColor colorWithRed:0.00 green:0.0 blue:1.0 alpha:0.5];//SKColor.blueColor;
    coldZoneShapeNode.antialiased = NO;
    coldZoneShapeNode.lineWidth = 1;
    [self addChild:coldZoneShapeNode];
    
    [_suns addObject:_sunNode];
}

- (void) addBlueSunAtPosition:(CGPoint)pos withSize:(CGSize)size
{
    _blueSunNode = [SKSpriteNode spriteNodeWithImageNamed:@"blueSun"];
    _blueSunNode.name = @"blueSun";
    _blueSunNode.position = pos;
    _blueSunNode.size = size;
    
    [_gameNode addChild:_blueSunNode];
    
    _blueSunNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius: size.width/2 ];
    _blueSunNode.physicsBody.dynamic = NO;
}

- (void) addBlackHoleAtPosition:(CGPoint)pos withSize:(CGSize)size
{
    _blackHoleNode = [SKSpriteNode spriteNodeWithImageNamed:@"alienPlanet"];
    _blackHoleNode.name = @"blackHole";
    _blackHoleNode.position = pos;
    _blackHoleNode.size = size;
    SKAction *action = [SKAction rotateByAngle:M_PI duration:0.3];
    [_blackHoleNode runAction:[SKAction repeatActionForever:action]];
    [_gameNode addChild:_blackHoleNode];
    
    float eventHoriz = size.width * 30;
    _blackHoleNode.userData = [[NSMutableDictionary alloc] init];
    [_blackHoleNode.userData setObject:[NSNumber numberWithInt:eventHoriz] forKey:@"eventHorizon"];
    
    _blackHoleNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius: size.width/2 ];
    _blackHoleNode.physicsBody.dynamic = NO;
    _blackHoleNode.physicsBody.categoryBitMask = PhysicsCategoryBlackHole;
    [_blackHoleLoc addObject:[NSValue valueWithCGPoint:pos]];
    
    CGRect eventHorizCircle = CGRectMake(pos.x - (eventHoriz/2), pos.y - (eventHoriz/2), eventHoriz, eventHoriz);
    SKShapeNode *eventHorizShapeNode = [[SKShapeNode alloc] init];
    eventHorizShapeNode.path = [UIBezierPath bezierPathWithOvalInRect:eventHorizCircle].CGPath;
    eventHorizShapeNode.fillColor = nil;
    eventHorizShapeNode.strokeColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
    eventHorizShapeNode.antialiased = NO;
    eventHorizShapeNode.lineWidth = 1;
    [self addChild:eventHorizShapeNode];
    [_eventHorizonShapes addObject:eventHorizShapeNode];
}


//______________________________________________________________________________________________________________
//|                                                                                                            |
//|                                                                                                            |
//|                                               TOUCHES BEGAN                                                |
//|                                                                                                            |
//|____________________________________________________________________________________________________________|

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    /* Called when a touch begins */
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        _touchLocation = location;
        _swipeCounter = 0;
        //NSLog(@"touch location: %@", NSStringFromCGPoint(_touchLocation));
    }
}


//______________________________________________________________________________________________________________
//|                                                                                                            |
//|                                                                                                            |
//|                                               TOUCHES MOVED                                                |
//|                                                                                                            |
//|____________________________________________________________________________________________________________|

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *) event
{
    //if (_swipeCounter < 10) {
    _swipeCounter++;
    //_fuel -= 1;
    //NSLog(@"%i", _swipeCounter);
    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        _releaseLocation = location;
        _newX = (_releaseLocation.x - _touchLocation.x) * 0.04;//(_swipeCounter * 0.0001);
        _newY = (_releaseLocation.y - _touchLocation.y) * 0.04;//(_swipeCounter * 0.0001);
        
        //______________________________________________________________________________________________________________
        //|                                                                                                            |
        //|                                      MOVE EARTH                                                            |
        //|____________________________________________________________________________________________________________|
        
        if ( [_shipNode.userData[@"canControl"] boolValue] == YES ) {
            if ( [_shipNode.userData[@"population"] intValue] > 0 ) {
                [_shipNode.physicsBody applyForce: CGVectorMake(_newX, _newY)];
                int newPop = [_shipNode.userData[@"population"] intValue];
                newPop -= 4;//change based on speed?
                [_shipNode.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
            } else {
                [_shipNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
            }
        }

        //______________________________________________________________________________________________________________
        //|                                                                                                            |
        //|                                MOVE CONTROL COLONIES                                                       |
        //|____________________________________________________________________________________________________________|
        
        [_gameNode enumerateChildNodesWithName:@"controlColony" usingBlock:^(SKNode *node, BOOL *stop) {
            if ( [node.userData[@"canControl"] boolValue] == YES ) {
                if ([node.userData[@"population"] intValue] > 0 ) {
                    [node.physicsBody applyForce: CGVectorMake(_newX, _newY)];
                    int newPop = [node.userData[@"population"] intValue];
                    newPop -= 4;
                    //NSLog(@"colony population = %i", [node.userData[@"population"] intValue]);
                    //node.userData = [@{@"population":@(newPop)} mutableCopy];
                    [node.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
                } else {
                    [node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
                    //int newPop = [node.userData[@"population"] intValue];
                    //newPop = -20;
                    //[node.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
                }
            }
         }];
        
//        [_gameNode enumerateChildNodesWithName:@"sun" usingBlock:^(SKNode *node, BOOL *stop) {
//            [node.physicsBody applyForce: CGVectorMake(_newX, _newY)];
//        }];  this was used to test update of eventhorizon zones on suns. still need to set sun dynamics to true to make it work.
    }
}


//______________________________________________________________________________________________________________
//|                                                                                                            |
//|                                                                                                            |
//|                                               TOUCHES ENDED                                                |
//|                                                                                                            |
//|____________________________________________________________________________________________________________|

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"array objects: %@", _blackHoleLoc);
}

//______________________________________________________________________________________________________________
//|                                                                                                            |
//|                                                                                                            |
//|                                               UPDATE LOOP                                                  |
//|                                                                                                            |
//|____________________________________________________________________________________________________________|

-(void)update:(CFTimeInterval)currentTime   /* Called before each frame is rendered */
{
    //______________________________________________________________________________________________________________
    //|                                                                                                            |
    //|                        get all blackhole positions and sizes to use for forces                             |
    //|____________________________________________________________________________________________________________|
    
    _newBlackHoleLoc = [[NSMutableArray alloc]init];    //THIS IS WEIRD. WHAT DOES IT MEAN THAT I'M REINITIALIZING THIS?
    [_gameNode enumerateChildNodesWithName:@"blackHole" usingBlock:^(SKNode *node, BOOL *stop) {
        [_newBlackHoleLoc addObject: [NSValue valueWithCGPoint:node.position]];
    }];
    //NSLog(@"array objects: %@", newArray);
    _blackHoleLoc = _newBlackHoleLoc;
    
    [_gameNode enumerateChildNodesWithName:@"blackHole" usingBlock:^(SKNode *node, BOOL *stop) {
        [_newBlackHoleSize addObject: [NSNumber numberWithFloat:node.frame.size.width]];
    }];
    
    
    for (SKSpriteNode * node in _gameNode.children)
    {
        //______________________________________________________________________________________________________________
        //|                                                                                                            |
        //|                           move control colonies and earth towards black holes                              |
        //|____________________________________________________________________________________________________________|
        
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
        //______________________________________________________________________________________________________________
        //|                                                                                                            |
        //|                                 burn up population if too close to sun                                     |
        //|____________________________________________________________________________________________________________|
        
        if (node.physicsBody.categoryBitMask == PhysicsCategoryControlColony | node.physicsBody.categoryBitMask == PhysicsCategoryShip) {
            for (int i = 0; i < [_suns count]; i++) {
                SKSpriteNode * thisSun = _suns[i];
                CGPoint point = thisSun.position;
                CGPoint offset = CGPointMake(point.x - node.position.x, point.y - node.position.y);
                CGFloat length = sqrtf(offset.x * offset.x + offset.y * offset.y);
                if (length < [thisSun.userData[@"hotZone"] intValue]/2) {
                    int newPop = [node.userData[@"population"] intValue];
                    newPop -= 1;
                    [node.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
                    [node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"isHot"];
                }
                else {
                    [node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isHot"];
                }
                if ([_suns count] == 1) {  //more than one cold zone overlapping hot zones doesn't make sense........
                    if (length > [thisSun.userData[@"coldZone"] intValue]/2) {
                        int newPop = [node.userData[@"population"] intValue];
                        newPop -= 1;
                        [node.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
                        [node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"isCold"];
                    }
                    else {
                        [node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isCold"];
                    }
                }
            }
            if ( [node.userData[@"isHot"] boolValue] == YES) {
                node.colorBlendFactor = 0.5;
                node.color = [SKColor redColor];
            }
            else if ([node.userData[@"isCold"] boolValue] == YES) {
                node.colorBlendFactor = 0.5;
                node.color = [SKColor blueColor];
            }
            else {
                node.colorBlendFactor = 0.0;
                node.color = nil;
            }
        }
    }
    
    //______________________________________________________________________________________________________________
    //|                                                                                                            |
    //|                                 REGENERATE POPULATION if EARTH can be controlled                           |
    //|____________________________________________________________________________________________________________|
    
    if ( [_shipNode.userData[@"canControl"] boolValue] == YES )
    {
        if ( [_shipNode.userData[@"population"] intValue] < [_shipNode.userData[@"maxPopulation"] intValue] ) {
            int newPop = [_shipNode.userData[@"population"] intValue];
            newPop += 1;
            [_shipNode.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
        }
    }
    //______________________________________________________________________________________________________________
    //|                                                                                                            |
    //|                                 or count down the timer until it can be controlled again                   |
    //|____________________________________________________________________________________________________________|
    else
    { //if ( [_shipNode.userData[@"canControl"] boolValue] == NO ) {
        if ( [_shipNode.userData[@"controlReturnCount"] intValue] > 0 ) {
            int newCount = [_shipNode.userData[@"controlReturnCount"] intValue];
            newCount --;
            //NSLog(@"control return count = %i", [_shipNode.userData[@"controlReturnCount"] intValue]);
            [_shipNode.userData setObject:[NSNumber numberWithInt:newCount] forKey:@"controlReturnCount"];
        } else {
            [_shipNode.userData setObject:[NSNumber numberWithBool:YES] forKey:@"canControl"];
            [_shipNode.userData setObject:[NSNumber numberWithInt:30] forKey:@"controlReturnCount"];
            //NSLog(@"control returned");
        }
    }
    
    //______________________________________________________________________________________________________________
    //|                                                                                                            |
    //|                                REGENERATE POPULATION if COLONY can be controlled                           |
    //|____________________________________________________________________________________________________________|
    
    [_gameNode enumerateChildNodesWithName:@"controlColony" usingBlock:^(SKNode *node, BOOL *stop) {
        if ( [node.userData[@"canControl"] boolValue] == YES) {
            if (([node.userData[@"population"] intValue] < [node.userData[@"maxPopulation"] intValue] )     ) {  //comment these two out if below
                //   && ([node.userData[@"population"] intValue] >= 0 )){  //for testing no regeneration if below 0?  //SEE BELOW RE. NEW TYPE
                int newPop = [node.userData[@"population"] intValue];
                newPop += 1;
                [node.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
            }
        //______________________________________________________________________________________________________________
        //|                                 or count down the timer until it can be controlled again                   |
        //|____________________________________________________________________________________________________________|
        } else { //if ( [node.userData[@"canControl"] boolValue] == NO ) {
            if ( [node.userData[@"controlReturnCount"] intValue] > 0 ) {
                int newCount = [node.userData[@"controlReturnCount"] intValue];
                newCount --;
                //NSLog(@"control return count = %i", [node.userData[@"controlReturnCount"] intValue]);
                [node.userData setObject:[NSNumber numberWithInt:newCount] forKey:@"controlReturnCount"];
            } else {
                [node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"canControl"];
                [node.userData setObject:[NSNumber numberWithInt:30] forKey:@"controlReturnCount"];
                //NSLog(@"colony planet control returned");
            }
        }
         //MAYBE KEEP THE NO-REGEN PERIOD THING FOR ANOTHER TYPE OF COLONY.
    }];

    //______________________________________________________________________________________________________________
    //|                                                                                                            |
    //|                                 REPLACE EARTH POPULATION LABEL text value                                  |
    //|____________________________________________________________________________________________________________|
    
    _earthPopulationLabel.text = [NSString stringWithFormat:@"%i", [_shipNode.userData[@"population"] intValue] ];
    
    //______________________________________________________________________________________________________________
    //|                                                                                                            |
    //|                                REPLACE COLONY POPULATION LABEL text value                                  |
    //|____________________________________________________________________________________________________________|
    
    for (int i = 0; i < [_populationLabels count]; i++)  // get all population labels
    {
        SKLabelNode * label = _populationLabels[i];   // make a new label equal to existing label  //KILL THESE NEW INITIALIZATIONS WITH A PRIVATE VAR?
        SKSpriteNode * newColony = _colonyPlanets[i];  //make a new colony planet equal to existing planet
        label.text = [NSString stringWithFormat:@"%i", [newColony.userData[@"population"] intValue]];  // replace label text of new label
        _populationLabels[i] = label;   //replace the old label with the new label
    }
    
    /*
    //--------------------------------------------------------------------------------------------------------------------
    //BELOW IS TO MAKE THE EVENT HORIZON GROW WHEN THE SUN CHANGES SHAPE, ETC.
    //--------------------------------------------------------------------------------------------------------------------
    for (int i = 0; i <[_eventHorizonShapes count]; i++) {
        SKShapeNode * currentShape = _eventHorizonShapes[i];
        SKSpriteNode * newSun = _suns[i];
        float newEventHoriz = newSun.size.width * 3;        //THIS IS THE PROBLEM- THE SIZE VALUE ISN'T BEING CHANGED, JUST THE SCALE THROUGH AN SKACTION
        CGPoint newPos = newSun.position;
        newEventHoriz = [newSun.userData[@"eventHorizon"] intValue]; //ALSO THE NEW VALUE WILL NEED TO GET CYCLED BACK INTO THE USER DATA KEY IN ORDER TO READ IT ELSEWHERE (FOR DETECTIONS ETC

        CGRect circle = CGRectMake(newPos.x - (newEventHoriz/2), newSun.position.y - (newEventHoriz/2), newEventHoriz, newEventHoriz);
        currentShape.path = [UIBezierPath bezierPathWithOvalInRect:circle].CGPath;
        currentShape.fillColor = nil;
        currentShape.strokeColor = SKColor.whiteColor;
        currentShape.antialiased = NO;
        currentShape.lineWidth = 0.8;
        _eventHorizonShapes[i] = currentShape;
    }
    //DO MORE FOR THE HOT ZONE AND COLD ZONE ONCE IT IS WORKING  */
}

//______________________________________________________________________________________________________________
//|                                                                                                            |
//|                                                                                                            |
//|                                           DID SIMULATE PHYSICS                                             |
//|                                                                                                            |
//|____________________________________________________________________________________________________________|

- (void)didSimulatePhysics  /* called just after physics get simulated */
{
    //_newX = 0;
    //_newY = 0;
    //_velocity = _shipNode.physicsBody.velocity;
}


//______________________________________________________________________________________________________________
//|                                                                                                            |
//|                                                                                                            |
//|                                             COLLISION LOOP                                                 |
//|                                                                                                            |
//|____________________________________________________________________________________________________________|

- (void)didBeginContact:(SKPhysicsContact *) contact
{
    uint32_t collision = (contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask);
    
    if (collision == ( PhysicsCategoryShip | PhysicsCategorySun) ) {
        NSLog(@"earth destruction");
        [contact.bodyA.node removeFromParent];
        NSLog(@"sun grows");
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
    
    else if (collision == (PhysicsCategorySun | PhysicsCategoryControlColony) | collision == (PhysicsCategorySun | PhysicsCategoryColony))
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
        int earthNewPop = [_shipNode.userData[@"population"] intValue];
        earthNewPop -= 20;
        [_shipNode.userData setObject:[NSNumber numberWithInt:earthNewPop] forKey:@"population"];
        int colonyNewPop = [_shipNode.userData[@"population"] intValue];
        colonyNewPop = 10;
        [contact.bodyB.node.userData setObject:[NSNumber numberWithInt:colonyNewPop] forKey:@"population"];
    }
    
    //asteroid reducing population after impact
    else if (collision == (PhysicsCategoryShip | PhysicsCategoryAsteroid))
    {
        int newPop = [_shipNode.userData[@"population"] intValue];
        newPop -= 20;
        [_shipNode.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
        NSLog(@"Earth contact with asteroid");
    }
    
    //asteroid reducing population after impact
    else if (collision == (PhysicsCategoryControlColony | PhysicsCategoryAsteroid))
    {
        int newPop = [contact.bodyA.node.userData[@"population"] intValue];
        newPop -= 20;
        [contact.bodyA.node.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
        NSLog(@"Colony contact with asteroid");
    }
    
    //Colony turning into control colony
    else if (collision == (PhysicsCategoryControlColony | PhysicsCategoryColony))
    {
        contact.bodyB.categoryBitMask = PhysicsCategoryControlColony;
        contact.bodyA.categoryBitMask = PhysicsCategoryControlColony;
        NSLog(@"New colony");
        contact.bodyB.node.name = @"controlColony";
        contact.bodyA.node.name = @"controlColony";
        [contact.bodyB.node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"canControl"];
        [contact.bodyA.node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"canControl"];
    }
    
    //black hole force explosion and disappear
    else if ( (collision == (PhysicsCategoryShip | PhysicsCategoryBlackHole)) | (collision == (PhysicsCategoryControlColony | PhysicsCategoryBlackHole)) | (collision == (PhysicsCategoryAsteroid | PhysicsCategoryBlackHole)) )
    {
        NSLog(@"black hole explode");
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
