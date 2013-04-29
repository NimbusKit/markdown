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

#import "MarkdownAttributedString.h"

#import "MarkdownTokens.h"
#import <pthread.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>
#import "fmemopen.h"

static pthread_mutex_t gMutex = PTHREAD_MUTEX_INITIALIZER;
MarkdownAttributedString* gActiveString = nil;

int markdownConsume(char* text, int token);

@interface MarkdownAttributedString()
- (void)consumeToken:(int)token text:(char*)text;
@property (nonatomic, readwrite, retain) NSMutableArray* bulletStarts;
@property (nonatomic, readwrite, retain) NSMutableArray* links;
@property (nonatomic, readwrite, retain) NSMutableAttributedString* accum;
@end

int markdownConsume(char* text, int token) {
  [gActiveString consumeToken:token text:text];
  return 0;
}

@implementation MarkdownAttributedString

- (NSAttributedString *)parseString:(NSString *)string links:(NSMutableArray *)links {
  self.links = links;
  self.bulletStarts = [NSMutableArray array];
  self.accum = [[NSMutableAttributedString alloc] init];

  // flex is not thread-safe so we force it to be by creating a single-access lock here.
  pthread_mutex_lock(&gMutex); {
    const char* cstr = [string UTF8String];

    markdownin = fmemopen((void *)cstr, sizeof(char) * (string.length + 1), "r");

    gActiveString = self;
    markdownlex();
    fclose(markdownin);

    if (self.bulletStarts.count > 0) {
      // Treat nested bullet points as flat ones...

      // Finish off the previous dash and start a new one.
      NSInteger lastBulletStart = [[self.bulletStarts lastObject] intValue];
      [self.bulletStarts removeLastObject];
      
      [self.accum addAttributes:[self paragraphStyle]
                          range:NSMakeRange(lastBulletStart, self.accum.length - lastBulletStart)];
    }
  }
  pthread_mutex_unlock(&gMutex);

  return [self.accum copy];
}

- (NSDictionary *)paragraphStyle {
  CTTextAlignment alignment = kCTLeftTextAlignment;
  CGFloat paragraphSpacing = 0.0;
  CGFloat paragraphSpacingBefore = 0.0;
  CGFloat firstLineHeadIndent = 15.0;
  CGFloat headIndent = 30.0;
  
  CGFloat firstTabStop = 35.0; // width of your indent
  CGFloat lineSpacing = 0.45;
  
  CTTextTabRef tabArray[] = { CTTextTabCreate(0, firstTabStop, NULL) };
  
  CFArrayRef tabStops = CFArrayCreate( kCFAllocatorDefault, (const void**) tabArray, 1, &kCFTypeArrayCallBacks );
  CFRelease(tabArray[0]);
  
  CTParagraphStyleSetting altSettings[] = 
  {
    { kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &lineSpacing},
    { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &alignment},
    { kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &firstLineHeadIndent},
    { kCTParagraphStyleSpecifierHeadIndent, sizeof(CGFloat), &headIndent},
    { kCTParagraphStyleSpecifierTabStops, sizeof(CFArrayRef), &tabStops},
    { kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &paragraphSpacing},
    { kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &paragraphSpacingBefore}
  }; 
  
  CTParagraphStyleRef style;
  style = CTParagraphStyleCreate( altSettings, sizeof(altSettings) / sizeof(CTParagraphStyleSetting) );
  
  if ( style == NULL )
  {
    NSLog(@"*** Unable To Create CTParagraphStyle in apply paragraph formatting" );
    return nil;
  }
  
  return [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)style,(NSString*) kCTParagraphStyleAttributeName, nil];
}

