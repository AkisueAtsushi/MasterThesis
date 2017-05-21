//
//  edge.h
//  SampleApplicatioin
//
//  Created by 根上 生也 on 10/09/07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Edge : NSObject {
	@protected
		int side1, side2;
		BOOL selected;
		int side1_connect_to_imaginary_vertex;
		int side2_connect_to_imaginary_vertex;
}

@property int side1, side2;
@property BOOL selected;
@property int side1_connect_to_imaginary_vertex;
@property int side2_connect_to_imaginary_vertex;

-(Edge *) initEdge: (int) sideA: (int) sideB;


@end
