#include <AppKit/AppKit.h>

int main() {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb clearContents];
    NSArray *objects = @[
        [NSURL fileURLWithPath:@"/bin/ls"],
        [NSURL URLWithString:@"https://developer.apple.com/"]
    ];
    [pb writeObjects:objects];
    [pool drain];
    return 0;
}
