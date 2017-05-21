//
//  Field.m
//  Sample Project
//
//  Created by Akisue on 10/11/25.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Field.h"

@implementation Field

@synthesize points;
@synthesize edges;
@synthesize number_of_vertex;
@synthesize	rad;
@synthesize arrow_point;
@synthesize arrow_edge;
@synthesize arrow_fin;

-(Field *)initField: (BOOL)orient: (int)genus {
	self = [super init];

	is_projection = NO;

	points = [[NSMutableArray alloc] initWithCapacity:0];
	edges  = [[NSMutableArray alloc] initWithCapacity:0];
	arrow_point = [[NSMutableArray alloc] initWithCapacity:0];
	arrow_edge  = [[NSMutableArray alloc] initWithCapacity:0];
	arrow_fin   = [[NSMutableArray alloc] initWithCapacity:0];

	[self makeField:orient : genus];

	return self;
}

-(void)makeField: (BOOL)orient: (int)genus {

	//初期化
	[points removeAllObjects];
	[edges removeAllObjects];
	[arrow_point removeAllObjects];
	[arrow_edge removeAllObjects];
	[arrow_fin removeAllObjects];

	Vertex *temp;
	Vertex *_arrow;

	if(orient == YES)
		is_projection = NO;
	else
		is_projection = YES;
	
	//向き付け可能な場合
	if (orient == YES)
		number_of_vertex = genus * 4;

	//向き付け不可能な場合
	else
		number_of_vertex = genus * 2;

	//最初の点（トーラスではない場合）
	temp = [[Vertex alloc] initVertex: 0: FIELD_DIAMETER];

	double arrow_diameter = ARROW_DIAMETER;

	for(int i=1; i < (number_of_vertex/4);i++)
		arrow_diameter *= ARROW_DIAMETER_RATE;

	_arrow = [[Vertex alloc] initVertex: 0: arrow_diameter];

	//トーラスの場合
	if(number_of_vertex == 4 && is_projection == NO) {
		temp = [Field Rotate:(M_PI/4):temp];
		_arrow = [Field Rotate:(M_PI_4):_arrow];
	}

	//射影平面の場合
	else if(number_of_vertex == 2)
	{
		is_projection = YES;
		number_of_vertex = 6;
	}

	[points addObject:temp];

	//角度を求める
	rad = (2*M_PI)/(number_of_vertex);

	//座標を求め,各線分の一次関数を求めるここから////
	Vertex *before_vertex, *before_arrow, *temp_arrow;
	Vertex *mdf_before_arrow, *mdf_temp_arrow;
	double endX, endY, beginX, beginY;
	double inclination, intercept;

	for(int i=0; i < number_of_vertex; i++) {

		before_vertex = [points objectAtIndex:i];
		beginX = [before_vertex x];
		beginY = [before_vertex y];

		if(i != (number_of_vertex - 1)) {
			temp = [Field Rotate:rad:before_vertex]; 
			[points addObject:temp];
			endX = [temp x];
			endY = [temp y];
		}
		else {
			endX = [[points objectAtIndex:0] x];
			endY = [[points objectAtIndex:0] y];
		}

		if(fabs(endX - beginX) > 0.000001 && fabs(endY - beginY) > 0.000001)
		{
			inclination = ((double)(endY - beginY))/((double)(endX - beginX));
			intercept = ((double)beginY) - (inclination * ((double)beginX));			
		}

		else if(fabs(endX - beginX) < 0.000001){
			inclination = endX;
			intercept = 0;
		}
		
		else if(fabs(endY - beginY) < 0.000001){
			inclination = 0;
			intercept = endY;
		}

		temp = [[Vertex alloc] initVertex: inclination: intercept];
		[edges addObject:temp];

		//矢印を作る
		before_arrow = _arrow;
		temp_arrow = [Field Rotate:rad:before_arrow];
		_arrow = temp_arrow;

		mdf_before_arrow = [[Vertex alloc] initVertex:[before_arrow x] :[before_arrow y]];
		mdf_temp_arrow = [[Vertex alloc] initVertex:[temp_arrow x] :[temp_arrow y]];

		double diff, fin_diff;
		if([[edges lastObject] y] != 0) {
			diff = fabs([before_arrow x] - [temp_arrow x]) * DIFF_RATE;
			fin_diff = fabs([before_arrow x] - [temp_arrow x]) * ARROW_FIN_RATE;
		}

		else {
			diff = fabs([before_arrow y] - [temp_arrow y]) * DIFF_RATE;
			fin_diff = fabs([before_arrow y] - [temp_arrow y]) * ARROW_FIN_RATE;
		}

		if([[edges lastObject] x] != 0 && [[edges lastObject] y] != 0) {

			double arrow_intercept = [before_arrow y] - ([before_arrow x]*[[edges lastObject] x]);

			if([before_arrow x] > [temp_arrow x]) {
				[mdf_before_arrow setX:[mdf_before_arrow x] - diff];
				[mdf_temp_arrow setX:[mdf_temp_arrow x] + diff];
			}

			else {
				[mdf_before_arrow setX:[mdf_before_arrow x] + diff];
				[mdf_temp_arrow setX:[mdf_temp_arrow x] - diff];
			}

			[mdf_before_arrow setY:([mdf_before_arrow x] * [[edges lastObject] x] + arrow_intercept)];
			[mdf_temp_arrow setY:([mdf_temp_arrow x] * [[edges lastObject] x] + arrow_intercept)];
			[arrow_edge addObject:[[Vertex alloc] initVertex:[[edges lastObject] x] :arrow_intercept]];
		}

		else if([[edges lastObject] x] == 0) {
			if([before_arrow x] > [temp_arrow x]) {
				[mdf_before_arrow setX:[mdf_before_arrow x] - diff];
				[mdf_temp_arrow setX:[mdf_temp_arrow x] + diff];
			}
			
			else {
				[mdf_before_arrow setX:[mdf_before_arrow x] + diff];
				[mdf_temp_arrow setX:[mdf_temp_arrow x] - diff];
			}
			[arrow_edge addObject:[[Vertex alloc] initVertex:0 :[before_arrow y]]];
		}

		else if([[edges lastObject] y] == 0) {
			if([before_arrow y] > [temp_arrow y]) {
				[mdf_before_arrow setY:[mdf_before_arrow y] - diff];
				[mdf_temp_arrow setY:[mdf_temp_arrow y] + diff];
			}
			
			else {
				[mdf_before_arrow setY:[mdf_before_arrow y] + diff];
				[mdf_temp_arrow setY:[mdf_temp_arrow y] - diff];
			}
			[arrow_edge addObject:[[Vertex alloc] initVertex:[before_arrow x] :0]];
		}

		[arrow_point addObject:mdf_before_arrow];
		[arrow_point addObject:mdf_temp_arrow];

		Vertex *make_fin_point = [[Vertex alloc] initVertex: [mdf_temp_arrow x]: [mdf_temp_arrow y]];
		Vertex *another_point = [[Vertex alloc] initVertex:[mdf_before_arrow x] :[mdf_before_arrow y]];

		if(orient && (([edges count]-1) % 4 == 2 || ([edges count]-1) % 4 == 3)) {
			[make_fin_point setX:[mdf_before_arrow x]];
			[make_fin_point setY:[mdf_before_arrow y]];
			[another_point  setX:[mdf_temp_arrow x]];
			[another_point  setY:[mdf_temp_arrow y]];
		}

		if([[arrow_edge lastObject] x] != 0 && [[arrow_edge lastObject] y] != 0) {
			if([make_fin_point x] > [another_point x])
				[make_fin_point setX:[make_fin_point x] - fin_diff];
			else
				[make_fin_point setX:[make_fin_point x] + fin_diff];
			[make_fin_point setY:([make_fin_point x]*[[arrow_edge lastObject] x] + [[arrow_edge lastObject] y])];
		}

		else if([[arrow_edge lastObject] x] == 0) {
			if([make_fin_point x] > [another_point x])
				[make_fin_point setX:[make_fin_point x] - fin_diff];
			else
				[make_fin_point setX:[make_fin_point x] + fin_diff];
		}

		else if([[arrow_edge lastObject] y] == 0) {
			if([make_fin_point y] > [another_point y])
				[make_fin_point setY:[make_fin_point y] - fin_diff];
			else
				[make_fin_point setY:[make_fin_point y] + fin_diff];
		}

		[arrow_fin addObject:make_fin_point];
	}
	//座標を求め,各線分の一次関数を求めるここまで////
}

+(Vertex *)Rotate:(double)radian:(Vertex *)before_vertex
{
	double x1 = [before_vertex x];
	double y1 = [before_vertex y];

	double x = x1 * cos(radian) - y1 * sin(radian);
	double y = x1 * sin(radian) + y1 * cos(radian);

	return [[Vertex alloc] initVertex:x :y];
}

@end