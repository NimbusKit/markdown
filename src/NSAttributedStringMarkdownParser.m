//
// Copyright 2012-2013 Jeff Verkoeyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "NSAttributedStringMarkdownParser.h"

#import "MarkdownTokens.h"
#import "fmemopen.h"

#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>
#import <pthread.h>


#define MKDNLog(...)       ((void)0) // NSLog(__VA_ARGS__)


static const CGFloat kNIFirstLineHeadIndent = 15.f;
static const CGFloat kNIHeadIndent = 30.f;

static NSString * const kNILocationKey = @"Location";
static NSString * const kNIIndentationLevelKey = @"IndentationLevel";


static NSRegularExpression *_hrefRegex = nil;
static inline NSRegularExpression* hrefRegex(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _hrefRegex = [NSRegularExpression regularExpressionWithPattern:@"\\[(.*?)\\]\\((\\S+)(\\s+(\"|\')(.*?)(\"|\'))?\\)"
                                                               options:NSRegularExpressionCaseInsensitive
                                                                 error:nil];
    });

    return _hrefRegex;
}

int markdownConsume(char* text, int token, yyscan_t scanner);

@interface NSAttributedStringMarkdownLink()
@property (nonatomic, strong) NSURL* url;
@property (nonatomic, assign) NSRange range;
@property (nonatomic, copy) NSString *tooltip;
@end

@implementation NSAttributedStringMarkdownLink

+ (instancetype)linkWithRange:(NSRange)range URL:(NSURL *)URL tooltip:(NSString *)tooltip {
  NSAttributedStringMarkdownLink *link = [[self alloc] init];
  link.range = range;
  link.url = URL;
  link.tooltip = tooltip;
  return link;
}

@end

