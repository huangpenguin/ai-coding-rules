# Core Pack

`core` 是默认 pack。直接运行 `init-ai` 时只注入这一组文件。

包含：

- Cursor rules: `.cursor/rules/`
- Claude / 兼容规则: `CLAUDE.md`、`.cursorrules`
- 项目记忆入口: `MEMORY.md`、`.cursor/project-context/`、`.cursor/lessons-learned/`

适合：

- 刚 clone 下来的 legacy 项目，例如 BasicSR 第一阶段试训。
- 只想让 Cursor / Claude Code 读到项目规则，不想引入 Docker / CI。

命令：

```bash
init-ai
```
