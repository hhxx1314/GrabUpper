/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 3.0 Edition
 BSD License, Use at your own risk
 */

#import "UploadOperation.h"

#define NOTIFY_AND_LEAVE(X) {[self cleanup:X]; return;}
#define DATA(X)	[X dataUsingEncoding:NSUTF8StringEncoding]

// Posting constants. Defined as constants for historical reasons (reused code)
#define BOUNDARY @"------------0x0x0x0x0x0x0x0x"
#define MULTIPART @"multipart/form-data; boundary=------------0x0x0x0x0x0x0x0x"
#define PREFIX [NSString stringWithFormat:@"--%@\r\n", BOUNDARY]
#define EACH_SUFFIX @"\r\n"
#define STRING_CONTENT @"Content-Disposition: form-data; name=\"%@\"\r\n\r\n"
#define SUFFIX [NSString stringWithFormat:@"--%@--\r\n", BOUNDARY]

@implementation UploadOperation
@synthesize path;
@synthesize delegate;

// On cleanup, just re-direct the string to the delegate
- (void) cleanup: (NSString *) output
{
	if (self.delegate && [self.delegate respondsToSelector:@selector(doneUploading:)])
		[self.delegate doneUploading:output];
}

- (void) main
{
	// Create the mutable  body data
	NSMutableData *postData = [[NSMutableData alloc] init];

	// First of two arguments, action to take
	NSString *firstArg = [NSString stringWithFormat:STRING_CONTENT, @"app_upload"];
	[postData appendData:DATA(PREFIX)];
	[postData appendData:DATA(firstArg)];
	[postData appendData:DATA(@"Upload")];
	[postData appendData:DATA(EACH_SUFFIX)];
	
	// Second of two arguments, the file name and data
	NSString *secondArg = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", [self.path lastPathComponent]];
	[postData appendData:DATA(PREFIX)];
	[postData appendData:DATA(secondArg)];
	[postData appendData:DATA(@"Content-Type: application/octet-stream\r\n\r\n")];
	[postData appendData:[NSData dataWithContentsOfFile:self.path]];
	[postData appendData:DATA(EACH_SUFFIX)];
	
	// Finish form
	[postData appendData:DATA(SUFFIX)];
	
	// Create the POST URL request
    NSString *baseurl = @"http://www.grabup.com/app_upload.php"; 
    NSURL *url = [NSURL URLWithString:baseurl];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    if (!urlRequest) NOTIFY_AND_LEAVE(@"Error creating the URL Request");
    [urlRequest setHTTPMethod: @"POST"];
	[urlRequest setValue:MULTIPART forHTTPHeaderField: @"Content-Type"];
    [urlRequest setHTTPBody:postData];
	[postData release];
	
	// Submit & retrieve results
    NSError *error;
    NSURLResponse *response;
	printf("Contacting GrabUp...\n");
    NSData* result = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    if (!result)
	{
		[self cleanup:[NSString stringWithFormat:@"Submission error: %@", [error localizedDescription]]];
		return;
	}
	
	// Return results
    NSString *outstring = [[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease];
	[self cleanup: outstring];
}
@end