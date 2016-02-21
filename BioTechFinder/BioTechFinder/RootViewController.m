//
//  ViewController.m
//  BioTechFinder
//
//  Created by Alex Blokker on 2/19/16.
//  Copyright © 2016 Blokkmani. All rights reserved.
//

#import "RootViewController.h"
#import "ABMapPin.h"

#define BOSTONAREALOCATION CLLocationCoordinate2DMake(42.359268746396054, -71.313874132222352), MKCoordinateSpanMake(1.5769176697540814, 1.3147296282506034)
#define SEARCHDELAY (int64_t)(4 * NSEC_PER_SEC)) // Note: Apple will throttle you if you set this value too low

static NSString *pinIdentifier = @"ABPinIdentifier";

typedef void (^ExecuteSearchBlock)(void);

@interface RootViewController () @end

@implementation RootViewController {
	NSArray *_companies;
	NSMutableArray <MKMapItem *> *_mapItems;
	NSMutableArray *_executeBlocks;
	NSMutableDictionary *_cachedResults;
	MKMapView *_mapView;
	UIProgressView *_progressView;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
		_companies = [self loadCompanyFile];
		_mapItems = [[NSMutableArray alloc] init];
		_executeBlocks = [[NSMutableArray alloc] init];
		_mapView = [[MKMapView alloc] init];
		_mapView.delegate = self;
		[self.view addSubview:_mapView];

		MKCoordinateRegion region = MKCoordinateRegionMake(BOSTONAREALOCATION);
		[_mapView setRegion:region];
	}
	return self;
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	_mapView.frame = self.view.bounds;
	_progressView.frame = CGRectMake(0, 42, self.view.bounds.size.width, 5);
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(rightButtonTapped)];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.navigationController.navigationBar addSubview:_progressView];

}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	_cachedResults = [self loadCachedResults];
	if (_cachedResults.count) {
		[self addMapPointsFromCached];
	}
#if (0)
	[self beginSearching];
#endif
}

-(void)beginSearching {
	__weak RootViewController *weakSelf = self;
	for (NSMutableDictionary *company in _companies) {
		NSString *name = company[@"name"];
		ExecuteSearchBlock searchBlock = ^{
			[weakSelf updateProgress];
			[weakSelf searchOnName:name withLocation:@"" andContinue:^(BOOL delayNext) {
				[_executeBlocks removeObjectAtIndex:0];
				ExecuteSearchBlock nextBlock = _executeBlocks.firstObject;
				if (nextBlock) {
					if (delayNext) {
						// we must delay the request to avoid being throttled
						dispatch_after(dispatch_time(DISPATCH_TIME_NOW, SEARCHDELAY, dispatch_get_main_queue(), ^{
							nextBlock();
						});
					} else {
						nextBlock();
					}
				} else {
					// done executing!
					[self finishedRequests];
				}
		}];
		};
		[_executeBlocks addObject:searchBlock];
	}
   // only use the 1st 25 companies
   //[_executeBlocks removeObjectsInRange:NSMakeRange(25, _executeBlocks.count-25)];
   ExecuteSearchBlock firstBlock = _executeBlocks.firstObject;
   if (firstBlock) {
	   firstBlock();
   }
}

- (void)updateProgress
{
	_progressView.progress = 1.0 - (float)_executeBlocks.count / (float)_companies.count;
}

- (void)addMapPointsFromCached
{
	for (NSString *key in _cachedResults.allKeys) {
		NSArray *locations = _cachedResults[key];
		for (NSDictionary *location in locations) {
			NSNumber *lat = location[@"lat"];
			NSNumber *lng = location[@"lng"];
			CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat.doubleValue, lng.doubleValue);
			ABMapPin *pin = [[ABMapPin alloc] initWithCoordinates:coordinate placeName:key description:@""];
			[_mapView addAnnotation:pin];
		}
	}
}

- (void)addMapPointsFromSearchResults
{
	for (MKMapItem *item in _mapItems) {
		[self addMapItemToMap:item];
	}
}

- (void)addMapItemToMap:(MKMapItem *)mapItem {
	ABMapPin *pin = [self pinFromMapItem:mapItem];
	[_mapView addAnnotation:pin];
}

- (ABMapPin *)pinFromMapItem:(MKMapItem *)item {
	CLLocationCoordinate2D coordinate = item.placemark.coordinate;
	ABMapPin *pin = [[ABMapPin alloc] initWithCoordinates:coordinate placeName:item.name description:item.url.absoluteString];
	return pin;
}

