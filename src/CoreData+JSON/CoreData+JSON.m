//
//  CoreData+JSON.m
//  CoreData+JSON
//
//  Created by Elliot Neal on 27/12/2010.
//  Copyright 2010 emdentec. All rights reserved.
//

#import "CoreData+JSON.h"
#import "JCMappingModelCache.h"

void JCClearMapCache()
{
	[[JCMappingModelCache defaultCache] clearCache];
}