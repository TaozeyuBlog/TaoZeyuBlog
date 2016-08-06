---
layout: blog
published: true
---

#引言
本人学习Node.js已有两周了，有点心得，写成文章，一方面便于今后自己查阅，另一方面巩固自己所学。如有错误，请诸位赏脸批评指教。

Node.js给我的第一印象就是，它的I/O操作是非阻塞的。非阻塞I/O带来了性能上的优势。与Java的阻塞式I/O操作做对比，Java程序需要从网络下载资源的时候，阻塞线程，当查询数据库的时候，阻塞线程，当读取文件的时候，阻塞线程。诸如此类的来自I/O的阻塞将浪费不少CPU的时间。如果心疼这些浪费的时间，那好，你就多开几个线程或进程。但这又引入了线程之间切换的代价。

Node.js使用事件驱动机制，当涉及I/O操作时，代码异步执行。这样带来的另一个好处就是，不需要考虑麻烦的<b>线程安全</b>问题，因为到Node.js即便是单线程，也不会因为I/O阻塞而出现性能瓶颈。同样和Java做比较。Java因为性能问题而开多线程，因为开多线程而需要考虑线程安全问题。Node.js可不这样。君不知曾有人在多线程的情况下使用HashMap类而导致服务器崩溃，虽然这只能算自作自受（因为HashMap的API上明确告诉你HashMap是非线程安全的），但如果语言本身就令程序员无需担心线程安全问题，那么这种情况就不会因为程序员的粗心而发生了。

但非阻塞I/O操作也有令人不爽的地方，进行I/O操作的时候，只能**异步调用**。

#异步调用的缺点

异步调用依赖回调函数，而回调函数的缺点更加显而易见。那就是代码难写，写出来以后可维护性差。如果不有意识地避免，很可能写出这种东西：

```
function add(x1, x2, callback) {
    callback(x1 + x2);
}

(function(){
    var a = 1;
    add(a, 1, function(res) {
        var a = res;
        add(a, 2, function(res) {
            var a = res;
            add(a, 3, function(res) {
                var a = res;
                add(a, 4, function(res) {
                    console.log(res);
                });
            });
        });
    });
})();
```

这种回调函数中嵌套回调函数的方法写起来麻烦，别人要读你的代码更加不知所云。因此，也许可以把流程拆解成若干函数，在异步调用时，将函数名作为回调函数参数传进去。

```
step0();

function step0() {
    var a = 1;
    add(a, 1, step2);
};

function step1(res) {
    var a = res;
    add(a, 2, step2);
}

function step2(res) {
    var a = res;
    add(a, 3, step2);
}

function step3(res) {
    var a = res;
    add(a, 2, step4);
}

function step4(res) {
    console.log(res);
}
```

这样看起来似乎好多了，代码从上到下，就是流程中的一个又一个步骤。不过还是有一点不好，你要为每一个步骤取一个名字，而这些名字仅仅是为了写回调函数参数时可以有所指代罢了。

如果不想为每一个步骤命个没太大意义的名，可以试试Promise方法：

```
new Promise(function(resolve, reject) {
    var a = 1;
    add(a, 1, resolve);
}).then(function(res){
    return new Promise(function(resolve, reject){
        var a = res;
        add(a, 2, resovle);
    });
}).then(function(res){
    console.log(res);
});
```

这样就既避免了嵌套，又省去为函数命名的苦恼。但是依然有问题：

1. 流程被分割了，确切的说，流程并非依照逻辑的相关程度，而仅仅按照是否有异步操作而被分割成不同部分。
2. 后面的匿名函数无法直接引用之前匿名函数中的变量。

想象一下，有这么一个过程，它需要查询n次数据库，每次都会根据查询的结果进行不同的操作，在此过程中它需要维护一组变量，随时需要读和修改这组变量的值。如果是阻塞式I/O，同步调用，那么直接将此过程写成一个函数，需要维护的变量就写成一组局部变量好了。写起来简单，阅读起来一目了然。但如果I/O是非阻塞式的，调用是异步的，那么不论怎么写，都不能和同步代码那样简单明了。

如果Node.js也能写出同步代码就好了，哪怕是看起来像同步代码也好。是的，这篇文章的目的，就是探讨如何用Node.js写出看起来像同步调用的代码，我称之为**伪同步代码**。

#ECMAScript 6 的新特性

目前V8引擎已经支持ECMAScript 6的<b>部分</b>特性，比如我即将介绍的generator。如果想使用这些特性，请至少使用Node.js 0.11及以上版本，并且在运行node的时候加上--harmony参数。

