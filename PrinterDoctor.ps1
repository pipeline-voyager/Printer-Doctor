#requires -version 5.1
<#
    Printer Troubleshooter TUI
    Version 1.0.0

    Navigation:
      Up / Down  = Navigate
      Enter      = Select
      Escape     = Back
      Escape on Main Menu = Exit

    Text Input:
      Enter      = Accept
      Escape     = Cancel / Back
      Backspace  = Delete Character
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# GLOBAL STATE
# ============================================================

$Script:App = @{
    Title           = "PRINTER TROUBLESHOOTING CONSOLE"
    Version         = "1.0"
    Running         = $true
    MenuStack       = New-Object System.Collections.ArrayList
    CurrentPrinter  = $null
    CurrentPort     = $null
    CurrentDriver   = $null
    LastResult      = @()
    ReportDirectory = Join-Path $env:USERPROFILE "PrinterTroubleshooterReports"
}

$Script:Colors = @{
    NormalForeground   = [ConsoleColor]::Gray
    NormalBackground   = [ConsoleColor]::Black

    HeaderForeground   = [ConsoleColor]::White
    HeaderBackground   = [ConsoleColor]::DarkBlue

    SelectedForeground = [ConsoleColor]::Black
    SelectedBackground = [ConsoleColor]::White

    TitleForeground    = [ConsoleColor]::White
    TitleBackground    = [ConsoleColor]::DarkBlue

    SuccessForeground  = [ConsoleColor]::Green
    WarningForeground  = [ConsoleColor]::Yellow
    ErrorForeground    = [ConsoleColor]::Red
    InfoForeground     = [ConsoleColor]::Cyan

    BorderForeground   = [ConsoleColor]::DarkGray
}

# ============================================================
# BASIC CONSOLE FUNCTIONS
# ============================================================

function Get-TerminalWidth {
    try {
        $width = [Console]::WindowWidth

        if ($width -lt 40) {
            return 40
        }

        return $width
    }
    catch {
        return 100
    }
}

function Get-TerminalHeight {
    try {
        return [Console]::WindowHeight
    }
    catch {
        return 30
    }
}

function Clear-Console {
    [Console]::Clear()
    [Console]::CursorVisible = $false
}

function Set-NormalColor {
    [Console]::ForegroundColor = $Script:Colors.NormalForeground
    [Console]::BackgroundColor = $Script:Colors.NormalBackground
}

function Write-FullLine {
    param(
        [string]$Text = "",
        [ConsoleColor]$Foreground = $Script:Colors.NormalForeground,
        [ConsoleColor]$Background = $Script:Colors.NormalBackground
    )

    $width = Get-TerminalWidth

    if ($null -eq $Text) {
        $Text = ""
    }

    if ($Text.Length -gt $width) {
        $Text = $Text.Substring(0, $width)
    }

    $line = $Text.PadRight($width)

    [Console]::ForegroundColor = $Foreground
    [Console]::BackgroundColor = $Background
    [Console]::Write($line)

    Set-NormalColor
}

function Write-Header {
    param(
        [string]$Title
    )

    $width = Get-TerminalWidth

    Clear-Console

    Write-FullLine `
        -Text $Script:App.Title `
        -Foreground $Script:Colors.TitleForeground `
        -Background $Script:Colors.TitleBackground

    $versionText = "Version $($Script:App.Version)"

    $header = $Title

    if ($header.Length -gt ($width - $versionText.Length - 3)) {
        $header = $header.Substring(
            0,
            [Math]::Max(0, $width - $versionText.Length - 3)
        )
    }

    $remaining = $width - $header.Length - $versionText.Length

    if ($remaining -lt 1) {
        $remaining = 1
    }

    $line = $header + (" " * $remaining) + $versionText

    Write-FullLine `
        -Text $line `
        -Foreground $Script:Colors.HeaderForeground `
        -Background $Script:Colors.HeaderBackground

    Write-FullLine `
        -Text ("-" * $width) `
        -Foreground $Script:Colors.BorderForeground `
        -Background $Script:Colors.NormalBackground
}

function Write-StatusBar {
    param(
        [string]$Text
    )

    $width = Get-TerminalWidth

    Write-FullLine `
        -Text $Text `
        -Foreground $Script:Colors.NormalForeground `
        -Background $Script:Colors.NormalBackground
}

function Write-Info {
    param([string]$Text)

    Write-Host $Text -ForegroundColor $Script:Colors.InfoForeground
}

function Write-Success {
    param([string]$Text)

    Write-Host $Text -ForegroundColor $Script:Colors.SuccessForeground
}

function Write-WarningMessage {
    param([string]$Text)

    Write-Host $Text -ForegroundColor $Script:Colors.WarningForeground
}

function Write-ErrorMessage {
    param([string]$Text)

    Write-Host $Text -ForegroundColor $Script:Colors.ErrorForeground
}

function Write-Section {
    param(
        [string]$Text
    )

    Write-Host ""
    Write-Host "[$Text]" -ForegroundColor White
    Write-Host (
        "-" * [Math]::Min((Get-TerminalWidth), 80)
    ) -ForegroundColor DarkGray
}

function Write-KeyValue {
    param(
        [string]$Name,
        [object]$Value,
        [int]$Width = 25
    )

    $displayValue = if (
        $null -eq $Value -or
        $Value -eq ""
    ) {
        "N/A"
    }
    else {
        [string]$Value
    }

    Write-Host (
        $Name.PadRight($Width) + ": " + $displayValue
    )
}

# ============================================================
# INPUT
# ESCAPE NOW CANCELS TEXT INPUT
# ============================================================

function Read-TextInput {
    param(
        [string]$Prompt,
        [string]$Default = ""
    )

    [Console]::CursorVisible = $true

    Write-Host ""
    Write-Host $Prompt -ForegroundColor White

    if ($Default -ne "") {
        Write-Host "[$Default]" -ForegroundColor DarkGray -NoNewline
        Write-Host " " -NoNewline
    }

    Write-Host ""

    $inputBuffer = New-Object System.Text.StringBuilder

    while ($true) {

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {

            "Escape" {

                [Console]::CursorVisible = $false

                return $null
            }

            "Enter" {

                [Console]::CursorVisible = $false

                $value = $inputBuffer.ToString()

                if (
                    [string]::IsNullOrWhiteSpace($value) -and
                    $Default -ne ""
                ) {
                    return $Default
                }

                return $value
            }

            "Backspace" {

                if ($inputBuffer.Length -gt 0) {

                    $inputBuffer.Remove(
                        $inputBuffer.Length - 1,
                        1
                    ) | Out-Null

                    [Console]::Write("`b `b")
                }
            }

            default {

                if (
                    $key.KeyChar -ne [char]0 -and
                    -not [char]::IsControl($key.KeyChar)
                ) {

                    [void]$inputBuffer.Append($key.KeyChar)

                    [Console]::Write($key.KeyChar)
                }
            }
        }
    }
}

function Pause-Console {
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray

    [Console]::ReadKey($true) | Out-Null
}

# ============================================================
# MENU ENGINE
# ============================================================

