//
//  ResourceManagerTilelessEditorManager.m
//  CocosBuilder
//
//  Created by Viktor on 7/24/13.
//
//

#import "ResourceManagerTilelessEditorManager.h"
#import "ResourceManager.h"
#import "ResourceManagerUtil.h"

@implementation ResourceManagerTilelessEditorManager

- (id) initWithImageBrowser:(IKImageBrowserView*)bw
{
    self = [super init];
    if (!self) return NULL;
    
    // Keep track of browser
    browserView = bw;
    browserView.dataSource = self;
    
    // Setup options
    browserView.intercellSpacing = CGSizeMake(2, 2);
    browserView.cellSize = CGSizeMake(54, 54);
    [browserView setValue:[NSColor colorWithCalibratedRed:0.93 green:0.93 blue:0.93 alpha:1] forKey:IKImageBrowserBackgroundColorKey];
    
    // Title font
    NSMutableDictionary* attr = [NSMutableDictionary dictionary];
    [attr setObject:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];
    [browserView setValue:attr forKey:IKImageBrowserCellsTitleAttributesKey];
    
    // Register with resource manager
    [[ResourceManager sharedManager] addResourceObserver:self];
    
    imageResources = [[NSMutableArray alloc] init];
    imageGroups = [[NSMutableArray alloc] init];
    
    return self;
}

#pragma mark Image Browser Data Provier

- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index
{
    return [imageResources objectAtIndex:index];
}

- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *) aBrowser
{
    return [imageResources count];
}

- (NSDictionary *) imageBrowser:(IKImageBrowserView *) aBrowser groupAtIndex:(NSUInteger) index
{
    return [imageGroups objectAtIndex:index];
}

- (NSUInteger) numberOfGroupsInImageBrowser:(IKImageBrowserView *) aBrowser
{
    return [imageGroups count];
}

#pragma mark Callback from ResourceMangager

- (void) resourceListUpdated
{
    [imageResources removeAllObjects];
    [imageGroups removeAllObjects];
    
    if ([ResourceManager sharedManager].activeDirectories.count > 0)
    {
        NSDictionary* dirs = [ResourceManager sharedManager].directories;
        for (NSString* dirPath in dirs)
        {
            RMDirectory* dir = [dirs objectForKey:dirPath];
            
            int numAddedFiles = 0;
            int startFileIdx = [imageResources count];
            
            for (RMResource* res in dir.any)
            {
                if (res.type == kCCBResTypeImage ||
                    res.type == kCCBResTypeCCBFile)
                {
                    [imageResources addObject:res];
                    numAddedFiles++;
                }
            }
            
            if (numAddedFiles > 0)
            {
                NSString* relDirPath = [dir.dirPath lastPathComponent];
                if (!relDirPath || [relDirPath isEqualToString:@""]) relDirPath = @"Resources";
                
                // Add a group
                NSMutableDictionary* group = [NSMutableDictionary dictionary];
                [group setObject:[NSValue valueWithRange:NSMakeRange(startFileIdx, numAddedFiles)] forKey:IKImageBrowserGroupRangeKey];
                [group setObject:relDirPath forKey:IKImageBrowserGroupTitleKey];
                [group setObject:[NSNumber numberWithInt:IKGroupDisclosureStyle] forKey:IKImageBrowserGroupStyleKey];
                
                // Colors
                CGColorRef cBlack = CGColorCreateGenericRGB(0, 0, 0, 1);
                CGColorRef cGray = CGColorCreateGenericRGB(0.63, 0.63, 0.63, 1);
                
                // Create group header with background image
                CALayer *headerLayer = [CALayer layer];
                headerLayer.contentsScale = [[NSScreen mainScreen] backingScaleFactor];
                headerLayer.frame = CGRectMake(0, 0, 100, 16);
                headerLayer.contents = [NSImage imageNamed:@"header-bg2-crop.png"];
                
                // Text for header
                CATextLayer* textLayer = [CATextLayer layer];
                textLayer.contentsScale = [[NSScreen mainScreen] backingScaleFactor];
                textLayer.bounds = CGRectMake(0, 0, 250, 20);
                textLayer.frame = CGRectMake(3, -5, 250, 20);
                textLayer.string = relDirPath;
                textLayer.font = [NSFont systemFontOfSize:11];
                textLayer.fontSize = 11;
                textLayer.foregroundColor = cBlack;
                
                [headerLayer addSublayer:textLayer];
                
                // Empty footer layer
                CALayer* footerLayer = [CALayer layer];
                footerLayer.backgroundColor = cGray;
                footerLayer.frame = CGRectMake(0, 0, 100, 5);
                
                [group setObject:headerLayer forKey:IKImageBrowserGroupHeaderLayer];
                [group setObject:footerLayer forKey:IKImageBrowserGroupFooterLayer];
                
                [imageGroups addObject:group];
                
                // Release objects
                CFRelease(cBlack);
                CFRelease(cGray);
            }
        }
    }
    
    [browserView reloadData];
}

#pragma mark Dealloc

- (void) dealloc
{
    [imageResources release];
    [super dealloc];
}

@end