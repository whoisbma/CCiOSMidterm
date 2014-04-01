//
//  physics.h
//  CCiOSMidterm
//
//  Created by Bryan Ma on 3/25/14.
//  Copyright (c) 2014 Bryan Ma. All rights reserved.
//

typedef NS_OPTIONS(uint32_t, PhysicsCategory) {
    PhysicsCategoryShip          = 1 << 0, //0001 = 1
    PhysicsCategoryColony        = 1 << 1, //0010 = 2
    PhysicsCategorySun           = 1 << 2, //0100 = 4
    PhysicsCategoryControlColony = 1 << 3, //1000 = 8
    PhysicsCategoryBlackHole     = 1 << 4, //10000 = 16
    PhysicsCategoryAsteroid      = 1 << 5, //100000 = 32
//    PhysicsCategoryHook   = 1 << 6, //1000000 = 64
};