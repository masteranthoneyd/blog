# Singleton Pattern
![](http://ojoba1c98.bkt.clouddn.com/img/design-pattern-creational/singleton.png)


## Java标准库中的单例模式
`java.lang.Runtime#getRuntime()`就是一个典型的代表。
```
class Runtime {
	private static Runtime currentRuntime = new Runtime();
 
	public static Runtime getRuntime() {
		return currentRuntime;
	}
 
	private Runtime() {}
 
	//... 
}
```
这个`currentRuntime`就是在初始化就已经加载了的。
