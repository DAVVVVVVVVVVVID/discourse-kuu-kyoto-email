# discourse-kuu-kyoto-email（给 Claude Code）

## 这是什么
- 京大中文论坛（KUU，Discourse 自托管）的京大邮箱插件：京大邮箱只用来注册和证明「我是京大学生」，注册后绑定常用邮箱接收通知；毕业后京大邮箱失效，账号照常使用
- 技术方案（需求、数据、设计、站点设置）：Notion「项目中心 › 项目文档 › 京大论坛｜京大邮箱插件技术方案」
  https://app.notion.com/p/3fd43ea2113c81109872f58fadfaa38b 。开发前先读这份方案；方案改了要同步更新 Notion，在改动处写日期
- 论坛的运维记录、待办、上线记录在另一个私有仓库：Windows 上的 `D:\PROJECT\KUU`（GitHub `kuu-forum`）。插件上线、线上改配置这些事要记在那边的 CHANGELOG 里
- 本仓库是**公开**的：不要提交任何密钥、服务器地址以外的敏感信息、用户数据（包括真实的京大邮箱）
- 写法可以参考同一个人做的评分插件 `~/discourse/plugins/discourse-kuu-ratings`（不要改它）

## 已确定的规则（不要自行改，要改先问 David）
1. 每个账号有两个邮箱：**京大认证邮箱**（`@st.kyoto-u.ac.jp`）和**常用邮箱**
2. 自行注册只能用京大邮箱；一个京大邮箱只能对应一个账号
3. 京大邮箱**只用于注册和身份认证**（延迟高、毕业后失效）。注册后尽快绑定常用邮箱，常用邮箱确认后**自动设为主邮箱**，之后所有通知都发到常用邮箱
4. 京大邮箱**不能删除、不能修改**（后端拦截，不只是前端藏按钮），直到注销账号
5. 注销账号后京大邮箱释放，可以再注册新账号
6. **京大邮箱明文保存，管理员能看到**
7. 没绑定常用邮箱的人：注册后第一次登录时弹窗提示（可跳过）→ 顶部一直显示提示条 → 每年毕业季发提醒邮件兜底
8. 不在本期：免京大邮箱注册（邀请链接 + 问卷 + 审核）。但「什么情况下允许非京大邮箱」要写成可扩展的判断

## core 里已经查清楚的事
- `allowed_email_domains` 不只管注册：`app/models/user_email.rb` 在邮箱变化时用 `EmailValidator` 校验，里面调 `EmailValidator.allowed?`，所以不装插件时用户加不了也改不了非京大邮箱。插件要在**不改 core** 的前提下放开
- 规则 2、5 core 已经满足：所有账号的所有邮箱全站查重；`normalize_emails` 默认开启，会去掉 `+` 后面的部分和点号再查重；删账号时 `user_emails` 一起删掉

## 开发环境
- 本仓库位于 WSL 的 `~/discourse/plugins/discourse-kuu-kyoto-email`，Discourse 源码在 `~/discourse`（官方仓库，不要改）
- 在 `~/discourse` 下执行：
  - `d/boot_dev`：启动容器；`d/shutdown_dev`：停止容器（不开发时停掉，本机内存只有 7.8GB）
  - `d/dev`：启动开发服务器，打开 http://localhost:3000
  - `d/rspec plugins/discourse-kuu-kyoto-email/spec`：跑本插件的测试
  - `d/rake db:migrate`，再执行 `RAILS_ENV=test d/rake db:migrate`：加了数据库迁移之后两个库都要跑；改了表结构还要跑一次 annotate（CI 的 annotations_tests 会检查）
  - `d/mailhog`：开发环境发的邮件在 http://localhost:8025 看（测「绑定常用邮箱」的确认邮件要用到）
  - lint 在容器里跑：`d/exec bin/lint --fix <文件...>`，路径相对 `~/discourse`
- `d/` 脚本都用 `docker exec -it`。没有终端时（比如后台运行）会报 `the input device is not a TTY`，那一步直接失败、脚本却显示成功。要用 `script -qec '命令' /dev/null` 包一层
- 开发服务器监测到 `plugins/` 下有变化会自动重启，文件改到一半时可能报错，改完再重启一次就好。评分插件也会同时被加载
- `plugin.rb` 的 `required_version` 保持 `2026.1.0`：本地和线上都是 `2026.10.0-latest`，按版本比较规则它比 `2026.10.0` 低，写成当前版本号插件就不会被激活，而设置照样加载，Rails 启动时报 `undefined method 'configurable?' for nil`
- 跑浏览器测试（spec/system）时 `d/dev` 要开着：测试环境的前端资源来自 `d/dev` 里的前端构建服务。`d/dev` 没开时，所有页面都返回 503，测试截图里一片空白（`frontend/discourse/dist/manifest/build.json` 里记的进程已经不在了）
- 用 `script -qec 'd/dev'` 在后台跑的开发服务器，结束本机这一端时容器里的 `node bin/dev`、pitchfork、rolldown 不会跟着退出，下次再起会报 `rolldown devserver is already running`。用 `docker exec discourse_dev ps -eo pid,ppid,args` 找到进程后按 pid `kill`（`pkill -f` 会连 `bash -c` 自己一起杀掉）
- 浏览器测试的 Playwright 环境问题、样式缓存问题，见评分插件 `CLAUDE.md` 的「开发环境」一节
- 插件的启用开关是站点设置 `kuu_kyoto_email_enabled`，默认关闭，开发环境要在后台打开
- 推送：WSL 里的 git 默认用 Windows 的 Git Credential Manager，会弹浏览器。本机 `gh` 已登录时可以临时借用它的凭据：`git -c credential.helper= -c credential.helper='!gh auth git-credential' push`
- 截图检查界面：用评分插件的 `script/screenshot.mjs`（用法见那个文件开头）。本地开发库里建了两个测试账号：`kyoto_student_test`（只有京大邮箱的普通用户）和 `kuu_admin_test`（管理员），密码都是 `kuu-local-test-pass-2026`，只存在本地开发库

## 约定
- Ruby 模块 `DiscourseKuuKyotoEmail`，接口挂在 `/kuu-kyoto-email`
- 代码标识符用英文；面向用户的文案放在 `config/locales/`（zh_CN 和 en 都要有）
- 跟着 Discourse 官方插件的写法走：前端用 Glimmer 组件（.gjs）和 plugin outlet，不要改 core
- 每个功能都要写测试（RSpec；前端交互用 system spec）
- 提交信息用中文；推送到 GitHub 之前先跑测试。线上 rebuild 会直接 clone main 的最新代码，所以 main 必须随时能上线，推送后确认 main 上的 CI 全部通过
- 部署到线上（改服务器 app.yml、rebuild）必须先得到 David 的同意，在 KUU 仓库那边操作和记录
- 规则相关的改动先问 David；纯技术细节自己定，写进 Notion 方案
- 用中文交流
