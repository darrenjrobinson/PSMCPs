# PowerShell MCP Servers

## AI Images

MCP Server to use OpenAI Image Tools

This MCP server provides access to powerful AI-based image generation and analysis capabilities using OpenAI's services:

1. **Generate-AIImage** - Creates AI-powered images from text prompts
   - Uses OpenAI's GPT-4o (gpt-image-1) and DALL-E 3 models
   - Supports various sizes, formats, and quality settings
   - Options for transparent backgrounds and content moderation

2. **Generate-AIImageVariation** - Creates variations of existing images
   - Uses OpenAI's DALL-E 2 model
   - Works with local image files or images from URLs
   - Validates image requirements (PNG format, <4MB, square dimensions)

3. **Analyze-AIImage** - Analyzes images using vision AI models
   - Uses OpenAI's GPT-4 family of models with vision capabilities
   - Accepts local image files or URLs
   - Customizable detail levels for image processing

### Getting Started

1. Configure your OpenAI API key in the `.vscode/mcp.json` file
2. Run the server with PowerShell: `Start-McpServer`
3. Connect to the server in VS Code with the Microsoft PowerShell extension

### Requirements

- PowerShell 5.1 or later
- PSMCP module installed
- Valid OpenAI API key with access to image generation models