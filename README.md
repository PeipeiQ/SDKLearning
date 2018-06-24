# SDKLearning
　　阅读源码的力量

　　在网上能够找到很多关于一些热门库的用法和详细解读，所以也就能很容易并且快速的解读其中的原理。

　　本仓库更专注于这些库中一些ios写法的技巧，以及一些架构思想设计的总结。如果想要从头到位详细了解源码的实现，可以重新查找资料，或者在本仓库的源码中找到
一些关于热门库的注释进行解读。

---
# Masonry

### 一、比较突出的就是链式语法的使用。  
　　其实就是get方法与block的结合。有些人说这种写法不好记住，我们进行一个逆推。要想实现```objc.aProperty```这种语法，就要使用到get方法，
返回一个aProperty的实例。要想实现```someOperate(para)```这种语法，则需要使用block。两者结合一下，定义一个block属性并实现他的get方法，
则可以实现```objc.aProperty(para)```这种形式。而链式编程的做法，比如```objc.aProperty(para).aProperty(para)...```则只需要在block
中return一个自身的实例即可。  
以下通过一个例子举例。
```
typedef NSNumber* (^addBlcok)(int);
//nsnumber扩展
@interface NSNumber (num)
-(addBlcok)add;
@end

@implementation NSNumber (num)
-(addBlcok)add{
    addBlcok addblock = ^(int a){
        return @([self intValue]+a);
    };
    return addblock;
}
@end

//链式语法
NSNumber *num = @(20);
NSNumber *res = num.add(120);   //输出@140
```
#### 一些思考：  
1.什么时候使用链式编程？  
　　从上面的例子还有Masonry可以看出，在面向一些过程化处理的时候（拼接SQL、给View加约束，都可以看成需要一步步完成的过程），需要将
这些“过程”拆分，然后在“组合”这些“过程”的时候，就可以使用链式编程，使得代码更加清晰，增加阅读性。

2.链式编程的核心实现  
　　实现链式编程的关键就是声明一个block的属性，而这个block返回值必须还是一个对象（根据业务需求不同，可以返回的是这个对象实例
本身，也可以是这个类的另一个实例，更可以是另一个类的实例对象）。而block中内部的逻辑就是项目的业务逻辑。

