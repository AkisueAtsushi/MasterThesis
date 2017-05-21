//
//  reportView.m
//  SampleApplicatioin
//
//  Created by 根上 生也 on 10/07/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "reportView.h"

@implementation reportView

@synthesize orientability;
@synthesize genus_selection;
@synthesize change;

- (id)initWithFrame:(CGRect)frame {

    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}

//初期化関数　※initWithFrameは呼ばれていない
- (void)awakeFromNib {

	//頂点の可変長配列
	vertexes = [[NSMutableArray alloc] initWithCapacity:0];

	//辺の可変長配列
	edges = [[NSMutableArray alloc] initWithCapacity:0];

	//状況判断フラグ
	flag = [[Flags alloc] initFlags];

	//フィールド
	is_oriented = NO;	genus = 1;
	field = [[Field alloc] initField:is_oriented :genus];

	//通過した辺
	passing_edge = OUT_OF_FIELD;
}

// 展開図を変えたい時に呼ばれるメソッド
-(IBAction)executeChangeNet:(id)sender{
	switch (self.orientability.selectedSegmentIndex) {
		case 0:
			is_oriented = YES;
			break;
		case 1:
			NSLog(@"non-orientable");
			is_oriented = NO;
			break;
		default:
			break;
	}
	
	switch (self.genus_selection.selectedSegmentIndex) {
		case 0:
			genus = 1;
			break;
		case 1:
			genus = 2;
			break;
		case 2:
			genus = 3;
			break;
		case 3:
			genus = 4;
			break;
		case 4:
			genus = 5;
			break;
		default:
			break;
	}

	[field makeField:is_oriented :genus];
	[self setNeedsDisplay];	
}

- (void) touchesBegan: (NSSet *)touches withEvent:(UIEvent *)event{

	for(UITouch *touch in touches) {
		CGPoint touchPos = [touch locationInView: self];
		int count = [vertexes count];
		
		//タップしたところが頂点の上かどうか
		for (int i=0; i < count; i++) {
			Gpoint *temp = [vertexes objectAtIndex:i];
			if(TOUCH_POINT_IS_INSIDE_VERTEX(touchPos.x, touchPos.y, [temp center_x], [temp center_y])) {
				[flag beginTouchAtVertex:i];
				if([flag is_touch_at_vertex] == NO)
					[flag setBefore_imaginary_vertex: CONNECT_TO_ORIGINAL_VERTEX];
				else
					[flag setConnect_to_imaginary_vertex: CONNECT_TO_ORIGINAL_VERTEX];
			}

			else {
				int imaginary_vertex = 0;
				for(Vertex* imaginary in [temp imaginary_vertex]) {
					if(TOUCH_POINT_IS_INSIDE_VERTEX(touchPos.x, touchPos.y, [imaginary x], [imaginary y])) {
						[flag beginTouchAtVertex:i];

						if([flag is_touch_at_vertex] == NO)
							[flag setBefore_imaginary_vertex:imaginary_vertex];
						else
							[flag setConnect_to_imaginary_vertex:imaginary_vertex];						
					}
					imaginary_vertex++;
				}
			}
		}

		if([flag begin_touch_at_vertex] == YES){

			if([flag is_touch_at_vertex] == NO) {
				
				Gpoint* temp = [vertexes objectAtIndex:[flag number_of_touched_vertex]];

				//もともとどこにいたかを求める
				int on_bound;
				if([flag before_imaginary_vertex] == CONNECT_TO_ORIGINAL_VERTEX)
					on_bound = [temp is_on_boundary];
				else {
					on_bound = [temp imaginary_on_boundary];
					[flag setBefore_touched_vertex: CONNECT_TO_ORIGINAL_VERTEX];
				}

				//スイッチング
				for(Edge* connectingEdge in edges) {
					int side1, side2;
					int temp = [self isOnEdge:connectingEdge switching: &side1 :&side2 ];
					if(temp != NOT_ON_BOUNDARY && temp != on_bound) {
						if(side1 == NOT_ON_COMMON_POINT) {
							if([connectingEdge side1_connect_to_imaginary_vertex] == CONNECT_TO_ORIGINAL_VERTEX)
								[connectingEdge setSide1_connect_to_imaginary_vertex: 0];
							else
								[connectingEdge setSide1_connect_to_imaginary_vertex: CONNECT_TO_ORIGINAL_VERTEX];
						}

						else {
							if(side1 != CONNECT_TO_IMAGINAL_VERTEX)
								[connectingEdge setSide1_connect_to_imaginary_vertex: side1];
							else
								[connectingEdge setSide1_connect_to_imaginary_vertex: CONNECT_TO_ORIGINAL_VERTEX];
						}

						if(side2 == NOT_ON_COMMON_POINT) {
							if([connectingEdge side2_connect_to_imaginary_vertex] == CONNECT_TO_ORIGINAL_VERTEX)
								[connectingEdge setSide2_connect_to_imaginary_vertex: 0];
							else
								[connectingEdge setSide2_connect_to_imaginary_vertex: CONNECT_TO_ORIGINAL_VERTEX];
						}

						else {
							if(side2 != CONNECT_TO_IMAGINAL_VERTEX)
								[connectingEdge setSide2_connect_to_imaginary_vertex: side2];
							else
								[connectingEdge setSide1_connect_to_imaginary_vertex: CONNECT_TO_ORIGINAL_VERTEX];
						}
					}
				}
			}

			[flag setIs_selecting_edge:NO];
			beginX = beginY = endX = endY = 0;
		}

		if([flag begin_touch_at_vertex] == NO){
			beginX = touchPos.x; 
			beginY = touchPos.y;
		}
	}

	[self setNeedsDisplay];	
}

- (void) touchesMoved: (NSSet *)touches withEvent:(UIEvent *)event {

	[flag setIs_moving_vertex:YES];

	for(UITouch *touch in touches) {
		CGPoint touchPos = [touch locationInView: self];

		//頂点を移動する
		if([flag begin_touch_at_vertex] == YES){
	
			Gpoint *temp = [vertexes objectAtIndex:[flag number_of_touched_vertex]];

			Vertex* touchPoint = [[Vertex alloc] initVertex:touchPos.x :touchPos.y];

			//タッチしたところがフィールド内に入っているなら
			if([self isInField:touchPoint] != OUT_OF_FIELD)
			{
				if([temp is_on_boundary] != NOT_ON_BOUNDARY) {

					[flag setOn_common_point: NOT_ON_COMMON_POINT];
					[temp setIs_on_boundary: NOT_ON_BOUNDARY];
					[temp setImaginary_on_boundary: NOT_ON_BOUNDARY];
					[[temp imaginary_vertex] removeAllObjects];

					//付随する辺の処理
					NSMutableIndexSet* targetIndexes = [NSMutableIndexSet indexSet];
					NSUInteger index = 0;
					for(Edge* tempedge in edges) {

						if([tempedge side1] == [temp vertex_number] && [tempedge side2] == [temp vertex_number])
							[targetIndexes addIndex:index];

						if([tempedge side1] == [temp vertex_number])
							[tempedge setSide1_connect_to_imaginary_vertex: CONNECT_TO_ORIGINAL_VERTEX];

						if([tempedge side2] == [temp vertex_number])
							[tempedge setSide2_connect_to_imaginary_vertex: CONNECT_TO_ORIGINAL_VERTEX];

						index++;
					}
					[edges removeObjectsAtIndexes: targetIndexes];

					NSMutableIndexSet* targetIndexes2 = [NSMutableIndexSet indexSet];
					NSUInteger index2 = 0;
					Edge *tempedge2;
					for(Edge* tempedge in edges) {
						if([tempedge side1_connect_to_imaginary_vertex] == CONNECT_TO_ORIGINAL_VERTEX &&
							 [tempedge side2_connect_to_imaginary_vertex] == CONNECT_TO_ORIGINAL_VERTEX) {
							for(int i = index2+1; i < [edges count]; i++) {
								tempedge2 = [edges objectAtIndex:i];
								if([tempedge2 side1_connect_to_imaginary_vertex] == CONNECT_TO_ORIGINAL_VERTEX &&
									 [tempedge2 side2_connect_to_imaginary_vertex] == CONNECT_TO_ORIGINAL_VERTEX)
									if((([tempedge side1] == [tempedge2 side1]) && ([tempedge side2] == [tempedge2 side2])) ||
										 (([tempedge side1] == [tempedge2 side2]) && ([tempedge side2] == [tempedge2 side1])))
										[targetIndexes2 addIndex:i];
							}
						}
						index2++;
					}
					[edges removeObjectsAtIndexes: targetIndexes2];
				}

				[temp initDrawVertexPoint: touchPos.x: touchPos.y];
			}

			//フィールドの外に出たが、頂点が境界線に近い場合、頂点クラスにフラグを立て、仮想頂点を設定する
			else if([temp is_on_boundary] == NOT_ON_BOUNDARY) {

				//通過した境界線を確定する
				Vertex* edgeAbegin = [[Vertex alloc] initVertex:[temp center_x] :[temp center_y]];
				Vertex* edgeAend = [[Vertex alloc] initVertex:touchPos.x :touchPos.y];
				Vertex *edgeBbegin = [Vertex alloc], *edgeBend = [Vertex alloc];
				for(int i=0; i < [[field points] count] ; i++) {
					edgeBbegin = [edgeBbegin initVertex: [[[field points] objectAtIndex: i] x] + iPad_WIDTH_CENTER : [[[field points] objectAtIndex: i] y] + iPad_HEIGHT_CENTER ];
					if(i == [[field points] count] - 1)
						edgeBend = [edgeBend initVertex: [[[field points] objectAtIndex: 0] x] + iPad_WIDTH_CENTER : [[[field points] objectAtIndex: 0] y] + iPad_HEIGHT_CENTER ];
					else
						edgeBend = [edgeBend initVertex: [[[field points] objectAtIndex: i+1] x] + iPad_WIDTH_CENTER : [[[field points] objectAtIndex: i+1] y] + iPad_HEIGHT_CENTER ] ;

					if([self isCrossed:edgeAbegin :edgeAend :edgeBbegin :edgeBend]) {
						passing_edge = i;
						break;
					}
				}

				if(passing_edge == OUT_OF_FIELD)
					passing_edge = [self isInField:[[Vertex alloc] initVertex:[temp center_x] :[temp center_y]]];

				if(passing_edge != OUT_OF_FIELD) {
					[temp setIs_on_boundary: passing_edge];

					if(is_oriented == YES){
						if(passing_edge % 4 == 0 || passing_edge % 4 == 1)
							[temp setImaginary_on_boundary:(passing_edge + 2)];
						else
							[temp setImaginary_on_boundary:(passing_edge - 2)];
					}

					else {
						if(genus != 1) {
							if(passing_edge % 2 == 0)
								[temp setImaginary_on_boundary:(passing_edge + 1)];
							else
								[temp setImaginary_on_boundary:(passing_edge - 1)];
						}
						
						else {
							if(passing_edge < [[field points] count]/2)
								[temp setImaginary_on_boundary:(passing_edge + [[field points] count]/2)];
							else
								[temp setImaginary_on_boundary:(passing_edge - [[field points] count]/2)];									
						}
					}

					[self setVertexOnBoundary: touchPoint: temp];
					[self setImaginaryVertex: temp];
				}
			}
		}
	}
	[self setNeedsDisplay];
}

