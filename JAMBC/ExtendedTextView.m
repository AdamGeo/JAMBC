//
//  ExtendedTextView.m
//  CalcyBar
//
//  Created by Adam Geoghegan on 29/1/18.
//

#import "ExtendedTextView.h"

@implementation ExtendedTextView

-(id)initWithCoder:(NSCoder *)coder
{
    if (self == [super initWithCoder:coder]) {
        [[self textStorage] setFont:[NSFont fontWithName:@"Courier" size:20.0f]];
        [self setFont:[NSFont fontWithName:@"Courier" size:20.0f]];
        [self setTextColor:[NSColor whiteColor]];
        NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [para setLineBreakMode:NSLineBreakByTruncatingTail];
        [self setDefaultParagraphStyle:para];
    }
    return self;
}

-(BOOL)becomeFirstResponder
{
    BOOL success = [super becomeFirstResponder];
    if(success)
    {
        if( [self respondsToSelector: @selector(setInsertionPointColor:)] ) {
            [self setInsertionPointColor: [NSColor whiteColor]];
        }
    }
    return success;
}

@end
