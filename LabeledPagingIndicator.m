//
//  LabeledPagingIndicator.m
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

#import "LabeledPagingIndicator.h"

@interface LabeledPagingIndicator ()
@property (nonatomic, weak) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, weak) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, weak) UISwipeGestureRecognizer *swipeLeftGestureRecognizer;
@property (nonatomic, weak) UISwipeGestureRecognizer *swipeRightGestureRecognizer;
@end

@implementation LabeledPagingIndicator

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self){ [self load]; }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self){ [self load]; }
    return self;
}

- (void)load {
    if (!_contentView) {
        UIView *contentView = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:contentView];
        _contentView = contentView;
    }
    
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onLabelTap:)];
    [_contentView addGestureRecognizer:tapGestureRecognizer];
    _tapGestureRecognizer = tapGestureRecognizer;
    
    UISwipeGestureRecognizer *swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipe:)];
    swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [_contentView addGestureRecognizer:swipeGestureRecognizer];
    _swipeLeftGestureRecognizer = swipeGestureRecognizer;
    
    swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipe:)];
    swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [_contentView addGestureRecognizer:swipeGestureRecognizer];
    _swipeRightGestureRecognizer = swipeGestureRecognizer;
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onIndicatorMove:)];
    [_contentView addGestureRecognizer:panGestureRecognizer];
    _panGestureRecognizer = panGestureRecognizer;
    
    self.useSwipeGesture = NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = _contentView.frame;
    frame.size.height = self.bounds.size.height;
    _contentView.frame = frame;
}

- (void)setUseSwipeGesture:(BOOL)useSwipeGesture {
    _useSwipeGesture = useSwipeGesture;
    _panGestureRecognizer.enabled = !useSwipeGesture;
    _swipeRightGestureRecognizer.enabled = useSwipeGesture;
    _swipeLeftGestureRecognizer.enabled = useSwipeGesture;
}

- (void)onLabelTap:(UITapGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:_contentView];
    NSArray *views = self.pageTitleViews;
    for (UIView *view in views) {
        if (CGRectContainsPoint(view.frame, point)) {
            NSInteger index = [views indexOfObjectIdenticalTo:view];
            UIScrollView * scrollView = self.referenceScrollView;
            CGPoint targetOffset = CGPointMake(index * scrollView.bounds.size.width, 0);
            BOOL animate = YES;
            [_delegate labeledPagingIndicator:self didTapOnTitleViewAtIndex:index targetScrollViewContentOffset:&targetOffset willAnimate:&animate];
            [scrollView setContentOffset:targetOffset animated:animate];
            break;
        }
    }
}

- (void)onIndicatorMove:(UIPanGestureRecognizer *)sender {
    static CGPoint startOffset = (CGPoint){0.0,0.0};
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            startOffset = self.referenceScrollView.contentOffset;
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [sender translationInView:self];
            self.referenceScrollView.contentOffset = CGPointMake(startOffset.x - translation.x, startOffset.y);
        }
            break;
        default: {
            UIScrollView *scrollView = self.referenceScrollView;
            CGFloat targetPageIndex = [self targetPageIndex];
            [scrollView setContentOffset:CGPointMake(targetPageIndex * scrollView.bounds.size.width, startOffset.y) animated:YES];
        }
            break;
    }
}

- (void)onSwipe:(UISwipeGestureRecognizer *)sender {
    UIScrollView *scrollView = self.referenceScrollView;
    NSInteger nextPageIndex = [self currentPageIndex];
    if (sender.direction & UISwipeGestureRecognizerDirectionRight) {
        nextPageIndex = MAX(0, nextPageIndex - 1);
    }
    else if (sender.direction & UISwipeGestureRecognizerDirectionLeft) {
        NSInteger maxIndex = [self maxPageIndex];
        nextPageIndex = MIN(maxIndex, nextPageIndex + 1);
    }
    [scrollView setContentOffset:CGPointMake(nextPageIndex * scrollView.bounds.size.width, scrollView.contentOffset.y) animated:YES];
}

#pragma mark Indexes

