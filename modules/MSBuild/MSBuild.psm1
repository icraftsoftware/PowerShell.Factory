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
    Removes the bin and obj subfolders from a Visual Studio project, as well as all the files produced by the BizTalk compiler.
.DESCRIPTION
    The obj subfolder will always be cleaned, while the bin subfolder will only be cleaned iff the Visual Studio project is not a website project (i.e. if there is no web.config file in the given folder).
    The command will always try to clear the *.btm.cs, *.btp.cs, and *.xsd.cs files that are produced by the BizTalk compiler.
.PARAMETER Path
    The path to the Visual Studio project to clean. It defaults to the current directory.
.PARAMETER Packages
    Whether to clean NuGet packages underneath the Path\packages folder if found. Notice that the Packages switch is not affected by the Recurse switch. You typically use this swith when the current folder is the solution folder and you want the NuGet packages found underneath .\Packages to be cleaned up.
.PARAMETER Recurse
    Whether to recursively clean the Visual studio project folders underneath Path. You typically use this swith when the current folder is the solution folder and you want to clean all the projects underneath.
.EXAMPLE
    Get-ChildItem -Directory | Clear-Project
.EXAMPLE
    Get-ChildItem -Directory | Clear-Project -Verbose
.EXAMPLE
    Get-ChildItem -Directory | Clear-Project -Verbose -WhatIf
.EXAMPLE
    Clear-Project -Recurse

    The -Recurse switch is shorthand for the following compound command: Get-ChildItem -Directory | Clear-Project.
.EXAMPLE
    Clear-Project .\BizTalk.Dsl, .\BizTalk.Dsl.Tests
.EXAMPLE
    (gi .\BizTalk.Dsl), (gi .\BizTalk.Dsl.Tests) | Clear-Project -WhatIf
.NOTES
    © 2019 be.stateless.
#>
function Clear-Project {
    [CmdletBinding(DefaultParametersetName = 'Single', SupportsShouldProcess = $true)]
    Param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelinebyPropertyName = $true)]
        [psobject[]]
        $Path,

        [switch]
        $Packages,

        [switch]
        $Recurse

        #TODO switch to also clean .user, .dotsettings.user, *.suo etc... files
    )

    # TODO test commands via Pester
    # https://www.simple-talk.com/sysadmin/powershell/practical-powershell-unit-testing-getting-started/
    # Clear-Project -Path .\src -Verbose -WhatIf
    # Clear-Project -Path .\src -Packages -Verbose -WhatIf
    # Clear-Project -Path .\src -Recurse -Verbose -WhatIf
    # Clear-Project -Path .\src -Recurse -Packages -Verbose -WhatIf
    # Clear-Project -Packages -Verbose -WhatIf
    # Clear-Project -Recurse -Verbose -WhatIf
    # Clear-Project -Recurse -Packages -Verbose -WhatIf
    # (gi .\BizTalk.Dsl), (gi .\BizTalk.Dsl.Tests) | Clear-Project -Verbose -WhatIf
    # (gi .\BizTalk.Dsl), (gi .\BizTalk.Dsl.Tests) | Clear-Project -Packages -Verbose -WhatIf
    # (gi .\BizTalk.Dsl), (gi .\BizTalk.Dsl.Tests) | Clear-Project -Recurse -Verbose -WhatIf
    # (gi .\BizTalk.Dsl), (gi .\BizTalk.Dsl.Tests) | Clear-Project -Recurse -Packages -Verbose -WhatIf
    # (gi .\src\BizTalk.Dsl), (gi .\src\BizTalk.Dsl.Tests) | Clear-Project -Verbose -WhatIf

    # begin { }
    process {
        if ($null -eq $Path) {
            $Path = Get-Item -Path .
        }
        else {
            $Path = Get-Item -Path $Path
        }
        if ($Recurse) {
            $projectPaths = Get-ChildItem -Path $Path -Directory
        }
        else {
            $projectPaths = $Path
        }
        foreach ($p in $projectPaths) {
            $p = Resolve-Path -Path $p.FullName -Relative
            Write-Verbose "Clearing $p..."
            if (-not(Test-Path -Path $p\web.config) -and (Test-Path -LiteralPath $p\bin)) {
                Remove-Item -LiteralPath $p\bin -Confirm:$false -Force -Recurse
            }
            if (Test-Path -LiteralPath $p\obj) {
                Remove-Item -LiteralPath $p\obj -Confirm:$false -Force -Recurse
            }
            Get-ChildItem -Path $p -Filter *.btm.cs -Recurse | Remove-Item -Confirm:$false
            Get-ChildItem -Path $p -Filter *.btp.cs -Recurse | Remove-Item -Confirm:$false
            Get-ChildItem -Path $p -Filter *.xsd.cs -Recurse | Remove-Item -Confirm:$false
        }
        if ($Packages) {
            $packagesPath = Join-Path -Path $Path .\packages
            if (Test-Path -Path $packagesPath) {
                $packagesPath = Resolve-Path -Path $packagesPath -Relative
                Write-Verbose "Cleaning NuGet packages under $packagesPath..."
                Get-ChildItem -Path $packagesPath -Directory | Remove-Item -Recurse -Force -Confirm:$false
            }
        }
    }
    #end { }
}

