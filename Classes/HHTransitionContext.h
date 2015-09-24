//
//  HHTransitionContext.h
//  Pods
//
//  Created by buaacss on 15/9/24.
//
//

#import <UIKit/UIKit.h>

@interface HHTransitionContext : NSObject <UIViewControllerContextTransitioning>

- (instancetype)initWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController isPush:(BOOL)isPush;
@property (nonatomic, copy) void (^completionBlock)(BOOL didComplete); /// A block of code we can set to execute after having received the completeTransition: message.
@property (nonatomic, assign, getter=isAnimated) BOOL animated; /// Private setter for the animated property.
@property (nonatomic, assign, getter=isInteractive) BOOL interactive; /// Private setter for the interactive property.

@end


