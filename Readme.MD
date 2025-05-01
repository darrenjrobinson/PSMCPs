# PowerShell MCP Servers

## Table of Contents
- [AI Images](#ai-images)
  - [Getting Started (AI Images)](#getting-started)
  - [Requirements (AI Images)](#requirements)
- [Geolocation](#geolocation)
  - [Getting Started (Geolocation)](#getting-started-1)
  - [Requirements (Geolocation)](#requirements-1)
- [Weather](#weather)
  - [Getting Started (Weather)](#getting-started-2)
  - [Example (Weather)](#example)
  - [Requirements (Weather)](#requirements-2)
- [Hash Type Identification](#hash-type-identification)
  - [Getting Started (Hash Type)](#getting-started-3)
  - [Example (Hash Type)](#example-1)
  - [Requirements (Hash Type)](#requirements-3)

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

## Geolocation

MCP server that provides IP and domain geolocation capabilities:

1. **Get-PublicIPAddress** - Retrieves the public IP address of the current machine
   - Uses ipinfo.io service to identify your external IP
   - Useful for testing and debugging applications that depend on IP address

2. **Find-Geolocation** - Resolves geolocation details from IP addresses or domain names
   - Uses the freegeoip.live API (free, up to 10,000 queries/hour per IP)
   - Accepts both IP addresses and domain names as input
   - Returns comprehensive location data including country, region, city, and coordinates

### Getting Started

1. Run the server with PowerShell: `Start-McpServer`
2. Connect to the server in VS Code with the Microsoft PowerShell extension
3. No API keys required - both services are free to use

### Requirements

- PowerShell 5.1 or later
- PSMCP module installed
- Internet connectivity

## Weather

MCP server providing weather forecast capabilities:

1. **Get-WeatherForecast** - Retrieves weather forecasts for locations worldwide
   - Uses the free Open-Meteo weather API (no API key required)
   - Supports location input as city name or exact coordinates 
   - Can provide forecasts for 1-7 days
   - Returns either daily summaries or detailed hourly forecasts
   - Includes temperature, precipitation, humidity, wind speed, and weather condition descriptions

### Getting Started

1. Run the server with PowerShell: `Start-McpServer`
2. Connect to the server in VS Code with the Microsoft PowerShell extension
3. No API keys required - the Open-Meteo API is free to use

### Example

```powershell
# Get today's weather for New York
Get-WeatherForecast -City "New York"

# Get 3-day forecast with hourly details for Tokyo
Get-WeatherForecast -City "Tokyo" -Days 3 -Detailed
```

### Requirements

- PowerShell 5.1 or later
- PSMCP module installed
- Internet connectivity

## Hash Type Identification

MCP server for identifying hash algorithm types:

1. **Get-HashType** - Identifies the algorithm of given hash strings
   - Pure PowerShell implementation using pattern matching
   - Supports over 25 different hash types including common cryptographic hashes and password hashes
   - Returns matches with confidence levels (high, medium, low)
   - Multiple output formats: colorized text, PowerShell objects, or JSON

### Getting Started

1. Run the server with PowerShell: `Start-McpServer`
2. Connect to the server in VS Code with the Microsoft PowerShell extension

### Example

```powershell
# Identify a single hash
Get-HashType -Hash "5f4dcc3b5aa765d61d8327deb882cf99"

# Process multiple hashes via pipeline
"5f4dcc3b5aa765d61d8327deb882cf99", "8843d7f92416211de9ebb963ff4ce28125932878" | Get-HashType

# Get results as JSON
Get-HashType -Hash "$2a$12$K3JNi5vQMio5UQRrUJQOm.7U8Fb3sacDJIQUblk75jtpz6nbMPuFS" -OutputFormat Json
```

### Requirements

- PowerShell 5.1 or later
- PSMCP module installed