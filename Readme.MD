# PowerShell MCP Servers

# Table of Contents

1. [PowerShell MCP Servers](#powershell-mcp-servers)
   - [AI Images](#ai-images)
     - [Generate-AIImage](#generate-aiimage)
     - [Generate-AIImageVariation](#generate-aiimagevariation)
     - [Analyze-AIImage](#analyze-aiimage)
   - [GeoLocation](#geolocation)
     - [Get-PublicIPAddress](#get-publicipaddress)
     - [Find-Geolocation](#find-geolocation)
2. [Getting Started](#getting-started)
3. [Requirements](#requirements)

## AI Images

[AIImages Folder](./AIImages/)

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

## GeoLocation

[GeoLocation Folder](./GeoLocation/)

MCP Server to provide geolocation and public IP address utilities

This MCP server offers tools for retrieving geolocation information and public IP addresses:

1. **Get-PublicIPAddress** - Retrieves the public IP address of the machine running the script
   - Uses `http://ipinfo.io/json` for IP address lookup
   - Useful for debugging and API testing

2. **Find-Geolocation** - Resolves an IP address or domain name to geolocation information
   - Uses the `https://freegeoip.live` API for geolocation data
   - Supports both IP addresses and domain names
   - Provides details such as country, region, city, and more

### Requirements

- PowerShell 5.1 or later
- PSMCP module installed
- Valid OpenAI API key with access to image generation models