- (NSInteger)maxPageIndex {
    UIScrollView *scrollView = self.referenceScrollView;
    NSInteger maxIndex = MAX(0, ( round(scrollView.contentSize.width/scrollView.bounds.size.width) - 1) );
    return maxIndex;
}

- (NSInteger)currentPageIndex {
    UIScrollView *scrollView = self.referenceScrollView;
    NSInteger maxIndex = [self maxPageIndex];
    NSInteger pageOfScrollCenter = (NSInteger)((scrollView.contentOffset.x + scrollView.bounds.size.width/2.0)/scrollView.bounds.size.width);
    if (pageOfScrollCenter > maxIndex) {
        pageOfScrollCenter = maxIndex;
    }
    else if (pageOfScrollCenter < 0) {
        pageOfScrollCenter = 0;
    }
    return pageOfScrollCenter;
}

- (NSInteger)targetPageIndex {
    UIScrollView *scrollView = self.referenceScrollView;
    NSInteger pageIndex = [self currentPageIndex];
    CGFloat currentDefaultCenterOffset = pageIndex * scrollView.bounds.size.width + scrollView.bounds.size.width/2.0;
    CGFloat offsetOfScrollCenter = (NSInteger)(scrollView.contentOffset.x + scrollView.bounds.size.width/2.0);
    CGFloat quarterWidth = scrollView.bounds.size.width/4.0;
    if (offsetOfScrollCenter < currentDefaultCenterOffset - quarterWidth) {
        pageIndex = MAX(0, pageIndex - 1);
    }
    else if (offsetOfScrollCenter > currentDefaultCenterOffset + quarterWidth) {
        NSInteger maxIndex = [self maxPageIndex];
        pageIndex = MIN(maxIndex, pageIndex + 1);
    }
    return pageIndex;
}

#pragma mark -

- (void)layoutPageLabels:(NSArray *)subviews {
    [_contentView layoutPageLabels:subviews];
}

- (void)referenceScrollViewDidScroll:(UIScrollView *)scrollView {
    [_contentView referenceScrollViewDidScroll:scrollView];
}

- (CGFloat)visibleFragmentOfHiddenPageTitle {
    return _contentView.visibleFragmentOfHiddenPageTitle;
}

-(void)setVisibleFragmentOfHiddenPageTitle:(CGFloat)visibleFragment{
    _contentView.visibleFragmentOfHiddenPageTitle = visibleFragment;
}

- (NSArray *)pageTitleViews {
    return _contentView.pageTitleViews;
}

-(void)setPageTitleViews:(NSArray *)pageTitleViews{
    for (UIView *label in pageTitleViews) {
        [_contentView addSubview:label];
    }
    _contentView.pageTitleViews = pageTitleViews;
}

- (UIScrollView *)referenceScrollView {
    return _contentView.referenceScrollView;
}

-(void)setReferenceScrollView:(UIScrollView *)referenceScrollView{
    _contentView.referenceScrollView = referenceScrollView;
}

@end


#import <objc/runtime.h>
#import "UIView+Find.h"

@implementation UIView (PageTitles)

- (CGFloat)visibleFragmentOfHiddenPageTitle {
    return [objc_getAssociatedObject(self, @selector(visibleFragmentOfHiddenPageTitle)) floatValue];
}