@implementation NSAttributedStringMarkdownParser {
  NSMutableDictionary* _headerFonts;

  NSMutableArray* _bulletStarts;
  NSMutableArray* _quoteStarts;

  NSMutableAttributedString* _accum;
  NSMutableArray* _links;

  UIFont* _topFont;
  NSMutableDictionary* _fontCache;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)init {
  if ((self = [super init])) {
    _headerFonts = [NSMutableDictionary dictionary];

    self.paragraphFont = [UIFont systemFontOfSize:12];
    self.boldFontName = [UIFont boldSystemFontOfSize:12].fontName;
    self.italicFontName = @"Helvetica-Oblique";
    self.boldItalicFontName = @"Helvetica-BoldOblique";
    self.blockQuotesAttributes = @{
                                   NSFontAttributeName : (__bridge id)[self fontRefForFontWithName:self.italicFontName pointSize:self.paragraphFont.pointSize],
                                   NSForegroundColorAttributeName : [UIColor darkGrayColor]
                                   };

    NSAttributedStringMarkdownParserHeader header = NSAttributedStringMarkdownParserHeader1;
    for (CGFloat headerFontSize = 24; headerFontSize >= 14; headerFontSize -= 2, header++) {
      [self setFont:[UIFont systemFontOfSize:headerFontSize] forHeader:header];
    }
  }
  return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NSCopying
////////////////////////////////////////////////////////////////////////

- (id)copyWithZone:(NSZone *)zone {
  NSAttributedStringMarkdownParser* parser = [[self.class allocWithZone:zone] init];
  parser.paragraphFont = self.paragraphFont;
  parser.boldFontName = self.boldFontName;
  parser.italicFontName = self.italicFontName;
  parser.boldItalicFontName = self.boldItalicFontName;
  for (NSAttributedStringMarkdownParserHeader header = NSAttributedStringMarkdownParserHeader1; header <= NSAttributedStringMarkdownParserHeader6; ++header) {
    [parser setFont:[self fontForHeader:header] forHeader:header];
  }
  return parser;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NSAttributedStringMarkdownParser
////////////////////////////////////////////////////////////////////////

- (NSMutableAttributedString *)attributedStringFromMarkdownString:(NSString *)string {
  _links = [NSMutableArray array];
  _bulletStarts = [NSMutableArray array];
  _quoteStarts = [NSMutableArray array];
  _accum = [[NSMutableAttributedString alloc] init];

  const char* cstr = [string UTF8String];
  FILE* markdownin = fmemopen((void *)cstr, sizeof(char) * (string.length + 1), "r");

  yyscan_t scanner;

  markdownlex_init(&scanner);
  markdownset_extra((__bridge void *)(self), scanner);
  markdownset_in(markdownin, scanner);
  markdownlex(scanner);
  markdownlex_destroy(scanner);

  fclose(markdownin);

  [self applyParagraphStyleWithArray:_bulletStarts firstLineHeadIndent:kNIFirstLineHeadIndent headIndent:kNIHeadIndent];
  [self applyParagraphStyleWithArray:_quoteStarts additionalAttributes:self.blockQuotesAttributes firstLineHeadIndent:kNIFirstLineHeadIndent headIndent:kNIFirstLineHeadIndent];

  return [_accum mutableCopy];
}

- (void)setFont:(UIFont *)font forHeader:(NSAttributedStringMarkdownParserHeader)header {
  _headerFonts[[self keyForHeader:header]] = font;
}

- (UIFont *)fontForHeader:(NSAttributedStringMarkdownParserHeader)header {
  return _headerFonts[[self keyForHeader:header]];
}

- (NSArray *)links {
  return [_links copy];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)consumeToken:(int)token text:(char *)text {
  NSString* textAsString = [[NSString alloc] initWithCString:text encoding:NSUTF8StringEncoding];

  NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
  [attributes addEntriesFromDictionary:[self attributesForFont:self.topFont]];

  switch (token) {
    case MARKDOWNEM: { // * *
      MKDNLog(@"Matched em: %@", textAsString);
      textAsString = [textAsString substringWithRange:NSMakeRange(1, textAsString.length - 2)];
      [attributes addEntriesFromDictionary:[self attributesForFontWithName:self.italicFontName]];
      break;
    }
    case MARKDOWNSTRONG: { // ** **
      MKDNLog(@"Matched strong: %@", textAsString);
      textAsString = [textAsString substringWithRange:NSMakeRange(2, textAsString.length - 4)];
      [attributes addEntriesFromDictionary:[self attributesForFontWithName:self.boldFontName]];
      break;
    }
    case MARKDOWNSTRONGEM: { // *** ***
      MKDNLog(@"Matched strongem: %@", textAsString);
      textAsString = [textAsString substringWithRange:NSMakeRange(3, textAsString.length - 6)];
      [attributes addEntriesFromDictionary:[self attributesForFontWithName:self.boldItalicFontName]];
      break;
    }
    case MARKDOWNSTRIKETHROUGH: { // ~~ ~~
      MKDNLog(@"Matched strikethrough: %@", textAsString);
      textAsString = [textAsString substringWithRange:NSMakeRange(2, textAsString.length - 4)];
      [attributes addEntriesFromDictionary:@{NSStrikethroughStyleAttributeName : @(NSUnderlineStyleSingle)}];
      break;
    }
    case MARKDOWNHEADER: { // ####
      MKDNLog(@"Matched header: %@", textAsString);
      NSRange rangeOfNonHash = [textAsString rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"#"] invertedSet]];
      if (rangeOfNonHash.length > 0) {
        textAsString = [[textAsString substringFromIndex:rangeOfNonHash.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        NSAttributedStringMarkdownParserHeader header = rangeOfNonHash.location;
        [self recurseOnString:textAsString withFont:[self fontForHeader:header]];

        // We already appended the recursive parser's results in recurseOnString.
        textAsString = nil;
      }
      break;
    }
    case MARKDOWNMULTILINEHEADER: {
      MKDNLog(@"Matched multiline-header: %@", textAsString);
      NSArray* components = [textAsString componentsSeparatedByString:@"\n"];
      textAsString = [components objectAtIndex:0];
      UIFont* font = nil;
      if ([[components objectAtIndex:1] rangeOfString:@"="].length > 0) {
        font = [self fontForHeader:NSAttributedStringMarkdownParserHeader1];
      } else if ([[components objectAtIndex:1] rangeOfString:@"-"].length > 0) {
        font = [self fontForHeader:NSAttributedStringMarkdownParserHeader2];
      }

      [self recurseOnString:textAsString withFont:font];

      // We already appended the recursive parser's results in recurseOnString.
      textAsString = nil;
      break;
    }
    case MARKDOWNPARAGRAPH: {
      MKDNLog(@"Matched paragraph: %@", textAsString);
      textAsString = @"\n\n";

      [self applyParagraphStyleWithArray:_bulletStarts firstLineHeadIndent:kNIFirstLineHeadIndent headIndent:kNIHeadIndent];
      [self applyParagraphStyleWithArray:_quoteStarts additionalAttributes:self.blockQuotesAttributes firstLineHeadIndent:kNIFirstLineHeadIndent headIndent:kNIFirstLineHeadIndent];

      break;
    }
    case MARKDOWNBULLETSTART: {
      MKDNLog(@"Matched bullet-start: %@", textAsString);
      NSInteger numberOfDashes = [textAsString rangeOfString:@" "].location;
      if (_bulletStarts.count > 0 && _bulletStarts.count <= numberOfDashes) {
        [self applyParagraphStyleWithArray:_bulletStarts firstLineHeadIndent:kNIFirstLineHeadIndent headIndent:kNIHeadIndent];
      }

      [_bulletStarts addObject:@{kNILocationKey : @(_accum.length), kNIIndentationLevelKey : @1}];
      textAsString = @"•\t";
      break;
    }
    case MARKDOWNBLOCKQUOTE: {
      MKDNLog(@"Matched block-quote: %@", textAsString);
      [self applyParagraphStyleWithArray:_quoteStarts
                    additionalAttributes:self.blockQuotesAttributes
                     firstLineHeadIndent:kNIFirstLineHeadIndent headIndent:kNIFirstLineHeadIndent];

      [_quoteStarts addObject:@{kNILocationKey : @(_accum.length), kNIIndentationLevelKey : @(textAsString.length)}];
      textAsString = @"";
      break;
    }
    case MARKDOWNHR: {
      MKDNLog(@"Matched hr: %@", textAsString);
      // TODO: Add custom attribute to retreive later instead of fake horizontal line
      textAsString = @"―――――――――――――――\n";
      break;
    }
    case MARKDOWNNEWLINE: {
      MKDNLog(@"Matched newline: %@", textAsString);
      [self applyParagraphStyleWithArray:_bulletStarts firstLineHeadIndent:kNIFirstLineHeadIndent headIndent:kNIHeadIndent];
      [self applyParagraphStyleWithArray:_quoteStarts additionalAttributes:self.blockQuotesAttributes firstLineHeadIndent:kNIFirstLineHeadIndent headIndent:kNIFirstLineHeadIndent];
      break;
    }
    case MARKDOWNURL: {
      MKDNLog(@"Matched url: %@", textAsString);
      NSAttributedStringMarkdownLink* link = [[NSAttributedStringMarkdownLink alloc] init];
      link.url = [NSURL URLWithString:textAsString];
      link.range = NSMakeRange(_accum.length, textAsString.length);
      [_links addObject:link];
      break;
    }
    case MARKDOWNHREF: { // [Title] (url "tooltip")
      MKDNLog(@"Matched href: %@", textAsString);
      NSTextCheckingResult *result = [hrefRegex() firstMatchInString:textAsString options:0 range:NSMakeRange(0, textAsString.length)];

      NSRange linkTitleRange = [result rangeAtIndex:1];
      NSRange linkURLRange = [result rangeAtIndex:2];
      NSRange tooltipRange = [result rangeAtIndex:5];

      if (linkTitleRange.location != NSNotFound && linkURLRange.location != NSNotFound) {
        NSAttributedStringMarkdownLink *link = [[NSAttributedStringMarkdownLink alloc] init];

        link.url = [NSURL URLWithString:[textAsString substringWithRange:linkURLRange]];
        link.range = NSMakeRange(_accum.length, linkTitleRange.length);

        if (tooltipRange.location != NSNotFound) {
          link.tooltip = [textAsString substringWithRange:tooltipRange];
        }

        [_links addObject:link];
        textAsString = [textAsString substringWithRange:linkTitleRange];
      }
      break;
    }
    default: {
      break;
    }
  }

  if (textAsString.length > 0) {
    NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:textAsString attributes:attributes];
    [_accum appendAttributedString:attributedString];
  }
}

- (id)keyForHeader:(NSAttributedStringMarkdownParserHeader)header {
  return @(header);
}

- (UIFont *)topFont {
  if (nil == _topFont) {
    return self.paragraphFont;
  } else {
    return _topFont;
  }
}

- (id)keyForFontWithName:(NSString *)fontName pointSize:(CGFloat)pointSize {
  return [fontName stringByAppendingFormat:@"%f", pointSize];
}

- (CTFontRef)fontRefForFontWithName:(NSString *)fontName pointSize:(CGFloat)pointSize {
  id key = [self keyForFontWithName:fontName pointSize:pointSize];
  NSValue* value = _fontCache[key];
  if (nil == value) {
    CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)fontName, pointSize, nil);
    value = [NSValue valueWithPointer:fontRef];
    _fontCache[key] = value;
  }
  return [value pointerValue];
}

