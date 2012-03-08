//
//  databaseViewController.m
//  database
//
//  Created by Yue Gu on 12-2-21.
//  Copyright (c) 2012年 Logic Solutions Inc. All rights reserved.
//

#import "databaseViewController.h"
#import "/usr/include/sqlite3.h"

@interface databaseViewController()
{
    NSString *databasePath;
    sqlite3 *contactDB;
}

@property (strong, nonatomic) IBOutlet UITextField *name;
@property (strong, nonatomic) IBOutlet UITextField *address;
@property (strong, nonatomic) IBOutlet UITextField *phone;
@property (strong, nonatomic) IBOutlet UILabel *status;

- (IBAction)saveData;
- (IBAction)findContact;

@end

@implementation databaseViewController

@synthesize name = _name;
@synthesize address = _address;
@synthesize phone = _phone;
@synthesize status = _status;

- (void)saveData
{
    sqlite3_stmt *statement;
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &contactDB) == SQLITE_OK) {
        NSString *insertSQL = [NSString stringWithFormat:@"INSERT INTO CONTACTS (name, address, phone) VALUES (\"%@\", \"%@\", \"%@\")", [[self name] text], [[self address] text], [[self phone] text]];
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(contactDB, insert_stmt, -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE) {
            [[self status] setText:@"Contact Added"];
            [[self name] setText:@""];
            [[self address] setText:@""];
            [[self phone] setText:@""];
        } else {
            [[self status] setText:@"Failed to add contact"];
        }
        sqlite3_finalize(statement);
        sqlite3_close(contactDB);
    }
}

- (void)findContact
{
    const char *dbpath = [databasePath UTF8String];
    sqlite3_stmt *statement;
    if (sqlite3_open(dbpath, &contactDB) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:@"SELECT address, phone FROM contacts WHERE name=\"%@\"", [[self name] text]];
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(contactDB, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                NSString *addressField = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 0)];
                [[self address] setText:addressField];
                NSString *phoneField = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 1)];
                [[self phone] setText:phoneField];
                [[self status] setText:@"Match found"];
            } else {
                [[self status] setText:@"Match not found"];
                [[self address] setText:@""];
                [[self phone] setText:@""];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(contactDB);
    }
}

- (void)viewDidLoad
{
    NSString *docsDir;
    NSArray *dirPaths;
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
    // Build the path to the database file
    databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@"contacts.db"]];
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if ([filemgr fileExistsAtPath:databasePath] == NO) {
        const char *dbpath = [databasePath UTF8String];
        if (sqlite3_open(dbpath, &contactDB) == SQLITE_OK) {
            char *errMsg;
            const char *sql_stmt = "CREATE TABLE IF NOT EXISTS CONTACTS (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT, ADDRESS TEXT, PHONE TEXT)";
            if (sqlite3_exec(contactDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK) {
                [[self status] setText:@"Failed to create table"]; 
            }
            sqlite3_close(contactDB);
        } else {
            [[self status] setText:@"Failed to open/create database"];
        }
    }
    [super viewDidLoad];
}

@end
