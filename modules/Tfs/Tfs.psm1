#region Copyright & License

# Copyright © 2012 - 2019 François Chabot
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

<#
.SYNOPSIS
    Get the one or all the TFS workspaces defined on this computer.
.DESCRIPTION
    This command will return the TFS Workspace object instances corresponding to the workspaces defined on the current computer.
.PARAMETER Uri
    The URI of the TFS Server.
.EXAMPLE
    PS> Get-Workspace -Uri https://dev.azure.com/stateless
.EXAMPLE
    PS> Get-Workspace -Uri https://dev.azure.com/stateless | ForEach Name
.EXAMPLE
    PS> Get-Workspace -Uri https://dev.azure.com/stateless -Name BizTalk.Factory
.LINK
    https://gist.github.com/785710
.NOTES
    © 2019 be.stateless.
#>
function Get-Workspace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Uri,

        [Parameter(ParameterSetName = 'Item')]
        [ValidateScript( { $_ -ne $null })]
        [string]
        $Name
    )

    $vcs = Get-VersionControlServer -Uri $Uri
    if ($PsCmdlet.ParameterSetName -eq 'Item') {
        $vcs.QueryWorkspaces($Name, '.', $env:COMPUTERNAME)
        # Invoke-Method -InputObject $vcs -MethodName 'QueryWorkspaces' -Arguments $Name, '.', $env:COMPUTERNAME
    }
    else {
        # the intuitive call can't be performed directly, $null cannot be passed, see
        # https://connect.microsoft.com/feedback/ViewFeedback.aspx?SiteID=99&FeedbackID=307821
        # $workspaces = $vcs.QueryWorkspaces($null, '.', $env:COMPUTERNAME)
        Invoke-Method -InputObject $vcs -MethodName 'QueryWorkspaces' -Arguments $null, '.', $env:COMPUTERNAME
    }
}

function New-Workspace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Uri,

        [ValidateScript( { $_ -ne $null })]
        [string]
        $Name,

        [Parameter(Mandatory = $true)]
        [object[]]
        $Folders
    )

    if (-not(Test-Workspace -Uri $Uri -Name $Name)) {
        $workspaceParameters = New-Object `
            -TypeName Microsoft.TeamFoundation.VersionControl.Client.CreateWorkspaceParameters `
            -ArgumentList $Name
        $workspaceParameters.Folders = (ConvertTo-WorkingFolder -Folders $Folders)
        $workspaceParameters.WorkspaceOptions = [Microsoft.TeamFoundation.VersionControl.Common.WorkspaceOptions]::SetFileTimeToCheckin

        $vcs = Get-VersionControlServer -Uri $Uri
        $workspace = $vcs.CreateWorkspace($workspaceParameters)
        $workspace
    }
}

function Test-Workspace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Uri,

        [ValidateScript( { $_ -ne $null })]
        [string]
        $Name
    )

    $null -ne (Get-Workspace -Uri $Uri -Name $Name)
}

function ConvertTo-WorkingFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]
        $Folders
    )

    @(
        $Folders |
            Where-Object { $null -ne $_.LocalItem } |
                ForEach-Object {
                    New-Object `
                        -TypeName Microsoft.TeamFoundation.VersionControl.Client.WorkingFolder `
                        -ArgumentList @(
                        $_.ServerItem,
                        $_.LocalItem,
                        [Microsoft.TeamFoundation.VersionControl.Client.WorkingFolderType]::Map
                    )
                }
        $Folders |
            Where-Object { $null -eq $_.LocalItem } |
                ForEach-Object {
                    New-Object `
                        -TypeName Microsoft.TeamFoundation.VersionControl.Client.WorkingFolder `
                        -ArgumentList @(
                        $_.ServerItem,
                        $null,
                        [Microsoft.TeamFoundation.VersionControl.Client.WorkingFolderType]::Cloak
                    )
                }
    )
}

<#
.SYNOPSIS
    Creates a PowerShell function to quickly set the console's current folder to the src subfolder of a local folder mapped to a TFS workspace.
.DESCRIPTION
    For a TFS workspace whose name is 'Foo', this command will create a global PowerShell shell function 'Foo:' whose purpose is to quickly switch the console's current folder to the src subfolder of a local folder mapped to the 'Foo' TFS workspace. Concretely, the following global command/function will be defined:
    Foo: { Set-Location 'c:\project\mapped\folder\src' }
    where 'c:\project\mapped\folder' denotes the folder mapped to the 'Foo' workspace.