<#
.SYNOPSIS
    Probe an MSBuild project file and list either all of its supported targets or only the ones matching a given filter.
.DESCRIPTION
    Probe an MSBuild project file and list all the supported targets that can be called.

    This function does not work with Visual Studio solution files.
.PARAMETER Project
    Project file to probe.
.EXAMPLE
    Get-MSBuildTargets BizTalk.Factory.Deployment.btdfproj
.EXAMPLE
    Get-MSBuildTargets BizTalk.Factory.Deployment.btdfproj binding
    Get-MSBuildTargets -Project BizTalk.Factory.Deployment.btdfproj -Filter binding

    Both commands are equivalent and list the supported targets of the BizTalk.Factory.Deployment.btdfproj project file that matches the 'binding' string.
.LINK
    http://stackoverflow.com/questions/441614/how-to-query-msbuild-file-for-list-of-supported-targets
.NOTES
    © 2015 be.stateless.
#>
function Get-MSBuildTargets {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $Project,

        [Parameter(Position = 1, Mandatory = $false)]
        [string]
        $Filter = '.'
    )

    try {
        $msbuildProject = [Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection.LoadProject((Resolve-Path $Project))
        # suggest targerts using a stricter matching criterium first
        $msbuildProject.Targets.Keys | Where-Object { $_ -match "^$Filter" } | Sort-Object
        # suggest targerts using a looser matching criterium next
        $msbuildProject.Targets.Keys | Where-Object { $_ -match "^.+$Filter" } | Sort-Object
    }
    finally {
        [Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection.UnloadAllProjects()
    }
}

<#
.SYNOPSIS
    Invokes the required/matching version of MSBuild.exe to build a project or solution file.
.DESCRIPTION
    Builds an MSBuild project or solution file by invoking the right version, as specified in the project or solution file, of MSBuild.exe.
    The command is able to dynamically switch between different version of the MSBuild.exe tool without corrupting the environment variables and therefore without requiring PowerShell from being restarted.
.PARAMETER Project
    Project or solution file to build.
.PARAMETER UnboundArguments
    This parameter accumulates all the additional arguments and pass them along to MSBuild.
.EXAMPLE
    PS> Invoke-MSBuild BizTalk.Factory.sln

    Dynamically sets up, if needed, the Visual Studio environment necessary to build the BizTalk.Factory.sln solution file and builds the solution.
.COMPONENT
    This command relies on the Pscx Get-EnvironmentBlock, Pop-EnvironmentBlock, and Push-EnvironmentBlock functions.
.NOTES
    © 2015 be.stateless.
#>
function Invoke-MSBuild {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $Project,

        [Parameter(Position = 1, Mandatory = $false)]
        [string[]]
        $Targets = '',

        [Parameter(Mandatory = $false)]
        [string]
        $VisualStudioVersion = $null,

        [Parameter(Mandatory = $false)]
        [string]
        $ToolsVersion = $null,

        [Parameter(Mandatory = $false)]
        [int[]]
        $NoWarn,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Quiet', 'Minimal', 'Normal', 'Detailed', 'Diagnostic')]
        [string]
        $Verbosity,

        [Parameter(DontShow, ValueFromRemainingArguments = $true)]
        [object[]]
        $UnboundArguments = @()
    )
    # see Get-Help about_Functions_Advanced_Parameters
    # TODO http://poshoholic.com/2007/11/28/powershell-deep-dive-discovering-dynamic-parameters/
    DynamicParam {
        $parameterDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        # only for .*proj project files, i.e. not for .sln files
        if ($Project -match '.*\.\w*proj$') {
            Find-MSBuildProperties $Project | New-DynamicParameter | ForEach-Object { $parameterDictionary.Add($_.Name, $_) }
        }
        $parameterDictionary
    }

    begin {
        $properties = @(
            $parameterDictionary.Keys |
                Where-Object { $parameterDictionary.$_.IsSet } |
                    ForEach-Object { $parameterDictionary.$_ } |
                        Select-Object -Property Name, Value
        )
    }
    process {
        $arguments = @{ Project = $Project }
        if ($PSBoundParameters.ContainsKey('Targets')) {
            $arguments.Targets = $Targets
        }
        if ($PSBoundParameters.ContainsKey('VisualStudioVersion')) {
            $arguments.VisualStudioVersion = $VisualStudioVersion
        }
        if ($PSBoundParameters.ContainsKey('ToolsVersion')) {
            $arguments.ToolsVersion = $ToolsVersion
        }
        if ($PSBoundParameters.ContainsKey('NoWarn')) {
            $arguments.NoWarn = $NoWarn
        }
        if ($PSBoundParameters.ContainsKey('Verbosity')) {
            $arguments.Verbosity = $Verbosity
        }
        $arguments.UnboundArguments = $UnboundArguments + @($properties | ForEach-Object { @("-$($_.Name)", $_.Value) })
        # see Get-Help about_Splatting
        Invoke-MSBuildCore @arguments `
            -Verbose:($PSBoundParameters['Verbose'] -eq $true) `
            -WhatIf:($PSBoundParameters['WhatIf'] -eq $true)
    }
}

