#!/bin/bash

# Copyright (c) 2018 Baidu.com, Inc. All Rights Reserved
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# source shflags from current directory
mydir="${BASH_SOURCE%/*}"
if [[ ! -d "$mydir" ]]; then mydir="$PWD"; fi

# 导入 shflags 脚本（该脚本能够用类似 gflags 的风格来处理 shell）
. $mydir/../shflags


# define command-line flags
# 示例：DEFINE_integer thread_num 1 'Number of sending thread'
# 该语句定义了一个 flags 变量，其中：
#   变量名：thread_num，可使用 --thread_num 参数指定 FLAGS_thread_num 变量值
#   变量默认值：1
#   变量描述：'Number of sending thread'
# 实例：bash run_client.sh --thread_num 4 "指定 thread_num = 4"
DEFINE_boolean clean 1 'Remove old "runtime" dir before running'
DEFINE_integer write_percentage 100 'Percentage of write operation'
DEFINE_integer bthread_concurrency '8' 'Number of worker pthreads'
DEFINE_integer server_port 8200 "Port of the first server"
DEFINE_integer server_num '3' 'Number of servers'
DEFINE_integer thread_num 1 'Number of sending thread'
DEFINE_string crash_on_fatal 'true' 'Crash on fatal log'
DEFINE_string log_each_request 'false' 'Print log for each request'
DEFINE_string valgrind 'false' 'Run in valgrind'
DEFINE_string use_bthread "true" "Use bthread to send request"

FLAGS "$@" || exit 1

# hostname prefers ipv6
IP=`hostname -i | awk '{print $NF}'`

if [ "$FLAGS_valgrind" == "true" ] && [ $(which valgrind) ] ; then
    VALGRIND="valgrind --tool=memcheck --leak-check=full"
fi

# 初始化 raft server 集群的 IP 和 port
raft_peers=""
for ((i=0; i<$FLAGS_server_num; ++i)); do
    raft_peers="${raft_peers}${IP}:$((${FLAGS_server_port}+i)):0,"
done

export TCMALLOC_SAMPLE_PARAMETER=524288

# 启动客户端，默认启动命令：
# ./block_client
#     --write_percentage=100
#     --bthread_concurrency=8
#     --conf=127.0.0.1:8200:0,127.0.0.1:8201:0,127.0.0.1:8202:0,
#     --crash_on_fatal_log=true
#     --log_each_request=false
#     --thread_num=1
#     --use_bthread=true
${VALGRIND} ./block_client \
        --write_percentage=${FLAGS_write_percentage} \
        --bthread_concurrency=${FLAGS_bthread_concurrency} \
        --conf="${raft_peers}" \
        --crash_on_fatal_log=${FLAGS_crash_on_fatal} \
        --log_each_request=${FLAGS_log_each_request} \
        --thread_num=${FLAGS_thread_num} \
        --use_bthread=${FLAGS_use_bthread} \