//iPhoneから手が離れたとき
- (void) touchesEnded: (NSSet *)touches withEvent:(UIEvent *)event{

	for(UITouch *touch in touches) {
		CGPoint touchPos = [touch locationInView: self];

		int numbers_of_vertex = [vertexes count];
		int numbers_of_edge = [edges count];
		
		//頂点の作成
		if(touch.tapCount == 2 && [flag is_touch_at_vertex] == NO){
			double _x = touchPos.x;
			double _y = touchPos.y;
			Vertex *tempX = [[Vertex alloc] initVertex:_x :_y];

			if([self isInField:tempX] != OUT_OF_FIELD){
				Gpoint *vertex = [[Gpoint alloc] initGpoint: touchPos.x : touchPos.y];
				[vertexes addObject:vertex];
			
				//すでにどこかの頂点をタップ→辺も同時作成
				if([flag is_touch_once] == YES){
					Gpoint *temp = [vertexes objectAtIndex:[flag number_of_touched_vertex]];
					
					int sideA = [vertex vertex_number];
					int sideB = [temp vertex_number];
					Edge *tempedge = [[Edge alloc] initEdge: sideA: sideB];

					if([flag before_imaginary_vertex] != CONNECT_TO_ORIGINAL_VERTEX) {
						[tempedge setSide2_connect_to_imaginary_vertex:[flag before_imaginary_vertex]];
						[flag setBefore_imaginary_vertex: CONNECT_TO_ORIGINAL_VERTEX];
						[flag setConnect_to_imaginary_vertex: CONNECT_TO_ORIGINAL_VERTEX];
					}
					[edges addObject: tempedge];
				}

				passing_edge = [self isInField:tempX];
				if(passing_edge != OUT_OF_FIELD) {
					if([self isNearBoundary: vertex]) {
						[vertex setIs_on_boundary: passing_edge];
						
						if(is_oriented == YES){
							if(passing_edge % 4 == 0 || passing_edge % 4 == 1)
								[vertex setImaginary_on_boundary:(passing_edge + 2)];
							else
								[vertex setImaginary_on_boundary:(passing_edge - 2)];
						}
						else {
							if(passing_edge % 2 == 0)
								[vertex setImaginary_on_boundary:(passing_edge + 1)];
							else
								[vertex setImaginary_on_boundary:(passing_edge -1)];
						}
						
						[self setVertexOnBoundary: [[Vertex alloc] initVertex:touchPos.x :touchPos.y] :vertex];
						
						if([[vertex imaginary_vertex] count] == 0)
							[self setImaginaryVertex: vertex];
					}
				}				
			}
			[flag allReset];
		}

		//頂点を作成する以外の場合
		else{

			//既にどこかの頂点をタップしている状況
			if([flag is_touch_at_vertex] == YES){

				//同じ頂点をタップ→頂点とそれに付随する辺の削除
				if([flag number_of_touched_vertex] == [flag before_touched_vertex] && [flag begin_touch_at_vertex] == YES){
					Gpoint *tempvertex = [vertexes objectAtIndex:[flag number_of_touched_vertex]];

					if([flag before_imaginary_vertex] == [flag connect_to_imaginary_vertex]) {

						NSMutableIndexSet* targetIndexes = [NSMutableIndexSet indexSet];
						NSUInteger index = 0;
						for(Edge* tempedge in edges) {
							if(([tempedge side1] == [tempvertex vertex_number]) || ([tempedge side2] == [tempvertex vertex_number])){
								[targetIndexes addIndex:index];
							}
							index++;
						}
						[edges removeObjectsAtIndexes:targetIndexes];

						[vertexes removeObjectAtIndex: [flag before_touched_vertex]];
					}
					
					else {
						Edge *newEdge = [[Edge alloc] initEdge: [tempvertex vertex_number] : [tempvertex vertex_number]];
						[newEdge setSide1_connect_to_imaginary_vertex: [flag before_imaginary_vertex]];
						[newEdge setSide2_connect_to_imaginary_vertex: [flag connect_to_imaginary_vertex]];
						[edges addObject:newEdge];
					}
					
					[flag allReset];
				}

				//違う頂点をタップした場合→辺を作成 もしすでに辺が作成されているなら消去
				else if([flag number_of_touched_vertex] != [flag before_touched_vertex]){

					Gpoint *tempA = [vertexes objectAtIndex:[flag number_of_touched_vertex]];
					Gpoint *tempB = [vertexes objectAtIndex:[flag before_touched_vertex]];
					int sideA = [tempA vertex_number];
					int sideB = [tempB vertex_number];

					//すでに辺が作成されている場合
					BOOL isEdge = NO;
					for(int i=0; i<numbers_of_edge; i++){
						Edge *tempedge = [edges objectAtIndex:i];
						if((sideA == [tempedge side1] && sideB == [tempedge side2]) || (sideB == [tempedge side1] && sideA == [tempedge side2])){
							if(([flag before_imaginary_vertex] == [tempedge side1_connect_to_imaginary_vertex] && 
								 [flag connect_to_imaginary_vertex] == [tempedge side2_connect_to_imaginary_vertex]) ||
								 ([flag before_imaginary_vertex] == [tempedge side2_connect_to_imaginary_vertex] && 
									[flag connect_to_imaginary_vertex] == [tempedge side1_connect_to_imaginary_vertex])){
								[edges removeObjectAtIndex:i];
								isEdge =YES;
								break;
							}
						}
					}

					//辺の作成
					if(isEdge == NO){

						Edge *tempedge = [[Edge alloc] initEdge: sideA: sideB];

						if([flag before_imaginary_vertex] != CONNECT_TO_ORIGINAL_VERTEX) {
							[tempedge setSide2_connect_to_imaginary_vertex:[flag before_imaginary_vertex]];
							[flag setBefore_imaginary_vertex: CONNECT_TO_ORIGINAL_VERTEX];
						}

						if([flag connect_to_imaginary_vertex] != CONNECT_TO_ORIGINAL_VERTEX) {
							[tempedge setSide1_connect_to_imaginary_vertex:[flag connect_to_imaginary_vertex]];							
							[flag setConnect_to_imaginary_vertex: CONNECT_TO_ORIGINAL_VERTEX];
						}

						[edges addObject: tempedge];
					}

					[flag allReset];
				}

				//何もないところでタップ→選択消去
				else{
					int tempnum = [flag number_of_touched_vertex];
					[flag allReset];
					[flag setIs_touch_once:YES];
					[flag setNumber_of_touched_vertex:tempnum];
				}
			}			

			//まだどこかの頂点をタップしておらず、頂点の移動がない場合→タップしたところが頂点の上か判定
			else if([flag is_moving_vertex] == NO) {
				[flag setIs_touch_once:NO];
				[flag setIs_selecting_edge:NO];

				for(Edge* tempedge in edges)
					[tempedge setSelected:NO];

				//タップしたところが頂点の上かどうか
				for(int i=0; i<numbers_of_vertex; i++) {

					Gpoint *temp = [vertexes objectAtIndex:i];

					if(TOUCH_POINT_IS_INSIDE_VERTEX(touchPos.x, touchPos.y, [temp center_x], [temp center_y])){
						[flag setIs_touch_at_vertex: YES];
						[flag isTouchAtVertex: i];
						[flag setBefore_touched_vertex: i];
						[flag setBegin_touch_at_vertex: NO];
						break;
					}

					int imaginary_vertex_number = 0;
					for(Vertex *imaginary_temp in [temp imaginary_vertex]) {
						if(TOUCH_POINT_IS_INSIDE_VERTEX(touchPos.x, touchPos.y, [imaginary_temp x], [imaginary_temp y])){
							[flag setIs_touch_at_vertex: YES];
							[flag isTouchAtVertex: i];
							[flag setBefore_touched_vertex: i];
							[flag setBegin_touch_at_vertex: NO];
							[flag setBefore_imaginary_vertex: imaginary_vertex_number];
							break;
						}
						imaginary_vertex_number++;
					}
				}
			}
			
			//辺が選択された状況の時
			else if([flag is_selecting_edge] == YES){
				draw_beginX = draw_beginY = draw_endX = draw_endY = 0;

				endX = touchPos.x;
				endY = touchPos.y;

				NSMutableIndexSet* targetIndexes = [NSMutableIndexSet indexSet];
				NSUInteger index = 0;
				BOOL no_selection = YES;
				for(Edge* tempedge in edges) {
					if([tempedge selected] == YES) {					
						if ([self checkCrossedEdges:tempedge] == YES) {
							[targetIndexes addIndex:index];
							no_selection = NO;
						}
					}
					index++;
				}
				if(no_selection == NO)
					[edges removeObjectsAtIndexes:targetIndexes];
				else
					[flag setIs_selecting_edge:NO];

				for(Edge* tempedge in edges)
					[tempedge setSelected:NO];

				[flag allReset];
			}
			
			else{

				//頂点を動かした後
				if([flag begin_touch_at_vertex] == YES) {
					Gpoint *tempvertex = [vertexes objectAtIndex:[flag number_of_touched_vertex]];

					//吸着処理
					passing_edge = [self isInField:[[Vertex alloc] initVertex:touchPos.x :touchPos.y]];
					if(passing_edge != OUT_OF_FIELD) {
						if([self isNearBoundary: tempvertex]) {
							[tempvertex setIs_on_boundary: passing_edge];

							if(is_oriented == YES){
								if(passing_edge % 4 == 0 || passing_edge % 4 == 1)
									[tempvertex setImaginary_on_boundary:(passing_edge + 2)];
								else
									[tempvertex setImaginary_on_boundary:(passing_edge - 2)];
							}
							else {
								if(genus != 1) {
									if(passing_edge % 2 == 0)
										[tempvertex setImaginary_on_boundary:(passing_edge + 1)];
									else
										[tempvertex setImaginary_on_boundary:(passing_edge -1)];
								}
								
								else {
									if(passing_edge < [[field points] count]/2)
										[tempvertex setImaginary_on_boundary:(passing_edge + [[field points] count]/2)];
									else
										[tempvertex setImaginary_on_boundary:(passing_edge - [[field points] count]/2)];									
								}
							}
							
							[self setVertexOnBoundary: [[Vertex alloc] initVertex:touchPos.x :touchPos.y] :tempvertex];

							if([[tempvertex imaginary_vertex] count] == 0)
								[self setImaginaryVertex: tempvertex];
						}
					}
				}

				//辺を選択しようと試みたときの成功、失敗の判定
				BOOL select = NO;
				if([flag begin_touch_at_vertex] == NO)
				{
					endX = touchPos.x;
					endY = touchPos.y;

					for(Edge* tempedge in edges){
						if([self checkCrossedEdges:tempedge] == YES){
							[tempedge setSelected:YES];
							select = YES;
						}
					}
				}

				[flag allReset];
				
				if(select == YES) {
					draw_beginX = beginX; draw_beginY = beginY;
					draw_endX = endX; draw_endY = endY;
					[flag setIs_selecting_edge:YES];
				}
			}
		}
		[self setNeedsDisplay];
	}
}

