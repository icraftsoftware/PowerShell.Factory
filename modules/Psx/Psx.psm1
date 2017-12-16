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

<#
.SYNOPSIS
    Ensures the current process is 32 bit.
.DESCRIPTION
    This command will throw if the current process is not a 32 bit process and will silently complete otherwise.
.EXAMPLE
    PS> Assert-32bitProcess
.EXAMPLE
    PS> Assert-32bitProcess -Verbose
    With the -Verbose switch, this command will confirm this process is 32 bit.
.NOTES
    © 2012 be.stateless.
#>
function Assert-32bitProcess {
   [CmdletBinding()]
   param()

   if (-not(Test-32bitProcess)) {
      throw "A 32 bit process is required to run this function!"
   }
   Write-Verbose "Process is 32 bit."
}

<#
.SYNOPSIS
    Ensures the current process is 64 bit.
.DESCRIPTION
    This command will throw if the current process is not a 64 bit process and will silently complete otherwise.
.EXAMPLE
    PS> Assert-64bitProcess
.EXAMPLE
    PS> Assert-64bitProcess -Verbose
    With the -Verbose switch, this command will confirm this process is 64 bit.
.NOTES
    © 2012 be.stateless.
#>
function Assert-64bitProcess {
   [CmdletBinding()]
   param()

   if (-not(Test-64bitProcess)) {
      throw "A 64 bit process is required to run this function!"
   }
   Write-Verbose "Process is 64 bit."
}

<#
.SYNOPSIS
    Ensures the current process is running in elevated mode.
.DESCRIPTION
    This command will throw if the current process is not running in elevated mode and will silently complete otherwise.
.EXAMPLE
    PS> Assert-Elevated
.EXAMPLE
    PS> Assert-Elevated -Verbose
    With the -Verbose switch, this command will confirm this process is running
    in elevated mode.
.NOTES
    © 2012 be.stateless.
#>
function Assert-Elevated {
   [CmdletBinding()]
   param()

   if (-not(Test-Elevated)) {
      throw "A process running in elevated mode is required to run this function!"
   }
   Write-Verbose "Process is running in elevated mode."
}

<#
.SYNOPSIS
    Compare two hashtables and returns an array of differences.
.DESCRIPTION
    The Compare-HashTable function computes differences between two hashtables. Results are returned as
    an array of objects with the properties: "Key" (the name of the key for which there is a difference),
    "SideIndicator" (one of "<=", "!=" or "=>"), "ReferenceValue" an "DifferenceValue" (resp. the Reference
    and Difference value associated with the Key).
.PARAMETER ReferenceHashTable
    The hashtable used as a reference for comparison.
.PARAMETER DifferenceHashTable
    The hashtable that is compared to the reference hashtable.
.EXAMPLE
    Compare-HashTable @{ a = 1; b = 2; c = 3 } @{ b = 2; c = 4; e = 5}
    Returns a difference for ("3 <="), c (3 "!=" 4) and e ("=>" 5).
.EXAMPLE
    $ReferenceHashTable = @{ a = 1; b = 2; c = 3; f = $Null; g = 6 }
    $DifferenceHashTable = @{ b = 2; c = 4; e = 5; f = $Null; g = $Null }
    Compare-HashTable $ReferenceHashTable $DifferenceHashTable
    Returns a difference for a ("3 <="), c (3 "!=" 4), e ("=>" 5) and g (6 "<=").
.NOTES
    See https://gist.github.com/dbroeglin/c6ce3e4639979fa250cf
#>
function Compare-HashTable {
   [CmdletBinding()]
   [OutputType([PSCustomObject[]])]
   param (
      [Parameter(Mandatory = $true)]
      [HashTable]
      $ReferenceHashTable,

      [Parameter(Mandatory = $true)]
      [HashTable]
      $DifferenceHashTable
   )
   $ReferenceHashTable.Keys + $DifferenceHashTable.Keys | Sort-Object -Unique -PipelineVariable key | ForEach-Object -Process {
      if ($ReferenceHashTable.ContainsKey($key) -and !$DifferenceHashTable.ContainsKey($key)) {
         [PSCustomObject]@{Key = $key ; ReferenceValue = $ReferenceHashTable.$key ; SideIndicator = '<' ; DifferenceValue = $null} | Tee-Object -Variable difference
         Write-Verbose -Message $difference
      }
      elseif (!$ReferenceHashTable.ContainsKey($key) -and $DifferenceHashTable.ContainsKey($key)) {
         [PSCustomObject]@{Key = $key ; ReferenceValue = $null ; SideIndicator = '>' ; DifferenceValue = $DifferenceHashTable.$key} | Tee-Object -Variable difference
         Write-Verbose -Message $difference
      }
      else {
         $referenceValue, $differenceValue = $ReferenceHashTable.$key, $DifferenceHashTable.$key
         if ($referenceValue -ne $differenceValue) {
            [PSCustomObject]@{Key = $key ; ReferenceValue = $referenceValue ; SideIndicator = '<>' ; DifferenceValue = $differenceValue} | Tee-Object -Variable difference
            Write-Verbose -Message $difference
         }
      }
   }
}

