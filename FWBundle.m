//
//  FWBundle.m
//  tetherKit
//
//  Created by Kevin Bradley on 1/14/11.
//  Copyright 2011 FireCore, LLC. All rights reserved.
//

#import "FWBundle.h"
#import "nitoUtility.h"


@implementation FWBundle

@synthesize fwRoot;

+ (FWBundle *)bundleWithName:(NSString *)bundleName
{
	
	NSString *thePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle" inDirectory:@"bundles"];
	if (![FM fileExistsAtPath:thePath])
		return nil;
	FWBundle *theBundle = [[FWBundle alloc] initWithPath:thePath];
	theBundle.fwRoot = TMP_ROOT;
	return [theBundle autorelease];
}

+ (FWBundle *)bundleForFile:(NSString *)theFile
{
	NSString *filename = [[theFile lastPathComponent] stringByDeletingPathExtension];
	NSArray *filenameSplit = [filename componentsSeparatedByString:@"_Restore"];
	NSString *newName = [filenameSplit objectAtIndex:0];
		//NSLog(@"checking for: %@", newName);
	FWBundle *theBundle = [FWBundle bundleWithName:newName];
		//NSLog(@"theBundle: %@", theBundle);
	return theBundle;
}

/*
 
 BuildIdentities - > object at index 0 - > Manifest  (dict) - > KernelCache
 BuildIdentities - > object at index 0 - > Manifest  (dict) - > iBSS
 
 */

- (NSDictionary *)buildManifest
{
	NSArray *buildIdentities = [[self fwDictionary] objectForKey:@"BuildIdentities"];
	NSDictionary *one = [buildIdentities lastObject];
	return [one valueForKey:@"Manifest"];
	
}

- (NSString *)kernelCacheName
{
	return [[[[self buildManifest] valueForKey:@"KernelCache"] valueForKey:@"Info"] valueForKey:@"Path"];
}

- (NSString *)iBSSName
{
	return [[[[self buildManifest] valueForKey:@"iBSS"] valueForKey:@"Info"] valueForKey:@"Path"];
}

- (NSDictionary *)fwDictionary
{
	NSString *buildM = [TMP_ROOT stringByAppendingPathComponent:@"BuildManifest.plist"];
	if ([FM fileExistsAtPath:buildM])
	{
		return [NSDictionary dictionaryWithContentsOfFile:buildM];
		
	} else {
		buildM = [IPSW_TMP stringByAppendingPathComponent:@"BuildManifest.plist"];
		if ([FM fileExistsAtPath:buildM])
		{
			return [NSDictionary dictionaryWithContentsOfFile:buildM];
			
		}
	}
	return nil;
}

- (NSString *)localBundlePath
{
	return [[nitoUtility applicationSupportFolder] stringByAppendingPathComponent:[[self bundleName] stringByAppendingPathExtension:@"bundle"]];
}

- (NSDictionary *)localManifest
{
	NSString *bundlePath = [self localBundlePath];
	NSString *bm = [bundlePath stringByAppendingPathComponent:@"BuildManifest.plist"];
	if ([FM fileExistsAtPath:bm])
	{
		return [NSDictionary dictionaryWithContentsOfFile:bm];
		
	}
	return nil;
}

- (NSString *)localiBSS
{
	if ([self localManifest] != nil)
	{
		return [[self localBundlePath] stringByAppendingPathComponent:[[self localManifest] valueForKey:@"iBSS"]];
	}
	return nil;
}

- (NSString *)localKernel
{
	if ([self localManifest] != nil)
	{
		return [[self localBundlePath] stringByAppendingPathComponent:[[self localManifest] valueForKey:@"KernelCache"]];
	}
	return nil;
}


- (NSString *)outputName
{
	return [[self bundleName] stringByAppendingString:@"_SP_Restore.ipsw"];
}

- (NSString *)ramdiskSize
{
	if ([[self bundleName] isEqualToString:@"AppleTV2,1_4.3_8F5148c"])
	{
		return @"24676576";
	} else if ([[self bundleName] isEqualToString:@"AppleTV2,1_4.3_8F5153d"]){
		return @"24676576";
	} else {
		return @"16541920";	}
}

