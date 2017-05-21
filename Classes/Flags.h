//
//  Flags.h
//  SampleApplicatioin
//
//  Created by 根上 生也 on 10/08/19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Defines.h"

@interface Flags : NSObject {
	@private
		int number_of_touched_vertex;
		int before_touched_vertex;

		int on_common_point;
		int connect_to_imaginary_vertex;
		int before_imaginary_vertex;

		BOOL is_touch_at_vertex;
		BOOL begin_touch_at_vertex;
		BOOL is_moving_vertex;
		BOOL is_touch_once;
		BOOL is_selecting_edge;
}

@property int on_common_point;
@property BOOL is_selecting_edge;
@property BOOL is_touch_once;
@property BOOL is_touch_at_vertex;
@property BOOL begin_touch_at_vertex;
@property BOOL is_moving_vertex;
@property int number_of_touched_vertex;
@property int before_touched_vertex;
@property int connect_to_imaginary_vertex;
@property int before_imaginary_vertex;

-(void) beginTouchAtVertex: (int)touched_vertex_number;
-(void) isTouchAtVertex: (int)touched_vertex_number;
-(void) allReset;
-(Flags *) initFlags;

@end
