#Requires -Module PSMCP

$env:OPENAI_API_KEY = 'sk-proj-.....WMyv6CMA'
$currentLocation = (Get-location).Path 
Set-LogFile "$currentLocation\mcp_server.log"

 
function Global:Generate-AIImage {
    <#
.SYNOPSIS
    Generates AI-powered images using OpenAI's image generation models.

.DESCRIPTION
    The Generate-AIImage function creates images based on text prompts using OpenAI's image generation
    models like GPT-4o (gpt-image-1) and DALL-E 3. It provides various options to customize the output,
    including image quality, format, and background transparency settings.

.PARAMETER Prompt
    The text description of the image you want to generate. Be as detailed as possible for best results.

.PARAMETER Model
    The AI model to use for image generation. Options are:
    - gpt-image-1: OpenAI's GPT-4o model (default)
    - dall-e-3: OpenAI's DALL-E 3 model

.PARAMETER Size
    The size of the generated images. Available options depend on the model:
    
    For gpt-image-1:
    - auto: The model determines the best size (default)
    - 1024x1024: Square format
    - 1536x1024: Landscape format
    - 1024x1536: Portrait format
    
    For dall-e-3:
    - 1024x1024: Square format
    - 1792x1024: Landscape format
    - 1024x1792: Portrait format
    
    Note: The function will automatically adjust to a valid size if an incompatible size is selected for the model.

.PARAMETER Moderation
    Controls the level of content filtering. Options are:
    - low: Less restrictive filtering (only available for gpt-image-1)
    - auto: Standard content filtering (default for gpt-image-1)
    Note: This parameter is only used for gpt-image-1 model.

.PARAMETER NumberOfImages
    The number of images to generate (1-10). Default is 1.

.PARAMETER Format
    The output image format. Options are:
    - png: PNG format with possible transparency (default)
    - jpeg: JPEG format
    - webp: WebP format (only for gpt-image-1)
    Note: For transparent backgrounds, use png or webp format.

.PARAMETER Quality
    The quality level of the generated images. Options are:
    - standard: Basic quality
    - medium: Better quality (default)
    - high: Highest quality (may be slower)

.PARAMETER Background
    Controls the background transparency of generated images (for gpt-image-1 model only). Options are:
    - auto: The model automatically determines the best background (default)
    - transparent: Creates images with transparent backgrounds (requires png or webp format)
    - opaque: Forces an opaque background

.PARAMETER ApiKey
    Your OpenAI API key. If not provided, the function will attempt to use the OPENAI_API_KEY environment variable.

.EXAMPLE
    Generate-AIImage -Prompt "A serene mountain lake at sunset"
    
    Generates a single image of a mountain lake at sunset using the default gpt-image-1 model, medium quality, and PNG format.

.EXAMPLE
    Generate-AIImage -Prompt "A futuristic cityscape" -Model dall-e-3 -Quality high -Size 1792x1024
    
    Generates a high-quality landscape image of a futuristic cityscape using the DALL-E 3 model.

.EXAMPLE
    Generate-AIImage -Prompt "A portrait of a Victorian woman" -Size 1024x1536
    
    Generates a portrait-oriented image using the gpt-image-1 model.

.EXAMPLE
    Generate-AIImage -Prompt "A golden retriever wearing a party hat" -NumberOfImages 3 -Format jpeg -Size 1024x1024
    
    Generates three square images of a golden retriever wearing a party hat in JPEG format.

.EXAMPLE
    Generate-AIImage -Prompt "A logo with a blue gradient" -Background transparent -Size auto
    
    Generates an image with a transparent background using the gpt-image-1 model and automatically determined size.

.EXAMPLE
    Generate-AIImage -Prompt "Photo-realistic astronaut on mars" -Model gpt-image-1 -Quality high -Moderation low
    
    Generates a high-quality, photo-realistic image of an astronaut on Mars with less restrictive content filtering.

.EXAMPLE
    Generate-AIImage -Prompt "Children's book illustration of a talking tree" -Model dall-e-3 -NumberOfImages 2 -Size 1024x1792
    
    Generates two portrait-oriented images in the style of a children's book illustration using DALL-E 3.

.EXAMPLE
    Generate-AIImage -Prompt "Photorealistic cat with wings" -Format webp -Background transparent -Quality high -Size 1536x1024
    
    Generates a high-quality, landscape WebP image with a transparent background of a photorealistic cat with wings.

.EXAMPLE
    Generate-AIImage -Prompt "A landscape with mountains" -ApiKey "your-api-key-here"
    
    Generates an image using a specific API key instead of the environment variable.

.NOTES
    Author: Darren Robinson
    Last Updated: April 30, 2025
    Requirements: Requires PowerShell 5.1 or later and an OpenAI API key with access to image generation models
    Links: 
    - OpenAI API Documentation: https://platform.openai.com/docs/api-reference/images
    - GPT-4o (gpt-image-1): https://platform.openai.com/docs/models/gpt-4o
    - DALL-E 3: https://platform.openai.com/docs/models/dall-e

.LINK
    https://github.com/DarrenRobinson/AIImageGenerator
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Prompt,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("gpt-image-1", "dall-e-3")]
        [string]$Model = "gpt-image-1",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("auto", "1024x1024", "1536x1024", "1024x1536", "1792x1024", "1024x1792")]
        [string]$Size = "auto",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("low", "auto")]
        [string]$Moderation = "auto",
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$NumberOfImages = 1,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("png", "jpeg", "webp")]
        [string]$Format = "png",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("standard", "medium", "high")]
        [string]$Quality = "medium",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("auto", "transparent", "opaque")]
        [string]$Background = "auto",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey
    )
    
    begin {
        # Use provided API key or retrieve from environment variable
        if (-not $ApiKey) {
            $ApiKey = $env:OPENAI_API_KEY
        }
        
        if (-not $ApiKey) {
            $errorMessage = @"
API key is required. You must either:
1. Provide the API key via the -ApiKey parameter, or
2. Set up the OPENAI_API_KEY environment variable.

To create a persistent global environment variable that will be accessible to this function:

Using PowerShell as Administrator:
1. Open PowerShell as Administrator (right-click, 'Run as Administrator')
2. Run the following command:
   [System.Environment]::SetEnvironmentVariable('OPENAI_API_KEY', 'your-api-key-here', 'Machine')
3. Close and reopen PowerShell for the change to take effect

Using Windows GUI:
1. Press Win + X and select 'System'
2. Click on 'Advanced system settings'
3. Click the 'Environment Variables' button
4. Under 'System variables' section, click 'New'
5. Enter 'OPENAI_API_KEY' as the variable name
6. Enter your OpenAI API key as the variable value
7. Click 'OK' on all dialogs to save

You can get an OpenAI API key from: https://platform.openai.com/api-keys
"@
            throw $errorMessage
        }
        
        # Validate format for transparency
        if ($Background -eq "transparent" -and $Format -eq "jpeg") {
            Write-Warning "Transparent backgrounds require PNG or WebP format. Switching to PNG format."
            $Format = "png"
        }
        
        # Validate size compatibility with model
        $validSizes = @{
            "gpt-image-1" = @("auto", "1024x1024", "1536x1024", "1024x1536")
            "dall-e-3"    = @("1024x1024", "1792x1024", "1024x1792")
        }
        
        if ($Size -ne "auto" -and -not $validSizes[$Model].Contains($Size)) {
            $defaultSize = $Model -eq "dall-e-3" ? "1024x1024" : "auto"
            Write-Warning "Size '$Size' is not compatible with model '$Model'. Using '$defaultSize' instead."
            $Size = $defaultSize
        }
        
        # Create output directory if it doesn't exist
        $outputDir = Join-Path $env:TEMP "GeneratedImages"
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir | Out-Null
        }
        
        $headers = @{
            "Content-Type"  = "application/json"
            "Authorization" = "Bearer $ApiKey"
        }
    }
    
    process {
        $startTime = Get-Date
        
        # Prepare API request payload
        $body = @{
            model   = $Model
            prompt  = $Prompt
            n       = $NumberOfImages
            quality = $Quality
        }
        
        # Add size to the payload
        if ($Size -ne "auto" -or $Model -eq "dall-e-3") {
            # For dall-e-3, always set size explicitly as it doesn't support 'auto'
            $body.size = $Size -eq "auto" -and $Model -eq "dall-e-3" ? "1024x1024" : $Size
        }
        
        # Add model-specific parameters
        if ($Model -eq "dall-e-3") {
            $body.style = "vivid"
            $body.response_format = "b64_json"  # dall-e-3 uses response_format
        }
        else {
            # gpt-image-1 specific parameters
            $body.output_format = $Format  # gpt-image-1 uses output_format instead of response_format
            $body.moderation = $Moderation
            $body.background = $Background  # Correct parameter for transparency control
        }
        
        $bodyJson = $body | ConvertTo-Json
        
        # Define API endpoint based on model
        $apiUrl = "https://api.openai.com/v1/images/generations"
        
        Write-Verbose "Sending request to OpenAI API..."
        
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $bodyJson
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            Write-Host "Images generated in $($duration.ToString("0.00")) seconds" -ForegroundColor Green
            Write-Host "Usage metadata:" -ForegroundColor Yellow
            
            if ($response.usage) {
                $response.usage | Format-Table -AutoSize
            }
            
            $imageLinks = @()
            
            # Process each generated image
            for ($i = 0; $i -lt $response.data.Count; $i++) {
                $imageData = $response.data[$i]
                $base64Data = $imageData.b64_json
                $imageBytes = [Convert]::FromBase64String($base64Data)
                
                # Generate a unique filename
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $filename = "image_${timestamp}_$i.$Format"
                $filePath = Join-Path $outputDir $filename
                
                # Save the image file
                [System.IO.File]::WriteAllBytes($filePath, $imageBytes)
                
                # Create hyperlink
                $imageLinks += $filePath
                
                Write-Host "Image $($i + 1) saved to: $filePath" -ForegroundColor Cyan
            }
            
            # Return the path to the generated images
            return $imageLinks
        }
        catch {
            Write-Error "Error generating images: $_"
            if ($_.ErrorDetails.Message) {
                $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Error "API Error: $($errorResponse.error.message)"
            }
        }
    }   
}

