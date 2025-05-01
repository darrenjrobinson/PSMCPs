#Requires -Module PSMCP

Set-LogFile "$PSScriptRoot\mcp_server.log"

function Global:Get-WeatherForecast {
    <#
    .SYNOPSIS
        Gets weather forecast for a specified location.
    
    .DESCRIPTION
        Retrieves weather forecast data from Open-Meteo API for a given location specified
        either by city name or geographical coordinates. Can return forecast for the current
        day or up to 7 days.
        
        The function uses the free Open-Meteo weather API which doesn't require an API key
        and provides weather data worldwide. It automatically handles the geocoding of city names
        to coordinates using Open-Meteo's Geocoding API.
        
        Weather data includes temperature, precipitation, wind speed, and more, presented
        either as daily summaries or detailed hourly breakdowns.
    
    .PARAMETER City
        The name of the city to get weather forecast for. The function will attempt to geocode
        this city name to coordinates using the Open-Meteo Geocoding API. You can include the 
        country name for more accurate results (e.g., "London, UK" instead of just "London").
        
        This parameter cannot be used with Latitude and Longitude parameters.
    
    .PARAMETER Latitude
        The latitude coordinate of the location, specified as a decimal degree value between -90 and 90.
        Must be used together with the Longitude parameter. Use this parameter when you know the
        exact coordinates of a location or when you need weather data for a location that isn't
        a specific city or named place.
    
    .PARAMETER Longitude
        The longitude coordinate of the location, specified as a decimal degree value between -180 and 180.
        Must be used together with the Latitude parameter. Use this parameter when you know the
        exact coordinates of a location or when you need weather data for a location that isn't
        a specific city or named place.
    
    .PARAMETER Days
        Number of days to forecast, ranging from 1 to 7. Default is 1 (current day only).
        
        The value 1 returns today's forecast only.
        Values 2-7 include forecasts for additional days.
        
        Note that the Open-Meteo API supports forecasts up to 16 days ahead, but this function
        is limited to 7 days for more accurate results.
    
    .PARAMETER Detailed
        If specified, returns hourly forecast data instead of daily summary. This provides 
        hour-by-hour weather information including temperature, humidity, precipitation, and
        wind speed for each hour of the forecast period.
        
        Without this switch, the function returns one summary record per day with min/max values
        and total precipitation.
        
        Using this switch significantly increases the amount of data returned, especially 
        when combined with a higher number of Days.
    
    .EXAMPLE
        Get-WeatherForecast -City "New York"
        
        Returns today's weather forecast summary for New York City.
    
    .EXAMPLE
        Get-WeatherForecast -City "London, UK" -Days 3
        
        Returns weather forecast summaries for London, UK for today and the next 2 days (3 days total).
    
    .EXAMPLE
        Get-WeatherForecast -Latitude 40.7128 -Longitude -74.0060 -Days 3
        
        Returns weather forecast summaries for the coordinates 40.7128°N, 74.0060°W (New York City)
        for today and the next 2 days.
    
    .EXAMPLE
        Get-WeatherForecast -City "Tokyo" -Days 7 -Detailed
        
        Returns detailed hourly weather forecasts for Tokyo for the next 7 days.
        
    .EXAMPLE
        Get-WeatherForecast -City "Sydney" -Verbose
        
        Returns today's weather forecast for Sydney with verbose output showing the geocoding process
        and API calls being made.
    #>
    [CmdletBinding(DefaultParameterSetName = 'City')]
    param (
        [Parameter(ParameterSetName = 'City', Mandatory = $true)]
        [string]$City,
        
        [Parameter(ParameterSetName = 'Coordinates', Mandatory = $true)]
        [ValidateRange(-90, 90)]
        [double]$Latitude,
        
        [Parameter(ParameterSetName = 'Coordinates', Mandatory = $true)]
        [ValidateRange(-180, 180)]
        [double]$Longitude,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 7)]
        [int]$Days = 1,
        
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    
    # If city is provided, get coordinates using Geocoding API
    if ($PSCmdlet.ParameterSetName -eq 'City') {
        try {
            Write-Verbose "Resolving coordinates for city: $City"
            $geocodeUrl = "https://geocoding-api.open-meteo.com/v1/search?name=$([System.Web.HttpUtility]::UrlEncode($City))&count=1&language=en&format=json"
            $geocodeResponse = Invoke-RestMethod -Uri $geocodeUrl -Method Get
            
            if (-not $geocodeResponse.results -or $geocodeResponse.results.Count -eq 0) {
                Write-Error "Could not find coordinates for city: $City"
                return
            }
            
            $Latitude = $geocodeResponse.results[0].latitude
            $Longitude = $geocodeResponse.results[0].longitude
            $resolvedCity = $geocodeResponse.results[0].name
            $country = $geocodeResponse.results[0].country
            
            Write-Verbose "Resolved to: $resolvedCity, $country ($Latitude, $Longitude)"
        }
        catch {
            Write-Error "Error resolving city coordinates: $_"
            return
        }
    }
    
    # Build the forecast API URL
    $forecastUrl = "https://api.open-meteo.com/v1/forecast?latitude=$Latitude&longitude=$Longitude&timezone=auto"
    
    # Add parameters based on whether detailed or summary view is requested
    if ($Detailed) {
        $forecastUrl += "&hourly=temperature_2m,relativehumidity_2m,precipitation,windspeed_10m&forecast_days=$Days"
    }
    else {
        $forecastUrl += "&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max&forecast_days=$Days"
    }
    
    try {
        Write-Verbose "Fetching weather data from: $forecastUrl"
        $weatherData = Invoke-RestMethod -Uri $forecastUrl -Method Get
        
        # Process and format the response
        $locationName = if ($PSCmdlet.ParameterSetName -eq 'City') { "$resolvedCity, $country" } else { "Lat: $Latitude, Lon: $Longitude" }
        
        if ($Detailed) {
            # Return detailed hourly forecast
            $result = [PSCustomObject]@{
                Location = $locationName
                Timezone = $weatherData.timezone
                Hourly = @()
            }
            
            for ($i = 0; $i -lt ($Days * 24) -and $i -lt $weatherData.hourly.time.Count; $i++) {
                $hourlyData = [PSCustomObject]@{
                    Time = [datetime]$weatherData.hourly.time[$i]
                    Temperature = "$($weatherData.hourly.temperature_2m[$i]) $($weatherData.hourly_units.temperature_2m)"
                    Humidity = "$($weatherData.hourly.relativehumidity_2m[$i]) $($weatherData.hourly_units.relativehumidity_2m)"
                    Precipitation = "$($weatherData.hourly.precipitation[$i]) $($weatherData.hourly_units.precipitation)"
                    WindSpeed = "$($weatherData.hourly.windspeed_10m[$i]) $($weatherData.hourly_units.windspeed_10m)"
                }
                $result.Hourly += $hourlyData
            }
        }
        else {
            # Return daily summary
            $result = [PSCustomObject]@{
                Location = $locationName
                Timezone = $weatherData.timezone
                Daily = @()
            }
            
            for ($i = 0; $i -lt $Days -and $i -lt $weatherData.daily.time.Count; $i++) {
                $dailyData = [PSCustomObject]@{
                    Date = [datetime]$weatherData.daily.time[$i]
                    WeatherCode = Get-WeatherDescription -Code $weatherData.daily.weathercode[$i]
                    MaxTemperature = "$($weatherData.daily.temperature_2m_max[$i]) $($weatherData.daily_units.temperature_2m_max)"
                    MinTemperature = "$($weatherData.daily.temperature_2m_min[$i]) $($weatherData.daily_units.temperature_2m_min)"
                    Precipitation = "$($weatherData.daily.precipitation_sum[$i]) $($weatherData.daily_units.precipitation_sum)"
                    MaxWindSpeed = "$($weatherData.daily.windspeed_10m_max[$i]) $($weatherData.daily_units.windspeed_10m_max)"
                }
                $result.Daily += $dailyData
            }
        }
        
        return $result
    }
    catch {
        Write-Error "Error retrieving weather forecast: $_"
    }
}

