# Canal Learning

1. 原理：模拟mysql slave的交互协议，伪装自己为mysql slave，向mysql master发送dump协议；mysql master收到dump请求，开始推送binary log给slave(也就是canal)；解析binary log对象(原始为byte流)
2. 重复消费问题：在消费端解决。
3. 采用开源的open-replicator来解析binlog
4. canal需要维护EventStore，可以存取在Memory, File, zk
5. canal需要维护客户端的状态，同一时刻一个instance只能有一个消费端消费
6. 数据传输格式：protobuff
7. 支持binlog format 类型:statement, row, mixed. 多次附加功能只能在row下使用，比如otter
8. binlog position可以支持保存在内存，文件，zk中
9. instance启动方式：rpc/http; 内嵌
10. 有ACK机制
11. 无告警，无监控，这两个功能都需要对接外部系统
12. 方便快速部署。