### 二、抽象基类的运用  
　　大部分的OOP语言都有明确一种抽象基类的写法。Object-C中没有明确的抽象基类。于是我们可以采用一些类型判断去帮助我们建立一个抽象基类去使用。
Masonry中MASConstraint是一个很典型的抽象基类，里面声明了许多有关于NSLayoutConstraint的属性，并且声明了一些基类方法，并且不提供实现。我们
进入源码看这一过程。  
在初始化方法中，通过断言，不提供init方法的实现，也就是说无法获得一个MASConstraint类型的实例。
```
- (id)init {
    //抽象基类，不能直接被实例化
	NSAssert(![self isMemberOfClass:[MASConstraint class]], @"MASConstraint is an abstract class, you should not 
  instantiate it directly.");
	return [super init];
}
```
一些自身的实例方法，通过一个宏来拒绝本身实例去实现它的方法。
```
#define MASMethodNotImplemented() \
    @throw [NSException exceptionWithName:NSInternalInconsistencyException \
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)] \
                                 userInfo:nil]
```
```
#pragma mark - Abstract

- (MASConstraint * (^)(CGFloat multiplier))multipliedBy { MASMethodNotImplemented(); }

- (MASConstraint * (^)(CGFloat divider))dividedBy { MASMethodNotImplemented(); }

- (MASConstraint * (^)(MASLayoutPriority priority))priority { MASMethodNotImplemented(); }

- (MASConstraint * (^)(id, NSLayoutRelation))equalToWithRelation { MASMethodNotImplemented(); }

...

- (void)uninstall { MASMethodNotImplemented(); }
```
关于抽象基类和类族，其实在oc的一些系统类中有很好的运用。最常见的可能就是NSArray，NSArray作为一个抽象基类，本身不会去实现一些数组的方法例如
objectAtIndex:等等，它会根据你的初始化的数据而产生不同的实例。
```
NSArray *array0 = [NSArray new];  
NSArray *array = @[@1,@2,@3];  
NSMutableArray *array2 = [[NSMutableArray alloc]init];  
NSMutableArray *array3 = [NSMutableArray arrayWithObjects:@2,@3, nil];  
Class z = object_getClass(array0);    //输出__NSArrayO  
Class a = object_getClass(array);    //输出__NSArrayI  
Class b = object_getClass(array2);    //输出__NSArrayM  
Class c = object_getClass(array3);    //输出__NSArrayM  
```
从而去隐藏一些私有API的实现细节。关于类族的一些讨论，可以移步我的这一篇博客，有更加详细的讨论。
[由objectAtIndex引发的数组越界的思考](https://blog.csdn.net/peipeiq/article/details/80707686)。  

### 三、架构思考
　　关于Masonry的一些方法的组织，这里简要梳理一下。并且贴出一些自己的思考。先看一下总的头文件，这里介绍了各个类的功能。
```
#import "MASUtilities.h"            ->masonry的一些公共的工具类
#import "View+MASAdditions.h"       ->view的类扩展，常用的方法就是定义在这里
#import "View+MASShorthandAdditions.h".   ->Shorthand view additions without the 'mas_' prefixes,
#import "ViewController+MASAdditions.h".  
#import "NSArray+MASAdditions.h"         ->一组views进行约束，没什么特别
#import "NSArray+MASShorthandAdditions.h"   ->同上
#import "MASConstraint.h"                ->Constraint的抽象基类。其子类有MASViewConstraint和MASCompositeConstraint
#import "MASCompositeConstraint.h"       ->包装多个MASViewConstraint实例。（例如size和center）
#import "MASViewAttribute.h"             ->用来包装一个view的功能类，让一个view和NSLayoutAttribute产生关联
#import "MASViewConstraint.h"            ->包装一些用于设置NSLayoutConstraint的属性
#import "MASConstraintMaker.h"           ->顾名思义，用来制造Constraint
#import "MASLayoutConstraint.h"          ->NSLayoutConstraint的子类，仅仅添加了一个mas_key，作为标志属性
#import "NSLayoutConstraint+MASDebugAdditions.h"
```
入口很简单，通过一个类扩展
```
- (NSArray *)mas_makeConstraints:(void(^)(MASConstraintMaker *))block {
    //将view的translatesAutoresizingMaskIntoConstraint关掉
    self.translatesAutoresizingMaskIntoConstraints = NO;
    //初始化一个maker并将view传进去
    MASConstraintMaker *constraintMaker = [[MASConstraintMaker alloc] initWithView:self];
    //通过block去设置constraintMaker。一般一条语句对应一个或者两个MASLayoutConstraint。然后保存在一个可变数组@property (nonatomic, strong) NSMutableArray *constraints;
    block(constraintMaker);
    //取出constraintMaker中的constraints，遍历后根据constraint生成MASLayoutConstraint并添加至每个视图的约束。
    return [constraintMaker install];
}
```
关键方法有两个，block(constraintMaker)和constraintMaker install。  
在block中，我们通常会去设置一些layout的属性，然后保存在一个可变数组中，最终通过install方法去完成约束的添加。  
####简单总结：  
这种链式语法可以避免我们写过多的胶水代码，增强了代码的可读性，其实系统的NSLayoutConstraint确实不友好，导致我们一个view的约束会写出这一串代码：
```
[superview addConstraints:@[

    //view1 constraints
    [NSLayoutConstraint constraintWithItem:view1
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:superview
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                  constant:padding.top],

    [NSLayoutConstraint constraintWithItem:view1
                                 attribute:NSLayoutAttributeLeft
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:superview
                                 attribute:NSLayoutAttributeLeft
                                multiplier:1.0
                                  constant:padding.left],

    [NSLayoutConstraint constraintWithItem:view1
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:superview
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                  constant:-padding.bottom],

    [NSLayoutConstraint constraintWithItem:view1
                                 attribute:NSLayoutAttributeRight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:superview
                                 attribute:NSLayoutAttributeRight
                                multiplier:1
                                  constant:-padding.right],

 ]];
```
其中确实有太多属性我们要一直重复去写，而且attribute的枚举名词过长，导致写起来也十分冗杂，所以链式语法的简介性也就体现出来。其实在使用系统
的NSLayoutConstraints还是极容易出现布局错误导致app崩溃。所以masonry也做了很多边界值处理和防止重复layout的机制。  
其实masonry的源码要封装的系统的方法不多，可以说看了所有代码就发现关键方法也就封装了这里。
```
//使用系统NSLayoutConstraint的方法（相当于二次封装）
    //通过一个for循环，每有一个NSLayoutConstraint就install一次。
    MASLayoutConstraint *layoutConstraint
        = [MASLayoutConstraint constraintWithItem:firstLayoutItem
                                        attribute:firstLayoutAttribute
                                        relatedBy:self.layoutRelation
                                           toItem:secondLayoutItem
                                        attribute:secondLayoutAttribute
                                       multiplier:self.layoutMultiplier
                                         constant:self.layoutConstant];
    
    //MASLayoutConstraint这个类就是为了新增一个属性mas_key,在debug中可以使用到，对具体工程帮助不大。
    layoutConstraint.priority = self.layoutPriority;
    layoutConstraint.mas_key = self.mas_key;
    
    if (self.secondViewAttribute.view) {
        MAS_VIEW *closestCommonSuperview = [self.firstViewAttribute.view mas_closestCommonSuperview:self.secondViewAttribute.view];
        NSAssert(closestCommonSuperview,
                 @"couldn't find a common superview for %@ and %@",
                 self.firstViewAttribute.view, self.secondViewAttribute.view);
        self.installedView = closestCommonSuperview;
    } else if (self.firstViewAttribute.isSizeAttribute) {
        self.installedView = self.firstViewAttribute.view;
    } else {
        self.installedView = self.firstViewAttribute.view.superview;
    }

    MASLayoutConstraint *existingConstraint = nil;
    if (self.updateExisting) {
        existingConstraint = [self layoutConstraintSimilarTo:layoutConstraint];
    }
    if (existingConstraint) {
        // just update the constant
        existingConstraint.constant = layoutConstraint.constant;
        self.layoutConstraint = existingConstraint;
    } else {
        //最终添加约束
        [self.installedView addConstraint:layoutConstraint];
        
        self.layoutConstraint = layoutConstraint;
        [firstLayoutItem.mas_installedConstraints addObject:self];
    }
```
其他上万行代码都是为了这个方法服务的。这也就看出oc代码的一个灵活性。masonry的源码不难看懂，而且代码量比较少，所以还是比较容易了解它的核心。
关键还是要想得懂那些block方法的回调。用block作为返回值，其实就是把一个函数作为返回值，这种做法在js中比较常见，而且js中写法也更加简洁易懂。后面有机会
会写一写这两方面的对比。