-(void)setVisibleFragmentOfHiddenPageTitle:(CGFloat)visibleFragment{
    objc_setAssociatedObject(self, @selector(visibleFragmentOfHiddenPageTitle), @(visibleFragment), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *)pageTitleViews {
    return objc_getAssociatedObject(self, @selector(pageTitleViews));
}

-(void)setPageTitleViews:(NSArray *)pageTitleViews{
    for (UIView *label in pageTitleViews) {
        if (!label.superview) {
            [self addSubview:label];
        }
    }
    [self layoutPageLabels:pageTitleViews];
    objc_setAssociatedObject(self, @selector(pageTitleViews), pageTitleViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIScrollView *)referenceScrollView {
    return objc_getAssociatedObject(self, @selector(referenceScrollView));
}

-(void)setReferenceScrollView:(UIScrollView *)referenceScrollView{
    objc_setAssociatedObject(self, @selector(referenceScrollView), referenceScrollView, OBJC_ASSOCIATION_ASSIGN);
}

- (CGFloat)labelStep {
    return [self isKindOfClass:[UIScrollView class]] ? (self.bounds.size.width/2.0) : (self.superview.bounds.size.width/2.0);
}

- (void)layoutPageLabels:(NSArray *)subviews {
    if (subviews == nil) subviews = self.pageTitleViews;
    
    CGFloat step = self.labelStep;
    CGFloat x = step;
    
    CGFloat visibleFragment = self.visibleFragmentOfHiddenPageTitle;
    UIScrollView *scrollView = self.referenceScrollView;
    NSInteger pageIndex = scrollView ? (NSInteger)(scrollView.contentOffset.x/scrollView.bounds.size.width) : 0;
    
    UIView *view = nil;
    CGFloat shift;
    for (NSInteger i = 0; i < subviews.count; ++i) {
        view = subviews[i];
        shift = view.bounds.size.width/2.0 - (visibleFragment > 1.0 ? visibleFragment : (view.bounds.size.width * visibleFragment));
        if (i < pageIndex) {
            shift = -shift;
        }
        else if (i == pageIndex) {
            shift = 0;
        }
        
        view.center = CGPointMake(x + shift, self.bounds.size.height/2.0);
        x += step;
    }
    if ([self isKindOfClass:[UIScrollView class]]) {
        [(UIScrollView *)self setContentSize: CGSizeMake(x, self.frame.size.height)];
    }else{
        CGRect frame = self.frame;
        frame.origin.y = 0;
        frame.size.width = x;
        self.frame = frame;
    }
}

- (void)referenceScrollViewDidScroll:(UIScrollView *)scrollView  {
    if (scrollView == nil) return;
    
    /* Update offset */
    
    CGFloat step = self.labelStep;
    CGFloat page = scrollView.contentOffset.x/scrollView.bounds.size.width;
    CGPoint point = CGPointMake(page * step, 0);
    
    if ([self isKindOfClass:[UIScrollView class]]) {
        [(UIScrollView *)self setContentOffset: point];
    }else{
        CGRect frame = self.frame;
        frame.origin.x = -point.x;
        self.frame = frame;
    }
    
    /* Layout labels */
    
    NSArray *labels = self.pageTitleViews;
    CGFloat visibleFragment = self.visibleFragmentOfHiddenPageTitle;
    
    CGFloat scrolledPages = page + 1;
    CGFloat pageOfScrollCenter = (scrollView.contentOffset.x + scrollView.bounds.size.width/2.0)/scrollView.bounds.size.width;
    NSInteger pageIndex = (NSUInteger)pageOfScrollCenter;
    
    // current tab
    UIView *tab = pageIndex < labels.count ? labels[pageIndex] : nil;
    CGPoint defaultTabCenter = CGPointZero;
    CGFloat tabMoveRange = 0.0;
    if (tab) {
        defaultTabCenter = CGPointMake((CGFloat)(pageIndex) * step + step, self.bounds.size.height/2.0);
        tabMoveRange = tab.bounds.size.width/2.0 - (visibleFragment > 1.0 ? visibleFragment : (tab.bounds.size.width * visibleFragment));
    }
    
    CGFloat partOfPageAtScrollCenter = pageOfScrollCenter - (CGFloat)pageIndex;
    CGFloat tabCenterMovePercentage; // move step percentage
    if (partOfPageAtScrollCenter < 0.5) {
        tabCenterMovePercentage = (1 - (scrolledPages - (int)scrolledPages));
        defaultTabCenter.x += (tabMoveRange * tabCenterMovePercentage);
    }
    else{
        tabCenterMovePercentage = (scrolledPages - (int)scrolledPages);
        defaultTabCenter.x += -(tabMoveRange * tabCenterMovePercentage);
    }
    
    // move step percentage
    CGFloat otherTabsCenterMovePercentage = 1 - tabCenterMovePercentage;
    
    // prev tab
    UIView *prevTab = pageIndex > 0 ? labels[pageIndex-1] : nil;
    CGPoint prevCenter = CGPointZero;
    CGFloat prevTabMoveRange = 0.0;
    if (prevTab) {
        prevCenter = CGPointMake((CGFloat)(pageIndex-1) * step + step, self.bounds.size.height/2.0);
        prevTabMoveRange = prevTab.bounds.size.width/2.0 - (visibleFragment > 1.0 ? visibleFragment : (prevTab.bounds.size.width * visibleFragment));
        
        prevCenter.x += -(prevTabMoveRange * otherTabsCenterMovePercentage);
    }
    
    // next tab
    UIView *nextTab = pageIndex < labels.count-1 ? labels[pageIndex+1] : nil;
    CGPoint nextCenter = CGPointZero;
    CGFloat nextTabMoveRange = 0.0;
    if (nextTab) {
        nextCenter = CGPointMake((CGFloat)(pageIndex+1) * step + step, self.bounds.size.height/2.0);
        nextTabMoveRange = nextTab.bounds.size.width/2.0 - (visibleFragment > 1.0 ? visibleFragment : (nextTab.bounds.size.width * visibleFragment));
        
        nextCenter.x += (nextTabMoveRange * otherTabsCenterMovePercentage);
    }
    
    prevTab.center = prevCenter;
    tab.center = defaultTabCenter;
    nextTab.center = nextCenter;
    
    // Debug
    //#define DEBUG_LABELED_PAGE_INDICATOR
#ifdef DEBUG_LABELED_PAGE_INDICATOR
#define NUMBER_WITH_VARIABLE_BINDING(var) NSNumber *n_ ## var = @(var);
    
    NSInteger pagesCount = scrollView.contentSize.width/scrollView.bounds.size.width;
    NUMBER_WITH_VARIABLE_BINDING(step);
    NUMBER_WITH_VARIABLE_BINDING(pagesCount);
    NUMBER_WITH_VARIABLE_BINDING(scrolledPages);
    NUMBER_WITH_VARIABLE_BINDING(pageOfScrollCenter);
    NUMBER_WITH_VARIABLE_BINDING(pageIndex);
    NUMBER_WITH_VARIABLE_BINDING(partOfPageAtScrollCenter);
    NUMBER_WITH_VARIABLE_BINDING(tabCenterMovePercentage);
    NUMBER_WITH_VARIABLE_BINDING(otherTabsCenterMovePercentage);
    NSString *p0_ContentOffset = NSStringFromCGPoint(self.contentOffset);
    NSString *p1_PrevOffset = [NSString stringWithFormat:@"prevTab: '%@' %@",
                               ([prevTab respondsToSelector:@selector(subviewsOfType:)] ? [(UILabel *)[prevTab subviewsOfType:[UILabel class]].firstObject text] : @""),
                               NSStringFromCGPoint(prevCenter)];
    NSString *p2_Offset = [NSString stringWithFormat:@"tab: '%@' %@",
                           ([tab respondsToSelector:@selector(subviewsOfType:)] ? [(UILabel *)[tab subviewsOfType:[UILabel class]].firstObject text] : @""),
                           NSStringFromCGPoint(defaultTabCenter)];
    NSString *p3_NextOffset = [NSString stringWithFormat:@"tab: '%@' %@",
                               ([nextTab respondsToSelector:@selector(subviewsOfType:)] ? [(UILabel *)[nextTab subviewsOfType:[UILabel class]].firstObject text] : @""),
                               NSStringFromCGPoint(nextCenter)];
    
    NSLog(@"%@",NSDictionaryOfVariableBindings(n_step,n_pagesCount,n_scrolledPages,n_pageOfScrollCenter,n_pageIndex,n_partOfPageAtScrollCenter,n_tabCenterMovePercentage,n_otherTabsCenterMovePercentage,p0_ContentOffset,p1_PrevOffset,p2_Offset,p3_NextOffset));
#endif
}

@end
