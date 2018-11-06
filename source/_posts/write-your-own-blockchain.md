---
title: 转载—自己动手写区块链
date: 2018-03-05 17:38:08
categories: [Programming, Java]
tags: [Blockchain, Java]
---

![](https://cdn.yangbingdong.com/img/blockchain/blockchain.jpg)

# Preface

> **区块链**（英语：blockchain 或 block chain）是用[分布式数据库](https://zh.wikipedia.org/wiki/%E5%88%86%E5%B8%83%E5%BC%8F%E6%95%B0%E6%8D%AE%E5%BA%93)识别、传播和记载信息的智能化[对等网络](https://zh.wikipedia.org/wiki/%E5%AF%B9%E7%AD%89%E7%BD%91%E7%BB%9C), 也称为价值互联网。[中本聪](https://zh.wikipedia.org/wiki/%E4%B8%AD%E6%9C%AC%E8%81%AA)在2008年，于《[比特币](https://zh.wikipedia.org/wiki/%E6%AF%94%E7%89%B9%E5%B8%81)白皮书》中提出“区块链”概念，并在2009年创立了[比特币社会网络](https://zh.wikipedia.org/w/index.php?title=%E6%AF%94%E7%89%B9%E5%B8%81%E7%A4%BE%E4%BC%9A%E7%BD%91%E7%BB%9C&action=edit&redlink=1)，开发出第一个区块，即“创世区块”。
>
> 区块链共享价值体系首先被众多的[加密货币](https://zh.wikipedia.org/wiki/%E5%8A%A0%E5%AF%86%E8%B2%A8%E5%B9%A3)效仿，并在[工作量证明](https://zh.wikipedia.org/wiki/%E5%B7%A5%E4%BD%9C%E9%87%8F%E8%AD%89%E6%98%8E)上和算法上进行了改进，如采用[权益证明](https://zh.wikipedia.org/wiki/%E6%9D%83%E7%9B%8A%E8%AF%81%E6%98%8E)和[SCrypt算法](https://zh.wikipedia.org/w/index.php?title=SCrypt%E7%AE%97%E6%B3%95&action=edit&redlink=1)。随后，区块链生态系统在全球不断进化，出现了[首次代币发售](https://zh.wikipedia.org/wiki/%E9%A6%96%E6%AC%A1%E4%BB%A3%E5%B8%81%E5%8F%91%E5%94%AE)ICO；智能合约区块链[以太坊](https://zh.wikipedia.org/wiki/%E4%BB%A5%E5%A4%AA%E5%9D%8A)；“轻所有权、重使用权”的资产代币化[共享经济](https://zh.wikipedia.org/wiki/%E5%85%B1%E4%BA%AB%E7%B6%93%E6%BF%9F)； 和[区块链国家](https://zh.wikipedia.org/w/index.php?title=%E5%8C%BA%E5%9D%97%E9%93%BE%E5%9B%BD%E5%AE%B6&action=edit&redlink=1)。目前，人们正在利用这一共享价值体系，在各行各业开发去中心化电脑程序(Decentralized applications, Dapp)，在全球各地构建[去中心化自主组织](https://zh.wikipedia.org/w/index.php?title=%E5%8E%BB%E4%B8%AD%E5%BF%83%E5%8C%96%E8%87%AA%E4%B8%BB%E7%BB%84%E7%BB%87&action=edit&redlink=1)和去中心化自主社区(Decentralized autonomous society, DAS)。
>
> ——来自维基百科
>

<!--more-->

# 比特币UTXO和去中心化系统的设计

> 引用来自***[JoeCao](https://github.com/JoeCao)***大神的一段*[文章](https://github.com/JoeCao/JoeCao.github.io/issues/12)*
>

## 起因

刚进2018年，区块链突然大火，程序员们可能莫名其妙，不就是一个分布式系统么，怎么突然就要改变互联网了？趁着这个东风，我们了解一些区块链基础知识。看看是否可以改变世界。

## UTXO是什么

是Unspent Transaction Output（未消费交易输出）简写。这绝对是比特币的非常特殊的地方，理解UTXO也就理解了比特币去中心化的含义。

说起UTXO必须先要介绍交易模型。以我们平时对交易的理解，我给张三转账了一笔100块钱，那就是我的账上的钱少了100，张三账上的钱多了100。我们再把问题稍微复杂一些，我和张三合起来买一个李四的一个商品390块钱。我的账户支付100，张三账户支付300，李四的帐户获得390，支付宝账户获得了10块钱的转账手续费。那么对这比交易的记录应该是这样的：

[![帐户模型](https://camo.githubusercontent.com/dc61609affa838e8aca79b30ce4313b852457743/687474703a2f2f6f7338776a76796b772e626b742e636c6f7564646e2e636f6d2f323031382d30312d32362d3131323832322e6a7067)](https://camo.githubusercontent.com/dc61609affa838e8aca79b30ce4313b852457743/687474703a2f2f6f7338776a76796b772e626b742e636c6f7564646e2e636f6d2f323031382d30312d32362d3131323832322e6a7067)

这种记账方式常用在财务记账上。不过作为一个去中心化的系统，是没有一个中心化银行管理你的开户、销户、余额的。没有余额，怎么判断你的账上有100块钱？

[![如何确认](https://camo.githubusercontent.com/cfdfe28f28fe95857fa08d75e41692386fc7b26f/687474703a2f2f6f7338776a76796b772e626b742e636c6f7564646e2e636f6d2f323031382d30312d32362d3131323831392e6a7067)](https://camo.githubusercontent.com/cfdfe28f28fe95857fa08d75e41692386fc7b26f/687474703a2f2f6f7338776a76796b772e626b742e636c6f7564646e2e636f6d2f323031382d30312d32362d3131323831392e6a7067)

此时用户C必须将前面几次交易的比特币输出作为下一个关联交易的输入，具体见下图的no 321笔交易，用户C将前面获得的两次输出，作为输入放在了交易中，然后给自己输出1个比特币的找零（如果不给自己输出找零，那么这个差额就被矿工当成小费了，切记切记）。比特币的程序会判定，如果两个UTXO加在一起不够支付，则交易不成功。

[![区块链基础.001](https://camo.githubusercontent.com/4f314bd52ecbc90b59054cadb5b96de7dc99d237/687474703a2f2f6f7338776a76796b772e626b742e636c6f7564646e2e636f6d2f323031382d30312d32362d3131323832312e6a7067)](https://camo.githubusercontent.com/4f314bd52ecbc90b59054cadb5b96de7dc99d237/687474703a2f2f6f7338776a76796b772e626b742e636c6f7564646e2e636f6d2f323031382d30312d32362d3131323832312e6a7067)

比特币UTXO使用有点像古代的银锭

- 五两的银锭付给别人二两，需要通过夹剪将一整块银锭剪成两块，二两的给别人，三两的留给自己。对比：比特币在输出中重新创建一个新的UTXO作为给自己的找零
- 要付给别人五两，手上有几块碎银子单都不足五两，则需要将碎银子一起付给对方。对比：比特币在输入中同时引用多个输出UTXO。

这样的做法很繁琐，所以银两在古代并不是一个很普遍的支付方式（别被武侠片给骗了，大部分还是用铜钱）。
比特币采用UTXO并不能很直观的去理解，但是为什么要用呢？

## 使用UTXO的动机

那么我们站在系统设计的角度猜测一下为什么中本聪会考虑使用UTXO。

- 比特币是没有开户的过程的，一个本地计算生成公私钥就能构成一个合法的帐户，甚至有些用户为了一些“靓号”帐户，通过暴力运算生成天量的再也不会使用的帐户。去中心化系统无法跟踪每个账户的生成和销毁，这样的系统里面的帐户数量远大于未消费的输出数量，所以以UTXO来替代跟踪帐户交易的方式，消耗的系统资源会比较少 ；
- 比特币有个比较好的特性是匿名性，很多人每次交易就换一对公私钥，交易输出的给自己的找零往往输出到一个另外的帐户下去，UTXO迎合了这种需求。而使用帐户就没那么灵活了。
- 如果我使用余额系统，那么在生成一笔交易的时候，我首先要考虑的就是“幂等”问题，因为发出去的交易是给某个帐户加减钱，如果交易因为网络等原因重新发送，变成两笔交易重复扣钱，我就要哭了，这是在区块链里面著名的“重放攻击”。所以交易必须设计一个唯一的标识id让服务器知道这是同一笔交易。但是在去中心化系统中没有一个超级服务器统一分配交易ID，只能本地生成，而且跟踪这些交易ID的状态，也是一个很大的负担，因为我需要将区块链从创世块到现在所有的交易都遍历一遍，才能确定是是否是重复交易。如果用UTXO就可以避免这个问题，UTXO相比交易数少了不止一个数量级，而且UTXO只有两个状态—未消费、被消费，比特币只能有一个操作— 将为消费的UTXO变为已消费状态。不管我发送多少次交易，都会得到一个结果。
- 在中本聪倡导每个cpu都是一票的去中心化社区，让每个节点都有能力去做计算是需要特别重视的，否则单个节点的计算能力要求过高，整个系统将向着“中心化”趋势滑下去。

在比特币的实现中，是把所有的UTXO保存在一个单独的UTXOSet缓存中，截止2017年9月，这个缓存大概2.7Gb，与之对应，整个区块链的交易数据达到140Gb，UTXO缓存像是一个只保存了最终一个状态的git，整体的消耗负担小了很多很多。

但是中本聪没想到，很多人现在把交易输出的脚本玩出花来了，导致很多UTXO创建出来就是不为消费用的，永远不会被消费掉，节点的负担越来越重。这才有了后续的**BIP改进**以及**以太坊的账户模型**。那又是一个很长的故事了...

# 基础篇

> 也可以看一下这一篇：***[https://yemengying.com/2018/02/11/hash-blockchain/](https://yemengying.com/2018/02/11/hash-blockchain/)***

2018年开始区块链真是火啊。一夜暴富的例子一直在传说。今天我们就自己动手写一个基本的区块链。

先简单的说一下区块链是个什么（相信你早就知道了）。

区块链就是一个链表。把一堆区块串起来就是区块链。每个`block`有自己的数字签名（就是一串不规则看起来叼叼的字符串），同时包含有上一个`block`的数字签名，然后包含一些其他的`data`。

大体就长这样：

![img](https://cdn.yangbingdong.com/img/blockchain/blockchain01.webp)

是不是很熟悉，链表。

好，继续。

数字签名是什么？就是`hash`。

而且每个`block`含有前一个`block`的`hash`值，而且每个`block`自己的`hash`也是由前一个的`hash`计算得来的。如果前一个`block`（数据块）的数据发生改变，那么前一个的`hash`值也改变了，由此就会影响到之后的数据块的所有`hash`值。

所以，通过计算和对比`hash`值这种方式我们就可以知道区块链是不是合法的，是不是已经被篡改。

什么意思呢？意味着只要你修改了区块链中的任何一个块中的数据，都将会改变`hash`，从而破坏了整个链。

好，不多说。上代码：

## **block块定义**

先新建个block块：

```
public class Block {

   public String hash;
   public String previousHash; 
   private String data; //our data will be a simple message.
   private long timeStamp; //as number of milliseconds since 1/1/1970.

   //Block Constructor.  
   public Block(String data,String previousHash ) {
      this.data = data;
      this.previousHash = previousHash;
      this.timeStamp = new Date().getTime();
   }
}
```

你也看到了我们的`Block`里有四个字段，`hash`就是这个块自己的`hash`值，`previousHash`就是上一个块的`hash`值，`data`就是这个块所持有的数据，`timeStamp`就是一个时间记录。

## **数字签名生成**

接下来我们就需要生成数字签名。

有很多种的加密算法来生成数字签名。这里我们就选择`SHA256`。这里先新建一个工具类用来搞定这个件事情：

```
import java.security.MessageDigest;//通过导入MessageDigest来使用SHA256

public class StringUtil {

   //Applies Sha256 to a string and returns the result. 
   public static String applySha256(String input){

      try {
         MessageDigest digest = MessageDigest.getInstance("SHA-256");

         //Applies sha256 to our input, 
         byte[] hash = digest.digest(input.getBytes("UTF-8"));

         StringBuffer hexString = new StringBuffer(); // This will contain hash as hexidecimal
         for (int i = 0; i < hash.length; i++) {
            String hex = Integer.toHexString(0xff & hash[i]);
            if(hex.length() == 1) hexString.append('0');
            hexString.append(hex);
         }
         return hexString.toString();
      }
      catch(Exception e) {
         throw new RuntimeException(e);
      }
   }

   //Short hand helper to turn Object into a json string
   public static String getJson(Object o) {
      return new GsonBuilder().setPrettyPrinting().create().toJson(o);
   }

   //Returns difficulty string target, to compare to hash. eg difficulty of 5 will return "00000"  
   public static String getDificultyString(int difficulty) {
      return new String(new char[difficulty]).replace('\0', '0');
   }

   
}
```

好，现在我们在`Block`里添加生成`hash`的方法：

```
//Calculate new hash based on blocks contents
public String calculateHash() {
   String calculatedhash = StringUtil.applySha256( 
         previousHash +
         Long.toString(timeStamp) +
         Integer.toString(nonce) + 
         data 
         );
   return calculatedhash;
}
```

然后我们在构造函数里添加`hash`值的计算：

```
//Block Constructor.  
public Block(String data,String previousHash ) {
   this.data = data;
   this.previousHash = previousHash;
   this.timeStamp = new Date().getTime();

   this.hash = calculateHash(); //Making sure we do this after we set the other values.
}
```

## **一试身手**

现在是时候一试身手了。我们新建一个`main`类来玩耍一次：

```
public static void main(String[] args) {
   Block genesisBlock = new Block("Hi im the first block", "0");
   System.out.println("block 1的hash值 : " + genesisBlock.hash);

   Block secondBlock = new Block("Yo im the second block",genesisBlock.hash);
   System.out.println("block 2的hash值: " + secondBlock.hash);

   Block thirdBlock = new Block("Hey im the third block",secondBlock.hash);
   System.out.println("block 3的hash值: " + thirdBlock.hash);

}
```

输出结果如下：

![img](https://cdn.yangbingdong.com/img/blockchain/blockchain02.webp)

*`hash`值是不一样的，因为每个`block`的时间戳不同。*

现在每个块都有了自己的数字签名，并且这些数字签名都是基于每个块自身的信息以及前一个块的数字签名联合起来生成的数字签名。

但，现在还不能叫区块链。只是一个个区块。接下来就让我们把这些块装入一个`ArrayList`中：

```
public static ArrayList<Block> blockchain = new ArrayList<Block>();

public static void main(String[] args) {
    //add our blocks to the blockchain ArrayList:
    blockchain.add(new Block("Hi im the first block", "0"));
    blockchain.add(new Block("Yo im the second block",blockchain.get(blockchain.size()-1).hash));
    blockchain.add(new Block("Hey im the third block",blockchain.get(blockchain.size()-1).hash));

    String blockchainJson = new GsonBuilder().setPrettyPrinting().create().toJson(blockchain);
    System.out.println(blockchainJson);
}
```

现在看起来就比较紧凑了，也像个区块链的样子了：

![img](https://cdn.yangbingdong.com/img/blockchain/blockchain03.webp)

## **检查区块链的完整性**

现在就让我们在`ImportChain`中创建一个`isChainValid()`方法，它会遍历链中每个块，然后对比`hash`值。这个方法做的事情就是检查`hash`变量的值是否等于计算出来的`hash`值以及上一个块的`hash`是否等于`previousHash`变量的值。

```
public static Boolean isChainValid() {
   Block currentBlock; 
   Block previousBlock;
   String hashTarget = new String(new char[difficulty]).replace('\0', '0');

   //循环遍历每个块检查hash
   for(int i=1; i < blockchain.size(); i++) {
      currentBlock = blockchain.get(i);
      previousBlock = blockchain.get(i-1);
      //比较注册的hash和计算的hash:
      if(!currentBlock.hash.equals(currentBlock.calculateHash()) ){
         System.out.println("Current Hashes not equal");          
         return false;
      }
      //比较上一个块的hash和注册的上一个hash（也就是previousHash）
      if(!previousBlock.hash.equals(currentBlock.previousHash) ) {
         System.out.println("Previous Hashes not equal");
         return false;
      }
      //检查hash是否被处理
      if(!currentBlock.hash.substring( 0, difficulty).equals(hashTarget)) {
         System.out.println("This block hasn't been mined");
         return false;
      }

   }
   return true;
}
```

对区块链中的块的任何更改都将导致此方法返回false。

On the bitcoin network nodes share their blockchains and the **longest valid chain is accepted** by the network. What’s to stop someone tampering with data in an old block then creating a whole new longer blockchain and presenting that to the network ? **Proof of work**. The hashcash proof of work system means it takes considerable time and computational power to create new blocks. Hence the attacker would need more computational power than the rest of the peers combined.

上面说的就是POW 。之后会介绍。

好，上面基本上把区块链搞完了。

现在我们开始新的征程吧！

## **挖矿**

我们将要求矿工们来做POW，具体就是通过尝试不同的变量直到块的`hash`以几个0开头。

然后我们添加一个`nonce`（Number once）到`calculateHash()` 方法以及`mineBlock()`方法：

```
public class ImportChain {

   public static ArrayList<Block> blockchain = new ArrayList<Block>();
   public static int difficulty = 5;

   public static void main(String[] args) {
      //add our blocks to the blockchain ArrayList:

      System.out.println("正在尝试挖掘block 1... ");
      addBlock(new Block("Hi im the first block", "0"));

      System.out.println("正在尝试挖掘block 2... ");
      addBlock(new Block("Yo im the second block",blockchain.get(blockchain.size()-1).hash));

      System.out.println("正在尝试挖掘block 3... ");
      addBlock(new Block("Hey im the third block",blockchain.get(blockchain.size()-1).hash));

      System.out.println("\nBlockchain is Valid: " + isChainValid());

      String blockchainJson = StringUtil.getJson(blockchain);
      System.out.println("\nThe block chain: ");
      System.out.println(blockchainJson);
   }

   public static Boolean isChainValid() {
      Block currentBlock; 
      Block previousBlock;
      String hashTarget = new String(new char[difficulty]).replace('\0', '0');

      //loop through blockchain to check hashes:
      for(int i=1; i < blockchain.size(); i++) {
         currentBlock = blockchain.get(i);
         previousBlock = blockchain.get(i-1);
         //compare registered hash and calculated hash:
         if(!currentBlock.hash.equals(currentBlock.calculateHash()) ){
            System.out.println("Current Hashes not equal");          
            return false;
         }
         //compare previous hash and registered previous hash
         if(!previousBlock.hash.equals(currentBlock.previousHash) ) {
            System.out.println("Previous Hashes not equal");
            return false;
         }
         //check if hash is solved
         if(!currentBlock.hash.substring( 0, difficulty).equals(hashTarget)) {
            System.out.println("This block hasn't been mined");
            return false;
         }

      }
      return true;
   }

   public static void addBlock(Block newBlock) {
      newBlock.mineBlock(difficulty);
      blockchain.add(newBlock);
   }
}
```

```
import java.util.Date;

public class Block {

   public String hash;
   public String previousHash; 
   private String data; //our data will be a simple message.
   private long timeStamp; //as number of milliseconds since 1/1/1970.
   private int nonce;

   //Block Constructor.  
   public Block(String data,String previousHash ) {
      this.data = data;
      this.previousHash = previousHash;
      this.timeStamp = new Date().getTime();

      this.hash = calculateHash(); //Making sure we do this after we set the other values.
   }

   //Calculate new hash based on blocks contents
   public String calculateHash() {
      String calculatedhash = StringUtil.applySha256( 
            previousHash +
            Long.toString(timeStamp) +
            Integer.toString(nonce) + 
            data 
            );
      return calculatedhash;
   }

   //Increases nonce value until hash target is reached.
   public void mineBlock(int difficulty) {
      String target = StringUtil.getDificultyString(difficulty); //Create a string with difficulty * "0" 
      while(!hash.substring( 0, difficulty).equals(target)) {
         nonce ++;
         hash = calculateHash();
      }
      System.out.println("Block已挖到!!! : " + hash);
   }

}
```

执行main，输出如下：

![img](https://cdn.yangbingdong.com/img/blockchain/blockchain04.webp)

挖掘每一个块都需要一些时间，大概3秒钟。你可以调整难度，看看是如何影响挖矿时间的。

如果有人要窜改区块链中的数据，那么他们的区块链将是无效的，invalid。

他们将无法创建更长的区块链。

在你的网络中诚实的区块链有更大的时间优势来创建一个最长的链。

被篡改的区块链将无法追上更长、更有效的链。

除非它们比网络中的所有其他节点具有更快的计算速度。比如未来的量子计算机之类的东西。

好，我们已经完成了一个基本的区块链！

总结一下我们的这个区块链：

- 每个区块上携带数据。
- 有数字签名。
- 必须通过POW来挖掘来验证新的区块。
- 可以验证数据是否合法和是否被修改。

> ***[原文链接](https://mp.weixin.qq.com/s?__biz=MzA5MzQ2NTY0OA==&mid=2650797410&idx=1&sn=c16d1b0064768479a05dc65cf2b542d3&chksm=8856283dbf21a12be25300c012dc344199320f54a13b54d595c4db899d74ede95cb06d7e784c&mpshare=1&scene=1&srcid=0305VPK6hQFN8yg7iE3wz917#rd)***
>

# 发起一笔交易

上一文我们已经学会了写一个基本的区块链：[自己动手写区块链（Java版）](http://mp.weixin.qq.com/s?__biz=MzA5MzQ2NTY0OA==&mid=2650797410&idx=1&sn=c16d1b0064768479a05dc65cf2b542d3&chksm=8856283dbf21a12be25300c012dc344199320f54a13b54d595c4db899d74ede95cb06d7e784c&scene=21#wechat_redirect)。

本文我们接着前文，继续深入。

本文我们将会做以下事情：

1、创建一个钱包（wallet）。

2、使用我们的前面创建的区块链发送一笔签名的交易出去。

3、还有其他更叼的事情等等。

听起来是不是就让人心动。

最后的结果就是我们有了自己的**加密货币**，是的，`crypto coin`。

前面我们已经构建了一个基本的区块链。但目前这个区块链的区块中的`message`是一些没有什么实际用途和意义的数据。本文我们就尝试让区块中能够存储一些交易数据（一个区块中可以存储多笔交易数据），这样我们就可以创建自己的加密货币（当然还是一个简单的），这里给我们的货币起个名字叫：“NoobCoin”。

## **1、创建钱包**

在加密货币（crypto-currencies）中，货币所有权被作为交易（transaction）在区块链上进行转移，参与者有一个收发资金的地址。

![img](https://cdn.yangbingdong.com/img/blockchain/blockchain5.webp)

好，现在让我们创建一个钱包（Wallet）来持有`pubkey`和`private key`：

```
import java.security.*;
```

```
public class Wallet {

   public PrivateKey privateKey;
   public PublicKey publicKey;

}

```

**公钥和私钥的用途是什么？**

对于我们的“`noobcoin`”，公钥（`public key`）就是我们的一个地址，`address`。

可以与其他人共享这个公钥，来接受支付。我们的私钥是用来签署（`sign`）我们的交易（`transaction`），所以除了私钥（`private key`）的所有者，没有人可以花我们的钱。用户将不得不对自己的私钥保密！我们还将公钥与交易（`transaction`）一起发送，它可以用来验证我们的签名是否有效，并且数据没有被篡改。

![img](https://cdn.yangbingdong.com/img/blockchain/blockchain06.webp)

*私钥用于对我们不希望被篡改的数据进行签名。公钥用于验证签名。*

我们在一个`KeyPair`中生成我们的私钥和公钥。这里使用`Elliptic-curve`加密来生成`KeyPair`。现在我们就去`Wallet`类中添加一个方法`generateKeyPair()`，然后在构造函数中调用它：

```
public class Wallet {

   public PrivateKey privateKey;
   public PublicKey publicKey;

   public Wallet() {
      generateKeyPair();
   }

   public void generateKeyPair() {
      try {
         KeyPairGenerator keyGen = KeyPairGenerator.getInstance("ECDSA","BC");
         SecureRandom random = SecureRandom.getInstance("SHA1PRNG");
         ECGenParameterSpec ecSpec = new ECGenParameterSpec("prime192v1");
         // Initialize the key generator and generate a KeyPair
         keyGen.initialize(ecSpec, random); //256 
           KeyPair keyPair = keyGen.generateKeyPair();
           // Set the public and private keys from the keyPair
           privateKey = keyPair.getPrivate();
           publicKey = keyPair.getPublic();

      }catch(Exception e) {
         throw new RuntimeException(e);
      }
   }
}
```

这个方法就是负责生成公钥和私钥。具体就是通过`Java.security.KeyPairGenerator`来生成`Elliptic Curve key`对。然后把这个方法加入到`Wallet`的**构造函**数中。

现在我们已经有了一个大体的钱包类。接下来我们看看交易（`transaction`）类。

## **2. 交易和签名（Transactions & Signatures）**

每笔交易将会携带如下数据：

1、资金发送方的公钥（地址）。

2、资金接收方的公钥（地址）。

3、要转移的资金金额。

4、输入（`Inputs`）。这个输入是对以前交易的引用，这些交易证明发件人拥有要发送的资金。

5、输出（`Outputs`），显示交易中收到的相关地址量。（这些输出作为新交易中的输入引用）

6、一个加密签名。证明地址的所有者是发起该交易的人，并且数据没有被更改。（例如：防止第三方更改发送的金额）

让我们创建交易类吧：

```
import java.security.*;
import java.util.ArrayList;

public class Transaction {

   public String transactionId; //Contains a hash of transaction*
   public PublicKey sender; //Senders address/public key.
   public PublicKey reciepient; //Recipients address/public key.
   public float value; //Contains the amount we wish to send to the recipient.
   public byte[] signature; //This is to prevent anybody else from spending funds in our wallet.

   public ArrayList<TransactionInput> inputs = new ArrayList<TransactionInput>();
   public ArrayList<TransactionOutput> outputs = new ArrayList<TransactionOutput>();

   private static int sequence = 0; //A rough count of how many transactions have been generated 

   // Constructor: 
   public Transaction(PublicKey from, PublicKey to, float value,  ArrayList<TransactionInput> inputs) {
      this.sender = from;
      this.reciepient = to;
      this.value = value;
      this.inputs = inputs;
   }

   private String calulateHash() {
      sequence++; //increase the sequence to avoid 2 identical transactions having the same hash
      return StringUtil.applySha256(
            StringUtil.getStringFromKey(sender) +
            StringUtil.getStringFromKey(reciepient) +
            Float.toString(value) + sequence
            );
   }
}
```

上面的`TransactionInput`和`TransactionOutput`类一会再新建。

我们的交易（`Transaction`）类还应该包含生成/验证签名和验证交易的相关方法。

注意这里，既有验证签名的方法，也有验证交易的方法。

但是，稍等...

先来说说签名的目的是什么？它们是如何工作的？

**签名在我们的区块链上执行两个非常重要的任务：首先，它能只允许所有者使用其货币；其次，在新区块被挖掘之前，它能防止其他人篡改其提交的交易（在入口点）**。

**私钥用于对数据进行签名，公钥可用于验证其完整性**。

例如：Bob想给Sally发送2个NoobCoin，然后他们的钱包软件生成了这个交易并将其提交给矿工，以便将其包含在下一个块中。一名矿工试图将2枚货币的接收人改为Josh。不过，幸运的是，Bob已经用他的私钥签署了交易数据，允许任何人使用Bob的公钥去验证交易数据是否被更改（因为没有其他任何人的公钥能够验证交易）。

可以（从前面的代码块中）看到我们的签名就是一堆字节，所以现在创建一个方法来生成签名。我们首先需要的是`StringUtil`类中的几个`helper`方法：

```
//Applies ECDSA Signature and returns the result ( as bytes ).
public static byte[] applyECDSASig(PrivateKey privateKey, String input) {
   Signature dsa;
   byte[] output = new byte[0];
   try {
      dsa = Signature.getInstance("ECDSA", "BC");
      dsa.initSign(privateKey);
      byte[] strByte = input.getBytes();
      dsa.update(strByte);
      byte[] realSig = dsa.sign();
      output = realSig;
   } catch (Exception e) {
      throw new RuntimeException(e);
   }
   return output;
}

//Verifies a String signature
public static boolean verifyECDSASig(PublicKey publicKey, String data, byte[] signature) {
   try {
      Signature ecdsaVerify = Signature.getInstance("ECDSA", "BC");
      ecdsaVerify.initVerify(publicKey);
      ecdsaVerify.update(data.getBytes());
      return ecdsaVerify.verify(signature);
   }catch(Exception e) {
      throw new RuntimeException(e);
   }
}

public static String getStringFromKey(Key key) {
   return Base64.getEncoder().encodeToString(key.getEncoded());
}
```

*不要过分担心这些方法具体的逻辑。你只需要知道的是：`applyECDSASig`方法接收发送方的私钥和字符串输入，对其进行签名并返回字节数组。`verifyECDSASig`接受签名、公钥和字符串数据，如果签名是有效的，则返回`true`，否则`false`。`getStringFromKey`从任意`key`返回编码的字符串。*

现在让我们在`Transaction`类中使用这些签名方法，分别创建`generateSignature()`和`verifiySignature()`方法：

```
public void generateSignature(PrivateKey privateKey) {
   String data = StringUtil.getStringFromKey(sender) + StringUtil.getStringFromKey(reciepient) + Float.toString(value)    ;
   signature = StringUtil.applyECDSASig(privateKey,data);
}

public boolean verifySignature() {
   String data = StringUtil.getStringFromKey(sender) + StringUtil.getStringFromKey(reciepient) + Float.toString(value)    ;
   return StringUtil.verifyECDSASig(sender, data, signature);
}
```

在现实中，你可能希望签署更多的信息，比如使用的输出（outputs）/输入（inputs）和/或时间戳（time-stamp）（现在我们只签署了最基本的）。

在将新的交易添加到块中时，矿工将对签名进行验证。

当我们检查区块链的合法性的时候，其实也可以检查签名。

## **3.测试钱包（Wallets）和签名（Signatures）**

现在我们差不多完成了一半了，先来测试下已经完成的是不是可以正常工作。在`NoobChain`类中，让我们添加一些新变量并替换main方法的内容如下：

```
import java.security.Security;
import java.util.ArrayList;

public class NoobChain {

    public static ArrayList<Block> blockchain = new ArrayList<Block>();
    public static int difficulty = 5;
    public static Wallet walletA;
    public static Wallet walletB;

    public static void main(String[] args) {
        //Setup Bouncey castle as a Security Provider
        Security.addProvider(new org.bouncycastle.jce.provider.BouncyCastleProvider());
        //Create the new wallets
        walletA = new Wallet();
        walletB = new Wallet();
        //Test public and private keys
        System.out.println("Private and public keys:");
        System.out.println(StringUtil.getStringFromKey(walletA.privateKey));
        System.out.println(StringUtil.getStringFromKey(walletA.publicKey));
        //Create a test transaction from WalletA to walletB
        Transaction transaction = new Transaction(walletA.publicKey, walletB.publicKey, 5, null);
        transaction.generateSignature(walletA.privateKey);
        //Verify the signature works and verify it from the public key
        System.out.println("Is signature verified");
        System.out.println(transaction.verifySignature());

    }
}
```

可以发现我们使用了`boncey castle`来作为安全实现的提供者。

还创建了两个钱包，钱包A和钱包B，然后打印了钱包A的私钥和公钥。还新建一笔交易。然后使用钱包A的公钥对这笔交易进行了签名。

输出:

![img](https://cdn.yangbingdong.com/img/blockchain/blockchain07.webp)

嗯，签名验证是`true`，符合期望。

现在是时候小开心一下了。现在我们只需要创建和校验输出（`outputs`）和输入（`inputs`）然后把交易存储到区块链中。

## **4. 输入（Inputs）与输出（Outputs）1：加密货币是如何拥有的…**

如果你想拥有1个比特币，你必须收到1个比特币。总账不会真的给你添加一个比特币，从发送者那里减去一个比特币，发送者提到他/她以前收到一个比特币，然后创建一个交易输出，显示1比特币被发送到你的地址。（交易输入是对以前交易输出的引用。）

**你的钱包余额是所有发送给你的未使用的交易输出的总和。**

ps：这里略微有点绕，总之你就记住**进账**和**出账**这回事情。

从现在开始，我们将遵循比特币惯例并调用未使用的交易输出：`UTXO`。

好，让我们创建一个`TransactionInput`类：

```
public class TransactionInput {
   public String transactionOutputId; //Reference to TransactionOutputs -transactionId
   public TransactionOutput UTXO; //Contains the Unspent transaction output

   public TransactionInput(String transactionOutputId) {
      this.transactionOutputId = transactionOutputId;
   }
}
```

这个类将用于引用尚未使用的`TransactionOutputs`的值。`transactionOutputId`将用于查找相关的`TransactionOutput`，从而允许矿工检查你的所有权。

下面是`TransactionOutput`类：

```
import java.security.PublicKey;

public class TransactionOutput {
   public String id;
   public PublicKey reciepient; //also known as the new owner of these coins.
   public float value; //the amount of coins they own
   public String parentTransactionId; //the id of the transaction this output was created in

   //Constructor
   public TransactionOutput(PublicKey reciepient, float value, String parentTransactionId) {
      this.reciepient = reciepient;
      this.value = value;
      this.parentTransactionId = parentTransactionId;
      this.id = StringUtil.applySha256(StringUtil.getStringFromKey(reciepient)+Float.toString(value)+parentTransactionId);
   }

   //Check if coin belongs to you
   public boolean isMine(PublicKey publicKey) {
      return (publicKey == reciepient);
   }

}
```

交易输出将显示从交易发送到每一方的最终金额。当在新的交易中作为输入引用时，它们将作为你要发送的货币的证明，能够证明你有钱可发送。

## **5. 输入（Inputs）与输出（Outputs）2：处理交易……**

链中的块可能接收到许多交易，而区块链可能非常非常长，处理新交易可能需要数亿年的时间，因为我们必须查找并检查它的输入。要解决这个问题，我们就需要存在一个额外的集合（`collection`）来保存所有未使用的可被作为输入（`inputs`）的交易。在下面的`ImportChain`类中，添加一个所有UTXO的集合：

```
public class ImportChain {

   public static ArrayList<Block> blockchain = new ArrayList<Block>();
   public static HashMap<String,TransactionOutput> UTXOs = new HashMap<String,TransactionOutput>();

   public static int difficulty = 3;
   public static float minimumTransaction = 0.1f;
   public static Wallet walletA;
   public static Wallet walletB;
   public static Transaction genesisTransaction;

   public static void main(String[] args) {
```

现在我们把之前的那些实现放在一起来处理一笔交易吧。先在`Transaction`类中的添加一个方法`processTransaction`：

```
public boolean processTransaction() {

   if(verifySignature() == false) {
      System.out.println("#Transaction Signature failed to verify");
      return false;
   }

   //Gathers transaction inputs (Making sure they are unspent):
   for(TransactionInput i : inputs) {
      i.UTXO = ImportChain.UTXOs.get(i.transactionOutputId);
   }

   //Checks if transaction is valid:
   if(getInputsValue() < ImportChain.minimumTransaction) {
      System.out.println("Transaction Inputs to small: " + getInputsValue());
      return false;
   }

   //Generate transaction outputs:
   float leftOver = getInputsValue() - value; //get value of inputs then the left over change:
   transactionId = calulateHash();
   outputs.add(new TransactionOutput( this.reciepient, value,transactionId)); //send value to recipient
   outputs.add(new TransactionOutput( this.sender, leftOver,transactionId)); //send the left over 'change' back to sender

   //Add outputs to Unspent list
   for(TransactionOutput o : outputs) {
      ImportChain.UTXOs.put(o.id , o);
   }

   //Remove transaction inputs from UTXO lists as spent:
   for(TransactionInput i : inputs) {
      if(i.UTXO == null) continue; //if Transaction can't be found skip it
      ImportChain.UTXOs.remove(i.UTXO.id);
   }

   return true;
}
```

还添加了`getInputsValue`方法。使用此方法，我们执行一些检查以确保交易是有效的，然后收集输入并生成输出。（要了解更多信息，请参阅代码中的注释行）。

重要的是，在最后，我们从UTXO的列表中删除`input`，这意味着交易输出只能作为一个输入使用一次…而且必须使用完整的输入值，因为发送方要将“更改”返回给自己。

![img](https://cdn.yangbingdong.com/img/blockchain/blockchain08.webp)

红色箭头是输出。请注意，绿色输入是对以前输出的引用。

最后，让我们将钱包类更新为：

可以汇总得到的余额（通过**循环遍历UTXO列表**并检查事务输出是否为`Mine()`）

并可以生成交易。

```
import java.security.*;
import java.security.spec.ECGenParameterSpec;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class Wallet {

   public PrivateKey privateKey;
   public PublicKey publicKey;

   public HashMap<String,TransactionOutput> UTXOs = new HashMap<String,TransactionOutput>();

   public Wallet() {
      generateKeyPair();
   }

   public void generateKeyPair() {
      try {
         KeyPairGenerator keyGen = KeyPairGenerator.getInstance("ECDSA","BC");
         SecureRandom random = SecureRandom.getInstance("SHA1PRNG");
         ECGenParameterSpec ecSpec = new ECGenParameterSpec("prime192v1");
         // Initialize the key generator and generate a KeyPair
         keyGen.initialize(ecSpec, random); //256 
           KeyPair keyPair = keyGen.generateKeyPair();
           // Set the public and private keys from the keyPair
           privateKey = keyPair.getPrivate();
           publicKey = keyPair.getPublic();

      }catch(Exception e) {
         throw new RuntimeException(e);
      }
   }

   public float getBalance() {
      float total = 0;   
        for (Map.Entry<String, TransactionOutput> item: ImportChain.UTXOs.entrySet()){
           TransactionOutput UTXO = item.getValue();
            if(UTXO.isMine(publicKey)) { //if output belongs to me ( if coins belong to me )
               UTXOs.put(UTXO.id,UTXO); //add it to our list of unspent transactions.
               total += UTXO.value ; 
            }
        }  
      return total;
   }

   public Transaction sendFunds(PublicKey _recipient,float value ) {
      if(getBalance() < value) {
         System.out.println("#Not Enough funds to send transaction. Transaction Discarded.");
         return null;
      }
      ArrayList<TransactionInput> inputs = new ArrayList<TransactionInput>();

      float total = 0;
      for (Map.Entry<String, TransactionOutput> item: UTXOs.entrySet()){
         TransactionOutput UTXO = item.getValue();
         total += UTXO.value;
         inputs.add(new TransactionInput(UTXO.id));
         if(total value) break;
      }

      Transaction newTransaction = new Transaction(publicKey, _recipient , value, inputs);
      newTransaction.generateSignature(privateKey);

      for(TransactionInput input: inputs){
         UTXOs.remove(input.transactionOutputId);
      }

      return newTransaction;
   }

}
```

你还可以添加一些其他功能到你的钱包类，比如保留记录你的交易历史记录等等。

## **6. 向块中添加交易**

现在已有了一个可以正常工作的交易处理系统，我们需要将它实现到我们的区块链中。我们把上一集中块里的无用的数据替换成一个交易列表，`arraylist`。

然而，在一个块中可能有1000个交易，太多的交易不能包括在散列计算中……

没事，别担心，我们可以使用交易的**merkle根**，就是下面的那个`getMerkleRoot()`方法。

现在在`StringUtils`中添加一个`helper`方法`getMerkleRoot()`：

```
public static String getMerkleRoot(ArrayList<Transaction> transactions) {
   int count = transactions.size();

   List<String> previousTreeLayer = new ArrayList<String>();
   for(Transaction transaction : transactions) {
      previousTreeLayer.add(transaction.transactionId);
   }
   List<String> treeLayer = previousTreeLayer;

   while(count 1) {
      treeLayer = new ArrayList<String>();
      for(int i=1; i < previousTreeLayer.size(); i+=2) {
         treeLayer.add(applySha256(previousTreeLayer.get(i-1) + previousTreeLayer.get(i)));
      }
      count = treeLayer.size();
      previousTreeLayer = treeLayer;
   }

   String merkleRoot = (treeLayer.size() == 1) ? treeLayer.get(0) : "";
   return merkleRoot;
}
```

现在，我们把`Block`类加强一下：

```
import java.util.ArrayList;
import java.util.Date;

public class Block {

   public String hash;
   public String previousHash;
   public String merkleRoot;
   public ArrayList<Transaction> transactions = new ArrayList<Transaction>(); //our data will be a simple message.
   public long timeStamp; //as number of milliseconds since 1/1/1970.
   public int nonce;

   //Block Constructor.
   public Block(String previousHash ) {
      this.previousHash = previousHash;
      this.timeStamp = new Date().getTime();

      this.hash = calculateHash(); //Making sure we do this after we set the other values.
   }

   //Calculate new hash based on blocks contents
   public String calculateHash() {
      String calculatedhash = StringUtil.applySha256(
            previousHash +
                  Long.toString(timeStamp) +
                  Integer.toString(nonce) +
                  merkleRoot
      );
      return calculatedhash;
   }

   //Increases nonce value until hash target is reached.
   public void mineBlock(int difficulty) {
      merkleRoot = StringUtil.getMerkleRoot(transactions);
      String target = StringUtil.getDificultyString(difficulty); //Create a string with difficulty * "0"
      while(!hash.substring( 0, difficulty).equals(target)) {
         nonce ++;
         hash = calculateHash();
      }
      System.out.println("Block Mined!!! : " + hash);
   }

   //Add transactions to this block
   public boolean addTransaction(Transaction transaction) {
      //process transaction and check if valid, unless block is genesis block then ignore.
      if(transaction == null) return false;
      if((previousHash != "0")) {
         if((transaction.processTransaction() != true)) {
            System.out.println("Transaction failed to process. Discarded.");
            return false;
         }
      }

      transactions.add(transaction);
      System.out.println("Transaction Successfully added to Block");
      return true;
   }

}
```

上面我们更新了`Block`构造函数，因为不再需要传入字符串数据（还记得[上集](http://mp.weixin.qq.com/s?__biz=MzA5MzQ2NTY0OA==&mid=2650797410&idx=1&sn=c16d1b0064768479a05dc65cf2b542d3&chksm=8856283dbf21a12be25300c012dc344199320f54a13b54d595c4db899d74ede95cb06d7e784c&scene=21#wechat_redirect)中我们的`Block`构造函数传入了一个`data`的字符串，这里我们往块里添加的是交易，也就是`transaction`），并且在计算哈希方法中包含了**merkle根**。

并且新增了`addTransaction`方法来添加一笔交易，并且只有在交易被成功添加时才返回`true`。

ok，我们的区块链上交易所需的每个零部件都实现了。是时候运转一下了。

## **7. 大结局**

现在我们开始测试吧。发送货币进出钱包，并更新我们的区块链有效性检查。

但首先我们需要一个方法来引入新的币。有许多方法可以创建新的币，比如，在**比特币区块链**上：矿工可以将交易持有在自己手里，作为对每个块被开采的奖励。

这里，我们将只发行（release）我们希望拥有的所有货币，在第一个块（起源块）。就像比特币一样，我们将对起源块进行硬编码。

现在把``类更新，包含如下内容：

- 一个“创世纪”的块，它向钱包A发行100个新币。
- 帐户交易中的“更新的链”的有效性检查。
- 一些测试信息，让我们看到内部运行的细节信息。

```
import java.security.Security;
import java.util.ArrayList;
import java.util.HashMap;

//import java.util.Base64;
//import com.google.gson.GsonBuilder;

public class ImportChain {

   public static ArrayList<Block> blockchain = new ArrayList<Block>();
   public static HashMap<String,TransactionOutput> UTXOs = new HashMap<String,TransactionOutput>();

   public static int difficulty = 3;
   public static float minimumTransaction = 0.1f;
   public static Wallet walletA;
   public static Wallet walletB;
   public static Transaction genesisTransaction;

   public static void main(String[] args) {
      //add our blocks to the blockchain ArrayList:
      Security.addProvider(new org.bouncycastle.jce.provider.BouncyCastleProvider()); //Setup Bouncey castle as a Security Provider

      //Create wallets:
      walletA = new Wallet();
      walletB = new Wallet();
      Wallet coinbase = new Wallet();

      //create genesis transaction, which sends 100 NoobCoin to walletA:
      genesisTransaction = new Transaction(coinbase.publicKey, walletA.publicKey, 100f, null);
      genesisTransaction.generateSignature(coinbase.privateKey);  //manually sign the genesis transaction
      genesisTransaction.transactionId = "0"; //manually set the transaction id
      genesisTransaction.outputs.add(new TransactionOutput(genesisTransaction.reciepient, genesisTransaction.value, genesisTransaction.transactionId)); //manually add the Transactions Output
      UTXOs.put(genesisTransaction.outputs.get(0).id, genesisTransaction.outputs.get(0)); //its important to store our first transaction in the UTXOs list.

      System.out.println("Creating and Mining Genesis block... ");
      Block genesis = new Block("0");
      genesis.addTransaction(genesisTransaction);
      addBlock(genesis);

      //testing
      Block block1 = new Block(genesis.hash);
      System.out.println("\nWalletA's balance is: " + walletA.getBalance());
      System.out.println("\nWalletA is Attempting to send funds (40) to WalletB...");
      block1.addTransaction(walletA.sendFunds(walletB.publicKey, 40f));
      addBlock(block1);
      System.out.println("\nWalletA's balance is: " + walletA.getBalance());
      System.out.println("WalletB's balance is: " + walletB.getBalance());

      Block block2 = new Block(block1.hash);
      System.out.println("\nWalletA Attempting to send more funds (1000) than it has...");
      block2.addTransaction(walletA.sendFunds(walletB.publicKey, 1000f));
      addBlock(block2);
      System.out.println("\nWalletA's balance is: " + walletA.getBalance());
      System.out.println("WalletB's balance is: " + walletB.getBalance());

      Block block3 = new Block(block2.hash);
      System.out.println("\nWalletB is Attempting to send funds (20) to WalletA...");
      block3.addTransaction(walletB.sendFunds( walletA.publicKey, 20));
      System.out.println("\nWalletA's balance is: " + walletA.getBalance());
      System.out.println("WalletB's balance is: " + walletB.getBalance());

      isChainValid();

   }

   public static Boolean isChainValid() {
      Block currentBlock;
      Block previousBlock;
      String hashTarget = new String(new char[difficulty]).replace('\0', '0');
      HashMap<String,TransactionOutput> tempUTXOs = new HashMap<String,TransactionOutput>(); //a temporary working list of unspent transactions at a given block state.
      tempUTXOs.put(genesisTransaction.outputs.get(0).id, genesisTransaction.outputs.get(0));

      //loop through blockchain to check hashes:
      for(int i=1; i < blockchain.size(); i++) {

         currentBlock = blockchain.get(i);
         previousBlock = blockchain.get(i-1);
         //compare registered hash and calculated hash:
         if(!currentBlock.hash.equals(currentBlock.calculateHash()) ){
            System.out.println("#Current Hashes not equal");
            return false;
         }
         //compare previous hash and registered previous hash
         if(!previousBlock.hash.equals(currentBlock.previousHash) ) {
            System.out.println("#Previous Hashes not equal");
            return false;
         }
         //check if hash is solved
         if(!currentBlock.hash.substring( 0, difficulty).equals(hashTarget)) {
            System.out.println("#This block hasn't been mined");
            return false;
         }

         //loop thru blockchains transactions:
         TransactionOutput tempOutput;
         for(int t=0; t <currentBlock.transactions.size(); t++) {
            Transaction currentTransaction = currentBlock.transactions.get(t);

            if(!currentTransaction.verifySignature()) {
               System.out.println("#Signature on Transaction(" + t + ") is Invalid");
               return false;
            }
            if(currentTransaction.getInputsValue() != currentTransaction.getOutputsValue()) {
               System.out.println("#Inputs are note equal to outputs on Transaction(" + t + ")");
               return false;
            }

            for(TransactionInput input: currentTransaction.inputs) {
               tempOutput = tempUTXOs.get(input.transactionOutputId);

               if(tempOutput == null) {
                  System.out.println("#Referenced input on Transaction(" + t + ") is Missing");
                  return false;
               }

               if(input.UTXO.value != tempOutput.value) {
                  System.out.println("#Referenced input Transaction(" + t + ") value is Invalid");
                  return false;
               }

               tempUTXOs.remove(input.transactionOutputId);
            }

            for(TransactionOutput output: currentTransaction.outputs) {
               tempUTXOs.put(output.id, output);
            }

            if( currentTransaction.outputs.get(0).reciepient != currentTransaction.reciepient) {
               System.out.println("#Transaction(" + t + ") output reciepient is not who it should be");
               return false;
            }
            if( currentTransaction.outputs.get(1).reciepient != currentTransaction.sender) {
               System.out.println("#Transaction(" + t + ") output 'change' is not sender.");
               return false;
            }

         }

      }
      System.out.println("Blockchain is valid");
      return true;
   }

   public static void addBlock(Block newBlock) {
      newBlock.mineBlock(difficulty);
      blockchain.add(newBlock);
   }
}
```

运行结果：

![img](https://cdn.yangbingdong.com/img/blockchain/blockchain09.webp)

> 代码链接：***[https://github.com/importsource/blockchain-samples-transaction/tree/master](https://github.com/importsource/blockchain-samples-transaction/tree/master)***
> 
> ***[原文链接](https://mp.weixin.qq.com/s?__biz=MzA5MzQ2NTY0OA==&mid=2650797427&idx=1&sn=ba11e0bbe90b4776b73412264856e98c&chksm=8856282cbf21a13ab4e3031d4ce1eb2ea6ce66fa6ea182f509a104f5d9258c3144f4be149886&mpshare=1&scene=1&srcid=0305A7seElVJKytsJ4qseFzp#rd)***
>

# 最热门的3个基于Java的Blockchain库

大家应该都听说过比特币、以太币或其他加密货币，这些名字在新闻中经常出现，但是作为Java开发人员，你们知道如何轻松地与Blockchain技术进行交互吗?下面是可以利用Blockchain的三大Java项目。这个列表是基于GitHub存储库的星序排列的。非常感谢你的评论和意见。

## BitcoinJ

你有没有觉得这个名字很有描述性呢?如果你想知道如何创建一个比特币钱包，并且管理节点之间的事务，那么你应该[尝试一下BitcoinJ](https://github.com/bitcoinj/bitcoinj)。这个项目有一个不断扩大的社区，里面包含非常好的文档资料，这对每个开发人员都是非常有利的。当然，作为一个试图获得声望的开源项目，它也存在一定的局限性。现在已经有几个已知的开放漏洞的安全问题，以及可扩展性问题。不过，如果你想了解比特币协议是如何运作的，这个项目将是非常有帮助的。个人意见:这并不适用于生产应用。

## Web3j

一个词——Ethereum（以太币），这是基于尖端技术的第二大加密货币。[Web3j项目](https://github.com/web3j/web3j)允许你使用Ethereum区块链，同时不必为平台编写集成代码。同样，核心功能是创建钱包，管理事务，以及智能合约包装器。Ethereum项目的一部分是一种称为[Solidity](https://solidity.readthedocs.io/)的特殊语言，它是创建智能合约的实际标准。如果你想避免使用智能合约的底层实现细节，那就使用Web3j的智能合约包装器。如果这对一名开发人员来说还不够，那我需要告诉你，它包含很多好的文档和大量的例子，这也是使web3j成为我个人最爱的原因。

## HyperLedger Fabric

[HyperLedger Fabric](https://github.com/hyperledger/fabric-sdk-java)是企业会用到的。Linux基金会的框架是区块链解决方案的主干。所以无论你想创建一个简单的PoC，还是一个生产应用程序，它都是一个强大的工具。该项目正在由Linux基金会成员积极组织开发。它的重点是创建和管理智能合约。主要特点是:

> 管理共享机密信息的渠道 
> 支持政策事务 
> 一致地向网络中的对等节点交付事务

如果你在软件区块链堆栈中包括了HyperLedger Fabric，那么我的建议是熟悉其他的HyperLedger项目。根据你的需要，可以选择各种不同的HyperLedger项目，这些项目将保证一个连贯的、可扩展的、易于维护的区块链基础设施。对于许多人来说，区块链将改变整个互联网，难道你不想成为其中的一部分吗?