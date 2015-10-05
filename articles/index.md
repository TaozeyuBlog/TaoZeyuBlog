最近在检查 NextBook 在 Android 设备上运行情况。顺藤摸瓜察觉到 UIKit 底层可能有一些问题。后来勇辉叫我仔细研究一下。以下内容便是这次研究一下的结果。

## 问题背景

起因是我发现 UIApplication 中的这个方法不能正常工作：

```
  - sendAction:(SEL)action to:(id)target 
          from:(id)sender forEvent:(UIEvent *)event
```

在我调用它时，如果 target 参数为 nil，则其行为与文档描述不符。以下是该方法文档的内容节选。

> **Discussion**
> 
> Normally, this method is invoked by a UIControl object that the user has touched. The default implementation dispatches the action method to the given target object or, **if no target is specified, to the first responder**. Subclasses may override this method to perform special dispatching of action messages.

该方法的实现如下 (UIApplication.m:527)：

```
- (BOOL)sendAction:(SEL)action to:(id)target 
              from:(id)sender forEvent:(UIEvent *)event
{
    if (!target) {
        id responder = sender;
        while (responder) {
            if ([responder respondsToSelector:action]) {
                target = responder;
                break;
            } else if ([responder respondsToSelector:@selector(nextResponder)]) {
                responder = [responder nextResponder];
            } else {
                responder = nil;
            }
        }
    }
    
    if (target) {
        [target performSelector:action withObject:sender withObject:event];
        return YES;
    } else {
        return NO;
    }

```

显而易见的是这里 ```id responder = sender;```实际上，从文档上来看，target 为 nil 时，应该指向 first responder ，而和 sender 没有任何关系。

这个方法的实现来源于开源项目，实际上我认为，这段代码的作者是被某个错误的思路误导了，才写下这段代码。此外，经我检查，在 UIKIt 的其他地方，依然还有在这种错误思路指导下写出的代码。这些地方之后我会一一列出。

## 开源项目作者的思路

在 UIApplication.m:530 可以看到作者留下的一段注释，解释了他为什么不按文档来写。我截取了其中一部分。

> My confusion comes from the fact that motion events and keyboard events are supposed to start with the first responder - but what is that if none was ever set? Apparently the answer is, if none were set, the message doesn't get delivered.

作者的困惑在于，他认为一定要手动调用``becomeFirstResponder``才能把某个 UIResponder 变成 first responder。

显而易见的是，我们写 iOS 应用的时候，并没有在代码里到处调用``becomeFirstResponder``方法。因此，作者认为大部分时候，first responder 不存在。因此``sendAction:to:from:forEvent:``发出的事件（或回调）绝大部分时候不会被处理，这与常理不符，因此令作者感到困惑。

作者提出了自己的理解（我认为是错误的理解）。

> It seems that the reality of message delivery to "first responder" is that it depends a bit on the source. If the source is an external event like motion or keyboard, then there has to have been an explicitly set first responder (by way of becomeFirstResponder) in order for those events to even get delivered at all. If there is no responder defined, the action is simply never sent and thus never received.

> This is entirely independent of what "first responder" means in the context of a UIControl. Instead, for a UIControl, the first responder is the first UIResponder (including the UIControl itself) that responds to the action. It starts with the UIControl (sender) and not with whatever UIResponder may have been set with becomeFirstResponder.

总而言之，作者认为，有两种 first responder，苹果文档都把它们叫做 first。

1. 必须明确调用 UIResponder 的 ``becomeFirstResponder``的 first responder。当苹果碰到键盘事件和手势事件时，必须发给这种 first responder 处理。
2. 对于 UIControl 而言，first responder 是指 UIControl 自己。

此处作者多虑了，作者所言的第二种 first responder 并不存在。苹果的文档也没有表明或暗示有第二种 first responder 存在。

## 不存在第二种 first responder

可以通过一段代码证明：

```
- (void)viewDidAppear:(BOOL)animated
{
    _TNView *view0 = [_TNView new];
    _TNView *view1 = [_TNView new];
    _TNView *view2 = [_TNView new];
    
    view0.name = @"view0";
    view1.name = @"view1";
    view2.name = @"view2";
    
    [self.view addSubview:view0];
    [self.view addSubview:view1];
    [self.view.window addSubview:view2];
    
    NSLog(@"viewController is first responder %i", self.isFirstResponder);
    
    [[UIApplication sharedApplication] sendAction:@selector(callbackMethod:) to:nil from:self forEvent:nil];
    
    NSLog(@"view0 become first responder");
    [view0 becomeFirstResponder];
    [[UIApplication sharedApplication] sendAction:@selector(callbackMethod:) to:nil from:self forEvent:nil];
    
    NSLog(@"view1 become first responder");
    [view1 becomeFirstResponder];
    [[UIApplication sharedApplication] sendAction:@selector(callbackMethod:) to:nil from:self forEvent:nil];
    
    NSLog(@"view2 become first responder");
    [view2 becomeFirstResponder];
    [[UIApplication sharedApplication] sendAction:@selector(callbackMethod:) to:nil from:self forEvent:nil];
    
    NSLog(@"viewController become first responder");
    [self becomeFirstResponder];
    [[UIApplication sharedApplication] sendAction:@selector(callbackMethod:) to:nil from:self forEvent:nil];
}
```

```
@implementation _TNView

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)callbackMethod:(id)sender
{
    NSLog(@"callback at %@", _name);
}

@end
```

这段代码在 iOS 上执行的结果如下：

