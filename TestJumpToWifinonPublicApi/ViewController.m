//
//  ViewController.m
//  TestJumpToWifinonPublicApi
//
//  Created by dsw on 17/6/13.
//  Copyright © 2017年 dsw. All rights reserved.
//

#import "ViewController.h"
#import <CoreData/CoreData.h>
#import "Student.h"

@interface ViewController ()
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readwrite, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readwrite, strong) NSManagedObjectContext *context;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //注意首字母改成了大写，prefs->Prefs
    NSURL*url=[NSURL URLWithString:@"Prefs:root=Privacy&path=LOCATION"];
    Class LSApplicationWorkspace = NSClassFromString(@"LSApplicationWorkspace");
    [[LSApplicationWorkspace performSelector:@selector(defaultWorkspace)] performSelector:@selector(openSensitiveURL:withOptions:) withObject:url withObject:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        [self databaseOperation];
    });
    
}

// 使用懒加载的方式初始化
- (NSManagedObjectModel *)managedObjectModel
{
    if (!_managedObjectModel)
    {
        // url 为CoreDataDemo.xcdatamodeld，注意扩展名为 momd，而不是 xcdatamodeld 类型
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

// 同样使用懒加载创建
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (!_persistentStoreCoordinator) {
        
        // 如果app升级，数据库做了修改才需要options，否则不需要options = nil就行
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        
        
        
        //NSLog(@"self.managedObjectModel:%@",self.managedObjectModel);
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        
        // 指定本地的 sqlite 数据库文件
        NSURL *sqliteURL = [[self documentDirectoryURL] URLByAppendingPathComponent:@"Model.sqlite"];
        NSLog(@"sqliteURL:%@",sqliteURL);
        NSError *error;
        // 为 persistentStoreCoordinator 指定本地存储的类型，这里指定的是 SQLite
        [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:sqliteURL
                                                        options:options
                                                          error:&error];
        if (error) {
            NSLog(@"falied to create persistentStoreCoordinator %@", error.localizedDescription);
        }
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)context
{
    if (!_context) {
        // 指定 context 的并发类型： NSMainQueueConcurrencyType 或 NSPrivateQueueConcurrencyType
        _context = [[NSManagedObjectContext alloc ] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _context.persistentStoreCoordinator = self.persistentStoreCoordinator;
    }
    return _context;
}

// 用来获取 document 目录
- (nullable NSURL *)documentDirectoryURL {
    return [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
}


- (void)databaseOperation
{
    [self searchData];
//    [self modifyData];
}

#pragma mark *** 保存数据 ***
- (void)save
{
    [self.context save:nil];
}

// 插入一条数据
- (void)insertStudent
{
    Student *student = [NSEntityDescription insertNewObjectForEntityForName:@"Student" inManagedObjectContext:self.context];
    student.studentName = @"li xiao long";
    student.studentAge = [NSNumber numberWithInteger:100];
    student.salary = [NSNumber numberWithInteger:1000];
    [self save];
}

// 查询数据
- (void)searchData
{
    // 初始化一个查询请求
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    // 设置要查询的实体
    request.entity = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:self.context];
    // 执行请求
    NSError *error = nil;
    NSArray *objs = [self.context executeFetchRequest:request error:&error]; // 查询结果是数组
    if (error) {
        [NSException raise:@"查询错误" format:@"%@", [error localizedDescription]];
    }
    NSLog(@"**************start*******************");
    // 遍历数据
    for (NSManagedObject *obj in objs) {
        NSLog(@"name:%@ age:%@", [obj valueForKey:@"studentName"], [obj valueForKey:@"studentAge"]);
    }
}

// 查询特定数据, 添加查询约束
- (void)searchSpecData
{
    //2)创建NSFetchRequest对象（相当于数据库中的SQL语句）
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    //3)创建查询实体（相当于数据库中要查询的表）
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:self.context];
    //设置查询实体
    [request setEntity:entityDescription];
    
    
    //4)创建排序描述符,ascending：是否升序（相当于数据库中排序设置）。此处仅为演示，本实例不需要排序
    NSSortDescriptor *sortDiscriptor = [[NSSortDescriptor alloc] initWithKey:@"studentName" ascending:NO];
    NSArray *sortDiscriptos = [[NSArray alloc] initWithObjects:sortDiscriptor, nil];
    [request setSortDescriptors:sortDiscriptos];
    
    //5)创建查询谓词（相当于数据库中查询条件） // https://my.oschina.net/sunqichao/blog/141900
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(studentName CONTAINS[d] %@)",@"li"];// [NSPredicate predicateWithFormat:@"name like %@", @"*Ma*"];
    [request setPredicate:pred];
    
    NSError *error;
    NSArray *objects = [self.context executeFetchRequest:request error:&error];
    if(objects == nil)
    {
        NSLog(@"There has a error!");
    }
    else
    {
        NSLog(@"objects:%ld",[objects count]);
        
        for (int index = 0; index < [objects count]; index++)
        {
            NSManagedObject *oneObject = [objects objectAtIndex:index];
            NSString *studentName = [oneObject valueForKey:@"studentName"];
            NSLog(@"studentName:%@",studentName);
        }
    }
}

// 修改数据
- (void)modifyData
{
    // 初始化一个查询请求
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    // 设置要查询的实体
    request.entity = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:self.context];
    // 执行请求
    NSError *error = nil;
    NSArray *objs = [self.context executeFetchRequest:request error:&error]; // 查询结果是数组
    if (error) {
        [NSException raise:@"查询错误" format:@"%@", [error localizedDescription]];
    }
    
    // 遍历数据
    for (NSInteger index = 0; index < [objs count]; index ++)
    {
        NSManagedObject *obj = objs[index];
        if ([[obj valueForKey:@"studentName"] isEqualToString:@"li xiao long"])
        {
            NSLog(@"****find li xiao long");
        }
        [obj setValue:[NSNumber numberWithInteger:index] forKey:@"studentID"];
    }
    
    [self save];
    
    [self searchData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

@end
