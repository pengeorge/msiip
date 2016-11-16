# MSIIP实验室服务器任务提交工具

基于[Oracle Grid Engine](https://en.wikipedia.org/wiki/Oracle_Grid_Engine)实现资源的统一管理和分配，提高计算资源的利用率。

相关工具均位于/home/share/bin下，本文使用的样例程序在/home/share/bin/examples下。


Grid Engine中记录了每台服务器的资源数量或大小，例如gpu=1,tensorflow=1,ram\_free=32G。用户提交任务到Grid Engine，
同时指定需要的资源数量或大小，Grid Engine自动选取符合资源要求的空闲机器用于计算，并扣除请求的资源量以避免冲突，任务结束时释放资源。
如果暂时没有符合要求的机器，任务将进入等待队列。

代码的实现与单机没有区别，只需要在命令前加上调度脚本和相关选项。


## 调用方法

### 方法1: 一段时间内独享
请求本地资源在一段时间内的独享权。这种模式下会在本地执行一个sleep任务，声明对资源的占用。
之后可以以任意方式使用。

**适用场景**：小规模数据上调试程序，需要频繁修改代码和测试。

长时间的任务建议用其他调用方法。

默认请求本地tensorflow资源（gpu同时被占用）180分钟。
建议不用的时候 **Ctrl-c** 提前释放资源（吃饭、睡觉 etc.）。

**基本用法**：request [opts]

**完整用法**：`$ request -h`

- 实例1：请求成功
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
- 实例2：请求失败，显示当前占用该资源的任务和用户，进入等待状态
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

### 方法2: 本地执行 (TensorFlow) (推荐)
用本地资源执行任务，可以即时打印stdout和stderr，同时把stdout的输出写到log文件中（默认为qlog/job\_xxxxxx.log）。任务完成后自动释放资源。

**适用场景**：比较耗时的任务，需要关注即时输出的时候。

**基本用法**： tf [opts] \<your-command\> \[your-command-opts\] \[your-command-args\]

**完整用法**： `$ tf -h`

- 实例1：本地资源可用时正常执行
``` bash
$ tf ./convolutional.py
```
``` plain
I tensorflow/stream_executor/dso_loader.cc:111] successfully opened CUDA library libcublas.so locally
I tensorflow/stream_executor/dso_loader.cc:111] successfully opened CUDA library libcudnn.so locally
I tensorflow/stream_executor/dso_loader.cc:111] successfully opened CUDA library libcufft.so locally
...
...
Step 8500 (epoch 9.89), 17.1 ms
Minibatch loss: 1.619, learning rate: 0.006302
Minibatch error: 1.6%
Validation error: 0.9%
Test error: 0.8%
Done. log was saved in ./qlog/job_20161116135159.log
Terminated
/home/share/bin/request: line 2:   306 Terminated              queue.pl --qdel-on-Eqw -q $local_q -l $l_opt $logfile sleep $[time*60]
```
（这个方法最后可能会输出一些Terminated等信息，是正常现象）

- 实例2：本地资源不可用时中断，建议尝试“方法3“，使用其他机器的资源
``` bash
$ tf ./convolutional.py
```
``` plain
############################################################################
 - Running Jobs - Running Jobs - Running Jobs - Running Jobs - Running Jobs
############################################################################
 810081 0.50000 request_te chenzp       r     11/16/2016 13:56:59     1
       Full jobname:     request_tensorflow_on_x22_20161116135658.sh
       Master Queue:     x22.q@serverx22.msiip.thu.edu
       Hard Resources:   arch=*64* (0.000000)
                         ram_free=0M (0.000000)
                         mem_free=0M (0.000000)
                         tensorflow=1 (0.000000)
                         gpu=1 (0.000000)
       Soft Resources:
       Hard requested queues: x22.q

Local TensorFlow is not available.
Try '/home/share/bin/tf --local-only false <log-file> <command>'
```

### 方法3: 自动分配 (TensorFlow)
这种调用方法首先会尝试方法2，若本地资源不可用，任务会被提交到Grid Engine执行，自动请求空闲机器的资源。

**适用场景**：批量运行的TensorFlow实验；或尝试方法2失败时。

**缺点**
- 方法3、4、5无法在前端即时打印输出，需要打开log文件查看。可以用下面命令每隔5秒自动刷新：
``` bash
$ while :; do clear; tail <path-to-log>; sleep 5; done
```
  请远程到log文件实际所在的机器执行该命令，减少网络传输。
- 若执行任务的机器和数据所在机器不同，I/O密集时会阻塞网络。

**实例**
``` bash
$ tf --local-only false ./convolutional.py
```
``` plain
############################################################################
 - Running Jobs - Running Jobs - Running Jobs - Running Jobs - Running Jobs
############################################################################
 810081 0.50000 request_te chenzp       r     11/16/2016 13:56:59     1
       Full jobname:     request_tensorflow_on_x22_20161116135658.sh
       Master Queue:     x22.q@serverx22.msiip.thu.edu
       Hard Resources:   arch=*64* (0.000000)
                         ram_free=0M (0.000000)
                         mem_free=0M (0.000000)
                         tensorflow=1 (0.000000)
                         gpu=1 (0.000000)
       Soft Resources:
       Hard requested queues: x22.q

Local TensorFlow is not available.
Submitting to queue...
Job has been submitted. Use 'qstat' to track the state.
Now running...
(log files: ./qlog/job_20161116143235.log)
Job finished.
```

log文件中保存了任务的所有stdout和stderr输出、执行任务的机器、开始时间、结束时间、退出状态。
``` bash
$ head ./qlog/job_20161116143235.log
```
``` plain
# Running on serverx27
# Started at Wed Nov 16 14:32:39 CST 2016
# ./convolutional.py
I tensorflow/stream_executor/dso_loader.cc:111] successfully opened CUDA library libcublas.so locally
I tensorflow/stream_executor/dso_loader.cc:111] successfully opened CUDA library libcudnn.so locally
I tensorflow/stream_executor/dso_loader.cc:111] successfully opened CUDA library libcufft.so locally
I tensorflow/stream_executor/dso_loader.cc:111] successfully opened CUDA library libcuda.so.1 locally
I tensorflow/stream_executor/dso_loader.cc:111] successfully opened CUDA library libcurand.so locally
I tensorflow/core/common_runtime/gpu/gpu_device.cc:951] Found device 0 with properties:
name: GeForce GTX 780
```
``` bash
$ tail ./qlog/job_20161116143235.log
```
``` plain
Minibatch loss: 1.597, learning rate: 0.006302
Minibatch error: 0.0%
Validation error: 0.8%
Step 8500 (epoch 9.89), 13.5 ms
Minibatch loss: 1.623, learning rate: 0.006302
Minibatch error: 1.6%
Validation error: 0.9%
Test error: 0.8%
# Accounting: time=120 threads=1
# Finished at Wed Nov 16 14:34:39 CST 2016 with status 0
```

### 注意事项
- 方法3、4、5实际执行任务的机器未知，因此要求把任务相关的程序和数据放在NFS共享目录下，对所有机器可见，具体包括：
 - 任务相关的可执行程序和脚本。Python脚本的依赖库需要在所有机器上支持，C/C++程序连接的so文件需要在所有机器上存在且版本一致
 - 输入文件和输出文件
 - 当前目录。任务执行过程中需要在./qlog目录下写log文件
- 显卡资源紧张，尽量将不需要使用显卡的耗时操作独立出来（如数据预处理、后处理等等），只对必要的环节请求资源。

### 方法4: 自动分配 (通用)
可以指定执行任务的服务器（群），请求内存、GPU、TensorFlow等资源。

**基本用法**： queue [opts] \<log-file\> \<your-command\> \[your-command-opts\] \[your-command-args\]

**完整用法**：`$ queue -h`

- 实例1：运行其他需要要GPU支持的程序
``` bash
$ queue -l gpu=1 <a-gpu-required-program>
```

- 实例2: 内存需求较大的任务
``` bash
$ queue -l ram_free=10G,mem_free=10G <a-memory-killer-program>
```

- 实例3：在x34上处理x32通过NFS共享过来的大量数据，指定使用x32计算，避免网络传输
``` bash
$ queue -q x32.q -l ram_free=1G,mem_free=1G data-processer /home/share/my_big_data.dat /home/share/my_output.txt
```

###方法5: 多任务并行
把任务分成若干份，提交到Grid Engine，实现多机多核并行计算，最后汇总。
请求资源（每一份任务需要的资源）的方法同上。

**基本用法**： queue [opts] JOB=1:n \<log-file-JOB\> \<your-command\> \[your-command-opts\] \[your-command-args\]

**完整用法**：`$ queue -h`

- 实例：统计文本中词的总数

首先将文本数据分成7份：data/text/text.1.txt ~ data/text/text.7.txt，
在queue的参数中加入JOB=1:7，输入文件用data/text/text.JOB.txt表示，相应的log文件和输出文件名也要带上JOB加以区分

处理每份数据用的脚本wordcount.sh
``` bash
#!/bin/bash
# wordcount.sh
sleep 20
cat $1 | wc -c
```

统计总词数的脚本wordcount\_all.sh
``` bash
#!/bin/bash
# wordcount_all.sh
queue JOB=1:7 ./qlog/wordcount.JOB.log ./wordcount.sh data/text/text.JOB.txt '>' data/text/wc_result.JOB.txt
cat data/text/wc_result.*.txt | awk '{s+=$1}END{print "Total word count is ",s}'
```

运行
``` bash
$ ./wordcount_all.sh
```
``` plain
Job has been submitted. Use 'qstat' to track the state.
Now running...
(log files: ./qlog/wordcount.*.log)
Job finished.
Total word count is  34542473
```

任务运行过程中可以用qstat查看状态
``` bash
$ qstat
```
``` plain
job-ID  prior   name       user         state submit/start at     queue                          slots ja-task-ID
-----------------------------------------------------------------------------------------------------------------
 810088 0.50000 wordcount. chenzp       r     11/16/2016 15:43:54 all.q@serverx32.msiip.thu.edu      1 1
 810088 0.50000 wordcount. chenzp       r     11/16/2016 15:43:54 all.q@serverx22.msiip.thu.edu      1 2
 810088 0.50000 wordcount. chenzp       r     11/16/2016 15:43:54 gpu.q@serverx33.msiip.thu.edu      1 3
 810088 0.50000 wordcount. chenzp       r     11/16/2016 15:43:54 all.q@serverx35.msiip.thu.edu      1 4
 810088 0.50000 wordcount. chenzp       r     11/16/2016 15:43:54 all.q@serverx27.msiip.thu.edu      1 5
 810088 0.50000 wordcount. chenzp       r     11/16/2016 15:43:54 all.q@serverx34.msiip.thu.edu      1 6
 810088 0.50000 wordcount. chenzp       r     11/16/2016 15:43:54 all.q@serverx29.msiip.thu.edu      1 7
```
### 复杂命令的调用方法
任务的执行命令传递到tf/queue等脚本中时可能存在特殊转换的问题，下面举几个例子。
- 复杂命令样例1：带重定向或管道等特殊符号
  例如下面这条命令
  ``` bash
  $ cat /etc/passwd | grep ^chen > ./user_chen.txt
  ```
  用tf调用时，可以对整句命令加引号
  ``` bash
  $ tf 'cat /etc/passwd | grep ^chen > ./user_chen.txt'
  ```
  或者只对特殊符号加引号
  ``` bash
  $ tf cat /etc/passwd '|' grep ^chen '>' ./user_chen.txt
  ```

  用queue调用时，只能在特殊符号外加单引号
  ``` bash
  $ queue qlog/find_chen.log cat /etc/passwd '|' grep ^chen '>' ./user_chen.txt
  ```
  ``` bash
  $ cat ./user_chen.txt
  ```
  ``` plain
  chenzp:x:1001:1001:,,,:/home/chenzp:/bin/bash
  chenty:x:1003:1001:,,,:/home/chenty:/bin/bash
  ```
- 复杂命令样例2：带引号的命令
  ``` bash
  $ ./complicated.sh --op1 new_op1 --op2 "op2 with spaces" arg1_value "arg2 value with spaces"
  ```
  输出
  ``` plain
  op1 = new_op1
  op2 = op2 with spaces
  op3 = default_op3
  arg1 = arg1_value
  arg2 = arg2 value with spaces
  ```
  用tf调用，对整句命令加引号
  ``` bash
  $ tf './complicated.sh --op1 new_op1 --op2 "op2 with spaces" arg1_value "arg2 value with spaces"'
  ```

*选项和参数过于复杂的命令，建议包装在shell脚本里，再用tf/queue调用*



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
 e.g.: /home/share/bin/tf --log mylog.txt sleep 60
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
提交任务到Grid Engine，可以灵活请求资源，可以多机多核并行
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


# Grid Engine 常用命令
- qstat 查看任务状态
 - 列出我的任务  `$ qstat`
 - 列出所有用户任务  `$ qstat -u '*'`
 - 查看某任务信息  `$ qstat -j <job-ID>`
 - 查看某资源在某机器上的信息  `$ qstat -F tf -q x22.q`
 - 常见state：正在运行 (r)、等待中 (qw)、出错 (Eqw)、挂起 (s)
- qdel 删除任务  `$ qdel <job-ID>`
- qsub 提交任务（已封装进queue）
- qhost 查看所有机器状态（CPU、内存、交换区）
- 查看某机器的资源总量  `$ qconf -se serverx22 | grep complex_values`