- (void)drawRect:(CGRect)rect {

	cgContext = UIGraphicsGetCurrentContext();

	//領域の描画ここから////////
	//矩形を描く色
	CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 1.0);

	Vertex *temp = [[field points] objectAtIndex:0];
	CGContextMoveToPoint(cgContext, [temp x] + iPad_WIDTH_CENTER, [temp y] + iPad_HEIGHT_CENTER);

	for(int i=1; i<=[[field points] count]; i++){
		if(i != [[field points] count])
			temp = [[field points] objectAtIndex:i];
		else
			temp = [[field points] objectAtIndex: 0];

		CGContextAddLineToPoint(cgContext, [temp x] + iPad_WIDTH_CENTER, [temp y] + iPad_HEIGHT_CENTER);	
	}

	CGContextStrokePath(cgContext);

	//矢印を描く	
	double rad = M_PI/9;
	for(int i=0; i < [[field arrow_point] count] - 1; i += 2){

		if(!is_oriented && genus == 1){
			double line_width;
			if((i/2) % 3 == 0) line_width = 1.0;
			else if((i/2) % 3 == 1) line_width = 4.0;
			else line_width = 7.0;
			
			CGContextSetLineWidth(cgContext, line_width);
		}
		
		Vertex *before_temp = [[field arrow_point] objectAtIndex:i];
		CGContextMoveToPoint(cgContext, [before_temp x] + iPad_WIDTH_CENTER, [before_temp y] + iPad_HEIGHT_CENTER);
		Vertex *after_temp = [[field arrow_point] objectAtIndex:(i+1)];
		CGContextAddLineToPoint(cgContext, [after_temp x] + iPad_WIDTH_CENTER, [after_temp y] + iPad_HEIGHT_CENTER);

		CGContextStrokePath(cgContext);
		
		//矢印のヒレを描く
		Vertex *top = after_temp;
		if(is_oriented && ((i/2) % 4 == 2 || (i/2) % 4 == 3))
			 top = before_temp;

		CGContextMoveToPoint(cgContext, [top x] + iPad_WIDTH_CENTER, [top y] + iPad_HEIGHT_CENTER);

		Vertex *fin_temp = [[Vertex alloc] initVertex: [[[field arrow_fin] objectAtIndex:i/2] x]: [[[field arrow_fin] objectAtIndex:i/2] y]];
		[fin_temp setX: [fin_temp x] - [top x]];
		[fin_temp setY: [fin_temp y] - [top y]];
		fin_temp = [Field Rotate:rad :fin_temp];
		[fin_temp setX: [fin_temp x] + [top x]];
		[fin_temp setY: [fin_temp y] + [top y]];
		CGContextAddLineToPoint(cgContext, [fin_temp x] + iPad_WIDTH_CENTER, [fin_temp y] + iPad_HEIGHT_CENTER);

		CGContextStrokePath(cgContext);

		CGContextMoveToPoint(cgContext, [top x] + iPad_WIDTH_CENTER, [top y] + iPad_HEIGHT_CENTER);
		[fin_temp setX: [[[field arrow_fin] objectAtIndex:i/2] x]];
		[fin_temp setY: [[[field arrow_fin] objectAtIndex:i/2] y]];

		[fin_temp setX: [fin_temp x] - [top x]];
		[fin_temp setY: [fin_temp y] - [top y]];
		fin_temp = [Field Rotate:-rad :fin_temp];
		[fin_temp setX: [fin_temp x] + [top x]];
		[fin_temp setY: [fin_temp y] + [top y]];
		CGContextAddLineToPoint(cgContext, [fin_temp x] + iPad_WIDTH_CENTER, [fin_temp y] + iPad_HEIGHT_CENTER);
		
		CGContextStrokePath(cgContext);

		//区分けする円を描く
		double centerX, centerY, sign_diameter;
		sign_diameter = (sqrt(DISTANCE([before_temp x], [before_temp y], [after_temp x], [after_temp y]))) * DRAW_SIGN_RATE;
		centerX = (([before_temp x] + [after_temp x])/2) - (sign_diameter/2) + iPad_WIDTH_CENTER;
		centerY = (([before_temp y] + [after_temp y])/2) - (sign_diameter/2) + iPad_HEIGHT_CENTER;
	
		if(is_oriented) {
			if(is_oriented && ((i/2) % 4 == 0 || (i/2) % 4 == 2))
				CGContextStrokeEllipseInRect(cgContext, CGRectMake(centerX, centerY, sign_diameter, sign_diameter));
			else
				CGContextFillEllipseInRect(cgContext, CGRectMake(centerX, centerY, sign_diameter, sign_diameter));
		}

		else if(!(!is_oriented && genus == 1)){
			if((i/2) % 4 == 2 || (i/2) % 4 == 3)
				CGContextStrokeEllipseInRect(cgContext, CGRectMake(centerX, centerY, sign_diameter, sign_diameter));
			else
				CGContextFillEllipseInRect(cgContext, CGRectMake(centerX, centerY, sign_diameter, sign_diameter));			
		}

		if(!(genus == 1 && !is_oriented) && !(genus == 1 && is_oriented) && !(genus == 2 && !is_oriented)) {
			if(((i/2) % 4 == 3 && is_oriented) || ((i/2) % 2 == 1 && !is_oriented)) {
				double separateX = iPad_WIDTH_CENTER, separateY = iPad_HEIGHT_CENTER;
				double arrow_diameter = ARROW_DIAMETER + 10;
				
				int index = (i/2) + 1;
				if(index == [[field points] count])
					index = 0;
				
				for(int j=1; j < ([[field points] count]/4); j++)
					arrow_diameter *= ARROW_DIAMETER_RATE;

				if((int)[[[field points] objectAtIndex:index] x] != 0 && (int)[[[field points] objectAtIndex:index] y] != 0) {
					Vertex *tempArrowVertex = [[Vertex alloc] initVertex:0 : arrow_diameter];
					double rad = ((2*M_PI)/[[field points] count]) * ((i/2)+1);
					tempArrowVertex = [Field Rotate:rad :tempArrowVertex];
					separateX = [tempArrowVertex x] + iPad_WIDTH_CENTER;
					separateY = [tempArrowVertex y] + iPad_HEIGHT_CENTER;
				}

				else if((int)([[[field points] objectAtIndex:index] x]) == 0){
					if([[[field points] objectAtIndex:index] y] < 0)
						separateY -= arrow_diameter;
					else
						separateY += arrow_diameter;
				}

				else if((int)[[[field points] objectAtIndex:index] y] == 0){
					if([[[field points] objectAtIndex:index] x] < 0)
						separateX -= arrow_diameter;
					else
						separateX += arrow_diameter;
				}

				CGContextMoveToPoint(cgContext, [[[field points] objectAtIndex:index] x]+iPad_WIDTH_CENTER, [[[field points] objectAtIndex:index] y]+iPad_HEIGHT_CENTER);
				CGContextAddLineToPoint(cgContext, separateX, separateY);
				CGContextStrokePath(cgContext);				
			}
		}
	}
	//領域の描画ここまで/////////

	//選択された頂点の色
	if([flag is_touch_at_vertex] == YES && [flag is_touch_once] == NO){
		
		//矩形を描く色
		CGContextSetRGBStrokeColor(cgContext, 0.5, 0.5, 0.5, 1.0);
		
		//塗りつぶす色
		CGContextSetRGBFillColor(cgContext, 0.5, 0.5, 0.5, 1.0);
	}

	//移動中の頂点の色
	else if([flag begin_touch_at_vertex] == YES){

		//矩形を描く色
		CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 1.0, 1.0);
		
		//塗りつぶす色
		CGContextSetRGBFillColor(cgContext, 0.0, 0.0, 1.0, 1.0);		
	}

	int selected_num = [flag number_of_touched_vertex];

	if(selected_num != NO_TOUCHED_VERTEX){
		Gpoint *temp = [vertexes objectAtIndex: selected_num];
		CGContextFillEllipseInRect(cgContext, CGRectMake([temp draw_x], [temp draw_y], DIAMETER_OF_VERTEX, DIAMETER_OF_VERTEX));

		for(Vertex* imaginary in [temp imaginary_vertex])
			CGContextFillEllipseInRect(cgContext, CGRectMake([imaginary x]-(DIAMETER_OF_VERTEX/2), [imaginary y]-(DIAMETER_OF_VERTEX/2), DIAMETER_OF_VERTEX, DIAMETER_OF_VERTEX));		
	}

	//その他の頂点描画
	//矩形を描く色
	CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 1.0);

	//塗りつぶす色
	CGContextSetRGBFillColor(cgContext, 0.0, 0.0, 0.0, 1.0);

	int number_of_vertex = [vertexes count];
	for(int i=0; i<number_of_vertex; i++)
	{
		if(i != [flag number_of_touched_vertex]){
			Gpoint *temp = [vertexes objectAtIndex:i];
			CGContextFillEllipseInRect(cgContext, CGRectMake([temp draw_x], [temp draw_y], DIAMETER_OF_VERTEX, DIAMETER_OF_VERTEX));

			//仮想頂点の描画
			for(Vertex* imaginary in [temp imaginary_vertex]) {
				CGContextFillEllipseInRect(cgContext, CGRectMake([imaginary x]-(DIAMETER_OF_VERTEX/2), [imaginary y]-(DIAMETER_OF_VERTEX/2), DIAMETER_OF_VERTEX, DIAMETER_OF_VERTEX));
			}
		}
	}
	//その他の頂点描画ここまで
	
	CGContextStrokePath(cgContext);
	
	//辺の描画
	int number_of_edge = [edges count];
	Vertex *sideA = [Vertex alloc], *sideB = [Vertex alloc];
	Vertex *imgSideA = [Vertex alloc], *imgSideB =[Vertex alloc];

	for(int i=0; i < number_of_edge; i++)
	{
		BOOL isOnEdge = NO;
		Edge *tempedge = [edges objectAtIndex:i];

		isOnEdge = [self isOnEdge:tempedge decideSideCoordinate:sideA :sideB :imgSideA :imgSideB];

		//描く色(選択されている場合)		
		if([tempedge selected] == YES){
			CGContextSetRGBStrokeColor(cgContext, 1.0, 0.0, 0.0, 1.0);
		}
		
		//矩形を描く色(選択されていない場合)
		else{
			CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 1.0);
		}

		//線の太さ
		CGContextSetLineWidth(cgContext, LINE_WIDTH);

		CGContextMoveToPoint(cgContext, [sideA x], [sideA y]);
		CGContextAddLineToPoint(cgContext, [sideB x], [sideB y]);
		CGContextStrokePath(cgContext);

		//境界上の線を描く
		if(isOnEdge) {
			CGContextMoveToPoint(cgContext, [imgSideA x], [imgSideA y]);
			CGContextAddLineToPoint(cgContext, [imgSideB x], [imgSideB y]);
			CGContextStrokePath(cgContext);			
		}
	}

	if([flag is_selecting_edge] == YES){

		//描く色
		CGContextSetRGBStrokeColor(cgContext, 0.0, 1.0, 0.0, 1.0);
		//塗りつぶす色
		CGContextSetRGBFillColor(cgContext, 1.0, 1.0, 1.0, 1.0);

		CGContextMoveToPoint(cgContext, draw_beginX, draw_beginY);
		CGContextAddLineToPoint(cgContext, draw_endX, draw_endY);
		CGContextStrokePath(cgContext);
	}
}

