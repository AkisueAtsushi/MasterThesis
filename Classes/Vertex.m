//
//  point.m
//  Sample Project
//
//  Created by Akisue on 10/11/30.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Vertex.h"


@implementation Vertex

@synthesize x;
@synthesize y;

-(Vertex *) initVertex:(double)_x :(double)_y {
	self = [super init];
	
	x = _x;	y = _y;
	
	return self;
}
@end
