//
//  reportView.h
//  SampleApplicatioin
//
//  Created by 根上 生也 on 10/07/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Gpoint.h"
#import "Edge.h"
#import "Flags.h"
#import "Field.h"
#import "Defines.h"

@interface reportView : UIView {

	IBOutlet UISegmentedControl *orientability;
	IBOutlet UISegmentedControl *genus_selection;    //genus
	IBOutlet UIButton *change;	//change
	
	@protected
		CGContextRef cgContext;
		NSMutableArray *vertexes;
		NSMutableArray *edges;
		Field *field;
		BOOL is_oriented;
		int genus;
		int passing_edge;

	@private
		Flags *flag;

		//辺の選択に使用
		int beginX, beginY, endX, endY;
		int draw_beginX, draw_beginY, draw_endX, draw_endY;
}

@property (nonatomic, retain) UISegmentedControl *orientability;
@property (nonatomic, retain) UISegmentedControl *genus_selection;
@property (nonatomic, retain) UIButton *change;

// リセットボタンを押したときに呼ばれるメソッド
-(IBAction)executeChangeNet:(id)sender;

-(BOOL)checkCrossedEdges:(Edge *)tempedge;
-(BOOL)isCrossed: (Vertex *)edgeAbegin :(Vertex *)edgeAend :(Vertex *)edgeBbegin :(Vertex *)edgeBend; 
-(int)isInField:(Vertex *)tempvertex;
-(BOOL)isNearBoundary:(Gpoint *)tempvertex;
-(BOOL)isOnEdge: (Edge *)tempedge decideSideCoordinate: (Vertex *)sideA :(Vertex *)sideB :(Vertex *)imgSideA :(Vertex *)imgSideB;
-(int)isOnEdge: (Edge *)tempedge switching: (int *)side1: (int *)side2;
-(void)setVertexOnBoundary:(Vertex *)touchPosition:(Gpoint *)tempvertex;
-(void)setImaginaryVertex:(Gpoint *)tempvertex;

@end