- (BOOL)checkCrossedEdges:(Edge *)tempedge {

	Vertex *drawEdgeBegin = [[Vertex alloc] initVertex:beginX :beginY], *drawEdgeEnd = [[Vertex alloc] initVertex:endX :endY];

	BOOL isOnEdge = NO;
	Vertex *sideA = [Vertex alloc], *sideB = [Vertex alloc];
	Vertex *imgSideA = [Vertex alloc], *imgSideB =[Vertex alloc];

	isOnEdge = [self isOnEdge:tempedge decideSideCoordinate: sideA:sideB:imgSideA:imgSideB];

	if([self isCrossed:drawEdgeBegin :drawEdgeEnd :sideA :sideB])
		return YES;
	else if(isOnEdge)
		if([self isCrossed:drawEdgeBegin :drawEdgeEnd :imgSideA	:imgSideB])
			return YES;

	return NO;
}

- (BOOL)isCrossed:(Vertex *)edgeAbegin :(Vertex *)edgeAend :(Vertex *)edgeBbegin :(Vertex *)edgeBend {

	//辺と交差しているか確認
	int lowX, lowY, highX, highY;
	double crossX = 0, crossY = 0;

	//両辺の一次関数を求める
	double inclinationA = 0;	double interceptA = 0;
	if((int)([edgeAend x] - [edgeAbegin x]) != 0 && (int)([edgeAend y] - [edgeAbegin y]) != 0)
	{
		inclinationA = ([edgeAend y] - [edgeAbegin y])/([edgeAend x] - [edgeAbegin x]);
		interceptA = [edgeAbegin y] - (inclinationA * [edgeAbegin x]);
	}

	else if((int)([edgeAend x] - [edgeAbegin x]) == 0){
		inclinationA = 0;
		interceptA = [edgeAend y];
	}

	else if((int)([edgeAend y] - [edgeAbegin y]) == 0) {
		inclinationA = [edgeAend x];
		interceptA = 0;
	}

	//両辺の一次関数を求める
	double inclinationB = 0;	double interceptB = 0;
	if (((int)([edgeBend x] - [edgeBbegin x]) != 0) && ((int)([edgeBend y] - [edgeBbegin y]) != 0)) {
		inclinationB = (([edgeBend y] - [edgeBbegin y]))/(([edgeBend x] - [edgeBbegin x]));
		interceptB = [edgeBbegin y] - (inclinationB * [edgeBbegin x]);
	}

	else if((int)([edgeBend x] - [edgeBbegin x]) == 0){
		inclinationB = 0;
		interceptB = [edgeBend y];
	}
	
	else if((int)([edgeBend y] - [edgeBbegin y]) == 0) {
		inclinationB = [edgeBend x];
		interceptB = 0;
	}
	
	//交点の抽出
	if(([edgeAend x] - [edgeAbegin x]) != 0 && ([edgeAend y] - [edgeAbegin y]) != 0 && ([edgeBend x] - [edgeBbegin x]) != 0 && ([edgeBend y] - [edgeBbegin y]) != 0) {
		crossX = (interceptB - interceptA) / (inclinationA - inclinationB);
		crossY = (inclinationA * crossX) + interceptA;
	}
	 
	else {
		if(([edgeAend x] - [edgeAbegin x]) == 0) {
			if(([edgeBend y] - [edgeBbegin y]) == 0) {
				crossX = [edgeAend x];
				crossY = [edgeBbegin y];
			}

			else {
				crossX = [edgeAend x];
				crossY = (inclinationB * crossX) + interceptB;				
			}
		}

		else if(([edgeAend y] - [edgeAbegin y]) == 0) {
			if (([edgeBend x] - [edgeBbegin x]) == 0) {
				crossX = [edgeBbegin x];
				crossY = [edgeAend y];
			}
	 
			else {
				crossX = ([edgeAend y] - interceptB)/(inclinationB);
				crossY = [edgeAend y];
			}
		}

		else if(([edgeBend x] - [edgeBbegin x]) == 0) {
			crossX = [edgeBend x];
			crossY = (inclinationA * crossX) + interceptA;
		}

		else if(([edgeBend y] - [edgeBbegin y]) == 0) {
			crossX = ([edgeBend y] - interceptA)/inclinationA;
			crossY = [edgeBend y];
		}
	}
	//交点の抽出ここまで

	if([edgeBend x] > [edgeBbegin x]){
		int temp = [edgeBend x]; [edgeBend setX: [edgeBbegin x]]; [edgeBbegin setX: temp];
	}
	 
	if([edgeBend y] > [edgeBbegin y]){
		int temp = [edgeBend y]; [edgeBend setY: [edgeBbegin y]]; [edgeBbegin setY: temp];
	}
	 
	if([edgeAend x] > [edgeAbegin x]){
		lowX = [edgeAbegin x]; highX = [edgeAend x];
	}

	else{
		 lowX = [edgeAend x]; highX = [edgeAbegin x];
	}
	 
	if([edgeAend y] > [edgeAbegin y]){
		lowY = [edgeAbegin y]; highY = [edgeAend y];
	}
	 
	else{
		lowY = [edgeAend y]; highY = [edgeAbegin y];
	}

	if(crossX >= [edgeBend x] && crossX <= [edgeBbegin x] && crossY >= [edgeBend y] && crossY <= [edgeBbegin y] &&
	 crossX >= lowX && crossX <= highX && crossY >= lowY && crossY <= highY)
		 return YES;

	return NO;
}

