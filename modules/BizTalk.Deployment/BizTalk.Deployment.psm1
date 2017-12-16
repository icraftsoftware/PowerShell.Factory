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

Set-StrictMode -Version Latest

function Get-AssemblyName {
   [CmdletBinding()]
   [OutputType([psobject[]])]
   param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [ValidateNotNull()]
      [psobject[]]
      $Path,

      [Parameter(Mandatory = $false)]
      [switch]
      $Name,

      [Parameter(Mandatory = $false)]
      [switch]
      $FullName
   )
   process {
      $Path | ForEach-Object -Process { $_ } | ForEach-Object -Process {
         $assemblyName = [System.Reflection.AssemblyName]::GetAssemblyName($_)
         if ($Name) {
            $assemblyName.Name
         }
         elseif ($FullName) {
            $assemblyName.$FullName
         }
         else {
            $assemblyName
         }
      }
   }
}

function Stop-Application {
   [CmdletBinding()]
   [OutputType([boolean])]
   param(
      [Parameter(Position = 0, Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Name,

      [Parameter(Position = 1, Mandatory = $false)]
      [ApplicationStopOption]
      $StopOptions = (
         [ApplicationStopOption]::UnenlistAllOrchestrations -bor
         [ApplicationStopOption]::UnenlistAllSendPorts -bor
         [ApplicationStopOption]::UnenlistAllSendPortGroups -bor
         [ApplicationStopOption]::DisableAllReceiveLocations -bor
         [ApplicationStopOption]::UndeployAllPolicies
      ),

      [Parameter(Position = 2, Mandatory = $false)]
      [switch]
      $TerminateServiceInstances,

      [Parameter(Position = 3, Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [string]
      $ManagementDatabaseServer = (Get-RegisteredMgmtDbServer),

      [Parameter(Position = 4, Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [string]
      $ManagementDatabaseName = (Get-RegisteredMgmtDbName)
   )
   Use-Object ($controller = Get-BizTalkController $ManagementDatabaseServer $ManagementDatabaseName) {
      if ($TerminateServiceInstances) {
         $controller.GetServiceInstances() |
            ForEach-Object -Process { $_ -as [ServiceInstance] } |
            Where-Object -FilterScript { $_.Application -eq $Name -and ($_.InstanceStatus -band ([InstanceStatus]::RunningAll -bor [InstanceStatus]::SuspendedAll)) } |
            ForEach-Object -Process {
            Write-Information "Terminating service instance ['$($_.Class)', '$($_.ID)']."
            result = $controller.TerminateInstance($_.ID)
            if (result -ne [CompletionStatus]::Succeeded -and $_.Class -ne [ServiceClass::RoutingFailure]) {
               throw "Cannot stop application '$Name': failed to terminate service instance ['$($_.Class)', '$($_.ID)']."
            }
         }
      }
      $hasInstance = $controller.GetServiceInstances() |
         ForEach-Object -Process { $_ -as [ServiceInstance] } |
         Where-Object -FilterScript { $_.Application -eq $Name } |
         Test-Any
      if ($hasInstance) {
         throw "Cannot stop application '$Name' with associated service intances."
      }
   }
   Use-Object ($catalog = Get-BizTalkCatalog $ManagementDatabaseServer $ManagementDatabaseName) {
      $application = $catalog.Applications[$Name]
      try {
         $application.Stop($StopOptions)
         $catalog.SaveChanges()
      }
      catch {
         $catalog.DiscardChanges()
         throw
      }
   }
}

function Test-Application {
   [CmdletBinding()]
   [OutputType([boolean])]
   param(
      [Parameter(Position = 0, Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Name,

      [Parameter(Position = 1, Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [string]
      $ManagementDatabaseServer = (Get-RegisteredMgmtDbServer),

      [Parameter(Position = 2, Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [string]
      $ManagementDatabaseName = (Get-RegisteredMgmtDbName)
   )
   Use-Object ($catalog = Get-BizTalkCatalog $ManagementDatabaseServer $ManagementDatabaseName) {
      $catalog.Applications[$Name] -ne $null
   }
}

#region private helpers

function Get-BizTalkCatalog {
   [CmdletBinding()]
   [OutputType([BizTalkCatalog])]
   param(
      [Parameter(Position = 0, Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [string]
      $ManagementDatabaseServer = (Get-RegisteredMgmtDbServer),

      [Parameter(Position = 1, Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [string]
      $ManagementDatabaseName = (Get-RegisteredMgmtDbName)
   )
   try {
      $catalog = New-Object BizTalkCatalog
      $catalog.ConnectionString = "Server=$ManagementDatabaseServer;Database=$ManagementDatabaseName;Integrated Security=SSPI;"
      $catalog.Refresh()
      $catalog
   }
   catch {
      $disposable = [System.IDisposable]$catalog
      if ($disposable -ne $null) {
         $disposable.Dispose()
      }
   }
}

function Get-BizTalkController {
   [CmdletBinding()]
   [OutputType([BizTalkController])]
   param(
      [Parameter(Position = 0, Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [string]
      $ManagementDatabaseServer = (Get-RegisteredMgmtDbServer),

      [Parameter(Position = 1, Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [string]
      $ManagementDatabaseName = (Get-RegisteredMgmtDbName)
   )
   try {
      $controller = New-Object BizTalkController -ArgumentList $ManagementDatabaseServer, $ManagementDatabaseName
      $controller
   }
   catch {
      $disposable = [System.IDisposable]$controller
      if ($disposable -ne $null) {
         $disposable.Dispose()
      }
   }
}

function Get-RegisteredMgmtDbName {
   [CmdletBinding()]
   [OutputType([string])]
   param()
   if ($MyInvocation.MyCommand.Module.PrivateData['MgmtDbName'] -eq $null) {
      $MyInvocation.MyCommand.Module.PrivateData['MgmtDbName'] = Get-BizTalkAdministrationRegistryKeyValue 'MgmtDBName'
   }
   $MyInvocation.MyCommand.Module.PrivateData['MgmtDbName']
}

function Get-RegisteredMgmtDbServer {
   [CmdletBinding()]
   [OutputType([string])]
   param()
   if ($MyInvocation.MyCommand.Module.PrivateData['MgmtDbServer'] -eq $null) {
      $MyInvocation.MyCommand.Module.PrivateData['MgmtDbServer'] = Get-BizTalkAdministrationRegistryKeyValue 'MgmtDBServer'
   }
   $MyInvocation.MyCommand.Module.PrivateData['MgmtDbServer']
}

function Get-BizTalkAdministrationRegistryKeyValue {
   [CmdletBinding()]
   [OutputType([string])]
   param(
      [Parameter(Position = 0, Mandatory = $true)]
      [string]
      $Name
   )
   Use-Object ($hklm = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry32)) {
      $keyPath = 'SOFTWARE\Microsoft\Biztalk Server\3.0\Administration'
      Use-Object ($key = $hklm.OpenSubKey($keyPath)) {
         if ($key -eq $null) {
            throw "Cannot find registry key '$($hklm.Name)\$keyPath'"
         }
         [string]$key.GetValue($Name)
      }
   }
}

function Use-Object {
   [CmdletBinding()]
   param (
      [Parameter(Mandatory = $true)]
      [AllowEmptyString()]
      [AllowEmptyCollection()]
      [AllowNull()]
      [System.IDisposable]
      $Object,

      [Parameter(Mandatory = $true)]
      [scriptblock]
      $ScriptBlock
   )
   try {
      . $ScriptBlock
   }
   finally {
      if ($Object -ne $null) {
         $Object.Dispose()
      }
   }
}

#endregion

<#
 # Main
 #>

[accelerators]::Add('ApplicationStopOption', 'Microsoft.BizTalk.ExplorerOM.ApplicationStopOption')
[accelerators]::Add('BizTalkCatalog', 'Microsoft.BizTalk.ExplorerOM.BtsCatalogExplorer')

[accelerators]::Add('BizTalkController', 'Microsoft.BizTalk.Operations.BizTalkOperations')
[accelerators]::Add('CompletionStatus', 'Microsoft.BizTalk.Operations.CompletionStatus')
[accelerators]::Add('InstanceStatus', 'Microsoft.BizTalk.Operations.InstanceStatus')
[accelerators]::Add('ServiceClass', 'Microsoft.BizTalk.Operations.ServiceClass')
[accelerators]::Add('ServiceInstance', 'Microsoft.BizTalk.Operations.MessageBoxServiceInstance')

Export-ModuleMember -Function Get-AssemblyName, Stop-Application, Test-Application

# https://github.com/nightroman/Invoke-Build/tree/master/Tasks/Import
# https://github.com/nightroman/Invoke-Build/issues/73, Importing Tasks
Set-Alias BizTalk.Deployment.Tasks $PSScriptRoot/BizTalk.Deployment.tasks.ps1
Export-ModuleMember -Alias BizTalk.Deployment.Tasks
