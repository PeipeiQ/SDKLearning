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








