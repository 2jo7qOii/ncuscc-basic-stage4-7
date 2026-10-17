# 第五关：照看后台任务

编写 /workspace/manage.sh，为 /opt/recruitment/bin/slow-worker 提供可重复使用的进程管理接口。

脚本接收 start、status、report、stop，工作目录由 WORK_DIR 指定，PID 记录位于 $WORK_DIR/worker.pid。

start 应在 2 秒内返回 0；返回后 worker 持续运行并产生 heartbeat.log，重复启动不得产生第二个实例。status 在运行时输出 running 并退出 0，否则输出 stopped 并退出 1。stop 应使目标 worker 正常终止并留下 stopped.log；没有运行中的 worker 时也应成功，不能影响其他进程。未知命令输出 usage 并退出 64。

## 提交与通过条件

提交 manage.sh。report 在 worker 运行时退出 0，并生成 $WORK_DIR/resource.txt：首行为 PID=<实际PID>，随后依次包含该进程的 ps 状态信息和一次 top 快照，能识别目标 PID 与完整 worker 命令；瞬时资源数值不要求固定。未运行时 report 退出 1。评测检查持续运行、单实例、真实状态、报告内容，以及 TERM 终止后的记录。

系统故障不计入有效作答次数；重建工作区会丢弃文件和进程，恢复本关发布版本的初始状态，请先备份需要保留的内容。
