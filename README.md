# MSIIP实验室服务器任务提交工具

基于[Oracle Grid Engine](https://en.wikipedia.org/wiki/Oracle_Grid_Engine)实现资源的统一管理和分配，提高计算资源的利用率。

相关工具均位于/home/share/bin下。



Grid Engine中记录了每台服务器的资源数量或大小，例如gpu=1,tensorflow=1,ram\_free=32G。用户提交任务到Grid Engine，
同时指定需要的资源数量或大小，Grid Engine自动选取符合资源要求的空闲机器用于计算，并扣除请求的资源量以避免冲突，任务结束时释放资源。
如果暂时没有符合要求的机器，任务将进入等待队列。

代码的实现与单机没有区别，只需要在命令前加上调度脚本和相关选项。

[toc]

## 调用方法

### 1. 一段时间内独享
请求本地资源在一段时间内的独享权。这种模式下会在本地执行一个sleep任务，声明对资源的占用。
除此之外，实验过程和过去一样。
适合代码实现和调试阶段，需要频繁修改和测试。

默认请求本地tensorflow资源（gpu同时被占用）180分钟。
建议不用的时候 **Ctrl-c** 提前释放资源（吃饭、睡觉 etc.）。

- 实例1：占用成功
``` bash
$ request --mem 120
```
``` plain
Requesting for tensorflow on x22 for 120 minutes
/home/share/bin/check.sh: tensorflow on x22.q is available now.

Got it at 2016 11 16  10:36:50 CST
Job has been submitted. Use 'qstat' to track the state.
Now running...
(log files: qlog/request_tensorflow_on_x22_20161116103650.log)
```
- 实例2：占用失败，显示当前占用该资源的任务和用户，进入等待状态
``` bash
$ request
```
``` plain
Requesting for tensorflow on x22 for 180 minutes
############################################################################
 - Running Jobs - Running Jobs - Running Jobs - Running Jobs - Running Jobs
############################################################################
 810070 0.50000 request_te chenzp       r     11/16/2016 10:36:59     1
       Full jobname:     request_tensorflow_on_x22_20161116103650.sh
       Master Queue:     x22.q@serverx22.msiip.thu.edu
       Hard Resources:   arch=*64* (0.000000)
                         ram_free=0M (0.000000)
                         mem_free=0M (0.000000)
                         tensorflow=1 (0.000000)
                         gpu=1 (0.000000)
       Soft Resources:
       Hard requested queues: x22.q
############################################################################
Waiting... (0 min)

```

###2. 本地执行 (TensorFlow)

``` bash
$ tf ./convolutional.py
```

###3. 自动分配 (TensorFlow)
适合批量实验。

###4. 自动分配 (通用)

###5. 多任务并行


###注意事项
实际执行任务的机器未知，因此要求与任务相关的程序和数据等放在NFS共享目录下，对所有机器可见，具体包括：

- 任务相关的可执行程序和脚本。对于Python脚本，依赖的库需要在所有机器上支持，C/C++程序连接的so文件在所有机器上存在且版本一致
- 输入文件和输出文件
- 当前目录。任务执行过程中会在./qlog目录下生成日志文件

=================================================================================

###余下部分仅供查阅

=================================================================================

## 参数选项
###request用法
请求独占本地资源
``` bash
$ request -h
```
``` plain
Usage: /home/share/bin/request [opts]
 e.g.: /home/share/bin/request --mem 2G --time 180
Options
  --res <tensorflow|gpu>   default: tensorflow
  --time <time in minutes> default: 180
  --mem <memory requested> default: 0M
```
###tf用法
执行TensorFlow相关任务，优先使用本地资源
``` bash
$ tf -h
```
``` plain
Usage: /home/share/bin/tf [opts] <command>
 e.g.: /home/share/bin/tf
Options
  --local-only <true|false>   if true, only use local TensorFlow
                              (default: true)
  --quiet <true|false>        if true, only outputs of the user command will be output
                              (default: true)
  --log <log-file-name>       default: log/job_YYYYmmddHHMMSS.log
```

###check.sh用法
检查某机器tensorflow是否被占用
``` bash
$ check.sh -h
```
``` plain
Usage: /home/share/bin/check.sh [opts] [x22|x27|...|x34|x35, default: local]
 e.g.: /home/share/bin/check.sh x35
Options
  --res <tensorflow|gpu>   default: tensorflow
  --wait <true|false>      default: false
```

###queue用法
提交任务到Grid Engine，可以灵活请求资源，可以多机多CPU并行
``` bash
$ queue -h
```
``` plain
Usage: queue.pl [options] [JOB=1:n] log-file command-line arguments...
e.g.: queue.pl foo.log echo baz
 (which will echo "baz", with stdout and stderr directed to foo.log)
 or: queue.pl -q all.q@xyz foo.log echo bar | sed s/bar/baz/
  (which is an example of using a pipe; you can provide other escaped bash constructs)
 or: queue.pl -q all.q@qyz JOB=1:10 foo.JOB.log echo JOB
  (which illustrates the mechanism to submit parallel jobs; note, you can use
   another string other than JOB)
Note: if you pass the "-sync y" option to qsub, this script will take note
and change its behavior.  Otherwise it uses qstat to work out when the job finished
Options:
  --config <config-file> (default: conf/queue.conf)
  --mem <mem-requirement> (e.g. --mem 2G, --mem 500M,
                           also support K and numbers mean bytes)
  --num-threads <num-threads> (default: 1)
  --max-jobs-run <num-jobs>
  --gpu <0|1> (default: 0)
  --tf <0|1> (default: 0)
```


# Grid Engine

常用命令
----------
* qstat 查看任务状态
* 列出我的任务  `$ qstat`
* 列出所有用户任务  `$ qstat -u '*'`
* 查看指定任务信息  `$ qstat -j <job-ID>`
* 常见state：正在运行 (r)、等待中 (qw)、出错 (Eqw)、挂起 (s)
* qdel删除任务 `$ qdel <job-ID>`