function Global:Get-WeatherDescription {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Code
    )
    
    # WMO Weather interpretation codes (https://open-meteo.com/en/docs)
    switch ($Code) {
        0 { "Clear sky" }
        1 { "Mainly clear" }
        2 { "Partly cloudy" }
        3 { "Overcast" }
        45 { "Fog" }
        48 { "Depositing rime fog" }
        51 { "Light drizzle" }
        53 { "Moderate drizzle" }
        55 { "Dense drizzle" }
        56 { "Light freezing drizzle" }
        57 { "Dense freezing drizzle" }
        61 { "Slight rain" }
        63 { "Moderate rain" }
        65 { "Heavy rain" }
        66 { "Light freezing rain" }
        67 { "Heavy freezing rain" }
        71 { "Slight snow fall" }
        73 { "Moderate snow fall" }
        75 { "Heavy snow fall" }
        77 { "Snow grains" }
        80 { "Slight rain showers" }
        81 { "Moderate rain showers" }
        82 { "Violent rain showers" }
        85 { "Slight snow showers" }
        86 { "Heavy snow showers" }
        95 { "Thunderstorm" }
        96 { "Thunderstorm with slight hail" }
        99 { "Thunderstorm with heavy hail" }
        default { "Unknown weather code: $Code" }
    }
}