# To invoke this 'private' function from another module, see either of the following references
# http://powershell.com/cs/blogs/tips/archive/2009/09/18/accessing-hidden-module-members.aspx
# http://stackoverflow.com/questions/9382362/view-nested-private-function-definitions-in-powershell
# https://github.com/ligershark/psbuild/blob/master/src/psbuild.psm1
# https://github.com/deadlydog/Invoke-MsBuild
function Invoke-MSBuildCore {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Project,

        [Parameter(Mandatory = $false)]
        [string[]]
        $Targets = $null,

        [Parameter(Mandatory = $false)]
        [string]
        $VisualStudioVersion = '*',

        [Parameter(Mandatory = $false)]
        [string]
        $ToolsVersion = '*',

        [Parameter(Mandatory = $false)]
        [int[]]
        $NoWarn,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Quiet', 'Minimal', 'Normal', 'Detailed', 'Diagnostic')]
        [string]
        $Verbosity,

        [Parameter(Mandatory = $false)]
        [string]
        $Action = 'Invoking MSBuild.exe',

        [Parameter(Mandatory = $false)]
        [switch]
        $Elevated,

        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]
        $UnboundArguments
    )

    # dump bound and unbound parameters
    #$PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose "Bound Parameter: $_" }
    #$UnboundArguments.GetEnumerator() | ForEach-Object { Write-Verbose "Unbound Parameter: $_" }

    $rvsv = Resolve-VisualStudioVersion $Project $VisualStudioVersion $ToolsVersion
    $msbuildArgs = ''
    if ($PSBoundParameters.ContainsKey('Targets')) {
        $msbuildArgs += " /target:$(Join-String -Strings $Targets -Separator ';')"
    }
    if ($rvsv.Contains('ToolsVersion')) {
        $msbuildArgs += " /toolsversion:$($rvsv.ToolsVersion)"
    }
    if ($PSBoundParameters.ContainsKey('Verbosity')) {
        $msbuildArgs += " /verbosity:$($Verbosity.ToLower())"
    }
    if ($PSBoundParameters.ContainsKey('NoWarn')) {
        $msbuildArgs += " /property:NoWarn=`"$(Join-String -Strings $NoWarn -Separator ',')`""
    }

    # parse unbound arguments into $parsing structure
    $parsing = @{ Parameters = @() ; Verbatim = $null }
    $i = 0
    :parsing while ($UnboundArguments -and $i -lt $UnboundArguments.Length) {
        switch -regex ($UnboundArguments[$i]) {
            # parse name of brand new parameter
            '^-(\w+)$' {
                $parsing.Parameters += @{ Name = $matches[1] ; Values = @() }
                break
            }
            # parse verbatim command line tail and stop parsing
            '^--%$' {
                $parsing.Verbatim = $UnboundArguments[++$i]
                break parsing
            }
            # parse values of last parsed parameter
            default {
                $parsing.Parameters[$parsing.Parameters.Length - 1].Values += $UnboundArguments[$i]
                break
            }
        }
        $i++
    }

    # pass every $parsing.Parameters to MSBuild as /property:<name>=<value> ...
    $parsing.Parameters | Where-Object { $_.Values.Length -gt 0 } | ForEach-Object {
        $msbuildArgs += " /property:$($_.Name)=`"$(Join-String -Strings $_.Values -Separator ',')`""
    }
    # ... or as /property:<name>=true to MSBuild
    $parsing.Parameters | Where-Object { $_.Values.Length -eq 0 } | ForEach-Object {
        $msbuildArgs += " /property:$($_.Name)=$true"
    }
    # pass $parsing.Verbatim thru to MSBuild
    if ($null -ne $parsing.Verbatim) {
        $msbuildArgs += " $($parsing.Verbatim)"
    }

    if (-not($PSBoundParameters['Verbose'] -eq $true)) {
        if ($msbuildArgs) {
            Write-Host "$Action on $($rvsv.ProjectFile) with$msbuildArgs"
        }
        else {
            Write-Host "$Action on $($rvsv.ProjectFile)"
        }
    }
    # --% see STOP PARSING subtopic in Get-Help about_Parsing or STOP-PARSING SYMBOL subtopic in Get-Help about_Escape_Characters
    $command = "MSBuild.exe $($rvsv.ProjectFile) --%$msbuildArgs"

    if ($PsCmdlet.ShouldProcess($rvsv.ProjectFile, $Action)) {
        if (($PSBoundParameters['Elevated'] -eq $true)) {
            Assert-Elevated
        }
        if ($rvsv.Contains('VisualStudioVersion')) {
            Switch-VisualStudioEnvironment $rvsv.VisualStudioVersion
        }
        Assert-VisualStudioEnvironment $VisualStudioVersion
        Write-Verbose $command
        $scriptBlock = [scriptblock]::Create($command)
        Invoke-Command -ScriptBlock $scriptBlock
    }
    else {
        Write-Verbose $command
    }
}

