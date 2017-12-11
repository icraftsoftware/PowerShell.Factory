#region Copyright & License

# Copyright © 2012 - 2017 François Chabot
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#endregion

use "$(Join-path -Path (Split-Path -Parent $PSCommandPath) -ChildPath 'Tools')" GacUtil
use "$($env:BTSINSTALLPATH)" BTSTask
use 'Framework\v4.0.30319' InstallUtil

task Deploy Undeploy, Deploy-BizTalkApplication, Deploy-BizTalkArtifacts

task Patch { $Script:SkipMgmtDbDeployment = $true }, Deploy-BizTalkArtifacts

task Undeploy -If { -not $SkipUndeploy } Undeploy-BizTalkArtifacts, Undeploy-BizTalkApplication

task Deploy-BizTalkArtifacts `
   Deploy-Schemas, `
   Deploy-Transforms, `
   Deploy-Assemblies, `
   Deploy-Components, `
   Deploy-PipelineComponents, `
   Deploy-Pipelines, `
   Deploy-Orchestrations

task Undeploy-BizTalkArtifacts `
   Undeploy-Orchestrations, `
   Undeploy-Pipelines, `
   Undeploy-PipelineComponents, `
   Undeploy-Components, `
   Undeploy-Assemblies, `
   Undeploy-Transforms, `
   Undeploy-Schemas

task Deploy-BizTalkApplication -If { -not (Test-Application $ApplicationName) } {
   Write-Build DarkGreen "Adding application '$ApplicationName'"
   exec { BTSTask AddApp -ApplicationName:"$ApplicationName" -Description:"$ApplicationDescription" }
   # TODO add app references
   # <AddAppReference ApplicationName="$(BizTalkAppName)" AppsToReference="@(AppsToReference)" Condition="%(Identity) == %(Identity) and '@(AppsToReference)' != ''" />
}
task Undeploy-BizTalkApplication -If { Test-Application -Name $ApplicationName } Stop-Application, {
   Write-Build DarkGreen "Removing application '$ApplicationName'"
   exec { BTSTask RemoveApp -ApplicationName:"$ApplicationName" }
}
task Stop-Application {
   Stop-Application -Name $ApplicationName -TerminateServiceInstances:$TerminateServiceInstances
}

# Synopsis: Add assemblies to gac
task Deploy-Assemblies {
   Get-TaskItemGroup -Task $Task | ForEach-Object -Process {
      Add-ToGac -Path $_.Path
   }
}
# Synopsis: Remove assemblies from gac
task Undeploy-Assemblies {
   Get-TaskItemGroup -Task $Task | ForEach-Object -Process {
      Remove-FromGac -Path $_.Path
   }
}

task Deploy-Components Undeploy-Components, {
   Get-TaskItemGroup -Task $Task | ForEach-Object -Process {
      Add-ToGac -Path $_.Path
      Install-Component -Path $_.Path -SkipInstallUtil:$SkipInstallUtil
   }
}
task Undeploy-Components {
   Get-TaskItemGroup -Task $Task | ForEach-Object -Process {
      Uninstall-Component -Path $_.Path -SkipInstallUtil:$SkipInstallUtil
      Remove-FromGac -Path $_.Path
   }
}

task Deploy-Pipelines {
   Get-TaskItemGroup -Task $Task | ForEach-Object -Process {
      if ($SkipMgmtDbDeployment) {
         Add-ToGac -Path $_.Path
      }
      else {
         Add-BizTalkResource -Path $_.Path -ApplicationName $ApplicationName
      }
   }
}
task Undeploy-Pipelines {
   Get-TaskItemGroup -Task $Task | ForEach-Object -Process {
      Remove-FromGac -Path $_.Path
   }
}

task Deploy-PipelineComponents {
   Get-TaskItemGroup -Task $Task | ForEach-Object -Process {
      Copy-Item -Path $_.Path -Destination "$(Join-Path -Path $env:BTSINSTALLPATH -ChildPath 'Pipeline Components')" -Force
      Add-ToGac -Path $_.Path
   }
}
task Undeploy-PipelineComponents Recycle-AppPool, {
   Get-TaskItemGroup -Task $Task | ForEach-Object -Process {
      $pc = [System.IO.Path]::Combine($env:BTSINSTALLPATH, 'Pipeline Components', [System.IO.Path]::GetFileName($_.Path))
      if (Test-Path -Path $pc) {
         Remove-Item -Path $pc -Force
      }
      Remove-FromGac -Path $_.Path
   }
}

