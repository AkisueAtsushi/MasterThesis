//
//  defines.h
//  SampleApplicatioin
//
//  Created by 根上 生也 on 10/08/17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

//フィールドに関係する定数
#define iPad_WIDTH 768
#define iPad_HEIGHT 1024
#define iPad_WIDTH_CENTER iPad_WIDTH/2
#define iPad_HEIGHT_CENTER iPad_HEIGHT/2
#define FIELD_DIAMETER 330

//矢印表記に関わる定数
#define ARROW_DIAMETER FIELD_DIAMETER + 58
#define ARROW_DIAMETER_RATE 0.987
#define DIFF_RATE 0.15
#define ARROW_FIN_RATE 0.1
#define DRAW_SIGN_RATE 0.095

//頂点描画に関する定数
#define DIAMETER_OF_VERTEX 16
#define CATCH_VERTEX_AREA DIAMETER_OF_VERTEX/2+5

//辺描画に関する定数
#define LINE_WIDTH 4.0

//状況判断定数
#define NO_TOUCHED_VERTEX -1
#define OUT_OF_FIELD -2

//頂点と境界線の関係を定義する定数
#define NOT_ON_COMMON_POINT -3
#define NOT_ON_BOUNDARY -4
#define ON_ALL_BOUNDARY -5

//-1以下の数字のみ定義可能
#define CONNECT_TO_ORIGINAL_VERTEX -6
#define CONNECT_TO_IMAGINAL_VERTEX -7

//吸着処理定数
#define ABSORPTION_AREA DIAMETER_OF_VERTEX+10


//定義関数
#define SQUARE(x) ((x)*(x))
#define DISTANCE(bx, by, ex, ey) (SQUARE(bx - ex)) + (SQUARE(by - ey))
#define TOUCH_POINT_IS_INSIDE_VERTEX(x, y, vx, vy) ((SQUARE(CATCH_VERTEX_AREA)) > (SQUARE(vx-x) + SQUARE(vy-y)))
