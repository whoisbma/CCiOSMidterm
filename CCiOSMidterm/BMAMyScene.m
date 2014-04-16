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

//asteroids catch on fire?

//no movement when any controlled object at edge of screen?
//or... wrap screen?!??

//GAS PLANETS can turn into suns?

//certain hospitable planets do not regenerate if population drops below zero? or regenerate at ALL? (use alien planet sprite)

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
    
    int _currentLevel;
    int _swipeCounter;
    float _newX;
    float _newY;
    //int _timer;
    int _totalPopulation;
    int _levelGoal;
    bool _levelOver;
    
    CGPoint _touchLocation;
    CGPoint _releaseLocation;
    CGVector _velocity;
    
    NSMutableArray *_blackHoles;
    NSMutableArray *_newBlackHoles;
    
    SKLabelNode *_earthPopulationLabel;
//    SKLabelNode *_levelGoalLabel;

    NSMutableArray *_populationLabels;
    NSMutableArray *_colonyPlanets;
    NSMutableArray *_eventHorizonShapes;
    NSMutableArray *_suns;
    //will need new arrays for:
    NSMutableArray *_hotZoneShapes;
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
    
    _blackHoles = [[NSMutableArray alloc] init];
    _populationLabels = [[NSMutableArray alloc] init]; // for storing all planet population labels
    _colonyPlanets = [[NSMutableArray alloc]init];  // for keeping array of all the colony planets to use with the labels
    _eventHorizonShapes = [[NSMutableArray alloc]init];
    _hotZoneShapes = [[NSMutableArray alloc]init];
    _suns = [[NSMutableArray alloc]init];
    
    _currentLevel = 1;
    [self setupLevel: _currentLevel];
}

