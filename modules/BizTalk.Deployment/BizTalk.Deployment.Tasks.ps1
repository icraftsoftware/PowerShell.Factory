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

# https://docs.microsoft.com/en-us/biztalk/core/btstask-command-line-reference

task Deploy Deploy-BizTalkApplication, Deploy-BizTalkArtifacts

task Undeploy Undeploy-BizTalkArtifacts, Undeploy-BizTalkApplication

task Deploy-BizTalkArtifacts Undeploy-BizTalkArtifacts, Deploy-Schemas, Deploy-Transforms, Deploy-Assemblies, Deploy-Components, Deploy-PipelineComponents, Deploy-Pipelines, Deploy-Orchestrations

task Undeploy-BizTalkArtifacts Undeploy-Orchestrations, Undeploy-Pipelines, Undeploy-PipelineComponents, Undeploy-Components, Undeploy-Assemblies, Undeploy-Transforms, Undeploy-Schemas

# task Create-BizTalkApplication -If {-not (Test-Application $ApplicationName)} {
task Deploy-BizTalkApplication Undeploy-BizTalkApplication, {
   Write-Build DarkGreen "Adding application '$ApplicationName'"
   exec { BTSTask AddApp -ApplicationName:"$ApplicationName" -Description:"$ApplicationDescription" | Out-Null }
   # TODO add app references
   # <AddAppReference ApplicationName="$(BizTalkAppName)" AppsToReference="@(AppsToReference)" Condition="%(Identity) == %(Identity) and '@(AppsToReference)' != ''" />
}
task Undeploy-BizTalkApplication -If { -not $SkipUndeploy -and (Test-Application -Name $ApplicationName) } Stop-Application, {
   Write-Build DarkGreen "Removing application '$ApplicationName'"
   exec { BTSTask RemoveApp -ApplicationName:"$ApplicationName" | Out-Null }
}
task Stop-Application {
   Stop-Application -Name $ApplicationName -TerminateServiceInstances:$TerminateServiceInstances
}

task Deploy-Assemblies {
   $ItemGroups.Assemblies.Path | ForEach-Object -Process {
      Write-Build DarkGreen $_
      exec { GacUtil /f /i "$_" | Out-Null }
   }
}
task Undeploy-Assemblies -If { -not $SkipUndeploy } {
   $ItemGroups.Assemblies.Path | ForEach-Object -Process {
      Write-Build DarkGreen $_
      exec { GacUtil /u ((Get-AssemblyName -Path $_).Name) | Out-Null }
   }
}

task Deploy-Components Undeploy-Components, {
   $ItemGroups.Components.Path | ForEach-Object -Process {
      Write-Build DarkGreen $_
      exec { GacUtil /f /i "$_" | Out-Null }
      if (-not $SkipInstallUtil) {
         exec { InstallUtil /ShowCallStack "$_" }
      }
   }
}
task Undeploy-Components -If { -not $SkipUndeploy } {
   $ItemGroups.Components.Path | ForEach-Object -Process {
      Write-Build DarkGreen $_
      exec { GacUtil /u ((Get-AssemblyName -Path $_).Name) | Out-Null }
      if (-not $SkipInstallUtil) {
         exec { InstallUtil /u /ShowCallStack "$_" }
      }
   }
}

task Deploy-Pipelines Undeploy-Pipelines, {
   $ItemGroups.Pipelines.Path | ForEach-Object -Process {
      Write-Build DarkGreen $_
      if ($SkipMgmtDbDeployment) {
         exec { GacUtil /f /i "$_" | Out-Null }
      }
      else {
         exec { BTSTask AddResource -ApplicationName:"$ApplicationName" -Type:BizTalkAssembly -Overwrite -Source:"$_" -Options:'GacOnAdd,GacOnImport,GacOnInstall' }
      }
   }
}
task Undeploy-Pipelines -If { -not $SkipUndeploy } {
   $ItemGroups.Pipelines.Path | ForEach-Object -Process {
      Write-Build DarkGreen $_
      exec { GacUtil /u ((Get-AssemblyName -Path $_).Name) | Out-Null }
   }
}

