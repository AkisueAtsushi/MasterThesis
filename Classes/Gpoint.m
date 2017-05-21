//
//  Gpoint.m
//  SampleApplicatioin
//
//  Created by 根上 生也 on 10/08/03.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Gpoint.h"

int globalVertexnumber = 0;

@implementation Gpoint

@synthesize center_x;
@synthesize center_y;
@synthesize draw_x;
@synthesize draw_y;
@synthesize vertex_number;
@synthesize is_on_boundary;
@synthesize imaginary_vertex;
@synthesize imaginary_on_boundary;

-(Gpoint *) initGpoint: (int) point_x: (int) point_y{
	self = [super init];
	
	center_x = point_x;
	center_y = point_y;
	draw_x = point_x - (DIAMETER_OF_VERTEX/2);
	draw_y = point_y - (DIAMETER_OF_VERTEX/2);
	vertex_number = globalVertexnumber;
	globalVertexnumber++;
	is_on_boundary = NOT_ON_BOUNDARY;
	imaginary_on_boundary = NOT_ON_BOUNDARY;
	imaginary_vertex = [[NSMutableArray alloc] initWithCapacity:0];

	return self;
	
}

-(void) initDrawVertexPoint: (int) point_x: (int) point_y{
	center_x = point_x;
	center_y = point_y;
	draw_x = point_x - (DIAMETER_OF_VERTEX/2);
	draw_y = point_y - (DIAMETER_OF_VERTEX/2);
}

@end
