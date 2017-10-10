# Preface
>*[UML](https://zh.wikipedia.org/wiki/%E7%BB%9F%E4%B8%80%E5%BB%BA%E6%A8%A1%E8%AF%AD%E8%A8%80)*(Unified Modeling Language)又称**统一建模语言**或**标准建模语言**，是始于1997年一个OMG(Object Management Group)标准，它是一个支持模型化和软件系统开发的图形化语言，为软件开发的所有阶段提供模型化和可视化支持，包括由需求分析到规格，到构造和配置。
>
>*[StarUML](http://staruml.io/)*...就是一个画UML的很炫酷的工具=.=



UML中有九种建模的图标，即：
**用例图**、**类图**、**对象图**、**顺序图**、**协作图**、**状态图**、**活动图**、**组件图**、**配置图**


# Class Diagram
在这主要学习一下**类图 Class diagram **。
通过显示出系统的类以及这些类之间的关系来表示系统。类图是静态的———它们显示出什么可以产生影响但不会告诉你什么时候产生影响。

UML类的符号是一个被划分成三块的方框：类名，属性，和操作。抽象类的名字，是斜体的。类之间的关系是连接线。

## 类与类的关系

1. 泛化：表示类与类之间的继承关系、接口与接口之间的继承关系；
2. 实现：表示类对接口的实现；
3. 依赖：当类与类之间有使用关系时就属于依赖关系，不同于关联关系，依赖不具有“拥有关系”，而是一种“相识关系”，只在某个特定地方（比如某个方法体内）才有关系。
4. 关联：表示类与类或类与接口之间的依赖关系，表现为“拥有关系”；具体到代码可以用实例变量来表示；
5. 聚合：属于是关联的特殊情况，体现部分-整体关系，是一种弱拥有关系；整体和部分可以有不一样的生命周期；是一种弱关联；
6. 组合：属于是关联的特殊情况，也体现了体现部分-整体关系，是一种强“拥有关系”；整体与部分有相同的生命周期，是一种强关联；


## 显示interface
在staruml中，interface默认是以一个圆圈显示的(尴尬了)...，但好在可以设置成想要的样子。

1. 添加一个圆圈（interface）之后，右键或选择菜单栏中的Format
2. 选择Stereotype Display -> Label，这样矩形就显示出来了
3. 同样是Format，然后把Suppress Operations取消掉，这样操作就可以显示出来了

![](http://ojoba1c98.bkt.clouddn.com/img/learning-uml-and-using-staruml/interface-01.png)

![](http://ojoba1c98.bkt.clouddn.com/img/learning-uml-and-using-staruml/interface-02.png)