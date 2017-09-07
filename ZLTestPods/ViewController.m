//
//  ViewController.m
//  ZLTestPods
//
//  Created by long on 2017/9/4.
//  Copyright © 2017年 long. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"baoman" withExtension:@"png"];
    
    UIImage *image = [UIImage imageNamed:@"baoman"];
    
    NSLog(@"%@, %@", url, image);
    
    [self.imageView setImage:image];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
