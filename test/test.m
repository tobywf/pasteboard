#include <AppKit/AppKit.h>

int
main()
{
    BOOL ok;
    @autoreleasepool {
        // it doesn't matter if I use auto-release blocks or not
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        [pb clearContents];
        NSArray *files = @[
            [NSURL fileURLWithPath:@(__FILE__ "-example1")],
            [NSURL fileURLWithPath:@(__FILE__ "-example2")]
        ];
        ok = [pb writeObjects:files];
        [pb release];
        // [files release];
    }
    // this seems to cause the problem
    getchar();
    return ok ? 0 : 1;
}