//______________________________________________________________________________________________________________
//|                                                                                                            |
//|                                                                                                            |
//|                                  C R E A T E  G A M E  O B J E C T S                                       |
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
    SKAction *action = [SKAction rotateByAngle:M_PI duration:100];
    [_sunNode runAction:[SKAction repeatActionForever:action]];
    
    _sunNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius: size.width/2 ];
    _sunNode.physicsBody.dynamic = NO;
    _sunNode.physicsBody.categoryBitMask = PhysicsCategorySun;
    _sunNode.physicsBody.contactTestBitMask = PhysicsCategoryControlColony | PhysicsCategoryColony | PhysicsCategoryAsteroid;
    
    float eventHoriz = size.width * 3;
    float maxSize = size.width * 3;
    float hotZoneMax = size.width * 2;
    float coldZone = size.width * 5;
    float hotZoneSize = size.width;
    
    SKSpriteNode * sunGlow = [SKSpriteNode spriteNodeWithImageNamed:@"sun"];
    sunGlow.position = pos;
    sunGlow.size = CGSizeMake(hotZoneMax, hotZoneMax);
    sunGlow.alpha = .1;
    
    [_gameNode addChild:sunGlow];
    [_gameNode addChild:_sunNode];
    
    _sunNode.userData = [[NSMutableDictionary alloc] init];
    [_sunNode.userData setObject:[NSNumber numberWithInt:eventHoriz] forKey:@"eventHorizon"];
    [_sunNode.userData setObject:[NSNumber numberWithInt:maxSize] forKey:@"maxSize"];
    [_sunNode.userData setObject:[NSNumber numberWithInt:hotZoneMax] forKey:@"hotZoneMax"];
    [_sunNode.userData setObject:[NSNumber numberWithInt:hotZoneSize] forKey:@"hotZoneSize"];
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
    [_gameNode addChild:eventHorizShapeNode];
    [_eventHorizonShapes addObject:eventHorizShapeNode]; */
    
    
    
    /*  //this is my attempt to get a ton of shape nodes working for the sun radiation.
     // it displays multiple shape nodes but animating them in update is a multidimensional array mess.............
    
     NSMutableArray *singleSunHotZoneShapeNodes = [[NSMutableArray alloc] init]; //stores all hotZoneShapeNodes for a single sun (10 of them)
    
    for (int i = 0; i < 11; i++) {
        SKShapeNode *hotZoneShapeNode = [[SKShapeNode alloc] init];
        CGRect hotZoneCircle = CGRectMake(pos.x - ((hotZoneSize+i*(size.width/10))/2), pos.y - ((hotZoneSize+i*(size.width/10))/2), hotZoneSize+i*(size.width/10), hotZoneSize+i*(size.width/10));
        hotZoneShapeNode.path = [UIBezierPath bezierPathWithOvalInRect:hotZoneCircle].CGPath;
        hotZoneShapeNode.fillColor = nil;
        hotZoneShapeNode.strokeColor = [SKColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
        hotZoneShapeNode.antialiased = NO;
        hotZoneShapeNode.lineWidth = 1;
        [singleSunHotZoneShapeNodes addObject:hotZoneShapeNode];
        [_gameNode addChild:hotZoneShapeNode];
    }
    [_hotZoneShapes addObject:singleSunHotZoneShapeNodes]; //singleSunHotZoneShapeNodes gets stored in _hotZoneShapes (total shapes for all suns)
    */
    
    
    //works to animate a single shape node
    SKShapeNode *hotZoneShapeNode = [[SKShapeNode alloc] init];
    CGRect hotZoneCircle = CGRectMake(pos.x - hotZoneSize+(size.width)/2, pos.y - hotZoneSize+(size.width/2), hotZoneSize+size.width, hotZoneSize+size.width);
    hotZoneShapeNode.path = [UIBezierPath bezierPathWithOvalInRect:hotZoneCircle].CGPath;
    hotZoneShapeNode.fillColor = nil;
    hotZoneShapeNode.strokeColor = [SKColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
    hotZoneShapeNode.antialiased = NO;
    hotZoneShapeNode.lineWidth = 1;
    [_gameNode addChild:hotZoneShapeNode];
    [_hotZoneShapes addObject:hotZoneShapeNode];
    

    CGRect coldZoneCircle = CGRectMake(pos.x - (coldZone/2), pos.y - (coldZone/2), coldZone, coldZone);
    SKShapeNode *coldZoneShapeNode = [[SKShapeNode alloc] init];
    coldZoneCircle = CGRectMake(pos.x - (coldZone/2), pos.y - (coldZone/2), coldZone, coldZone);
    coldZoneShapeNode.path = [UIBezierPath bezierPathWithOvalInRect:coldZoneCircle].CGPath;
    coldZoneShapeNode.fillColor = nil;
    coldZoneShapeNode.strokeColor = [SKColor colorWithRed:0.00 green:0.0 blue:1.0 alpha:0.5];//SKColor.blueColor;
    coldZoneShapeNode.antialiased = NO;
    coldZoneShapeNode.lineWidth = 1;
    [_gameNode addChild:coldZoneShapeNode];
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
    //[_blackHoleLoc addObject:[NSValue valueWithCGPoint:pos]];
    
    CGRect eventHorizCircle = CGRectMake(pos.x - (eventHoriz/2), pos.y - (eventHoriz/2), eventHoriz, eventHoriz);
    SKShapeNode *eventHorizShapeNode = [[SKShapeNode alloc] init];
    eventHorizShapeNode.path = [UIBezierPath bezierPathWithOvalInRect:eventHorizCircle].CGPath;
    eventHorizShapeNode.fillColor = nil;
    eventHorizShapeNode.strokeColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
    eventHorizShapeNode.antialiased = NO;
    eventHorizShapeNode.lineWidth = 1;
    [_gameNode addChild:eventHorizShapeNode];
    [_eventHorizonShapes addObject:eventHorizShapeNode];
}