task Deploy-Orchestrations {
   Get-TaskItemGroup -Task $Task | ForEach-Object -Process {
      if ($SkipMgmtDbDeployment) {
         Add-ToGac -Path $_.Path
      }
      else {
         Add-BizTalkResource -Path $_.Path -ApplicationName $ApplicationName
      }
   }
}
task Undeploy-Orchestrations {
   Get-TaskItemGroup -Task $Task | ForEach-Object -Process {
      Remove-FromGac -Path $_.Path
   }
}

task Deploy-Schemas {
   Get-TaskItemGroup -Task $Task | ForEach-Object -Process {
      if ($SkipMgmtDbDeployment) {
         Add-ToGac -Path $_.Path
      }
      else {
         Add-BizTalkResource -Path $_.Path -ApplicationName $ApplicationName
      }
   }
}
task Undeploy-Schemas {
   Get-TaskItemGroup -Task $Task | ForEach-Object -Process {
      Remove-FromGac -Path $_.Path
   }
}

task Deploy-Transforms {
   Get-TaskItemGroup -Task $Task | ForEach-Object -Process {
      if ($SkipMgmtDbDeployment) {
         Add-ToGac -Path $_.Path
      }
      else {
         Add-BizTalkResource -Path $_.Path -ApplicationName $ApplicationName
      }
   }
}
task Undeploy-Transforms {
   Get-TaskItemGroup -Task $Task | ForEach-Object -Process {
      Remove-FromGac -Path $_.Path
   }
}

task Recycle-AppPool {
   # see cmdlet Restart-WebAppPool
   # <Exec Command="iisreset.exe /noforce /restart /timeout:$(IisResetTime)" Condition="'@(IISAppPool)' == ''" />
   # <RecycleAppPool Items="@(IISAppPool)" Condition="'@(IISAppPool)' != ''" />
}

function Get-TaskItemGroup {
   [CmdletBinding()]
   [OutputType([PSCustomObject[]])]
   param(
      [Parameter(Mandatory = $true)]
      [ValidateNotNull()]
      [psobject]
      $Task
   )
   $object = $Task.Name -split '-' | Select-Object -Skip 1
   $ItemGroups.$object
}

function Add-BizTalkResource {
   [CmdletBinding()]
   [OutputType([void])]
   param(
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Path,

      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $ApplicationName
   )
   # https://docs.microsoft.com/en-us/biztalk/core/btstask-command-line-reference
   Write-Build DarkGreen $Path
   exec { BTSTask AddResource -ApplicationName:"$ApplicationName" -Type:BizTalkAssembly -Overwrite -Source:"$Path" -Options:'GacOnAdd,GacOnImport,GacOnInstall' }
}

function Add-ToGac {
   [CmdletBinding()]
   [OutputType([void])]
   param(
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Path
   )
   Write-Build DarkGreen $Path
   exec { GacUtil /f /i "$Path" }
}
function Remove-FromGac {
   [CmdletBinding()]
   [OutputType([void])]
   param(
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Path
   )
   Write-Build DarkGreen $Path
   $name = Get-AssemblyName -Path $Path -Name
   exec { GacUtil /u "$name" }
}

function Install-Component {
   [CmdletBinding()]
   [OutputType([void])]
   param(
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Path,

      [Parameter(Mandatory = $false)]
      [switch]
      $SkipInstallUtil
   )
   if (-not $SkipInstallUtil) {
      Write-Build DarkGreen $Path
      exec { InstallUtil /ShowCallStack "$Path" }
   }
}
function Uninstall-Component {
   [CmdletBinding()]
   [OutputType([void])]
   param(
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Path,

      [Parameter(Mandatory = $false)]
      [switch]
      $SkipInstallUtil
   )
   if (-not $SkipInstallUtil) {
      Write-Build DarkGreen $Path
      exec { InstallUtil /u /ShowCallStack "$Path" }
   }
}
