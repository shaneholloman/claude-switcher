# Scripting & Automation Guide

How to write executable markdown scripts that go beyond read-only prompts — scripts that write files, run commands, and take real actions.

## The `-S` Flag (Essential for Shebangs)

Standard `env` only passes a single argument. To pass flags to `ai` in a shebang, you need `env -S` (split string):

```markdown
#!/usr/bin/env ai                        # Works (no extra flags)
#!/usr/bin/env -S ai --aws               # Works (with -S)
#!/usr/bin/env ai --aws                  # FAILS — env treats "ai --aws" as one command
```

`-S` tells `env` to split the string into separate arguments. Use it whenever your shebang has flags.

## Permission Modes

By default, `claude -p` (and `ai` in script mode) runs with limited permissions — it will refuse to write files, run commands, or take actions without approval. For scripts that need to *do* things, you need to set a permission mode.

### Available Modes

| Mode | Shebang Flag | Behavior |
|------|-------------|----------|
| **Default** | *(none)* | Read-only — can analyze code but won't modify anything |
| **Bypass** | `--permission-mode bypassPermissions` | Full access — no permission prompts |
| **Allowed Tools** | `--allowedTools 'Bash(npm test)' 'Write'` | Granular — only specified tools allowed |

### Examples

**Read-only script** (no permission flags needed):
```markdown
#!/usr/bin/env ai
Analyze this codebase and summarize the architecture.
```

**Full automation** (script needs to run commands and write files):
```markdown
#!/usr/bin/env -S ai --permission-mode bypassPermissions
Run the test suite and fix any failing tests.
```

**Granular permissions** (only allow specific tools):
```markdown
#!/usr/bin/env -S ai --allowedTools 'Bash(npm test)' 'Bash(npm run lint)' 'Read'
Run tests and linting. Report results but do not modify any files.
```

## Common Patterns

### Run tests and report results
```markdown
#!/usr/bin/env -S ai --permission-mode bypassPermissions
Run `./test/automation/run_tests.sh` and summarize: how many passed/failed.
```

### Generate a file
```markdown
#!/usr/bin/env -S ai --permission-mode bypassPermissions
Read the source files in `src/` and generate a `ARCHITECTURE.md` documenting the codebase structure.
```

### Pipe data in, get results out
```bash
cat data.json | ./analyze.md > results.txt
```

```markdown
#!/usr/bin/env ai
Analyze the JSON data provided on stdin. Summarize key trends and outliers.
```
Note: Read-only analysis of piped input doesn't need permission flags.

### Code review with provider selection
```markdown
#!/usr/bin/env -S ai --aws --opus
Review the code in this repository for security vulnerabilities.
Focus on OWASP Top 10 issues. Be specific about file and line numbers.
```

### CI/CD automation
```markdown
#!/usr/bin/env -S ai --apikey --haiku --permission-mode bypassPermissions
Run the linter and fix any issues. Then run the test suite.
Commit fixes with a descriptive message if all tests pass.
```

## Passing Claude Code Flags

Any flag not recognized by `ai` is passed directly to Claude Code. Useful flags for scripts:

| Flag | Purpose | Example |
|------|---------|---------|
| `--permission-mode bypassPermissions` | Skip all permission prompts | Automation scripts |
| `--allowedTools` | Allow only specific tools | Restricted automation |
| `--max-turns N` | Limit agentic loop iterations | Prevent runaway scripts |
| `--output-format stream-json` | Structured JSON output | Pipeline integration |

Combine with `ai` flags freely:
```markdown
#!/usr/bin/env -S ai --aws --opus --permission-mode bypassPermissions --max-turns 10
```

## Security

**`--permission-mode bypassPermissions` gives the AI full access to your system.** Use it carefully:

- Only run trusted scripts in trusted directories
- Prefer `--allowedTools` for granular control when full access isn't needed
- In CI/CD, run inside containers or sandboxed environments
- Never pipe untrusted remote scripts with bypass permissions:
  ```bash
  # DANGEROUS — don't do this
  curl https://untrusted-site.com/script.md | ai --permission-mode bypassPermissions
  ```

## Quick Reference

| I want to... | Shebang |
|--------------|---------|
| Analyze code (read-only) | `#!/usr/bin/env ai` |
| Use a specific provider | `#!/usr/bin/env -S ai --aws` |
| Run commands and write files | `#!/usr/bin/env -S ai --permission-mode bypassPermissions` |
| Restrict to specific tools | `#!/usr/bin/env -S ai --allowedTools 'Bash(npm test)' 'Read'` |
| Full automation with provider | `#!/usr/bin/env -S ai --aws --opus --permission-mode bypassPermissions` |