- (NSDictionary *)attributesForFontWithName:(NSString *)fontName {
  CTFontRef fontRef = [self fontRefForFontWithName:fontName pointSize:self.topFont.pointSize];
  NSDictionary* attributes = @{(__bridge NSString* )kCTFontAttributeName:(__bridge id)fontRef};
  CFRelease(fontRef);
  return attributes;
}

- (NSDictionary *)attributesForFont:(UIFont *)font {
  CTFontRef fontRef = [self fontRefForFontWithName:font.fontName pointSize:font.pointSize];
  NSDictionary* attributes = @{(__bridge NSString* )kCTFontAttributeName:(__bridge id)fontRef};
  CFRelease(fontRef);
  return attributes;
}

- (void)recurseOnString:(NSString *)string withFont:(UIFont *)font {
  NSAttributedStringMarkdownParser* recursiveParser = [self copy];
  recursiveParser->_topFont = font;
  [_accum appendAttributedString:[recursiveParser attributedStringFromMarkdownString:string]];

  // Adjust the recursive parser's links so that they are offset correctly.
  for (NSAttributedStringMarkdownLink *link in recursiveParser.links) {
    NSRange range = link.range;
    range.location += _accum.length;

    [_links addObject:[NSAttributedStringMarkdownLink linkWithRange:range URL:link.url tooltip:link.tooltip]];
  }
}