- (void)finishedRequests {
	_progressView.hidden = YES;
	[self addMapPointsFromSearchResults];
}

- (void)rightButtonTapped {
	[self saveCachedResults];
}

- (void)searchOnName:(NSString *)name withLocation:(NSString *)location andContinue:(void(^)(BOOL delayNext))continueBlock {
	NSDictionary *dict = _cachedResults[name];
	if (dict) { // already have the results, so skip it
		NSLog(@"Skipping: %@", name);
		continueBlock(NO);
		return;
	}
	NSLog(@"Searching: %@", name);
	[self searchOnQuery:name completion:^(NSArray<MKMapItem *> *mapItems) {
		if (mapItems.count) {
			NSLog(@"Adding %lu result(s)", mapItems.count);
			[_mapItems addObjectsFromArray:mapItems];
			NSMutableArray *locations = _cachedResults[name];
			if (!locations.count) {
				locations = _cachedResults[name] = [NSMutableArray new];
			}
			for (MKMapItem *item in mapItems) {
				CLLocationCoordinate2D coordinate = item.placemark.coordinate;
				[locations addObject:@{@"lat":@(coordinate.latitude), @"lng":@(coordinate.longitude)}];
				[self addMapItemToMap:item];
			}
		}
		continueBlock(YES);
	}];
}

- (void)searchOnQuery:(NSString *)query completion:(void(^)(NSArray<MKMapItem *> *mapItems))completion {
	MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
	request.naturalLanguageQuery = query;
	MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];

	// Start the search and display the results as annotations on the map.
	[search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
		if (completion && !error) {
			completion(response.mapItems);
		} else {
			NSLog(@"Search Error: %@\n Continuing", error.localizedDescription);
			completion(nil);
		}
	}];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKPinAnnotationView *pinView = nil;
	if(annotation!= _mapView.userLocation) {
		pinView = (MKPinAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:pinIdentifier];
		if(!pinView) {
			pinView = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:pinIdentifier];
			pinView.canShowCallout = YES;
			pinView.animatesDrop = YES;
		}
	}
	else {
		[_mapView.userLocation setTitle:@"You are Here!"];
	}
	return pinView;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (NSArray *)loadCompanyFile
{
	NSData *data = [NSData dataWithContentsOfURL:[NSBundle.mainBundle URLForResource:@"companies" withExtension:@"json"]];
	NSError *error;
	NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
	if (error) {
		NSLog(@"Json Error: %@", error.localizedDescription);
	}
	return array;
}

- (void)saveCompanyFile
{
	NSError *error;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_companies options:NSJSONWritingPrettyPrinted error:&error];
	if (error) {
		NSLog(@"Json Parse Error: %@", error.localizedDescription);
		return;
	}
	[jsonData writeToURL:[NSBundle.mainBundle URLForResource:@"companies" withExtension:@"json"] atomically:YES];
	if (error) {
		NSLog(@"Writing Json Error: %@", error.localizedDescription);
	}
}

-(NSString *)cachedResultsFilePath {
	return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"cachedResults.json"];
}

- (void)saveCachedResults
{
	NSAssert(_cachedResults, @"Expect a Dictionary");
	NSError *error;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_cachedResults options:NSJSONWritingPrettyPrinted error:&error];
	if (error) {
		NSLog(@"Json Parsing Erro: %@", error.localizedDescription);
		return;
	}
	NSString *locationsJSONString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	NSString *filePath = [self cachedResultsFilePath];

	if (![NSFileManager.defaultManager fileExistsAtPath:filePath]) {
		[NSFileManager.defaultManager createFileAtPath:filePath contents:nil attributes:nil];
	}
	[locationsJSONString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
}

- (NSMutableDictionary *)loadCachedResults
{
	NSError *error;
	NSString *filePath = [self cachedResultsFilePath];
	NSData *locationsData = [NSData dataWithContentsOfFile:filePath];
	if (!locationsData) {
		return [NSMutableDictionary new];
	}
	NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:locationsData options:NSJSONReadingMutableContainers error:&error];
	if (error) {
		NSLog(@"Json Error: %@", error.localizedDescription);
	}
	NSMutableDictionary *mutibleDict;
	if (dict) {
		mutibleDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
	return mutibleDict;
}

@end
