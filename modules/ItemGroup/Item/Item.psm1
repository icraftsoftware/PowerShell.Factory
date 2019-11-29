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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.u
# See the License for the specific language governing permissions and
# limitations under the License.

#endregion

Set-StrictMode -Version Latest

function Compare-Item {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [PSCustomObject]
        $ReferenceItem,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [PSCustomObject]
        $DifferenceItem,

        [Parameter(Mandatory = $false)]
        [string]
        $Prefix = ''
    )
    $referenceProperties = @( (?? { $ReferenceItem } { [PSCustomObject]@{ } }) | Get-Member -MemberType NoteProperty, ScriptProperty | Select-Object -ExpandProperty Name)
    $differenceProperties = @( (?? { $DifferenceItem } { [PSCustomObject]@{ } }) | Get-Member -MemberType NoteProperty, ScriptProperty | Select-Object -ExpandProperty Name)
    $referenceProperties + $differenceProperties | Select-Object -Unique -PipelineVariable key | ForEach-Object -Process {
        $propertyName = if ($Prefix) { "$Prefix.$key" } else { $key }
        if ($referenceProperties.Contains($key) -and !$differenceProperties.Contains($key)) {
            [PSCustomObject]@{Key = $propertyName ; ReferenceValue = $ReferenceItem.$key ; SideIndicator = '<' ; DifferenceValue = $null } | Tee-Object -Variable difference
            Write-Verbose -Message $difference
        }
        elseif (!$referenceProperties.Contains($key) -and $differenceProperties.Contains($key)) {
            [PSCustomObject]@{Key = $propertyName ; ReferenceValue = $null ; SideIndicator = '>' ; DifferenceValue = $DifferenceItem.$key } | Tee-Object -Variable difference
            Write-Verbose -Message $difference
        }
        else {
            $referenceValue, $differenceValue = $ReferenceItem.$key, $DifferenceItem.$key
            if ($referenceValue -ne $differenceValue) {
                [PSCustomObject]@{Key = $propertyName ; ReferenceValue = $referenceValue ; SideIndicator = '<>' ; DifferenceValue = $differenceValue } | Tee-Object -Variable difference
                Write-Verbose -Message $difference
            }
        }
    }
}

function ConvertTo-Item {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]
        $HashTable
    )
    process {
        @(
            $HashTable |
                Where-Object -FilterScript { $_.Count } <# filter out empty hashtables #> -PipelineVariable currentHashTable |
                ForEach-Object -Process {
                    $item = New-Object -TypeName PSCustomObject
                    $currentHashTable.Keys | ForEach-Object -Process {
                        if ($currentHashTable.$_ -is [ScriptBlock]) {
                            Add-Member -InputObject $item -MemberType ScriptProperty -Name $_ -Value $currentHashTable.$_
                        }
                        else {
                            Add-Member -InputObject $item -MemberType NoteProperty -Name $_ -Value $currentHashTable.$_
                        }
                    }
                    $item
                }
        )
    }
}

