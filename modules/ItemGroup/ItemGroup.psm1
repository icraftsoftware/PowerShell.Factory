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

#region ItemGroup

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
         [PSCustomObject]@{Key = $key ; ReferenceValue = $ReferenceItemGroup.$key ; SideIndicator = '<' ; DifferenceValue = $null} | Tee-Object -Variable difference
         Write-Verbose -Message $difference
      }
      elseif (!$ReferenceItemGroup.ContainsKey($key) -and $DifferenceItemGroup.ContainsKey($key)) {
         [PSCustomObject]@{Key = $key ; ReferenceValue = $null ; SideIndicator = '>' ; DifferenceValue = $DifferenceItemGroup.$key} | Tee-Object -Variable difference
         Write-Verbose -Message $difference
      }
      else {
         $referenceItems, $differenceItems = @($ReferenceItemGroup.$key), @($DifferenceItemGroup.$key)
         for ($i = 0; $i -lt [math]::Max($referenceItems.Count, $differenceItems.Count); $i++) {
            if ($i -lt $referenceItems.Count -and $i -lt $differenceItems.Count) {
               Compare-Item -ReferenceItem $referenceItems[$i] -DifferenceItem $differenceItems[$i] -Prefix ('{0}[{1}]' -f $key, $i)
            }
            elseif ($i -lt $referenceItems.Count) {
               [PSCustomObject]@{Key = "$key[$i]" ; ReferenceValue = $referenceItems[$i] ; SideIndicator = '<' ; DifferenceValue = $null} | Tee-Object -Variable difference
               Write-Verbose -Message $difference
            }
            else {
               [PSCustomObject]@{Key = "$key[$i]" ; ReferenceValue = $null ; SideIndicator = '>' ; DifferenceValue = $differenceItems[$i]} | Tee-Object -Variable difference
               Write-Verbose -Message $difference
            }
         }
      }
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
         $Path = Get-PSCallStack | Select-Object -Last 1 -ExpandProperty InvocationInfo | Select-Object -ExpandProperty MyCommand |
            Where-Object -FilterScript {$_ -match '^Get\-Help\s+(:?\-Name\s+)?Import\-ItemGroup\s+\-Path\s+''?([^\s'']+)''?.*$' } |
            ForEach-Object -Process { Resolve-Path $Matches[2] | Select-Object -ExpandProperty Path }
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
      Write-Information -MessageData "Importing ItemGroups from file '$absolutePath'." -InformationAction Continue
      # make sure current folder for each item group definition file is its containing folder
      $itemGroupFolderPath = Split-Path -Path $absolutePath -Parent
      Write-Verbose -Message "Setting location to '$itemGroupFolderPath'."
      Set-Location -Path $itemGroupFolderPath

      $itemGroups = Invoke-ScriptBlock -ScriptBlock $scriptBlock -Parameters $PSBoundParameters
      ## TODO enrich hashtable with source file to provide better diagnostics info
      # pipe itemGroups to support array of hashtables and not just a single hashtable
      $itemGroups | ForEach-Object -Process { if ($_ -isnot [hashtable]) { throw "File '$absolutePath' does not contain valid ItemGroup definitions." } }
      $itemGroups
   }
   end {
      Set-Location -Path $location
      Write-Verbose -Message "Restoring initial location to '$location'."
   }
}

# function Merge-ItemGroup {
#    # merge item groups having same name
#    [CmdletBinding()]
#    param(
#       [Parameter(Position = 0, Mandatory = $true)]
#       [hashtable[]]
#       $ItemGroup
#    )
#    $result = @{}
#    foreach ($group in $ItemGroup) {
#       foreach ($key in $group.Keys) {
#          # TODO ensure value is an array
#          $result[$key] += $group[$key]
#       }
#    }
#    $result
#    # $bindings = $hash.ApplicationBindings.Where{ $_.Condition | Expand-Value }
#    # $bindings | ForEach-Object { @{ Name = ($_.Name | Expand-Value) ; Path = ($_.Path | Expand-Value) } } | Format-Table
# }