<#
.SYNOPSIS
    Test whether the project files, *.*proj, in a given folder path, reference non-system assemblies from outside of the NuGet packages subfolder.
.DESCRIPTION
    This command can be used to ensure than any referenced assembly in a project is not coming from the GAC, which Visual Studio tends to do if it cannot find it where the HintPath points to or if the HintPath is simply missing. Thusly ensuring that a project can be built by simply resotiring the NuGet packages and without deploying anything else in the GAC or elsewhere. The Detailed switch will enumerate any offending references, and HintPaths if present, in a particular project file.
.PARAMETER Path
    The path to the Visual Studio project(s).
.EXAMPLE
    Get-ChildItem -Directory | Test-HintPath
.EXAMPLE
    Test-HintPath -Recurse

    The -Recurse switch is shorthand for the following compound command: Get-ChildItem -Directory | Test-HintPath.
.EXAMPLE
    Test-HintPath .\BizTalk.Dsl, .\BizTalk.Dsl.Tests
.EXAMPLE
    Test-HintPath .\BizTalk.Dsl, .\BizTalk.Dsl.Tests -Detailed
.EXAMPLE
    (gi .\BizTalk.Dsl), (gi .\BizTalk.Dsl.Tests) | Test-HintPath -Verbose
.NOTES
    © 2019 be.stateless.
