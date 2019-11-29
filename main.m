/**
 * clang main.m -framework Cocoa -framework QuartzCore -framework IOSurface -o test && ./test
 **/

/**
 * This project demonstrates that some IOSurfaces stay in use on macOS 10.15 after a GPU switch.
 * This app creates a new IOSurface once a second, and sets it on a CALayer.
 * Also, once per second, all surfaces are queried through -[IOSurface isInUse].
 * See the end of this file for example output.
 **/

#import <Cocoa/Cocoa.h>
#import <IOSurface/IOSurfaceObjC.h>
#import <QuartzCore/QuartzCore.h>

@interface TestView: NSView
{
  BOOL nextTickSetsNewSurface_;
  int surfaceIndex_;
  NSMutableArray<IOSurface*>* surfaces_;
  CALayer* layer_;
}

@end

@implementation TestView

- (id)initWithFrame:(NSRect)frame
{
  self = [super initWithFrame:frame];
  nextTickSetsNewSurface_ = YES;
  surfaceIndex_ = 0;
  surfaces_ = [NSMutableArray new];

  layer_ = [[CALayer layer] retain];
  layer_.position = NSZeroPoint;
  layer_.anchorPoint = NSZeroPoint;
  layer_.bounds = NSMakeRect(0, 0, 300, 300);
  layer_.contentsGravity = kCAGravityTopLeft;
  self.wantsLayer = YES;
  [self.layer addSublayer:layer_];
  [self performSelector:@selector(tick) withObject:nil afterDelay:0.5];

  return self;
}

- (void)dealloc {
  [layer_ release];
  [surfaces_ release];
  [super dealloc];
}

- (void)tick {
  if (nextTickSetsNewSurface_) {
    [self setNewSurface];
  } else {
    [self dumpSurfaceUsage];
  }
  nextTickSetsNewSurface_ = !nextTickSetsNewSurface_;
  [self performSelector:@selector(tick) withObject:nil afterDelay:0.5];
}

- (void)setNewSurface {
  NSLog(@"Creating surface %d", surfaceIndex_);

  IOSurface* newSurf = [[IOSurface alloc] initWithProperties:@{
    IOSurfacePropertyKeyWidth : @(300),
    IOSurfacePropertyKeyHeight : @(300),
    IOSurfacePropertyKeyPixelFormat : @(kCVPixelFormatType_32BGRA),
    IOSurfacePropertyKeyBytesPerElement : @(4),
  }];
  [surfaces_ addObject:newSurf];
  [self drawToSurface:newSurf drawingHandler:^(NSRect dstRect) {
    [[NSColor whiteColor] set];
    NSRectFill(dstRect);
    [[NSString stringWithFormat:@"%d", surfaceIndex_]
         drawAtPoint:NSMakePoint(NSMidX(dstRect), NSMidY(dstRect))
      withAttributes:@{
          NSFontAttributeName: [NSFont labelFontOfSize:40]
        }];
  }];

  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  layer_.contents = newSurf;
  layer_.contentsScale = 1;
  [CATransaction commit];

  [newSurf release];

  surfaceIndex_++;
}

- (void)dumpSurfaceUsage {
  NSLog(@"IOSurfaceIsInUse:");
  [surfaces_ enumerateObjectsUsingBlock:^(IOSurface* surf, NSUInteger idx, BOOL *stop) {
    NSLog(@"  - IOSurface %@ %@", @(idx), surf.isInUse ? @"is in use" : @"is not in use");
  }];
}

- (void)drawToSurface:(IOSurface*)surface drawingHandler:(void (^)(NSRect dstRect))drawingHandler {
  [surface lockWithOptions:0 seed:nil];

  CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
  CGContextRef cg = CGBitmapContextCreate(
      surface.baseAddress, surface.width, surface.height,
      8, surface.bytesPerRow, rgb,
      kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
  CGColorSpaceRelease(rgb);
  NSGraphicsContext* oldContext = [NSGraphicsContext currentContext];
  [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithCGContext:cg flipped:NO]];

  drawingHandler(NSMakeRect(0, 0, surface.width, surface.height));

  [NSGraphicsContext setCurrentContext:oldContext];
  CGContextRelease(cg);

  [surface unlockWithOptions:0 seed:nil];
}

@end

@interface TerminateOnClose : NSObject<NSWindowDelegate>
@end

@implementation TerminateOnClose
- (void)windowWillClose:(NSNotification*)notification
{
  [NSApp terminate:self];
}
@end