- (NSDictionary *)extraPatch
{
	if ([[self bundleName] isEqualToString:@"AppleTV2,1_4.3_8F5148c"])
	{
		NSDictionary *thePatch = [NSDictionary dictionaryWithObjectsAndKeys:[[NSBundle mainBundle] pathForResource:@"status" ofType:@"patch" inDirectory:@"patches"], @"Patch", @"private/var/lib/dpkg/status", @"Target", @"7945d79f0dad7c3397b930877ba92ec4", @"md5", nil];
		NSLog(@"extraPatch: %@", thePatch);
		return thePatch;					  
	}
	
	if ([[self bundleName] isEqualToString:@"AppleTV2,1_4.3_8F5153d"])
	{
		NSDictionary *thePatch = [NSDictionary dictionaryWithObjectsAndKeys:[[NSBundle mainBundle] pathForResource:@"status" ofType:@"patch" inDirectory:@"patches"], @"Patch", @"private/var/lib/dpkg/status", @"Target", @"7945d79f0dad7c3397b930877ba92ec4", @"md5", nil];
		NSLog(@"extraPatch: %@", thePatch);
		return thePatch;					  
	}
	
	return nil;
}

- (NSDictionary *)coreFilesInstallation
{
	return [[self filesystemPatches] valueForKey:CORE_FILES];
}

- (NSString *)restoreRamdiskVolume
{
	return [[self infoDictionary] valueForKey:MOUNTED_RAMDISK];
}

- (void)logDescription
{
	NSLog(@"filename: %@", [self filename]);
	NSLog(@"iBSS: %@", [self iBSS]);
	NSLog(@"Restore Ramdisk: %@", [self restoreRamdisk]);
	NSLog(@"Update Ramdisk: %@", [self updateRamdisk]);
	NSLog(@"RootFilesystem: %@", [self rootFilesystem]);
	NSLog(@"Filesystem Patches: %@", [self filesystemPatches]);
	NSLog(@"bundlePath: %@", [self bundlePath]);
	NSLog(@"fwRoot: %@", [self fwRoot]);
	NSLog(@"bundleName: %@", [self bundleName]);
	NSLog(@"kernelCache: %@", [self kernelCacheName]);
	NSLog(@"iBSS: %@", [self iBSSName]);
	NSLog(@"AppleLogo: %@", [self appleLogo]);
}

- (NSString *)bundleName
{
	return [[self infoDictionary] valueForKey:@"Name"];
}

- (NSString *)restoreRamdiskFile
{
	return [[self restoreRamdisk] valueForKey:@"File"];
}

- (NSString *)updateRamdiskFile
{
	return [[self updateRamdisk] valueForKey:@"File"];
}

- (NSDictionary *)restoreRamdisk;
{
	return [[self firmwarePatches] valueForKey:RESTORE_RD];
}

- (NSDictionary *)updateRamdisk
{
	
	return [[self firmwarePatches] valueForKey:UPDATE_RD];
}

- (NSDictionary *)iBSS
{
	return [[self firmwarePatches] valueForKey:@"iBSS"];
}

- (NSDictionary *)appleLogo
{
	return [[self firmwarePatches] valueForKey:@"AppleLogo"];
}


- (NSString *)rootFilesystem
{
	return [[self infoDictionary] valueForKey:ROOT_FS];
}

- (NSString *)filesystemKey
{
	return [[self infoDictionary] valueForKey:FS_KEY];
}

- (NSString *)filename
{
	return [[self infoDictionary] valueForKey:FILE_NAME];
}

- (NSDictionary *)filesystemPatches
{
	return [[self infoDictionary] valueForKey:FS_PATCHES];
}

- (NSArray *)filesystemJailbreak
{
	return [[self filesystemPatches] valueForKey:FS_JB];
}

- (NSDictionary *)firmwarePatches
{
	return [[self infoDictionary] valueForKey:FW_PATCHES];
	
}

- (NSDictionary *)ramdiskPatches
{
	return [[self infoDictionary] valueForKey:RD_PATCHES];
}

- (NSDictionary *)preInstalledPackages
{
	return [[self infoDictionary] valueForKey:PREINST_PACKAGES];
}

- (void)dealloc
{
	[fwRoot release];
	fwRoot = nil;
	[super dealloc];
}

@end