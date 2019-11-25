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
    Ensures that an EnvironmentBlock has been setup to operate the tools accompanying a given version of Visual Studio.
.DESCRIPTION
    This command will throw if no EnvironmentBlock has been setup to operate the tools accompanying a given version of Visual Studio and will silently complete otherwise.
.EXAMPLE
    PS> Assert-VisualStudioEnvironment
.EXAMPLE
    PS> Assert-VisualStudioEnvironment 2010

    Asserts that the environment has been specifically setup for Visual Studio 2010.
.EXAMPLE
    PS> Assert-VisualStudioEnvironment *

    Asserts that the environment has been setup for some version of Visual Studio.
.EXAMPLE
    PS> Assert-VisualStudioEnvironment -Verbose
    With the -Verbose switch, this command will confirm this process is 32 bit.
.NOTES
    © 2012 be.stateless.
#>
function Assert-VisualStudioEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]
        $Version = '*'
    )

    if (-not(Test-VisualStudioEnvironment $Version)) {
        if ($Version -eq '*') {
            throw 'Environment has not been setup for any specific version of Visual Studio! Use the Switch-VisualStudioEnvironment command to setup one.'
        }
        throw "Environment has not been setup for Visual Studio $Version!"
    }
    $currentEnvironment = Get-VisualStudioEnvironment | Select-Object -First 1
    Write-Verbose "Environment has already been setup for Visual Studio $($currentEnvironment.Version)."
}

<#
.SYNOPSIS
    Clears the environment that has been set up for a version of Visual Studio and all EnvironmentBlocks that have been pushed afterwards.
.DESCRIPTION
    Unless specified otherwise, this command will clear the latest and topmost environment that has been set up for a version of Visual Studio and all the other EnvironmentBlocks, i.e. Pscx.EnvironmentBlock.EnvironmentFrame, that have been pushed afterwards.
.PARAMETER Environment
    The anonymous object whose EnvironmentBlock field references the Pscx.EnvironmentBlock.EnvironmentFrame up to which to clear.
.EXAMPLE
    PS> Clear-VisualStudioEnvironment

    Clears all the EnvironmentBlocks that have been set up after and up to the latest Pscx.EnvironmentBlock.EnvironmentFrame that has been setup for a given version of Visual Studio.
.EXAMPLE
    PS> Clear-VisualStudioEnvironment -WhatIf

    Describes all the EnvironmentBlocks that have been set up and would be cleared.
.EXAMPLE
    PS> Get-VisualStudioEnvironment | Select-Object -Last 1 | Clear-VisualStudioEnvironment

    Clears all the EnvironmentBlocks that have been set up after and up to the first Pscx.EnvironmentBlock.EnvironmentFrame that has been setup for a given version of Visual Studio.
.EXAMPLE
    PS> Clear-VisualStudioEnvironment (Get-VisualStudioEnvironment)[3]

    Clears all the EnvironmentBlocks that have been set up after and up to the given Pscx.EnvironmentBlock.EnvironmentFrame that has been setup for a given version of Visual Studio.
.COMPONENT
    This command relies on the Pscx Get-EnvironmentBlock, Pop-EnvironmentBlock, and Push-EnvironmentBlock functions.
.NOTES
    © 2013 be.stateless.
#>
function Clear-VisualStudioEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [object]
        $Environment = $(Get-VisualStudioEnvironment | Select-Object -First 1)
    )
    if ($null -ne $Environment) {
        # fetch Visual Studio's EnvironmentBlock and all EnvironmentBlocks pushed afterwards
        $deprecatedEnvironmentBlocks = Get-EnvironmentBlock | Where-Object Timestamp -ge $Environment.EnvironmentBlock.Timestamp

        Write-Verbose "Clearing former Visual Studio $($Environment.Version) environment..."
        # pop Visual Studio's EnvironmentBlock and all EnvironmentBlocks pushed afterwards
        $deprecatedEnvironmentBlocks | ForEach-Object {
            if ($PsCmdlet.ShouldProcess("Environment variables", "Clearing EnvironmentBlock $($_.Description)")) {
                Pop-EnvironmentBlock
            }
        }
    }
    else {
        Write-Verbose "There is no former Visual Studio environment to clear."
    }
}

<#
.SYNOPSIS
    Returns an anonymous object describing the EnvironmentBlock that has been set up to operate the tools accompanying a given version of Visual Studio.
.DESCRIPTION
    This command will returns either $null or an anonymous object whose EnvironmentBlock field references the topmost Pscx.EnvironmentBlock.EnvironmentFrame that has been set up, and whose Version field denotes the version of Visual Studio for which the environment has been set up.
.EXAMPLE
    PS> Get-VisualStudioEnvironment

    Returns the topmost EnvironmentBlock descriptor that has been set up for a given version of Visual Studio.
