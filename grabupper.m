#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "UploadOperation.h"

@interface Watcher : NSObject <UploadOperationDelegate>
@end

@implementation Watcher
- (void) doneUploading:(NSString *)status
{
	// Range didn't work. This does.  First look for imgup
	NSString *endString = [[status componentsSeparatedByString:@"imgup"] lastObject];
	
	// Then grab the start of the http://
	NSArray *items = [endString componentsSeparatedByString:@"img src=\""];
	if (items.count < 2) {printf("Error extracting URL from GrabUp response.");	return;}
	
	// Find the end of the URL
	endString = [items objectAtIndex:1];
	items = [endString componentsSeparatedByString:@"?direct"];
	if (items.count < 2) {printf("Error extracting URL from GrabUp response.");	return;}
	
	// And add the ?direct back in. (Trust me, it's better that way.)
	endString = [[items objectAtIndex:0] stringByAppendingString:@"?direct"];
	
	// Shorten with bitly, if possible
	NSString *bitlyString = [NSString stringWithFormat:@"http://bit.ly/?s=&keyword=&url=%@", [endString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	bitlyString = [NSString stringWithContentsOfURL:[NSURL URLWithString:bitlyString] encoding:NSUTF8StringEncoding error:nil];
	if (bitlyString)
	{
		items = [bitlyString componentsSeparatedByString:@"shortUrl\": "];
		if (items.count > 1)
		{
			items = [[items objectAtIndex:1] componentsSeparatedByString:@"\""];
			if (items.count > 2) endString = [items objectAtIndex:1];
		}
	}

	// Create URL from the string
	NSURL *url = [NSURL URLWithString:endString];
	
	// Add it to the pasteboard
	NSString *type = NSURLPboardType;
	[[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:type] owner:nil];
	[url writeToPasteboard:[NSPasteboard generalPasteboard]];

	// Alternatively, text
	// [[NSPasteboard generalPasteboard] setString:endString forType:NSStringPboardType];
	
	// Write info to stdout too
	printf("Pasteboard:\n%s\n\n", [endString UTF8String]);
	
	// Alert with result. Select from any of the following.
	// system("afplay /System/Library/Sounds/Glass.aiff");
	system("say 'You Are Ell is ready'");
	
	// Open URL in Browser
	NSString *doit = [NSString stringWithFormat:@"open %@", endString];
	system([doit UTF8String]);
}

- (void) notify: (NSNotification *) notification
{
	// Screen cap prefs
	NSString *scprefspath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.apple.screencapture.plist"];
	NSDictionary *scdict = [NSDictionary dictionaryWithContentsOfFile:scprefspath];

	// Get prefix
	NSString *prefix = @"Screen shot";
	if (scdict && [scdict objectForKey:@"name"]) prefix = [scdict objectForKey:@"name"];
	
	// Get path
	NSString *basepath = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"];
	if (scdict && [scdict objectForKey:@"location"]) basepath = [scdict objectForKey:@"location"];
		
	// Iterate through all files at that path
	NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:basepath error:nil];
	for (NSString *fileName in files)
	{
		// if there's a file that matches the prefix
		if ([fileName hasPrefix:prefix])
		{
			// Extract the date string and use natural language matching to get its date
			NSString *datestring = [[[[[fileName stringByDeletingPathExtension] substringFromIndex:8] stringByReplacingOccurrencesOfString:@" at" withString:@""] stringByReplacingOccurrencesOfString:@"." withString:@":"] stringByAppendingString:@" -0600"];
			NSDate *picDate = [NSDate dateWithNaturalLanguageString:datestring];
			
			// Determine the length of time since the screen was shot.
			NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:picDate];
			
			// Proceed if the time interval lies within 10 seconds
			// New extra time is to allow for better screen shot layout
			if (t < 10.0f)
			{
				// Get the full path and the actual image
				NSString *path = [basepath stringByAppendingPathComponent:fileName];
				NSImage *image = [[[NSImage alloc]  initWithContentsOfFile:path] autorelease];
				
				// Convert the image to jpeg (use "NSPNGFileType" for PNG)
				NSArray *representations = [image representations];
				NSData * bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:nil];
				[bitmapData writeToFile:@"/tmp/foo.jpg" atomically:YES];
				
				// Upload the image
				UploadOperation *op = [[[UploadOperation alloc] init] autorelease];
				op.path = @"/tmp/foo.jpg";
				op.delegate = self;
				[op start];
			}
		}
		else if ([fileName hasPrefix:@"Snapz"]) // Snapz Pro Shot
		{
			NSString *path = [basepath stringByAppendingPathComponent:fileName];
			NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
			NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:[dict objectForKey:NSFileCreationDate]];

			// Proceed if the time interval lies within 5 seconds
			if (t < 5.0f)
			{
				// Get the full path and the actual image
				NSImage *image = [[[NSImage alloc]  initWithContentsOfFile:path] autorelease];
				
				// Convert the image to jpeg (use "NSPNGFileType" for PNG)
				NSArray *representations = [image representations];
				NSData * bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:nil];
				[bitmapData writeToFile:@"/tmp/foo.jpg" atomically:YES];
				
				// Upload the image
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
	
	// Listen for Directory Update events
    printf("Starting Pic Capture Scan. ^C to quit.\n");
	Watcher *watcher = [[Watcher alloc] init];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:watcher selector:@selector(notify:) name:@"com.apple.carbon.core.DirectoryNotification" object:nil];
	CFRunLoopRun();
	
	[watcher release];
    [pool drain];
    return 0;
}