#>
function Test-HintPath {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelinebyPropertyName = $true)]
        [psobject[]]
        $Path,

        [switch]
        $Detailed,

        [switch]
        $Recurse
    )

    process {
        if ($null -eq $Path) {
            $Path = Get-Item -Path .
        }
        else {
            $Path = Get-Item -Path $Path
        }
        if ($Recurse) {
            $projectPaths = Get-ChildItem -Path $Path -Directory
        }
        else {
            $projectPaths = $Path
        }
        foreach ($p in $projectPaths) {
            $p = Resolve-Path -Path $p.FullName -Relative
            Write-Verbose "Checking $p..."
            Get-ChildItem -Path $p -Filter *.*proj -PipelineVariable projectFile | ForEach-Object {
                $xml = [xml] (Get-Content -Path $projectFile.FullName -Raw)
                $nsm = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList ($xml.NameTable)
                $nsm.AddNamespace('ns', $xml.DocumentElement.xmlns)
                $noHintReferences = $xml.SelectNodes('//ns:Reference[not(ns:HintPath)]', $nsm) |
                    Where-Object { $_.Include -notmatch '^System|^Microsoft\.Csharp' }
                $badHintReferences = $xml.SelectNodes('//ns:Reference[ns:HintPath]', $nsm) |
                    Where-Object { $_.Include -notmatch '^System|^Microsoft\.Csharp' } |
                        Where-Object { $_.HintPath -notmatch '\.\.\\packages\\' }
                if (($noHintReferences | Test-Any) -or ($badHintReferences | Test-Any)) {
                    Write-Output $projectFile.Name
                    if ($Detailed) {
                        if ($noHintReferences | Test-Any) {
                            Write-Output 'References without hint path'
                            $noHintReferences | ForEach-Object {
                                Write-Output "  $($_.Include)"
                            }
                        }
                        if ($badHintReferences | Test-Any) {
                            Write-Output 'References with suspicious hint path'
                            $badHintReferences | ForEach-Object {
                                Write-Output $_.Include
                                Write-Output "    $($_.HintPath)"
                            }
                        }
                        Write-Output ''
                    }
                }
            }
        }
    }
}

#region Private Probing and Resolution Helper Functions

function Convert-ToolsVersionToVisualStudioVersion([string]$version) {
    switch -Exact ($version) {
        '2.0' { '2005' }
        '3.0' { '2008' }
        '3.5' { '2008' }
        '4.0' { '2010' }
        '4.5' { '2012' }
        '12.0' { '2013' }
        default { throw "Tools Version $version is not supported and cannot be used to dertermine the version of Visual Studio to use." }
    }
}

