# NCUSCC 基础入门 第四–七关

Linux / Shell / 系统管理练习的作答脚本，每关一个目录。

| 关卡 | 目录 | 提交物 | 考点 |
| --- | --- | --- | --- |
| 第四关 · 让命令找到路 | `level4-route/` | `route.sh` | 参数校验、环境变量、按接口探测调用外部工具、退出码约定 |
| 第五关 · 照看后台任务 | `level5-manage/` | `manage.sh` | 后台进程生命周期、PID 文件、单实例、TERM 终止 |
| 第六关 · 交给服务账号 | `level6-account/` | `setup-account.sh`、`flag` | 系统组/服务账号、幂等配置、属主与权限、真实换身份验证 |
| 第七关 · 装好工具并读日志 | `level7-build/` | `setup-build.sh`、`hello.c`、`flag` | APT 故障排查、包依赖、C 构建与输出约定 |

> **进度说明**：由于容器排队问题，未完成「基础入门」第八关之后的关卡。

## 说明

- 脚本均按 POSIX `sh` 或 `bash` 编写，入口带 `set -u` 一类的严格模式。
- 第六、七关的 `flag` 是评测环境生成的结果，一并保留以便对照。
- 各关目录下的 `README.md` 为原任务说明。
- 运行期产物（`*.log`、`worker.pid`、`resource.txt`、含 `ACCESS_TOKEN` 的 `job.env`）与编译产物已由 `.gitignore` 排除。

## 本地校验

```sh
# 语法检查
for f in */[a-z]*.sh; do sh -n "$f" 2>/dev/null || bash -n "$f"; echo "ok  $f"; done

# 第七关：源码可编译
gcc -std=c11 -Wall -Wextra -Werror -o /tmp/hello level7-build/hello.c
/tmp/hello foundation
```
