param(
    [Parameter(Mandatory=$true)]
    [string]$inputPath,
    
    [Parameter(Mandatory=$true)]
    [string]$outputPath,
    
    [Parameter(Mandatory=$true)]
    [string]$movePath,

    [Parameter(Mandatory=$false)]
    [switch]$WhatIf = $false,

    [Parameter(Mandatory=$false)]
    [switch]$DetailedLog = $false,

    [Parameter(Mandatory=$false)]
    [switch]$CopyOnly = $false
)

# Create move directory if it doesn't exist (needed for log file)
if (-not (Test-Path $movePath)) {
    New-Item -ItemType Directory -Path $movePath -Force | Out-Null
}

# Start Logging - Now using movePath instead of PSScriptRoot
$logDate = Get-Date -Format "yyyyMMdd_HHmmss"
$logFileName = "FileComparisonLog_$logDate.log"
$logFile = Join-Path $movePath $logFileName

# Create Log File
Start-Transcript -Path $logFile

function Write-LogMessage {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

# Initial checks and setup
Write-LogMessage "Script started by user: $env:USERNAME" "Cyan"
Write-LogMessage "Input Path: $inputPath"
Write-LogMessage "Output Path: $outputPath"
Write-LogMessage "Move Path: $movePath"
Write-LogMessage "WhatIf Mode: $WhatIf"
Write-LogMessage "Copy Only Mode: $CopyOnly"

# Validate paths
$pathChecks = @(
    @{Path = $inputPath; Name = "Input"},
    @{Path = $outputPath; Name = "Output"}
)

foreach ($check in $pathChecks) {
    if (-not (Test-Path $check.Path)) {
        Write-LogMessage "$($check.Name) path does not exist: $($check.Path)" "Red"
        Stop-Transcript
        exit 1
    }
}

if (-not (Test-Path $movePath)) {
    Write-LogMessage "Creating move directory: $movePath" "Yellow"
    if (-not $WhatIf) {
        New-Item -ItemType Directory -Path $movePath -Force
    }
}

# Get all TIF files recursively
$tifFiles = Get-ChildItem -Path $inputPath -Filter "*.tif" -File -Recurse
if ($tifFiles.Count -eq 0) {
    Write-LogMessage "No TIF files found in input path!" "Red"
    Stop-Transcript
    exit 1
}

# Group TIF files by their parent directory
$tifFolders = $tifFiles | Group-Object DirectoryName

Write-LogMessage "Found $($tifFiles.Count) TIF files in $($tifFolders.Count) folders" "Green"

# Get all PDF files in output path
$outputPdfs = Get-ChildItem -Path $outputPath -Filter "*.pdf" -File -Recurse
Write-LogMessage "Found $($outputPdfs.Count) PDF files in output directory" "Green"

if ($DetailedLog) {
    Write-LogMessage "`nPDF files found:" "Cyan"
    $outputPdfs | ForEach-Object {
        Write-LogMessage "  - $($_.FullName)" "Gray"
    }
}

$processedFolders = @{}
$statistics = @{
    TotalFolders = $tifFolders.Count
    MovedFolders = 0
    MatchedFolders = 0
    ErrorFolders = 0
    ProcessedFiles = 0
}

foreach ($folderGroup in $tifFolders) {
    $folderPath = $folderGroup.Name
    $folder = Get-Item $folderPath
    $folderName = $folder.Name
    
    if ($processedFolders.ContainsKey($folderPath)) {
        Write-LogMessage "Skipping already processed folder: $folderPath" "Gray"
        continue
    }
    
    Write-LogMessage "`nProcessing folder: $folderPath" "Cyan"
    Write-LogMessage "  - Contains $($folderGroup.Count) TIF files"
    
    # Check for matching PDF at multiple levels
    $matchFound = $false
    $matchingPdfPath = $null
    
    # Check exact folder name
    $matchingPdf = $outputPdfs | Where-Object { $_.BaseName -eq $folderName }
    if ($matchingPdf) {
        $matchFound = $true
        $matchingPdfPath = $matchingPdf.FullName
        Write-LogMessage "  - Found matching PDF: $($matchingPdf.Name)" "Green"
    }
    
    # Check parent folder
    if (-not $matchFound -and $folder.Parent) {
        $parentName = $folder.Parent.Name
        $matchingParentPdf = $outputPdfs | Where-Object { $_.BaseName -eq $parentName }
        if ($matchingParentPdf) {
            $matchFound = $true
            $matchingPdfPath = $matchingParentPdf.FullName
            Write-LogMessage "  - Found matching PDF in parent: $($matchingParentPdf.Name)" "Green"
        }
    }
    
    if (-not $matchFound) {
        Write-LogMessage "  - NO MATCHING PDF found for: $folderName" "Yellow"
        
        $relativePath = $folderPath.Substring($inputPath.Length)
        $targetPath = Join-Path $movePath $relativePath
        
        try {
            if ($WhatIf) {
                $operation = if ($CopyOnly) { "copy" } else { "move" }
                Write-LogMessage "  [WhatIf] Would $operation folder to: $targetPath" "Cyan"
            } else {
                # Create target directory
                New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
                
                # Move or copy all files
                foreach ($file in (Get-ChildItem -Path $folderPath -File)) {
                    $operation = if ($CopyOnly) { "Copying" } else { "Moving" }
                    Write-LogMessage "  - $operation file: $($file.Name)" "Gray"
                    
                    if ($CopyOnly) {
                        Copy-Item -Path $file.FullName -Destination $targetPath -Force
                    } else {
                        Move-Item -Path $file.FullName -Destination $targetPath -Force
                    }
                    $statistics.ProcessedFiles++
                }
                
                # Cleanup empty source folder only if we're moving files
                if (-not $CopyOnly -and -not (Get-ChildItem -Path $folderPath)) {
                    Remove-Item -Path $folderPath -Force
                }
                
                $statistics.MovedFolders++
            }
        }
        catch {
            Write-LogMessage "  - Error processing folder: $_" "Red"
            $statistics.ErrorFolders++
        }
    } else {
        $statistics.MatchedFolders++
    }
    
    $processedFolders[$folderPath] = $true
}

# Final Statistics
Write-LogMessage "`n=== Processing Statistics ===" "Cyan"
Write-LogMessage "Total folders processed: $($statistics.TotalFolders)"
Write-LogMessage "Folders with matches: $($statistics.MatchedFolders)" "Green"
Write-LogMessage "Folders processed: $($statistics.MovedFolders)" "Yellow"
Write-LogMessage "Folders with errors: $($statistics.ErrorFolders)" "Red"
Write-LogMessage "Total files processed: $($statistics.ProcessedFiles)"
Write-LogMessage "Processing completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

Stop-Transcript