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

function Compare-ItemGroup {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ReferenceItemGroup,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $DifferenceItemGroup
    )
    $ReferenceItemGroup.Keys + $DifferenceItemGroup.Keys | Sort-Object -Unique -PipelineVariable key | ForEach-Object -Process {
        if ($ReferenceItemGroup.ContainsKey($key) -and !$DifferenceItemGroup.ContainsKey($key)) {
            [PSCustomObject]@{ Key = $key ; ReferenceValue = $ReferenceItemGroup.$key ; SideIndicator = '<' ; DifferenceValue = $null } | Tee-Object -Variable difference
            Write-Verbose -Message $difference
        }
        elseif (!$ReferenceItemGroup.ContainsKey($key) -and $DifferenceItemGroup.ContainsKey($key)) {
            [PSCustomObject]@{ Key = $key ; ReferenceValue = $null ; SideIndicator = '>' ; DifferenceValue = $DifferenceItemGroup.$key } | Tee-Object -Variable difference
            Write-Verbose -Message $difference
        }
        else {
            $referenceItems, $differenceItems = @($ReferenceItemGroup.$key), @($DifferenceItemGroup.$key)
            for ($i = 0; $i -lt [math]::Max($referenceItems.Count, $differenceItems.Count); $i++) {
                if ($i -lt $referenceItems.Count -and $i -lt $differenceItems.Count) {
                    Compare-Item -ReferenceItem $referenceItems[$i] -DifferenceItem $differenceItems[$i] -Prefix ('{0}[{1}]' -f $key, $i)
                }
                elseif ($i -lt $referenceItems.Count) {
                    [PSCustomObject]@{ Key = "$key[$i]" ; ReferenceValue = $referenceItems[$i] ; SideIndicator = '<' ; DifferenceValue = $null } | Tee-Object -Variable difference
                    Write-Verbose -Message $difference
                }
                else {
                    [PSCustomObject]@{ Key = "$key[$i]" ; ReferenceValue = $null ; SideIndicator = '>' ; DifferenceValue = $differenceItems[$i] } | Tee-Object -Variable difference
                    Write-Verbose -Message $difference
                }
            }
        }
    }
}