function Expand-ItemGroup {
   [CmdletBinding()]
   [OutputType([PSCustomObject[]])]
   param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [hashtable[]]
      $ItemGroup
   )
   begin {
      $result = @{}
   }
   process {
      $ItemGroup | Test-ItemGroup -Duplicate
      $ItemGroup | ForEach-Object -Process { $_ } -PipelineVariable currentItemGroup | Select-Object -ExpandProperty Keys -PipelineVariable itemGroupName | ForEach-Object -Process {
         Write-Information -MessageData "Expanding ItemGroup '$itemGroupName'." -InformationAction Continue
         if ($currentItemGroup.$itemGroupName -isnot [array]) { throw "'$itemGroupName' is expected to be an array." }
         # compute ItemGroup's default item to be merged into every other item
         $defaultItem = Resolve-DefaultItem -ItemGroup $currentItemGroup.$itemGroupName
         # iterates over valid non-default items to flatten vector ones, i.e. those whose item.Path is a list/array of items
         $items = @(
            $currentItemGroup.$itemGroupName `
               | Where-Object -FilterScript { Test-Item -Item $_ -IsValid } `
               | Where-Object -FilterScript { (Test-Item -Item $_ -Property Path) -and $_.Path -ne '*' } -PipelineVariable item `
               | Where-Object -FilterScript { -not(Test-Item -Item $_ -Property Condition) -or $_.Condition } `
               | ForEach-Object -Process { $item.Path | Resolve-Path -ErrorAction Stop <# will throw if Item is not found #> | Select-Object -ExpandProperty ProviderPath } -PipelineVariable path `
               | ForEach-Object -Process { Merge-HashTable -HashTable @{Path = $path}, $item, $defaultItem }
         )
         if ($result.ContainsKey($itemGroupName)) {
            Write-Warning -Message "Items of ItemGroup '$itemGroupName' have been redefined."
         }
         $result.$itemGroupName = @($items | ConvertTo-Item)
         $result.$itemGroupName | Test-Item -Duplicate
      }
   }
   end {
      $result
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
      $Duplicate
   )
   begin {
      $itemGroupCache = @()
   }
   process {
      if ($Duplicate) { $itemGroupCache += @( $ItemGroup | ForEach-Object -Process { $_ } ) }
   }
   end {
      if ($Duplicate) {
         $itemGroupCache | Select-Object -ExpandProperty Keys | Group-Object |
            Where-Object -FilterScript { $_.Count -gt 1 } |
            ForEach-Object -Process { Write-Warning -Message "ItemGroup '$($_.Name)' has been defined multiple times." }
         $itemGroupCache | ForEach-Object -Process { $_.Values } | Test-Item -Duplicate:$Duplicate
      }
   }
}

#endregion

#region Item

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
   $referenceProperties = @( (?? { $ReferenceItem } { [PSCustomObject]@{} }) | Get-Member -MemberType NoteProperty, ScriptProperty | Select-Object -ExpandProperty Name)
   $differenceProperties = @( (?? { $DifferenceItem } { [PSCustomObject]@{} }) | Get-Member -MemberType NoteProperty, ScriptProperty | Select-Object -ExpandProperty Name)
   $referenceProperties + $differenceProperties | Select-Object -Unique -PipelineVariable key | ForEach-Object -Process {
      $propertyName = if ($Prefix) { "$Prefix.$key" } else { $key }
      if ($referenceProperties.Contains($key) -and !$differenceProperties.Contains($key)) {
         [PSCustomObject]@{Key = $propertyName ; ReferenceValue = $ReferenceItem.$key ; SideIndicator = '<' ; DifferenceValue = $null} | Tee-Object -Variable difference
         Write-Verbose -Message $difference
      }
      elseif (!$referenceProperties.Contains($key) -and $differenceProperties.Contains($key)) {
         [PSCustomObject]@{Key = $propertyName ; ReferenceValue = $null ; SideIndicator = '>' ; DifferenceValue = $DifferenceItem.$key} | Tee-Object -Variable difference
         Write-Verbose -Message $difference
      }
      else {
         $referenceValue, $differenceValue = $ReferenceItem.$key, $DifferenceItem.$key
         if ($referenceValue -ne $differenceValue) {
            [PSCustomObject]@{Key = $propertyName ; ReferenceValue = $referenceValue ; SideIndicator = '<>' ; DifferenceValue = $differenceValue} | Tee-Object -Variable difference
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
         $HashTable | Where-Object -FilterScript { $_.Count } <# filter out empty hashtables #> | ForEach-Object -Process {
            $currentHashTable = $_
            $object = New-Object -TypeName PSCustomObject
            $currentHashTable.Keys | ForEach-Object -Process {
               if ($currentHashTable.$_ -is [ScriptBlock]) {
                  Add-Member -InputObject $object -MemberType ScriptProperty -Name $_ -Value $currentHashTable.$_
               }
               else {
                  Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $currentHashTable.$_
               }
            }
            $object
         }
      )
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
   # compute default item, which defines inheritable default properties, from all items whose Path = '*'
   $ItemGroup |
      ForEach-Object -Process { $_ } |
      Where-Object -FilterScript { (Test-Item -Item $_ -IsValid) -and $_.Path -eq '*' } |
      Merge-HashTable -Exclude 'Path' -Force
}