如果你不了解generator，强烈建议你先看看[JavaScript标准参考教程(alpha)》3.7部分](http://javascript.ruanyifeng.com/advanced/ecmascript6.html#toc9)。我将假定你已经阅读过该部分了。

如何理解generator，我们可以把它理解成一种代码的<b>等效替换</b>。例如有如下一段代码。

```
function g(name, age) {
    var flow = [
        function(){
            console.log("Name:"+name);
            return name;
        },
        function(){
            console.log("Age:"+age);
            return age;
        },
        function(){
            console.log(age > 18 ? "old" : "young");
        },
    ];
    var index = 0;
    var next = function(){
        if(index >= flow.length) { throw "error";}
        var fun = flow[index];
        index++;
        return {
            done : index >= flow.length,
            value : fun.apply(null, arguments),
        }
    }
    return {next : next};
}
```

可以用等效的generator代替。

```
function* g(name, age) {
    console.log("Name:"+name);
    yield name;
    console.log("Age:"+age);
    yield age;
    console.log(age > 18 ? "old" : "young");
}
```

第二段代码，和第一段代码的效果是完全一样的。显然第二段代码更易阅读，也更好写。

此外，对于generator又有另一种理解方式。在generator中使用yield关键字，可以让程序流执行至此时被中断，此时现场被保护起来，直到下次调用next()的时候，现场还能恢复，程序流从之前中断的地方继续执行。

#写出伪同步代码

利用generator，我们可以写出看起来很像同步代码，但却是<b>异步执行</b>的代码。

```
var http = require('http');

var options = [
    {
        host : 'www.baidu.com',
        port : 80,
        page : '/'
    },
    {
        host : 'www.google.com',
        port : 80,
        page : '/'
    },
    {
        host : 'taozeyu.com',
        port : 80,
        page : '/'
    },
];

function* printStatusCode() {
    for(var i=0; i<options.length; ++i) {
        var res = yield http.get(options, function(res){g.next(res); });
        console.log(res.statusCode);
    }
};

var g = printStatusCode();
g.next();
```

这段小程序按顺序先后访问www.baidu.com、www.google.com、taozeyu.com这三个网站，然后分别打印出服务器返回的statusCode。其中`http.get()`函数一定是异步执行的，但是程序视觉上却有些同步执行的感觉。

但是，仅仅使用generator并不能在所有情况下都能写出伪同步代码。例如，如果有两个函数A，B。其中A必须调用B。且A与B中都有多个地方需要执行异步操作。这种情况下仅用generator就写不出来（或写不好）。此时，我们需要再做一层封装。

作为实验，我写了一个叫做dollar的库，可以去<a href="https://github.com/taozeyu/dollar">github.com/taozeyu/dollar</a>查看源代码。我将演示下用dollar库如何写出伪同步代码。在下集中，我将讲下dollar库的思路。

```
var http = require('http');
var D = require('dollar');

var get$ = D.async(http, http.get);

D.start(function* (){
    console.log("ready to load...");
    var options = {
        host : 'www.douban.com',
        port : 80,
        page : '/good-good-study-day-day-up'
    };
    var res = yield get$(options);
    if(res.statusCode == 200) {
        console.log("success");
    } else {
        console.log("fail : "+res.statusCode);
    }
    console.log("complite");
});
```

使用dollar库时，建议使用大写的D来表示，因为D可能写在代码的各个地方，如果用某个较长的词代替，这个词可能填充得到处都是。

```
var D = require('dollar');
```

使用D.async()包装某个只能异步调用的函数，使之变成同步函数。

```
var get$ = D.async(http, http.get);
```

这样，我们就将http.get这个异步函数，包装成了一个名为get$的同步函数。建议将包装后的函数名字结尾加上$符，这样一眼就可以看出哪个函数是包装过的。

当我们想要调用get$()函数时，在之前加上yield关键字，且保证调用在`D.start(function* (){...})`之中即可。

```
var res = yield get$(options);
```

如此一来，我们就写出了看起来像同步执行的实际却是异步执行的**伪同步**代码。写代码时，只要记得一看见名字以$结尾的函数，调用时就在它前面加上一个yield关键字，那么写代码来就和同步无异。

现在考虑之前说的那种情况，有两个函数A，B。其中A必须调用B。且A与B中都有多个地方需要执行异步操作。此时，我们只需把B函数包装一下即可。

```
var http = require('http');
var D = require('dollar');

var get$ = D.async(http, http.get);

var getStateCode$ = D(function* (host){
    var options = {
        host : host,
        port : 80,
        page : '/good-good-study-day-day-up'
    };
    var res = yield get$(options);
    console.log("get code:"+res.statusCode);
    return res.statusCode;
});

D.start(function* (){
    console.log("ready to load...");
    console.log("status code :"+(yield getStateCode$("www.baidu.com")));
    console.log("status code :"+(yield getStateCode$("www.douban.com")));
    console.log("status code :"+(yield getStateCode$("taozeyu.com")));
    console.log("done");
});
```

请注意这种用法，同包装http.get这种函数一样，包装过的函数命名时也建议在末尾加上$符，因为调用这种函数也必须在之前加yield关键字。

```
var getStateCode$ = D(function* (...){...});
```

OK，至此，我们似乎得到了一个可以将Node.js在各种情况下都能写出同步代码的方案，真是如此吗？不是的，还有异常处理呢。这部分我留在再下一篇文章中再写吧。