function Show-TuiMenu {
    param(
        [string]$Title,
        [array]$Items,
        [string]$Footer = "`n[UP/DOWN] Navigate   [ENTER] Select   [ESC] Back"
    )

    $selected = 0
    $lastSelected = -1
    $lastWidth = Get-TerminalWidth

    Clear-Console

    while ($true) {

        $currentWidth = Get-TerminalWidth

        if ($currentWidth -ne $lastWidth) {

            Clear-Console

            $lastSelected = -1
            $lastWidth = $currentWidth
        }

        if ($selected -ne $lastSelected) {

            Clear-Console

            Write-Header -Title $Title

            Write-Host ""

            for ($i = 0; $i -lt $Items.Count; $i++) {

                $item = $Items[$i]

                if ($null -eq $item) {
                    continue
                }

                $label = [string]$item.Label

                if ($label.Length -gt $currentWidth) {
                    $label = $label.Substring(
                        0,
                        $currentWidth
                    )
                }

                if ($i -eq $selected) {

                    Write-FullLine `
                        -Text $label `
                        -Foreground $Script:Colors.SelectedForeground `
                        -Background $Script:Colors.SelectedBackground
                }
                else {

                    Write-FullLine `
                        -Text $label `
                        -Foreground $Script:Colors.NormalForeground `
                        -Background $Script:Colors.NormalBackground
                }
            }

            Write-Host ""

            Write-FullLine `
                -Text $Footer `
                -Foreground $Script:Colors.NormalForeground `
                -Background $Script:Colors.NormalBackground

            $lastSelected = $selected
        }

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {

            "UpArrow" {

                $selected--

                if ($selected -lt 0) {
                    $selected = $Items.Count - 1
                }
            }

            "DownArrow" {

                $selected++

                if ($selected -ge $Items.Count) {
                    $selected = 0
                }
            }

            "Enter" {

                return $Items[$selected]
            }

            "Escape" {

                return $null
            }
        }
    }
}

function Show-ActionMenu {
    param(
        [string]$Title,
        [array]$Items
    )

    return Show-TuiMenu `
        -Title $Title `
        -Items $Items
}

# ============================================================
# PRINTER DISCOVERY
# ============================================================

function Get-PrinterObjects {

    try {

        return @(
            Get-Printer -ErrorAction Stop
        )
    }
    catch {

        try {

            return @(
                Get-CimInstance `
                    Win32_Printer `
                    -ErrorAction Stop
            )
        }
        catch {

            return @()
        }
    }
}

function Get-PrinterObject {
    param(
        [string]$Name
    )

    try {

        return Get-Printer `
            -Name $Name `
            -ErrorAction Stop
    }
    catch {

        try {

            return Get-CimInstance `
                Win32_Printer `
                -Filter (
                    "Name='{0}'" -f
                    $Name.Replace("'", "''")
                ) `
                -ErrorAction Stop
        }
        catch {

            return $null
        }
    }
}

function Select-Printer {

    $printers = @(Get-PrinterObjects)

    if ($printers.Count -eq 0) {

        Write-ErrorMessage "No printers were found."

        Pause-Console

        return $null
    }

    $items = @()

    foreach ($printer in $printers) {

        $name = $printer.Name

        if ([string]::IsNullOrWhiteSpace($name)) {
            $name = "Unnamed Printer"
        }

        $status = ""

        if (
            $printer.PSObject.Properties.Name -contains
            "PrinterStatus"
        ) {

            $status = [string]$printer.PrinterStatus
        }
        elseif (
            $printer.PSObject.Properties.Name -contains
            "Status"
        ) {

            $status = [string]$printer.Status
        }

        if ([string]::IsNullOrWhiteSpace($status)) {
            $status = "Unknown"
        }

        $items += [PSCustomObject]@{
            Label = "$name  [$status]"
            Value = $name
        }
    }

    $choice = Show-TuiMenu `
        -Title "SELECT PRINTER" `
        -Items $items

    if ($null -eq $choice) {
        return $null
    }

    $Script:App.CurrentPrinter =
        Get-PrinterObject -Name $choice.Value

    return $Script:App.CurrentPrinter
}

# ============================================================
# PRINTER STATUS
# ============================================================

function Show-PrinterStatus {
    param(
        [object]$Printer
    )

    if ($null -eq $Printer) {

        $Printer = Select-Printer
    }

    if ($null -eq $Printer) {
        return
    }

    Write-Header -Title "PRINTER STATUS"

    Write-Section "Printer"

    Write-KeyValue "Name" $Printer.Name
    Write-KeyValue "Computer" $Printer.ComputerName
    Write-KeyValue "Driver" $Printer.DriverName
    Write-KeyValue "Port" $Printer.PortName
    Write-KeyValue "Shared" $Printer.Shared
    Write-KeyValue "Published" $Printer.Published
    Write-KeyValue "Default" $Printer.Default

    if (
        $Printer.PSObject.Properties.Name -contains
        "PrinterStatus"
    ) {

        Write-KeyValue `
            "Printer Status" `
            $Printer.PrinterStatus
    }

    if (
        $Printer.PSObject.Properties.Name -contains
        "WorkOffline"
    ) {

        Write-KeyValue `
            "Work Offline" `
            $Printer.WorkOffline
    }

    if (
        $Printer.PSObject.Properties.Name -contains
        "KeepPrintedJobs"
    ) {

        Write-KeyValue `
            "Keep Printed Jobs" `
            $Printer.KeepPrintedJobs
    }

    if (
        $Printer.PSObject.Properties.Name -contains
        "Location"
    ) {

        Write-KeyValue `
            "Location" `
            $Printer.Location
    }

    if (
        $Printer.PSObject.Properties.Name -contains
        "Comment"
    ) {

        Write-KeyValue `
            "Comment" `
            $Printer.Comment
    }

    Pause-Console
}

# ============================================================
# DEFAULT PRINTER
# ============================================================

function Set-PrinterDefault {
    param(
        [object]$Printer
    )

    if ($null -eq $Printer) {
        $Printer = Select-Printer
    }

    if ($null -eq $Printer) {
        return
    }

    try {

        $printerName = $Printer.Name

        $printerCim =
            Get-CimInstance Win32_Printer `
                -Filter (
                    "Name='{0}'" -f
                    $printerName.Replace("'", "''")
                )

        if ($printerCim) {

            Invoke-CimMethod `
                -InputObject $printerCim `
                -MethodName SetDefaultPrinter |
                Out-Null

            Write-Success `
                "Default printer changed to: $printerName"
        }
        else {

            Write-ErrorMessage `
                "Unable to access printer through WMI/CIM."
        }
    }
    catch {

        Write-ErrorMessage `
            "Unable to set default printer."

        Write-Host $_.Exception.Message
    }

    Pause-Console
}

# ============================================================
# PRINTER QUEUE
# ============================================================

function Get-PrinterJobs {
    param(
        [string]$PrinterName
    )

    try {

        return @(
            Get-PrintJob `
                -PrinterName $PrinterName `
                -ErrorAction Stop
        )
    }
    catch {

        return @()
    }
}

function Show-PrinterQueue {
    param(
        [object]$Printer
    )

    if ($null -eq $Printer) {
        $Printer = Select-Printer
    }

    if ($null -eq $Printer) {
        return
    }

    Write-Header -Title "PRINT QUEUE"

    $jobs = @(
        Get-PrinterJobs `
            -PrinterName $Printer.Name
    )

    if ($jobs.Count -eq 0) {

        Write-Success `
            "No print jobs are currently queued."

        Pause-Console

        return
    }

    Write-Section "Jobs"

    foreach ($job in $jobs) {

        Write-Host ("ID       : " + $job.Id)
        Write-Host (
            "Document : " + $job.DocumentName
        )
        Write-Host (
            "User     : " + $job.UserName
        )
        Write-Host (
            "Status   : " + $job.JobStatus
        )
        Write-Host (
            "Size     : " + $job.Size
        )
        Write-Host (
            "Pages    : " + $job.PagesPrinted
        )
        Write-Host ""
    }

    Pause-Console
}

