//
// FlipBoardNavigationController.m
// iamkel.net
//
// Created by Michael henry Pantaleon on 4/30/13.
// Copyright (c) 2013 Michael Henry Pantaleon. All rights reserved.
// 
// Version 1.0
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "FlipBoardNavigationController.h"
#import <QuartzCore/QuartzCore.h>
#import "HHTransitionContext.h"
#import "HHAnimatedTransition.h"
#import "HHPanGestureInteractiveTransition.h"

#pragma mark - FlipBardNavigationController

static const CGFloat kAnimationDurationPush = 0.5f;
static const CGFloat kAnimationDurationPop = 0.3f;
static const CGFloat kAnimationDelay = 0.0f;
static const CGFloat kMaxBlackMaskAlpha = 0.5f;
static BOOL _animationInProgress;

typedef enum {
    PanDirectionNone = 0,
    PanDirectionLeft = 1,
    PanDirectionRight = 2
} PanDirection;

@interface FlipBoardNavigationController () <HHPanGestureInteractiveTransitionDelegate>
{
    CGPoint _panOrigin;
    CGFloat _percentageOffsetFromLeft;
    UIView *_tabBarContainer;
}

@property (nonatomic, strong) HHPanGestureInteractiveTransition *defaultInteractionController;

- (void) rollBackViewController;

- (UIViewController *)currentViewController;
- (UIViewController *)previousViewController;

- (void) transformAtPercentage:(CGFloat)percentage ;
- (void) completeSlidingAnimationWithOffset:(CGFloat)offset;
- (CGRect) getSlidingRectWithPercentageOffset:(CGFloat)percentage orientation:(UIInterfaceOrientation)orientation ;

@end

@implementation FlipBoardNavigationController

- (id)initWithRootViewController:(UIViewController*)rootViewController
{
    if (self = [super init]) {
        self.viewControllers = [NSMutableArray arrayWithObject:rootViewController];
        CGRect viewRect = UIScreen.mainScreen.bounds;
        
        UIViewController *rootViewController = [self.viewControllers objectAtIndex:0];
        [rootViewController willMoveToParentViewController:self];
        [self addChildViewController:rootViewController];
        
        UIView *rootView = rootViewController.view;
        rootView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        rootView.frame = viewRect;
        [self.view addSubview:rootView];
        [rootViewController didMoveToParentViewController:self];
        self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        __weak FlipBoardNavigationController *weakSelf = self;
        _defaultInteractionController = [[HHPanGestureInteractiveTransition alloc] initWithGestureRecognizerInView:self.view recognizedBlock:^(UIPanGestureRecognizer *recognizer) {
            [weakSelf popViewController];
        }];
        _defaultInteractionController.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    self.viewControllers = nil;
}

#pragma mark - PushViewController With Completion Block

- (void)pushViewController:(UIViewController *)viewController
{
    [self pushViewController:viewController completion:^{}];
}

- (void)pushViewController:(UIViewController *)viewController completion:(void(^)())completion
{
    [self pushViewController:viewController transition:UIViewAnimationOptionTransitionFlipFromRight completion:completion];
}

- (void)pushViewController:(UIViewController *)viewController transition:(UIViewAnimationOptions)transition
{
    [self pushViewController:viewController transition:transition completion:^{}];
}

- (void)pushViewController:(UIViewController *)viewController transition:(UIViewAnimationOptions)transition completion:(void(^)())completion
{
    if (_animationInProgress || !viewController) {
        return;
    }
    _animationInProgress = YES;
    viewController.hidesBottomBarWhenPushed = YES;
    viewController.view.clipsToBounds = YES;
    if (transition != UIViewAnimationOptionTransitionFlipFromRight) {
        viewController.view.alpha = 0.1;
        viewController.view.frame = self.view.bounds;
    }
    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [viewController willMoveToParentViewController:self];
    [self addChildViewController:viewController];
    if (self.viewControllers.count == 1) {
        //只有最外层显示bottomBar
        UITabBar *tabBar = self.currentViewController.tabBarController.tabBar;
        tabBar.userInteractionEnabled = NO;
        _tabBarContainer = tabBar.superview;
        [tabBar removeFromSuperview];
        [[self currentViewController].view addSubview:tabBar];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _animationInProgress = NO;
    });
    
    void(^animationCompletionBlock)() = ^() {
        [self.viewControllers addObject:viewController];
        viewController.view.transform = CGAffineTransformIdentity;
        
        //[self.previousViewController.view removeFromSuperview];
        viewController.view.frame = self.view.bounds;
        [viewController didMoveToParentViewController:self];
        if (completion) {
            completion();
        }
    };
    
    if (transition == UIViewAnimationOptionTransitionFlipFromRight) {
        id<UIViewControllerAnimatedTransitioning>animator = [[HHAnimatedTransition alloc] init];
        
        HHTransitionContext *transitionContext = [[HHTransitionContext alloc] initWithFromViewController:self.currentViewController toViewController:viewController isPush:YES];
        
        transitionContext.animated = YES;
        transitionContext.interactive = NO;
        transitionContext.completionBlock = ^(BOOL didComplete) {
            animationCompletionBlock();
            if ([animator respondsToSelector:@selector (animationEnded:)]) {
                [animator animationEnded:didComplete];
            }
        };
        
        [animator animateTransition:transitionContext];
    } else {
        [self.view addSubview:viewController.view];
        [UIView animateWithDuration:kAnimationDurationPush
                         animations:^{
                             viewController.view.alpha = 1.f;
                         }
                         completion:^(BOOL finished) {
                             animationCompletionBlock();
                         }];
    }
}

