---
layout: blog
published: true
---

因为想要做一个可以发表格式化文章的网站，所以我需要一个网页版的所见即所得的文本编辑器。而KindEditor就是这么一个开源的文本编辑器。

这篇文章也是我大概接触了KindEditor并用它做了一点点东西后总结出来的一点心得，当然，想要全面的介绍，或详细的文档，还是要去官方吧，[kindeditor.net](http://kindeditor.net/)。因为是国产软件（应该是国产的吧？），所以官网是中文的，蛮好的。 

貌似Google一下KindEditor，则可以找到各种语言的安装方法，Java也好PHP也好很多的。所以我不想介绍特定语言的安装方法，因为我觉得KindEditor只是个前端的文本编辑器，为什么要和后台所用的语言扯上关系呢？例如Java语言的安装会告诉你把这几个jar包装好，你要不用Java，这种安装方法毫无意义。比如我做KindEditor的时候用的就是Ruby on Rails，翻了翻好像没有特别针对Ruby on Rails的安装方法。

于是就写一个通用安装方法吧，只要是Web项目都可以这么搞。

KindEditor的编辑区是以一个textarea为原型，因此，最后变成html应该大概是个这样子。 

```
<textarea id="editor_id" name="content" style="width:700px;height:300px;">
   内容
</textarea>
```


至于内容，则是一开是打开这个网页所看到的初始内容，内容支持格式化。如果什么也没有就留空好了。如果要设置内容的话，JSP的话大概写个EL表达式，Rails的erb文件的话，写`<%= XXX %>`之类的就可以了。

之后，就要把这个textarea变成KindEditor演示页面中那个样子了。

首先，你应该下载KindEditor，从官网上下载。下载完应该是一个zip包什么的，解压缩出来以后在你的Web项目中自己找一个喜欢的路径解压缩。但是官方会告诉你如果你是Java应该如何如何，你是PHP应该如何如何。别理这个，你要用个Ruby on Rails 什么的他也没告诉怎么安装难道你就不能安装了啊？反正看看zip包里这些文件夹里有些什么吧。如果是js文件或css文件肯定是必要的。如果叫做Java或PHP你就删了吧。

反正把KindEditor安装在用户可以访问到的地址就行了。例如Java的话就是WebRoot，我用Rails就是public目录。 

之后，在你的文本编辑器出现的页面里加上：

```
<script>
        KindEditor.ready(function(K) {
                window.editor = K.create('#editor_id');
        });
</script>
```

其中#editor_id是你定义的textarea的ID。

你要觉得把JS直接写网页了不好的话写js文件里也一样，一个意思就行。哦对了，记得这两行脚本一定也要添加上去（添加到之前的script标签前面）。

```
<script charset="utf-8" src="/editor/kindeditor.js"></script>
<script charset="utf-8" src="/editor/lang/zh_CN.js"></script>
```

其中src根据具体项目而顶，反正能指向这两个js文件就行了。

之后打开你的网页，如果一切顺利的话，就能看到官方演示页面里那个东西了。你在编辑器内输入文本，可以编辑字号什么的，还可以设置字体，还可以排版。

好了，如何将编辑器里的内容提交到服务器呢？其实整个KindEditor编辑器就是一个textarea变来的，你直接按照提交textarea的方式就可以了。

只不过有一点一定要注意，在提交到服务器前要将textarea的内容同步。

要调用`editor.sync()`;就ok了。其中editor就是你的那个textarea，用jquery取id就可以取到该变量了。虽然我不调用貌似也能正常提交，但是官方文档说一定要同步，所以记得一定要调用该方法再提交。