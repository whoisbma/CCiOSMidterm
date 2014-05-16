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

//add a lose state when the total remaining planets' max population doesn't reach the goal.

//add a delay before losing

//bug - sometimes touching a colony changes population to 1 and colony stays at 0 (might be a collision bug, might be something related to removing old nodes from parents?

//still need to add the lose condition related to total POTENTIAL population

//moving always decreases population? pick up stuff to get more?
//asteroids crash into you and make moons?

//death state is kind of wrong. especially noticeable in the later levels.

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
    int _totalPossiblePopulation;
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
    NSMutableArray *_hotZoneShapes2; //can this possibly be integrated into the first array? 2D array?......
    NSMutableArray *_hotZoneShapes3; //3D?@?!
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
    self.backgroundColor = [SKColor colorWithRed:0 green:0 blue:0 alpha:1.0];
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
    _hotZoneShapes2 = [[NSMutableArray alloc]init]; //blah!..
    _hotZoneShapes3 = [[NSMutableArray alloc]init]; //BLAHHH!..
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
    _shipNode.physicsBody.linearDamping = 0;//0.9;
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
    [_shipNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isDestroyed"];
    
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

- (void) addColonyPlanetAtPosition:(CGPoint)pos withSize:(CGSize)size withDensity:(CGFloat)density withStartingPop:(int)pop
{
    _colonyPlanetNode = [SKSpriteNode spriteNodeWithImageNamed:@"greenPlanet"];
    _colonyPlanetNode.name = @"colonyPlanet";
    _colonyPlanetNode.position = pos;
    _colonyPlanetNode.size = size;
    
    [_gameNode addChild:_colonyPlanetNode];
    
    _colonyPlanetNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:size.width/2];
    _colonyPlanetNode.physicsBody.density = density;
    _colonyPlanetNode.physicsBody.linearDamping = 0;//0.9;
    _colonyPlanetNode.physicsBody.angularDamping = 0.9;
    _colonyPlanetNode.physicsBody.categoryBitMask = PhysicsCategoryColony;
    _colonyPlanetNode.physicsBody.contactTestBitMask = PhysicsCategoryShip | PhysicsCategoryColony | PhysicsCategoryControlColony | PhysicsCategoryBlackHole | PhysicsCategoryAsteroid | PhysicsCategorySun;

    _colonyPlanetNode.userData = [[NSMutableDictionary alloc] init];
    [_colonyPlanetNode.userData setObject:[NSNumber numberWithInt:size.width*10] forKey:@"maxPopulation"];
    [_colonyPlanetNode.userData setObject:[NSNumber numberWithInt:pop] forKey:@"population"];
    [_colonyPlanetNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
    [_colonyPlanetNode.userData setObject:[NSNumber numberWithInt:30] forKey:@"controlReturnCount"];
    [_colonyPlanetNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isHot"];
    [_colonyPlanetNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isCold"];
    [_colonyPlanetNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isDestroyed"];
    
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
    
    _asteroidNode.userData = [[NSMutableDictionary alloc] init];

    [_asteroidNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isHot"];
    
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
    float hotZoneSize2 = size.width + size.width/2;
    float hotZoneSize3 = size.width + size.width/4;
//    
//    SKSpriteNode * sunGlow = [SKSpriteNode spriteNodeWithImageNamed:@"sun"];
//    sunGlow.position = pos;
//    sunGlow.size = CGSizeMake(hotZoneMax, hotZoneMax);
//    sunGlow.alpha = .05;
    //disabled the glow
 //   [_gameNode addChild:sunGlow];
    [_gameNode addChild:_sunNode];
    
    _sunNode.userData = [[NSMutableDictionary alloc] init];
    [_sunNode.userData setObject:[NSNumber numberWithInt:eventHoriz] forKey:@"eventHorizon"];
    [_sunNode.userData setObject:[NSNumber numberWithInt:maxSize] forKey:@"maxSize"];
    [_sunNode.userData setObject:[NSNumber numberWithInt:hotZoneMax] forKey:@"hotZoneMax"];
    [_sunNode.userData setObject:[NSNumber numberWithInt:hotZoneSize] forKey:@"hotZoneSize"];
        [_sunNode.userData setObject:[NSNumber numberWithInt:hotZoneSize2] forKey:@"hotZoneSize2"];
        [_sunNode.userData setObject:[NSNumber numberWithInt:hotZoneSize3] forKey:@"hotZoneSize3"];     ///ARGHHHHH
    [_sunNode.userData setObject:[NSNumber numberWithInt:coldZone] forKey:@"coldZone"];
    
    //CERTAIN KINDS OF SUNS GROW WHEN THEY SWALLOW MASS? THEY CAN BECOME A BLACK HOLE OR EXPLODE?
    //will need to have a 'resting state?' or natural lifecycle?

    
    
    
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
    
    SKShapeNode *hotZoneShapeNode2 = [[SKShapeNode alloc] init];
    CGRect hotZoneCircle2 = CGRectMake(pos.x - hotZoneSize2/2, pos.y - hotZoneSize2/2, hotZoneSize2, hotZoneSize2);
    hotZoneShapeNode2.path = [UIBezierPath bezierPathWithOvalInRect:hotZoneCircle2].CGPath;
    hotZoneShapeNode2.fillColor = nil;
    hotZoneShapeNode2.strokeColor = [SKColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
    hotZoneShapeNode2.antialiased = NO;
    hotZoneShapeNode2.lineWidth = 1;
    [_gameNode addChild:hotZoneShapeNode2];
    
    [_hotZoneShapes2 addObject:hotZoneShapeNode2];
    
    SKShapeNode *hotZoneShapeNode3 = [[SKShapeNode alloc] init];
    CGRect hotZoneCircle3 = CGRectMake(pos.x - hotZoneSize3/2, pos.y - hotZoneSize3/2, hotZoneSize3, hotZoneSize3);
    hotZoneShapeNode3.path = [UIBezierPath bezierPathWithOvalInRect:hotZoneCircle3].CGPath;
    hotZoneShapeNode3.fillColor = nil;
    hotZoneShapeNode3.strokeColor = [SKColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
    hotZoneShapeNode3.antialiased = NO;
    hotZoneShapeNode3.lineWidth = 1;
    [_gameNode addChild:hotZoneShapeNode3];
    
    [_hotZoneShapes3 addObject:hotZoneShapeNode3];

//    CGRect coldZoneCircle = CGRectMake(pos.x - (coldZone/2), pos.y - (coldZone/2), coldZone, coldZone);
//    SKShapeNode *coldZoneShapeNode = [[SKShapeNode alloc] init];
//    coldZoneCircle = CGRectMake(pos.x - (coldZone/2), pos.y - (coldZone/2), coldZone, coldZone);
//    coldZoneShapeNode.path = [UIBezierPath bezierPathWithOvalInRect:coldZoneCircle].CGPath;
//    coldZoneShapeNode.fillColor = nil;
//    coldZoneShapeNode.strokeColor = [SKColor colorWithRed:0.00 green:0.0 blue:1.0 alpha:0.5];//SKColor.blueColor;
//    coldZoneShapeNode.antialiased = NO;
//    coldZoneShapeNode.lineWidth = 1;
//    [_gameNode addChild:coldZoneShapeNode];
    
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

- (void) addBlackHoleAtPosition:(CGPoint)pos withSize:(CGSize)size withEventHoriz:(CGFloat)eventHorizon
{
    _blackHoleNode = [SKSpriteNode spriteNodeWithImageNamed:@"alienPlanet"];
    _blackHoleNode.name = @"blackHole";
    _blackHoleNode.position = pos;
    _blackHoleNode.size = size;
    SKAction *action = [SKAction rotateByAngle:M_PI duration:0.3];
    [_blackHoleNode runAction:[SKAction repeatActionForever:action]];
    [_gameNode addChild:_blackHoleNode];
    
//    float eventHoriz = size.width * 10;
    float eventHoriz = eventHorizon;
    _blackHoleNode.userData = [[NSMutableDictionary alloc] init];
    [_blackHoleNode.userData setObject:[NSNumber numberWithInt:eventHoriz] forKey:@"eventHorizonMax"];
    [_blackHoleNode.userData setObject:[NSNumber numberWithInt:eventHoriz] forKey:@"eventHorizon"];
    [_blackHoleNode.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isDestroyed"];
    
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
    eventHorizShapeNode.name = @"eventHorizon";
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
        _newX = (_releaseLocation.x - _touchLocation.x) * 0.02;//(_swipeCounter * 0.0001);
        _newY = (_releaseLocation.y - _touchLocation.y) * 0.02;//(_swipeCounter * 0.0001);
        
        //______________________________________________________________________________________________________________
        //|                                                                                                            |
        //|                                      MOVE EARTH                                                            |
        //|____________________________________________________________________________________________________________|
        
        if ( [_shipNode.userData[@"canControl"] boolValue] == YES ) {
            if ( [_shipNode.userData[@"population"] intValue] > 0 ) {
                [_shipNode.physicsBody applyForce: CGVectorMake(_newX, _newY)];
                int newPop = [_shipNode.userData[@"population"] intValue];
                
                if (([_shipNode.userData[@"isHot"] boolValue] == NO) && ([_shipNode.userData[@"isCold"] boolValue] == NO)){
                    newPop -= 2;//change based on speed?
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
                        newPop -= 2;
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
    [self animateAllShapes];  //ANIMATE ALL SHAPE NODES FOR SUNS AND BLACK HOLES
    
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
    
    NSMutableArray *newEventHorizonShapes = [[NSMutableArray alloc]init];
    
    [_gameNode enumerateChildNodesWithName:@"eventHorizon" usingBlock:^(SKNode *node, BOOL *stop) {
        [newEventHorizonShapes addObject:node];
    }];
    _eventHorizonShapes = newEventHorizonShapes;
    
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
                if (length < [thisBlackHole.userData[@"eventHorizonMax"] intValue]/2) {        //black holes only attract within certain distances
                    [node.physicsBody applyForce: CGVectorMake(direction.x * 0.03 * size.width, direction.y * 0.03 * size.width )];
                }
            }
        }
            //______________________________________________________________________________________________________________
            //|                                                                                                            |
            //|                                 BURN up population if too close to sun                                     |
            //|____________________________________________________________________________________________________________|
        if (node.physicsBody.categoryBitMask == PhysicsCategoryControlColony | node.physicsBody.categoryBitMask == PhysicsCategoryShip | node.physicsBody.categoryBitMask == PhysicsCategoryColony | node.physicsBody.categoryBitMask == PhysicsCategoryAsteroid) {
            [node.userData setObject:[NSNumber numberWithInt:0] forKey:@"isHotCount"];
            [_gameNode enumerateChildNodesWithName:@"sun" usingBlock:^(SKNode *thisSun, BOOL *stop) {
                CGPoint point = thisSun.position;
                CGPoint offset = CGPointMake(point.x - node.position.x, point.y - node.position.y);
                CGFloat length = sqrtf(offset.x * offset.x + offset.y * offset.y);
                if (length < [thisSun.userData[@"hotZoneMax"] intValue]/2 + node.size.width/2) {
                    [node.userData setObject:[NSNumber numberWithInt:[node.userData[@"isHotCount"]intValue]+1] forKey:@"isHotCount"];
                }
                //}// FOR COLD..............
//                if ([_suns count] == 1) {  //more than one cold zone overlapping hot zones doesn't make sense........
//                    if (length > [thisSun.userData[@"coldZone"] intValue]/2) {
//                        [node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"isCold"];
//                    }
//                    else {
//                        [node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isCold"];
//                    }
//                }
            }];
            
            if ([node.userData[@"isHotCount"]intValue] > 0) {
                [node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"isHot"];
            }
            else {
                [node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"isHot"];
            }
            
            //}
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
    
    _totalPossiblePopulation = 0;
    [_gameNode enumerateChildNodesWithName:@"earth" usingBlock:^(SKNode *node, BOOL *stop) {
        _totalPossiblePopulation += [node.userData[@"maxPopulation"] intValue];
    }];
    [_gameNode enumerateChildNodesWithName:@"controlColony" usingBlock:^(SKNode *node, BOOL *stop) {
        _totalPossiblePopulation += [node.userData[@"maxPopulation"] intValue];
    }];
    [_gameNode enumerateChildNodesWithName:@"colonyPlanet" usingBlock:^(SKNode *node, BOOL *stop) {
        _totalPossiblePopulation += [node.userData[@"maxPopulation"] intValue];
    }];
    NSLog(@"total possible population = %i", _totalPossiblePopulation);
    
    
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
    if ([_shipNode.userData[@"isDestroyed"] boolValue] == YES ) {
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
        if ([node.userData[@"isDestroyed"] boolValue] == YES)  {
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
    if ( ((_totalPopulation == 0) && (earthLose > 0) && (coloniesLose == coloniesNum) && (_levelOver == NO))     ){
       // | (_totalPossiblePopulation < _levelGoal) ) {
        [self lose];
        _levelOver = YES;
 //   } else if (_totalPossiblePopulation < _levelGoal) {
 //       [self loseByPossiblePopulation];
 //       _levelOver = YES;   //something wrong here............ a weird stutter on level restart. also there's a problem with recognizing game over with colony death(?)
    }
    

    
    [self updatePopulations];
    [self updateLabelNodes];
}

// CALLED JUST AFTER PHYSICS GET SIMULATED
- (void)didSimulatePhysics  /* called just after physics get simulated */
{

    
}


// COLLISION LOOP
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
        //NSLog(@"sun grows");
        //ENTER MYSTERY CODE HERE! contact.bodyB.node.size is no good.
        //[contact.bodyB.node setScale:2.0];
        //CGFloat absorbMass = contact.bodyA.node.frame.size.width * 0.01; //THIS SORT OF WORKS BUT I WANTED MASS
        //NSLog(@"width: %f", absorbMass);
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
        int earthNewPop = [_shipNode.userData[@"population"] intValue];
        earthNewPop -= 20;
        [_shipNode.userData setObject:[NSNumber numberWithInt:earthNewPop] forKey:@"population"];
        int colonyNewPop = [_shipNode.userData[@"population"] intValue];   ///initially wanted to adjust contact planet stuff.
        colonyNewPop = 1;
        if (contact.bodyA.node.physicsBody.categoryBitMask == PhysicsCategoryColony) {
            contact.bodyA.categoryBitMask = PhysicsCategoryControlColony;
            colonyNewPop += [contact.bodyA.node.userData[@"population"]intValue];   //HHAAAAXXXX
            NSLog(@"New colony");
            contact.bodyA.node.name = @"controlColony";
            [contact.bodyA.node.userData setObject:[NSNumber numberWithInt:colonyNewPop] forKey:@"population"];
        }
        else if (contact.bodyB.node.physicsBody.categoryBitMask == PhysicsCategoryColony) {
            contact.bodyB.categoryBitMask = PhysicsCategoryControlColony;
            colonyNewPop += [contact.bodyB.node.userData[@"population"]intValue];        //HHAAAAXXXX
            NSLog(@"New colony");
            contact.bodyB.node.name = @"controlColony";
            //[contact.bodyB.node.userData setObject:[NSNumber numberWithInt:colonyNewPop] forKey:@"population"];
        }
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
        if (contact.bodyA.node.physicsBody.categoryBitMask == PhysicsCategoryColony) {
            int colonyNewPop = 1;
            colonyNewPop += [contact.bodyA.node.userData[@"population"]intValue];
            contact.bodyA.categoryBitMask = PhysicsCategoryControlColony;
            contact.bodyA.node.name = @"controlColony";
            [contact.bodyA.node.userData setObject:[NSNumber numberWithInt:colonyNewPop] forKey:@"population"];
            [contact.bodyA.node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"canControl"];
        }
        else if (contact.bodyB.node.physicsBody.categoryBitMask == PhysicsCategoryColony) {
            int colonyNewPop = 1;
            colonyNewPop += [contact.bodyA.node.userData[@"population"]intValue];
            contact.bodyB.categoryBitMask = PhysicsCategoryControlColony;
            contact.bodyB.node.name = @"controlColony";
            [contact.bodyA.node.userData setObject:[NSNumber numberWithInt:colonyNewPop] forKey:@"population"];
            [contact.bodyB.node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"canControl"];
        }
        NSLog(@"New colony");
    }
    
    //black hole force explosion and disappear
    else if ( (collision == (PhysicsCategoryShip | PhysicsCategoryBlackHole)) | (collision == (PhysicsCategoryControlColony | PhysicsCategoryBlackHole)) | (collision == (PhysicsCategoryAsteroid | PhysicsCategoryBlackHole)) )
    {
        NSLog(@"black hole explode");
        for (SKSpriteNode *node in _gameNode.children)
        {
            
            for (int i = 0; i < [_blackHoles count]; i ++) {
                if (contact.bodyA.node == _blackHoles[i]) {
                    [_eventHorizonShapes[i] removeFromParent];
                }
                else if (contact.bodyB.node == _blackHoles[i]) {
                    [_eventHorizonShapes[i] removeFromParent];
                }
            }
            
            //probably need to add a conditional to take care of the bodyA/bodyB confusion.......
            CGPoint offset = CGPointMake(contact.bodyB.node.position.x - node.position.x, contact.bodyB.node.position.y - node.position.y);
            CGFloat length = sqrtf(offset.x * offset.x + offset.y * offset.y);
            CGPoint direction = CGPointMake(offset.x / length, offset.y / length);
            [node.physicsBody applyImpulse: CGVectorMake(-direction.x * contact.bodyB.node.frame.size.width * 0.3, -direction.y * contact.bodyB.node.frame.size.width * 0.3)];
        }
        if (contact.bodyA.node.physicsBody.categoryBitMask == PhysicsCategoryShip) {
            [contact.bodyA.node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
            [contact.bodyA.node.userData setObject:[NSNumber numberWithInt:0] forKey:@"population"];
            [contact.bodyA.node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"isDestroyed"];
            [contact.bodyB.node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"isDestroyed"];
//            for (int i = 0; i < [_blackHoles count]; i ++) {
//                if (_blackHoles[i] == contact.bodyB.node) {
//                    [_eventHorizonShapes[i] removeFromParent];
//                }
//            }
            [contact.bodyA.node removeFromParent];
            [contact.bodyB.node removeFromParent];
        }
        else if (contact.bodyA.node.physicsBody.categoryBitMask == PhysicsCategoryControlColony) {
            [contact.bodyA.node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
            [contact.bodyA.node.userData setObject:[NSNumber numberWithInt:0] forKey:@"population"];
            [contact.bodyA.node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"isDestroyed"];
            [contact.bodyB.node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"isDestroyed"];
//            for (int i = 0; i < [_blackHoles count]; i ++) {
//                if (_blackHoles[i] == contact.bodyB.node) {
//                    [_eventHorizonShapes[i] removeFromParent];
//                }
//            }
            [contact.bodyA.node removeFromParent];
            [contact.bodyB.node removeFromParent];
        }
        else if (contact.bodyB.node.physicsBody.categoryBitMask == PhysicsCategoryShip) {
            [contact.bodyB.node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
            [contact.bodyB.node.userData setObject:[NSNumber numberWithInt:0] forKey:@"population"];
            [contact.bodyB.node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"isDestroyed"];
            [contact.bodyA.node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"isDestroyed"];
//            for (int i = 0; i < [_blackHoles count]; i ++) {
//                if (_blackHoles[i] == contact.bodyA.node) {
//                    [_eventHorizonShapes[i] removeFromParent];
//                }
//            }
            [contact.bodyA.node removeFromParent];
            [contact.bodyB.node removeFromParent];
        }
        else if (contact.bodyB.node.physicsBody.categoryBitMask == PhysicsCategoryControlColony) {
            [contact.bodyB.node.userData setObject:[NSNumber numberWithBool:NO] forKey:@"canControl"];
            [contact.bodyB.node.userData setObject:[NSNumber numberWithInt:0] forKey:@"population"];
            [contact.bodyB.node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"isDestroyed"];
            [contact.bodyA.node.userData setObject:[NSNumber numberWithBool:YES] forKey:@"isDestroyed"];
//            for (int i = 0; i < [_blackHoles count]; i ++) {
//                if (_blackHoles[i] == contact.bodyA.node) {
//                    [_eventHorizonShapes[i] removeFromParent];
//                }
//            }
            [contact.bodyA.node removeFromParent];
            [contact.bodyB.node removeFromParent];
        }
        // THE ABOVE IS MY DESPERATE ATTEMPT TO MAKE BLACK HOLES RESULT IN A LEVEL-FAIL STATE .......... :(
        //it seems to work now that i use the isDestroyed logic above
        [contact.bodyA.node removeFromParent];
        [contact.bodyB.node removeFromParent];
    }
    
}


// Update to new level, display win message
// Needs some subtlety and additional options/messages
-(void)win
{
    if (_currentLevel < 10) {
        _currentLevel ++;
    }
    else {
        _currentLevel = 1;
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

// Restart level, display message
// Needs similar update to win
-(void)lose
{
    NSLog(@"lose");
    [self inGameMessage:@"EXTINCT"];
    [self runAction:
     [SKAction sequence:
      @[[SKAction waitForDuration:3.0],
        [SKAction performSelector:@selector(newGame) onTarget:self]]]];
}

-(void)loseByPossiblePopulation
{
    NSLog(@"lose");
    [self inGameMessage:@"NOT ENOUGH PLANETS"];
    [self runAction:
     [SKAction sequence:
      @[[SKAction waitForDuration:3.0],
        [SKAction performSelector:@selector(newGame) onTarget:self]]]];
}

// Called every time a new level starts, removes gamenode children and runs setupLevel
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
-(void)setupLevel:(int)levelNum
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
    levelGoalLabel.fontColor = [SKColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
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
    
//    SKSpriteNode * _vignette = [SKSpriteNode spriteNodeWithImageNamed:@"vignette"];
//    _vignette.position = CGPointMake(self.size.width/2, self.size.height/2);
//    _vignette.size = CGSizeMake(self.size.width, self.size.height);
//    [_gameNode addChild:_vignette];
}

//for setupLevel, grabs from plist
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

//for setupLevel, grabs from plist
-(void)addSunsFromArray:(NSArray*)suns
{
    for (NSDictionary *sun in suns) {
        CGSize size = CGSizeFromString(sun[@"size"]);
        CGPoint position = CGPointFromString(sun[@"position"]);
        [self addSunAtPosition:position withSize:size];
        NSLog(@"addSunsFromArray");
    }
}

//for setupLevel, grabs from plist
-(void)addAsteroidsFromArray:(NSArray*)asteroids
{
    for (NSDictionary *asteroid in asteroids) {
        CGSize size = CGSizeFromString(asteroid[@"size"]);
        CGPoint position = CGPointFromString(asteroid[@"position"]);
        [self addAsteroidAtPosition:position withSize:size];
        NSLog(@"addAsteroidsFromArray");
    }
}

//for setupLevel, grabs from plist
-(void)addColoniesFromArray:(NSArray*)colonies
{
    for (NSDictionary *colony in colonies) {
        CGPoint position = CGPointFromString(colony[@"position"]);
        CGSize size = CGSizeFromString(colony[@"size"]);
        CGFloat density = [(colony[@"density"])floatValue];
        CGFloat startingPop = [(colony[@"population"])floatValue];
        [self addColonyPlanetAtPosition:position withSize:size withDensity:density withStartingPop:startingPop];
        NSLog(@"addColoniesFromArray");
    }
}

//for setupLevel, grabs from plist
-(void)addBlackHolesFromArray:(NSArray*)blackHoles
{
    for (NSDictionary *blackHole in blackHoles) {
        CGPoint position = CGPointFromString(blackHole[@"position"]);
        CGSize size = CGSizeFromString(blackHole[@"size"]);
        CGFloat eventHorizon = [(blackHole[@"eventHorizon"]) floatValue ];
        [self addBlackHoleAtPosition:position withSize:size withEventHoriz:eventHorizon];
        NSLog(@"addBlackHolesFromArray");
    }
}

//updates the userData population key of all the nodes with any population
-(void)updatePopulations
{
    //______________________________________________________________________________________________________________
    //|                                                                                                            |
    //|                                 REGENERATE POPULATION if EARTH can be controlled                           |
    //|____________________________________________________________________________________________________________|
    
    //CHECK THIS
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
}

// updates the population label nodes on the planets
// this will need to have other label nodes at some point or maybe replaced entirely by another visual system
-(void)updateLabelNodes
{
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
    
}

-(void)animateAllShapes
{
    //______________________________________________________________________________________________________________
    //|                                                                                                            |
    //|                       make all shapes (event horizon, sun heat) update and animate                         |
    //|____________________________________________________________________________________________________________|
    /*
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
        _suns[i] = newSun;        //i might be able to kill this... or maybe not if the suns actually move. //WAIT NO. i need to update the mutable dir
    }
    //second shape node?
    for (int i = 0; i < [_suns count]; i++) {
        SKShapeNode * newShape2 = _hotZoneShapes2[i];
        SKSpriteNode * newSun2 = _suns[i];
        CGPoint pos2 = newSun2.position;
        float newHotZone2 = [newSun2.userData[@"hotZoneSize2"] floatValue];
        float newHotMax2 = [newSun2.userData[@"hotZoneMax"] floatValue];
        
        int newHotZoneInt2 = (int) newHotZone2;
        int newHotMaxInt2 = (int) newHotMax2;
        
        if (newHotZoneInt2 < newHotMaxInt2+3) {
            newHotZone2 += (newHotMax2 - newHotZone2+25) * .05;
            [newSun2.userData setObject:[NSNumber numberWithInt:newHotZone2] forKey:@"hotZoneSize2"];
        }
        else {
            //NSLog(@"here's the old size- %f", [newSun.userData[@"hotZoneSize"]floatValue]);
            [newSun2.userData setObject:[NSNumber numberWithFloat:newSun2.size.width] forKey:@"hotZoneSize2"];
            //NSLog(@"here should be the new size - %f", [newSun.userData[@"hotZoneSize"]floatValue]);
        }
        CGRect hotZoneCircle2 = CGRectMake(pos2.x - (newHotZone2/2), pos2.y - (newHotZone2/2), newHotZone2, newHotZone2);
        hotZoneCircle2 = CGRectMake(pos2.x - (newHotZone2/2), pos2.y - (newHotZone2/2), newHotZone2, newHotZone2);
        newShape2.path = [UIBezierPath bezierPathWithOvalInRect:hotZoneCircle2].CGPath;
        newShape2.fillColor = nil;
        newShape2.strokeColor = [SKColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1];
        newShape2.antialiased = NO;
        newShape2.lineWidth = 1;
        newShape2.alpha = 0.5;
        _hotZoneShapes2[i] = newShape2;
        _suns[i] = newSun2;
    }
    //third shape node?
    for (int i = 0; i < [_suns count]; i++) {
        SKShapeNode * newShape3 = _hotZoneShapes3[i];
        SKSpriteNode * newSun3 = _suns[i];
        CGPoint pos3 = newSun3.position;
        float newHotZone3 = [newSun3.userData[@"hotZoneSize3"] floatValue];
        float newHotMax3 = [newSun3.userData[@"hotZoneMax"] floatValue];
        
        int newHotZoneInt3 = (int) newHotZone3;
        int newHotMaxInt3 = (int) newHotMax3;
        
        if (newHotZoneInt3 < newHotMaxInt3+3) {
            newHotZone3 += (newHotMax3 - newHotZone3 + 25) * .05;
            [newSun3.userData setObject:[NSNumber numberWithInt:newHotZone3] forKey:@"hotZoneSize3"];
        }
        else {
            //NSLog(@"here's the old size- %f", [newSun.userData[@"hotZoneSize"]floatValue]);
            [newSun3.userData setObject:[NSNumber numberWithFloat:newSun3.size.width] forKey:@"hotZoneSize3"];
            //NSLog(@"here should be the new size - %f", [newSun.userData[@"hotZoneSize"]floatValue]);
        }
        CGRect hotZoneCircle3 = CGRectMake(pos3.x - (newHotZone3/2), pos3.y - (newHotZone3/2), newHotZone3, newHotZone3);
        hotZoneCircle3 = CGRectMake(pos3.x - (newHotZone3/2), pos3.y - (newHotZone3/2), newHotZone3, newHotZone3);
        newShape3.path = [UIBezierPath bezierPathWithOvalInRect:hotZoneCircle3].CGPath;
        newShape3.fillColor = nil;
        newShape3.strokeColor = [SKColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1];
        newShape3.antialiased = NO;
        newShape3.lineWidth = 1;
        newShape3.alpha = 0.5;
        _hotZoneShapes3[i] = newShape3;
        _suns[i] = newSun3;
    }
    
    //animates black hole event horizons
    for (int i = 0; i < [_blackHoles count]; i++) {
        SKShapeNode * newShape = _eventHorizonShapes[i];
        SKSpriteNode * newBlackHole = _blackHoles[i];
        CGPoint pos = newBlackHole.position;
        float newEventHorizon = [newBlackHole.userData[@"eventHorizon"] floatValue];
        float newEventHorizonMax = [newBlackHole.userData[@"eventHorizonMax"] floatValue];
        
        int newEventHorizonInt = (int) newEventHorizon;
//        if ([newBlackHole.userData[@"isDestroyed"] boolValue] == NO ) {
            if (newEventHorizonInt > newBlackHole.size.width) {
                newEventHorizon -= (newBlackHole.size.width + newEventHorizon) * .01;
                [newBlackHole.userData setObject:[NSNumber numberWithInt:newEventHorizon] forKey:@"eventHorizon"];
            }
            else {
                [newBlackHole.userData setObject:[NSNumber numberWithFloat:newEventHorizonMax] forKey:@"eventHorizon"];
            }
//        }
//        else {
//            [newBlackHole removeFromParent];
//            newEventHorizon += (newBlackHole.size.width + newEventHorizon) * .01;
//            [newBlackHole.userData setObject:[NSNumber numberWithInt:1000] forKey:@"eventHorizon"];
//        }
        CGRect hotZoneCircle = CGRectMake(pos.x - (newEventHorizon/2), pos.y - (newEventHorizon/2), newEventHorizon, newEventHorizon);
        hotZoneCircle = CGRectMake(pos.x - (newEventHorizon/2), pos.y - (newEventHorizon/2), newEventHorizon, newEventHorizon);
        newShape.path = [UIBezierPath bezierPathWithOvalInRect:hotZoneCircle].CGPath;
        newShape.fillColor = nil;
        newShape.strokeColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1];
        newShape.antialiased = NO;
        newShape.lineWidth = 1;
        newShape.alpha = 0.5;
        _eventHorizonShapes[i] = newShape;
        _blackHoles[i] = newBlackHole;        //i might be able to kill this... or maybe not if the suns actually move. //WAIT NO. i need to update the mutable dir
    }
}


@end