function Find-MSBuildProperties {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $Project,

        [Parameter(Position = 1)]
        [string[]]
        $Exclude = @()
    )

    try {
        $msbuildProject = [Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection.LoadProject((Resolve-Path $Project))
        $msbuildProject.ConditionedProperties.Keys | Where-Object { $Exclude -notcontains $_ } | Sort-Object
    }
    finally {
        [Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection.UnloadAllProjects()
    }
}

function Find-ProjectFile([string]$pattern, [bool]$includeSolutionFiles = $false) {
    if ($pattern) {
        $pattern = $pattern.Trim()
        $path = Split-Path $pattern -Parent
        if ($path.Length -lt 1) { $path = '.' }
        $file = Split-Path $pattern -Leaf
    }
    else {
        $path = '.'
        $file = $null
    }
    $includeFilter = @("$file*.*proj")
    if ($includeSolutionFiles) {
        $includeFilter = @("$file*.sln") + $includeFilter
    }
    Get-ChildItem -Path "$path\*" -Include $includeFilter -Name | ForEach-Object { "$path\$_" }
}

function Find-ToolStudioVersions([string]$pattern) {
    # https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-toolset-toolsversion?view=vs-2019
    # https://docs.microsoft.com/en-us/dotnet/api/microsoft.build.utilities.toollocationhelper?view=netframework-4.8
    # Add-Type -AssemblyName Microsoft.Build.Utilities.v4.0
    # [Microsoft.Build.Utilities.ToolLocationHelper]::GetTargetPlatformSdks()
    # [Microsoft.Build.Utilities.ToolLocationHelper]::GetSupportedTargetFrameworks()

    # https://docs.microsoft.com/en-us/visualstudio/msbuild/updating-an-existing-application?view=vs-2019#use-microsoftbuildlocator
    # https://github.com/Microsoft/msbuild/issues/2427
    # https://github.com/Microsoft/msbuild/blob/master/src/MSBuild/app.config#L72-L111
    # https://dotnet.myget.org/feed/msbuild/package/nuget/Microsoft.Build.MSBuildLocator
    # https://github.com/Microsoft/MSBuildLocator/
    Get-ChildItem HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions -Name |
        Where-Object { $_ -match '\d+\.\d+' } |
            Sort-Object { [float]$_ }
}

function Resolve-ProjectFile([string]$project) {
    if ($project) { $project = $project.Trim() }
    if (-not(Test-Path .\$project)) {
        throw "$project MSBuild project file not found!"
    }
    @{ ProjectFile = (Resolve-Path $project -Relative) }
}

function Resolve-VisualStudioVersion([string]$project, [string]$visualStudioVersion, [string]$toolsVersion) {
    $rvsv = Resolve-ProjectFile $project

    # determine Visual Studio Version
    if ($visualStudioVersion -and $visualStudioVersion -ne '*') {
        # get it from $visualStudioVersion argument
        $rvsv.Add('VisualStudioVersion', $visualStudioVersion)
    }
    # first try probing $project file as if it were a Visual Studio .sln file
    elseif ($project -match '.sln$') {
        $headers = Get-Content -Path $project -TotalCount 5
        if ($headers | Where-Object { $_ -match '^# Visual Studio (?<Version>\d\d\d\d)\s*$' }) {
            Write-Verbose "Solution file contains a match for Version: $($Matches.Version)"
            $version = $Matches.Version
        }
        elseif ($headers | Where-Object { $_ -match '^VisualStudioVersion = (?<VersionNumber>\d+\.\d+)[\d.]+\s*$' }) {
            Write-Verbose "Solution file contains a match for VersionNumber: $($Matches.VersionNumber)"
            $version = Convert-VisualStudioVersionNumber $Matches.VersionNumber
        }
        elseif ($headers | Where-Object { $_ -match '^MinimumVisualStudioVersion = (?<MinimumVersionNumber>\d+\.\d+)[\d.]+\s*$' }) {
            Write-Verbose "Solution file contains a match for MinimumVersionNumber: $($Matches.MinimumVersionNumber)"
            $version = Convert-VisualStudioVersionNumber $Matches.MinimumVersionNumber
        }
        elseif ($headers | Where-Object { $_ -match '^Microsoft Visual Studio Solution File, Format Version (?<FormatVersion>\d\d\.\d\d)\s*$' }) {
            Write-Verbose "Solution file contains a match for FormatVersion: $($Matches.FormatVersion)"
            $version = Convert-VisualStudioSolutionFileFormatVersion $Matches.FormatVersion
        }
        if ($null -ne $version) {
            $visualStudioVersion = & ${Find-VisualStudioVersions-Delegate} | Where-Object { $_ -ge $version } | Select-Object -First 1
            if ($null -ne $visualStudioVersion) {
                $rvsv.Add('VisualStudioVersion', $visualStudioVersion)
            }
        }
    }
    else {
        # next try probing $project file as if it were an MSBuild .*proj file
        # https://natemcmaster.com/blog/2017/03/09/vs2015-to-vs2017-upgrade/
        $matchInfo = Select-String -Pattern 'Project\s+(.*\s+)?ToolsVersion\s*\=\s*[''"](?<Version>\d+\.\d)[''"]' -Path $project
        if ($null -ne $matchInfo) {
            $matches = $matchInfo.Matches
            if ($matches -ne $null -and $matches.Success) {
                $probedVersion = $matches[0].Groups['Version'].Value
                $visualStudioVersion = Convert-ToolsVersionToVisualStudioVersion ([string] $probedVersion)
                $visualStudioVersion = & ${Find-VisualStudioVersions-Delegate} | Where-Object { $_ -ge $visualStudioVersion } | Select-Object -First 1
                $rvsv.Add('VisualStudioVersion', $visualStudioVersion)
            }
        }
    }

    # determine MSBuild's ToolsVersion; only relevant if it has been explicitly given, will be determined by MSBuild otherwise
    if ($toolsVersion -and $toolsVersion -ne '*') {
        # get it from $toolsVersion argument
        $rvsv.Add('ToolsVersion', $toolsVersion)
    }

    $rvsv
}

#endregion

#region Dynamic Parameters

function New-DynamicParameter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]
        $Name
    )
    process {
        $attributes = New-Object -Type System.Management.Automation.ParameterAttribute
        $attributes.ParameterSetName = '__AllParameterSets'
        $attributes.Mandatory = $false
        $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($attributes)
        New-Object -Type System.Management.Automation.RuntimeDefinedParameter($Name, [string], $attributeCollection)
    }
}

