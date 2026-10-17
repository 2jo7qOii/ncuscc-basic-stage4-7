# 第七关：装好工具并读日志

一个最小 C 程序尚不能在当前环境正常构建。请修复构建环境和给定源码，使它符合输出要求。

源码为 /workspace/hello.c，提供的构建入口为 /workspace/build.sh；构建和运行日志分别位于 /workspace/build.log、/workspace/run.log。容器允许 root 管理软件包，APT 指向镜像内的离线仓库，仓库已备齐 build-essential 及其依赖。请在 /workspace/setup-build.sh 中记录可重复执行的环境配置。

程序接收一个由英文字母或数字组成的参数，正常退出时标准输出为 hello:<参数>，并向运行日志追加 processed:<参数>，两者均含结尾换行。

## 提交与通过条件

提交 setup-build.sh、修复后的 hello.c 和 /workspace/flag；flag 内容须等于程序在参数 foundation 下的标准输出。评测运行环境配置脚本两次，确认 build-essential 已安装且妨碍安装的练习包已被正常处理，保留 apt、libc 等基础包；随后重新编译，以多组参数检查程序退出码、输出和日志。

系统故障不计入有效作答次数；重建工作区会丢弃文件和进程，恢复本关发布版本的初始状态，请先备份需要保留的内容。