- (int)isOnEdge:(Edge *)tempedge switching: (int *)sideA: (int *)sideB{

	int isOnBoundA = NOT_ON_BOUNDARY, isOnBoundB = NOT_ON_BOUNDARY;
	int imgOnBoundA = NOT_ON_BOUNDARY, imgOnBoundB = NOT_ON_BOUNDARY;

	int common_point_num = NOT_ON_COMMON_POINT;

	Vertex *connectedVertexA, *connectedVertexB;
	for(int j=0; j < [vertexes count]; j++){

		Gpoint *tempvertex = [vertexes objectAtIndex:j];

		if([tempedge side1] == [tempvertex vertex_number]){
			if([tempvertex is_on_boundary] != NOT_ON_BOUNDARY && [tempvertex is_on_boundary] != ON_ALL_BOUNDARY) {
				if([tempedge side1_connect_to_imaginary_vertex] != CONNECT_TO_ORIGINAL_VERTEX) {
					isOnBoundA = [tempvertex imaginary_on_boundary];
					imgOnBoundA = [tempvertex is_on_boundary];
				}
				else {
					isOnBoundA = [tempvertex is_on_boundary];
					imgOnBoundA = [tempvertex imaginary_on_boundary];
				}
			}

			else if([tempvertex is_on_boundary] == ON_ALL_BOUNDARY) {
				isOnBoundA = ON_ALL_BOUNDARY;

				if([tempedge side1_connect_to_imaginary_vertex] != CONNECT_TO_ORIGINAL_VERTEX)
					connectedVertexA = [[tempvertex imaginary_vertex] objectAtIndex: [tempedge side1_connect_to_imaginary_vertex]];
				else
					connectedVertexA = [[Vertex alloc] initVertex:[tempvertex center_x] :[tempvertex center_y]];
					
				Vertex *common_point;
				for(int i=0; i < [[field points] count]; i++){
					common_point = [[field points] objectAtIndex:i];
					if((int)([common_point x] + iPad_WIDTH_CENTER) == (int)[connectedVertexA x] && (int)([common_point y] + iPad_HEIGHT_CENTER) == (int)[connectedVertexA y]) {
						common_point_num = i;
						break;
					}
				}				
			}
		}

		if([tempedge side2] == [tempvertex vertex_number]){
			if([tempvertex is_on_boundary] != NOT_ON_BOUNDARY && [tempvertex is_on_boundary] != ON_ALL_BOUNDARY) {
				if([tempedge side2_connect_to_imaginary_vertex] != CONNECT_TO_ORIGINAL_VERTEX) {
					isOnBoundB = [tempvertex imaginary_on_boundary];
					imgOnBoundB = [tempvertex is_on_boundary];
				}
				else {
					isOnBoundB = [tempvertex is_on_boundary];
					imgOnBoundB = [tempvertex imaginary_on_boundary];
				}
			}

			else if([tempvertex is_on_boundary] == ON_ALL_BOUNDARY) {
				isOnBoundB = ON_ALL_BOUNDARY;

				if([tempedge side2_connect_to_imaginary_vertex] != CONNECT_TO_ORIGINAL_VERTEX)
					connectedVertexB = [[tempvertex imaginary_vertex] objectAtIndex: [tempedge side2_connect_to_imaginary_vertex]];
				else
					connectedVertexB = [[Vertex alloc] initVertex:[tempvertex center_x] :[tempvertex center_y]];
				
				Vertex *common_point;
				for(int i=0; i < [[field points] count]; i++){
					common_point = [[field points] objectAtIndex:i];
					if((int)([common_point x] + iPad_WIDTH_CENTER) == (int)[connectedVertexB x] && (int)([common_point y] + iPad_HEIGHT_CENTER) == (int)[connectedVertexB y]) {
						common_point_num = i;
						break;
					}
				}				
			}
		}
	}
	
	if(isOnBoundA == isOnBoundB && isOnBoundA != NOT_ON_BOUNDARY && isOnBoundB != NOT_ON_BOUNDARY) {
		if(isOnBoundA != ON_ALL_BOUNDARY || isOnBoundB != ON_ALL_BOUNDARY) {
			*sideA = NOT_ON_COMMON_POINT;
			*sideB = NOT_ON_COMMON_POINT;
			return isOnBoundA;
		}
		
		else if(isOnBoundA == ON_ALL_BOUNDARY && isOnBoundB == ON_ALL_BOUNDARY)
			return NOT_ON_BOUNDARY;
	}

	else if((isOnBoundA == ON_ALL_BOUNDARY && isOnBoundB != NOT_ON_BOUNDARY) || (isOnBoundB == ON_ALL_BOUNDARY && isOnBoundA != NOT_ON_BOUNDARY)) {
		*sideA = NOT_ON_COMMON_POINT;
		*sideB = NOT_ON_COMMON_POINT;

		int *common;
		int imgEdge; int isEdge; int img_common_point_num;
		if(isOnBoundA == ON_ALL_BOUNDARY){
			imgEdge = imgOnBoundB; isEdge = isOnBoundB;
			common = sideA;
		}

		else if(isOnBoundB == ON_ALL_BOUNDARY) {
			imgEdge = imgOnBoundA; isEdge = isOnBoundA;
			common = sideB;
		}

		if(is_oriented) {
			if(common_point_num == isEdge) {
				img_common_point_num = imgEdge + 1;
				if(img_common_point_num == [[field points] count])
					img_common_point_num = 0;
			}
			else
				img_common_point_num = imgEdge;
		}
		
		else {
			if(common_point_num == isEdge)
				img_common_point_num = imgEdge;
			else {
				img_common_point_num = imgEdge + 1;
				if(img_common_point_num == [[field points] count])
					img_common_point_num = 0;
			}
		}

				
		Vertex *imgCommonPoint = [[field points] objectAtIndex: img_common_point_num];

		for(Gpoint *connectVertex in vertexes) {
			if([connectVertex is_on_boundary] == ON_ALL_BOUNDARY) {

				if((int)[connectVertex center_x] == (int)[imgCommonPoint x] + iPad_WIDTH_CENTER &&
					 (int)[connectVertex center_y] == (int)[imgCommonPoint y] + iPad_HEIGHT_CENTER) {
					*common = CONNECT_TO_ORIGINAL_VERTEX;
					break;
				}

				int i=0;
				for(Vertex *imgConnectedVertex in [connectVertex imaginary_vertex]) {
					if(([imgConnectedVertex x] == ([imgCommonPoint x] + iPad_WIDTH_CENTER)) &&
						 ([imgConnectedVertex y] == ([imgCommonPoint y] + iPad_HEIGHT_CENTER))) {
						*common = i;
						break;
					}
					i++;
				}
			}
		}

		return isEdge;
	}

	return NOT_ON_BOUNDARY;
}

