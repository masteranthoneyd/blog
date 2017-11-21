## CPU100%问题快速定位
### 步骤一、找到最耗CPU的进程
1、执行top -c ，显示进程运行信息列表
2、键入P (大写p)，进程按照CPU使用率排序
3、第一个进程为最耗CPU，假设其PID为 2333
### 步骤二：找到最耗CPU的线程
1、top -Hp 2333 ，显示一个进程的线程运行信息列表
2、键入P (大写p)，线程按照CPU使用率排序
3、第一个为最耗CPU线程，假设其PID为 666
### 步骤三：将线程PID转化为16进制
输入 ： printf “%x\n” 666 得到 29a
666对应的16进制是0x29a
之所以要转化为16进制，是因为堆栈里，线程id是用16进制表示的
### 步骤四：查看堆栈，找到线程在干嘛
jstack 2333 | grep ‘0x29a’ -C5 --color
即可打印堆栈

## 内存OOM问题定位

### 一、确认是不是内存本身就分配过小
方法：jmap -heap 10765
注意：Ubuntu系统需要修改一下配置 打开`/etc/sysctl.d/10-ptrace.conf` 修改为：`kernel.yama.ptrace_scope = 0` （（即将1改成0）	）

### 二、找到最耗内存的对象
方法：jmap -histo:live 10765 | more
### 三、确认是否是资源耗尽
/proc/${PID}/fd
/proc/${PID}/task


所以，只要
ll /proc/${PID}/fd | wc -l
ll /proc/${PID}/task | wc -l （效果等同pstree -p | wc -l）
就能知道进程打开的句柄数和线程数。