#pragma mark - PopViewController With Completion Block

- (void)popViewControllerWithCompletion:(void(^)())completion
{
    if (self.viewControllers.count < 2) {
        if (completion) {
            completion();
        };
        return;
    }
    if (_animationInProgress) {
        return;
    }
    _animationInProgress = YES;
    
    UIViewController *currentVC = [self currentViewController];
    [currentVC.view setClipsToBounds:YES];
    UIViewController *previousVC = [self previousViewController];
    
    void(^finishBlock)() = ^(){
        if ([previousVC conformsToProtocol:@protocol(FlipBoardNavigationDelegate)]) {
            self.delegate = (id<FlipBoardNavigationDelegate>)previousVC;
        } else {
            self.delegate = nil;
        }
        [currentVC.view removeFromSuperview];
        [currentVC willMoveToParentViewController:nil];
        [self.view bringSubviewToFront:previousVC.view];
        [currentVC removeFromParentViewController];
        [currentVC didMoveToParentViewController:nil];
        [self.viewControllers removeLastObject];
        if (!previousVC.hidesBottomBarWhenPushed) {
            if (_tabBarContainer != nil) {
                /*UITabBar *tabBar = previousVC.tabBarController.tabBar;
                void(^tabBarBlock)() = ^{
                    [tabBar removeFromSuperview];
                    tabBar.userInteractionEnabled = YES;
                    [_tabBarContainer addSubview:tabBar];
                };
                if (bg) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((kAnimationDurationPush + 0.2) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        tabBarBlock();
                    });
                } else {
                    tabBarBlock();
                }*/
                
                UITabBar *tabBar = previousVC.tabBarController.tabBar;
                [tabBar removeFromSuperview];
                /*if (bg) {
                    tabBar.hidden = YES;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((kAnimationDurationPush + 0.2) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        tabBar.hidden = NO;
                    });
                }*/
                tabBar.userInteractionEnabled = YES;
                [_tabBarContainer addSubview:tabBar];
            }
        }
        _animationInProgress = NO;
        if (completion) {
            completion();
        }
    };
    
    if ([UIView areAnimationsEnabled]) {
        id<UIViewControllerAnimatedTransitioning>animator = [[HHAnimatedTransition alloc] init];
        HHTransitionContext *transitionContext = [[HHTransitionContext alloc] initWithFromViewController:currentVC toViewController:previousVC isPush:NO];
        transitionContext.animated = YES;
        id<UIViewControllerInteractiveTransitioning> interactionController = [self _interactionControllerForAnimator:animator animatorIsDefault:YES];
        transitionContext.interactive = (interactionController != nil);
        transitionContext.completionBlock = ^(BOOL didComplete) {
            if (didComplete) {
                finishBlock();
            } else {
                //滑动返回取消
                _animationInProgress = NO;
            }
            [animator animationEnded:didComplete];
        };
        
        if ([transitionContext isInteractive]) {
            [interactionController startInteractiveTransition:transitionContext];
        } else {
            [animator animateTransition:transitionContext];
            //[self _finishTransitionToChildViewController:toViewController];
        }
        
        /*dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:kAnimationDurationPop
                                  delay:kAnimationDelay
                                options:UIViewAnimationOptionCurveEaseIn animations:^{
                                    [previousVC viewWillAppear:YES];
                                    currentVC.view.frame = CGRectOffset(self.view.bounds, self.view.bounds.size.width, 0);
                                    previousVC.view.transform = CGAffineTransformIdentity;
                                    previousVC.view.frame = self.view.bounds;
                                }
                             completion:^(BOOL finished) {
                                 finishBlock();
                             }];
        });*/
    } else {
        finishBlock(YES);
    }
}

