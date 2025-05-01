#Requires -Module PSMCP

Set-LogFile ".\mcp_server.log"

function Global:Get-HashType {
    <#
    .SYNOPSIS
        Identifies the algorithm of a given hash using pure PowerShell.
    
    .DESCRIPTION
        A pure PowerShell implementation that identifies hash algorithms based on pattern matching.
        This function analyzes input hash strings and returns the most likely hash type(s) based on 
        character patterns, length, and structure. It supports over 25 different hash types including
        common cryptographic hashes, password hashes, and checksums.
        
        The function classifies matches with confidence levels (high, medium, or low) based on the
        distinctiveness of the hash pattern and the rarity of the hash type.
    
    .PARAMETER Hash
        The hash string(s) to identify. Can be a single string or an array of hash strings.
        Accepts pipeline input for bulk hash identification.
    
    .PARAMETER OutputFormat
        Output format for the results:
        - 'Text' (default): Colorized console output with confidence indicators
        - 'Object': PowerShell objects for further processing
        - 'Json': JSON-formatted output for integration with other tools
    
    .EXAMPLE
        Get-HashType -Hash "5f4dcc3b5aa765d61d8327deb882cf99"
        
        Identifies a single MD5 hash (this example hash is for the word "password").
    
    .EXAMPLE
        "5f4dcc3b5aa765d61d8327deb882cf99", "d41d8cd98f00b204e9800998ecf8427e" | Get-HashType
        
        Identifies multiple hashes passed through the pipeline.
    
    .EXAMPLE
        Get-HashType -Hash "5f4dcc3b5aa765d61d8327deb882cf99" -OutputFormat Json
        
        Returns the hash identification results in JSON format for integration with other tools.
    
    .EXAMPLE
        Get-Content hashes.txt | Get-HashType
        
        Reads hash values from a file and identifies each one.
    
    .EXAMPLE
        Get-HashType -Hash '$2a$12$K3JNi5vQMio5UQRrUJQOm.7U8Fb3sacDJIQUblk75jtpz6nbMPuFS' -OutputFormat Object
        
        Identifies a bcrypt hash and returns the result as a PowerShell object.
    
    .EXAMPLE
        Get-HashType -Hash "*31D6CFE0D16AE931B73C59D7E0C089C0" -OutputFormat Text
        
        Identifies a MySQL4.1+ hash with colorized output in the console.
    
    .EXAMPLE
        $result = Get-HashType -Hash "8843d7f92416211de9ebb963ff4ce28125932878" -OutputFormat Object
        $result.Matches | Where-Object Confidence -eq "high" | Select-Object Name, Description
        
        Gets the hash type as an object and filters only the high confidence matches.
    
    .NOTES
        Author: Darren J Robinson
        Version: 1.0
        Last Updated: May 1, 2025
        
        This function uses pattern matching to identify hash types, which means:
        1. Some hash types share the same pattern (e.g., MD5, MD4, and NTLM all have 32 hex characters)
        2. The confidence level helps distinguish between similarly patterned hashes
        3. For definitive identification, consider the context of where the hash was obtained
        
        Supported hash types include:
        - Common: MD5, SHA1, SHA256, SHA512, NTLM, BCrypt, UNIX MD5 Crypt
        - Uncommon: MD4, SHA224, SHA384, MySQL hashes, LM, PBKDF2, Scrypt
        - Rare: SHA3 family, ADLER32
        
        For more accurate results, provide clean hash strings without additional characters or formatting.
    
    .LINK
        https://github.com/DarrenJRobinson/PSMCPs
    #>
    
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string[]]$Hash,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Text', 'Object', 'Json')]
        [string]$OutputFormat = 'Text'
    )
    
    begin {
        # Hash type definitions - each with a regex pattern, description, and example
        $hashTypes = @(
            @{
                Name = "MD5"; 
                Regex = "^[a-fA-F0-9]{32}$"; 
                Rarity = "common";
                Description = "Message Digest 5 - Common hash used for checksums";
            },
            @{
                Name = "SHA1"; 
                Regex = "^[a-fA-F0-9]{40}$"; 
                Rarity = "common";
                Description = "Secure Hashing Algorithm 1";
            },
            @{
                Name = "SHA256"; 
                Regex = "^[a-fA-F0-9]{64}$"; 
                Rarity = "common";
                Description = "Secure Hashing Algorithm 256";
            },
            @{
                Name = "SHA512"; 
                Regex = "^[a-fA-F0-9]{128}$"; 
                Rarity = "common";
                Description = "Secure Hashing Algorithm 512";
            },
            @{
                Name = "NTLM"; 
                Regex = "^[a-fA-F0-9]{32}$"; 
                Rarity = "common";
                Description = "NT LAN Manager hash";
            },
            @{
                Name = "NetNTLMv1"; 
                Regex = "^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$"; 
                Rarity = "common";
                Description = "Microsoft Net-NTLMv1 hash format";
            },
            @{
                Name = "NetNTLMv2"; 
                Regex = "^[^:]+:[^:]*:[^:]*:[^:]*:[^:]*:.*$"; 
                Rarity = "common";
                Description = "Microsoft Net-NTLMv2 hash format";
            },
            @{
                Name = "MD4"; 
                Regex = "^[a-fA-F0-9]{32}$"; 
                Rarity = "uncommon";
                Description = "Message Digest 4";
            },
            @{
                Name = "RIPEMD160"; 
                Regex = "^[a-fA-F0-9]{40}$"; 
                Rarity = "uncommon";
                Description = "RACE Integrity Primitives Evaluation Message Digest 160";
            },
            @{
                Name = "Whirlpool"; 
                Regex = "^[a-fA-F0-9]{128}$"; 
                Rarity = "uncommon";
                Description = "Whirlpool cryptographic hash function";
            },
            @{
                Name = "LM"; 
                Regex = "^[a-fA-F0-9]{32}$"; 
                Rarity = "uncommon";
                Description = "LAN Manager hash";
            },
            @{
                Name = "SHA224"; 
                Regex = "^[a-fA-F0-9]{56}$"; 
                Rarity = "uncommon";
                Description = "Secure Hashing Algorithm 224";
            },
            @{
                Name = "SHA384"; 
                Regex = "^[a-fA-F0-9]{96}$"; 
                Rarity = "uncommon";
                Description = "Secure Hashing Algorithm 384";
            },
            @{
                Name = "SHA3-224"; 
                Regex = "^[a-fA-F0-9]{56}$"; 
                Rarity = "rare";
                Description = "Secure Hashing Algorithm 3-224";
            },
            @{
                Name = "SHA3-256"; 
                Regex = "^[a-fA-F0-9]{64}$"; 
                Rarity = "rare";
                Description = "Secure Hashing Algorithm 3-256";
            },
            @{
                Name = "SHA3-384"; 
                Regex = "^[a-fA-F0-9]{96}$"; 
                Rarity = "rare";
                Description = "Secure Hashing Algorithm 3-384";
            },
            @{
                Name = "SHA3-512"; 
                Regex = "^[a-fA-F0-9]{128}$"; 
                Rarity = "rare";
                Description = "Secure Hashing Algorithm 3-512";
            },
            @{
                Name = "MySQL323"; 
                Regex = "^[a-fA-F0-9]{1,32}$"; 
                Rarity = "uncommon";
                Description = "MySQL v3.23 and older hash";
            },
            @{
                Name = "MySQL4.1+"; 
                Regex = "^\*[a-fA-F0-9]{40}$"; 
                Rarity = "uncommon";
                Description = "MySQL v4.1 and newer hash";
            },
            @{
                Name = "BCrypt"; 
                Regex = '^\$2[abfy]\$\d+\$[\./A-Za-z0-9]{53}$'; 
                Rarity = "common";
                Description = "BCrypt password hashing algorithm";
            },
            @{
                Name = "Argon2"; 
                Regex = '^\$argon2[id][dv]?\$.*\$.*\$.*$'; 
                Rarity = "uncommon";
                Description = "Argon2 password hashing algorithm";
            },
            @{
                Name = "PBKDF2"; 
                Regex = '^\$pbkdf2-sha\d+\$\d+\$[a-zA-Z0-9/.]+\$[a-zA-Z0-9/.]+$'; 
                Rarity = "uncommon";
                Description = "Password-Based Key Derivation Function 2";
            },
            @{
                Name = "Scrypt"; 
                Regex = '^\$scrypt\$.*$'; 
                Rarity = "uncommon";
                Description = "Scrypt key derivation function";
            },
            @{
                Name = "CRC32"; 
                Regex = "^[a-fA-F0-9]{8}$"; 
                Rarity = "uncommon";
                Description = "Cyclic Redundancy Check 32";
            },
            @{
                Name = "CRC32B"; 
                Regex = "^[a-fA-F0-9]{8}$"; 
                Rarity = "uncommon";
                Description = "Cyclic Redundancy Check 32B";
            },
            @{
                Name = "ADLER32"; 
                Regex = "^[a-fA-F0-9]{8}$"; 
                Rarity = "rare";
                Description = "Adler-32 checksum algorithm";
            },
            @{
                Name = "Domain Cached Credentials"; 
                Regex = "^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$"; 
                Rarity = "uncommon";
                Description = "Domain Cached Credentials (DCC1)";
            },
            @{
                Name = "Domain Cached Credentials 2"; 
                Regex = "^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$"; 
                Rarity = "uncommon";
                Description = "Domain Cached Credentials version 2 (DCC2)";
            },
            @{
                Name = "UNIX MD5 Crypt"; 
                Regex = '^\$1\$[a-zA-Z0-9./]{1,16}\$[a-zA-Z0-9./]{22}$'; 
                Rarity = "common";
                Description = "MD5 Crypt as used in Unix systems";
            },
            @{
                Name = "SHA-Crypt"; 
                Regex = '^\$5\$[a-zA-Z0-9./]+\$[a-zA-Z0-9./]{43}$'; 
                Rarity = "uncommon";
                Description = "SHA256-Crypt used in Unix systems";
            },
            @{
                Name = "SHA512-Crypt"; 
                Regex = '^\$6\$[a-zA-Z0-9./]+\$[a-zA-Z0-9./]{86}$'; 
                Rarity = "uncommon";
                Description = "SHA512-Crypt used in Unix systems";
            }
        )
        
        $allResults = @()
    }
    
    process {
        foreach ($h in $Hash) {
            $cleanHash = $h.Trim()
            $hashMatches = @()
            
            foreach ($hashType in $hashTypes) {
                if ($cleanHash -match $hashType.Regex) {
                    # Assign confidence level based on rarity and specificity
                    $confidence = switch ($hashType.Rarity) {
                        "common" { 
                            # For common hash types with same pattern, like MD5/NTLM both matching 32 hex chars
                            # Check if the regex is shared by multiple types
                            $patternCount = ($hashTypes | Where-Object { $_.Regex -eq $hashType.Regex }).Count
                            if ($patternCount -gt 1) { "medium" } else { "high" }
                        }
                        "uncommon" { "medium" }
                        "rare" { "low" }
                        default { "low" }
                    }
                    
                    $hashMatches += [PSCustomObject]@{
                        Name = $hashType.Name
                        Confidence = $confidence
                        Description = $hashType.Description
                    }
                }
            }
            
            # If no matches, add unknown result
            if ($hashMatches.Count -eq 0) {
                $hashMatches += [PSCustomObject]@{
                    Name = "Unknown"
                    Confidence = "unknown"
                    Description = "Could not identify this hash type"
                }
            }
            
            # Sort matches by confidence (high to low)
            $sortedMatches = $hashMatches | Sort-Object -Property @{
                Expression = {
                    switch ($_.Confidence) {
                        "high" { 1 }
                        "medium" { 2 }
                        "low" { 3 }
                        default { 4 }
                    }
                }
            }
            
            $result = [PSCustomObject]@{
                Hash = $cleanHash
                Matches = $sortedMatches
            }
            
            $allResults += $result
        }
    }
    
    end {
        switch ($OutputFormat) {
            'Object' {
                return $allResults
            }
            
            'Json' {
                return $allResults | ConvertTo-Json -Depth 5
            }
            
            default {
                # Text output similar to Name-That-Hash formatting
                foreach ($result in $allResults) {
                    Write-Host "`n[+] $($result.Hash)" -ForegroundColor Cyan
                    
                    foreach ($match in $result.Matches) {
                        $confidenceText = switch ($match.Confidence) {
                            "high" { "Most Likely" }
                            "medium" { "Possible" }
                            "low" { "Least Likely" }
                            default { "Unknown" }
                        }
                        
                        $color = switch ($match.Confidence) {
                            "high" { "Green" }
                            "medium" { "Yellow" }
                            "low" { "Gray" }
                            default { "Gray" }
                        }
                        
                        Write-Host "[$confidenceText] $($match.Name) - $($match.Description)" -ForegroundColor $color
                    }
                }
            }
        }
    }
}

Start-McpServer Get-HashType