function Expand-ItemGroup {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable[]]
        $ItemGroup
    )
    begin {
        $expandedItemGroup = @{ }
    }
    process {
        # warns about every duplicate ItemGroup and Item
        $ItemGroup | Test-ItemGroup -Unique -WarningAction:(Resolve-WarningAction $PSBoundParameters) | Out-Null
        $ItemGroup | ForEach-Object -Process { $_ } -PipelineVariable currentItemGroup | Select-Object -ExpandProperty Keys -PipelineVariable itemGroupName | ForEach-Object -Process {
            Write-Information -MessageData "Expanding ItemGroup '$itemGroupName'."
            if ($currentItemGroup.$itemGroupName -isnot [array]) { throw "ItemGroup '$itemGroupName' must be an array of Items." }
            if ($expandedItemGroup.ContainsKey($itemGroupName)) { Write-Warning -Message "ItemGroup '$itemGroupName' is being redefined." }
            # compute ItemGroup's default Item to be merged into every other Item
            $defaultItem = Resolve-DefaultItem -ItemGroup $currentItemGroup.$itemGroupName
            $expandedItemGroup.$itemGroupName = @(
                $currentItemGroup.$itemGroupName |
                    Where-Object -PipelineVariable validItem -FilterScript {
                        # select valid and non-default Items
                        (Test-Item -Item $_ -Valid -WarningAction SilentlyContinue) `
                            -and ((Test-Item -Item $_ -Property Name -Mode None -WarningAction SilentlyContinue) -or $_.Name -ne '*')
                    } |
                    ForEach-Object -PipelineVariable flattenedItem -Process {
                        if (Test-Item -Item $validItem -Property Path -WarningAction SilentlyContinue) {
                            # flatten Items whose Path is a list of paths
                            $validItem.Path |
                                Resolve-Path -ErrorAction Stop <# throw if Path cannot be resolved #> |
                                ForEach-Object -Process {
                                    # rewrite Name after Path and merges validItem's other properties back into the flattened Item
                                    Merge-HashTable -HashTable (
                                        @{ Name = Split-Path -Path $_.ProviderPath -Leaf ; Path = $_.ProviderPath },
                                        $validItem
                                    )
                                }
                        }
                        else {
                            $validItem
                        }
                    } |
                    ForEach-Object -Process { Merge-HashTable -HashTable $flattenedItem, $defaultItem } |
                    Where-Object -FilterScript { (Test-Item -Item $_ -Property Condition -Mode None) -or $_.Condition } |
                    ConvertTo-Item
            )
        }
    }
    end {
        $expandedItemGroup
    }
}

function Import-ItemGroup {
    # load item groups files
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )
    dynamicparam {
        # resolve path to itemgroup file when invoked through 'Get-Help -Name Import-ItemGroup -Path <some item group file.psd1>' as well
        if (-not(Test-Path -Path Variable:Path)) {
            # $Path = Get-PSCallStack | Select-Object -Last 1 -ExpandProperty Position | Select-Object -ExpandProperty Text |
            $Path = Get-PSCallStack |
                Select-Object -Last 1 -ExpandProperty InvocationInfo |
                Select-Object -ExpandProperty MyCommand |
                Where-Object -FilterScript { $_ -match '^Get\-Help\s+(:?\-Name\s+)?Import\-ItemGroup\s+\-Path\s+''?([^\s'']+)''?.*$' } |
                ForEach-Object -Process { $Matches[2] }
        }
        # $Path is mandatory but could be $null when invoked through 'Get-Help -Name Import-ItemGroup'
        if (![string]::IsNullOrEmpty($Path)) {
            $source = Get-Content -Raw -Path $Path
            $scriptBlock = [scriptblock]::Create($source)
            Convert-ScriptBlockParametersToDynamicParameters -ScriptBlock $scriptBlock
        }
    }
    begin {
        $location = Get-Location
    }
    process {
        $absolutePath = Resolve-Path -Path $Path
        Write-Information -MessageData "Importing ItemGroups from file '$absolutePath'."
        # make sure current folder for each item group definition file is its containing folder
        $itemGroupFolderPath = Split-Path -Path $absolutePath -Parent
        Write-Verbose -Message "Setting location to '$itemGroupFolderPath'."
        Set-Location -Path $itemGroupFolderPath

        $itemGroups = Invoke-ScriptBlock -ScriptBlock $scriptBlock -Parameters $PSBoundParameters
        ## TODO enrich hashtable with source file to provide better diagnostics info
        # pipe ItemGroups to support array of hashtables and not just a single hashtable
        $itemGroups | ForEach-Object -Process { if ($_ -isnot [hashtable]) { throw "File '$absolutePath' does not contain valid ItemGroup definitions." } }
        $itemGroups
    }
    end {
        Set-Location -Path $location
        Write-Verbose -Message "Restoring initial location to '$location'."
    }
}

function Test-ItemGroup {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable[]]
        $ItemGroup,

        [Parameter(Mandatory = $true)]
        [switch]
        $Unique
    )
    begin {
        $allItemGroups = @()
    }
    process {
        if ($Unique) { $allItemGroups += @( $ItemGroup | ForEach-Object -Process { $_ } ) }
    }
    end {

        function private:Trace-DuplicateItemGroup {
            [CmdletBinding()]
            [OutputType([Microsoft.PowerShell.Commands.GroupInfo])]
            param(
                [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
                [Microsoft.PowerShell.Commands.GroupInfo]
                $GroupInfo
            )
            process {
                Write-Warning -Message "ItemGroup '$($GroupInfo.Name)' has been defined multiple times."
                $GroupInfo
            }
        }

        if ($Unique) {
            $itemGroupsAreUnique = $allItemGroups |
                Select-Object -ExpandProperty Keys |
                Group-Object |
                Where-Object -FilterScript { $_.Count -gt 1 } |
                private:Trace-DuplicateItemGroup -WarningAction:(Resolve-WarningAction $PSBoundParameters) |
                Test-None
            $itemsAreUnique = $allItemGroups |
                ForEach-Object -Process { $_.Values } |
                Test-Item -Unique -WarningAction:(Resolve-WarningAction $PSBoundParameters)
            $itemGroupsAreUnique -and $itemsAreUnique
        }
    }
}

function Resolve-DefaultItem {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [hashtable[]]
        $ItemGroup
    )
    # compute default Item, which defines inheritable default properties, from all Items whose Name = '*'
    $ItemGroup |
        ForEach-Object -Process { $_ } |
        Where-Object -FilterScript { (Test-Item -Item $_ -Valid -WarningAction SilentlyContinue) -and (Test-Item -Item $_ -Property Name) -and $_.Name -eq '*' } |
        Merge-HashTable -Exclude 'Name' -Force
}

Import-Module ItemGroup\Item
Import-Module ItemGroup\Utils
