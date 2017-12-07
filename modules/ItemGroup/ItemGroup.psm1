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

#region ItemGroup

function Get-AssemblyName {
   [CmdletBinding()]
   [OutputType([System.Reflection.AssemblyName[]])]
   param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [psobject[]]
      $Path
   )
   process {
      $Path | ForEach-Object -Process { $_ } | ForEach-Object -Process { [System.Reflection.AssemblyName]::GetAssemblyName($_) }
   }
}

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
      } elseif (!$ReferenceItemGroup.ContainsKey($key) -and $DifferenceItemGroup.ContainsKey($key)) {
         [PSCustomObject]@{Key = $key ; ReferenceValue = $null ; SideIndicator = '>' ; DifferenceValue = $DifferenceItemGroup.$key} | Tee-Object -Variable difference
         Write-Verbose -Message $difference
      } else {
         $referenceItems, $differenceItems = @($ReferenceItemGroup.$key), @($DifferenceItemGroup.$key)
         for ($i = 0; $i -lt [math]::Max($referenceItems.Count, $differenceItems.Count); $i++) {
            if ($i -lt $referenceItems.Count -and $i -lt $differenceItems.Count) {
               Compare-Item -ReferenceItem $referenceItems[$i] -DifferenceItem $differenceItems[$i] -Prefix ('{0}[{1}]' -f $key, $i)
            } elseif ($i -lt $referenceItems.Count) {
               [PSCustomObject]@{Key = "$key[$i]" ; ReferenceValue = $referenceItems[$i] ; SideIndicator = '<' ; DifferenceValue = $null} | Tee-Object -Variable difference
               Write-Verbose -Message $difference
            } else {
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
      [Parameter(Position = 0, Mandatory = $true)]#, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [psobject[]]
      $Paths,

      [Parameter(DontShow, ValueFromRemainingArguments = $true)]
      [psobject[]]
      $UnboundArguments
   )

   # TODO dynamic arguments and support completion of the ones defined in the param sectionof the file located at $path

   # https://www.google.com/search?newwindow=1&safe=active&pws=0&gl=us&q=powershell+use+unbound+parameters+to+call+another+command&oq=powershell+use+unbound+parameters+to+call+another+command
   # https://stackoverflow.com/questions/4702406/how-to-pass-the-argument-line-of-one-powershell-function-to-another
   # https://stackoverflow.com/questions/24984483/pass-an-unspecified-set-of-parameters-into-a-function-and-thru-to-a-cmdlet
   # https://stackoverflow.com/questions/37709429/can-you-combine-cmdletbinding-with-unbound-parameters
   # https://4sysops.com/archives/finding-function-default-parameters-with-powershell-ast-when-working-with-psboundparameters/

   #https://stackoverflow.com/questions/27764394/get-valuefromremainingarguments-as-an-hashtable
   # $UnboundArguments | gm
   # $UnboundArguments

   begin {
      $location = Get-Location
   }
   process {
      $absolutePath = Resolve-Path -Path $Paths
      Write-Information -MessageData "Importing ItemGroups from file '$absolutePath'." -InformationAction Continue
      # make sure current folder for each item group definition file is its containing folder
      $itemGroupFolderPath = Split-Path -Path $absolutePath -Parent
      Write-Verbose -Message "Setting location to '$itemGroupFolderPath'."
      Set-Location -Path $itemGroupFolderPath

      $content = Get-Content -Raw -Path $absolutePath
      # $expectedParameterNames = @( [scriptblock]::Create($content).Ast.ParamBlock.Parameters.Name.VariablePath.UserPath )
      # $arguments = [hashtable]$PSBoundParameters
      # $PSBoundParameters.Keys | Where-Object { $_ -notin $expectedParameterNames } | ForEach-Object { $arguments.Remove($_) }
      # $block = [scriptblock]::Create(".{$content} $(&{$args} @arguments)")
      $block = [scriptblock]::Create(".{$content} $(&{$args} @UnboundArguments)")
      $itemGroups = Invoke-Command -ScriptBlock $block

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
               | Where-Object -FilterScript { $_.Path -ne '*' } -PipelineVariable item `
               | ForEach-Object -Process { $item.Path | Resolve-Path -ErrorAction Stop <# will throw if Item is not found #> | Select-Object -ExpandProperty Path } -PipelineVariable path `
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
      $Duplicate = $false
   )
   begin {
      $itemGroupCache = @()
   }
   process {
      if ($Duplicate) { $itemGroupCache += @( $ItemGroup | ForEach-Object -Process { $_ } ) }
   }
   end {
      if ($Duplicate) {
         $itemGroupCache.Keys | Group-Object |
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
      } elseif (!$referenceProperties.Contains($key) -and $differenceProperties.Contains($key)) {
         [PSCustomObject]@{Key = $propertyName ; ReferenceValue = $null ; SideIndicator = '>' ; DifferenceValue = $DifferenceItem.$key} | Tee-Object -Variable difference
         Write-Verbose -Message $difference
      } else {
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
               } else {
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

      [Parameter(Mandatory = $true, ParameterSetName = 'duplicate')]
      [switch]
      $Duplicate = $false,

      [Parameter(Mandatory = $true, ParameterSetName = 'valid')]
      [switch]
      $IsValid = $false
   )
   begin {
      $itemCache = @()
      $isItem = $false
   }
   process {
      if ($Duplicate) {
         $itemCache += @(
            $Item |
               Where-Object -FilterScript { Test-Item -Item $_ -IsValid } |
               ForEach-Object -Process { $_ }
         )
      }
      if ($IsValid) {
         $Item | ForEach-Object -Process { $_ } -PipelineVariable currentItem | ForEach-Object -Process {
            if (-not $isItem) {
               if ($currentItem -eq $null) {
                  $isItem = $false
               } elseif ($currentItem -is [hashtable]) {
                  $isItem = $currentItem.Count -gt 0
               } elseif ($currentItem -is [PSCustomObject]) {
                  $isItem = $currentItem | Get-Member -MemberType NoteProperty, ScriptProperty | Test-Any
               }
            }
         }
      }
   }
   end {
      if ($Duplicate) {
         $itemCache | Group-Object -Property { $_.Path } |
            Where-Object -FilterScript { $_.Count -gt 1 } |
            ForEach-Object -Process { Write-Warning -Message "Item '$($_.Name)' has been defined multiple times." }
      }
      if ($IsValid) {
         $isItem
      }
   }
}

#endregion

<#
 # Main
 #>

# Export-ModuleMember -Function Import-ItemGroups
