# 第六关：交给服务账号

归档任务需要交给专用服务账号完成。你以 root 身份进入本关容器，任务说明位于 /workspace/task.txt（TASK_FILE 也指向该文件）。请编写 /workspace/setup-account.sh，建立符合要求的账号及文件访问状态，并按任务说明生成收尾结果。

系统组名为 archive，服务账号名为 archiver。账号 UID 为 200–999，主组为 archive，不创建 home，登录 shell 为 /usr/sbin/nologin。

任务文件的属主、属组分别为 archiver、archive。所有者可读写，同组用户仅可读，其他用户无权限；archiver 必须能读取，预置 visitor 必须不能读取。

## 提交与通过条件

提交 setup-account.sh 和 /workspace/flag。脚本须可重复执行：已有符合要求的账号和组应复用；不符合要求的同名账号不能悄悄接受。评测在独立容器运行脚本两次，核对账号属性、home、文件归属与访问权限、两类账号的实际读取结果，以及任务说明要求的 flag。

系统故障不计入有效作答次数；重建工作区会丢弃文件和进程，恢复本关发布版本的初始状态，请先备份需要保留的内容。
