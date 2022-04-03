#### Instantiate variables ####
$global:activeMatch = 0
$global:activeApp = 0
$global:errorCount = 0
$global:gameOver = 0
$global:gameOverStatus = $NULL
$global:gameStart = 0
$global:isSpectating = $NULL
$global:matchEndStatus = $NULL
$global:matchStartStatus = $NULL
$global:midnight = 0
$global:playerHeroID = $NULL
$global:playerHeroName = $NULL
$global:playerHeroString = $NULL
$global:playerID = $NULL
$global:playerString = $NULL
$global:playerUN = $NULL
$global:spectate = 0
$global:status = $NULL
$global:timeStamp = $NULL

$global:resultsFileCSV = "~\hsResults.csv"
$global:resultsFileTXT = "~\hsResults.txt"


#### Instantiate functions ####
function checkMidnight {
  $midnightTime = (Get-Content "C:\Program Files (x86)\Hearthstone\Logs\Power.log" -tail 1).split(" ")[1]
  if (($midnightTime -like "00:*") -and ($global:midnight -ne 1)){
    echo "New timestamp: $midnightTime"
    $global:midnight = 1
    # $global:timeStamp = $midnightTime
    # $global:timeStamp | Out-File .\timestamp.txt
  }elseif(($midnightTime -like "01:*") -and ($global:midnight -ne 0)){
    $global:midnight = 0
  }
}

function checkSpectating{
  echo "Checking for spectating match..."
  if(($global:isSpectating = Get-Content "C:\Program Files (x86)\Hearthstone\Logs\Power.log" -tail 5000 | Where-Object {($_.Contains("================== Start Spectator Game ==================")) -or ($_.Contains("================== Begin Spectating 1st player =================="))} | Where-Object { $_.split(" ")[1] -ge $global:timeStamp }) -ne $NULL){
    $global:spectate = 1
  }
  ### verbatim output
  # $global:isSpectating
}

function checkEndSpectating{
  if ((Get-Content "C:\Program Files (x86)\Hearthstone\Logs\Power.log" -tail 5000 | Where-Object {$_.Contains("================== End Spectator Mode ==================")} | Where-Object { $_.split(" ")[1] -ge $global:timeStamp }) -ne $NULL){
    $global:spectate = 0
    $timeStampLine = Get-Content "C:\Program Files (x86)\Hearthstone\Logs\Power.log" -tail 5000 | Where-Object {$_.Contains("================== End Spectator Mode ==================")} | Where-Object { $_.split(" ")[1] -ge $global:timeStamp }
    if ($timeStampLine -ne $NULL){
      $global:timeStamp = $timeStampLine.Split(" ")[1]
      $global:timeStamp | Out-File .\timestamp.txt
    }
    Clear-Variable matchEndStatus,playerString,playerID,playerUN
    . .\bgMatchResults.ps1
    gameScript
  }
}

function checkNewGame {
  $global:matchStartStatus = Get-Content "C:\Program Files (x86)\Hearthstone\Logs\Power.log" -tail 5000 | Where-Object {($_.Contains("GameState.DebugPrintPower() - CREATE_GAME")) -or ($_.Contains("================== Start Spectator Game ==================")) -or ($_.Contains("================== Begin Spectating 1st player =================="))} | Where-Object { $_.split(" ")[1] -ge $global:timeStamp };Clear-Variable matchEndStatus
  $timeStampLine = Get-Content "C:\Program Files (x86)\Hearthstone\Logs\Power.log" -tail 2000 | Where-Object {($_.Contains("GameState.DebugPrintPower() - CREATE_GAME")) -or ($_.Contains("================== Start Spectator Game ==================")) -or ($_.Contains("================== Begin Spectating 1st player =================="))}
  if ($timeStampLine -ne $NULL){
    $global:timeStamp = $timeStampLine.Split(" ")[1]
    $global:timeStamp | Out-File .\timestamp.txt

  }
  
}
function checkEndGame {
  $global:matchEndStatus = Get-Content "C:\Program Files (x86)\Hearthstone\Logs\Power.log" -tail 5000 | Where-Object {($_.contains("TAG_CHANGE Entity=$playerUN tag=PLAYSTATE value=LOST")) -or ($_.contains("TAG_CHANGE Entity=$playerUN tag=PLAYSTATE value=WON"))} | Where-Object { $_.split(" ")[1] -ge $global:timeStamp }; Clear-Variable matchStartStatus; if($global:spectate -eq 1){checkEndSpectating}; checkMidnight
}