```
viewController is first responder 1
callback at viewController.
view0 become first responder
callback at view0
view1 become first responder
callback at view1
view2 become first responder
callback at view2
viewController become first responder
callback at viewController.
```

由结果可以看到，谁是 first responder 就调用谁，和 ``sendAction:to:from:forEvent:``的 sender 参数没有任何关系。

特别是 view2，甚至不在 sender 的 Responder Chain 路线上，但是只要它是 first responder 就可以被顺利调用。

同样的代码，如果在 Android 设备上运行，则结果如下：

```
viewController is first responder 0
callback at viewController.
view0 become first responder
callback at viewController.
view1 become first responder
callback at viewController.
view2 become first responder
callback at viewController.
viewController become first responder
callback at viewController.
```

相对于 iOS，这个方法调错了对象。

**结论：``sendAction:to:from:forEvent:`` 的行为和苹果的官方文档描述的全一致，并不存在第二种 first responder。**

## 更多被隐藏的问题

开源项目的作者之所以会困惑，在于他无法理解 UIKit 如何处理 first responder 不存在的情况。显然，除非手动调用 ``becomeFirstResponder``，否则哪里会有 frist responder 呢？可见，``sendAction:to:from:forEvent:``应该经常找不到对象才对，但实际情况并非如此，在 iOS 下调用这个方法，它总能找到合适的对象。

我个人猜测，作者也许不知道 iOS 会偷偷把 UIViewController 设置成 first responder。证据就是，通过全文检索，目前的 UIKit 项目中，除了 UITextField 之外，没有任何地方有主动调用 ``becomeFirstResponder``。

不过为了消除任何一点可能存在的疑问，我决定再做一个实验。

```

@interface _TNViewController3 : UIViewController
@property (nonatomic, strong) UIViewController *parent;
@end

@implementation TNIssue4
{
    BOOL _hasShowed;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    _TNViewController3 *viewController = [_TNViewController3 new];
    viewController.parent = self;
    
    NSLog(@"--------");
    NSLog(@"parent is first responder %i", self.isFirstResponder);
    NSLog(@"child is first responder %i", viewController.isFirstResponder);
    
    if (!_hasShowed) {
        _hasShowed = YES;
        NSLog(@"navigation push");
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

@end

@implementation _TNViewController3

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"parent is first responder %i", self.parent.isFirstResponder);
    NSLog(@"child is first responder %i", self.isFirstResponder);
    [self.navigationController popViewControllerAnimated:YES];
    NSLog(@"navigation pop");
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"parent is first responder %i", self.parent.isFirstResponder);
    NSLog(@"child is first responder %i", self.isFirstResponder);
}

@end
```

这段代码在 iOS 设备上运行结果如下：

```
--------
parent is first responder 1
child is first responder 0
navigation push
parent is first responder 0
child is first responder 1
navigation pop
parent is first responder 1
child is first responder 0
--------
parent is first responder 1
child is first responder 0
```

这段代码说明，UINavigationController 会在每次调用完``pushViewController:`` 和``popViewController`` 之后，自动将 topViewController 设置成 first responder。

以上实验虽然仅限于 UINavigationController 的行为，但 UIKit 中其他组件肯定也有类似行为。只不过在实践中，由于 UIViewController 的 ``canBecomeFirstResponder`` 默认返回 NO，因此一般情况下，你不会看到某个 viewController 变成了 first responder。

此外，另一个问题就在于 UIView 被调用 ``becomeFirstResponder``后，会有一些特殊的行为（只有 UIView 以及其派生类有）。

我们知道 UIResponder 必须处于 Responder Chain 上，才能变成 first responder。因此，倘若你调用一个没有被派生的 UIResponder 对象的 ``becomeFirstResponder`` 是毫无疑义的，因为单纯的 UIResponder 不会处于某一条 Responder Chain 上。

而对于 UIView，倘若它是某个 UIWindow 对象的子孙节点，则它是可以被设置成 first responder（自然，它的 ``canBecomeFirstResponder``必须返回 YES）。

如果 UIView 不是任何一个 UIWindow 对象的子孙节点，那么调用 ``becomeFirstResponder`` 会返回 NO。但此时 UIView 会处于一种状态，一旦它有机会变成某个 UIWindow 对象的子孙节点，它会自动变成 first responder。

这个行为可以用以下实验展示出来：

```
    UIView *view0 = [_TNView new];
    BOOL result;
    
    result = [view0 becomeFirstResponder];
    NSLog(@"set first responder for view0 - %i", result);
    NSLog(@"is first responder %d for view0", view0.isFirstResponder);
    
    [self.view addSubview:view0];
    
    NSLog(@"add view0 to window.");
    NSLog(@"is first responder %d for view0", view0.isFirstResponder);
    
    NSLog(@"remove view0 from window");
    [view0 removeFromSuperview];
    NSLog(@"is first responder %d for view0", view0.isFirstResponder);
    
    NSLog(@"add view0 back to window.");
    [self.view addSubview:view0];
    NSLog(@"is first responder %d for view0", view0.isFirstResponder);
```

在 iOS 设备中运行的结果如下：

```
set first responder for view0 - 0
is first responder 0 for view0
add view0 to window.
is first responder 1 for view0
remove view0 from window
is first responder 0 for view0
add view0 back to window.
is first responder 0 for view0
```

在 Android 设备中运行结果如下：

```
set first responder for view0 - 0
is first responder 0 for view0
add view0 to window.
is first responder 0 for view0
remove view0 from window
is first responder 0 for view0
add view0 back to window.
is first responder 0 for view0
```

可以看到这种区别。