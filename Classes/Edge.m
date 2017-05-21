//
//  edge.m
//  SampleApplicatioin
//
//  Created by 根上 生也 on 10/09/07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Edge.h"
#import "Defines.h"

@implementation Edge

@synthesize side1;
@synthesize side2;
@synthesize selected;
@synthesize side1_connect_to_imaginary_vertex;
@synthesize side2_connect_to_imaginary_vertex;

-(Edge *) initEdge: (int) sideA: (int) sideB {
	self = [super init];

	side1 = sideA;
	side2 = sideB;
	selected = NO;
	side1_connect_to_imaginary_vertex = CONNECT_TO_ORIGINAL_VERTEX;
	side2_connect_to_imaginary_vertex = CONNECT_TO_ORIGINAL_VERTEX;

	return self;
}

@end
