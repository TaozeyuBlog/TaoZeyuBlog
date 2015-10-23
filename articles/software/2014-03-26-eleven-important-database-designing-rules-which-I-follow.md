---
node : technology
translation : true
author: ShivprasadKoirala
source : http://www.codeproject.com/Articles/359654/
title : 微软工程师建议的11条数据库设计准则
---

# 简介

作者：Shivprasad koirala</p>

前微软ASP/ASP.NET的MVC工程师，现在印度当CEO。如果你认为本文有些地方翻译不准确，可以去[知言译义网对应的贴子](http://115.29.175.42/post/8)参与本贴的翻译。

# 引言

在你开始读这篇文章之前，我可要事先声明，我可不是什么数据库设计方面的大师什么的。这11条设计准则，都是我从实际项目中，从经验中，从阅读和学习之中总结而来的。我个人认为，如我来设计数据库，遵循这11条准则，会让我受益良多。请多指教。

我之所以要写这么一篇详尽的文章，那是因为，我发现很多developer对“三范式”笃信不疑，而不顾自己的实际情况如何。他们认为，“三范式”就是数据库设计的唯一选项！随着项目进度不断推进，这些抱着这种观点的人，终归会碰壁的。

如果你对于“范式”没什么印象，可以点击[这里](http://www.youtube.com/watch?v=wp0N1tYjEWc&feature=youtu.be&hd=1)。这篇视频教程手把手地教你“三范式”是怎么一回事。

**译者注：**
视频教程贴在youtube，如果不翻墙可能看不到。如果不想翻墙，或者不想听英语，可以谷歌“数据库范式”。

说到底，“范式”是非常重要的准则，但是，奉为圭臬，则总归要吃亏。因此，我将列出我所认为数据库设计最重要的11条准则。

# 准则一：应用的类型是什么？是OLTP还是OLAP？

当你开始设计数据库的时候，第一件事，就是分析，你设计的数据库，是为那种类型的数据库提供服务的。具体来说，到底是**事务型**（Transactional）还是**分析型**（Analytical）。你可以发现，很多developer根本就不管自己的应用到底是那种类型，就直接按照“范式”的规定设计，最终，碰上了各种各样的性能、用户化问题。正如所说，有两种应用类型：基于事务的、基于分析的。让我来简单地介绍下这两种类型。

- **事务型：**
这种类型的应用程序，最终用户更专注增删查改操作。这种类型叫做**OLTP**。
- **分析型：**
这种类型的应用程序，最终用户更专注于对数据库存储的数据进行分析，并生成报告和进行预测。这时，数据库很少需要执行insert和remove操作。设计的主要目的，在于以最快的速度从数据库取数据，并进行分析。这种类型叫做**OLAP**。

![](/public/upload/images/important-database-designing-rules-which-I-follow-001.jpg)

换句话说，如果你发现，增删改操作更加突出，那么你应该遵循传统的“范式”来设计。否则，你就建立一个扁平化非规范数据库结构吧。

下图表示name和adress的关系结构。左边是遵循范式的设计方案，右边是不遵循范式的扁平化设计方案。

![](/public/upload/images/important-database-designing-rules-which-I-follow-002.jpg)

# 准则二：将数据拆分成逻辑片段，生活本该更简单。

这条准则，实际上就是“第一范式”。如果你违反这条准则，一个显而易见的特征就是，你的查询中会用到很多字符串解析函数，像substring、charindex等等。如果不幸出现了这些特征，请尽量遵循这条准则吧。

举个例子，如下图。表中包含 Student Name 字段。如果你想在该表中查询包含“Koirala”，但是不包含“Harisingh”的内容，你会怎么做呢？（很纠结吧）

所以，如果你把 Student Name 按逻辑进一步拆分，这显然要好一些。这样，写出的查询语句也就更简洁、更优雅。

![](/public/upload/images/important-database-designing-rules-which-I-follow-003.jpg)

# 准则三：上一条准则别玩过头了

developer们是一种可爱的生物。如果你告诉他们一种方法，他们就老是用这种方法。好吧，其实准则二如果玩过头了，也会导致一些你不想要的结果。因此，当你产生“拆了这玩意吧”的想法的时候，赶紧暂停，然后问自己一个问题：“有必要吗？”。正如之前所说，拆解必须是符合逻辑的。（译者：即业务逻辑上有简化的需求，你才去拆分。如果业务逻辑没需求，你也拆分就是过度设计。）

如图，请看 Phone Number 字段。一般来说，号码就是号码，很少有业务需要对号码的 ISD（译者注：ISD - 国际订户拨号）进行管理。把号码留着不拆解显然是明智之举，你要真把号码拆解成图中那样，恐怕会产生很多麻烦的后遗症。

![](/public/upload/images/important-database-designing-rules-which-I-follow-004.jpg)

# 准则四：冗余的不规范数据是你的敌人

警惕冗余数据，并重构这些数据。我本人才不会因为冗余数据占用磁盘空间而为之担忧，冗余数据麻烦的地方在于“制造混乱”！

例如下图中，你可以看到 5th Standard 和 Fifth standard ，两者是相同信息的不同表述。这种数据叫你怎么查？好吧，你可能会说，之所以数据库中冒出这种东西，谁叫他乱录入，而且又没有校验机制。但如果你用这种数据生成一份报告，对于 sth Standard 会生成两份不同东西，看到这种报告，用户恐怕就凌乱了。

![](/public/upload/images/important-database-designing-rules-which-I-follow-005.jpg)

一个解决方案就是：把 Standard 的所有内容全部转移到另外一个完全不同的表中，而原来 Standard 的位置用外键引用。如图，这个新表叫做Standards，通过一个简单的外键与原来的表连接起来。

![](/public/upload/images/important-database-designing-rules-which-I-follow-006.jpg)

# 准则五：小心那些用分隔符分割的数据</h1>

第一范式的第二条说：数据库每一列不能存储<b>多个值</b>。如图展示的就是让数据库列存储多个值的例子。仔细看看 Syllabus 字段，这个字段被塞满了很多数据。这种字段被称为重复组（Repeating groups）。如果来操作这种数据，查询语句会很复杂，并且我也要怀疑查询的性能如何了。

![](/public/upload/images/important-database-designing-rules-which-I-follow-007.jpg)

这种一眼看上去，列中塞满了分隔符的数据必须要特别认真对待。为了更好的数据管理，最好把这种列全部转移到令一个表，然后通过外键与原表建立联系。

![](/public/upload/images/important-database-designing-rules-which-I-follow-008.jpg)

所以，我们还是要遵循第一范式的第二条：列不得存储多个值。我建立了一个 Syllabus 分表，并与主表建立了一个多对多的关系。

用这种方法，在主表中，Syllabus 字段不再塞入重复内容，也看不见“分隔符”这种东西了。

# 准则六：当心部分依赖

![](/public/upload/images/important-database-designing-rules-which-I-follow-009.jpg)

注意这些**部分依赖**主键的字段。如图，主键是（Roll Number，Standard）。这张表中，Syllabus 部分依赖于 Standard。注意 Syllabus 字段：Syllabus 通过 Standard 联系起来，而不是通过 Student 直接联系起来。

倘若 Syllabus 直接与 Student本身联系，那么，倘若某一天，我想要更新某个 Syllabus 字段，我必须将与之对应的所有 Student 更新一次。这既麻烦，也毫无逻辑。因此，把 Syllabus 独立一个表出来，并与 Standard 而不是 Sudent 联系起来，这样更有意义。

这条准则其实就是“第二范式”的表述：**全部属性必须完全依赖主键，不可以部分依赖主键**。

# 准则七：仔细选择推导列

![](/public/upload/images/important-database-designing-rules-which-I-follow-010.jpg)

**译者注：**所谓推导列，指它的值依赖于同一个表的其他类。例如图中的 Averge，其实可以通过 Total Marks ÷ Total Subject 得到。

如果你是设计OLTP（事务型）数据库，那么，去掉推导列将是一个明智之举。除非性能要求十分紧迫。但对于OLAP（分析型）数据库而言，推导列就是必要的了。因为分析型数据库要进行大量的求和与统计操作。

如上图，我们可以看到，Averge 依赖 Total Marks 和 Total Subject 的值。这就是一种冗余的形式。因此，碰到这种依赖、并由其他列推导而出的字段时，想一想：“这是必要的吗？”。

这条准则其实就如“第三范式”所说：<b>属性不得依赖其他非主属性</b>。我个人认为，别盲目追从第三范式，要视情况而定。数据还是要有冗余的。如果冗余数据是通过计算得来的，就视情况而定，判断是否要遵守第三范式。</p>

# 准则八：如果性能是关键，有点冗余也没什么。

![](/public/upload/images/important-database-designing-rules-which-I-follow-011.jpg)

你有没有严格执行“避免冗余”这条命令？要是性能问题很紧迫呢？想不想考虑一下非标准方案？用标准方案，你通常要大量使用连接操作。而非标准方案却可以减少连接操作——通过增加冗余。
</p>

# 准则九：多维数据是一种完全不同的野兽

![](/public/upload/images/important-database-designing-rules-which-I-follow-012.jpg)

OLAP 项目主要处理多维数据。如图，就需要知道每个国家、顾客、某年某月的销量。简单来说，所关注的“销量”是三个维度的数据的交集。

这种情况下，最好设计成一维的情况。简单说来，就是建一个中心表来存储销量（通过设置一个Sales的字段）。然后将其他维度的信息作为副表，并通过外键与中心表建立联系。

![](/public/upload/images/important-database-designing-rules-which-I-follow-013.jpg)

# 准则十：使用集合设计处理键-值表</h1>

我经常遇到的另一种表叫键-值表。它存储着**键**和与键对应的**值**。如下图的 Currency 和 Country 表，仔细看看，这两张表其实仅仅包含键和值罢了。

![](/public/upload/images/important-database-designing-rules-which-I-follow-014.jpg)

这种情况下，更明智的方案是，用一个**集合表**存下这两个表的全部信息，并设立一个 Type 字段来区分值的类型。

# 准则十一：为多级数据建立外键，或引用自身的主键

我也经常碰上那种多级情况。例如，有一个多级营销方案，一个销售商下面还有很多很多销售商。这种情况下，引用自身的主键和使用外键，都可以得到相同的效果。

![](/public/upload/images/important-database-designing-rules-which-I-follow-015.jpg)

我之所以这么说，并非叫你不要遵循范式，而是叫你别盲目遵循就行了。首要考虑的，应该是确认你的项目的类型和你要处理的数据的类型。

![](/public/upload/images/important-database-designing-rules-which-I-follow-016.jpg)
