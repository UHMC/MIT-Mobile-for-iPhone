#include <stdarg.h>
#import "MITLogging.h"

// Based on code from bbum
// http://stackoverflow.com/questions/1354728/in-xcode-is-there-a-way-to-disable-the-timestamps-that-appear-in-the-debugger-co/1354736#1354736

void MyLog(const char *level, const char *filepath, int line, NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format
                                                       arguments:args];
    va_end(args);
    NSString *pathString = [NSString stringWithUTF8String:filepath];
    NSString *outputFormat = (level == NULL) ? @"[%1$@:%2$d] %3$@\n" : @"%4$s [%1$@:%2$d] %3$@\n";
    NSString *outputString = [NSString stringWithFormat:outputFormat, [pathString lastPathComponent], line, formattedString, level];
    
    [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] 
     writeData:[outputString dataUsingEncoding:NSUTF8StringEncoding]];
    
    [formattedString release];
}
