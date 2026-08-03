# clavis-zsh-theme

独立的 Clavis Zsh prompt 包。它不依赖 `key-cli`，也不覆盖整个 `.zshrc`。

职责：prompt 程序、Zsh managed-block 接入、Matugen 颜色文件、备份、apply、卸载和
manifest。颜色在 apply/hook 时生成，prompt 绘制时只读取已生成文件，不启动 Matugen。

## 使用

```bash
./setup.sh doctor
./setup.sh configure
./setup.sh build
./setup.sh test
./setup.sh install
./setup.sh apply
./setup.sh uninstall
```

系统文件默认安装到 `/usr/local/share/clavis-zsh-theme/`，需要全局命令时放到
`/usr/local/bin/`。测试可以用 `CMAKE_INSTALL_PREFIX`、`DESTDIR` 和临时 `HOME`，不会
修改真实 `.zshrc`。apply 会先备份受影响文件到
`$XDG_STATE_HOME/clavis/backups/<timestamp>/`，managed block 重复执行幂等且可逆。

`/home/archirithm/prompt_dev` 是 prompt 的源码提供者。它当前工作树有用户未提交
修改，迁移只读取并复制文件，不会写回或覆盖该仓库；源文件保留其 prompt 功能、Git
状态栏、语言检测、宽度计算和测试。

来源仓库当前没有单独的 LICENSE 文件；本仓库保留其 README 中的功能说明和
`Archirithm/my_zsh_prompt` 来源链接，并在本包中新增的安装/Matugen 接入代码沿用
Clavis 的 GPL-3.0 项目许可。个人 `.zshrc`、截图和构建产物没有被复制。

## 与 Clavis Shell 的关系和未来 AUR

Shell/Matugen hook 只调用本仓库公开的 `apply` 接口；`key-cli` 仅作为官方组件编排器。
AUR 可把本仓库打包为独立 `clavis-zsh-theme`，不需要 Shell runtime 或 key daemon。
