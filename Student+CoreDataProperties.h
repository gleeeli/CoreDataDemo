//
//  Student+CoreDataProperties.h
//  TestJumpToWifinonPublicApi
//
//  Created by dsw on 17/6/15.
//  Copyright © 2017年 dsw. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Student.h"

NS_ASSUME_NONNULL_BEGIN

@interface Student (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *salary;
@property (nullable, nonatomic, retain) NSNumber *studentAge;
@property (nullable, nonatomic, retain) NSNumber *studentID;
@property (nullable, nonatomic, retain) NSString *studentName;
@property (nullable, nonatomic, retain) NSString *studentuuid;

@end

NS_ASSUME_NONNULL_END