- (void)consumeToken:(int)token text:(char*)text {
  NSString* textAsString = [[NSString alloc] initWithCString:text encoding:NSUTF8StringEncoding];

  NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
  switch (token) {
    case MARKDOWNEM: {
      textAsString = [textAsString substringWithRange:NSMakeRange(1, textAsString.length - 2)];

      UIFont* font = [UIFont fontWithName:@"Helvetica-Oblique" size:[UIFont systemFontSize]];
      CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
      [attributes setObject:(__bridge id)fontRef forKey:(__bridge NSString* )kCTFontAttributeName];
      break;
    }
    case MARKDOWNSTRONG: {
      textAsString = [textAsString substringWithRange:NSMakeRange(2, textAsString.length - 4)];
      
      UIFont* font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
      CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
      [attributes setObject:(__bridge id)fontRef forKey:(__bridge NSString* )kCTFontAttributeName];
      break;
    }
    case MARKDOWNSTRONGEM: {
      textAsString = [textAsString substringWithRange:NSMakeRange(3, textAsString.length - 6)];
      
      UIFont* font = [UIFont fontWithName:@"Helvetica-BoldOblique" size:[UIFont systemFontSize]];
      CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
      [attributes setObject:(__bridge id)fontRef forKey:(__bridge NSString* )kCTFontAttributeName];
      break;
    }
    case MARKDOWNHEADER: {
      NSRange rangeOfNonHash = [textAsString rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"#"] invertedSet]];
      if (rangeOfNonHash.length > 0) {
        textAsString = [[textAsString substringFromIndex:rangeOfNonHash.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        UIFont* font = [UIFont fontWithName:@"Helvetica-BoldOblique" size:6 - rangeOfNonHash.location + 16];
        CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
        [attributes setObject:(__bridge id)fontRef forKey:(__bridge NSString* )kCTFontAttributeName];
        textAsString = [textAsString stringByAppendingString:@"\n"];
      }
      break;
    }
    case MARKDOWNMULTILINEHEADER: {
      NSArray* components = [textAsString componentsSeparatedByString:@"\n"];
      textAsString = [components objectAtIndex:0];
      UIFont* font = nil;
      if ([[components objectAtIndex:1] rangeOfString:@"="].length > 0) {
        font = [UIFont fontWithName:@"Helvetica-BoldOblique" size:16];
      } else if ([[components objectAtIndex:1] rangeOfString:@"-"].length > 0) {
        font = [UIFont fontWithName:@"Helvetica-BoldOblique" size:15];
      }
      
      CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
      [attributes setObject:(__bridge id)fontRef forKey:(__bridge NSString* )kCTFontAttributeName];

      textAsString = [textAsString stringByAppendingString:@"\n"];
      break;
    }
    case MARKDOWNPARAGRAPH: {
      textAsString = @"\n\n";
      
      if (self.bulletStarts.count > 0) {
        // Treat nested bullet points as flat ones...
        
        // Finish off the previous dash and start a new one.
        NSInteger lastBulletStart = [[self.bulletStarts lastObject] intValue];
        [self.bulletStarts removeLastObject];
        
        [self.accum addAttributes:[self paragraphStyle]
                            range:NSMakeRange(lastBulletStart, self.accum.length - lastBulletStart)];
      }
      break;
    }
    case MARKDOWNBULLETSTART: {
      NSInteger numberOfDashes = [textAsString rangeOfString:@" "].location;
      if (self.bulletStarts.count > 0 && self.bulletStarts.count <= numberOfDashes) {
        // Treat nested bullet points as flat ones...

        // Finish off the previous dash and start a new one.
        NSInteger lastBulletStart = [[self.bulletStarts lastObject] intValue];
        [self.bulletStarts removeLastObject];

        [self.accum addAttributes:[self paragraphStyle]
                            range:NSMakeRange(lastBulletStart, self.accum.length - lastBulletStart)];
      }

      [self.bulletStarts addObject:[NSNumber numberWithInt:self.accum.length]];
      textAsString = @"•\t";
      break;
    }
    case MARKDOWNNEWLINE: {
      textAsString = @"";
      break;
    }
    case MARKDOWNURL: {
      [self.links addObject:[NSValue valueWithRange:NSMakeRange(self.accum.length, textAsString.length)]];
      break;
    }
    case MARKDOWNHREF: {
      NSRange rangeOfRightBracket = [textAsString rangeOfString:@"]"];
      textAsString = [textAsString substringWithRange:NSMakeRange(1, rangeOfRightBracket.location - 1)];
      [self.links addObject:[NSValue valueWithRange:NSMakeRange(self.accum.length, textAsString.length)]];
      break;
    }
    default: {
      break;
    }
  }

  if (textAsString.length > 0) {
    NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:textAsString attributes:attributes];
    [self.accum appendAttributedString:attributedString];
  }
}

@end