#endregion Dynamic Parameters

#region TabExpansion Overrides

function Register-TabExpansions {
    $global:options['CustomArgumentCompleters']['Project'] = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
        if ($commandName -eq 'Invoke-MSBuild') {
            Find-ProjectFile $wordToComplete $true | ForEach-Object {
                New-Object System.Management.Automation.CompletionResult $_, $_, 'ParameterValue', $_
            }
        }
        elseif ($commandName -eq 'Get-MSBuildTargets') {
            Find-ProjectFile $wordToComplete | ForEach-Object {
                New-Object System.Management.Automation.CompletionResult $_, $_, 'ParameterValue', $_
            }
        }
    }

    $global:options['CustomArgumentCompleters']['Targets'] = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
        if ($commandName -eq 'Invoke-MSBuild') {
            Get-MSBuildTargets $fakeBoundParameter.Project $wordToComplete | ForEach-Object {
                New-Object System.Management.Automation.CompletionResult $_, $_, 'ParameterValue', $_
            }
        }
    }

    $global:options['CustomArgumentCompleters']['ToolsVersion'] = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
        if ($commandName -eq 'Invoke-MSBuild') {
            Find-ToolStudioVersions | ForEach-Object {
                New-Object System.Management.Automation.CompletionResult $_, $_, 'ParameterValue', $_
            }
        }
    }

    $global:options['CustomArgumentCompleters']['VisualStudioVersion'] = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
        if ($commandName -eq 'Invoke-MSBuild') {
            Find-VisualStudioVersions $wordToComplete | ForEach-Object {
                New-Object System.Management.Automation.CompletionResult $_, $_, 'ParameterValue', $_
            }
        }
    }
}

function Unregister-TabExpansions {
    $global:options['CustomArgumentCompleters'].Remove('Project')
    $global:options['CustomArgumentCompleters'].Remove('Targets')
    $global:options['CustomArgumentCompleters'].Remove('ToolsVersion')
    $global:options['CustomArgumentCompleters'].Remove('VisualStudioVersion')
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

# friend function delegates
${Find-VisualStudioVersions-Delegate} = (& (Get-Module VSE) { (Get-Item function:Find-VisualStudioVersions) })

New-Alias -Name build -Value Invoke-MSBuild

Export-ModuleMember -Alias * -Function *
# Export-ModuleMember -Alias * -Function 'Clear-Project', 'Get-MSBuildTargets', 'Invoke-MSBuild', 'Test-HintPath'