.PARAMETER Workspace
    A Microsoft.TeamFoundation.VersionControl.Client.Workspace instance.
.EXAMPLE
    PS> New-WorkspaceShortcut $workspace
.EXAMPLE
    PS> Get-Workspaces -Uri https://tfs.codeplex.com/tfs/TFS14 | New-WorkspaceShortcut
.LINK
    https://gist.github.com/785710
.NOTES
    © 2012 be.stateless.
#>
function New-WorkspaceShortcut {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [psobject]
        $Workspace,

        [Parameter(Mandatory = $false)]
        [string]
        $Prefix = ''
    )

    #begin { }
    process {
        $name = $Prefix + ($Workspace.Name -replace ' ', '_' -replace '\.', '_')
        if (($Workspace.Folders.Length -gt 0) -and -not(Test-Path "function:global:$name):")) {
            # look for the first folder for which LocalItem\src exists on disk
            $folder = $Workspace.Folders |
                Where-Object { Test-Path -Path "$($_.LocalItem)\src" } |
                    Select-Object -First 1 -ExpandProperty LocalItem

            # create a shortcut function and report its creation
            New-Item -Name "global:$($name):" -Path function: -Value "Set-Location '$folder\src'" -Force |
                ForEach-Object { 'Created Workspace Shortcut {0}' -f $_.Name } |
                    Out-Default
        }
    }
    #end { }
}

<#
 # Private Helper Functions
 #>

function Add-TeamFoundationClientAssemblies {
    [CmdletBinding()]
    param()

    $vswherePath = Split-Path -Parent (Get-VSSetupInstance | Select-VSSetupInstance -Latest).Properties['SetupEngineFilePath']
    $paths = @(
        # https://github.com/microsoft/vswhere/issues/189
        # https://github.com/microsoft/vssetup.powershell/issues/52
        # Get-VSSetupInstance | Select-VSSetupInstance -Require Microsoft.VisualStudio.TestTools.TeamFoundationClient -Latest
        # see https://github.com/microsoft/vssetup.powershell/issues/52#issuecomment-533813553
        & "$vswherePath\vswhere.exe" -latest -requires Microsoft.VisualStudio.TestTools.TeamFoundationClient -find **\TeamFoundation\**\Microsoft.TeamFoundation.Client.dll
        & "$vswherePath\vswhere.exe" -latest -requires Microsoft.VisualStudio.TestTools.TeamFoundationClient -find **\TeamFoundation\**\Microsoft.TeamFoundation.VersionControl.Client.dll
    )
    if ($paths | Test-Any) {
        $paths | ForEach-Object -Process { Add-Type -LiteralPath $_ }
    }
    else {
        $highestVisualStudioVersionNumber = Get-VisualStudioVersionNumbers -Descending | Select-Object -First 1
        if ($null -eq $highestVisualStudioVersionNumber) {
            throw 'Visual Studio is not installed.'
        }
        Add-Type -AssemblyName "Microsoft.TeamFoundation.Client, Version=$highestVisualStudioVersionNumber.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"
        Add-Type -AssemblyName "Microsoft.TeamFoundation.VersionControl.Client, Version=$highestVisualStudioVersionNumber.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"
    }
}

function Assert-TeamFoundationClientAssemblies {
    [CmdletBinding()]
    param(
        [switch]
        $Force
    )

    if (-not(Test-TeamFoundationClientAssemblies)) {
        if (-not($Force)) {
            throw "TeamFoundation client assemblies are required to run this module's cmdlets!"
        }
        Add-TeamFoundationClientAssemblies
    }
}

function Test-TeamFoundationClientAssemblies {
    [CmdletBinding()]
    param()

    # http://stackoverflow.com/questions/16552801/how-do-i-conditionally-add-a-class-with-add-type-typedefinition-if-it-isnt-add
    -not ([System.Management.Automation.PSTypeName] 'Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory').Type `
        -and -not ([System.Management.Automation.PSTypeName] 'Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer').Type
}

function Get-VersionControlServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Uri
    )

    $tfs = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($Uri)
    $tfs.Authenticate()
    $tfs.GetService([Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer])
}


<#
 # Main
 #>

Add-TeamFoundationClientAssemblies

Export-ModuleMember -Function '*-Workspace*', 'ConvertTo-*'
