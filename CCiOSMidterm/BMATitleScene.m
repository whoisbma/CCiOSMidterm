//
//  BMATitleScene.m
//  CCiOSMidterm
//
//  Created by Bryan Ma on 4/20/14.
//  Copyright (c) 2014 Bryan Ma. All rights reserved.
//

#import "BMATitleScene.h"
#import "BMAMyScene.h"

@implementation BMATitleScene
{
    int _titlePhase;
    
}

-(id)initWithSize:(CGSize)size
{
    if(self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor colorWithRed:0 green:0 blue:0 alpha:1.0];
        
        SKSpriteNode * titleColony;
        titleColony = [SKSpriteNode spriteNodeWithImageNamed:@"greenPlanet"];
        titleColony.position = CGPointMake(270, 400);
        titleColony.size = CGSizeMake(8, 8);
        [self addChild:titleColony];
        
        SKSpriteNode * titleAlienPlanet;
        titleAlienPlanet = [SKSpriteNode spriteNodeWithImageNamed:@"alienPlanet"];
        titleAlienPlanet.position = CGPointMake(75, 350);
        titleAlienPlanet.size = CGSizeMake(16, 16);
        [self addChild:titleAlienPlanet];
        
        SKSpriteNode * titleSun;
        titleSun = [SKSpriteNode spriteNodeWithImageNamed:@"sun"];
        titleSun.position = CGPointMake(self.size.width/2, 250);
        titleSun.size = CGSizeMake(64, 64);
        [self addChild:titleSun];
        
        SKSpriteNode * titleEarth;
        titleEarth = [SKSpriteNode spriteNodeWithImageNamed:@"earth"];
        titleEarth.position = CGPointMake(self.size.width/2, 0);
        titleEarth.size = CGSizeMake(500, 500);
        [self addChild:titleEarth];
        SKAction *action = [SKAction rotateByAngle:M_PI duration:100];
        [titleEarth runAction:[SKAction repeatActionForever:action]];
        
        _titlePhase = 0;
        
    }
    return self;
}

-(void)update:(NSTimeInterval)currentTime
{
    if (_titlePhase > 0) {
        _titlePhase++;
    }
    if (_titlePhase > 0 && _titlePhase < 5) {
        [self titleMessage:@"IT'S TIME TO LEAVE." withYPos:450];
    }
    else if (_titlePhase > 100 && _titlePhase <105)
    {
        [self titleMessage:@"NO, NOT THE EARTH." withYPos:420];
    }
    else if (_titlePhase > 200 && _titlePhase < 205)
    {
        [self titleMessage:@"WE'RE TAKING THAT WITH US." withYPos:390];
    }
    else if (_titlePhase > 300 && _titlePhase < 305)
    {
        [self titleMessage:@"SWIPE TO MOVE SETTLED PLANETS!" withYPos:360];
    }
    else if (_titlePhase > 400 && _titlePhase < 405)
    {
        [self titleMessage:@"BUMP INTO HOSPITABLE PLANETS!" withYPos:330];
    }
    else if (_titlePhase > 500 && _titlePhase < 505)
    {
        [self titleMessage:@"REACH TARGET POPULATION!" withYPos:300];
    }
    else if (_titlePhase > 650 && _titlePhase < 655)
    {
        [self titleMessage:@"ok let's go now, tap already" withYPos:200];
    }
    else if (_titlePhase > 750 && _titlePhase < 755)
    {
        [self titleMessage:@"the sun is seriously TOO HOT" withYPos:170];
         [self titleMessage:@"LET'S GO YOU GUYS" withYPos:140];
    }
    
    //NSLog(@"%i", _titlePhase);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_titlePhase == 0) {
        _titlePhase++;
        
    }
    else if (_titlePhase > 100) {
        SKScene * myScene = [[BMAMyScene alloc] initWithSize:self.size ];
        SKTransition *fade = [SKTransition fadeWithDuration:2.0];
        [self.view presentScene:myScene transition:fade];
    }
}


-(void)titleMessage:(NSString *)text1 withYPos:(float)pos
{

    SKLabelNode *label1 = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Regular"];
    label1.text = text1;
    label1.fontSize = 16.0;
    label1.fontColor = [SKColor whiteColor];
    label1.position = CGPointMake(self.frame.size.width/2, pos);
    [self addChild:label1];
    
    [label1 runAction: [SKAction sequence:@[
                                           [SKAction waitForDuration:4.0],
                                           [SKAction removeFromParent]]]];
    
    
}



@end
