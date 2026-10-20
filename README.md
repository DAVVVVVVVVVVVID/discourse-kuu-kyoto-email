# discourse-kuu-kyoto-email

京大中文论坛（KUU）的京大邮箱插件。

- 只能用京都大学学生邮箱（`@st.kyoto-u.ac.jp`）自行注册，一个京大邮箱只能对应一个账号
- 京大邮箱**只用于注册和身份认证**：注册后绑定一个常用邮箱，常用邮箱确认后自动设为主邮箱，通知都发到常用邮箱
- 京大邮箱锁定在账号上，不能删除、不能修改，注销账号后才释放
- 没绑定常用邮箱的人会看到提示，毕业季还会收到提醒邮件
- 可选：京大邮箱注册的账号用 6 位激活码激活，激活邮件里不放任何链接（京大邮箱扫描链接会让邮件晚到几分钟）

## 设置

- `kuu_kyoto_email_enabled`：总开关，默认关闭。打开时自动给已有的京大邮箱账号补上「京大认证邮箱」
- `kuu_kyoto_email_banner_snooze_days`：提示条被关掉后几天再出现，默认 3
- `kuu_kyoto_email_reminder_dates`：毕业季提醒邮件的日期（月-日，日本时间），默认 `01-15|02-15|03-01`
- `kuu_kyoto_email_activation_code_enabled`：用激活码激活，默认关闭。关闭时照旧发带链接的激活邮件
- `kuu_kyoto_email_activation_code_ttl_minutes`：激活码有效期（分钟），默认 30

京大邮箱的域名取自 `allowed_email_domains`。

## 许可证

MIT