function Convert-ScriptBlockParametersToDynamicParameters {
   [CmdletBinding()]
   [OutputType([System.Management.Automation.RuntimeDefinedParameterDictionary])]
   param(
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [scriptblock]
      $ScriptBlock
   )
   begin {
      # https://stackoverflow.com/questions/26910789/is-it-possible-to-reuse-a-param-block-across-multiple-functions
      $commonParameterNames = [FormatterServices]::GetUninitializedObject([CommonParameters]) |
         Get-Member -MemberType Properties |
         Select-Object -ExpandProperty Name
      $dynamicParameters = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
   }
   process {
      $ScriptBlock.Ast.ParamBlock | Select-Object -ExpandProperty Parameters |
         Where-Object -FilterScript { $commonParameterNames -notcontains $_.Name.VariablePath.UserPath } |
         ForEach-Object -Process {
         $paramName = $_.Name.VariablePath.UserPath
         $paramAttributes = new-object System.Collections.ObjectModel.Collection[System.Attribute]
         $_.Attributes | ForEach-Object -Process {
            $attributeType = Invoke-Expression -Command "[$($_.TypeName.FullName)]"
            if ([System.Management.Automation.Internal.CmdletMetadataAttribute].IsAssignableFrom($attributeType)) {
               $attribute = New-Object -TypeName $attributeType.FullName -ArgumentList @($_.PositionalArguments | ForEach-Object Value)
               $_.NamedArguments | ForEach-Object -Process {
                  $attribute.($_.ArgumentName) = Invoke-Expression -Command ($_.Argument.Extent.Text)
               }
               $paramAttributes.Add($attribute)
            }
         }
         $param = New-Object System.Management.Automation.RuntimeDefinedParameter $paramName, $_.StaticType, $paramAttributes
         $dynamicParameters.Add($paramName, $param)
      }
   }
   end {
      $dynamicParameters
   }
}

<#
.SYNOPSIS
    Given a command name or alias, lists its matching command name and all its aliases.
.DESCRIPTION
    This command will throw if the current process is not a 32 bit process and will silently complete otherwise.
.PARAMETER Command
    The command name or alias for which the command and all its aliases will be returned.
.EXAMPLE
    PS> Get-CommandAlias ls
.EXAMPLE
    PS> Get-CommandAlias Get-ChildItem
.NOTES
    © 2012 be.stateless.
#>
function Get-CommandAlias {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true)]
      [string]
      $Command
   )

   $cmd = Get-Command $Command
   if ($cmd -ne $null) {
      if ($cmd.CommandType -eq "alias") {
         $cmd = $cmd.Definition
      }
      @(Get-Command $cmd) + @(Get-Alias -Definition $cmd -errorAction SilentlyContinue | Sort-Object)
   }
}

function Invoke-ScriptBlock {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true)]
      [scriptblock]
      $ScriptBlock,

      [Parameter(Mandatory = $true)]
      [psobject]
      $Parameters
   )
   process {
      $expectedParameters = @( $ScriptBlock.Ast.ParamBlock | Select-Object -ExpandProperty Parameters | ForEach-Object -Process { $_.Name.VariablePath.UserPath } )
      $unexpectedParameters = @( $Parameters.Keys | Where-Object -FilterScript { $_ -notin $expectedParameters } )
      $unexpectedParameters | ForEach-Object -Process { $Parameters.Remove($_) | Out-Null }
      & $ScriptBlock @Parameters
   }
}

<#
.SYNOPSIS
    Returns a new hashtable which is the merging of the input hash tables.
.DESCRIPTION
    Properties are not overwritten during the merge operation unless forced. Even when forced it is possible to provide a list of properties not to overwrite.
.EXAMPLE
.NOTES
    © 2017 be.stateless.
#>
function Merge-HashTable {
   [CmdletBinding()]
   [OutputType([hashtable])]
   param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [hashtable[]]
      $HashTable,

      [Parameter(Mandatory = $false)]
      [string[]]
      $Exclude = @(),

      [Parameter(Mandatory = $false)]
      [switch]
      $Force
   )
   begin {
      $result = @{}
   }
   process {
      $HashTable | ForEach-Object -Process { $_ } -PipelineVariable currentHashTable | Select-Object -ExpandProperty Keys -PipelineVariable key | ForEach-Object -Process {
         $propertyExists = $result.ContainsKey($key)
         if (-not $propertyExists -or ($Force -and $key -notin $Exclude) ) {
            $result.$key = $currentHashTable.$key
            if ($propertyExists) {
               Write-Verbose -Message "Property '$key' has been overwritten because it has been defined multiple times."
            }
         }
      }
   }
   end {
      $result
   }
}