task Deploy-PipelineComponents {
   $ItemGroups.PipelineComponents.Path | ForEach-Object -Process {
      Write-Build DarkGreen $_
      Copy-Item -Path "$_" -Destination "$(Join-Path -Path $env:BTSINSTALLPATH -ChildPath 'Pipeline Components')"
      exec { GacUtil /f /i "$_" | Out-Null }
   }
}
task Undeploy-PipelineComponents -If { -not $SkipUndeploy } Recycle-AppPool, {
   $ItemGroups.PipelineComponents.Path | ForEach-Object -Process {
      Write-Build DarkGreen $_
      $pc = [System.IO.Path]::Combine($env:BTSINSTALLPATH, 'Pipeline Components', [System.IO.Path]::GetFileName($_))
      if (Test-Path -Path $pc) {
         Remove-Item -Path $pc
      }
      exec { GacUtil /u ((Get-AssemblyName -Path $_).Name) | Out-Null }
   }
}

task Deploy-Orchestrations Undeploy-Orchestrations, {
   $ItemGroups.Orchestrations.Path | ForEach-Object -Process {
      Write-Build DarkGreen $_
      if ($SkipMgmtDbDeployment) {
         exec { GacUtil /f /i "$_" | Out-Null }
      }
      else {
         exec { BTSTask AddResource -ApplicationName:"$ApplicationName" -Type:BizTalkAssembly -Overwrite -Source:"$_" -Options:'GacOnAdd,GacOnImport,GacOnInstall' }
      }
   }
}
task Undeploy-Orchestrations -If { -not $SkipUndeploy } {
   $ItemGroups.Orchestrations.Path | ForEach-Object -Process {
      Write-Build DarkGreen $_
      exec { GacUtil /u ((Get-AssemblyName -Path $_).Name) | Out-Null }
   }
}

task Deploy-Schemas Undeploy-Schemas, {
   $ItemGroups.Schemas.Path | ForEach-Object -Process {
      Write-Build DarkGreen $_
      if ($SkipMgmtDbDeployment) {
         exec { GacUtil /f /i "$_" | Out-Null }
      }
      else {
         exec { BTSTask AddResource -ApplicationName:"$ApplicationName" -Type:BizTalkAssembly -Overwrite -Source:"$_" -Options:'GacOnAdd,GacOnImport,GacOnInstall' }
      }
   }
}
task Undeploy-Schemas -If { -not $SkipUndeploy } {
   $ItemGroups.Schemas.Path | ForEach-Object -Process {
      Write-Build DarkGreen $_
      exec { GacUtil /u ((Get-AssemblyName -Path $_).Name) | Out-Null }
   }
}

task Deploy-Transforms Undeploy-Transforms, {
   $ItemGroups.Transforms.Path | ForEach-Object -Process {
      Write-Build DarkGreen $_
      if ($SkipMgmtDbDeployment) {
         exec { GacUtil /f /i "$_" | Out-Null }
      }
      else {
         exec { BTSTask AddResource -ApplicationName:"$ApplicationName" -Type:BizTalkAssembly -Overwrite -Source:"$_" -Options:'GacOnAdd,GacOnImport,GacOnInstall' }
      }
   }
}
task Undeploy-Transforms -If { -not $SkipUndeploy } {
   $ItemGroups.Transforms.Path | ForEach-Object -Process {
      Write-Build DarkGreen $_
      exec { GacUtil /u ((Get-AssemblyName -Path $_).Name) | Out-Null }
   }
}

task Recycle-AppPool {
   # see cmdlet Restart-WebAppPool
   # <Exec Command="iisreset.exe /noforce /restart /timeout:$(IisResetTime)" Condition="'@(IISAppPool)' == ''" />
   # <RecycleAppPool Items="@(IISAppPool)" Condition="'@(IISAppPool)' != ''" />
}
