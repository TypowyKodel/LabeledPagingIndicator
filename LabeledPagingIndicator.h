//
//  LabeledPagingIndicator.h
//  LabeledPagingIndicator
//
//  Created by Grzegorz Maciak on 26.04.2017.
//  Copyright © 2017 Grzegorz Maciak. All rights reserved.
//

/*
 This code is distributed under the terms and conditions of the MIT license:
 
 Copyright (c) 2017 Grzegorz Maciak
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <UIKit/UIKit.h>

@protocol LabeledPagingIndicatorDelegate;

@interface LabeledPagingIndicator : UIView
@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet id <LabeledPagingIndicatorDelegate> delegate;
@property (nonatomic, assign) BOOL useSwipeGesture; // if YES the delegate method `labeledPagingIndicator:didTapOnTitleViewAtIndex:targetScrollViewContentOffset:willAnimate:` is not invoked. Default is NO (pan gesture is used)
@end

@protocol LabeledPagingIndicatorDelegate <NSObject>

- (void)labeledPagingIndicator:(LabeledPagingIndicator *)indicator didTapOnTitleViewAtIndex:(NSUInteger)index targetScrollViewContentOffset:(CGPoint *)targetOffset willAnimate:(BOOL *)shouldAnimate;

@end


/** The view may be kind of UIScrollView but does not have to.
 If the view is not a UIScrollView it should be placed in container, and the view should not be layouted with constraints constraints
 */
@interface UIView (PageTitles)
@property (nonatomic, assign) UIScrollView *referenceScrollView; // you should set it to nil in the dealloc method of the owner
@property (nonatomic, assign) CGFloat visibleFragmentOfHiddenPageTitle; // values <=1.0 are considered as percentage values, values >1.0 are considered as width in points
@property (nonatomic, retain) NSArray *pageTitleViews;

- (void)layoutPageLabels:(NSArray *)subviews;
- (void)referenceScrollViewDidScroll:(UIScrollView *)scrollView;

@end
