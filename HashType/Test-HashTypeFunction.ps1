# Test-HashTypeFunction.ps1
# Script to test the Get-HashType function with examples of different hash types

# Import the Get-HashType function
# . "$PSScriptRoot\Get-HashType.ps1"

# Set up colors for output
$colorSuccess = "Green"
$colorFail = "Red"
$colorInfo = "Cyan"
$colorWarning = "Yellow"

Write-Host "Testing Get-HashType function with examples of each hash type..." -ForegroundColor $colorInfo

# Create a hashtable of test cases with hash examples and expected types
# Format: @{ "HashExample" = @("ExpectedPrimaryType", "AlternativeAcceptableType1", ...) }
$testCases = @{
    # Common hash types
    "5f4dcc3b5aa765d61d8327deb882cf99"                = @("MD5", "NTLM", "MD4", "LM") # "password" in MD5
    "da39a3ee5e6b4b0d3255bfef95601890afd80709"        = @("SHA1", "RIPEMD160") # Empty string in SHA1
    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" = @("SHA256", "SHA3-256") # Empty string in SHA256
    "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e" = @("SHA512", "SHA3-512", "Whirlpool") # Empty string in SHA512
    
    # Authentication hashes
    "AAD3B435B51404EEAAD3B435B51404EE:8846F7EAEE8FB117AD06BDD830B7586C" = @("NetNTLMv1", "Domain Cached Credentials", "Domain Cached Credentials 2")
    "admin::N46iSNekpT:08ca45b7d7ea58ee:88dcbe4446168966a153a0064958dac6:5c7830315c7830310000000000000b45c67103d07d7b95acd12ffa11230e0000000052920b85f78d013c31cdb3b92f5d765c783030" = @("NetNTLMv2")
    
    # Unix password hashes
    '$1$salt$qJH7.N4xYta3aEG/dfqo/0' = @("UNIX MD5 Crypt")
    '$5$salt$Gcm6FsVtF/Qa77ZKD.iwsJlCVPY0XSMgLJL0Hnww/c1' = @("SHA-Crypt")
    '$6$salt$IxDD3jeSOb5eB1CX5LBsqZFVkJdido3OUILO5Ifz5iwMuTS4XMS130MTSuDDl3aCI6WouIL9AjRbLCelDCy.g.' = @("SHA512-Crypt")
    
    # Modern password hashes
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy' = @("BCrypt")
    '$argon2i$v=19$m=16,t=2,p=1$cGFzc3dvcmRwYXNzd29yZA$GpZ3sK/oEzl6.ehRpzxSwA' = @("Argon2")
    '$pbkdf2-sha256$29000$PIdwrhXiXKuVsvY.R2jN2Q$1akqp03PqZWqj5MmXq5R5pccvFrGwgTOl8KqYW9QTCg' = @("PBKDF2")
    '$scrypt$ln=16,r=8,p=1$aM15713r3Xsvxbi31lqr1Q$uL5WIN5ZZJdLWPI0Zn0lyQf5h25UKlHQTt511vPQpws' = @("Scrypt")
    
    # Database hashes
    "7af2d10b73ab6d78db6d78db6d" = @("MySQL323")
    "*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19" = @("MySQL4.1+")
    
    # Checksums
    "d41d8cd9" = @("CRC32", "CRC32B", "ADLER32")
    
    # Various SHA hash lengths
    "d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f" = @("SHA224", "SHA3-224")
    "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b" = @("SHA384", "SHA3-384")
}

# Initialize counters
$totalTests = $testCases.Count
$passedTests = 0
$failedTests = 0

# Function to test if any expected type is in the top results
function Test-ContainsExpectedType {
    param (
        [PSCustomObject[]]$Results,
        [string[]]$ExpectedTypes
    )
    
    foreach ($match in $Results) {
        if ($ExpectedTypes -contains $match.Name) {
            return $true
        }
    }
    return $false
}

# Run tests for each hash example
foreach ($hash in $testCases.Keys) {
    $expectedTypes = $testCases[$hash]
    
    Write-Host "`nTesting hash: " -NoNewline
    Write-Host $hash -ForegroundColor $colorInfo
    Write-Host "Expected type(s): " -NoNewline
    Write-Host ($expectedTypes -join ", ") -ForegroundColor $colorInfo
    
    # Call Get-HashType with the test hash
    try {
        $result = Get-HashType -Hash $hash -OutputFormat Object
        $topResults = $result.Matches | Where-Object { $_.Confidence -eq "high" -or $_.Confidence -eq "medium" }
        
        # Check if any of the expected types are in the top results
        $foundExpectedType = Test-ContainsExpectedType -Results $topResults -ExpectedTypes $expectedTypes
        
        # Output test status
        if ($foundExpectedType) {
            Write-Host "✓ PASS: Found expected type in results" -ForegroundColor $colorSuccess
            $passedTests++
        } else {
            Write-Host "✗ FAIL: Did not find expected type in top results" -ForegroundColor $colorFail
            $failedTests++
            
            # Show what was found instead
            Write-Host "  Found types: " -NoNewline
            Write-Host (($topResults | ForEach-Object { $_.Name }) -join ", ") -ForegroundColor $colorWarning
        }
    }
    catch {
        Write-Host "✗ FAIL: Error processing hash: $_" -ForegroundColor $colorFail
        $failedTests++
    }
}

# Output summary
Write-Host "`n===== TEST SUMMARY =====" -ForegroundColor $colorInfo
Write-Host "Total Tests: $totalTests" -ForegroundColor $colorInfo
Write-Host "Passed: $passedTests" -ForegroundColor $colorSuccess
Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -eq 0) { $colorSuccess } else { $colorFail })
Write-Host "Success Rate: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor $colorInfo

# Exit with code based on test results
if ($failedTests -eq 0) {
    Write-Host "`n✅ All tests passed! The Get-HashType function is working correctly." -ForegroundColor $colorSuccess
    exit 0
} else {
    Write-Host "`n❌ Some tests failed. Review the output above for details." -ForegroundColor $colorFail
    exit 1
}
