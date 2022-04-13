# Battlegrounds Placement Tracker

## Table of Contents
1. Summary
1. [Installation/Execution](#Installation-Execution)
2. [Usage in OBS](#Usage-in-OBS)
3. [Script Exports](#Script-Exports)
4. [Other Notes](#Other-Notes)
5. [Known Bugs](#Known-Bugs)

## Summary

The purpose of this project is to track and record your Hearthstone Battlegrounds matches and export that information in a manner that can be used for streaming or simple data collection/aggregation.

------
## Installation/Execution: <a name="Installation-Execution"></a>
- Clone or download the script.
- Open the run.bat file.
- ~~Open an administrator Powershell window and cd to the directory that you placed the project.~~
- ~~Ensure your execution policy is set to bypass. (instructions can be found [here]~(https://riptutorial.com/powershell/example/20107/bypassing-execution-policy-for-a-single-script))
- ~~Run the script using: ```& .\bgMatchResults.ps1```~~

## Usage in OBS: <a name="Usage-in-OBS"></a>
- 

## Script Exports: <a name="Script-Exports"></a>
The script exports information into two primary files: a CSV file and a text file. The text file only has placement number and chosen hero recorded to it. This file can be used in OBS to keep an automatically updated list of placements for a stream (I haven't tested any other streaming applications yet). The CSV file stores more information that can be used for data aggregation (e.g. determine which heroes you win the most with). I'll list a comparison between the two files below.

**Text file:**
- Placement number
- Hero name

**CSV file:**
- Battle.net username
- Placement number
- Hero name
- Date/time (at start of match)

## Other Notes: <a name="Other-Notes"></a>
- While spectating does NOT export information to your files, you can still see the identical info in the powershell window.
- Battlegrounds calculates and determines the winner of a fight before the fighting starts, which means if you get 1st place or die that information is recorded and displayed well before the fighting finishes. I personally don't have an issue with this, but if you do please let me know and I can make adjustments to withhold that info.

## Known Bugs: <a name="Known-Bugs"></a>
- Aranna won't correctly record results due to her name change mid-match.
- Matches may not record properly after re-launching the game while the script is running.