int
main (int argc, char **argv)
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  [NSApplication sharedApplication];
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

  int style = 
    NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable;
  NSRect contentRect = NSMakeRect(600, 500, 300, 300);
  NSWindow* window = [[NSWindow alloc] initWithContentRect:contentRect
                                       styleMask:style
                                         backing:NSBackingStoreBuffered
                                           defer:NO];

  NSView* view = [[TestView alloc] initWithFrame:NSMakeRect(0, 0, contentRect.size.width, contentRect.size.height)];
    
  [window setContentView:view];
  [window setDelegate:[[TerminateOnClose alloc] autorelease]];
  [NSApp activateIgnoringOtherApps:YES];
  [window makeKeyAndOrderFront:window];

  [NSApp run];

  [pool release];
  
  return 0;
}

/*******************************************************************************

Example output

During this run, I started on the integrated GPU, switched to the discrete GPU
after surface 2 was created, and switched back to the integrated GPU after
surface 6 was created.

You can see that surface 2 stays in use while the discrete GPU is active, even
though surface 2 is no longer attached to a CALayer.
After switching back to the integrated GPU, surface 2 becomes unused.
However, from that point on, surface 6 stays in use.

This was tested on 10.15.2 Beta (19C46a), on a MacBook Pro (15-inch, Late 2016),
with an Intel HD Graphics 530 and an AMD Radeon Pro 460.
GPU switching was performed with the help of the gfxCardStatus app from gfx.io.

% clang main.m -framework Cocoa -framework QuartzCore -framework IOSurface -o test && ./test
2019-11-29 17:11:27.702 test[27952:2001784] Creating surface 0
2019-11-29 17:11:28.206 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:28.206 test[27952:2001784]   - IOSurface 0 is in use
2019-11-29 17:11:28.707 test[27952:2001784] Creating surface 1
2019-11-29 17:11:29.210 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:29.210 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:29.210 test[27952:2001784]   - IOSurface 1 is in use
2019-11-29 17:11:29.710 test[27952:2001784] Creating surface 2
2019-11-29 17:11:30.212 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:30.212 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:30.212 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:30.212 test[27952:2001784]   - IOSurface 2 is in use
2019-11-29 17:11:30.713 test[27952:2001784] Creating surface 3
2019-11-29 17:11:31.215 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:31.215 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:31.215 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:31.215 test[27952:2001784]   - IOSurface 2 is in use
2019-11-29 17:11:31.215 test[27952:2001784]   - IOSurface 3 is in use
2019-11-29 17:11:31.716 test[27952:2001784] Creating surface 4
2019-11-29 17:11:32.218 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:32.218 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:32.218 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:32.218 test[27952:2001784]   - IOSurface 2 is in use
2019-11-29 17:11:32.218 test[27952:2001784]   - IOSurface 3 is not in use
2019-11-29 17:11:32.218 test[27952:2001784]   - IOSurface 4 is in use
2019-11-29 17:11:32.719 test[27952:2001784] Creating surface 5
2019-11-29 17:11:33.221 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:33.221 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:33.222 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:33.222 test[27952:2001784]   - IOSurface 2 is in use
2019-11-29 17:11:33.222 test[27952:2001784]   - IOSurface 3 is not in use
2019-11-29 17:11:33.222 test[27952:2001784]   - IOSurface 4 is not in use
2019-11-29 17:11:33.222 test[27952:2001784]   - IOSurface 5 is in use
2019-11-29 17:11:33.723 test[27952:2001784] Creating surface 6
2019-11-29 17:11:34.224 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:34.224 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:34.224 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:34.224 test[27952:2001784]   - IOSurface 2 is in use
2019-11-29 17:11:34.224 test[27952:2001784]   - IOSurface 3 is not in use
2019-11-29 17:11:34.224 test[27952:2001784]   - IOSurface 4 is not in use
2019-11-29 17:11:34.224 test[27952:2001784]   - IOSurface 5 is not in use
2019-11-29 17:11:34.224 test[27952:2001784]   - IOSurface 6 is in use
2019-11-29 17:11:34.724 test[27952:2001784] Creating surface 7
2019-11-29 17:11:35.227 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 2 is not in use
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 3 is not in use
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 4 is not in use
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 5 is not in use
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 6 is in use
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 7 is in use
2019-11-29 17:11:35.728 test[27952:2001784] Creating surface 8
2019-11-29 17:11:36.230 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 2 is not in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 3 is not in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 4 is not in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 5 is not in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 6 is in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 7 is not in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 8 is in use
2019-11-29 17:11:36.730 test[27952:2001784] Creating surface 9
2019-11-29 17:11:37.232 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 2 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 3 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 4 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 5 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 6 is in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 7 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 8 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 9 is in use
2019-11-29 17:11:37.732 test[27952:2001784] Creating surface 10
2019-11-29 17:11:38.234 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 2 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 3 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 4 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 5 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 6 is in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 7 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 8 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 9 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 10 is in use

*******************************************************************************/
