//
//	MDExport.m
//	MDExport
//
//	Created by Hans-Christian Pahlig on 25.07.10.
//	Copyright Apple Inc 2010. All rights reserved.
//

#import "MDExport.h"


@implementation MDExport

//---------------------------------------------------------
// initWithAPIManager:
//
// This method is called when a plug-in is first loaded, and
// is a good point to conduct any checks for anti-piracy or
// system compatibility. This is also your only chance to
// obtain a reference to Aperture's export manager. If you
// do not obtain a valid reference, you should return nil.
// Returning nil means that a plug-in chooses not to be accessible.
//---------------------------------------------------------

 - (id)initWithAPIManager:(id<PROAPIAccessing>)apiManager
{
	if (self = [super init])
	{
		_apiManager	= apiManager;
		_exportManager = [[_apiManager apiForProtocol:@protocol(ApertureExportManager)] retain];
		if (!_exportManager)
			return nil;
		
		_progressLock = [[NSLock alloc] init];
		
		// Finish your initialization here
	}
	
	return self;
}

- (void)dealloc
{
	// Release the top-level objects from the nib.
	[_topLevelNibObjects makeObjectsPerformSelector:@selector(release)];
	[_topLevelNibObjects release];
	
	[_progressLock release];
	[_exportManager release];
	
	[super dealloc];
}


#pragma mark -
// UI Methods
#pragma mark UI Methods

- (NSView *)settingsView
{
	if (nil == settingsView)
	{
		// Load the nib using NSNib, and retain the array of top-level objects so we can release
		// them properly in dealloc
		NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
		NSNib *myNib = [[NSNib alloc] initWithNibNamed:@"MDExport" bundle:myBundle];
		if ([myNib instantiateNibWithOwner:self topLevelObjects:&_topLevelNibObjects])
		{
			[_topLevelNibObjects retain];
		}
		[myNib release];
	}
	
	return settingsView;
}

- (NSView *)firstView
{
	return firstView;
}

- (NSView *)lastView
{
	return lastView;
}

- (void)willBeActivated
{
	
}

- (void)willBeDeactivated
{
	
}

#pragma mark
// Aperture UI Controls
#pragma mark Aperture UI Controls

- (BOOL)allowsOnlyPlugInPresets
{
	return NO;	
}

- (BOOL)allowsMasterExport
{
	return YES;	
}

- (BOOL)allowsVersionExport
{
	return YES;	
}

- (BOOL)wantsFileNamingControls
{
	return YES;	
}

- (void)exportManagerExportTypeDidChange
{
	
}


#pragma mark -
// Save Path Methods
#pragma mark Save/Path Methods

- (BOOL)wantsDestinationPathPrompt
{
	return NO;
}

- (NSString *)destinationPath
{
	return @"/Users/hc/Pictures/MDExportPictures";
}

- (NSString *)defaultDirectory
{
	return nil;
}


#pragma mark -
// Export Process Methods
#pragma mark Export Process Methods

- (void)exportManagerShouldBeginExport
{
	[_exportManager shouldBeginExport];
	// You must call [_exportManager shouldBeginExport] here or elsewhere before Aperture will begin the export process
}

- (void)exportManagerWillBeginExportToPath:(NSString *)path
{

}