function status {
  $global:status = Get-Process -Name Hearthstone -erroraction 'silentlycontinue'
}

function appStatus {
  status
  if ($global:status -eq $NULL){
    Write-Output "Waiting for Hearthstone to open..."
    do {
      Write-Host "`r##### O o o #####" -nonewline; status
      Start-Sleep -m 300
      Write-Host "`r##### o O o #####" -nonewline; status
      Start-Sleep -m 300
      Write-Host "`r##### o o O #####" -nonewline; status
      Start-Sleep -m 300
    } until ($global:status -ne $NULL)
    appStatus
  }else{
    $global:errorCount = 0
    $global:activeApp = 1
  }
}

function calcMatchResults {
  ### CHECK IF PLAYER WON OR LOST
  Write-Output "Match over. Gathering results..."
  $matchResultString = Get-Content "C:\Program Files (x86)\Hearthstone\Logs\Power.log" -tail 30000 | Where-Object { ($_.Contains("GameState.DebugPrintPower() - TAG_CHANGE Entity=$playerUN tag=PLAYSTATE value=LOST")) -or ($_.Contains("GameState.DebugPrintPower() - TAG_CHANGE Entity=$playerUN tag=PLAYSTATE value=WON"))} | Where-Object { $_.split(" ")[1] -ge $global:timeStamp }
  $matchResult = ($matchResultString -replace ".*value=")
  Start-Sleep -s 1
  if ($matchResult -ne "WON"){
    $playerResultString = Get-Content "C:\Program Files (x86)\Hearthstone\Logs\Power.log" -tail 100000 | Where-Object { $_.Contains("$playerHeroName") } | Where-Object { $_.Contains("tag=PLAYER_LEADERBOARD_PLACE") } | Where-Object { !$_.Contains("value=0") } | Where-Object { $_.split(" ")[1] -ge $global:timeStamp }
    ### verbatim output
    # $playerResultString
    if($playerResultString.count -gt 1){
      $playerResult = ($playerResultString[$playerResultString.count-1] -replace ".*value=")
    }else{
      $playerResult = ($playerResultString -replace ".*value=")
    }
  }else{
    $playerResult = 1
  }
  
  $newLine1 = "{0},{1},{2},{3}" -f $playerUN,$playerResult,$global:playerHeroName,(Get-Date -Format u)
  # if ($matchResult -eq "LOST"){
  echo "- Match Recorded -"
  Start-Sleep -m 100
  echo "Player: $playerUN"
  Start-Sleep -m 100
  echo "Hero: $playerHeroName"
  Start-Sleep -m 100
  echo "Place: $playerResult"
  echo "Date: $(Get-Date -Format u)"
  echo "\_/\_/\_/\_/\_/\_/\_/\_/\_/\_/\_/\_/\_/"
  $newLine2 = "$playerResult  - $playerHeroName"
  if ($global:spectate -eq 0){
    $newLine1 | Add-Content $global:resultsFileCSV
    $newLine2 | Add-Content $global:resultsFileTXT
  }
}

