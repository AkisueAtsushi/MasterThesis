//
//  Field.h
//  Sample Project
//
//  Created by Akisue on 10/11/25.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Defines.h"
#import "Vertex.h"

@interface Field : NSObject {
	@private
		NSMutableArray *points;
		NSMutableArray *edges;
		NSMutableArray *arrow_point;
		NSMutableArray *arrow_edge;
		NSMutableArray *arrow_fin;
		int number_of_vertex;
		BOOL is_projection;
		double rad;
}

@property (assign) NSMutableArray* points;
@property (assign) NSMutableArray* edges;
@property (assign) NSMutableArray* arrow_point;
@property (assign) NSMutableArray* arrow_edge;
@property (assign) NSMutableArray* arrow_fin;
@property int number_of_vertex;
@property double rad;

-(Field *)initField:(BOOL)orient:(int)genus;
-(void)makeField:(BOOL)orient:(int)genus;
+(Vertex *)Rotate:(double)rad:(Vertex *)before_vertex;

@end
