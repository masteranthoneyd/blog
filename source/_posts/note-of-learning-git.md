---
title: Git学习笔记
date: 2017-01-18 12:42:52
categories: Git/Github
tags: [Git,Github]
---

![](https://cdn.yangbingdong.com/img/git/git-operations.png)
# 前言
What is Git?
Git是目前世界上最先进的分布式版本控制系统（没有之一），而且是一款免费、开源的分布式版本控制系统，用于敏捷高效地处理任何或小或大的项目
一直以来，博主开发项目用的版本管理系用都是SVN[^1]，其实早就听闻过Git，一直没用过，后来接触Github和Hexo博客框架，才真正意义上开始接触Git，感受就是高端大气上档次！

<!--more-->
# 简介
Git是Linux系统的开发者Linus在2005年的时候，BitKeeper[^2]的东家BitMover公司回收了Linux社区的免费使用权的情况下，在仅仅的两周内Linus用C写出了一个分布式版本控制系统，这就是Git（超级牛X）！从此，Linux系统的源码已经由Git管理了。逐渐地，Git迅速成为最流行的分布式版本控制系统，尤其是在Github上线之后，无数开源项目开始迁移至GitHub，包括jQuery，PHP，Ruby等等

# Git安装
在**Debian**或者**Ubuntu Linux**下的Git安装非常简单，直接一条命令搞定
```
sudo apt-get install git
```
**Windows**下的模拟环境安装起来比较复杂，那么可以用牛人封装好的模拟环境加Git，叫**msysgit**，只需要下载一个exe然后双击安装
可从*[https://git-for-windows.github.io/](https://git-for-windows.github.io/)* 下载，或者从*[廖雪峰老师的镜像](https://pan.baidu.com/s/1kU5OCOB#list/path=%2Fpub%2Fgit)* 下载，然后按默认选项安装
安装完成后，在开始菜单里找到“Git”->“Git Bash”，蹦出一个类似命令行窗口的东西，就说明Git安装成功

成功安装之后，还需要配置一下全局个人信息：
```
git config --global user.name "Your Name"
git config --global user.email "email@example.com"

```
每次提交，都会记录这两个值，`--global` 参数，表示你这台机器上所有的Git仓库都会使用这个配置
可使用 `git config -l` 查看全局配置信息

# 运行前配置
一般在新的系统上，我们都需要先配置下自己的 Git 工作环境。配置工作只需一次，以后升级时还会沿用现在的配置。

## 配置文件如何生效

对于 Git 来说，配置文件的权重是**仓库>全局>系统**。Git 会使用这一系列的配置文件来存储你定义的偏好，它首先会查找 `/etc/gitconfig` 文件（系统级），该文件含有对系统上所有用户及他们所拥有的仓库都生效的配置值。接下来 Git 会查找每个用户的 `~/.gitconfig` 文件（全局级）。最后 Git 会查找由用户定义的各个库中Git目录下的配置文件 `.git/config`（仓库级），该文件中的值只对当前所属仓库有效。以上阐述的三 层配置从一般到特殊层层推进，如果定义的值有冲突，以后面层中定义的为准，例如：`.git/config` 和 `/etc/gitconfig` 的较量中， `.git/config` 取得了胜利。

## 查看配置

格式：`git config [--local|--global|--system] -l`

example:

```
# 查看当前生效的配置
git config -l

# 查看仓库级的配置
git config --local -l

# 查看全局级的配置
git config --global -l

# 查看系统级的配置
git config --system -l
```

## 修改配置

格式：`git config [--local|--global|--system] key value`

example:

```
git config --global user.name ybd
git config --global user.email yangbingdong1994@gmail.com
```



# 创建仓库（Repository）
创建一个目录并进入，进行初始化仓库
```
mkdir repo
cd repo
git init
```
目录下会多一个 `.git` 的隐藏文件，现在要创建一个文件并提交到仓库
```
touch read
vi read
 # 按a进入编辑
 # 输入Git is a distributed version control system
 # 按下Esc，并输入 ":wq" 保存退出
git add README.md  #添加文件到缓存区
git commit -m "first commit"  #将缓存区的文件提交到本地仓库
```
多个文件提交可用 `git add -A` 然后再 commit
```
➜  repo git:(master) ✗ git commit -m "first commit"
[master （根提交） 20717f5] first commit
 1 file changed, 2 insertions(+)
 create mode 100644 read

```

# 操作的自由穿越
要随时掌握工作区的状态：`git status` 
查看修改内容：`git diff read` 
查看版本历史信息 `got log` 或 `git log --pretty=oneline`
## 版本穿越
退到上一个版本：
```
git reset --hard HEAD^
```
上上一个版本就是 `HEAD^^`，当然往上100个版本写100个^比较容易数不过来，所以写成 `HEAD~100`
要重返未来，查看命令历史：`git reflog`

## 修改管理
添加文件到缓存区：`git add read` 或 `git add -A`
然后提交：`git commit -m "msg"`
查看状态：`git status`
**每次修改，如果不add到暂存区，那就不会加入到commit中**

## 撤销修改
当你发现工作区的修改有错误的时候，可丢弃工作区的修改：
```
git checkout -- read
```
命令 `git checkout -- read` 意思就是，把 `read` 文件在工作区的修改全部撤销，这里有两种情况：

一种是 `read` 自修改后还没有被放到暂存区，现在，撤销修改就回到和版本库一模一样的状态

一种是 `read` 已经添加到暂存区后，又作了修改，现在，撤销修改就回到添加到暂存区后的状态

**总之，就是让这个文件回到最近一次 `git commit` 或 `git add` 时的状态**
**注意！ `git checkout -- file` 命令中的 `--` 很重要，没有 `--` 就变成了切换分支了**

当你发现该文件修改错误并且已经提交到了缓存区，这个时候可以把暂存区的修改撤销掉（unstage），重新放回工作区：
```
git reset HEAD read
```
然后再丢弃工作区中的修改：
```
git checkout -- read
```
`git reset`命令既可以回退版本，也可以把暂存区的修改回退到工作区。当我们用HEAD时，表示最新的版本

## 删除文件
如果把工作区中的文件删除了，那么工作区和版本库就不一致，`git status` 命令会立刻告诉你哪些文件被删除了
现在有两个选择
* 一是确实要从版本库中删除该文件，那就用命令删掉，并且提交： 
```
git rm read
git commit -m "delete"
```

* 另一种情况是删错了，因为版本库里还有呢，所以可以很轻松地把误删的文件恢复到最新版本：
```
git checkout -- read
```
`git checkout` 其实是用版本库里的版本替换工作区的版本，无论工作区是修改还是删除，都可以“一键还原”

# 远程仓库
那么学会了Git的基本操作之后，对于分布式管理我们还需要有一个远程仓库供大家一起共同开发，好在有一个全世界最大最神奇的同性交友网—— *[Github](https://github.com/)*
那么在使用Github之前呢，我们需要设置一下与Github的SSH通讯：
1\. 创建SSH Key（已有.ssh目录的可以略过）
```
ssh-keygen -t rsa -C "youremail@example.com"
```
你需要把邮件地址换成你自己的邮件地址，然后一路回车，使用默认值即可，由于这个Key也不是用于军事目的，所以也无需设置密码
如果一切顺利的话，可以在用户主目录里找到 `.ssh` 目录，里面有 `id_rsa` 和 `id_rsa.pub` 两个文件，这两个就是SSH Key的秘钥对，` id_rsa` 是私钥，不能泄露出去，`id_rsa.pub` 是公钥，可以放心地告诉任何人

2\. 登陆GitHub，打开“Account settings”，“SSH Keys”页面，然后，点“Add SSH Key”，填上任意Title，在Key文本框里粘贴`id_rsa.pub`文件的内容，最后点“Add Key”

## 添加远程仓库
首先到Github创建一个仓库
然后与本地关联：
```
git remote add origin git@github.com:your-name/repo-name.git
```
远程库的名字就是`origin`，这是Git默认的叫法，也可以改成别的，但是`origin`这个名字一看就知道是远程库

下一步，就可以把本地库的所有内容推送到远程库上：
```
git push -u origin master
```
把本地库的内容推送到远程，用 `git push` 命令，实际上是把当前分支 `master` 推送到远程
由于远程库是空的，我们第一次推送 `master` 分支时，加上了 `-u` 参数，Git不但会把本地的 `master` 分支内容推送的远程新的 `master` 分支，还会把本地的 `master` 分支和远程的 `master` 分支关联起来，在以后的推送或者拉取时就可以简化命令

此后的推送都可以使用：
```
git push
```

## 从远程仓库克隆
```
git git@github.com:your-name/repo-name.git
```

# 标签管理
## 查看tag
列出所有tag：
```
git tag
```
这样列出的tag是按字母排序的，和创建时间没关系。如果只是想查看某些tag的话，可以加限定：
```
git tag -l v1.*
```
这样就只会列出1.几的版本。

## 创建tag

创建轻量级`tag`：
```
git tag 1.0.1
```
这样创建的`tag`没有附带其他信息，与之相应的是带信息的`tag`,`-m`后面带的就是注释信息，这样在日后查看的时候会很有用，这种是普通`tag`，还有一种有签名的`tag`：
```
git tag -a 1.0.1 -m 'first version'
```

除了可以为当前的进度添加`tag`，我们还可以为以前的`commit`添加`tag`：
首先查看以前的`commit`
```
git log --oneline
```
假如有这样一个`commit`：8a5cbc2 updated readme
这样为他添加`tag`
```
git tag -a v1.1 8a5cbc2
```

## 删除tag
很简单，知道`tag`名称后：
```
git tag -d v1.0
```
删除远程分支：
```
git push origin --delete tag <tagname>

```

## 共享tag
我们在执行`git push`的时候，`tag`是不会上传到服务器的，比如现在的`github`，创建`tag`后`git push`，在`github`网页上是看不到`tag`的，为了共享这些`tag`，你必须这样：
```
git push origin --tags
```


# 分支管理
分支相当与平行宇宙，互不干扰，哪天合并了就拥有了所有平行宇宙的特性
![](https://cdn.yangbingdong.com/img/git/gitBranch.png)
## 创建与合并分支
* 每次提交，Git都把它们串成一条时间线，这条时间线就是一个分支。截止到目前，只有一条时间线，在Git里，这个分支叫主分支，即 `master` 分支
* 一开始的时候，`master` 分支是一条线，Git用 `master` 指向最新的提交，再用 `HEAD` 指向 `master` ，就能确定当前分支，以及当前分支的提交点
* 当我们创建新的分支，例如 `dev` 时，Git新建了一个指针叫 `dev` ，指向 `master` 相同的提交，再把 `HEAD` 指向 `dev` ，就表示当前分支在 `dev` 上
* Git创建一个分支很快，因为除了增加一个 `dev` 指针，改改 `HEAD` 的指向，工作区的文件都没有任何变化
* 当 `HEAD` 指向 `dev` ，对工作区的修改和提交就是针对 `dev` 分支了，比如新提交一次后， `dev` 指针往前移动一步，而 `master` 指针不变
  ![](https://cdn.yangbingdong.com/img/git/gitBranch01.png)

查看分支：`git branch`
创建分支：`git branch <name>`
切换分支：`git checkout <name>`
创建+切换分支：`git checkout -b <name>`
合并某分支到当前分支：`git merge <name>`
删除分支：`git branch -d <name>`

## 解决冲突
合并分支并不是每次都不会出问题，如不同的分支对同一个文件同一行都被修改过，就会出现以下情况
![](https://cdn.yangbingdong.com/img/git/gitConflict.png)
那么再次合并有可能会冲突
```
➜  repo git:(master) git merge feature1 
自动合并 read
冲突（内容）：合并冲突于 read
自动合并失败，修正冲突然后提交修正的结果。
➜  repo git:(master) ✗ git status 
位于分支 master
您有尚未合并的路径。
  （解决冲突并运行 "git commit"）

未合并的路径：
  （使用 "git add <文件>..." 标记解决方案）

	双方修改：   read

修改尚未加入提交（使用 "git add" 和/或 "git commit -a"）
```
这种情况必须手动解决然后再次 `git add .`，`git commit -m "commit"`，打开文件可看到
```
Git is a version control
<<<<<<< HEAD
Creating a new branch is quick & simple.
=======
Creating a new branch is quick AND simple.
>>>>>>> feature1
```
Git用`<<<<<<<`，`=======`，`>>>>>>>`标记出不同分支的内容，那么经过合意，不好意思，大师兄说了，在座的各位都是垃圾，于是改成
```
Git,too fast too simple
```
再提交
```
➜  repo git:(master) ✗ git add read 
➜  repo git:(master) ✗ git commit -m "conflict fixed"
[master 8933f88] conflict fixed
➜  repo git:(master) 
```
ok了，再次 `add` 和 `commit` ，现在 `master` 分支和` feature1 `分支变成了这样
![](https://cdn.yangbingdong.com/img/git/gitFixConflict.png)


## 多PC协同开发
当你从远程仓库克隆时，实际上Git自动把本地的 `master` 分支和远程的 `master` 分支对应起来了，并且，远程仓库的默认名称是 `origin` 

查看远程库的信息：
查看简单信息：`git remote`
查看详细信息：`git remote -v`
查看远程仓库分支：`git branch -r`
查看本地分支与远程分支的对应关系：`git branch -vv`


推送分支
```
git push origin <branch> 

git push -u origin <branch> # 第一次推送加-u可以把当前分支与远程分支关联起来
```

克隆分支并关联
```
git clone git@github.com:youName/program.git # 默认克隆master分支到当前目录（包含分支文件目录）

git clone -b <branch> git@github.com:youName/program.git ./
# 克隆指定分支到指定文件目录下（不包含分支文件目录）

```

创建远程 `origin` 的 `dev` 分支到本地
```
git checkout -b <branch> origin/<branch>
```


关联本地分支与远程仓库分支
```
git branch --set-upstream <branch> origin/<branch>
```

# 同步更新Github Fork的项目

1、`fork`项目并`clone`到本地

2、进入项目根目录

3、添加`remote`指向**上游仓库**

```
git remote add upstream https://github.com/ORIGINAL_OWNER/ORIGINAL_REPOSITORY.git
```

4、把上游项目`fetch`下来

```
git fetch upstream
```

5、`merge`到`master`

```
git checkout master
git merge upstream/master
```

6、`push`到自己的远程仓库，搞定～

# 最后

Git真的异常强大，但命令繁多，需多加练习

> ***参考：[廖雪峰老师的教程](http://www.liaoxuefeng.com/)***

附命令图一张：
![](https://cdn.yangbingdong.com/img/git/gitCommand.png)

[^1]: 集中式版本管理系统之一
[^2]: 一个商业的版本控制系统




