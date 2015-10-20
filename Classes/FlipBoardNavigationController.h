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

#import <UIKit/UIKit.h>

@protocol FlipBoardNavigationDelegate <NSObject>

@optional
- (BOOL)canSwipeBack:(CGPoint)point;

@end

@interface FlipBoardNavigationController : UIViewController

@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (nonatomic, weak) id<FlipBoardNavigationDelegate> delegate;

- (instancetype)initWithRootViewController:(UIViewController*)rootViewController;
- (void)pushViewController:(UIViewController *)viewController;
- (void)pushViewController:(UIViewController *)viewController transition:(UIViewAnimationOptions)transition;
- (void)pushViewController:(UIViewController *)viewController completion:(void(^)())completion;
- (void)pushViewController:(UIViewController *)viewController transition:(UIViewAnimationOptions)transition completion:(void(^)())completion;
- (void)popViewController;
- (void)popViewControllerWithCompletion:(void(^)())completion;
- (void)popToRootViewControllerWithCompletion:(void(^)())completion;
- (void)popToRootViewControllerWithCompletion:(void(^)())completion animate:(BOOL)animate;
- (void)popToViewControllerForwardIndex:(NSInteger)idx withCompletion:(void (^)())completion animate:(BOOL)animate;
- (void)popToLatestViewControllerWithClass:(Class)className withCompletion:(void(^)())completion animate:(BOOL)animate;
- (void)popToViewControllerAtIndex:(NSInteger)idx withCompletion:(void(^)())completion animate:(BOOL)animate;
+ (BOOL)animationInProgress;

@end

@interface UIViewController (FlipBoardNavigationController)

@property (nonatomic, retain) FlipBoardNavigationController *flipboardNavigationController;

@end
