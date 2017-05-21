//
//  Gpoint.h
//  SampleApplicatioin
//
//  Created by 根上 生也 on 10/08/03.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "defines.h"

@interface Gpoint : NSObject {
	@protected
		int center_x; int cenetr_y;
		int draw_x; int draw_y;
		int vertex_number;
		int is_on_boundary;
		int imaginary_on_boundary;
		NSMutableArray *imaginary_vertex;
}

@property int center_x, center_y, draw_x, draw_y, vertex_number, is_on_boundary, imaginary_on_boundary;
@property (assign) NSMutableArray* imaginary_vertex;

-(Gpoint *) initGpoint: (int) point_x : (int) point_y;
-(void) initDrawVertexPoint: (int) point_x : (int) point_y;

@end