.EXAMPLE
    PS> Get-VisualStudioEnvironment | Select-Object -First 1

    Returns the latest and topmost EnvironmentBlock descriptor that has been set up for a given version of Visual Studio.
.EXAMPLE
    PS> Get-VisualStudioEnvironment | Select-Object -Last 1

    Returns the earliest and bottommost EnvironmentBlock descriptor that has been set up for a given version of Visual Studio.
.COMPONENT
    This command relies on the Pscx Get-EnvironmentBlock function.
.NOTES
    © 2013 be.stateless.
#>
function Get-VisualStudioEnvironment {
    [CmdletBinding()]
    param()
    $currentEnvironment = Get-EnvironmentBlock | Where-Object -Property Description -Match 'VisualStudioVersion=\d{4}'
    if ($null -ne $currentEnvironment) {
        $currentEnvironment | ForEach-Object {
            $matches = ($_.Description | Select-String -Pattern 'VisualStudioVersion=(?<Version>\d{4})').Matches
            @{ EnvironmentBlock = $_ ; Version = $matches[0].Groups['Version'].Value }
        }
    }
}

<#
.SYNOPSIS
    Sets up the enviroment necessary to operate the tools accompanying a given version of Visual Studio.
.DESCRIPTION
    Sets up the enviroment necessary to operate the tools accompanying a given version of Visual Studio. It moreover clears any environment that had previously been setup for another version of Visual Studio.
.PARAMETER Version
    The version of Visual Studio for which to setup the environment.
.EXAMPLE
    PS> Switch-VisualStudioEnvironment 2008

    Sets up the enviroment necessary to operate Visual Studio 2008 and its accompanying tools.
.EXAMPLE
    PS> Switch-VisualStudioEnvironment 2010

    Sets up the enviroment necessary to operate Visual Studio 2010 and its accompanying tools.
.EXAMPLE
    PS> Switch-VisualStudioEnvironment 2010 -WhatIf

    Describes the clearing and setup steps that would be necessary to setup the enviroment necessary to operate Visual Studio 2010 and its accompanying tools.
.COMPONENT
    This command relies on the Pscx Get-EnvironmentBlock, Pop-EnvironmentBlock, and Push-EnvironmentBlock functions.
.NOTES
    © 2019 be.stateless.
#>
function Switch-VisualStudioEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $Version

        # TODO -Latest Switch
    )
    $currentEnvironment = Get-VisualStudioEnvironment | Select-Object -First 1
    if ($null -ne $currentEnvironment -and $currentEnvironment.Version -ne $Version) {
        Write-Verbose "Clearing environment previously setup for Visual Studio $($currentEnvironment.Version)..."
        Get-VisualStudioEnvironment | Select-Object -Last 1 | Clear-VisualStudioEnvironment
    }
    if ($null -eq $currentEnvironment -or $currentEnvironment.Version -ne $Version) {
        Write-Verbose "Setting up environment for Visual Studio $Version..."

        if ($Version -eq '2013') {
            $path = Get-Item -Path Env:\VS120COMNTOOLS
            $batchPath = [System.IO.Path]::GetFullPath("$($path.Value)..\..\VC\vcvarsall.bat")
        }
        else {
            $path = Get-VSSetupInstance |
                Where-Object -FilterScript { $_.CatalogInfo['ProductLineVersion'] -eq $Version } |
                Select-Object -ExpandProperty InstallationPath
            $batchPath = Join-Path -Path $path 'Common7\Tools\vsdevcmd.bat'
        }
        if ($PsCmdlet.ShouldProcess("Environment variables", "Pushing EnvironmentBlock for Visual Studio $Version")) {
            if (Test-Path $batchPath) {
                Push-EnvironmentBlock -Description "VisualStudioVersion=$Version"
                Invoke-BatchFile $batchPath
            }
            else {
                throw "Version $Version of Visual Studio is not supported!"
            }
        }
    }
    else {
        Write-Verbose "Environment has already been setup for Visual Studio $Version."
    }
}

<#
.SYNOPSIS
    Returns whether an EnvironmentBlock has been setup to operate the tools accompanying a given version of Visual Studio.
.DESCRIPTION
    This command will return $true if an EnvironmentBlock has been setup to operate the tools accompanying a given version of Visual Studio, or $false otherwise.
.EXAMPLE
    PS> Test-VisualStudioEnvironment
.EXAMPLE
    PS> Test-VisualStudioEnvironment 2010

    Tests whether the environment has been setup specifically for Visual Studio 2010.
.EXAMPLE
    PS> Test-VisualStudioEnvironment *

    Tests whether the environment has been setup for some version of Visual Studio.
.NOTES
    © 2012 be.stateless.
