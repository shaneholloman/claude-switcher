# Claude Switcher

A collection of scripts to easily switch between different authentication modes and providers for [Claude Code](https://claude.ai/code).

## Features

- **Multiple Providers**: Support for Anthropic API, AWS Bedrock, Google Vertex AI, and Microsoft Foundry on Azure.
- **Model Switching**: Easily switch between Sonnet 4.5, Opus 4.1, Haiku 4.5, or custom models.
- **Pro Plan Support**: Toggle back to standard Claude Pro web authentication.
- **Seamless Switching**: Switch between providers and authentication methods without logout flows.
- **Session Management**: Unique session IDs for tracking.
- **Secure Configuration**: API keys stored in a separate, git-ignored file.
- **System-Wide Access**: Scripts are installed to `/usr/local/bin` for easy access.

## How It Works

Claude Switcher uses two complementary approaches for provider switching:

### API Key Helper (Anthropic API ↔ Pro/Max)

For switching between **Claude Pro/Max subscription** and **Anthropic native API key**, claude-switcher uses Claude Code's `apiKeyHelper` setting **non-destructively**:

1. **First `claude-anthropic` run**: Adds `apiKeyHelper` to `~/.claude/settings.json` (backed up first)
2. **Mode tracking** in `~/.claude-switcher/current-mode.sh` stores your current provider (`pro` or `anthropic`)
3. **Dynamic authentication**: The helper script returns your API key in `anthropic` mode, or nothing in `pro` mode (enabling web auth)
4. **Running `claude-pro`**: Removes `apiKeyHelper` from settings.json, restoring original behavior
5. **Plain `claude` unaffected**: Always works as it did before installation, unless you've explicitly run `claude-anthropic`

**Key**: The switcher never modifies settings.json during installation—only when you explicitly choose to use Anthropic API mode
### Environment Variables (AWS, Vertex AI, Azure)

For **AWS Bedrock**, **Google Vertex AI**, and **Microsoft Foundry on Azure**, switching is even simpler:

- Each provider has a dedicated environment variable (`CLAUDE_CODE_USE_BEDROCK`, `CLAUDE_CODE_USE_VERTEX`, `CLAUDE_CODE_USE_FOUNDRY`)
- Setting these automatically disables `/login` and `/logout` commands
- No apiKeyHelper needed—Claude Code natively supports these providers
- Scripts just set the appropriate environment variables and launch Claude Code

**Result**: Seamless switching between any provider without logout flows, browser prompts, or authentication friction.

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/andisearch/claude-switcher.git
cd claude-switcher
```

### 2. Run the Setup Script
This script will:
- Install commands to `/usr/local/bin` for system-wide access
- Create your configuration directory at `~/.claude-switcher/`
- Install the API key helper script (but NOT activate it yet)
- **Does NOT modify** your existing `~/.claude/settings.json`

You may be prompted for your password to allow installation to system directories.

```bash
./setup.sh
```

> **Important**: Setup does NOT modify your Claude configuration. Plain `claude` continues to work exactly as before. The apiKeyHelper is only activated when you explicitly run `claude-anthropic` for the first time, and is removed when you run `claude-pro`.

### 3. Configure Your Secrets
The setup script creates a secrets file at `~/.claude-switcher/secrets.sh`. You must edit this file to add your API keys and credentials.

```bash
nano ~/.claude-switcher/secrets.sh
```

#### Adding API Keys
Uncomment and fill in the sections for the providers you wish to use:

**AWS Bedrock:**

Multiple authentication methods supported (see [official docs](https://code.claude.com/docs/en/amazon-bedrock)):

```bash
# Option 1: AWS Bedrock API Key (recommended for simplicity)
export AWS_BEARER_TOKEN_BEDROCK="your-bedrock-api-key"
export AWS_REGION="us-west-2"

# Option 2: AWS Access Keys
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-west-2"

# Option 3: AWS Profile
export AWS_PROFILE="your-profile-name"
export AWS_REGION="us-west-2"
```
> **Note**: `AWS_REGION` is required for all auth methods. Scripts validate authentication is configured before launching.

**Google Vertex AI:**

**Setup Steps:**
1. **Install Google Cloud SDK**: [Download here](https://cloud.google.com/sdk/docs/install)
2. **Authenticate**: Run `gcloud auth application-default login`
3. **Enable Vertex AI API**: [Click to enable](https://console.cloud.google.com/flows/enableapi?apiid=aiplatform.googleapis.com)
4. **Enable Claude Models**: [Open Model Garden](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4) and click "Enable" on models you want to use
5. **Configure secrets.sh**:
   ```bash
   export ANTHROPIC_VERTEX_PROJECT_ID="your-gcp-project-id"
   export CLOUD_ML_REGION="global"
   ```

> **Optional**: Set specific regions per model (defaults to `CLOUD_ML_REGION`):
> ```bash
> export VERTEX_REGION_CLAUDE_4_5_SONNET="us-east5"
> export VERTEX_REGION_CLAUDE_4_1_OPUS="global"
> ```
>
> **Note**: Models are region-specific. Check [availability](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden) in your region.

**Anthropic API:**
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```
> **Note**: Scripts validate that `ANTHROPIC_API_KEY` is set before launching.

**Microsoft Foundry on Azure:**

Announced November 18, 2024 ([blog post](https://www.anthropic.com/news/claude-in-microsoft-foundry)).

**Setup Steps:**
1. **Create Azure Resource**: Navigate to [Microsoft Foundry portal](https://ai.azure.com/)
2. **Deploy Models**: Create deployments for Claude Opus, Sonnet, and/or Haiku
3. **Get Credentials**: From your resource's "Endpoints and keys" section
4. **Configure secrets.sh**:
   ```bash
   # Option 1: API Key (simpler)
   export ANTHROPIC_FOUNDRY_API_KEY="your-azure-api-key"
   export ANTHROPIC_FOUNDRY_RESOURCE="your-resource-name"
   
   # Option 2: Azure CLI (az login)
   export ANTHROPIC_FOUNDRY_RESOURCE="your-resource-name"
   # Then run: az login
   
   # Set your deployment names (must match what you created in Azure)
   export CLAUDE_MODEL_SONNET_AZURE="claude-sonnet-4-5"
   export CLAUDE_MODEL_HAIKU_AZURE="claude-haiku-4-5"
   export CLAUDE_MODEL_OPUS_AZURE="claude-opus-4-1"
   ```

> **Note**: Model names in Azure are your custom deployment names, not the standard model IDs.

#### Overriding Defaults (Optional)
You can override default model IDs or regions in the same `secrets.sh` file. This is useful for testing new models or using custom endpoints.

**Example: Override AWS Region and Model**
```bash
export AWS_REGION="us-east-1"
export CLAUDE_MODEL_SONNET_AWS="global.anthropic.claude-sonnet-4-5-20250929-v1:0"
```

## Switching Providers to Avoid Rate Limits

**This is the killer feature.** Claude Pro has rate limits that reset every 5 hours. When you hit a limit mid-task, instantly switch to your own API and keep working.

### Quick Switch with `--resume`

```bash
# Working with Claude Pro, hit rate limit
claude
# "Rate limit exceeded. Try again in 4 hours 23 minutes."

# Immediately continue with AWS (keeps conversation context)
claude-aws --resume

# Or switch to Haiku for speed/cost
claude-aws --haiku --resume

# Or switch to Opus for complex reasoning
claude-aws --opus --resume

# Or use Vertex AI
claude-vertex --resume
```

The `--resume` flag lets you pick up your last conversation exactly where you left off (or any recent conversation). No lost context, no restarting explanations.

### Common Workflows

**Hit Pro limit mid-debugging:**
```bash
claude-aws --resume  # Continue on your AWS credits
```

**Need faster responses:**
```bash
claude-aws --haiku --resume  # Switch to Haiku for speed
```

**Large codebase analysis:**
```bash
claude-anthropic --opus --resume  # Upgrade to Opus for complex reasoning
```

**Back to Pro when limits reset:**
```bash
claude --resume  # Resume on your default Pro or Max plan
```

### Why This Works

- **Claude Pro**: Great for normal work, but limited (10-40 prompts per 5-hour window)
- **Your API**: Unlimited usage, pay per token. Allows you to use cloud credits.
- **Instant switching**: One command, same conversation
- **No friction**: The only thing stopping you from switching was how annoying it was. Not anymore.


## Usage

Once installed, you can use the following commands from any terminal window.

### AWS Bedrock
```bash
# Use default model (Sonnet 4.5 - latest)
claude-aws

# Use Opus 4.1 (most capable for planning and reasoning)
claude-aws --opus

#Use Haiku 4.5 (fastest, most cost-effective)
claude-aws --haiku

# Use a custom model ID
claude-aws --model "global.anthropic.claude-sonnet-4-5-20250929-v1:0"
```

### Google Vertex AI
```bash
# Use default model (Sonnet 4.5 - latest)
claude-vertex

# Use Opus (most capable for planning and reasoning)
claude-vertex --opus

# Use Haiku (fastest, most cost-effective)
claude-vertex --haiku
```

### Anthropic API
```bash
# Use default model (Sonnet 4.5 - latest)
claude-anthropic

# Use Opus (most capable for planning and reasoning)
claude-anthropic --opus

# Use Haiku (fastest, most cost-effective)
claude-anthropic --haiku
```

### Microsoft Foundry on Azure
```bash
# Use default model (Sonnet deployment)
claude-azure

# Use Opus deployment
claude-azure --opus

# Use Haiku deployment
claude-azure --haiku

# Use custom deployment name
claude-azure --model "my-custom-deployment"
```

### Claude Pro Plan
```bash
# Switch back to standard web auth (default Claude Code behavior)
claude-pro

# OR simply run claude directly
# This works because the switcher scripts only affect the current command execution
claude
```

### Utilities

#### `claude-status`
Shows your current Claude Code authentication configuration with mode-specific details:

```bash
claude-status
```

**Detects and displays:**
- **AWS Bedrock**: Shows region, API token status, model settings, and output token limits
- **Vertex AI**: Shows GCP project, location, authentication status, and active gcloud account
- **Anthropic API**: Shows API key status and model configuration
- **Claude Pro**: Shows when using default web authentication

**Example output (Anthropic API mode):**
```
[Claude Switcher] Current mode: Anthropic API

[Claude Switcher] Anthropic API Configuration:
[Claude Switcher]   CLAUDE_CODE_USE_BEDROCK: 0
[Claude Switcher]   ANTHROPIC_API_KEY: set (hidden)
[Claude Switcher]   ANTHROPIC_MODEL: claude-sonnet-4-5-20250929

[Claude Switcher] Features:
  - API authentication via Anthropic API
  - Login/logout disabled
  - Direct access to Anthropic models
```

#### `claude-sessions`
Lists all active Claude Code processes with session tracking:

```bash
claude-sessions
```

**Shows:**
- Process ID (PID)
- Authentication mode (AWS Bedrock, Vertex AI, Anthropic API, Claude Pro)
- Session ID for tracking
- Region (for AWS)
- Status

**Example output:**
```
[Claude Sessions] Found Claude Code processes:

PID      Mode                 Session ID                Region          Status
----     ----                 ----------                ------          ------
12345    AWS Bedrock          aws-12345-1234567890      us-west-2       Running
67890    Vertex AI            vertex-67890-1234567     N/A             Running
```

## Configuration

### Models
Default model IDs are defined in `config/models.sh`. The `--sonnet`, `--opus`, and `--haiku` flags automatically use the latest available version of each model tier.

While you can modify `config/models.sh` directly, it is recommended to use `~/.claude-switcher/secrets.sh` for overrides to avoid merge conflicts when updating.

#### Variable Naming
The scripts use provider-specific model variables that can be customized in `secrets.sh`:

```bash
# AWS Bedrock
export CLAUDE_MODEL_SONNET_AWS="global.anthropic.claude-sonnet-4-5-20250929-v1:0"
export CLAUDE_MODEL_OPUS_AWS="us.anthropic.claude-opus-4-1-20250805-v1:0"
export CLAUDE_MODEL_HAIKU_AWS="us.anthropic.claude-haiku-4-5-20251001-v1:0"

# Google Vertex AI
export CLAUDE_MODEL_SONNET_VERTEX="claude-sonnet-4-5@20250929"
export CLAUDE_MODEL_OPUS_VERTEX="claude-opus-4-1@20250805"
export CLAUDE_MODEL_HAIKU_VERTEX="claude-haiku-4-5@20251001"

# Anthropic API
export CLAUDE_MODEL_SONNET_ANTHROPIC="claude-sonnet-4-5-20250929"
export CLAUDE_MODEL_OPUS_ANTHROPIC="claude-opus-4-1-20250805"
export CLAUDE_MODEL_HAIKU_ANTHROPIC="claude-haiku-4-5"

# Microsoft Foundry/Azure (deployment names)
export CLAUDE_MODEL_SONNET_AZURE="claude-sonnet-4-5"
export CLAUDE_MODEL_OPUS_AZURE="claude-opus-4-1"
export CLAUDE_MODEL_HAIKU_AZURE="claude-haiku-4-5"
```

These variables are used by the scripts to set `ANTHROPIC_MODEL` at runtime based on which provider you're using.

### Updating to New Models
When new Claude models are released:

```bash
cd claude-switcher
git pull
./setup.sh
```

The setup script will update all commands with the latest model definitions while preserving your API keys in `~/.claude-switcher/secrets.sh`.

### Secrets
Credentials are stored in `~/.claude-switcher/secrets.sh`. This file is not committed to the repository and is safe for your private keys.

## Troubleshooting

### Verify apiKeyHelper Setup

Check if the API key helper is properly configured:

```bash
claude-status
```

This will show:
- Whether `settings.json` has `apiKeyHelper` configured
- Whether the helper script exists and is executable
- Your current switcher mode (`pro`, `anthropic`, etc.)

### Check Current Mode

View your current mode:

```bash
cat ~/.claude-switcher/current-mode.sh
```

Should show something like:
```bash
export CLAUDE_SWITCHER_MODE="pro"
# or
export CLAUDE_SWITCHER_MODE="anthropic"
```

### Manually Reset to Pro Mode

If you need to reset to Pro/Max subscription:

```bash
claude-pro
# OR manually:
echo 'export CLAUDE_SWITCHER_MODE="pro"' > ~/.claude-switcher/current-mode.sh
```

### Test apiKeyHelper Directly

Verify the helper script works:

```bash
# Test in Pro mode (should output nothing)
echo 'export CLAUDE_SWITCHER_MODE="pro"' > ~/.claude-switcher/current-mode.sh
~/.claude-switcher/claude-api-key-helper.sh

# Test in Anthropic mode (should output your API key)
echo 'export CLAUDE_SWITCHER_MODE="anthropic"' > ~/.claude-switcher/current-mode.sh 
~/.claude-switcher/claude-api-key-helper.sh
```

### Still Getting Rate Limits After Switching?

If you switch from Pro to `claude-anthropic` but still see Pro plan rate limits:

1. Verify API key is set: `grep ANTHROPIC_API_KEY ~/.claude-switcher/secrets.sh`
2. Check current mode: `cat ~/.claude-switcher/current-mode.sh`
3. Run `claude-status` to verify configuration
4. Try running `claude-anthropic` again (not just `claude`)

### Switching Back to Pro Not Working?

If web authentication doesn't activate after running `claude-pro`:

1. Check mode was set: `cat ~/.claude-switcher/current-mode.sh` (should show `pro`)
2. Launch with `claude-pro` or plain `claude` command
3. In Claude session, run `/status` to verify authentication method

### AWS/Vertex/Azure Issues?

These providers don't use apiKeyHelper - they rely on environment variables:

- **AWS**: Verify `AWS_BEARER_TOKEN_BEDROCK` or AWS credentials are set
- **Vertex**: Verify `gcloud auth application-default login` is complete
- **Azure**: Verify `ANTHROPIC_FOUNDRY_API_KEY` or `az login` is complete

Run `claude-status` to see provider-specific configuration.

### Restore Original settings.json

If you need to remove apiKeyHelper:

```bash
# Restore from backup
cp ~/.claude/settings.json.backup-YYYYMMDD-HHMMSS ~/.claude/settings.json

# Or manually remove apiKeyHelper line from settings.json
```

## License

MIT License. Copyright (c) 2025 Jed White from Andi AI Search.
