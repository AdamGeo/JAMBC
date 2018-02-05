//
//  NSSplitViewColoured.m
//  JAMBC
//
//  Created by Adam Geoghegan on 5/2/18.
//

#import "NSSplitViewColoured.h"

@implementation NSSplitViewColoured

-(void) drawDividerInRect:(NSRect)aRect {
    [[NSColor lightGrayColor] set];
    NSRectFill(aRect);
}

@end
