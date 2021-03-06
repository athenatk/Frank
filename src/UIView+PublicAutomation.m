//
//  UIView+PublicAutomation.m
//  Frank
//
//  Created by Pete Hodgson on 10/15/11.
//  Copyright (c) 2011 ThoughtWorks. All rights reserved.
//

#import <PublicAutomation/UIAutomationBridge.h>

#import "LoadableCategory.h"
MAKE_CATEGORIES_LOADABLE(UIView_PublicAutomation)

NSString * formatCGPointVal(NSValue *val) {
    CGPoint p = [val CGPointValue];
    return [NSString stringWithFormat:@"[%.2f, %.2f]", p.x, p.y];
}

@implementation UIView(PublicAutomation)

#pragma mark - Utils

- (CGPoint)FEX_centerPoint {
    return CGPointMake(0.5 * self.bounds.size.width, 0.5 * self.bounds.size.height);
}

- (CGPoint)FEX_pointFromX:(NSNumber*)x andY:(NSNumber*)y {
    if (CGFLOAT_IS_DOUBLE) {
		return CGPointMake([x doubleValue], [y doubleValue]);
	}
	else {
        return CGPointMake([x floatValue], [y floatValue]);
    }
}

#pragma mark - Test touch

- (BOOL)FEX_isPointInWindow:(CGPoint)point {
    CGPoint pointInWindowCoords = [self.window convertPoint:point fromView:self];
    
    return (CGRectContainsPoint(self.window.bounds, pointInWindowCoords));
}

- (BOOL)FEX_isPointInDirectViewHierarchy:(CGPoint)point touchRecipient:(UIView**)touchRecipient {
    CGPoint pointInWindowCoords = [self.window convertPoint:point fromView:self];
    
    UIView* touchedView = [self.window hitTest:pointInWindowCoords withEvent:nil];
    
    if (touchRecipient) {
        *touchRecipient = touchedView;
    }
    
    if ([touchedView isDescendantOfView:self]) {
        return YES;
    }
    else if ([self isDescendantOfView:touchedView]) {
        /* the following code implements the same functionality as `hitTest:withEvent:`
         but it doesn't ignore views with disabled user interactions */
        
        BOOL canContinue;
        
        do {
            canContinue = NO;
            
            CGPoint testedPoint = [self.window convertPoint:pointInWindowCoords toView:touchedView];
            NSArray* subviews = [[touchedView.subviews copy] autorelease];
            
            for (NSUInteger i = subviews.count; i > 0; i--) {
                UIView* subview = [subviews objectAtIndex:(i - 1)];
                
                if (subview.alpha < 0.01 || subview.hidden) {
                    continue;
                }
                
                CGPoint testedPointInSubviewCoords = [subview convertPoint:testedPoint fromView:touchedView];
                
                if ([subview pointInside:testedPointInSubviewCoords withEvent:nil]) {
                    if (subview == self) {
                        return YES;
                    }
                    else {
                        touchedView = subview;
                        canContinue = YES;
                        break;
                    }
                }
            }
        } while (canContinue);
    }
    
    return NO;
}

- (BOOL)FEX_canTouchPoint:(CGPoint)point force:(BOOL)force raiseExceptions:(BOOL)raiseExceptions {
    NSString* errorTitle = @"Touch failed";
    
    if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
        NSString* errorMessage = @"Application is ignoring interaction events";
        
        NSLog(@"%@ - %@", errorTitle, errorMessage);        
        
        if (raiseExceptions) {
            [NSException raise:errorTitle format:@"%@", errorMessage];
        }
        
        return NO;
    }
    
    if (![self FEX_isPointInWindow:point]) {
        NSString* errorMessage = @"Touch point is outside window bounds";
        
        NSLog(@"%@ - %@", errorTitle, errorMessage);
        
        if (raiseExceptions) {
            [NSException raise:errorTitle format:@"%@", errorMessage];
        }
        
        return NO;
    }
    
    UIView* touchedView = nil;
    
    if (!force && ![self FEX_isPointInDirectViewHierarchy:point touchRecipient:&touchedView]) {
        NSString* touchedViewDescriptor = nil;
        
        if (touchedView != nil) {
            touchedViewDescriptor = [NSString stringWithFormat:@"%p#%@", touchedView, NSStringFromClass([touchedView class])];
        }
        
        NSString* errorMessage = [NSString stringWithFormat:
                                  @"View not touched because it would not be the recipient of the touch event - consider FEX_forcedTouch instead (touch recipient: %@)",
                                  touchedViewDescriptor];
        
        NSLog(@"%@ - %@", errorTitle, errorMessage);
        
        if (raiseExceptions) {
            [NSException raise:errorTitle format:@"%@", errorMessage];
        }
        
        return NO;
    }
    
    return YES;
}

