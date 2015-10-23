---
node : technology
title: KindEditor上传图片
---

通过之前的文章《KindEditor的安装和使用》的介绍，我们已经可以令我们的网页上出现一个KindEditor在线文本编辑器。我们可以直接使用它，在里面添加文字，编辑其格式，排版什么的。完了，我们还可以把内容提交到服务器（用于发表文章，编辑文章等，这就看具体业务需求了）。

好了，但是仅仅做到这一步，你会发现如果试图上传图片，只会弹出一个404错误窗口。（如果你没有得到错误窗口，你一定不是按照我在《KindEditor的安装和使用》中介绍的方法安装的，那么你也许不必继续看了，因为按照特定语言的安装方法安装的话，应该一切都搞定了才对。）

那么我们就来做一个上传功能吧。首先，后台服务器应该为前台提供一个接口，接收上传的图片，然后把它保存在服务器的文件系统内（或存储在数据库中，或其他，具体如何做由你自己决定），然后，将能访问到该图片的url返回给前台。

后台具体如何实现，取决于你用什么语言，用什么技术。我大概演示下用Ruby on Rails如何实现后台。</p>

```
# app/controller/image_upload_controller.rb
class ImageUploadController < ApplicationController
  def upload
    _upload = params[:imgFile]
    _name = create_image_name
    _path = File.join(Directory, _name)
    File.open(_path, "wb") do |f|
      f.write(_upload.read)
    end
    render :json => {
      :error => 0,
      :url => "/upload/images/#{_name}"
    }.to_json
    puts _path
    puts "#{Directory}#{_name}"
  end
  
  private
  
  TimeFormat = '%Y%m%d%H%M%a'
  Directory = 'public/upload/images/'
  
  def create_image_name
    "IMG#{Time.now.strftime(TimeFormat)}#{rand(0..9999)}.jpg"
  end
  
end
```

处理细节上，我的后台是直接将上传的图片保存在public/upload/images/文件夹里面，在Ruby on Rails中，public下的资源浏览器可以直接访问。假如图片在服务器中的地址是 public/upload/images/IMG.jpg，则用户直接在浏览器中输入'http://www.XXX.com/upload/images/IMG.jpg'就可以访问到该图片。

你当然可以把图片保存在数据库，但是只要能提供图片的url地址就行。不同的语言后台实现不一，但是只要注意两点就行了。

- 向前端提供一个用于上传图片的url接口。KindEditor会用POST方法访问该url从而把图片上传给服务器。
- 在处理完上传的图片后（保存在本地，或存储在数据库），返回一个json给客户端。这个json最重要的信息是，成功上传图片的url地址。

根据官方文档，这个json的格式应该是这样的：

```
//成功时
{
        "error" : 0,
        "url" : "http://www.example.com/upload/images/IMG.jpg"
}
//失败时
{
        "error" : 1,
        "message" : "错误信息"
}
```

在编写了后台接收图片上传的url后，要将这个url告诉KindEditor。在配置KindEditor的时候，应该有说必须加上这么一些js脚本。

```
<script>
        KindEditor.ready(function(K) {
                window.editor = K.create('#editor_id');
        });
</script>
```

现在，将其改为：

```
<script>
        KindEditor.ready(function(K) {
                window.editor = ('#editor-id', {
                       uploadJson : '/image_upload/upload'
                });
        });
</script>
```