function getPlayerInfo {
  ### Get player info ###
  echo "<<---------------------------------->>"
  echo "Checking for player info..."
  do{
    $global:playerString = Get-Content "C:\Program Files (x86)\Hearthstone\Logs\Power.log" -tail 5000 | Where-Object { ($_.Contains("GameState.DebugPrintGame() - PlayerID=")) -and (!$_.Contains("PlayerName=The Innkeeper"))} | Where-Object { $_.split(" ")[1] -ge $global:timeStamp }; appStatus
    ### verbatim output
    # $global:playerString
  }until($global:playerString -ne $NULL)

  ### Extract exact ID and username from string
  ### verbatim output
  # echo "String count: $($global:playerString.count)"
  $global:playerID = ($global:playerString -replace ".*PlayerID=").Substring(0,1)
  echo "Player's match ID: $global:playerID"
  $global:playerUN = ($global:playerString -replace ".*PlayerName=")
  echo "Player's username: $global:playerUN"

  ### Get hero info ###
  # checkSpectating
  echo "Checking for hero info..."
  if($global:spectate -eq 0) {
    do{
      appStatus
      checkEndGame
      $global:playerHeroString = Get-Content "C:\Program Files (x86)\Hearthstone\Logs\Power.log" -tail 5000 | Where-Object { $_.Contains("GameState.SendChoices() -   m_chosenEntities[0]=") } | Where-Object { $_.Contains("zone=HAND") } | Where-Object { $_.split(" ")[1] -ge $global:timeStamp }
    }until($global:playerHeroString -ne $NULL)
    ### verbatim output
    # $global:playerHeroString
  }else{
    do{
      checkEndSpectating
      $global:playerHeroString = Get-Content "C:\Program Files (x86)\Hearthstone\Logs\Power.log" -tail 5000 | Where-Object { $_.Contains("GameState.DebugPrintEntitiesChosen() -   Entities[0]=[entityName=") } | Where-Object { $_.Contains("zone=HAND") } | Where-Object { $_.split(" ")[1] -ge $global:timeStamp }
      if(@("BaconPHhero",$NULL) -contains $global:playerHeroString){
        $global:playerHeroString = Get-Content "C:\Program Files (x86)\Hearthstone\Logs\Power.log" -tail 5000 | Where-Object { ($_.Contains("PowerTaskList.DebugPrintPower() -     FULL_ENTITY - Updating [entityName=")) } | Where-Object { $_.Contains("zone=PLAY") } | Where-Object { $_.Contains("_HERO_") } | Where-Object { !$_.Contains("_Buddy") } | Where-Object { $_.Contains("player=$global:playerID") } | Where-Object { $_.split(" ")[1] -ge $global:timeStamp } | Where-Object { $_[-1.-1] -ne 'p'} | Where-Object { $_[-1] -ne 'p'} | Where-Object { $_ -notlike "*p_*"}
      }
    # }until($global:playerHeroString -ne $NULL)
    }until(@("BaconPHhero",$NULL) -notcontains $global:playerHeroString)
    ### verbatim output
    # $global:playerHeroString
  }

  ### Extract exact hero name and ID from string ###
  if ($global:playerHeroString -ne $NULL){
    if ($global:playerHeroString.count -gt 1){
      $global:playerHeroID = ($global:playerHeroString[($global:playerHeroString.Length-1)] -replace ".* id=").Substring(0,2)
      $global:playerHeroName = ($global:playerHeroString[($global:playerHeroString.Length-1)] -replace ".*entityName=" -replace "id=.*")
    }else{
      $global:playerHeroID = ($global:playerHeroString -replace ".* id=").Substring(0,2)
      $global:playerHeroName = ($global:playerHeroString -replace ".*entityName=" -replace "id=.*")
    }
    echo "Hero ID: $global:playerHeroID"
    echo "Player's Hero: $global:playerHeroName"
    echo "<<---------------------------------->>"
  }
}

function gameStart {
  echo "Waiting for match info..."
  do {
    appStatus
    checkNewGame
  } until ($global:matchStartStatus -ne $NULL)
  appStatus
  checkSpectating
  if($global:spectate -eq 0){"Not spectating"}else{"Spectating"; $global:spectate=1}
  appStatus
  getPlayerInfo
  $global:gameStart = 1
}

function matchResult {
  Write-Output "Waiting for match to finish..."
  $global:matchEndStatus = $NULL
  do {
    appStatus
    checkEndGame
  } until ($global:matchEndStatus -ne $NULL)
  $global:matchEndStatus
  calcMatchResults
}

function gameScript{
  appStatus
  if ($global:activeApp -eq 1){
    appStatus
    gameStart
    if ($global:gameStart -eq 1){
      appStatus
      matchResult
    }
  }
}

#### Begin game script ####
Start-Transcript -Append ~\bgScriptLog.txt
$global:timeStamp = Get-Content ".\timestamp.txt"
while($true){
  # cd ~
  # cd "C:\Users\GrahamWin10\Documents\Hearthstone Project"
  appStatus
  Write-Host "`r######## Hearthstone is open ########"
  Start-Sleep -m 500
  echo "Checking for power.log..."
  While (!(Test-Path "C:\Program Files (x86)\Hearthstone\Logs\Power.log" -ErrorAction SilentlyContinue)){Write-Host "`rPower.log not created yet. Start match..." -NoNewline; appStatus}
  echo "Power.log found."
  gameScript
}