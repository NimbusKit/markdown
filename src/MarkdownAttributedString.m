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

static pthread_mutex_t gMutex = PTHREAD_MUTEX_INITIALIZER;
MarkdownAttributedString* gActiveString = nil;

int markdownConsume(char* text, int token);

@interface MarkdownAttributedString()
- (void)consumeToken:(int)token text:(char*)text;
@end

int markdownConsume(char* text, int token) {
  [gActiveString consumeToken:token text:text];
  return 0;
}

@implementation MarkdownAttributedString

- (void)parseString:(NSString *)string {
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
    
    NSLog(@"%s", tempFileNameCString);
    free(tempFileNameCString);
    tempFileNameCString = 0;
  }
  pthread_mutex_unlock(&gMutex);
}

- (void)consumeToken:(int)token text:(char*)text {
  NSString* textAsString = [[NSString alloc] initWithCString:text encoding:NSUTF8StringEncoding];
  NSLog(@"text: %@", textAsString);

  switch (token) {
  }
}

@end