- (BOOL)FEX_canTouch {
    return [self FEX_canTouchPoint:[self FEX_centerPoint] force:NO raiseExceptions:NO];
}

- (BOOL)FEX_canTouchPointX:(NSNumber*)x y:(NSNumber*)y {
    CGPoint point = [self FEX_pointFromX:x andY:y];
    
    return [self FEX_canTouchPoint:point force:NO raiseExceptions:NO];
}

#pragma mark - Touch

- (BOOL)FEX_touchPoint:(CGPoint)point {
    if (![self FEX_canTouchPoint:point force:NO raiseExceptions:YES]) {
        return NO;
    }
    
    [UIAutomationBridge tapView:self atPoint:point];
    return YES;
}

- (BOOL)touch {
    return [self FEX_touchPoint:[self FEX_centerPoint]];
}

- (BOOL)FEX_forcedTouch {
    CGPoint point = [self FEX_centerPoint];
    
    if (![self FEX_canTouchPoint:point force:YES raiseExceptions:YES]) {
        return NO;
    }
    
    [UIAutomationBridge tapView:self atPoint:point];
    
    return YES;
}

- (BOOL)touchx:(NSNumber *)x y:(NSNumber *)y {
    CGPoint point = [self FEX_pointFromX:x andY:y];
    
	return [self FEX_touchPoint:point];
}

// New code by Carmen Bay

- (BOOL)FEX_forcedTouchx:(NSNumber *)x y:(NSNumber *)y {
    CGPoint point = [self FEX_pointFromX:x andY:y];
    
    if (![self FEX_canTouchPoint:point force:YES raiseExceptions:NO]) {
        return NO;
    }
    
    [UIAutomationBridge tapView:self atPoint:point];
    
    return YES;
}

// End of new code

//Modled on UIAutomation
#pragma mark - Touch Gestures

//Double Tap
- (BOOL)doubleTapPoint:(CGPoint)point {
    if (![self FEX_canTouchPoint:point force:NO raiseExceptions:YES]) {
        return NO;
    }
	
	[UIAutomationBridge doubleTapView:self atPoint:point];
	return YES;
}

- (BOOL)doubleTap {
    return [self doubleTapPoint:[self FEX_centerPoint]];
}

- (BOOL)doubleTapx:(NSNumber *)x y:(NSNumber *)y {
    CGPoint point = [self FEX_pointFromX:x andY:y];
    
    return [self doubleTapPoint:point];
}

////Tap With Options
//- (BOOL)tapWithOptions:(NSDictionary *)options pointIfInsideWindow:(CGPoint)point {
//	
//}
//
//- (BOOL)tapWithOptions:(NSDictionary *)options {
//	
//}
//
//- (BOOL)tapWithOptions:(NSDictionary *)options x:(NSNumber *)x y:(NSNumber *)y {
//	
//}

//Touch and hold
- (BOOL)touchAndHold:(NSTimeInterval)duration point:(CGPoint)point {
    if (![self FEX_canTouchPoint:point force:NO raiseExceptions:YES]) {
        return NO;
    }
	
	[UIAutomationBridge longTapView:self atPoint:point forDuration:duration];
	return YES;
}

- (BOOL)touchAndHold:(CGFloat)duration {
    return [self touchAndHold:duration point:[self FEX_centerPoint]];
}

- (BOOL)touchAndHold:(CGFloat)duration x:(NSNumber *)x y:(NSNumber *)y {
    CGPoint point = [self FEX_pointFromX:x andY:y];
    
    return [self touchAndHold:duration point:point];
}

////Two finger tap
//- (BOOL)twofingerTapPointIfInsideWindow:(CGPoint)point {
//	
//}
//
//- (BOOL)twofingerTap {
//	
//}
//
//- (BOOL)twofingerTapx:(NSNumber *)x y:(NSNumber *)y {
//	
//}

#pragma mark - Swipe Gestures
//TODO
//-(void)swipeInDirection:(NSString *)dir by:(int)pixels {


- (NSString *)swipeInDirection:(NSString *)strDir {
    PADirection dir = [UIAutomationBridge parseDirection:strDir];
    NSArray *swipeExtremes = [UIAutomationBridge swipeView:self inDirection:dir];
    return [NSString stringWithFormat:@"%@ => %@", formatCGPointVal([swipeExtremes objectAtIndex:0]), formatCGPointVal([swipeExtremes objectAtIndex:1])];
}

- (BOOL)FEX_dragWithInitialDelayToX:(CGFloat)x y:(CGFloat)y {
    [UIAutomationBridge dragViewWithInitialDelay:self toPoint:CGPointMake(x,y)];
    return YES;
}

@end