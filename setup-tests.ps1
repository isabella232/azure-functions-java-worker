
# A function that checks exit codes and fails script if an error is found 
function StopOnFailedExecution {
  if ($LastExitCode)
  {
    exit $LastExitCode
  }
}
Write-Host "$args[0]"
Write-Host $args[0]

$skipCliDownload = $false
if($args[0])
{
  $skipCliDownload = $args[0]
}
Write-Host $skipCliDownload

$currDir =  Get-Location
if(!$skipCliDownload)
{
  Write-Host "Deleting Functions Core Tools if exists...."
  Remove-Item -Force ./Azure.Functions.Cli.zip -ErrorAction Ignore
  Remove-Item -Recurse -Force ./Azure.Functions.Cli -ErrorAction Ignore

  Write-Host "Downloading Functions Core Tools...."
  Invoke-RestMethod -Uri 'https://functionsclibuilds.blob.core.windows.net/builds/3/latest/version.txt' -OutFile version.txt
  Write-Host "Using Functions Core Tools version: pgopa-CLI"
  $version = "$(Get-Content -Raw version.txt)"
  Remove-Item version.txt

  if ($version -and $version.trim())
  {
    $env:CORE_TOOLS_URL = "https://pgopafunctestv2storage.blob.core.windows.net/cli/pgopa-cli.zip"
  }
  Write-Host "CORE_TOOLS_URL: $env:CORE_TOOLS_URL"
  $output = "$currDir\Azure.Functions.Cli.zip"
  $wc = New-Object System.Net.WebClient
  $wc.DownloadFile($env:CORE_TOOLS_URL, $output)

  Write-Host "Extracting Functions Core Tools...."
  Expand-Archive ".\Azure.Functions.Cli.zip" -DestinationPath ".\Azure.Functions.Cli"
}
Write-Host "Copying azure-functions-java-worker to  Functions Host workers directory...."
Get-ChildItem -Path .\target\* -Include 'azure*' -Exclude '*shaded.jar','*tests.jar' | %{ Copy-Item $_.FullName ".\Azure.Functions.Cli\workers\java\azure-functions-java-worker.jar" }
Copy-Item ".\worker.config.json" ".\Azure.Functions.Cli\workers\java"
Copy-Item ".\lib_worker_1.6.2" ".\Azure.Functions.Cli\workers\java\lib" -Recurse

Write-Host "Building endtoendtests...."
$Env:Path = $Env:Path+";$currDir\Azure.Functions.Cli"
Push-Location -Path "./endtoendtests" -StackName javaWorkerDir
Write-Host "Building azure-functions-maven-com.microsoft.azure.functions.endtoendtests"
cmd.exe /c '.\..\mvnBuildSkipTests.bat'
StopOnFailedExecution
Copy-Item "confluent_cloud_cacert.pem" ".\target\azure-functions\azure-functions-java-endtoendtests"
tree .
ls .\target\azure-functions\azure-functions-java-endtoendtests\bin
Pop-Location -StackName "javaWorkerDir"