<#
.SYNOPSIS
    Returns whether the current operating system is 32 bit.
.DESCRIPTION
    This command will return $true if the current operating system is 32 bit, or $false otherwise.
.EXAMPLE
    PS> Test-32bitArchitecture
.NOTES
    © 2012 be.stateless.
#>
function Test-32bitArchitecture {
   [CmdletBinding()]
   param()

   # http://msdn.microsoft.com/en-us/library/windows/desktop/aa394373(v=vs.85).aspx
   # On a 32-bit operating system, the value is 32 and on a 64-bit operating system it is 64
   [bool]((Get-WmiObject -Class Win32_Processor -ComputerName $Env:COMPUTERNAME | Select-Object -First 1).AddressWidth -eq 32)
}

<#
.SYNOPSIS
    Returns whether the current process is 32 bit.
.DESCRIPTION
    This command will return $true if the current process is 32 bit, or $false otherwise.
.EXAMPLE
    PS> Test-32bitProcess
.NOTES
    © 2012 be.stateless.
#>
function Test-32bitProcess {
   [CmdletBinding()]
   param()

   [bool]($Env:PROCESSOR_ARCHITECTURE -eq 'x86')
}

<#
.SYNOPSIS
    Returns whether the current operating system is 64 bit.
.DESCRIPTION
    This command will return $true if the current operating system is 64 bit, or $false otherwise.
.EXAMPLE
    PS> Test-64bitArchitecture
.NOTES
    © 2012 be.stateless.
#>
function Test-64bitArchitecture {
   [CmdletBinding()]
   param()

   # http://msdn.microsoft.com/en-us/library/windows/desktop/aa394373(v=vs.85).aspx
   # On a 32-bit operating system, the value is 32 and on a 64-bit operating system it is 64
   [bool]((Get-WmiObject -Class Win32_Processor -ComputerName $Env:COMPUTERNAME | Select-Object -First 1).AddressWidth -eq 64)
}

<#
.SYNOPSIS
    Returns whether the current process is 64 bit.
.DESCRIPTION
    This command will return $true if the current process is 64 bit, or $false otherwise.
.EXAMPLE
    PS> Test-64bitProcess
.NOTES
    © 2012 be.stateless.
#>
function Test-64bitProcess {
   [CmdletBinding()]
   param()

   [bool]($Env:PROCESSOR_ARCHITECTURE -match '64')
}

<#
.SYNOPSIS
    Tests whether there is anything in a pipeline.
.DESCRIPTION
    This command will return $true if there is anything in the pipeline, or $false otherwise.
.EXAMPLE
    PS> Get-ChildItem | Test-Any
.NOTES
    See https://blogs.msdn.microsoft.com/jaredpar/2008/06/12/is-there-anything-in-that-pipeline/
#>
function Test-Any {
   [CmdletBinding()]
   param(
      [Parameter(ValueFromPipeline = $true)]
      [AllowEmptyCollection()]
      [psobject[]]
      $InputObject
   )
   begin {
      $any = $false
   }
   process {
      $any = $true
   }
   end {
      $any
   }
}

<#
.SYNOPSIS
    Returns whether the current process is running in elevated mode.
.DESCRIPTION
    This command will return $true if the current process is running in elevated mode, or $false otherwise.
.EXAMPLE
    PS> Test-Elevated
.NOTES
    © 2012 be.stateless.
#>
function Test-Elevated {
   [CmdletBinding()]
   param()

   # only if OS is later than XP (i.e. from Vista upward)
   # if ([System.Environment]::OSVersion.Version.Major -gt 5)

   $wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
   [bool]( ([Security.Principal.WindowsPrincipal] $wid).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator) )
}

<#
 # Main
 #>

if (-not((Get-Module Pscx).Version.Major -ge 3)) {
   throw "PowerShell Community Extensions PSCX 3.0 or higher is required to run this module!"
}

[accelerators]::Add('CommonParameters', 'System.Management.Automation.Internal.CommonParameters')
[accelerators]::Add('FormatterServices', 'System.Runtime.Serialization.FormatterServices')

Set-Alias aka Get-CommandAlias -Option AllScope -Scope 'Global' -Force
Set-Alias which Get-Command -Option AllScope -Scope 'Global' -Force