我这么改了以后，等于是为KindEditor的初始化配置了一个参数。即uploadJson，这个参数说明当KindEditor要上传图片的时候，它应该访问哪个url接口。这种初始化参数还有很多。详情可以查看[官方文档](http://kindeditor.net/docs/option.html)。鉴于本篇只讨论上传图片，其他参数就不罗嗦了。

哦，还有，本文的代码仅供参考，直接复制粘贴肯定不能运行的。如果非要复制粘贴，请将代码中的特定部分改为你的项目中的内容。）

之后，如果使用KindEditor的上传图片功能，在一段时间的等待后，你将看到上传的图片出现在编辑区内。这就代表成功了。

如果上传图片成功（没有出现错误信息），但是图片却在编辑区内无法显示，那么就检查一下json返回的那个图片url信息是否正确吧。试图将它输入到浏览器中，试试浏览器能否访问到该图片。总之，要让那个url是有效的。

哦，写到这里我突然想起来了一个东西，就是错误信息。官方文档说uploadJson参数的url应该返回一个json，但是，如果我偏不返回json，而是返回一个`Content-Type=text/html`的页面，那么KindEditor将视为图片上传失败的错误，并将这个页面以弹出对话框的形式显示出来。（我只试过4.1，其他版本是否如此没试过。）

因此如果你不想让图片上传失败后仅仅显示文字的话，返回一个漂亮点的页面提醒图片上传失败了，也是可以的。KindEditor会把它显示出来。

# 附录：上传图片时发生CSRF校验错误

不同的语言和技术，这个错误信息的描述可能不一样。但是，看到这条错误信息，你大概就知道是怎么回事了。如果你使用Ruby on Rails开发后台，那么默认情况下对于浏览器提交的POST方法，都会进行CSRF校验。（实际上Rails还会对PUT，DELETE方法校验，但这就扯远了，和本主题无关了。）

为什么要校验，请参考[《CSRF攻击的应对之道》](http://www.ibm.com/developerworks/cn/web/1102_niugang_csrf/)。如果你对CSRF攻击不感兴趣，只想知道如何令你的图片可以通过验证成功上传，也没关系。

遗憾的是，KindEditor似乎没有提供CSRF验证的支持（这点尚未考证，我接触KindEditor不久，如有勿请告诉我），因此，如果你的后台程序要求CSRF验证，那么，KindEditor的图片肯定不能上传成功。

因此，最简单的解决方法，就是关掉CSRF验证。关掉整个服务器的CSRF验证肯定是把玩笑开大了，那么你可以只关掉上传图片的url的验证。

但这么一来，就算是阿猫阿狗都能通过你的url向你的服务器疯狂上传图片了。所以，手动写一段过滤程序吧。例如必须是登录用户且有上传图片权限的用户才能上传图片，否则直接返回error。

但是，你可能会说，我一定要验证，不验证不行！那么，就去改KindEditor的源代码吧。怎么改网上貌似还是有很多，但是大家改法不一。我也把我改的东西贴出来，这样也多一个参考。

CSRF的验证有很多种，一定要知道自己的后台如何验证才能开始动手改。例如我是用的Ruby on Rails，它会在html页面的head中加入如下信息。

```
<meta name="csrf-param" content="authenticity_token"/>
<meta name="csrf-token" content="eNaG5Hp25pctFmtko9LEvXWtbnBXnN8wxzzlcpMeupc="/>
```

如果在POST提交的时候加一个字段 `'authenticity_token' =>'eNaG5Hp25pctFmtko9LEvXWtbnBXnN8wxzzlcpMeupc='`，那么验证就会通过，至少Rails是如此。但是，这个csrf-token不是一个固定值，因此每次提交图片的时候必须动态的从head里取才行。

因此，我们要通过修改KindEditor的源代码，令它在上传图片的时候，把authenticity_token字段带上。

首先，找到kindeditor.js文件，然后找到大约4100行前后的范围（我的版本是4.1.x具体忘了），算了，我不写怎么找了，反正也不好找。我直接贴出我是怎么改的，如果你要想跟着改的话，直接ctrl+F找到附近位置就好了。

```
var hiddenElements = [];
for(var k in extraParams){
	hiddenElements.push('<input type="hidden" name="' + k + '" value="' + extraParams[k] + '" />');
}
//MOsky inserts this code.
var csrfParam = $("meta[name='csrf-param']").attr("content");
var csrfToken = $("meta[name='csrf-token']").attr("content");
//End insert
var html = [
	'<div class="ke-inline-block ' + cls + '">',
	(options.target ? '' : '<iframe name="' + target + '" style="display:none;"></iframe>'),
	(options.form ? '<div class="ke-upload-area">' : '<form class="ke-upload-area ke-form" method="post" enctype="multipart/form-data" target="' + target + '" action="' + url + '">'),
	'<span class="ke-button-common">',
	hiddenElements.join(''),
	//MOsky inserts this code.
	'<input type="hidden" name="', csrfParam, '" value="', csrfToken, '"/>',
	//End insert
	'<input type="button" class="ke-button-common ke-button" value="' + title + '" />',
	'</span>',
	'<input type="file" class="ke-upload-file" name="' + fieldName + '" tabindex="-1" />',
	(options.form ? '</div>' : '</form>'),
	'</div>'].join('');
var div = K(html, button.doc);
```

原理就是我直接从html文件的head中将这两个标签中的值取出来。

然后在提交图片的时候，生成一个input，将其name设置成authenticity_token，value设置成取的token值。然后一起提交上去了。
