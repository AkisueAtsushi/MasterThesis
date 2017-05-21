//
//  Flags.m
//  SampleApplicatioin
//
//  Created by 根上 生也 on 10/08/19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Flags.h"

@implementation Flags

@synthesize on_common_point;
@synthesize is_touch_at_vertex;
@synthesize is_touch_once;
@synthesize begin_touch_at_vertex;
@synthesize is_moving_vertex;
@synthesize number_of_touched_vertex;
@synthesize before_touched_vertex;
@synthesize is_selecting_edge;
@synthesize connect_to_imaginary_vertex;
@synthesize before_imaginary_vertex;

-(Flags *) initFlags{
	self = [super init];
	on_common_point = NOT_ON_COMMON_POINT;
	begin_touch_at_vertex = NO;
	is_touch_at_vertex = NO;
	is_moving_vertex = NO;
	is_selecting_edge = NO;
	number_of_touched_vertex = NO_TOUCHED_VERTEX;
	before_touched_vertex = NO;
	is_touch_once = NO;
	connect_to_imaginary_vertex = CONNECT_TO_ORIGINAL_VERTEX;
	before_imaginary_vertex = CONNECT_TO_ORIGINAL_VERTEX;
	return self;
}

-(void) beginTouchAtVertex: (int) touched_vertex_number{
	begin_touch_at_vertex = YES;
	number_of_touched_vertex = touched_vertex_number;
}

-(void) isTouchAtVertex: (int) touched_vertex_number{
	is_touch_at_vertex = YES;
	number_of_touched_vertex = touched_vertex_number;
}

-(void) allReset{
	begin_touch_at_vertex = NO;
	is_touch_at_vertex = NO;
	is_moving_vertex = NO;
	is_touch_once = NO;
	is_selecting_edge = NO;
	number_of_touched_vertex = NO_TOUCHED_VERTEX;
	before_touched_vertex = NO_TOUCHED_VERTEX;
}


@end