- (NSDictionary *)paragraphStyleWithFirstLineHeadIndent:(CGFloat)headIndent headIndent:(CGFloat)indent {
  CTTextAlignment alignment = kCTLeftTextAlignment;
  CGFloat paragraphSpacing = 0.0;
  CGFloat paragraphSpacingBefore = 0.0;

  CGFloat firstTabStop = kNIHeadIndent;
  CGFloat lineSpacing = 0.45;

  CTTextTabRef tabArray[] = {CTTextTabCreate(0, firstTabStop, NULL)};

  CFArrayRef tabStops = CFArrayCreate(kCFAllocatorDefault, (const void **) tabArray, 1, &kCFTypeArrayCallBacks);
  CFRelease(tabArray[0]);

  CTParagraphStyleSetting altSettings[] = {
    { kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &lineSpacing},
    { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &alignment},
    { kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &headIndent},
    { kCTParagraphStyleSpecifierHeadIndent, sizeof(CGFloat), &indent},
    { kCTParagraphStyleSpecifierTabStops, sizeof(CFArrayRef), &tabStops},
    { kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &paragraphSpacing},
    { kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &paragraphSpacingBefore}
  };

  CTParagraphStyleRef style;
  style = CTParagraphStyleCreate( altSettings, sizeof(altSettings) / sizeof(CTParagraphStyleSetting) );

  if (style == NULL) {
    NSLog(@"*** Unable To Create CTParagraphStyle in apply paragraph formatting" );
    return nil;
  }

  return @{(NSString *)kCTParagraphStyleAttributeName : (__bridge id)style};
}

- (void)applyParagraphStyleWithArray:(NSMutableArray *)array firstLineHeadIndent:(CGFloat)firstLineHeadIndent headIndent:(CGFloat)headIndent {
  [self applyParagraphStyleWithArray:array additionalAttributes:nil firstLineHeadIndent:firstLineHeadIndent headIndent:headIndent];
}

- (void)applyParagraphStyleWithArray:(NSMutableArray *)array additionalAttributes:(NSDictionary *)additionalAttributes firstLineHeadIndent:(CGFloat)firstLineHeadIndent headIndent:(CGFloat)headIndent {
  if (array.count > 0) {
    // Finish off the previous dash and start a new one.
    NSDictionary *last = [array lastObject];
    [array removeLastObject];

    NSInteger lastStart = [last[kNILocationKey] intValue];
    NSInteger indentation = [last[kNIIndentationLevelKey] intValue];
    NSRange range = NSMakeRange(lastStart, _accum.length - lastStart);

    [_accum addAttributes:[self paragraphStyleWithFirstLineHeadIndent:firstLineHeadIndent*indentation headIndent:headIndent*indentation]
                    range:range];
    if (additionalAttributes != nil) {
      [_accum addAttributes:additionalAttributes range:range];
    }
  }
}

@end

////////////////////////////////////////////////////////////////////////
#pragma mark - Flex
////////////////////////////////////////////////////////////////////////

int markdownConsume(char* text, int token, yyscan_t scanner) {
  NSAttributedStringMarkdownParser* parser = (__bridge NSAttributedStringMarkdownParser *)(markdownget_extra(scanner));
  [parser consumeToken:token text:text];
  return 0;
}
