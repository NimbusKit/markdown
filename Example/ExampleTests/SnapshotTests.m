#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <XNGMarkdownParser/NSAttributedStringMarkdownParser.h>

#define kRecordModeAll NO

@interface ExampleTests : FBSnapshotTestCase

@end

@implementation ExampleTests

- (void)testPlainText {
    self.recordMode = kRecordModeAll;
    UITextView * textView = [self defaultTextView];
    textView.attributedText = [self parseWithDefaultAttributes:@"This is just some plaintext to test the markdown parser, with some UTF-8: ÄÖÜäöüßñ©€"];

    FBSnapshotVerifyView(textView, @"Snapshot");
}

- (void)testBasicFormat {
    self.recordMode = kRecordModeAll;
    UITextView * textView = [self defaultTextView];
    textView.attributedText = [self parseWithDefaultAttributes:@"#This is a header 1\n"
                               "This is **bold**, now *some italic*, I like ***both together***.\n"
                               "[this is a link](http://www.google.com) and at the end, `[some code]`"];

    FBSnapshotVerifyView(textView, @"Snapshot");
}

- (void)testFontChange {
    self.recordMode = kRecordModeAll;
    UITextView * textView = [self defaultTextView];
    NSString * markdown = @"#This is a header 1\n"
    "This is **bold**, now *some italic*, I like ***both together***.\n"
    "[this is a link](http://www.google.com) and at the end, `[some code]`";

    NSAttributedStringMarkdownParser * parser = [[NSAttributedStringMarkdownParser alloc] init];
    parser.paragraphFont = [UIFont fontWithName:@"Damascus" size:15];
    parser.codeFontName = @"Menlo-Regular";
    parser.boldFontName = @"EuphemiaUCAS-Bold";
    parser.linkFontName = @"Futura-Medium";
    [parser setFont:[UIFont fontWithName:@"Copperplate" size:24]
          forHeader:NSAttributedStringMarkdownParserHeader1];
    textView.attributedText = [parser attributedStringFromMarkdownString:markdown];

    FBSnapshotVerifyView(textView, @"Snapshot");
}

- (void)testParagraphAttributes {
    self.recordMode = kRecordModeAll;
    UITextView * textView = [self defaultTextView];
    NSString * markdown = @"Lorem fistrum **benemeritaar** jarl pupita fistro qué dise usteer quietooor **papaar papaar** va usté muy cargadoo sexuarl. Tiene musho peligro [pecador](http://www.wikileaks.org) *te va a hasé pupitaa ese que llega*.\n"
    "A gramenawer `va usté muy cargadoo` te va a hasé pupitaa amatomaa condemor a wan te va a hasé pupitaa ese hombree ese pedazo de. Mamaar caballo blanco caballo negroorl ese que llega pecador me cago en tus muelas a wan se calle ustée va usté muy cargadoo. Hasta luego Lucas tiene musho peligro va usté muy cargadoo papaar papaar apetecan. Papaar papaar benemeritaar pecador va usté muy cargadoo hasta luego Lucas.\n"
    "Tiene musho **peligro** al ataquerl a peich ese pedazo de tiene musho peligro jarl te voy a borrar el cerito amatomaa apetecan. Te va a hasé pupitaa diodenoo no te digo trigo por no llamarte Rodrigor ***ese pedazo de fistro caballo blanco caballo negroorl*** va usté muy cargadoo. De la pradera por la gloria de mi madre sexuarl al ataquerl jarl. Condemor tiene musho peligro benemeritaar te va a hasé pupitaa pecador mamaar no te digo trigo por no llamarte Rodrigor.";

    NSAttributedStringMarkdownParser * parser = [[NSAttributedStringMarkdownParser alloc] init];
    NSShadow * shadow = [[NSShadow alloc] init];
    shadow.shadowOffset = CGSizeMake(1, 0.5);
    shadow.shadowBlurRadius = 0.5;
    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 5;
    parser.topAttributes = @{NSForegroundColorAttributeName : [UIColor darkGrayColor],
                             NSShadowAttributeName : shadow,
                             NSParagraphStyleAttributeName : paragraphStyle,
                             };
    textView.attributedText = [parser attributedStringFromMarkdownString:markdown];

    FBSnapshotVerifyView(textView, @"Snapshot");
}

- (UITextView *)defaultTextView {
    UITextView *tv = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    tv.editable = NO;
    return tv;
}

- (NSAttributedString *)parseWithDefaultAttributes:(NSString*)markdown {
    NSAttributedStringMarkdownParser * parser = [[NSAttributedStringMarkdownParser alloc] init];
    return [parser attributedStringFromMarkdownString:markdown];
}

@end