- (BOOL)isOnEdge:(Edge *)tempedge decideSideCoordinate:(Vertex *)sideA :(Vertex *)sideB :(Vertex *)imgSideA :(Vertex *)imgSideB {

	int sideA_x, sideA_y, sideB_x, sideB_y;
	int imgSideA_x, imgSideA_y, imgSideB_x, imgSideB_y;

	int imgOnBoundA = NOT_ON_BOUNDARY, imgOnBoundB = NOT_ON_BOUNDARY;
	int isOnBoundA = NOT_ON_BOUNDARY, isOnBoundB = NOT_ON_BOUNDARY;
	int common_point_num = NOT_ON_COMMON_POINT;
	
	for(int j=0; j < [vertexes count]; j++){
		Gpoint *tempvertex = [vertexes objectAtIndex:j];
		if([tempedge side1] == [tempvertex vertex_number]){

			if([tempedge side1_connect_to_imaginary_vertex] == CONNECT_TO_ORIGINAL_VERTEX ||
				 [[tempvertex imaginary_vertex] count] == 0) {
				sideA_x = [tempvertex center_x];
				sideA_y = [tempvertex center_y];
			}
			else{
				Vertex *temp = [[tempvertex imaginary_vertex] objectAtIndex: [tempedge side1_connect_to_imaginary_vertex]];
				sideA_x = [temp x];
				sideA_y = [temp y];
			}
			
			if([tempvertex is_on_boundary] != NOT_ON_BOUNDARY && [tempvertex is_on_boundary] != ON_ALL_BOUNDARY) {
				if([tempedge side1_connect_to_imaginary_vertex] != CONNECT_TO_ORIGINAL_VERTEX) {
					imgOnBoundA = [tempvertex is_on_boundary];
					isOnBoundA = [tempvertex imaginary_on_boundary];
					imgSideA_x = [tempvertex center_x];
					imgSideA_y = [tempvertex center_y];
				}

				else {
					isOnBoundA = [tempvertex is_on_boundary];
					imgOnBoundA = [tempvertex imaginary_on_boundary];
					imgSideA_x = [[[tempvertex imaginary_vertex] objectAtIndex: 0] x];
					imgSideA_y = [[[tempvertex imaginary_vertex] objectAtIndex: 0] y];
				}
			}

			else if([tempvertex is_on_boundary] == ON_ALL_BOUNDARY) {
				imgOnBoundA = ON_ALL_BOUNDARY;

				Vertex *common_point;
				for(int i=0; i < [[field points] count]; i++){
					common_point = [[field points] objectAtIndex:i];
					if((int)([common_point x] + iPad_WIDTH_CENTER) == sideA_x && (int)([common_point y] + iPad_HEIGHT_CENTER) == sideA_y) {
						common_point_num = i;
						break;
					}
				}
			}
		}

		if([tempedge side2] == [tempvertex vertex_number]){

			if([tempedge side2_connect_to_imaginary_vertex] == CONNECT_TO_ORIGINAL_VERTEX ||
				 [[tempvertex imaginary_vertex] count] == 0) {
				sideB_x = [tempvertex center_x];
				sideB_y = [tempvertex center_y];
			}
			else {
				Vertex *temp = [[tempvertex imaginary_vertex] objectAtIndex: [tempedge side2_connect_to_imaginary_vertex]];
				sideB_x = [temp x];
				sideB_y = [temp y];
			}

			if([tempvertex is_on_boundary] != NOT_ON_BOUNDARY && [tempvertex is_on_boundary] != ON_ALL_BOUNDARY) {
				if([tempedge side2_connect_to_imaginary_vertex] != CONNECT_TO_ORIGINAL_VERTEX) {
					isOnBoundB = [tempvertex imaginary_on_boundary];
					imgOnBoundB = [tempvertex is_on_boundary];
					imgSideB_x = [tempvertex center_x];
					imgSideB_y = [tempvertex center_y];
				}
				
				else {
					isOnBoundB = [tempvertex is_on_boundary];
					imgOnBoundB = [tempvertex imaginary_on_boundary];
					imgSideB_x = [[[tempvertex imaginary_vertex] objectAtIndex: 0] x];
					imgSideB_y = [[[tempvertex imaginary_vertex] objectAtIndex: 0] y];
				}
			}
			
			else if([tempvertex is_on_boundary] == ON_ALL_BOUNDARY) {
				imgOnBoundB = ON_ALL_BOUNDARY;
				Vertex *common_point;
				for(int i=0; i < [[field points] count]; i++){
					common_point = [[field points] objectAtIndex:i];
					if((int)([common_point x] + iPad_WIDTH_CENTER) == sideB_x && (int)([common_point y] + iPad_HEIGHT_CENTER) == sideB_y) {
						common_point_num = i;
						break;
					}
				}				
			}
		}
	}

	[sideA setX: sideA_x]; [sideA setY: sideA_y]; [sideB setX: sideB_x]; [sideB setY: sideB_y];

	if(imgOnBoundA == imgOnBoundB && imgOnBoundA != NOT_ON_BOUNDARY && imgOnBoundB != NOT_ON_BOUNDARY) {
		if(imgOnBoundA != ON_ALL_BOUNDARY || imgOnBoundB != ON_ALL_BOUNDARY) {
			[imgSideA setX: imgSideA_x]; [imgSideA setY: imgSideA_y]; [imgSideB setX: imgSideB_x]; [imgSideB setY: imgSideB_y];
		}

		else {
			Vertex *common_pointA;
			Vertex *common_pointB;

			for(int i=0; i < [[field points] count]; i++){
				common_pointA = [[field points] objectAtIndex:i];
				if(i == [[field points] count] -1)
					common_pointB = [[field points] objectAtIndex:0];
				else
					common_pointB = [[field points] objectAtIndex:i+1];

				if(((int)([common_pointA x] + iPad_WIDTH_CENTER) == sideA_x && (int)([common_pointA y] + iPad_HEIGHT_CENTER) == sideA_y &&
					  (int)([common_pointB x] + iPad_WIDTH_CENTER) == sideB_x && (int)([common_pointB y] + iPad_HEIGHT_CENTER) == sideB_y) ||
					 ((int)([common_pointA x] + iPad_WIDTH_CENTER) == sideB_x && (int)([common_pointA y] + iPad_HEIGHT_CENTER) == sideB_y &&
						(int)([common_pointB x] + iPad_WIDTH_CENTER) == sideA_x && (int)([common_pointB y] + iPad_HEIGHT_CENTER) == sideA_y)) {
					int numA, numB;
					if(is_oriented){
						if(i % 4 == 0 || i % 4 == 1) {
							numA = i+2;

							if(i+3 == [[field points] count])
								numB = 0;
							else
								numB = i+3;
						}
						else {
							numA = i-1;
							numB = i-2;
						}
					}
					else {
						if(i % 2 == 0) {
							numA = i+1;
							
							if(i+3 == [[field points] count])
								numB = 0;
							else
								numB = i+2;
						}
						else {
							numA = i;
							numB = i-1;
						}
					}
					[imgSideA setX: ([[[field points] objectAtIndex:numA] x] + iPad_WIDTH_CENTER) ];
					[imgSideA setY: ([[[field points] objectAtIndex:numA] y] + iPad_HEIGHT_CENTER) ];
					[imgSideB setX: ([[[field points] objectAtIndex:numB] x] + iPad_WIDTH_CENTER) ];
					[imgSideB setY: ([[[field points] objectAtIndex:numB] y] + iPad_HEIGHT_CENTER) ];						 
				}
			}
		}

		return YES;
	}

	else if((imgOnBoundA == ON_ALL_BOUNDARY && imgOnBoundB != NOT_ON_BOUNDARY) || (imgOnBoundB == ON_ALL_BOUNDARY && imgOnBoundA != NOT_ON_BOUNDARY)) {

		int isEdge;	int imgEdge;
		if(imgOnBoundB == ON_ALL_BOUNDARY) {
			isEdge = isOnBoundA;
			imgEdge = imgOnBoundA;
		}
		else if(imgOnBoundA == ON_ALL_BOUNDARY) {
			isEdge = isOnBoundB;
			imgEdge = imgOnBoundB;
		}

		BOOL isOnEdge = NO;
		if(isEdge == common_point_num || isEdge == common_point_num - 1)
			isOnEdge = YES;
		else if(common_point_num == 0 && isEdge == ([[field points] count] - 1))
			isOnEdge = YES;

		if(isOnEdge){
			int img_common_point_num;
			if(is_oriented) {
				if(common_point_num == isEdge) {
					img_common_point_num = imgEdge + 1;
					if(img_common_point_num == [[field points] count])
						img_common_point_num = 0;
				}
				else
					img_common_point_num = imgEdge;
			}

			else {
				if(common_point_num == isEdge)
					img_common_point_num = imgEdge;
				else {
					img_common_point_num = imgEdge + 1;				
					if(img_common_point_num == [[field points] count])
						img_common_point_num = 0;
				}
			}


			if(imgOnBoundB == ON_ALL_BOUNDARY) {
				imgSideB_x = [[[field points] objectAtIndex: img_common_point_num] x] + iPad_WIDTH_CENTER;
				imgSideB_y = [[[field points] objectAtIndex: img_common_point_num] y] + iPad_HEIGHT_CENTER;
			}

			else if(imgOnBoundA == ON_ALL_BOUNDARY) {
				imgSideA_x = [[[field points] objectAtIndex: img_common_point_num] x] + iPad_WIDTH_CENTER;
				imgSideA_y = [[[field points] objectAtIndex: img_common_point_num] y] + iPad_HEIGHT_CENTER;				
			}

			[imgSideA setX: imgSideA_x]; [imgSideA setY: imgSideA_y]; [imgSideB setX: imgSideB_x]; [imgSideB setY: imgSideB_y];
			return YES;
		}
	}

	return NO;
}