#>
function Test-VisualStudioEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]
        $Version = '*'
    )

    $currentEnvironment = Get-VisualStudioEnvironment | Select-Object -First 1
    [bool]($null -ne $currentEnvironment -and ($Version -eq '*' -or $currentEnvironment.Version -eq $Version))
}

<#
.SYNOPSIS
    Returns the numerically sorted version numbers of all the locally installed Visual Studio versions.
.DESCRIPTION
    This command will returns the version numbers of all the locally installed Visual Studio versions sorted either ascendingly or descendingly. Notice that only those versions for which the common tools are deployed and configured will be returned.
.EXAMPLE
    PS> Get-VisualStudioVersionNumbers

    Returns the version numbers of the installed Visual Studio in ascending numerical order.
.EXAMPLE
    PS> Get-VisualStudioVersionNumbers -Descending

    Returns the version numbers of the installed Visual Studio in descending numerical order.
.NOTES
    © 2019 be.stateless.
#>
function Get-VisualStudioVersionNumbers {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [switch]
        $Descending
    )
    # http://social.technet.microsoft.com/Forums/windowsserver/en-US/9620af9a-0323-460c-b3e8-68a73715f99d/module-scoped-variable
    # cache to avoid looking through registry again and again
    $installedVisualStudioVersionNumbers = $MyInvocation.MyCommand.Module.PrivateData['InstalledVisualStudioVersionNumbers']
    if ($null -eq $installedVisualStudioVersionNumbers) {
        # HKLM:\SOFTWARE\Microsoft\VSCommon instead of HKLM:\SOFTWARE\Microsoft\VisualStudio to skip shell-only installations of Visual Studio, e.g. SQL Server Management Studio
        $path = ?: { Test-64bitArchitecture } { 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VSCommon' } { 'HKLM:\SOFTWARE\Microsoft\VSCommon' }
        if (Test-Path $path) {
            $installedVisualStudioVersionNumbers = Get-ChildItem -Path $path |
                Select-Object -ExpandProperty PSChildName |
                Where-Object { $_ -match '^\d+\.\d+$' }
        }
        $installedVisualStudioVersionNumbers = @($installedVisualStudioVersionNumbers)
        $MyInvocation.MyCommand.Module.PrivateData['InstalledVisualStudioVersionNumbers'] = $installedVisualStudioVersionNumbers
    }
    $installedVisualStudioVersionNumbers | Sort-Object { [float]$_ } -Descending:$Descending
}

#region Private Probing and Resolution Helper Functions

function Convert-VisualStudioSolutionFileFormatVersion([string]$formatVersion) {
    switch -Exact ($formatVersion) {
        '10.00' { '2008' }
        '11.00' { '2010' }
        '12.00' { '2012' }
        default { throw "Visual Studio Solution File Format Version $formatVersion is not supported." }
    }
}

function Convert-VisualStudioVersionNumber([string]$versionNumber) {
    switch -Exact ($versionNumber) {
        '9.0' { '2008' }
        '10.0' { '2010' }
        '11.0' { '2012' }
        '12.0' { '2013' }
        default {
            $version = Get-VSSetupInstance |
                Select-VSSetupInstance -Latest -Version ("[{0},{1:00.0})" -f $versionNumber, [Math]::Floor([double]$versionNumber + 1)) |
                ForEach-Object -Process { $_.CatalogInfo['ProductLineVersion'] }
            if ($null -eq $version) { throw "Visual Studio Version Number $versionNumber is not supported." }
            $version
        }
    }
}

function Find-VisualStudioVersions([string]$pattern) {
    Get-VisualStudioVersionNumbers |
        Sort-Object { [double]$_ } |
        ForEach-Object { Convert-VisualStudioVersionNumber $_ } |
        Where-Object { if ($null -eq $pattern) { $true } else { $_ -match $pattern } }
}

#endregion Private Probing and Resolution Helper Functions

#region TabExpansion Overrides

function Register-TabExpansions {
    $global:options['CustomArgumentCompleters']['Version'] = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
        if ($commandName -eq 'Switch-VisualStudioEnvironment') {
            Find-VisualStudioVersions $wordToComplete | ForEach-Object {
                New-Object System.Management.Automation.CompletionResult $_, $_, 'ParameterValue', $_
            }
        }
        elseif ($commandName -match '(Assert|Test)\-VisualStudioEnvironment') {
            @('*') + @(Find-VisualStudioVersions $wordToComplete) | ForEach-Object {
                New-Object System.Management.Automation.CompletionResult $_, $_, 'ParameterValue', $_
            }
        }
    }
}

function Unregister-TabExpansions {
    $global:options['CustomArgumentCompleters'].Remove('Version')
}

#endregion TabExpansion Overrides

<#
 # Main
 #>

Register-TabExpansions
# register clean up handler should the module be removed from the session
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Unregister-TabExpansions
}
