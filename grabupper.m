#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "UploadOperation.h"

#define DESKTOP [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"]

@interface Watcher : NSObject <UploadOperationDelegate>
@end

@implementation Watcher
- (void) doneUploading:(NSString *)status
{
	
	// Range didn't work. This does.
	NSString *endString = [[status componentsSeparatedByString:@"imgup"] lastObject];
	NSArray *items = [endString componentsSeparatedByString:@"img src=\""];
	if (items.count < 2) {printf("Error extracting URL from GrabUp response.");	return;}
	
	endString = [items objectAtIndex:1];
	items = [endString componentsSeparatedByString:@"?direct"];
	if (items.count < 2) {printf("Error extracting URL from GrabUp response.");	return;}
	
	endString = [[items objectAtIndex:0] stringByAppendingString:@"?direct"];
	NSURL *url = [NSURL URLWithString:endString];
	NSString *type = NSURLPboardType;
	[[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:type] owner:nil];
	[url writeToPasteboard:[NSPasteboard generalPasteboard]];
	
	printf("Pasteboard: %s\n", [endString UTF8String]);
	system("say 'You Are Ell is ready'");
}

- (void) notify: (NSNotification *) notification
{
	NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:DESKTOP error:nil];
	for (NSString *fileName in files)
	{
		if ([fileName hasPrefix:@"Screen shot "])
		{
			NSString *datestring = [[[[[fileName stringByDeletingPathExtension] substringFromIndex:8] stringByReplacingOccurrencesOfString:@" at" withString:@""] stringByReplacingOccurrencesOfString:@"." withString:@":"] stringByAppendingString:@" -0600"];
			NSDate *picDate = [NSDate dateWithNaturalLanguageString:datestring];
			NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:picDate];
			if (t < 5.0f)
			{
				CFShow(fileName);
				NSString *path = [DESKTOP stringByAppendingPathComponent:fileName];
				
				NSImage *image = [[[NSImage alloc]  initWithContentsOfFile:path] autorelease];
				NSArray *representations = [image representations];
				NSData * bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:nil];
				[bitmapData writeToFile:@"/tmp/foo.jpg" atomically:YES];
				
				UploadOperation *op = [[[UploadOperation alloc] init] autorelease];
				op.path = @"/tmp/foo.jpg";
				op.delegate = self;
				[op start];
			}
		}
	}
}
@end

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    printf("Starting Pic Capture Scan. ^C to quit.\n");
	
	Watcher *watcher = [[Watcher alloc] init];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:watcher selector:@selector(notify:) name:@"com.apple.carbon.core.DirectoryNotification" object:nil];
	CFRunLoopRun();
	
    [pool drain];
    return 0;
}