function Remove-AllPrinterJobs {
    param(
        [object]$Printer
    )

    if ($null -eq $Printer) {
        $Printer = Select-Printer
    }

    if ($null -eq $Printer) {
        return
    }

    $jobs = @(
        Get-PrinterJobs `
            -PrinterName $Printer.Name
    )

    if ($jobs.Count -eq 0) {

        Write-Info "There are no queued jobs."

        Pause-Console

        return
    }

    Write-Host ""

    Write-WarningMessage `
        "This will remove all jobs from:"

    Write-Host $Printer.Name

    $confirm =
        Read-TextInput "Type YES to continue"

    # ESC = cancel
    if ($null -eq $confirm) {
        return
    }

    if ($confirm -ne "YES") {

        Write-Info "Operation cancelled."

        Pause-Console

        return
    }

    foreach ($job in $jobs) {

        try {

            Remove-PrintJob `
                -PrinterName $Printer.Name `
                -ID $job.Id `
                -ErrorAction Stop
        }
        catch {

            Write-WarningMessage `
                "Unable to remove job $($job.Id)."
        }
    }

    Write-Success "Queue cleanup completed."

    Pause-Console
}

function Remove-SelectedPrinterJob {
    param(
        [object]$Printer
    )

    if ($null -eq $Printer) {
        $Printer = Select-Printer
    }

    if ($null -eq $Printer) {
        return
    }

    $jobs = @(
        Get-PrinterJobs `
            -PrinterName $Printer.Name
    )

    if ($jobs.Count -eq 0) {

        Write-Info "No jobs found."

        Pause-Console

        return
    }

    $items = @()

    foreach ($job in $jobs) {

        $items += [PSCustomObject]@{
            Label = (
                "[$($job.Id)] " +
                "$($job.DocumentName) - " +
                "$($job.UserName)"
            )
            Value = $job
        }
    }

    $choice = Show-TuiMenu `
        -Title "SELECT PRINT JOB" `
        -Items $items

    if ($null -eq $choice) {
        return
    }

    try {

        Remove-PrintJob `
            -PrinterName $Printer.Name `
            -ID $choice.Value.Id `
            -ErrorAction Stop

        Write-Success "Print job removed."
    }
    catch {

        Write-ErrorMessage `
            "Unable to remove print job."

        Write-Host $_.Exception.Message
    }

    Pause-Console
}

# ============================================================
# SPOOLER
# ============================================================

function Get-SpoolerService {

    return Get-Service `
        -Name Spooler `
        -ErrorAction SilentlyContinue
}

function Show-SpoolerStatus {

    Write-Header -Title "PRINT SPOOLER STATUS"

    $service = Get-SpoolerService

    if ($null -eq $service) {

        Write-ErrorMessage `
            "Print Spooler service was not found."

        Pause-Console

        return
    }

    Write-KeyValue "Service Name" $service.Name
    Write-KeyValue "Display Name" $service.DisplayName
    Write-KeyValue "Status" $service.Status
    Write-KeyValue "Startup Type" $service.StartType

    Pause-Console
}

function Start-Spooler {

    try {

        Start-Service `
            -Name Spooler `
            -ErrorAction Stop

        Write-Success "Print Spooler started."
    }
    catch {

        Write-ErrorMessage `
            "Unable to start Print Spooler."

        Write-Host $_.Exception.Message
    }

    Pause-Console
}

function Stop-Spooler {

    try {

        Stop-Service `
            -Name Spooler `
            -Force `
            -ErrorAction Stop

        Write-Success "Print Spooler stopped."
    }
    catch {

        Write-ErrorMessage `
            "Unable to stop Print Spooler."

        Write-Host $_.Exception.Message
    }

    Pause-Console
}

function Restart-Spooler {

    try {

        Restart-Service `
            -Name Spooler `
            -Force `
            -ErrorAction Stop

        Write-Success "Print Spooler restarted."
    }
    catch {

        Write-ErrorMessage `
            "Unable to restart Print Spooler."

        Write-Host $_.Exception.Message
    }

    Pause-Console
}

function Clear-SpoolerFiles {

    Write-Header -Title "CLEAR SPOOLER FILES"

    Write-WarningMessage `
        "This operation stops the Print Spooler."

    Write-WarningMessage `
        "Pending spool files will be removed."

    $confirm =
        Read-TextInput "Type CLEAR to continue"

    # ESC = cancel
    if ($null -eq $confirm) {
        return
    }

    if ($confirm -ne "CLEAR") {

        Write-Info "Operation cancelled."

        Pause-Console

        return
    }

    try {

        Stop-Service `
            Spooler `
            -Force `
            -ErrorAction Stop

        $spoolPath =
            Join-Path `
                $env:SystemRoot `
                "System32\spool\PRINTERS"

        $files = Get-ChildItem `
            -Path $spoolPath `
            -Force `
            -ErrorAction SilentlyContinue

        foreach ($file in $files) {

            try {

                Remove-Item `
                    -Path $file.FullName `
                    -Force `
                    -Recurse `
                    -ErrorAction Stop
            }
            catch {
            }
        }

        Start-Service `
            Spooler `
            -ErrorAction Stop

        Write-Success `
            "Spooler files cleared and service restarted."
    }
    catch {

        Write-ErrorMessage "Spooler reset failed."

        Write-Host $_.Exception.Message

        try {
            Start-Service Spooler
        }
        catch {
        }
    }

    Pause-Console
}

# ============================================================
# DRIVER INFORMATION
# ============================================================

function Get-PrinterDriverObjects {

    try {

        return @(
            Get-PrinterDriver `
                -ErrorAction Stop
        )
    }
    catch {

        return @()
    }
}

function Show-PrinterDrivers {

    Write-Header -Title "INSTALLED PRINTER DRIVERS"

    $drivers = @(
        Get-PrinterDriverObjects
    )

    if ($drivers.Count -eq 0) {

        Write-WarningMessage `
            "No printer drivers could be retrieved."

        Pause-Console

        return
    }

    foreach ($driver in $drivers) {

        Write-Host (
            "Name        : " + $driver.Name
        )

        Write-Host (
            "Manufacturer: " + $driver.Manufacturer
        )

        Write-Host (
            "Version     : " + $driver.DriverVersion
        )

        Write-Host (
            "Environment : " + $driver.PrinterEnvironment
        )

        Write-Host (
            "Major       : " + $driver.MajorVersion
        )

        Write-Host (
            "Minor       : " + $driver.MinorVersion
        )

        Write-Host ""
    }

    Pause-Console
}

function Show-PrinterDriverForPrinter {

    $printer = Select-Printer

    if ($null -eq $printer) {
        return
    }

    Write-Header -Title "PRINTER DRIVER CHECK"

    Write-KeyValue "Printer" $printer.Name
    Write-KeyValue "Driver Name" $printer.DriverName

    $driver = $null

    try {

        $driver =
            Get-PrinterDriver `
                -Name $printer.DriverName `
                -ErrorAction Stop
    }
    catch {
    }

    if ($null -eq $driver) {

        Write-ErrorMessage `
            "Driver information could not be retrieved."

        Write-WarningMessage `
            "The driver may be unavailable, corrupt, or managed differently."

        Pause-Console

        return
    }

    Write-Section "Driver"

    Write-KeyValue "Name" $driver.Name
    Write-KeyValue "Manufacturer" $driver.Manufacturer
    Write-KeyValue "Version" $driver.DriverVersion
    Write-KeyValue "Environment" $driver.PrinterEnvironment
    Write-KeyValue "Major Version" $driver.MajorVersion
    Write-KeyValue "Minor Version" $driver.MinorVersion

    Write-Success "Driver lookup completed."

    Pause-Console
}

function Compare-PrinterDrivers {

    Write-Header -Title "DRIVER USAGE"

    $printers = @(Get-PrinterObjects)

    if ($printers.Count -eq 0) {

        Write-ErrorMessage "No printers found."

        Pause-Console

        return
    }

    $groups =
        $printers |
        Group-Object -Property DriverName

    foreach ($group in $groups) {

        Write-Host ""

        Write-Host (
            "Driver: " + $group.Name
        ) -ForegroundColor White

        foreach ($printer in $group.Group) {

            Write-Host (
                "  - " + $printer.Name
            )
        }
    }

    Pause-Console
}

# ============================================================
# PORT INFORMATION
# ============================================================

function Get-PrinterPortObjects {

    try {

        return @(
            Get-PrinterPort `
                -ErrorAction Stop
        )
    }
    catch {

        return @()
    }
}

function Show-PrinterPorts {

    Write-Header -Title "PRINTER PORTS"

    $ports = @(Get-PrinterPortObjects)

    if ($ports.Count -eq 0) {

        Write-WarningMessage `
            "No printer ports could be retrieved."

        Pause-Console

        return
    }

    foreach ($port in $ports) {

        Write-Host (
            "Name        : " + $port.Name
        )

        Write-Host (
            "Description : " + $port.Description
        )

        Write-Host (
            "Protocol    : " + $port.Protocol
        )

        Write-Host (
            "PrinterHost : " + $port.PrinterHostAddress
        )

        Write-Host (
            "PortNumber  : " + $port.PortNumber
        )

        Write-Host (
            "SNMP        : " + $port.SNMPEnabled
        )

        Write-Host ""
    }

    Pause-Console
}

function Show-PrinterPortForPrinter {

    $printer = Select-Printer

    if ($null -eq $printer) {
        return
    }

    Write-Header -Title "PRINTER PORT"

    Write-KeyValue "Printer" $printer.Name
    Write-KeyValue "Port" $printer.PortName

    $port = $null

    try {

        $port =
            Get-PrinterPort `
                -Name $printer.PortName `
                -ErrorAction Stop
    }
    catch {
    }

    if ($null -eq $port) {

        Write-WarningMessage `
            "Detailed port information unavailable."

        Pause-Console

        return
    }

    Write-Section "Configuration"

    Write-KeyValue "Name" $port.Name
    Write-KeyValue "Description" $port.Description
    Write-KeyValue "Protocol" $port.Protocol
    Write-KeyValue "Host Address" $port.PrinterHostAddress
    Write-KeyValue "Port Number" $port.PortNumber
    Write-KeyValue "SNMP Enabled" $port.SNMPEnabled

    Pause-Console
}

# ============================================================
# NETWORK INFORMATION
# ============================================================

function Show-NetworkConfiguration {

    Write-Header -Title "NETWORK CONFIGURATION"

    Write-Section "IPv4 Configuration"

    try {

        $configs =
            Get-NetIPConfiguration `
                -ErrorAction Stop |
            Where-Object {
                $_.IPv4Address -ne $null
            }

        foreach ($config in $configs) {

            Write-Host (
                "Interface : " +
                $config.InterfaceAlias
            )

            foreach ($address in $config.IPv4Address) {

                Write-Host (
                    "IPv4      : " +
                    $address.IPAddress
                )

                Write-Host (
                    "Prefix    : " +
                    $address.PrefixLength
                )
            }

            if ($config.IPv4DefaultGateway) {

                Write-Host (
                    "Gateway   : " +
                    $config.IPv4DefaultGateway.NextHop
                )
            }

            if ($config.DNSServer.ServerAddresses) {

                Write-Host (
                    "DNS       : " +
                    (
                        $config.DNSServer.ServerAddresses -join ", "
                    )
                )
            }

            Write-Host ""
        }
    }
    catch {

        ipconfig /all
    }

    Pause-Console
}

function Show-NetworkAdapters {

    Write-Header -Title "NETWORK ADAPTERS"

    try {

        $adapters =
            Get-NetAdapter `
                -ErrorAction Stop

        foreach ($adapter in $adapters) {

            Write-Host (
                "Name       : " + $adapter.Name
            )

            Write-Host (
                "Description: " +
                $adapter.InterfaceDescription
            )

            Write-Host (
                "Status     : " + $adapter.Status
            )

            Write-Host (
                "Link Speed : " + $adapter.LinkSpeed
            )

            Write-Host (
                "MAC        : " + $adapter.MacAddress
            )

            Write-Host ""
        }
    }
    catch {

        Get-WmiObject Win32_NetworkAdapter |
            Where-Object {
                $_.NetConnectionID
            } |
            ForEach-Object {

                Write-Host (
                    "Name   : " +
                    $_.NetConnectionID
                )

                Write-Host (
                    "Status : " +
                    $_.NetConnectionStatus
                )

                Write-Host (
                    "MAC    : " +
                    $_.MACAddress
                )

                Write-Host ""
            }
    }

    Pause-Console
}

# ============================================================
# PRINTER IP DISCOVERY
# ============================================================

function Get-PrinterIpAddress {
    param(
        [object]$Printer
    )

    if ($null -eq $Printer) {
        return $null
    }

    $portName = $Printer.PortName

    try {

        $port =
            Get-PrinterPort `
                -Name $portName `
                -ErrorAction Stop

        if ($port.PrinterHostAddress) {

            return $port.PrinterHostAddress
        }
    }
    catch {
    }

    if (
        $portName -match
        '^\d{1,3}(\.\d{1,3}){3}$'
    ) {

        return $portName
    }

    return $null
}

# ============================================================
# PING
# ============================================================

function Test-PrinterPing {

    $printer = Select-Printer

    if ($null -eq $printer) {
        return
    }

    $ip = Get-PrinterIpAddress -Printer $printer

    Write-Header -Title "PING PRINTER"

    Write-KeyValue "Printer" $printer.Name
    Write-KeyValue "Detected Address" $ip

    if ([string]::IsNullOrWhiteSpace($ip)) {

        $ip =
            Read-TextInput `
                "Enter printer hostname or IP"

        # ESC = back
        if ($null -eq $ip) {
            return
        }

        if ([string]::IsNullOrWhiteSpace($ip)) {

            Write-ErrorMessage `
                "No address entered."

            Pause-Console

            return
        }
    }

    Write-Host ""

    Write-Info `
        "Testing connectivity to $ip..."

    try {

        $result =
            Test-Connection `
                -ComputerName $ip `
                -Count 4 `
                -ErrorAction Stop

        $average =
            (
                $result |
                Measure-Object `
                    -Property ResponseTime `
                    -Average
            ).Average

        Write-Success `
            "Ping successful."

        Write-KeyValue `
            "Packets" `
            $result.Count

        Write-KeyValue `
            "Average Response" `
            "$([Math]::Round($average,2)) ms"
    }
    catch {

        Write-ErrorMessage "Ping failed."

        Write-Host $_.Exception.Message
    }

    Pause-Console
}

# ============================================================
# TCP PORT TEST
# ============================================================

function Test-TcpPort {

    $printer = Select-Printer

    if ($null -eq $printer) {
        return
    }

    $ip = Get-PrinterIpAddress -Printer $printer

    Write-Header -Title "TCP PORT TEST"

    if ([string]::IsNullOrWhiteSpace($ip)) {

        $ip =
            Read-TextInput `
                "Enter printer hostname or IP"

        # ESC = back
        if ($null -eq $ip) {
            return
        }

        if ([string]::IsNullOrWhiteSpace($ip)) {
            return
        }
    }

    $ports = @(
        [PSCustomObject]@{
            Label = "RAW Printing (9100)"
            Port  = 9100
        },
        [PSCustomObject]@{
            Label = "LPD / LPR (515)"
            Port  = 515
        },
        [PSCustomObject]@{
            Label = "IPP (631)"
            Port  = 631
        },
        [PSCustomObject]@{
            Label = "Custom Port"
            Port  = 0
        }
    )

    $choice =
        Show-TuiMenu `
            -Title "SELECT TCP PORT" `
            -Items $ports

    if ($null -eq $choice) {
        return
    }

    $port = $choice.Port

    if ($port -eq 0) {

        $inputPort =
            Read-TextInput `
                "Enter TCP port"

        # ESC = back
        if ($null -eq $inputPort) {
            return
        }

        if (
            -not [int]::TryParse(
                $inputPort,
                [ref]$port
            )
        ) {

            Write-ErrorMessage "Invalid port."

            Pause-Console

            return
        }
    }

    Write-Header -Title "TCP PORT TEST"

    Write-KeyValue "Host" $ip
    Write-KeyValue "Port" $port

    try {

        $tcp =
            New-Object System.Net.Sockets.TcpClient

        $async =
            $tcp.BeginConnect(
                $ip,
                $port,
                $null,
                $null
            )

        $success =
            $async.AsyncWaitHandle.WaitOne(3000)

        if (
            $success -and
            $tcp.Connected
        ) {

            $tcp.EndConnect($async)

            Write-Success `
                "TCP connection successful."
        }
        else {

            Write-ErrorMessage `
                "TCP connection failed or timed out."
        }

        $tcp.Close()
    }
    catch {

        Write-ErrorMessage `
            "TCP connection failed."

        Write-Host $_.Exception.Message
    }

    Pause-Console
}

# ============================================================
# DNS
# ============================================================

function Test-PrinterDns {

    $printer = Select-Printer

    if ($null -eq $printer) {
        return
    }

    $ip = Get-PrinterIpAddress -Printer $printer

    Write-Header -Title "DNS TEST"

    Write-KeyValue "Printer" $printer.Name
    Write-KeyValue "Address" $ip

    if ([string]::IsNullOrWhiteSpace($ip)) {

        $ip =
            Read-TextInput `
                "Enter hostname or IP"

        # ESC = back
        if ($null -eq $ip) {
            return
        }

        if ([string]::IsNullOrWhiteSpace($ip)) {
            return
        }
    }

    try {

        $dns =
            Resolve-DnsName `
                -Name $ip `
                -ErrorAction Stop

        Write-Success `
            "DNS resolution completed."

        foreach ($record in $dns) {

            Write-Host (
                "Name       : " +
                $record.Name
            )

            Write-Host (
                "Type       : " +
                $record.Type
            )

            if ($record.IPAddress) {

                Write-Host (
                    "IP Address : " +
                    $record.IPAddress
                )
            }

            Write-Host ""
        }
    }
    catch {

        Write-WarningMessage `
            "DNS lookup failed or the address is an IP address."
    }

    Pause-Console
}

# ============================================================
# ARP
# ============================================================

function Show-ArpTable {

    Write-Header -Title "ARP TABLE"

    try {

        $arp =
            Get-NetNeighbor `
                -ErrorAction Stop |
            Where-Object {
                $_.IPAddress
            }

        foreach ($entry in $arp) {

            Write-Host (
                "Interface : " +
                $entry.InterfaceAlias
            )

            Write-Host (
                "IP        : " +
                $entry.IPAddress
            )

            Write-Host (
                "MAC       : " +
                $entry.LinkLayerAddress
            )

            Write-Host (
                "State     : " +
                $entry.State
            )

            Write-Host ""
        }
    }
    catch {

        arp -a
    }

    Pause-Console
}

# ============================================================
# ROUTE TEST
# ============================================================

function Test-Route {

    $printer = Select-Printer

    if ($null -eq $printer) {
        return
    }

    $ip = Get-PrinterIpAddress -Printer $printer

    if ([string]::IsNullOrWhiteSpace($ip)) {

        $ip =
            Read-TextInput `
                "Enter printer hostname or IP"

        # ESC = back
        if ($null -eq $ip) {
            return
        }

        if ([string]::IsNullOrWhiteSpace($ip)) {
            return
        }
    }

    Write-Header -Title "NETWORK ROUTE"

    Write-Info `
        "Testing route to $ip..."

    Write-Host ""

    try {

        if (
            Get-Command `
                Test-NetConnection `
                -ErrorAction SilentlyContinue
        ) {

            Test-NetConnection `
                -ComputerName $ip `
                -InformationLevel Detailed
        }
        else {

            tracert $ip
        }
    }
    catch {

        Write-ErrorMessage `
            "Route test failed."
    }

    Pause-Console
}

# ============================================================
# PRINTER CONFIGURATION
# ============================================================

function Edit-PrinterComment {

    $printer = Select-Printer

    if ($null -eq $printer) {
        return
    }

    $comment =
        Read-TextInput `
            "Enter printer comment" `
            ([string]$printer.Comment)

    # ESC = back
    if ($null -eq $comment) {
        return
    }

    try {

        Set-Printer `
            -Name $printer.Name `
            -Comment $comment `
            -ErrorAction Stop

        Write-Success `
            "Printer comment updated."
    }
    catch {

        Write-ErrorMessage `
            "Unable to update printer comment."

        Write-Host $_.Exception.Message
    }

    Pause-Console
}

function Edit-PrinterLocation {

    $printer = Select-Printer

    if ($null -eq $printer) {
        return
    }

    $location =
        Read-TextInput `
            "Enter printer location" `
            ([string]$printer.Location)

    # ESC = back
    if ($null -eq $location) {
        return
    }

    try {

        Set-Printer `
            -Name $printer.Name `
            -Location $location `
            -ErrorAction Stop

        Write-Success `
            "Printer location updated."
    }
    catch {

        Write-ErrorMessage `
            "Unable to update printer location."

        Write-Host $_.Exception.Message
    }

    Pause-Console
}

function Rename-PrinterTui {

    $printer = Select-Printer

    if ($null -eq $printer) {
        return
    }

    $newName =
        Read-TextInput `
            "Enter new printer name"

    # ESC = back
    if ($null -eq $newName) {
        return
    }

    if ([string]::IsNullOrWhiteSpace($newName)) {
        return
    }

    try {

        Rename-Printer `
            -Name $printer.Name `
            -NewName $newName `
            -ErrorAction Stop

        Write-Success "Printer renamed."
    }
    catch {

        Write-ErrorMessage `
            "Unable to rename printer."

        Write-Host $_.Exception.Message
    }

    Pause-Console
}

function Remove-PrinterTui {

    $printer = Select-Printer

    if ($null -eq $printer) {
        return
    }

    Write-WarningMessage `
        "This will remove the printer from Windows."

    Write-Host $printer.Name

    $confirm =
        Read-TextInput `
            "Type REMOVE to continue"

    # ESC = back
    if ($null -eq $confirm) {
        return
    }

    if ($confirm -ne "REMOVE") {

        Write-Info "Operation cancelled."

        Pause-Console

        return
    }

    try {

        Remove-Printer `
            -Name $printer.Name `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Success "Printer removed."
    }
    catch {

        Write-ErrorMessage `
            "Unable to remove printer."

        Write-Host $_.Exception.Message
    }

    Pause-Console
}

# ============================================================
# PRINTER ENABLE / DISABLE
# ============================================================

function Set-PrinterEnabled {

    $printer = Select-Printer

    if ($null -eq $printer) {
        return
    }

    $items = @(
        [PSCustomObject]@{
            Label = "Enable Printer"
            Action = "Enable"
        },
        [PSCustomObject]@{
            Label = "Disable Printer"
            Action = "Disable"
        }
    )

    $choice =
        Show-TuiMenu `
            -Title "PRINTER ENABLE / DISABLE" `
            -Items $items

    if ($null -eq $choice) {
        return
    }

    try {

        if ($choice.Action -eq "Enable") {

            Enable-Printer `
                -Name $printer.Name `
                -ErrorAction Stop

            Write-Success "Printer enabled."
        }
        else {

            Disable-Printer `
                -Name $printer.Name `
                -ErrorAction Stop

            Write-Success "Printer disabled."
        }
    }
    catch {

        Write-ErrorMessage `
            "Operation failed."

        Write-Host $_.Exception.Message
    }

    Pause-Console
}

# ============================================================
# PRINTER SHARING
# ============================================================

function Set-PrinterSharing {

    $printer = Select-Printer

    if ($null -eq $printer) {
        return
    }

    $items = @(
        [PSCustomObject]@{
            Label = "Enable Sharing"
            Action = "Enable"
        },
        [PSCustomObject]@{
            Label = "Disable Sharing"
            Action = "Disable"
        }
    )

    $choice =
        Show-TuiMenu `
            -Title "PRINTER SHARING" `
            -Items $items

    if ($null -eq $choice) {
        return
    }

    try {

        if ($choice.Action -eq "Enable") {

            $shareName =
                Read-TextInput `
                    "Enter share name" `
                    ([string]$printer.ShareName)

            # ESC = back
            if ($null -eq $shareName) {
                return
            }

            Set-Printer `
                -Name $printer.Name `
                -Shared:$true `
                -ShareName $shareName `
                -ErrorAction Stop

            Write-Success `
                "Printer sharing enabled."
        }
        else {

            Set-Printer `
                -Name $printer.Name `
                -Shared:$false `
                -ErrorAction Stop

            Write-Success `
                "Printer sharing disabled."
        }
    }
    catch {

        Write-ErrorMessage `
            "Unable to modify printer sharing."

        Write-Host $_.Exception.Message
    }

    Pause-Console
}

# ============================================================
# WINDOWS TOOLS
# ============================================================

function Start-WindowsTool {
    param(
        [string]$FilePath,
        [string]$Arguments = ""
    )

    try {

        Start-Process `
            -FilePath $FilePath `
            -ArgumentList $Arguments `
            -ErrorAction Stop
    }
    catch {

        Write-ErrorMessage `
            "Unable to start tool: $FilePath"

        Write-Host $_.Exception.Message

        Pause-Console
    }
}

function Open-PrinterSettings {

    Start-WindowsTool `
        -FilePath "ms-settings:" `
        -Arguments "printers"
}

function Open-DevicesAndPrinters {

    Start-WindowsTool `
        -FilePath "control.exe" `
        -Arguments "printers"
}

function Open-PrintManagement {

    Start-WindowsTool `
        -FilePath "printmanagement.msc"
}

function Open-Services {

    Start-WindowsTool `
        -FilePath "services.msc"
}

function Open-DeviceManager {

    Start-WindowsTool `
        -FilePath "devmgmt.msc"
}

function Open-EventViewer {

    Start-WindowsTool `
        -FilePath "eventvwr.msc"
}

function Open-NetworkConnections {

    Start-WindowsTool `
        -FilePath "ncpa.cpl"
}

# ============================================================
# DIAGNOSTIC WIZARD
# ============================================================

function Invoke-PrinterDiagnostic {

    $printer = Select-Printer

    if ($null -eq $printer) {
        return
    }

    Write-Header -Title "PRINTER DIAGNOSTIC WIZARD"

    Write-Host `
        "Running diagnostics for:" `
        -ForegroundColor White

    Write-Host `
        $printer.Name `
        -ForegroundColor Cyan

    Write-Host ""

    $results =
        New-Object System.Collections.ArrayList

    # --------------------------------------------------------
    # Printer
    # --------------------------------------------------------

    [void]$results.Add(
        [PSCustomObject]@{
            Test   = "Printer Object"
            Status = "PASS"
            Detail = "Printer exists in Windows."
        }
    )

    # --------------------------------------------------------
    # Spooler
    # --------------------------------------------------------

    $spooler = Get-SpoolerService

    if (
        $spooler -and
        $spooler.Status -eq "Running"
    ) {

        [void]$results.Add(
            [PSCustomObject]@{
                Test   = "Print Spooler"
                Status = "PASS"
                Detail = "Spooler service is running."
            }
        )
    }
    else {

        [void]$results.Add(
            [PSCustomObject]@{
                Test   = "Print Spooler"
                Status = "FAIL"
                Detail = "Spooler service is not running."
            }
        )
    }

    # --------------------------------------------------------
    # Driver
    # --------------------------------------------------------

    $driverFound = $false

    try {

        $driver =
            Get-PrinterDriver `
                -Name $printer.DriverName `
                -ErrorAction Stop

        if ($driver) {
            $driverFound = $true
        }
    }
    catch {
    }

    if ($driverFound) {

        [void]$results.Add(
            [PSCustomObject]@{
                Test   = "Printer Driver"
                Status = "PASS"
                Detail = $printer.DriverName
            }
        )
    }
    else {

        [void]$results.Add(
            [PSCustomObject]@{
                Test   = "Printer Driver"
                Status = "FAIL"
                Detail = "Driver information unavailable."
            }
        )
    }

    # --------------------------------------------------------
    # Port
    # --------------------------------------------------------

    $portFound = $false

    try {

        $port =
            Get-PrinterPort `
                -Name $printer.PortName `
                -ErrorAction Stop

        if ($port) {
            $portFound = $true
        }
    }
    catch {
    }

    if ($portFound) {

        [void]$results.Add(
            [PSCustomObject]@{
                Test   = "Printer Port"
                Status = "PASS"
                Detail = $printer.PortName
            }
        )
    }
    else {

        [void]$results.Add(
            [PSCustomObject]@{
                Test   = "Printer Port"
                Status = "WARN"
                Detail = "Port details unavailable."
            }
        )
    }

    # --------------------------------------------------------
    # Queue
    # --------------------------------------------------------

    $jobs = @(
        Get-PrinterJobs `
            -PrinterName $printer.Name
    )

    if ($jobs.Count -eq 0) {

        [void]$results.Add(
            [PSCustomObject]@{
                Test   = "Print Queue"
                Status = "PASS"
                Detail = "No stuck jobs detected."
            }
        )
    }
    else {

        [void]$results.Add(
            [PSCustomObject]@{
                Test   = "Print Queue"
                Status = "WARN"
                Detail = "$($jobs.Count) job(s) currently queued."
            }
        )
    }

    # --------------------------------------------------------
    # IP
    # --------------------------------------------------------

    $ip =
        Get-PrinterIpAddress `
            -Printer $printer

    if ($ip) {

        [void]$results.Add(
            [PSCustomObject]@{
                Test   = "Printer IP"
                Status = "PASS"
                Detail = $ip
            }
        )

        # ----------------------------------------------------
        # Ping
        # ----------------------------------------------------

        try {

            $ping =
                Test-Connection `
                    -ComputerName $ip `
                    -Count 2 `
                    -ErrorAction Stop

            if ($ping) {

                [void]$results.Add(
                    [PSCustomObject]@{
                        Test   = "Ping"
                        Status = "PASS"
                        Detail = "Printer responded to ICMP."
                    }
                )
            }
        }
        catch {

            [void]$results.Add(
                [PSCustomObject]@{
                    Test   = "Ping"
                    Status = "FAIL"
                    Detail = "Printer did not respond to ICMP."
                }
            )
        }

        # ----------------------------------------------------
        # TCP 9100
        # ----------------------------------------------------

        try {

            $tcp =
                New-Object System.Net.Sockets.TcpClient

            $async =
                $tcp.BeginConnect(
                    $ip,
                    9100,
                    $null,
                    $null
                )

            $connected =
                $async.AsyncWaitHandle.WaitOne(2500)

            if (
                $connected -and
                $tcp.Connected
            ) {

                [void]$results.Add(
                    [PSCustomObject]@{
                        Test   = "TCP 9100"
                        Status = "PASS"
                        Detail = "RAW printing port is reachable."
                    }
                )
            }
            else {

                [void]$results.Add(
                    [PSCustomObject]@{
                        Test   = "TCP 9100"
                        Status = "WARN"
                        Detail = "Port 9100 is not reachable."
                    }
                )
            }

            $tcp.Close()
        }
        catch {

            [void]$results.Add(
                [PSCustomObject]@{
                    Test   = "TCP 9100"
                    Status = "WARN"
                    Detail = "Unable to test port."
                }
            )
        }
    }
    else {

        [void]$results.Add(
            [PSCustomObject]@{
                Test   = "Printer IP"
                Status = "WARN"
                Detail = "Could not determine printer IP."
            }
        )
    }

    # --------------------------------------------------------
    # Display
    # --------------------------------------------------------

    Write-Header -Title "DIAGNOSTIC RESULTS"

    foreach ($result in $results) {

        $status = $result.Status

        switch ($status) {

            "PASS" {
                $color =
                    $Script:Colors.SuccessForeground
            }

            "WARN" {
                $color =
                    $Script:Colors.WarningForeground
            }

            "FAIL" {
                $color =
                    $Script:Colors.ErrorForeground
            }

            default {
                $color =
                    $Script:Colors.NormalForeground
            }
        }

        Write-Host (
            "[{0}] " -f $status
        ) `
            -ForegroundColor $color `
            -NoNewline

        Write-Host (
            $result.Test.PadRight(22)
        ) -NoNewline

        Write-Host $result.Detail
    }

    $Script:App.LastResult = $results

    Write-Host ""

    $failures = @(
        $results |
        Where-Object Status -eq "FAIL"
    )

    $warnings = @(
        $results |
        Where-Object Status -eq "WARN"
    )

    if ($failures.Count -gt 0) {

        Write-ErrorMessage `
            "$($failures.Count) diagnostic failure(s) detected."
    }
    elseif ($warnings.Count -gt 0) {

        Write-WarningMessage `
            "$($warnings.Count) warning(s) detected."
    }
    else {

        Write-Success `
            "All diagnostic checks passed."
    }

    Pause-Console
}

# ============================================================
# REPORT GENERATION
# ============================================================

function Export-PrinterDiagnosticReport {

    $printer = Select-Printer

    if ($null -eq $printer) {
        return
    }

    Write-Header -Title "EXPORT DIAGNOSTIC REPORT"

    if (-not (Test-Path $Script:App.ReportDirectory)) {

        try {

            New-Item `
                -Path $Script:App.ReportDirectory `
                -ItemType Directory `
                -Force `
                -ErrorAction Stop |
                Out-Null
        }
        catch {

            Write-ErrorMessage `
                "Unable to create report directory."

            Pause-Console

            return
        }
    }

    $timestamp =
        Get-Date -Format "yyyyMMdd_HHmmss"

    $safeName =
        $printer.Name -replace `
            '[\\/:*?"<>|]', '_'

    $file =
        Join-Path `
            $Script:App.ReportDirectory `
            "${safeName}_${timestamp}.txt"

    try {

        $lines =
            New-Object System.Collections.ArrayList

        [void]$lines.Add(
            "============================================================"
        )

        [void]$lines.Add(
            "PRINTER TROUBLESHOOTING REPORT"
        )

        [void]$lines.Add(
            "============================================================"
        )

        [void]$lines.Add(
            "Generated: $(Get-Date)"
        )

        [void]$lines.Add(
            "Computer : $env:COMPUTERNAME"
        )

        [void]$lines.Add(
            "User     : $env:USERNAME"
        )

        [void]$lines.Add("")

        [void]$lines.Add(
            "PRINTER INFORMATION"
        )

        [void]$lines.Add(
            "-------------------"
        )

        [void]$lines.Add(
            "Name       : $($printer.Name)"
        )

        [void]$lines.Add(
            "Driver     : $($printer.DriverName)"
        )

        [void]$lines.Add(
            "Port       : $($printer.PortName)"
        )

        [void]$lines.Add(
            "Shared     : $($printer.Shared)"
        )

        [void]$lines.Add(
            "Published  : $($printer.Published)"
        )

        [void]$lines.Add(
            "Default    : $($printer.Default)"
        )

        [void]$lines.Add(
            "Location   : $($printer.Location)"
        )

        [void]$lines.Add(
            "Comment    : $($printer.Comment)"
        )

        [void]$lines.Add("")

        $ip =
            Get-PrinterIpAddress `
                -Printer $printer

        [void]$lines.Add(
            "NETWORK"
        )

        [void]$lines.Add(
            "-------"
        )

        [void]$lines.Add(
            "Printer IP : $ip"
        )

        if ($ip) {

            try {

                $ping =
                    Test-Connection `
                        -ComputerName $ip `
                        -Count 2 `
                        -ErrorAction Stop

                [void]$lines.Add(
                    "Ping       : PASS"
                )
            }
            catch {

                [void]$lines.Add(
                    "Ping       : FAIL"
                )
            }
        }

        [void]$lines.Add("")

        [void]$lines.Add(
            "SPOOLER"
        )

        [void]$lines.Add(
            "-------"
        )

        $spooler =
            Get-SpoolerService

        if ($spooler) {

            [void]$lines.Add(
                "Status     : $($spooler.Status)"
            )

            [void]$lines.Add(
                "Startup    : $($spooler.StartType)"
            )
        }

        [void]$lines.Add("")

        [void]$lines.Add(
            "PRINT QUEUE"
        )

        [void]$lines.Add(
            "-----------"
        )

        $jobs = @(
            Get-PrinterJobs `
                -PrinterName $printer.Name
        )

        if ($jobs.Count -eq 0) {

            [void]$lines.Add(
                "No print jobs."
            )
        }
        else {

            foreach ($job in $jobs) {

                [void]$lines.Add(
                    "ID=$($job.Id) " +
                    "Document=$($job.DocumentName) " +
                    "User=$($job.UserName) " +
                    "Status=$($job.JobStatus)"
                )
            }
        }

        [void]$lines.Add("")

        [void]$lines.Add(
            "DRIVER"
        )

        [void]$lines.Add(
            "------"
        )

        try {

            $driver =
                Get-PrinterDriver `
                    -Name $printer.DriverName `
                    -ErrorAction Stop

            [void]$lines.Add(
                "Name         : $($driver.Name)"
            )

            [void]$lines.Add(
                "Manufacturer : $($driver.Manufacturer)"
            )

            [void]$lines.Add(
                "Version      : $($driver.DriverVersion)"
            )

            [void]$lines.Add(
                "Environment  : $($driver.PrinterEnvironment)"
            )
        }
        catch {

            [void]$lines.Add(
                "Driver details unavailable."
            )
        }

        [void]$lines.Add("")

        [void]$lines.Add(
            "NETWORK CONFIGURATION"
        )

        [void]$lines.Add(
            "---------------------"
        )

        try {

            $configs =
                Get-NetIPConfiguration `
                    -ErrorAction Stop

            foreach ($config in $configs) {

                if ($config.IPv4Address) {

                    [void]$lines.Add(
                        "Interface: $($config.InterfaceAlias)"
                    )

                    foreach (
                        $address in
                        $config.IPv4Address
                    ) {

                        [void]$lines.Add(
                            "IPv4: " +
                            "$($address.IPAddress)/" +
                            "$($address.PrefixLength)"
                        )
                    }

                    if ($config.IPv4DefaultGateway) {

                        [void]$lines.Add(
                            "Gateway: " +
                            "$($config.IPv4DefaultGateway.NextHop)"
                        )
                    }

                    if (
                        $config.DNSServer.ServerAddresses
                    ) {

                        [void]$lines.Add(
                            "DNS: " +
                            (
                                $config.DNSServer.ServerAddresses `
                                    -join ", "
                            )
                        )
                    }
                }
            }
        }
        catch {

            [void]$lines.Add(
                "Network configuration unavailable."
            )
        }

        [void]$lines.Add("")

        [void]$lines.Add(
            "============================================================"
        )

        [void]$lines.Add(
            "END OF REPORT"
        )

        [void]$lines.Add(
            "============================================================"
        )

        $lines |
            Out-File `
                -FilePath $file `
                -Encoding UTF8 `
                -Force

        Write-Success `
            "Report exported."

        Write-Host ""

        Write-Host `
            $file `
            -ForegroundColor Cyan
    }
    catch {

        Write-ErrorMessage `
            "Unable to create diagnostic report."

        Write-Host $_.Exception.Message
    }

    Pause-Console
}

# ============================================================
# SYSTEM INFORMATION
# ============================================================

function Show-SystemInformation {

    Write-Header -Title "SYSTEM INFORMATION"

    $os =
        Get-CimInstance `
            Win32_OperatingSystem

    Write-KeyValue `
        "Computer Name" `
        $env:COMPUTERNAME

    Write-KeyValue `
        "User" `
        $env:USERNAME

    Write-KeyValue `
        "PowerShell" `
        $PSVersionTable.PSVersion

    Write-KeyValue `
        "OS" `
        $os.Caption

    Write-KeyValue `
        "OS Version" `
        $os.Version

    $spooler =
        Get-SpoolerService

    if ($spooler) {

        Write-KeyValue `
            "Spooler Status" `
            $spooler.Status

        Write-KeyValue `
            "Spooler Start" `
            $spooler.StartType
    }

    $printers =
        @(Get-PrinterObjects)

    Write-KeyValue `
        "Installed Printers" `
        $printers.Count

    Pause-Console
}

# ============================================================
# PRINTER MANAGEMENT MENU
# ============================================================

function Printer-ManagementMenu {

    while ($true) {

        $items = @(
            [PSCustomObject]@{
                Label = "Printer Status"
                Action = {
                    Show-PrinterStatus
                }
            },

            [PSCustomObject]@{
                Label = "Select / Change Current Printer"
                Action = {
                    Select-Printer | Out-Null
                }
            },

            [PSCustomObject]@{
                Label = "Set Default Printer"
                Action = {
                    Set-PrinterDefault
                }
            },

            [PSCustomObject]@{
                Label = "Enable / Disable Printer"
                Action = {
                    Set-PrinterEnabled
                }
            },

            [PSCustomObject]@{
                Label = "Rename Printer"
                Action = {
                    Rename-PrinterTui
                }
            },

            [PSCustomObject]@{
                Label = "Edit Printer Location"
                Action = {
                    Edit-PrinterLocation
                }
            },

            [PSCustomObject]@{
                Label = "Edit Printer Comment"
                Action = {
                    Edit-PrinterComment
                }
            },

            [PSCustomObject]@{
                Label = "Printer Sharing"
                Action = {
                    Set-PrinterSharing
                }
            },

            [PSCustomObject]@{
                Label = "Remove Printer"
                Action = {
                    Remove-PrinterTui
                }
            }
        )

        $choice =
            Show-ActionMenu `
                -Title "PRINTER MANAGEMENT" `
                -Items $items

        if ($null -eq $choice) {
            return
        }

        & $choice.Action
    }
}

# ============================================================
# QUEUE MANAGEMENT MENU
# ============================================================

function Queue-ManagementMenu {

    while ($true) {

        $items = @(
            [PSCustomObject]@{
                Label = "View Print Queue"
                Action = {
                    Show-PrinterQueue
                }
            },

            [PSCustomObject]@{
                Label = "Remove Selected Print Job"
                Action = {
                    Remove-SelectedPrinterJob
                }
            },

            [PSCustomObject]@{
                Label = "Clear All Print Jobs"
                Action = {
                    Remove-AllPrinterJobs
                }
            }
        )

        $choice =
            Show-ActionMenu `
                -Title "PRINT QUEUE MANAGEMENT" `
                -Items $items

        if ($null -eq $choice) {
            return
        }

        & $choice.Action
    }
}

# ============================================================
# SPOOLER MENU
# ============================================================

function Spooler-Menu {

    while ($true) {

        $items = @(
            [PSCustomObject]@{
                Label = "Spooler Status"
                Action = {
                    Show-SpoolerStatus
                }
            },

            [PSCustomObject]@{
                Label = "Start Spooler"
                Action = {
                    Start-Spooler
                }
            },

            [PSCustomObject]@{
                Label = "Stop Spooler"
                Action = {
                    Stop-Spooler
                }
            },

            [PSCustomObject]@{
                Label = "Restart Spooler"
                Action = {
                    Restart-Spooler
                }
            },

            [PSCustomObject]@{
                Label = "Clear Spooler Files"
                Action = {
                    Clear-SpoolerFiles
                }
            }
        )

        $choice =
            Show-ActionMenu `
                -Title "PRINT SPOOLER" `
                -Items $items

        if ($null -eq $choice) {
            return
        }

        & $choice.Action
    }
}

# ============================================================
# DRIVER MENU
# ============================================================

function Driver-Menu {

    while ($true) {

        $items = @(
            [PSCustomObject]@{
                Label = "List Installed Printer Drivers"
                Action = {
                    Show-PrinterDrivers
                }
            },

            [PSCustomObject]@{
                Label = "Check Driver Used by Printer"
                Action = {
                    Show-PrinterDriverForPrinter
                }
            },

            [PSCustomObject]@{
                Label = "Show Driver Usage Across Printers"
                Action = {
                    Compare-PrinterDrivers
                }
            }
        )

        $choice =
            Show-ActionMenu `
                -Title "DRIVER DIAGNOSTICS" `
                -Items $items

        if ($null -eq $choice) {
            return
        }

        & $choice.Action
    }
}

# ============================================================
# PORT MENU
# ============================================================

function Port-Menu {

    while ($true) {

        $items = @(
            [PSCustomObject]@{
                Label = "List Printer Ports"
                Action = {
                    Show-PrinterPorts
                }
            },

            [PSCustomObject]@{
                Label = "Show Port Used by Printer"
                Action = {
                    Show-PrinterPortForPrinter
                }
            }
        )

        $choice =
            Show-ActionMenu `
                -Title "PRINTER PORTS" `
                -Items $items

        if ($null -eq $choice) {
            return
        }

        & $choice.Action
    }
}

# ============================================================
# NETWORK MENU
# ============================================================

function Network-Menu {

    while ($true) {

        $items = @(
            [PSCustomObject]@{
                Label = "Ping Printer"
                Action = {
                    Test-PrinterPing
                }
            },

            [PSCustomObject]@{
                Label = "TCP Port Test"
                Action = {
                    Test-TcpPort
                }
            },

            [PSCustomObject]@{
                Label = "DNS Test"
                Action = {
                    Test-PrinterDns
                }
            },

            [PSCustomObject]@{
                Label = "Network Route / Test-NetConnection"
                Action = {
                    Test-Route
                }
            },

            [PSCustomObject]@{
                Label = "ARP Table"
                Action = {
                    Show-ArpTable
                }
            },

            [PSCustomObject]@{
                Label = "Network Configuration"
                Action = {
                    Show-NetworkConfiguration
                }
            },

            [PSCustomObject]@{
                Label = "Network Adapters"
                Action = {
                    Show-NetworkAdapters
                }
            }
        )

        $choice =
            Show-ActionMenu `
                -Title "NETWORK CONNECTIVITY" `
                -Items $items

        if ($null -eq $choice) {
            return
        }

        & $choice.Action
    }
}

# ============================================================
# WINDOWS TOOLS MENU
# ============================================================

function Windows-ToolsMenu {

    while ($true) {

        $items = @(
            [PSCustomObject]@{
                Label = "Windows Printer Settings"
                Action = {
                    Open-PrinterSettings
                }
            },

            [PSCustomObject]@{
                Label = "Devices and Printers"
                Action = {
                    Open-DevicesAndPrinters
                }
            },

            [PSCustomObject]@{
                Label = "Print Management"
                Action = {
                    Open-PrintManagement
                }
            },

            [PSCustomObject]@{
                Label = "Services"
                Action = {
                    Open-Services
                }
            },

            [PSCustomObject]@{
                Label = "Device Manager"
                Action = {
                    Open-DeviceManager
                }
            },

            [PSCustomObject]@{
                Label = "Event Viewer"
                Action = {
                    Open-EventViewer
                }
            },

            [PSCustomObject]@{
                Label = "Network Connections"
                Action = {
                    Open-NetworkConnections
                }
            }
        )

        $choice =
            Show-ActionMenu `
                -Title "WINDOWS TOOLS" `
                -Items $items

        if ($null -eq $choice) {
            return
        }

        & $choice.Action
    }
}

# ============================================================
# REPORT MENU
# ============================================================

function Reports-Menu {

    while ($true) {

        $items = @(
            [PSCustomObject]@{
                Label = "Export Printer Diagnostic Report"
                Action = {
                    Export-PrinterDiagnosticReport
                }
            },

            [PSCustomObject]@{
                Label = "Show Report Directory"
                Action = {

                    Write-Header `
                        -Title "REPORT DIRECTORY"

                    Write-Host `
                        $Script:App.ReportDirectory `
                        -ForegroundColor Cyan

                    Pause-Console
                }
            },

            [PSCustomObject]@{
                Label = "Open Report Directory"
                Action = {

                    try {

                        if (
                            -not (
                                Test-Path `
                                    $Script:App.ReportDirectory
                            )
                        ) {

                            New-Item `
                                -Path $Script:App.ReportDirectory `
                                -ItemType Directory `
                                -Force |
                                Out-Null
                        }

                        Start-Process `
                            explorer.exe `
                            $Script:App.ReportDirectory
                    }
                    catch {

                        Write-ErrorMessage `
                            "Unable to open directory."

                        Pause-Console
                    }
                }
            }
        )

        $choice =
            Show-ActionMenu `
                -Title "REPORTS" `
                -Items $items

        if ($null -eq $choice) {
            return
        }

        & $choice.Action
    }
}

# ============================================================
# MAIN MENU
# ============================================================

function Start-PrinterTui {

    [Console]::CursorVisible = $false

    while ($Script:App.Running) {

        $printerText =
            "No printer selected"

        if ($Script:App.CurrentPrinter) {

            $printerText =
                $Script:App.CurrentPrinter.Name
        }

        $items = @(
            [PSCustomObject]@{
                Label = "Printer Management"
                Action = {
                    Printer-ManagementMenu
                }
            },

            [PSCustomObject]@{
                Label = "Print Queue Management"
                Action = {
                    Queue-ManagementMenu
                }
            },

            [PSCustomObject]@{
                Label = "Print Spooler"
                Action = {
                    Spooler-Menu
                }
            },

            [PSCustomObject]@{
                Label = "Driver Diagnostics"
                Action = {
                    Driver-Menu
                }
            },

            [PSCustomObject]@{
                Label = "Printer Ports"
                Action = {
                    Port-Menu
                }
            },

            [PSCustomObject]@{
                Label = "Network Connectivity"
                Action = {
                    Network-Menu
                }
            },

            [PSCustomObject]@{
                Label = "PRINTER TROUBLESHOOTING WIZARD"
                Action = {
                    Invoke-PrinterDiagnostic
                }
            },

            [PSCustomObject]@{
                Label = "Windows Tools"
                Action = {
                    Windows-ToolsMenu
                }
            },

            [PSCustomObject]@{
                Label = "Diagnostic Reports"
                Action = {
                    Reports-Menu
                }
            },

            [PSCustomObject]@{
                Label = "System Information"
                Action = {
                    Show-SystemInformation
                }
            }
        )

        $footer =
            "`n[UP/DOWN] Navigate   [ENTER] Select   [ESC] Exit    " +
            "Current Printer: $printerText"

        $choice =
            Show-TuiMenu `
                -Title "MAIN MENU" `
                -Items $items `
                -Footer $footer

        if ($null -eq $choice) {

            $Script:App.Running = $false

            break
        }

        & $choice.Action

        if ($Script:App.CurrentPrinter) {

            try {

                $Script:App.CurrentPrinter =
                    Get-PrinterObject `
                        -Name $Script:App.CurrentPrinter.Name
            }
            catch {
            }
        }
    }

    [Console]::CursorVisible = $true

    Set-NormalColor

    Clear-Console

    Write-Host ""

    Write-Host `
        "Printer Troubleshooting Console closed." `
        -ForegroundColor Gray

    Write-Host ""
}

# ============================================================
# ERROR HANDLING / STARTUP
# ============================================================

try {

    Start-PrinterTui
}
catch {

    [Console]::CursorVisible = $true

    Set-NormalColor

    Clear-Console

    Write-Host ""

    Write-Host `
        "FATAL ERROR" `
        -ForegroundColor Red

    Write-Host `
        "-----------" `
        -ForegroundColor DarkGray

    Write-Host `
        $_.Exception.Message `
        -ForegroundColor Red

    Write-Host ""

    Write-Host `
        "Press any key to exit..." `
        -ForegroundColor Gray

    [Console]::ReadKey($true) | Out-Null
}
finally {

    [Console]::CursorVisible = $true

    Set-NormalColor
}