//
//  ABMapPin.m
//  BioTechFinder
//
//  Created by Alex Blokker on 2/20/16.
//  Copyright © 2016 Blokkmani. All rights reserved.
//

#import "ABMapPin.h"

@implementation ABMapPin {
	CLLocationCoordinate2D _coordinate;
	NSString *_title;
	NSString *_subTitle;
}

- (id)initWithCoordinates:(CLLocationCoordinate2D)location placeName:(NSString *)placeName description:(NSString *)description {
	self = [super init];
	if (self) {
		_coordinate = location;
		_title = placeName;
		_subTitle = description;
	}
	return self;
}

@end
