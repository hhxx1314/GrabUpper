/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 3.0 Edition
 BSD License, Use at your own risk
 */

#import <Foundation/Foundation.h>

@protocol UploadOperationDelegate <NSObject>
- (void) doneUploading: (NSString *) status;
@end

@interface UploadOperation : NSOperation 
{
	id <UploadOperationDelegate> delegate;
	NSString *path;
}
@property (retain) id delegate;
@property (retain) NSString *path;
@end
