//
//  ClientViewController.m
//  SanKung-Client
//
//  Created by 黄志航 on 16/3/15.
//  Copyright © 2016年 Hunt. All rights reserved.
//

#import "ClientViewController.h"
#import "AsyncSocket.h"

@interface ClientViewController ()<AsyncSocketDelegate>

@property (nonatomic, strong) AsyncSocket *socket;
@property (nonatomic, strong) AsyncSocket *acceptSocket;
@property (nonatomic, weak) UIImageView *coverImage;

@end

@implementation ClientViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self debugSocket];
    UIImageView *coverImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.coverImage = coverImage;
    [self.view addSubview:self.coverImage];
}

- (void)debugSocket
{
    NSError *err = nil;
    if ([self.socket acceptOnPort:6667 error:&err])
    {
        NSLog(@"accept ok.");
    }
    else
    {
        NSLog(@"accept failed.");
    }
    if (err)
    {
        NSLog(@"error: %@",err);
    }
}

- (NSInteger)noRepeatNumberWithArray:(NSArray *)numberArray
{
    NSInteger count = numberArray.count;
    int index = arc4random() % count;
    NSInteger number = [numberArray[index] integerValue];
    return number;
}

- (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // 触摸任意位置
    UITouch *touch = touches.anyObject;
    // 触摸位置在图片上的坐标
    CGPoint cententPoint = [touch locationInView:self.coverImage];
    // 设置清除点的大小
    CGRect  rect = CGRectMake(cententPoint.x, cententPoint.y, 35, 35);
    // 默认是去创建一个透明的视图
    UIGraphicsBeginImageContextWithOptions(self.coverImage.bounds.size, NO, 0);
    // 获取上下文(画板)
    CGContextRef ref = UIGraphicsGetCurrentContext();
    // 把imageView的layer映射到上下文中
    [self.coverImage.layer renderInContext:ref];
    // 清除划过的区域
    CGContextClearRect(ref, rect);
    // 获取图片
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    // 结束图片的画板, (意味着图片在上下文中消失)
    UIGraphicsEndImageContext();
    self.coverImage.image = image;
}

#pragma mark - AsyncSocketDelegate
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"socket:%@, host:%@, port:%u", sock, host, port);
    [_acceptSocket readDataWithTimeout:-1 tag:0];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSLog(@"did disconnect %@", sock);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"结束了" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
    [alert show];
    for (int i = 0; i < 3; i++)
    {
        UIImageView *imageView = (UIImageView *)[self.view viewWithTag:10+i];
        imageView.image = nil;
    }
    _acceptSocket = nil;
}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
    if (!_acceptSocket)
    {
        _acceptSocket = newSocket;
    }
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
//    NSLog(@"data len:%ld", data.length);
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    for (int i = 0; i < 3; i++)
    {
        NSArray *imageArray = [dic objectForKey:@"imageString"];
        UIImageView *imageView = (UIImageView *)[self.view viewWithTag:10+i];
        NSString *imageString = [NSString stringWithFormat:@"%ld.JPG", [self noRepeatNumberWithArray:imageArray]];
        imageView.image = [UIImage imageNamed:imageString];
    }
    self.coverImage.image = [self imageWithColor:[UIColor grayColor] size:[UIScreen mainScreen].bounds.size];
    [_acceptSocket readDataWithTimeout:-1 tag:0];
}


- (AsyncSocket *)socket
{
    if (!_socket)
    {
        _socket = [[AsyncSocket alloc] initWithDelegate:self];
    }
    return _socket;
}

@end