<#
.SYNOPSIS 
   Get my public IP Address  

   .DESCRIPTION
   Uses http://ipinfo.io/json to get the public IP Address of the machine running this script.
   This is useful for testing and debugging purposes, especially when working with APIs that require a public IP Address.
   It is also useful to then use functions like Find-Geolocation to get the geolocation information of the public IP Address.

   .EXAMPLE
    Get-PublicIPAddress

    .OUTPUTS
    Returns the public IP Address of the machine running the script.
#>

function Global:Get-PublicIPAddress {
    [CmdletBinding()]
    Param
    ()
    Begin {
        Write-Verbose -Message "Getting public IP Address"
    }
    Process {
        try {
            $ip = Invoke-RestMethod http://ipinfo.io/json | Select-Object -exp ip
            Write-Output $ip
        }
        catch {
            Write-Warning -Message "Unable to get public IP Address: $_"
        }
    }
    End {
    }
}


<#
.Synopsis
   Can resolve either an IP Address or a Domain Name and give you geolocation information.
.DESCRIPTION
   This module is using https://freegeoip.live API which is free. Yes. It's totally free. They believe that digital businesses need to get such kind of service for free. Many services are selling Geoip API as a service, but they think that it should be totally free. Feel free to their API as much as you want without any limit other than 10,000 queries per hour for one IP address. I thought this would be another good addition to add to the Powershell Gallery.
.Parameter IP
   This parameter is used to specify the IP Address you want to find the geolocation information
.Parameter DomainName
   This parameter is used to specify the Domain Name address you want to find the geolocation information
.EXAMPLE
   Find-Geolocation -DomainName portsmouth.co.uk
.EXAMPLE
   Find-Geolocation -IP 141.193.213.10
#>
function Global:Find-Geolocation {
    [CmdletBinding()]
    Param
    (
        [Parameter(ParameterSetName = 'IP Address Parameter Set')]
        [ipaddress]$IP,
        [Parameter(ParameterSetName = 'Domain Name Parameter Set')]
        [System.Uri]$DomainName
    )

    Begin {
        if ($IP) {
            $Pattern = $IP
        }
        if ($DomainName) {
            $Pattern = $DomainName
        }
    }
    Process {
        foreach ($item in $Pattern) {
            Write-Verbose -Message "About to find out more information on $item"
            try {
                Invoke-RestMethod -Method Get -Uri https://freegeoip.live/json/$item -ErrorAction Stop
            }
            catch {
                Write-Warning -Message "$item : $_"
            }
        }
    }
    End {
    }
}


Start-McpServer Find-Geolocation, Get-PublicIPAddress, Get-WeatherForecast, Get-WeatherDescription  