function Test-Item {
    [CmdletBinding()]
    [OutputType([boolean])]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [psobject[]]
        $Item,

        [Parameter(Mandatory = $true, ParameterSetName = 'membership')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Property,

        [Parameter(Mandatory = $false, ParameterSetName = 'membership')]
        [ValidateSet('All', 'Any', 'None')]
        [string]
        $Mode = 'All',

        [Parameter(Mandatory = $true, ParameterSetName = 'unicity')]
        [switch]
        $Unique,

        [Parameter(Mandatory = $true, ParameterSetName = 'validity')]
        [switch]
        $Valid,

        [Parameter(Mandatory = $true, ParameterSetName = 'well-formedness')]
        [switch]
        $WellFormed
    )

    begin {
        switch ($PSCmdlet.ParameterSetName) {
            'unicity' {
                $allValidItems = @()
            }
        }
    }
    process {

        function private:Get-ItemPropertyMembers {
            [CmdletBinding()]
            [OutputType([psobject[]])]
            param(
                [Parameter(Mandatory = $true)]
                [AllowNull()]
                [psobject]
                $Item
            )
            if ($Item -is [hashtable]) {
                @($Item.Keys)
            }
            elseif ($Item -is [PSCustomObject]) {
                @(Get-Member -InputObject $Item -MemberType  NoteProperty, ScriptProperty | Select-Object -ExpandProperty Name)
            }
            else {
                @()
            }
        }

        function private:Trace-InvalidItem {
            [CmdletBinding()]
            [OutputType([void])]
            param(
                [Parameter(Mandatory = $true)]
                [AllowNull()]
                [psobject]
                $Item
            )
            if (@('SilentlyContinue', 'Ignore') -notcontains (Resolve-WarningAction $PSBoundParameters)) {
                Write-Warning -Message 'The following Item is invalid because it is either ill-formed or misses either a valid Path or Name property:'
                # cast to PSCustomObject to ensure Format-List has an output format consistent among hashtable and PSCustomObject
                ([PSCustomObject]$Item) | Format-List | Out-String -Stream | Where-Object { -not([string]::IsNullOrWhitespace($_)) } | ForEach-Object -Process {
                    Write-Warning -Message $_.Trim()
                }
            }
        }

        switch ($PSCmdlet.ParameterSetName) {
            'membership' {
                $Item | ForEach-Object -Process { $_ } -PipelineVariable currentItem | ForEach-Object -Process {
                    $isMember = $false
                    if (Test-Item -Item $currentItem -WellFormed) {
                        $members = private:Get-ItemPropertyMembers -Item $currentItem
                        switch ($Mode) {
                            'All' {
                                $isMember = $Property | Where-Object -FilterScript { $members -notcontains $_ } | Test-None
                            }
                            'Any' {
                                $isMember = $Property | Where-Object -FilterScript { $members -contains $_ } | Test-Any
                            }
                            'None' {
                                $isMember = $Property | Where-Object -FilterScript { $members -contains $_ } | Test-None
                            }
                        }
                    }
                    $isMember
                }
            }
            'unicity' {
                $allValidItems += @(
                    $Item | ForEach-Object -Process { $_ } -PipelineVariable currentItem | Where-Object -FilterScript {
                        Test-Item -Item $currentItem -Valid -WarningAction:(Resolve-WarningAction $PSBoundParameters)
                    }
                )
            }
            'validity' {
                $Item | ForEach-Object -Process { $_ } -PipelineVariable currentItem | ForEach-Object -Process {
                    $isValid = $false
                    if (Test-Item -Item $currentItem -WellFormed) {
                        # Path property has the precedence over the Name property, but either one is required
                        if (Test-Item -Item $currentItem -Property Path) {
                            $isValid = $null -ne $currentItem.Path -and (Test-Path $currentItem.Path)
                        }
                        elseif (Test-Item -Item $currentItem -Property Name) {
                            $isValid = -not([string]::IsNullOrWhitespace($currentItem.Name))
                        }
                    }
                    if (-not $isValid) {
                        private:Trace-InvalidItem -Item $currentItem -WarningAction:(Resolve-WarningAction $PSBoundParameters)
                    }
                    $isValid
                }
            }
            'well-formedness' {
                $Item | ForEach-Object -Process { $_ } -PipelineVariable currentItem | ForEach-Object -Process {
                    private:Get-ItemPropertyMembers -Item $currentItem | Test-Any
                }
            }
        }
    }
    end {

        function private:Trace-DuplicateItem {
            [CmdletBinding()]
            [OutputType([Microsoft.PowerShell.Commands.GroupInfo])]
            param(
                [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
                [Microsoft.PowerShell.Commands.GroupInfo]
                $GroupInfo
            )
            process {
                if (@('SilentlyContinue', 'Ignore') -notcontains (Resolve-WarningAction $PSBoundParameters)) {
                    $GroupInfo.Group | ForEach-Object -Process {
                        Write-Warning -Message "The following Item '$($GroupInfo.Name)' has been defined multiple times:"
                        # cast to PSCustomObject to ensure Format-List has an output format consistent among hashtable and PSCustomObject
                        ([PSCustomObject]$_) | Format-List | Out-String -Stream | Where-Object { -not([string]::IsNullOrWhitespace($_)) } | ForEach-Object -Process {
                            Write-Warning -Message $_.Trim()
                        }
                    }
                }
                $GroupInfo
            }
        }

        switch ($PSCmdlet.ParameterSetName) {
            'unicity' {
                # Path property has the precedence over the Name property when grouping Items
                $allValidItems |
                    Group-Object -Property { if (Test-Item -Item $_ -Property Path) { $_.Path } else { $_.Name } } |
                    Where-Object -FilterScript { $_.Count -gt 1 } |
                    private:Trace-DuplicateItem -WarningAction:(Resolve-WarningAction $PSBoundParameters) |
                    Test-None
            }
        }
    }
}

Import-Module ItemGroup\Utils
