//
//  Sample_ProjectAppDelegate.h
//  Sample Project
//
//  Created by Akisue on 10/09/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Sample_ProjectViewController;

@interface Sample_ProjectAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    Sample_ProjectViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet Sample_ProjectViewController *viewController;

@end