$MCPFunctions += "Generate-AIImage"

function Global:Generate-AIImageVariation {
    <#
.SYNOPSIS
    Generates variations of an existing image using OpenAI's DALL-E 2 model.

.DESCRIPTION
    The Generate-AIImageVariation function creates variations of an existing image using OpenAI's DALL-E 2 model.
    You can provide a local image file or a URL to an image. The function validates that the image meets
    the API requirements (PNG format, <4MB, square dimensions) and then generates variations based on your settings.

.PARAMETER ImagePath
    The path to a local image file to use as the basis for variations. 
    Must be a PNG file, less than 4MB, and have square dimensions.
    Either ImagePath or ImageUrl must be provided, but not both.

.PARAMETER ImageUrl
    A URL to an image to use as the basis for variations.
    The image will be downloaded and must be a PNG file, less than 4MB, and have square dimensions.
    Either ImagePath or ImageUrl must be provided, but not both.

.PARAMETER Model
    The AI model to use. Currently only supports "dall-e-2".

.PARAMETER NumberOfImages
    The number of image variations to generate (1-10). Default is 1.

.PARAMETER Size
    The size of the generated image variations. Options are:
    - 256x256: Small size
    - 512x512: Medium size
    - 1024x1024: Large size (default)

.PARAMETER ResponseFormat
    The format in which the generated images are returned. Options are:
    - url: Returns URLs to the generated images (default, URLs expire after 60 minutes)
    - b64_json: Returns base64-encoded JSON of the images

.PARAMETER User
    A unique identifier representing your end-user, which helps OpenAI monitor and detect abuse.
    Optional.

.PARAMETER ApiKey
    Your OpenAI API key. If not provided, the function will attempt to use the OPENAI_API_KEY environment variable.

.EXAMPLE
    Generate-AIImageVariation -ImagePath "C:\Images\MyImage.png"
    
    Generates a single variation of the local image using default settings.

.EXAMPLE
    Generate-AIImageVariation -ImageUrl "https://example.com/image.png" -NumberOfImages 3 -Size 512x512
    
    Downloads the image from the URL and generates three medium-sized variations.

.EXAMPLE
    Generate-AIImageVariation -ImagePath "C:\Images\Logo.png" -ResponseFormat b64_json
    
    Generates a variation of the local image and returns it as base64-encoded JSON instead of a URL.

.EXAMPLE
    Generate-AIImageVariation -ImagePath "C:\Images\Square.png" -NumberOfImages 5 -Size 256x256
    
    Generates five small variations of the local image.

.EXAMPLE
    Generate-AIImageVariation -ImagePath "C:\Images\MyImage.png" -ApiKey "your-api-key-here"
    
    Generates a variation of the local image using a specific API key instead of the environment variable.

.NOTES
    Author: Darren Robinson
    Last Updated: April 30, 2025
    Requirements: 
    - Requires PowerShell 5.1 or later
    - An OpenAI API key with access to image generation models
    - Input images must be PNG files, less than 4MB, and have square dimensions
    Links: 
    - OpenAI API Documentation: https://platform.openai.com/docs/api-reference/images/variations

.LINK
    https://github.com/DarrenRobinson/AIImageGenerator
#>

    [CmdletBinding(DefaultParameterSetName = 'LocalImage')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'LocalImage')]
        [string]$ImagePath,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'RemoteImage')]
        [string]$ImageUrl,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("dall-e-2")]
        [string]$Model = "dall-e-2",
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$NumberOfImages = 1,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("256x256", "512x512", "1024x1024")]
        [string]$Size = "1024x1024",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("url", "b64_json")]
        [string]$ResponseFormat = "url",
        
        [Parameter(Mandatory = $false)]
        [string]$User,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey
    )
    
    begin {
        # Use provided API key or retrieve from environment variable
        if (-not $ApiKey) {
            $ApiKey = $env:OPENAI_API_KEY
        }
        
        if (-not $ApiKey) {
            $errorMessage = @"
API key is required. You must either:
1. Provide the API key via the -ApiKey parameter, or
2. Set up the OPENAI_API_KEY environment variable.

To create a persistent global environment variable that will be accessible to this function:

Using PowerShell as Administrator:
1. Open PowerShell as Administrator (right-click, 'Run as Administrator')
2. Run the following command:
   [System.Environment]::SetEnvironmentVariable('OPENAI_API_KEY', 'your-api-key-here', 'Machine')
3. Close and reopen PowerShell for the change to take effect

Using Windows GUI:
1. Press Win + X and select 'System'
2. Click on 'Advanced system settings'
3. Click the 'Environment Variables' button
4. Under 'System variables' section, click 'New'
5. Enter 'OPENAI_API_KEY' as the variable name
6. Enter your OpenAI API key as the variable value
7. Click 'OK' on all dialogs to save

You can get an OpenAI API key from: https://platform.openai.com/api-keys
"@
            throw $errorMessage
        }
        
        # Create output directory if it doesn't exist
        $outputDir = Join-Path $env:TEMP "GeneratedImages"
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir | Out-Null
        }
        
        # Get the image file path based on the parameter set
        $tempImagePath = $null
        
        if ($PSCmdlet.ParameterSetName -eq 'RemoteImage') {
            Write-Verbose "Downloading image from URL: $ImageUrl"
            $tempImagePath = Join-Path $env:TEMP "$(New-Guid).png"
            
            try {
                Invoke-WebRequest -Uri $ImageUrl -OutFile $tempImagePath
                $ImagePath = $tempImagePath
            }
            catch {
                throw "Failed to download image from URL: $_"
            }
        }
        
        # Validate image file
        if (-not (Test-Path -Path $ImagePath)) {
            throw "Image file not found: $ImagePath"
        }
        
        # Check file size (<4MB)
        $fileInfo = Get-Item $ImagePath
        $fileSizeMB = $fileInfo.Length / 1MB
        if ($fileSizeMB -ge 4) {
            throw "Image file size ($($fileSizeMB.ToString('0.00')) MB) exceeds the 4MB limit."
        }
        
        # Check file type (PNG)
        $fileExtension = [System.IO.Path]::GetExtension($ImagePath).ToLower()
        if ($fileExtension -ne ".png") {
            throw "Image file must be in PNG format. Current format: $fileExtension"
        }
        
        # Check if image is square
        Add-Type -AssemblyName System.Drawing
        try {
            $image = [System.Drawing.Image]::FromFile($ImagePath)
            if ($image.Width -ne $image.Height) {
                throw "Image must have square dimensions. Current dimensions: $($image.Width)x$($image.Height)"
            }
        }
        catch {
            throw "Failed to process image: $_"
        }
        finally {
            if ($image) {
                $image.Dispose()
            }
        }
        
        $headers = @{
            "Authorization" = "Bearer $ApiKey"
        }
    }
    
    process {
        $startTime = Get-Date
        
        # Define API endpoint
        $apiUrl = "https://api.openai.com/v1/images/variations"
        
        # Prepare form data
        $form = @{
            image           = Get-Item -Path $ImagePath
            n               = $NumberOfImages
            size            = $Size
            response_format = $ResponseFormat
        }
        
        # Add optional parameters if provided
        if ($User) {
            $form.user = $User
        }
        
        Write-Verbose "Sending request to OpenAI API for image variations..."
        
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Form $form
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            Write-Host "Image variations generated in $($duration.ToString("0.00")) seconds" -ForegroundColor Green
            
            $imageLinks = @()
            
            # Process each generated image variation
            for ($i = 0; $i -lt $response.data.Count; $i++) {
                if ($ResponseFormat -eq "url") {
                    $imageUrl = $response.data[$i].url
                    $imageLinks += $imageUrl
                    
                    # Download the image if it's a URL
                    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                    $filename = "variation_${timestamp}_$i.png"
                    $filePath = Join-Path $outputDir $filename
                    
                    try {
                        Invoke-WebRequest -Uri $imageUrl -OutFile $filePath
                        Write-Host "Image variation $($i + 1) saved to: $filePath" -ForegroundColor Cyan
                    }
                    catch {
                        Write-Error "Failed to download image variation $($i + 1): $_"
                    }
                }
                else {
                    # Handle base64 encoded images
                    $base64Data = $response.data[$i].b64_json
                    $imageBytes = [Convert]::FromBase64String($base64Data)
                    
                    # Generate a unique filename
                    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                    $filename = "variation_${timestamp}_$i.png"
                    $filePath = Join-Path $outputDir $filename
                    
                    # Save the image file
                    [System.IO.File]::WriteAllBytes($filePath, $imageBytes)
                    
                    $imageLinks += $filePath
                    Write-Host "Image variation $($i + 1) saved to: $filePath" -ForegroundColor Cyan
                }
            }
            
            # Return the URLs or file paths of the generated images
            return $imageLinks
        }
        catch {
            Write-Error "Error generating image variations: $_"
            if ($_.ErrorDetails.Message) {
                $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Error "API Error: $($errorResponse.error.message)"
            }
        }
        finally {
            # Cleanup temp file if we downloaded from URL
            if ($tempImagePath -and (Test-Path -Path $tempImagePath)) {
                Remove-Item -Path $tempImagePath -Force
            }
        }
    }
}

