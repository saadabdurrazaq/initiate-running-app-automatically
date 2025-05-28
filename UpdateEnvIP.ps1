# $currentIp = (Get-NetIPAddress | Where-Object {
#         $_.AddressFamily -eq 'IPv4' -and 
#     ($_.IPAddress -like '192.168.*' -or $_.IPAddress -like '172.16.*' -or $_.IPAddress -like '10.*')
#     }).IPAddress

$currentIp = (Get-NetIPAddress | Where-Object {
    $_.InterfaceAlias -like '*Wi-Fi*' -and
    $_.AddressFamily -eq 'IPv4'
}).IPAddress

# Ensure IP address was found
if ($currentIp) {
    $env:PGPASSWORD = "your_pg_password"

    # Format the SQL queries as strings
    $query1 = "ALTER SERVER your_database OPTIONS (SET host '$currentIp', SET port '5432');"
    $query2 = "ALTER SERVER another_your_database OPTIONS (SET host '$currentIp', SET port '5432');"
    $query3 = "ALTER SERVER another_your_database OPTIONS (SET host '$currentIp', SET port '5432');"

    # Run SQL queries with dynamic IP replacement using proper escaping
    $psqlCommand1 = "psql -U postgres -d eams -c `"$query1`""
    $psqlCommand2 = "psql -U postgres -d eams -c `"$query2`""
    $psqlCommand3 = "psql -U postgres -d eams -c `"$query3`""

    try {
        # Execute the psql command for each server configuration update
        Invoke-Expression $psqlCommand1
        Invoke-Expression $psqlCommand2
        Invoke-Expression $psqlCommand3
        Write-Output "Database server configurations have been updated with the new IP address."
    }
    catch {
        Write-Error "Failed to execute SQL query: $_"
    }

    #####################################################################

    # Define the path to the .env file
    $envBEPath = "C:\xampp\htdocs\restek\eamms-be-main-juli\.env"
    $envFEPath = "C:\xampp\htdocs\restek\fe\.env"
    $envAbsensiFEPath = "C:\xampp\htdocs\restek\absensi-fe\.env"
    $envMobilePath = "C:\xampp\htdocs\restek\EAMMS-MOBILE\lib\core\environment\app_environment.dart"

    $oldIPBE = ""
    $oldIPFE = ""
    $oldIPMobile = ""
    $oldIPAbsensiFE = ""

    # Read the content of the .env file
    $envBEContent = Get-Content $envBEPath
    $envFEContent = Get-Content $envFEPath
    $envAbsensiFEContent = Get-Content $envAbsensiFEPath
    $envMobileContent = Get-Content $envMobilePath

    foreach ($line in $envBEContent) {
        if (![string]::IsNullOrWhiteSpace($line)) {
            # Skip empty or null lines
            if ($line.StartsWith("BASE_URL=http://")) {
                $oldIPBE = $line -replace "BASE_URL=http://", "" -split ":5000" | Select-Object -First 1
                # Write-Host "Found old IP: $oldIPBE"
            }
            else {
                # Write-Host "No match for BASE_URL in: $line"
            }
        }
        else {
            # Write-Host "Skipping empty or null line"
        }
    }

    foreach ($line in $envFEContent) {
        if (![string]::IsNullOrWhiteSpace($line)) {
            # Skip empty or null lines
            if ($line.StartsWith("VITE_STAGING_API_URL=http://")) {
                $oldIPFE = $line -replace "VITE_STAGING_API_URL=http://", "" -split ":5000" | Select-Object -First 1
                # Write-Host "Found old IP: $oldIPBE"
            }
            else {
                # Write-Host "No match for BASE_URL in: $line"
            }
        }
        else {
            # Write-Host "Skipping empty or null line"
        }
    }

    foreach ($line in $envAbsensiFEContent) {
        if (![string]::IsNullOrWhiteSpace($line)) {
            # Skip empty or null lines
            if ($line.StartsWith("VITE_STAGING_API_URL=http://")) {
                $oldIPAbsensiFE = $line -replace "VITE_STAGING_API_URL=http://", "" -split ":5000" | Select-Object -First 1
                # Write-Host "Found old IP: $oldIPAbsensiFE"
            }
            else {
                # Write-Host "No match for BASE_URL in: $line"
            }
        }
        else {
            # Write-Host "Skipping empty or null line"
        }
    }

    foreach ($line in $envMobileContent) {
        if (![string]::IsNullOrWhiteSpace($line)) {
            # Skip empty or null lines
            if ($line.StartsWith("baseURL = 'http://")) {
                $oldIPMobile = $line -replace "baseURL = 'http://", "" -split ":5000" | Select-Object -First 1
                # Write-Host "Found old IP: $oldIPBE"
            }
            else {
                # Write-Host "No match for BASE_URL in: $line"
            }
        }
        else {
            # Write-Host "Skipping empty or null line"
        }
    }

    $updatedBEContent = $envBEContent `
        -replace "BASE_URL=http://$oldIPBE", "BASE_URL=http://$currentIp" `
        -replace "URL_API=http://$oldIPBE", "URL_API=http://$currentIp" `
        -replace "DATABASE_URL=postgres://postgres:your_pg_password@$oldIPBE", "DATABASE_URL=postgres://postgres:your_pg_password@$currentIp" `
        -replace "DATABASE_TA_URL=postgres://postgres:your_pg_password@$oldIPBE", "DATABASE_TA_URL=postgres://postgres:your_pg_password@$currentIp"

    $updatedFEContent = $envFEContent `
        -replace "VITE_STAGING_API_URL=http://$oldIPFE", "VITE_STAGING_API_URL=http://$currentIp" `
        -replace "VITE_STAGING_USER_API_URL=http://$oldIPFE", "VITE_STAGING_USER_API_URL=http://$currentIp" 
    
    $updatedAbsensiFEContent = $envAbsensiFEContent `
        -replace "VITE_STAGING_API_URL=http://$oldIPAbsensiFE", "VITE_STAGING_API_URL=http://$currentIp" `
        -replace "VITE_STAGING_USER_API_URL=http://$oldIPAbsensiFE", "VITE_STAGING_USER_API_URL=http://$currentIp" 
        
    $updatedMobileContent = $envMobileContent `
        -replace "baseURL = 'http://$oldIPFE", "baseURL = 'http://$currentIp" `
        -replace "baseURLAuth = 'http://$oldIPFE", "baseURLAuth = 'http://$currentIp" 

    # Write the updated content back to the .env file
    Set-Content -Path $envBEPath -Value $updatedBEContent
    Set-Content -Path $envFEPath -Value $updatedFEContent
    Set-Content -Path $envAbsensiFEPath -Value $updatedAbsensiFEContent
    Set-Content -Path $envMobilePath -Value $updatedMobileContent

    # Output confirmation
    Write-Host "Updated .env files with IP $currentIp"

    ##################################################################

    # Close currently opened CMD windows
    Get-Process cmd -ErrorAction SilentlyContinue | ForEach-Object { $_.CloseMainWindow() }

    # Load the necessary assembly for SendKeys
    Add-Type -AssemblyName System.Windows.Forms

    # Define the list of tasks and their corresponding commands
    $tasks = @(
        @{Path = "C:\xampp\htdocs\restek\eamms-be-login"; Command = "yarn start" },
        @{Path = "C:\xampp\htdocs\restek\eamms-be-main-juli"; Command = "yarn start" },
        @{Path = "C:\xampp\htdocs\restek\fe"; Command = "npm run dev" },
        @{Path = "C:\xampp\htdocs\restek\absensi-fe"; Command = "npm run dev" }
    )

    # Function to send Ctrl+C to terminate a process
    function Send-CtrlC {
        param ([int]$handle)
        try {
            if ($handle -ne 0) {
                [System.Windows.Forms.SendKeys]::SendWait("^c")
                Start-Sleep -Seconds 2  # Allow time for task to terminate
            }
        }
        catch {
            Write-Error "Failed to send Ctrl+C to process handle {$handle}: $_"
        }
    }

    function Release-Port {
        param ([int]$port)
        try {
            $processUsingPort = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($processUsingPort) {
                Stop-Process -Id $processUsingPort.OwningProcess -Force
                Write-Host "Released port $port by terminating process ID $($processUsingPort.OwningProcess)"
            }
        }
        catch {
            Write-Error "Failed to release port {$port}: $_"
        }
    }

    # Check running CMD processes and their tasks
    Get-Process cmd -ErrorAction SilentlyContinue | ForEach-Object {
        $cmd = $_
        $isTaskRunning = $false

        try {
            # Check if the CMD process is running a task by examining its MainWindowTitle
            foreach ($task in $tasks) {
                if ($cmd.MainWindowTitle -like "*$($task.Path)*" -and $cmd.MainWindowTitle -like "*$($task.Command)*") {
                    Write-Host "Task running in CMD window: $($cmd.MainWindowTitle)"
                    $isTaskRunning = $true

                    # Terminate the running task with Ctrl+C
                    Send-CtrlC -handle $cmd.MainWindowHandle

                    # Forcefully stop if still running
                    if (!$cmd.HasExited) {
                        Stop-Process -Id $cmd.Id -Force
                    }

                    # Wait for the process to terminate gracefully
                    Start-Sleep -Seconds 2

                    # Release the port used by the specific task
                    if ($task.Path -like "*eamms-be-login*") {
                        Release-Port -port 3001
                    }
                
                    # $cmd.CloseMainWindow()

                    Write-Host "Stopped task in CMD process ID $($cmd.Id)"
                    break
                }
            }

            if (-not $isTaskRunning) {
                Write-Host "CMD window ID $($cmd.Id) is not running a matching task."
                $cmd.CloseMainWindow()
            }
        }
        catch {
            Write-Error "Failed to check CMD process ID $($cmd.Id): $_"
        }
    }

    # Wait before starting new tasks
    Start-Sleep -Seconds 2

    # Start the defined tasks
    foreach ($task in $tasks) {
        $cmdPath = $task.Path
        $cmdCommand = $task.Command
        Start-Process cmd.exe -ArgumentList "/K cd $cmdPath && $cmdCommand"
        Write-Host "Started task in CMD window: cd $cmdPath && $cmdCommand"
    }

    # Output confirmation
    Write-Output "The .env file has been updated with currentIP: $currentIp and the app is started automatically."

}
else {
    Write-Output "No IP address found. Please check your network connection."
}





