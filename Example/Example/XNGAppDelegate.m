#import "XNGAppDelegate.h"
#import "XNGMarkdownTestViewController.h"

@implementation XNGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = [UIColor whiteColor];

    XNGMarkdownTestViewController * viewController = [[XNGMarkdownTestViewController alloc] init];
    self.window.rootViewController = viewController;
    [self.window makeKeyAndVisible];
    return YES;
}


@end