- (BOOL)exportManagerShouldExportImageAtIndex:(unsigned)index
{
/*
 * Variante extra-Verzeichnis: Verzeichnishierarchie anlegen
 *
	 //#define PATH_PREFIX @"/Users/hc/Pictures/XMP_EXPORT"
 */	

#define XMP_SUFFIX @".xmp"

	NSDictionary *dict = [_exportManager propertiesWithoutThumbnailForImageAtIndex:index];

	NSString *master = [dict valueForKey:@"kExportKeyReferencedMasterPath"];
	
/*
 * Variante extra-Verzeichnis: Verzeichnishierarchie anlegen
 *
	// Extension durch .xmp ersetzen, Pfad-Präfix anhängen
	// NSString *master_mod = [PATH_PREFIX stringByAppendingPathComponent:[[master stringByDeletingPathExtension] stringByAppendingString:XMP_SUFFIX]];
*/
	
	// Variante Sidecar: Extension durch .xmp ersetzen
	NSString *master_mod = [[master stringByDeletingPathExtension] stringByAppendingString:XMP_SUFFIX];
	
	NSString *xmp = [dict valueForKey:@"kExportKeyXMPString"];

/*
 * Variante extra-Verzeichnis: Verzeichnishierarchie anlegen
 *
	NSString *master_path = [master_mod stringByDeletingLastPathComponent];

	NSFileManager *filemgr = [[NSFileManager alloc] init];
	NSError *err;
	BOOL is_dir;

	if (![filemgr fileExistsAtPath:master_path isDirectory:&is_dir]) {
		// Verzeichnis existiert noch nicht - anlegen
		if(![filemgr createDirectoryAtPath:master_path withIntermediateDirectories:YES attributes:nil error:&err]) {
			// Problem beim Verzeichnis anlegen
			NSLog(@"Kann Verzeichnis %@ nicht anlegen, Fehler %@", master_path, err );
			return NO;
		}
	} else {
		if (!is_dir) {
			NSLog(@"Problem: Verzeichnis %@ existiert, ist aber eine Datei", master_path);
			return NO;
		}
	}
 */
	
	// Variante sidecar: Check, ob die Datei ein Verzeichnis ist. Sicherheitshalber...
	// Eigentlich müsste ich checken, ob der erbastelte XMP-Dateiname zufällig eine
	// Bilddatei ist. Aber wie? Dateigröße? XMP-Dateien <=50k, Fotos immer >50k?
	NSFileManager *filemgr = [[NSFileManager alloc] init];
	NSError *err;
	BOOL is_dir;
	
	if ([filemgr fileExistsAtPath:master_mod isDirectory:&is_dir]) {
		if (is_dir) {
			NSLog(@"Problem: Datei %@ existiert, ist aber ein Verzeichnis???", master_mod);
			return NO;
		}
	}


	// XMP-Datei schreiben 
	if (![xmp writeToFile:master_mod atomically:NO encoding:NSUTF8StringEncoding error:&err]) {
		NSLog(@"Schreibfehler %@", err );
	}
	
	// eigentliche Fotodatei nicht exportieren
	return NO;
}

- (void)exportManagerWillExportImageAtIndex:(unsigned)index
{
	
}

- (BOOL)exportManagerShouldWriteImageData:(NSData *)imageData toRelativePath:(NSString *)path forImageAtIndex:(unsigned)index
{
	// Dieser Code sollte eigentlich nicht aufgerufen werden
	// Falls doch: Das Plugin kümmert sich ums Daten schreiben -- und tut nichts 
	return NO;	
}

- (void)exportManagerDidWriteImageDataToRelativePath:(NSString *)relativePath forImageAtIndex:(unsigned)index
{
	
}

- (void)exportManagerDidFinishExport
{
	// You must call [_exportManager shouldFinishExport] before Aperture will put away the progress window and complete the export.
	// NOTE: You should assume that your plug-in will be deallocated immediately following this call. Be sure you have cleaned up
	// any callbacks or running threads before calling.
	[_exportManager shouldFinishExport];
}

- (void)exportManagerShouldCancelExport
{
	// You must call [_exportManager shouldCancelExport] here or elsewhere before Aperture will cancel the export process
	// NOTE: You should assume that your plug-in will be deallocated immediately following this call. Be sure you have cleaned up
	// any callbacks or running threads before calling.
	[_exportManager shouldCancelExport];
}


#pragma mark -
	// Progress Methods
#pragma mark Progress Methods

- (ApertureExportProgress *)progress
{
	return &exportProgress;
}

- (void)lockProgress
{
	
	if (!_progressLock)
		_progressLock = [[NSLock alloc] init];
		
	[_progressLock lock];
}

- (void)unlockProgress
{
	[_progressLock unlock];
}

@end
