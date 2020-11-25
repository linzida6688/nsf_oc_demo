//
//  ViewController.m
//  nsfoc
//
//  Created by Lindashuai on 2020/9/27.
//  Copyright © 2020 Lindashuai. All rights reserved.
//

#import "ViewController.h"
#import "BaseIdentifyImageManager.h"

@interface ViewController () <UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property(nonatomic, strong) UITextView *testView;
@property(nonatomic, strong) UIButton *btn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.testView];
    [self.view addSubview:self.btn];
}

- (UITextView *)testView {
    if(_testView == nil) {
        _testView = [[UITextView alloc]init];
        _testView.frame = CGRectMake(0, 0, self.view.frame.size.width, 100);
        _testView.center = self.view.center;
        _testView.textColor = [UIColor blackColor];
    }
    return _testView;;
}

- (UIButton *)btn {
    if(_btn == nil) {
        _btn = [[UIButton alloc]initWithFrame:CGRectMake((self.view.frame.size.width - 200) / 2 , self.view.frame.size.height - 300, 200, 200)];
        _btn.backgroundColor = [UIColor redColor];
        [_btn setTitle:@"选择图片" forState:UIControlStateNormal];
        _btn.titleLabel.font = [UIFont systemFontOfSize:18];
        [_btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_btn addTarget:self action:@selector(chooseClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btn;
}

- (void)chooseClick:(UIButton *)sender {
    UIImagePickerController *PickerImage = [[UIImagePickerController alloc]init];
    PickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    PickerImage.allowsEditing = YES;
    PickerImage.delegate = self;
    [self presentViewController:PickerImage animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *newPhoto = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    [self.btn setImage:[newPhoto imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]forState:UIControlStateNormal];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    __weak typeof(self) weakSelf = self;
    [BaseIdentifyImageManager checkImage:newPhoto completBlock:^(BOOL canShow, CGFloat valid) {
        NSLog(@"valid %f", valid);
        weakSelf.testView.text = [NSString stringWithFormat:@"图片指数值 - %f", valid];
    }];
}

@end
