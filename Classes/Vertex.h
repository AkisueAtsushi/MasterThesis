//
//  point.h
//  Sample Project
//
//  Created by Akisue on 10/11/30.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Vertex : NSObject {
	@private
		double x;
		double y;
}

@property	double x, y;

-(Vertex *) initVertex: (double)_x: (double)_y;
@end