//tempvertexはtouchPos
-(int)isInField:(Vertex *)tempvertex {

	if([tempvertex y] > iPad_HEIGHT_CENTER + FIELD_DIAMETER || [tempvertex y] < iPad_HEIGHT_CENTER - FIELD_DIAMETER)
		return OUT_OF_FIELD;

	//どの辺と比較するかを決定する
	int area = 0; Vertex *tempA, *tempB;
	for(int i=0; i<[[field points] count]/2; i++)
	{
		tempA = [[field points] objectAtIndex:i];
		tempB = [[field points] objectAtIndex:i+1];

		if((([tempA y] + iPad_HEIGHT_CENTER) > [tempvertex y]) && (([tempB y] + iPad_HEIGHT_CENTER) < [tempvertex y]))
			break;
		else if(([tempA y] + iPad_HEIGHT_CENTER) == [tempvertex y])
			break;
		area++;
	}	

	Vertex *field_edge; int edge_number;
	if([tempvertex x] <= iPad_WIDTH_CENTER)
		edge_number = area;
	else
		edge_number = [[field edges] count]-area-1;

	field_edge = [[field edges] objectAtIndex: edge_number];

	//種数１のオリエンタブル以外
	if((is_oriented != YES || genus != 1)){
	
		double on_edge;
		//境界線が x=αの式
		if([field_edge y] == 0)
			on_edge = [field_edge x] + iPad_WIDTH_CENTER;
		else
			on_edge = ((([tempvertex y] - iPad_HEIGHT_CENTER) - [field_edge y])/[field_edge x]) + iPad_WIDTH_CENTER;

		if([tempvertex x] > iPad_WIDTH_CENTER) {
			if([tempvertex x] < on_edge)
				return edge_number;
			else {
				passing_edge = edge_number;
				return OUT_OF_FIELD;
			}
		}

		else {
			if([tempvertex x] > on_edge)
				return edge_number;
			else {
				passing_edge = edge_number;
				return OUT_OF_FIELD;
			}
		}
	}

	//種数１のオリエンタブル
	else {
		Vertex *side = [Field Rotate: (M_PI/4): [[Vertex alloc] initVertex: 0:FIELD_DIAMETER]];

		double sideA, sideB, sideC, sideD;
		sideA = [side x] + iPad_WIDTH_CENTER; sideB = [side y] + iPad_HEIGHT_CENTER;
		sideC = -[side x] + iPad_WIDTH_CENTER; sideD = -[side y] + iPad_HEIGHT_CENTER;

		if(fabs([tempvertex x] - sideA) < DIAMETER_OF_VERTEX)
			passing_edge = 0;

		else if(fabs([tempvertex y] - sideB) < DIAMETER_OF_VERTEX)
			passing_edge = 3;

		else if(fabs([tempvertex x] - sideC) < DIAMETER_OF_VERTEX)
			passing_edge = 2;
		
		else if(fabs([tempvertex y] - sideD) < DIAMETER_OF_VERTEX)
			passing_edge = 1;

		if([tempvertex x] > sideA && [tempvertex x] < sideC && [tempvertex y] < sideB && [tempvertex y] > sideD) {
			if(passing_edge == OUT_OF_FIELD)
				passing_edge = 0;
			return passing_edge;
		}
		else
			return OUT_OF_FIELD;
	}
}

-(BOOL)isNearBoundary:(Gpoint *)tempvertex {

	//種数１のオリエンタブル以外
	if(is_oriented != YES || genus != 1){
		
		Vertex *bound;
		if(passing_edge != OUT_OF_FIELD)
			bound = [[field edges] objectAtIndex:passing_edge];
		else
			return NO;


		//x=αの一次関数の場合
		if([bound y] == 0) {
			if (fabs((([bound x] + iPad_WIDTH_CENTER) - [tempvertex center_x])) < DIAMETER_OF_VERTEX/2)
				return YES;
			else
				return NO;
		}
		
		//切片と傾きのある一次関数の場合
		else {
			double pos_x = [tempvertex center_x] - iPad_WIDTH_CENTER;
			double pos_y = [tempvertex center_y] - iPad_HEIGHT_CENTER;
			double distance = fabs((-[bound x]) * pos_x + pos_y + (-[bound y]))/sqrt(pow([bound x], 2.0) + 1);
			if( distance < DIAMETER_OF_VERTEX/2)
				return YES;
			else
				return NO;
		}
	}

	//種数１のオリエンタブル
	else {

		Vertex *side = [Field Rotate: (M_PI/4): [[Vertex alloc] initVertex: 0:FIELD_DIAMETER]];
		
		double sideA, sideB, sideC, sideD;
		sideA = [side x] + iPad_WIDTH_CENTER;	sideB = [side y] + iPad_HEIGHT_CENTER;
		sideC = -[side x] + iPad_WIDTH_CENTER; sideD = -[side y] + iPad_HEIGHT_CENTER;

		if(fabs([tempvertex center_x] - sideA) < DIAMETER_OF_VERTEX/2)
			return YES;
		
		if(fabs([tempvertex center_y] - sideB) < DIAMETER_OF_VERTEX/2)
			return YES;

		if(fabs([tempvertex center_x] - sideC) < DIAMETER_OF_VERTEX/2)
			return YES;

		if(fabs([tempvertex center_y] - sideD) < DIAMETER_OF_VERTEX/2)
			return YES;
		
		return NO;
	}
}