//______________________________________________________________________________________________________________
//|                                                                                                            |
//|                                                                                                            |
//|                                          T O U C H E S  B E G A N                                          |
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
//|                                          T O U C H E S  M O V E D                                          |
//|                                                                                                            |
//|____________________________________________________________________________________________________________|

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *) event
{
    //if (_swipeCounter < 10) {
    _swipeCounter++;
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
                
                if (([_shipNode.userData[@"isHot"] boolValue] == NO) && ([_shipNode.userData[@"isCold"] boolValue] == NO)){
                    newPop -= 6;//change based on speed?
                }
                else {
                    newPop -= 1;
                }
                if (newPop < 0) {
                    newPop = 0;
                }
                [_shipNode.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
            } else {
                [_shipNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
            }
        }

        //______________________________________________________________________________________________________________
        //|                                                                                                            |
        //|                                 M O V E  C O N T R O L  C O L O N I E S                                    |
        //|____________________________________________________________________________________________________________|
        
        [_gameNode enumerateChildNodesWithName:@"controlColony" usingBlock:^(SKNode *node, BOOL *stop) {
            if ( [node.userData[@"canControl"] boolValue] == YES ) {
                if ([node.userData[@"population"] intValue] > 0 ) {
                    [node.physicsBody applyForce: CGVectorMake(_newX, _newY)];
                    int newPop = [node.userData[@"population"] intValue];
                    if (([node.userData[@"isHot"] boolValue] == NO) && ([node.userData[@"isCold"] boolValue] == NO)){
                        newPop -= 6;
                    }
                    else {
                        newPop -=1;
                    }
                    if (newPop < 0) {
                        newPop = 0;
                    }
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
//|                                          T O U C H E S  E N D E D                                          |
//|                                                                                                            |
//|____________________________________________________________________________________________________________|

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"array objects: %@", _blackHoleLoc);
}

//______________________________________________________________________________________________________________
//|                                                                                                            |
//|                                                                                                            |
//|                                           U P D A T E  L O O P                                             |
//|                                                                                                            |
//|____________________________________________________________________________________________________________|

-(void)update:(CFTimeInterval)currentTime   /* Called before each frame is rendered */
{
    
    //NSLog(@"can control %d", [_shipNode.userData[@"canControl"]boolValue]);
    
    //______________________________________________________________________________________________________________
    //|                                                                                                            |
    //|                        get all blackhole positions and sizes to use for forces                             |
    //|____________________________________________________________________________________________________________|
    
    _newBlackHoles = [[NSMutableArray alloc]init];
    [_gameNode enumerateChildNodesWithName:@"blackHole" usingBlock:^(SKNode *node, BOOL *stop) {
        [_newBlackHoles addObject:node];
    }];
    _blackHoles = _newBlackHoles;
    for (SKSpriteNode * node in _gameNode.children)
    {
        //______________________________________________________________________________________________________________
        //|                                                                                                            |
        //|                           move control colonies and earth towards black holes                              |
        //|____________________________________________________________________________________________________________|
        
        if (node.physicsBody.categoryBitMask == PhysicsCategoryControlColony | node.physicsBody.categoryBitMask == PhysicsCategoryShip) {
            for (int i = 0; i < [_blackHoles count]; i++) {
                SKSpriteNode * thisBlackHole = _blackHoles[i];
                CGPoint point = thisBlackHole.position;
                CGSize size = thisBlackHole.size;
                CGPoint offset = CGPointMake(point.x - node.position.x, point.y - node.position.y);
                CGFloat length = sqrtf(offset.x * offset.x + offset.y * offset.y);
                CGPoint direction = CGPointMake(offset.x / length, offset.y / length);
                if (length < [thisBlackHole.userData[@"eventHorizon"] intValue]/2) {        //black holes only attract within certain distances
                    [node.physicsBody applyForce: CGVectorMake(direction.x * 0.01 * size.width, direction.y * 0.01 * size.width )];
                }
            }
        
            //______________________________________________________________________________________________________________
            //|                                                                                                            |
            //|                                 burn up population if too close to sun                                     |
            //|____________________________________________________________________________________________________________|
            for (int i = 0; i < [_suns count]; i++) {
                SKSpriteNode * thisSun = _suns[i];
                CGPoint point = thisSun.position;
                CGPoint offset = CGPointMake(point.x - node.position.x, point.y - node.position.y);
                CGFloat length = sqrtf(offset.x * offset.x + offset.y * offset.y);
                if (length < [thisSun.userData[@"hotZoneMax"] intValue]/2) {
                    [node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"isHot"];
                }
                else {
                    [node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isHot"];
                }
                if ([_suns count] == 1) {  //more than one cold zone overlapping hot zones doesn't make sense........
                    if (length > [thisSun.userData[@"coldZone"] intValue]/2) {
                        [node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"isCold"];
                    }
                    else {
                        [node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isCold"];
                    }
                }
            }
            //change colors
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
    
    // get total population after refreshing it
    _totalPopulation = 0;
    
    __block int earthLose = 0;

    int earthPopulation = [_shipNode.userData[@"population"] intValue];
    if (( [_shipNode.userData[@"canControl"] boolValue] == YES )) {
        _totalPopulation += earthPopulation;
    }
    if (([_shipNode.userData[@"canControl"] boolValue] == NO ) && ([_shipNode.userData[@"isHot"]boolValue] == YES)){
        earthLose++;
    }
    
    __block int coloniesLose = 0;
    __block int coloniesNum = 0;
    //this is where my winstate issue arises from....... (update: not sure if i still have issues?)
    [_gameNode enumerateChildNodesWithName:@"controlColony" usingBlock:^(SKNode *node, BOOL *stop) {
        coloniesNum++;
        int colonyPopulation = [node.userData[@"population"] intValue];
        if (( [node.userData[@"canControl"] boolValue] == YES )) {
            _totalPopulation += colonyPopulation;
        }
        if (( [node.userData[@"canControl"] boolValue] == NO ) && ([node.userData[@"isHot"]boolValue] == YES)){
            coloniesLose++;
        }
    }];
    
    //win-state
    if ((_totalPopulation >= _levelGoal) && (_levelOver == NO)) {
        [self win];
        NSLog(@"SUCCESS");
//        _totalPopulation = 999;
        _levelOver = YES;
    }
    
    //lose-state
    if ( (_totalPopulation == 0) && (earthLose > 0) && (coloniesLose == coloniesNum) && (_levelOver == NO) ) {
        [self lose];
        _levelOver = YES;
    }
    
    //______________________________________________________________________________________________________________
    //|                                                                                                            |
    //|                                 REGENERATE POPULATION if EARTH can be controlled                           |
    //|____________________________________________________________________________________________________________|
    
    if ( [_shipNode.userData[@"canControl"] boolValue] == YES )
    {
        if ( [_shipNode.userData[@"population"] intValue] < [_shipNode.userData[@"maxPopulation"] intValue] )  {
            if (([_shipNode.userData[@"isHot"] boolValue] == NO) && ([_shipNode.userData[@"isCold"] boolValue] == NO)){
                int newPop = [_shipNode.userData[@"population"] intValue];
                newPop += 1;
                [_shipNode.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
                //NSLog(@"added population");
            }
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
                if (([node.userData[@"isHot"] boolValue] == NO) && ([node.userData[@"isCold"] boolValue] == NO)){
                    int newPop = [node.userData[@"population"] intValue];
                    newPop += 1;
                    [node.userData setObject:[NSNumber numberWithInt:newPop] forKey:@"population"];
                }
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
    //BELOW IS TO MAKE THE EVENT HORIZON GROW WHEN THE SUN CHANGES SHAPE, ETC.  (would need to add logic for the new black hole approach too)
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
    
    
    
    /* //the attempt to animate an array of shapenodes for each sun. it sort of works but all insane............
    for (int i = 0; i < [_suns count]; i++) {
        SKSpriteNode * newSun = _suns[i];
        CGPoint pos = newSun.position;
        float newHotZone = [newSun.userData[@"hotZoneSize"] floatValue];
        float newHotMax = [newSun.userData[@"hotZoneMax"] floatValue];
        NSMutableArray * newSingleSunHotZoneShapeNodes = [[NSMutableArray alloc] init];
        newSingleSunHotZoneShapeNodes = _hotZoneShapes[i];
        for (int j = 0; j < [newSingleSunHotZoneShapeNodes count]; j++) {
            SKShapeNode * newShape = newSingleSunHotZoneShapeNodes[j];
            
            int newHotZoneInt = (int) newHotZone;
            int newHotMaxInt = (int) newHotMax;
        
            if (newHotZoneInt < newHotMaxInt) {//[newSun.userData[@"hotZoneMax"]floatValue]) {
            newHotZone +=10;
                [newSun.userData setObject:[NSNumber numberWithInt:newHotZone] forKey:@"hotZoneSize"];
            }
            else {
                //NSLog(@"here's the old size- %f", [newSun.userData[@"hotZoneSize"]floatValue]);
                [newSun.userData setObject:[NSNumber numberWithFloat:newSun.size.width] forKey:@"hotZoneSize"];
                //NSLog(@"here should be the new size - %f", [newSun.userData[@"hotZoneSize"]floatValue]);
            }
            CGRect hotZoneCircle = CGRectMake(pos.x - ((newHotZone+j*(newSun.size.width/10))/2), pos.y - ((newHotZone+j*(newSun.size.width/10))/2), newHotZone+j*(newSun.size.width/10), newHotZone+j*(newSun.size.width/10));
            newShape.path = [UIBezierPath bezierPathWithOvalInRect:hotZoneCircle].CGPath;
            newShape.fillColor = nil;
            newShape.strokeColor = [SKColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
            newShape.antialiased = NO;
            newShape.lineWidth = 1;
            newSingleSunHotZoneShapeNodes[j] = newShape;
        }
        _hotZoneShapes[i] = newSingleSunHotZoneShapeNodes;
        _suns[i] = newSun;
    }*/
    
    //animates a single sun shape node
    for (int i = 0; i < [_suns count]; i++) {
        SKShapeNode * newShape = _hotZoneShapes[i];
        SKSpriteNode * newSun = _suns[i];
        CGPoint pos = newSun.position;
        float newHotZone = [newSun.userData[@"hotZoneSize"] floatValue];
        float newHotMax = [newSun.userData[@"hotZoneMax"] floatValue];
        //NSLog(@"incrementing hot zone size - %f", [newSun.userData[@"hotZoneSize"]floatValue]);
        //NSLog(@"new hot zone: %f", newHotZone);
        //NSLog(@"hot zone max: %f", [newSun.userData[@"HotZoneMax"]floatValue]);
        //if ([newSun.userData[@"HotZoneGrow"]boolValue] == YES) {  ///NEED TO ADD THIS DICTIONARY KEY
        
        int newHotZoneInt = (int) newHotZone;
        int newHotMaxInt = (int) newHotMax;
        
        if (newHotZoneInt < newHotMaxInt+3) {//[newSun.userData[@"hotZoneMax"]floatValue]) {
            newHotZone += (newHotMax -newHotZone+25) * .05;
            [newSun.userData setObject:[NSNumber numberWithInt:newHotZone] forKey:@"hotZoneSize"];
        }
        else {
            //NSLog(@"here's the old size- %f", [newSun.userData[@"hotZoneSize"]floatValue]);
            [newSun.userData setObject:[NSNumber numberWithFloat:newSun.size.width] forKey:@"hotZoneSize"];
            //NSLog(@"here should be the new size - %f", [newSun.userData[@"hotZoneSize"]floatValue]);
        }
        CGRect hotZoneCircle = CGRectMake(pos.x - (newHotZone/2), pos.y - (newHotZone/2), newHotZone, newHotZone);
        hotZoneCircle = CGRectMake(pos.x - (newHotZone/2), pos.y - (newHotZone/2), newHotZone, newHotZone);
        newShape.path = [UIBezierPath bezierPathWithOvalInRect:hotZoneCircle].CGPath;
        newShape.fillColor = nil;
        newShape.strokeColor = [SKColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1];
        newShape.antialiased = NO;
        newShape.lineWidth = 1;
        newShape.alpha = 0.5;
        _hotZoneShapes[i] = newShape;
        _suns[i] = newSun;
    }
}

//______________________________________________________________________________________________________________
//|                                                                                                            |
//|                                                                                                            |
//|                                   D I D  S I M U L A T E  P H Y S I C S                                    |
//|                                                                                                            |
//|____________________________________________________________________________________________________________|

- (void)didSimulatePhysics  /* called just after physics get simulated */
{

    
}


//______________________________________________________________________________________________________________
//|                                                                                                            |
//|                                                                                                            |
//|                                        C O L L I S I O N  L O O P                                          |
//|                                                                                                            |
//|____________________________________________________________________________________________________________|

- (void)didBeginContact:(SKPhysicsContact *) contact
{
    uint32_t collision = (contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask);
    
    if (collision == ( PhysicsCategoryShip | PhysicsCategorySun) ) {
        NSLog(@"earth destruction");
        if (contact.bodyA.node.physicsBody.categoryBitMask == PhysicsCategoryShip) {
            [contact.bodyA.node removeFromParent];
            [_shipNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
        }
        else if (contact.bodyB.node.physicsBody.categoryBitMask == PhysicsCategoryShip) {
            [contact.bodyB.node removeFromParent];
            [_shipNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
        }
        NSLog(@"sun grows");
        //ENTER MYSTERY CODE HERE! contact.bodyB.node.size is no good.
        //[contact.bodyB.node setScale:2.0];
        CGFloat absorbMass = contact.bodyA.node.frame.size.width * 0.01; //THIS SORT OF WORKS BUT I WANTED MASS
        NSLog(@"width: %f", absorbMass);
        //SKAction *grow = [SKAction scaleTo:1.0+absorbMass duration:3.0]; //THIS ISN'T REALLY WORKING THE WAY I WANT IT TO, ESP WHEN IT STACKS
       // SKAction *wait = [SKAction waitForDuration:5.0];
        //SKAction *shrink = [SKAction scaleTo:1.0-absorbMass/2 duration:10.0]; //MATH ISN'T RIGHT FOR THE SHRINK
        //[contact.bodyB.node runAction:
        //[SKAction sequence:@[grow, wait, shrink]]];
    }
    
    else if (collision == (PhysicsCategorySun | PhysicsCategoryControlColony) | collision == (PhysicsCategorySun | PhysicsCategoryColony))
    {
        NSLog(@"Colony death");
        if (contact.bodyB.node.physicsBody.categoryBitMask == PhysicsCategoryControlColony) {
            [contact.bodyB.node removeFromParent];
            [contact.bodyB.node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
        }
        else if (contact.bodyA.node.physicsBody.categoryBitMask == PhysicsCategoryControlColony) {
            [contact.bodyA.node removeFromParent];
            [contact.bodyA.node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
        }
        //SKAction *grow = [SKAction scaleTo:1.4 duration:3.0];
        //SKAction *wait = [SKAction waitForDuration:10.0];
        //SKAction *shrink = [SKAction scaleTo:1.0 duration:10.0];
        //[contact.bodyA.node runAction:
        //[SKAction sequence:@[grow, wait, shrink]]];
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
        colonyNewPop = 1;
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
            //probably need to add a conditional to take care of the bodyA/bodyB confusion.......
            CGPoint offset = CGPointMake(contact.bodyB.node.position.x - node.position.x, contact.bodyB.node.position.y - node.position.y);
            CGFloat length = sqrtf(offset.x * offset.x + offset.y * offset.y);
            CGPoint direction = CGPointMake(offset.x / length, offset.y / length);
            [node.physicsBody applyImpulse: CGVectorMake(-direction.x * contact.bodyB.node.frame.size.width * 0.3, -direction.y * contact.bodyB.node.frame.size.width * 0.3)];
        }
        if (contact.bodyA.node.physicsBody.categoryBitMask == PhysicsCategoryShip) {
            [contact.bodyA.node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
            [contact.bodyA.node.userData setObject:[NSNumber numberWithInt:0] forKey:@"population"];
        }
        else if (contact.bodyA.node.physicsBody.categoryBitMask == PhysicsCategoryControlColony) {
            [contact.bodyA.node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
            [contact.bodyA.node.userData setObject:[NSNumber numberWithInt:0] forKey:@"population"];
        }
        else if (contact.bodyB.node.physicsBody.categoryBitMask == PhysicsCategoryShip) {
            [contact.bodyB.node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
            [contact.bodyB.node.userData setObject:[NSNumber numberWithInt:0] forKey:@"population"];
        }
        if (contact.bodyB.node.physicsBody.categoryBitMask == PhysicsCategoryControlColony) {
            [contact.bodyB.node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
            [contact.bodyB.node.userData setObject:[NSNumber numberWithInt:0] forKey:@"population"];
        }
        [contact.bodyA.node removeFromParent];
        [contact.bodyB.node removeFromParent];
        [contact.bodyA.node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
        [contact.bodyB.node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
        
        // THE ABOVE IS MY DESPERATE ATTEMPT TO MAKE BLACK HOLES RESULT IN A LEVEL-FAIL STATE .......... :(
    }
    
}

//this needs fixing. win method. currently generates a ton of nodes.
-(void)win
{
    if (_currentLevel < 4) {
        _currentLevel ++;
    }
    NSLog(@"[win]");
    //[_shipNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
    //do the same for colony nodes
    
    [self inGameMessage:@"COMPLETE"];
    
    [self runAction:
     [SKAction sequence:
      @[[SKAction waitForDuration:3.0],
        [SKAction performSelector:@selector(newGame) onTarget:self]]]];
}

-(void)lose
{
    NSLog(@"lose");
    [self inGameMessage:@"EXTINCT"];
    [self runAction:
     [SKAction sequence:
      @[[SKAction waitForDuration:3.0],
        [SKAction performSelector:@selector(newGame) onTarget:self]]]];
}

-(void)newGame
{
    [_gameNode removeAllChildren];  //remove all sprites from _gameNode
    [self setupLevel: _currentLevel];   //load the level configuration and build everything anew
    [self inGameMessage:[NSString stringWithFormat:@"Level %i", _currentLevel]];
}

//this is just a temporary method for displaying text, it will need some tuning
- (void)inGameMessage:(NSString*)text
{
    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Regular"];
    label.text = text;
    label.fontSize = 60.0;
    label.fontColor = [SKColor whiteColor];
    label.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    [_gameNode addChild:label];
    [label runAction: [SKAction sequence:@[
                                           [SKAction waitForDuration:1.0],
                                           [SKAction removeFromParent]]]];
}

//getting level stuff from the plist
-(void) setupLevel:(int)levelNum
{
    _levelOver = NO;
    NSString *fileName = [NSString stringWithFormat:@"level%i", levelNum];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"plist"];
    NSDictionary *level = [NSDictionary dictionaryWithContentsOfFile:filePath];
    _levelGoal = [(level[@"levelGoal"])intValue];
    _totalPopulation = 0;
    
    SKLabelNode * levelGoalLabel = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Regular"];
    levelGoalLabel.text = [NSString stringWithFormat:@"%d", _levelGoal];
    levelGoalLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    levelGoalLabel.fontSize = 160;
    levelGoalLabel.fontColor = [SKColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
    levelGoalLabel.position = CGPointMake(self.frame.size.width/2, 200);
    [_gameNode addChild:levelGoalLabel];

    if (level[@"earthProperties"]) {
        [self addEarthFromArray:level[@"earthProperties"]];
    }
    
    if (level[@"suns"]) {
        [self addSunsFromArray:level[@"suns"]];
    }
    
    if (level[@"blackHoles"]) {
        [self addBlackHolesFromArray:level[@"blackHoles"]];
    }

    if (level[@"asteroids"]) {
        [self addAsteroidsFromArray:level[@"asteroids"]];
    }
    
    if (level[@"colonies"]) {
        [self addColoniesFromArray:level[@"colonies"]];
    }
    
    NSLog(@"%i", _levelGoal);
    
    SKSpriteNode * _vignette = [SKSpriteNode spriteNodeWithImageNamed:@"vignette"];
    _vignette.position = CGPointMake(self.size.width/2, self.size.height/2);
    _vignette.size = CGSizeMake(self.size.width, self.size.height);
    [_gameNode addChild:_vignette];
}

-(void)addEarthFromArray:(NSArray*)earthProperties
{
    for (NSDictionary *earth in earthProperties) {
        CGSize size = CGSizeFromString(earth[@"size"]);
        CGPoint position = CGPointFromString(earth[@"position"]);
        CGFloat density = [(earth[@"density"])floatValue];
        NSLog(@"addEarthFromArray");
        [self addShipAtPosition:position withSize:size withDensity:density];
    }
}

-(void)addSunsFromArray:(NSArray*)suns
{
    for (NSDictionary *sun in suns) {
        CGSize size = CGSizeFromString(sun[@"size"]);
        CGPoint position = CGPointFromString(sun[@"position"]);
        [self addSunAtPosition:position withSize:size];
        NSLog(@"addSunsFromArray");
    }
}

-(void)addAsteroidsFromArray:(NSArray*)asteroids
{
    for (NSDictionary *asteroid in asteroids) {
        CGSize size = CGSizeFromString(asteroid[@"size"]);
        CGPoint position = CGPointFromString(asteroid[@"position"]);
        [self addAsteroidAtPosition:position withSize:size];
        NSLog(@"addAsteroidsFromArray");
    }
}

-(void)addColoniesFromArray:(NSArray*)colonies
{
    for (NSDictionary *colony in colonies) {
        CGPoint position = CGPointFromString(colony[@"position"]);
        CGSize size = CGSizeFromString(colony[@"size"]);
        [self addColonyPlanetAtPosition:position withSize:size];
        NSLog(@"addColoniesFromArray");
    }
}

-(void)addBlackHolesFromArray:(NSArray*)blackHoles
{
    for (NSDictionary *blackHole in blackHoles) {
        CGPoint position = CGPointFromString(blackHole[@"position"]);
        CGSize size = CGSizeFromString(blackHole[@"size"]);
        [self addBlackHoleAtPosition:position withSize:size];
        NSLog(@"addBlackHolesFromArray");
    }
}

@end