- (void)popViewController
{
    [self transformAtPercentage:0];
    [self popViewControllerWithCompletion:^{}];
}

- (void)popToViewControllerForwardIndex:(NSInteger)idx withCompletion:(void (^)())completion animate:(BOOL)animate
{
    NSInteger currentIdx = [self.viewControllers indexOfObject:self.currentViewController];
    return [self popToViewControllerAtIndex:(currentIdx - idx) withCompletion:completion animate:animate];
}

- (void)popToRootViewControllerWithCompletion:(void(^)())completion
{
    return [self popToRootViewControllerWithCompletion:completion animate:NO];
}

- (void)popToRootViewControllerWithCompletion:(void(^)())completion animate:(BOOL)animate
{
    return [self popToViewControllerAtIndex:0 withCompletion:completion animate:animate];
}

- (void)popToLatestViewControllerWithClass:(Class)className withCompletion:(void(^)())completion animate:(BOOL)animate
{
    [self.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
        if ([vc isMemberOfClass:className]) {
            return [self popToViewControllerAtIndex:idx withCompletion:completion animate:animate];
        }
    }];
}

static UIImageView *bg;
- (void)popToViewControllerAtIndex:(NSInteger)idx withCompletion:(void(^)())completion animate:(BOOL)animate
{
    if (!bg) {
        UIView *view = self.currentViewController.view;
        UIGraphicsBeginImageContextWithOptions(view.frame.size, 0, 0);
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
        bg = [[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()];
        UIGraphicsEndImageContext();
        [((UIViewController *)self.viewControllers[idx]).view addSubview:bg];
    }
    
    if (self.viewControllers.count <= idx + 1) {
        [UIView setAnimationsEnabled:YES];
        //[self.view addSubview:self.currentViewController.view];
        void(^finishBlock)() = ^{
            _animationInProgress = NO;
            if (completion) {
                completion();
            }
            [self.currentViewController viewDidAppear:YES];
        };
        if (animate) {
            //self.currentViewController.tabBarController.tabBar.hidden = NO;
            [UIView animateWithDuration:kAnimationDurationPop
                             animations:^{
                                 [self.currentViewController viewWillAppear:YES];
                                 bg.transform = CGAffineTransformMakeTranslation(bg.frame.size.width, 0);
                             }
                             completion:^(BOOL finished) {
                                 finishBlock();
                                 bg.transform = CGAffineTransformIdentity;
                                 [bg removeFromSuperview];
                                 bg = nil;
                             }];
        } else {
            [self.currentViewController viewWillAppear:YES];
            finishBlock();
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((kAnimationDurationPush + 0.2) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [bg removeFromSuperview];
                bg = nil;
            });
        }
    } else {
        [UIView setAnimationsEnabled:NO];
        [self popViewControllerWithCompletion:^{
            [self popToViewControllerAtIndex:idx withCompletion:completion animate:animate];
        }];
    }   
}