function Test-Item {
   [CmdletBinding()]
   [OutputType([void])]
   param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [AllowNull()]
      [AllowEmptyCollection()]
      [psobject[]]
      $Item,

      [Parameter(Mandatory = $true, ParameterSetName = 'member')]
      [ValidateNotNullOrEmpty()]
      [string]
      $Property,

      [Parameter(Mandatory = $true, ParameterSetName = 'duplicate')]
      [switch]
      $Duplicate,

      [Parameter(Mandatory = $true, ParameterSetName = 'valid')]
      [switch]
      $IsValid
   )
   begin {
      switch ($PSCmdlet.ParameterSetName) {
         'member' {}
         'duplicate' {
            $itemCache = @()
         }
         'valid' {
            $isItem = $false
         }
      }
   }
   process {
      switch ($PSCmdlet.ParameterSetName) {
         'member' {
            $Item | ForEach-Object -Process { $_ } -PipelineVariable currentItem | ForEach-Object -Process {
               if (-not(Test-Item -Item $currentItem -IsValid)) {
                  $false
               }
               elseif ($currentItem -is [hashtable]) {
                  $currentItem.Keys -contains $Property
               }
               elseif ($currentItem -is [PSCustomObject]) {
                  Get-Member -InputObject $currentItem -Name $Property -MemberType  NoteProperty, ScriptProperty | Test-Any
               }
            }
         }
         'duplicate' {
            $itemCache += @(
               $Item | ForEach-Object -Process { $_ } | Where-Object -FilterScript { Test-Item -Item $_ -IsValid }
            )
         }
         'valid' {
            $Item | ForEach-Object -Process { $_ } -PipelineVariable currentItem | ForEach-Object -Process {
               if (-not $isItem) {
                  if ($currentItem -eq $null) {
                     $isItem = $false
                  }
                  elseif ($currentItem -is [hashtable]) {
                     $isItem = $currentItem.Count -gt 0
                  }
                  elseif ($currentItem -is [PSCustomObject]) {
                     $isItem = $currentItem | Get-Member -MemberType NoteProperty, ScriptProperty | Test-Any
                  }
               }
            }
         }
      }
   }
   end {
      switch ($PSCmdlet.ParameterSetName) {
         'member' {}
         'duplicate' {
            # TODO rename param to Uniqueness and return true or false besides writing warnings
            $itemCache | Group-Object -Property { $_.Path } |
               Where-Object -FilterScript { $_.Count -gt 1 } |
               ForEach-Object -Process { Write-Warning -Message "Item '$($_.Name)' has been defined multiple times." }
         }
         'valid' {
            $isItem
         }
      }
   }
}

#endregion

<#
 # Main
 #>

Export-ModuleMember -Function Import-ItemGroup, Expand-ItemGroup