$MCPFunctions += "Generate-AIImageVariation"

function Global:Analyze-AIImage {
    <#
.SYNOPSIS
    Analyzes images using OpenAI's GPT-4 models with vision capabilities.

.DESCRIPTION
    The Analyze-AIImage function uses OpenAI's GPT-4 models with vision capabilities to analyze 
    and understand images. You can provide a local image file or a URL to an image, along with a 
    prompt asking about the image content. The function will return a detailed analysis based on 
    what the AI model sees in the image.

.PARAMETER ImagePath
    The path to a local image file to analyze.
    Either ImagePath or ImageUrl must be provided, but not both.
    Supported formats: PNG, JPEG, WEBP, non-animated GIF.

.PARAMETER ImageUrl
    A URL to an image to analyze.
    Either ImagePath or ImageUrl must be provided, but not both.
    Supported formats: PNG, JPEG, WEBP, non-animated GIF.

.PARAMETER Prompt
    The text prompt describing what you want to know about the image.
    For example: "What's in this image?" or "Describe what you see in detail."

.PARAMETER Model
    The AI model to use for image analysis. Options are:
    - gpt-4: The standard GPT-4 with vision capabilities
    - gpt-4-turbo: Faster GPT-4 model with vision capabilities
    - gpt-4o: The latest GPT-4o model with vision capabilities (default)
    - gpt-4-vision-preview: Preview version of GPT-4 with vision
    - gpt-4.1-mini: Smaller, faster model for basic image analysis
    - gpt-4.1-nano: Even smaller model for very basic image analysis
    - o4-mini: OpenAI's optimized model for image analysis

.PARAMETER MaxTokens
    The maximum number of tokens to generate in the response. Defaults to 300.

.PARAMETER Temperature
    Controls randomness. Lower values make output more focused and deterministic.
    Higher values make output more random. Range is 0.0 to 2.0. Defaults to 1.0.

.PARAMETER DetailLevel
    The level of detail to use when processing the image. Options are:
    - auto: Let the model decide (default)
    - low: Use lower resolution (512px x 512px) to save tokens and speed up responses
    - high: Use higher resolution for better understanding of details in the image

.PARAMETER ApiKey
    Your OpenAI API key. If not provided, the function will attempt to use the OPENAI_API_KEY environment variable.

.EXAMPLE
    Analyze-AIImage -ImagePath "C:\Images\photo.jpg" -Prompt "What's in this image?"
    
    Analyzes the local image using the default model and returns a description of its contents.

.EXAMPLE
    Analyze-AIImage -ImageUrl "https://example.com/image.png" -Prompt "Describe the colors and mood of this image" -Model gpt-4o
    
    Analyzes the image from the URL using the GPT-4o model and describes its colors and mood.

.EXAMPLE
    Analyze-AIImage -ImagePath "C:\Images\document.png" -Prompt "Extract all text from this image" -DetailLevel high
    
    Analyzes the local image with high detail level to accurately extract text content.

.EXAMPLE
    Analyze-AIImage -ImageUrl "https://example.com/art.jpg" -Prompt "What style of art is this?" -Model gpt-4.1-nano -DetailLevel low
    
    Uses the smaller gpt-4.1-nano model with low detail level to identify the art style, optimizing for speed and cost.

.EXAMPLE
    Analyze-AIImage -ImagePath "C:\Images\photo.jpg" -Prompt "What's in this image?" -ApiKey "your-api-key-here"
    
    Analyzes the local image using a specific API key instead of the environment variable.

.NOTES
    Author: Darren Robinson
    Last Updated: April 30, 2025
    Requirements: 
    - Requires PowerShell 5.1 or later
    - An OpenAI API key with access to vision models
    - Input images must meet OpenAI requirements (size limits, content policies)
    
    Limitations:
    - Not suitable for interpreting specialized medical images
    - May not perform optimally with non-Latin text
    - Small text may be difficult to read (consider enlarging it)
    - May struggle with rotated or upside-down text and images
    - Limited spatial reasoning capabilities
    - May generate incorrect descriptions in certain scenarios
    - Struggles with panoramic and fisheye images
    - May give approximate counts for objects
    - Cannot process CAPTCHAs (blocked for safety reasons)

    Image requirements:
    - Supported formats: PNG, JPEG, WEBP, non-animated GIF
    - Up to 20MB per image
    - Low-resolution: 512px x 512px (with "low" detail level)
    - High-resolution: 768px (short side) x 2000px (long side) (with "high" detail level)
    - No watermarks/logos, NSFW content
    - Must be clear enough for a human to understand

.LINK
    https://github.com/DarrenRobinson/AIImageGenerator
#>

    [CmdletBinding(DefaultParameterSetName = 'LocalImage')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'LocalImage')]
        [string]$ImagePath,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'RemoteImage')]
        [string]$ImageUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$Prompt,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("gpt-4", "gpt-4-turbo", "gpt-4o", "gpt-4-vision-preview", "gpt-4.1-mini", "gpt-4.1-nano", "o4-mini")]
        [string]$Model = "gpt-4o",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxTokens = 300,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature = 1.0,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("auto", "low", "high")]
        [string]$DetailLevel = "auto",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey
    )
    
    begin {
        # Use provided API key or retrieve from environment variable
        if (-not $ApiKey) {
            $ApiKey = $env:OPENAI_API_KEY
        }
        
        if (-not $ApiKey) {
            $errorMessage = @"
API key is required. You must either:
1. Provide the API key via the -ApiKey parameter, or
2. Set up the OPENAI_API_KEY environment variable.

To create a persistent global environment variable that will be accessible to this function:

Using PowerShell as Administrator:
1. Open PowerShell as Administrator (right-click, 'Run as Administrator')
2. Run the following command:
   [System.Environment]::SetEnvironmentVariable('OPENAI_API_KEY', 'your-api-key-here', 'Machine')
3. Close and reopen PowerShell for the change to take effect

Using Windows GUI:
1. Press Win + X and select 'System'
2. Click on 'Advanced system settings'
3. Click the 'Environment Variables' button
4. Under 'System variables' section, click 'New'
5. Enter 'OPENAI_API_KEY' as the variable name
6. Enter your OpenAI API key as the variable value
7. Click 'OK' on all dialogs to save

You can get an OpenAI API key from: https://platform.openai.com/api-keys
"@
            throw $errorMessage
        }
        
        # Prepare image for analysis
        $imageContent = $null
        
        if ($PSCmdlet.ParameterSetName -eq 'LocalImage') {
            # Validate local image file
            if (-not (Test-Path -Path $ImagePath)) {
                throw "Image file not found: $ImagePath"
            }
            
            # Check file type
            $fileExtension = [System.IO.Path]::GetExtension($ImagePath).ToLower()
            $supportedFormats = @(".png", ".jpg", ".jpeg", ".webp", ".gif")
            
            if (-not $supportedFormats.Contains($fileExtension)) {
                throw "Unsupported image format: $fileExtension. Supported formats are: PNG, JPEG, WEBP, and non-animated GIF."
            }
            
            # Check file size (<20MB)
            $fileInfo = Get-Item $ImagePath
            $fileSizeMB = $fileInfo.Length / 1MB
            if ($fileSizeMB -gt 20) {
                throw "Image file size ($($fileSizeMB.ToString('0.00')) MB) exceeds the 20MB limit."
            }
            
            # Convert image to base64
            $imageBytes = [System.IO.File]::ReadAllBytes($ImagePath)
            $base64Image = [Convert]::ToBase64String($imageBytes)
            $mimeType = switch ($fileExtension) {
                ".png" { "image/png" }
                ".jpg" { "image/jpeg" }
                ".jpeg" { "image/jpeg" }
                ".webp" { "image/webp" }
                ".gif" { "image/gif" }
            }
            
            $imageContent = "data:$mimeType;base64,$base64Image"
        }
        else {
            # Using remote image URL
            $imageContent = $ImageUrl
        }
        
        $headers = @{
            "Content-Type"  = "application/json"
            "Authorization" = "Bearer $ApiKey"
        }
    }
    
    process {
        $startTime = Get-Date
        
        # Prepare the API request payload using the chat/completions endpoint
        $body = @{
            "model"       = $Model
            "messages"    = @(
                @{
                    "role"    = "user"
                    "content" = @(
                        @{
                            "type" = "text"
                            "text" = $Prompt
                        }
                        @{
                            "type"      = "image_url"
                            "image_url" = @{
                                "url"    = $imageContent
                                "detail" = $DetailLevel
                            }
                        }
                    )
                }
            )
            "max_tokens"  = $MaxTokens
            "temperature" = $Temperature
        }
        
        $bodyJson = $body | ConvertTo-Json -Depth 10
        
        # Define the correct API endpoint for vision capabilities
        $apiUrl = "https://api.openai.com/v1/chat/completions"
        
        Write-Verbose "Sending request to OpenAI API for image analysis..."
        
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $bodyJson
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            Write-Host "Image analysis completed in $($duration.ToString("0.00")) seconds" -ForegroundColor Green
            
            # Extract and return the analysis from the response
            if ($response.choices -and $response.choices.Count -gt 0) {
                $analysis = $response.choices[0].message.content
                return $analysis
            }
            else {
                # In case the API response format changes, return the whole response
                return $response
            }
        }
        catch {
            Write-Error "Error analyzing image: $_"
            if ($_.ErrorDetails.Message) {
                try {
                    $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
                    Write-Error "API Error: $($errorResponse.error.message)"
                }
                catch {
                    Write-Error "API Error: $($_.ErrorDetails.Message)"
                }
            }
        }
    }
}


Start-McpServer Generate-AIImage, Generate-AIImageVariation, Analyze-AIImage
