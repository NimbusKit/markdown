//
// Copyright 2012 Jeff Verkoeyen
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

static pthread_mutex_t gMutex = PTHREAD_MUTEX_INITIALIZER;
MarkdownAttributedString* gActiveString = nil;

int markdownConsume(char* text, int token);

@interface MarkdownAttributedString()
- (void)consumeToken:(int)token text:(char*)text;
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
  self.accum = [[NSMutableAttributedString alloc] init];

  // flex is not thread-safe so we force it to be by creating a single-access lock here.
  pthread_mutex_lock(&gMutex); {
    NSString *tempFileTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tempstr.XXXXXX"];
    const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
    char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
    strcpy(tempFileNameCString, tempFileTemplateCString);
    int fileDescriptor = mkstemp(tempFileNameCString);
    
    if (fileDescriptor == -1) {
    }
    
    NSFileHandle* handle = [[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor closeOnDealloc:YES];
    [handle writeData:[NSData dataWithBytes:[string UTF8String] length:string.length]];
    handle = nil;

    markdownin = fopen(tempFileNameCString, "r");
    gActiveString = self;
    markdownlex();
    fclose(markdownin);
    
    free(tempFileNameCString);
    tempFileNameCString = 0;
  }
  pthread_mutex_unlock(&gMutex);

  return [self.accum copy];
}

- (void)consumeToken:(int)token text:(char*)text {
  NSString* textAsString = [[NSString alloc] initWithCString:text encoding:NSUTF8StringEncoding];

  NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
  NSLog(@"--%@ %s--", textAsString, markdownnames[token - MARKDOWNFIRST_TOKEN]);
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
    case MARKDOWNPARAGRAPH: {
      textAsString = @"\n";
      break;
    }
    case MARKDOWNNEWLINE: {
      textAsString = nil;
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