- (void)rollBackViewController
{
    _animationInProgress = YES;
    
    UIViewController *vc = [self currentViewController];
    CGRect rect = CGRectMake(0, 0, vc.view.frame.size.width, vc.view.frame.size.height);
    
    [UIView animateWithDuration:0.3f
                          delay:kAnimationDelay
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         vc.view.frame = rect;
                     }
                     completion:^(BOOL finished) {
                         _animationInProgress = NO;
                     }];
}

+ (BOOL)animationInProgress
{
    return _animationInProgress;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

}

- (id<UIViewControllerInteractiveTransitioning>)_interactionControllerForAnimator:(id<UIViewControllerAnimatedTransitioning>)animationController animatorIsDefault:(BOOL)animatorIsDefault {
    
    if (self.defaultInteractionController.recognizer.state == UIGestureRecognizerStateBegan) {
        self.defaultInteractionController.animator = animationController;
        return self.defaultInteractionController;
    } else if (!animatorIsDefault) {
        HHPercentDrivenInteractiveTransition *fakeInteraction = [[HHPercentDrivenInteractiveTransition alloc] initWithAnimator:animationController];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [fakeInteraction updateInteractiveTransition:0.25];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [fakeInteraction updateInteractiveTransition:0.5];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [fakeInteraction finishInteractiveTransition];
        });
        return fakeInteraction;
    } else {
        return nil;
    }
}

#pragma mark - ChildViewController
- (UIViewController *)currentViewController {
    if (self.viewControllers.count > 0) {
        return self.viewControllers.lastObject;
    }
    return nil;
}

#pragma mark - ParentViewController
- (UIViewController *)previousViewController {
    UIViewController *result = nil;
    if ([self.viewControllers count]>1) {
        result = [self.viewControllers objectAtIndex:self.viewControllers.count - 2];
    }
    return result;
}

#pragma mark - Set the required transformation based on percentage
- (void)transformAtPercentage:(CGFloat)percentage
{
    [self previousViewController].view.transform = CGAffineTransformIdentity;
}

#pragma mark - This will complete the animation base on offset
- (void)completeSlidingAnimationWithOffset:(CGFloat)offset
{
    if (offset < UIScreen.mainScreen.bounds.size.width / 2) {
         [self popViewController];
    } else {
        [self rollBackViewController];
    }
}

#pragma mark - Get the origin and size of the visible viewcontrollers(child)
- (CGRect)getSlidingRectWithPercentageOffset:(CGFloat)percentage orientation:(UIInterfaceOrientation)orientation
{
    CGRect rectToReturn = self.view.bounds;
    rectToReturn.origin = CGPointMake(MAX(0, (1-percentage)*CGRectGetWidth(rectToReturn)), 0);
    return rectToReturn;
}

#pragma mark HHPanGestureInteractiveTransition Delegate

- (BOOL)swipeBackGestureEnable:(CGPoint)point
{
    if ([self.delegate respondsToSelector:@selector(canSwipeBack:)]) {
        return [self.delegate canSwipeBack:point];
    }
    return YES;
}

@end

#pragma mark - UIViewController Category
//For Global Access of flipViewController
@implementation UIViewController (FlipBoardNavigationController)
@dynamic flipboardNavigationController;

- (FlipBoardNavigationController *)flipboardNavigationController
{
    if([self.parentViewController isKindOfClass:[FlipBoardNavigationController class]]){
        return (FlipBoardNavigationController*)self.parentViewController;
    }
    else if([self.parentViewController.parentViewController isKindOfClass:[FlipBoardNavigationController class]]){
        return (FlipBoardNavigationController*)[self.parentViewController parentViewController];
    }
    else{
        return nil;
    }
}

@end