-(void)setVertexOnBoundary:(Vertex *)touchPosition :(Gpoint *)tempvertex {

	Vertex *tempedge; double inclination, intercept;
	Vertex *bound = [[field edges] objectAtIndex:passing_edge];
		
	if((int)[bound x] != 0 && (int)[bound y] != 0) {
		inclination = -[bound x];
		intercept = [tempvertex center_y] - (inclination * [tempvertex center_x]);
	}

	else if((int)[bound x] == 0) {
		inclination = [tempvertex center_x];
		intercept = 0;
	}

	else if((int)[bound y] == 0) {
		inclination = 0;
		intercept = [tempvertex center_y];		
	}

	tempedge = [[Vertex alloc] initVertex:inclination :intercept];


	//種数１のオリエンタブル以外
	if(is_oriented != YES || genus != 1) {

		//境界線がx=αの一次関数の場合
		if([bound y] == 0) {

			//頂点と触れている場所が作る一次関数が切片と傾きを持つ場合
			if([tempedge x] != 0)
				[tempvertex initDrawVertexPoint: ([bound x] + iPad_WIDTH_CENTER): (([bound x] + iPad_WIDTH_CENTER) * inclination + intercept)];

			//y=αの場合
			else
				[tempvertex initDrawVertexPoint : ([bound x] + iPad_WIDTH_CENTER): [tempedge y]];
		}

		//境界線が切片と傾きのある一次関数の場合
		else {
			double cross_x, cross_y;
			double bound_intercept = [bound y] + iPad_HEIGHT_CENTER-(iPad_WIDTH_CENTER*[bound x]);

			if([tempedge x] == 0 && [tempedge y] == 0) {
				cross_x = [tempvertex center_x];
				cross_y = [tempvertex center_y];
			}

			//頂点と触れている場所が作る一次関数がy=αの場合
			else if([tempedge x] == 0) {
				cross_x = ([tempedge y] - bound_intercept)/[bound x];
				cross_y = [tempedge y];
			}

			//頂点と触れている場所が作る一次関数がx=αの場合
			else if([tempedge y] == 0) {
				cross_x = [tempedge x];
				cross_y = [tempedge x] * [bound x] + bound_intercept;
			}

			//一般的な一次関数の場合
			else {
				cross_x = (intercept - bound_intercept) / ([bound x] - inclination);
				cross_y = (inclination * cross_x) + intercept;
			}

			[tempvertex initDrawVertexPoint:cross_x :cross_y];
		}

		//vertexの位置が境界線の端に近い場合は、そこを頂点にする
		if(!(genus == 1 && is_oriented == NO)) {
			Vertex *temp = [[field points] objectAtIndex:passing_edge];

			double distance = sqrt(SQUARE(([tempvertex center_x] - iPad_WIDTH_CENTER) - [temp x]) + SQUARE(([tempvertex center_y] - iPad_HEIGHT_CENTER) - [temp y]));

			if(distance <= ABSORPTION_AREA) {
				[flag setOn_common_point: passing_edge];
				[tempvertex setIs_on_boundary: ON_ALL_BOUNDARY];
				[tempvertex setImaginary_on_boundary: NOT_ON_BOUNDARY];
				[tempvertex initDrawVertexPoint:([temp x] + iPad_WIDTH_CENTER) : ([temp y] + iPad_HEIGHT_CENTER)];
			}
		
			if(passing_edge != [[field points] count]-1)
				temp = [[field points] objectAtIndex:passing_edge+1];
			else
				temp = [[field points] objectAtIndex:0];
			distance = sqrt(SQUARE(([tempvertex center_x] - iPad_WIDTH_CENTER) - [temp x]) + SQUARE(([tempvertex center_y] - iPad_HEIGHT_CENTER) - [temp y]));
			if(distance <= ABSORPTION_AREA) {
				[flag setOn_common_point: passing_edge+1];
				[tempvertex setIs_on_boundary:ON_ALL_BOUNDARY];
				[tempvertex setImaginary_on_boundary: NOT_ON_BOUNDARY];
				[tempvertex initDrawVertexPoint:([temp x] + iPad_WIDTH_CENTER) : ([temp y] + iPad_HEIGHT_CENTER)];
			}
		}
	}

	//種数１のオリエンタブル
	else {
		BOOL no_common_point = YES;
		int point = 0;
		for(Vertex *temp in [field points]) {
			double distance = sqrt(SQUARE(([tempvertex center_x] - iPad_WIDTH_CENTER) - [temp x]) + SQUARE(([tempvertex center_y] - iPad_HEIGHT_CENTER) - [temp y]));
			if(distance <= ABSORPTION_AREA) {
				no_common_point = NO;
				[flag setOn_common_point: point];
				[tempvertex setIs_on_boundary:ON_ALL_BOUNDARY];
				[tempvertex setImaginary_on_boundary: NOT_ON_BOUNDARY];
				[tempvertex initDrawVertexPoint: ([temp x] + iPad_WIDTH_CENTER): ([temp y] + iPad_HEIGHT_CENTER)];
			}
			point++;
		}

		if(no_common_point) {
			Vertex *side = [Field Rotate: (M_PI/4): [[Vertex alloc] initVertex: 0:FIELD_DIAMETER]];

			double sideA, sideB, sideC, sideD;		
			sideA = [side x] + iPad_WIDTH_CENTER; sideB =  [side y] + iPad_HEIGHT_CENTER;		
			sideC = -[side x] + iPad_WIDTH_CENTER; sideD = -[side y] + iPad_HEIGHT_CENTER;

			switch (passing_edge) {
				case 0:
					if([tempedge x] != 0)
						[tempvertex initDrawVertexPoint:sideA : ([tempedge x] * sideA) + [tempedge y]];
					else
						[tempvertex initDrawVertexPoint:sideA :[tempedge y]];
					break;

				case 1:
					if([tempedge y] != 0)
						[tempvertex initDrawVertexPoint:(sideD - intercept)/inclination : sideD];
					else
						[tempvertex initDrawVertexPoint:[tempedge x] : sideD];
					break;
					
				case 2:
					if([tempedge x] != 0)
						[tempvertex initDrawVertexPoint:sideC : (inclination*sideC)+intercept];
					else
						[tempvertex initDrawVertexPoint:sideC :[tempedge y]];
					break;

				case 3:
					if([tempedge y] != 0)
						[tempvertex initDrawVertexPoint:(sideB-intercept)/inclination : sideB];
					else
						[tempvertex initDrawVertexPoint:[tempedge x] : sideB];
					break;

				default:
					break;
			}
		}
	}
}

-(void)setImaginaryVertex:(Gpoint *)tempvertex {
	
	if([flag on_common_point] != NOT_ON_COMMON_POINT) {

		[[tempvertex imaginary_vertex] removeAllObjects];
		for(int i=0; i < [[field points] count]; i++) {
			if([flag on_common_point] != i) {
				Vertex *imaginary_vertex = [[Vertex alloc] initVertex:0 :0];
				[imaginary_vertex setX:([[[field points] objectAtIndex:i] x] + iPad_WIDTH_CENTER) ];
				[imaginary_vertex setY:([[[field points] objectAtIndex:i] y] + iPad_HEIGHT_CENTER) ];
				[[tempvertex imaginary_vertex] addObject: imaginary_vertex];
			}
		}
		[flag setOn_common_point: NOT_ON_COMMON_POINT];
	}

	else {

		//原点中心に移動
		Vertex *imaginary_vertex = [[Vertex alloc] initVertex:[tempvertex center_x]-iPad_WIDTH_CENTER :[tempvertex center_y]-iPad_HEIGHT_CENTER ];

		//回転する角度を格納する変数
		double rad;

		//non-orientable
		if(is_oriented == NO) {
			if(genus != 1) {
				rad = (2*M_PI)/(double)[field number_of_vertex];

				if(passing_edge % 2 == 1)
					rad = -rad;
			}

			else
				rad = M_PI;
		}

		//orientable
		else {
			rad = acos([imaginary_vertex x] / sqrt([imaginary_vertex x]*[imaginary_vertex x] + [imaginary_vertex y] * [imaginary_vertex y]));

			if(genus != 1) {
				Vertex *bound_vertex;
				if(passing_edge % 4 == 0 || passing_edge % 4 == 1)
					bound_vertex = [[field points] objectAtIndex:passing_edge+1];
				else
					bound_vertex = [[field points] objectAtIndex:passing_edge];

				double bound_x = [bound_vertex x];
				double bound_y = [bound_vertex y];
				double rad2 = acos(bound_x / sqrt(bound_x * bound_x + bound_y * bound_y));

				if([imaginary_vertex y] >= 0) {
					if(passing_edge % 4 == 0 || passing_edge % 4 == 1)
						rad = 2*(rad2 - rad) + ((2*M_PI) / [field number_of_vertex]);
					else
						rad = -(2*(rad - rad2) + ((2*M_PI) / [field number_of_vertex]));
				}
			
				else {
					if(passing_edge % 4 == 0 || passing_edge % 4 == 1)
						rad = 2*(rad - rad2) + ((2*M_PI) / [field number_of_vertex]);
					else
						rad = -(2*(rad2 - rad) + ((2*M_PI) / [field number_of_vertex]));
				}
			}

			else {
				switch (passing_edge) {
					case 0:
						rad -= M_PI/2;
						[imaginary_vertex y] >= 0 ? (rad *= -2) : (rad *= 2);
						break;

					case 1:
						if([imaginary_vertex x] >= 0)
							rad *= 2;
						else {
							rad = M_PI - rad;
							rad *= -2;
						}
						break;

					case 2:
						[imaginary_vertex y] >= 0 ? (rad = M_PI/2 - rad) : (rad -= 3*M_PI/2);
						rad *= 2;
						break;

					case 3:
						[imaginary_vertex x] >= 0 ? (rad -= 2*M_PI) : (rad -= M_PI);
						rad *= -2;
						break;

					default:
						break;
				}
			}
		}

		//回転
		imaginary_vertex = [Field Rotate: rad :imaginary_vertex];

		//元の位置に戻す
		[imaginary_vertex setX:[imaginary_vertex x]+iPad_WIDTH_CENTER ];
		[imaginary_vertex setY:[imaginary_vertex y]+iPad_HEIGHT_CENTER ];

		[[tempvertex imaginary_vertex] addObject:imaginary_vertex];
	}
}

- (void)dealloc {
    [super dealloc];
	[vertexes dealloc];
	[flag dealloc];
}

@end