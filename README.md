# tif-pdf-validator

A utility tool to verify and compare TIF files against their corresponding PDF outputs. Perfect for OCR processing workflows.

## Purpose

Validates if TIF files in input/archive folders have matching PDF files in the output folder. Unmatched files can be moved or copied to a separate location for review.

## Features

- Compare TIF folders with PDF outputs
- Support for nested folder structures
- Multiple operation modes:
  - Move unmatched files
  - Copy unmatched files (keeps originals)
  - Preview mode (no changes)
- Detailed logging
- Interactive command-line interface

## Usage

1. Right-click properties > check unblock with the .bat and .ps1 file(s)
1. Run `RunCompareAndMove.bat`
2. Enter the required paths when prompted:
   ```
   Input/Archive Path:  [Path to TIF files]
   Output Path:        [Path to PDF files]
   Move Path:          [Path for unmatched files]
   ```
3. Select operation mode:
   - Move files
   - Copy files
   - Preview only
4. Enable/disable detailed logging
5. Review and confirm settings

## File Structure

Expected folder structure:
```
Input:
D:\Sample\Input\Project-A-123\
    └── Batch-001-XY\
        ├── scan001.tif
        ├── scan002.tif
        └── scan003.tif

Output:
D:\Sample\Output\
    └── Project-A-123\
        └── Batch-001-XY.pdf
```

## Requirements

- Windows OS
- PowerShell 5.1 or higher
- Administrative privileges not required

## Log Files

Log files are saved in the move directory with format:
```
FileComparisonLog_YYYYMMDD_HHMMSS.log
```
