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

Import-Module ItemGroup\Group -Force

Describe 'Expand-ItemGroup' {
   InModuleScope Group {

      Context 'Expansion computes Name property after Path property' {
         Mock -CommandName Test-Item -ParameterFilter { $Valid.IsPresent } -MockWith { $true <# assumes every Item is valid #> }
         Mock -CommandName Resolve-Path -MockWith { [PSCustomObject]@{ ProviderPath = $Path } }
         It 'computes Name property after Path property.' {
            $itemGroup = @(
               @{ Group = @( @{ Path = '\\Server\Folder\Item.txt' } ) }
            )

            $expandedItemGroup = $itemGroup | Expand-ItemGroup -InformationAction SilentlyContinue -WarningAction SilentlyContinue

            $expectedItemGroup = @{
               Group = @(
                  ConvertTo-Item @{ Name = 'Item.txt'; Path = '\\Server\Folder\Item.txt' }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'computes and overwrites Name property after Path property.' {
            $itemGroup = @(
               @{ Group = @( @{ Name = 'item-name' ; Path = '\\Server\Folder\Item.txt' } ) }
            )

            $expandedItemGroup = $itemGroup | Expand-ItemGroup -InformationAction SilentlyContinue -WarningAction SilentlyContinue

            $expectedItemGroup = @{
               Group = @(
                  ConvertTo-Item @{ Name = 'Item.txt'; Path = '\\Server\Folder\Item.txt' }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
      }

      Context 'Expansion fails if Item.Path cannot be resolved.' {
         Mock -CommandName Test-Item -ParameterFilter { $Valid.IsPresent } -MockWith { $true <# assumes every Item is valid #> }
         It 'Throws on the first Item whose Path cannot be resolved.' {
            $itemGroup = @{ Group1 = @(@{ Path = 'not-found-item-1.dll' }, @{ Path = 'not-found-item-2.exe' }) }

            { Expand-ItemGroup -ItemGroup $itemGroup -InformationAction SilentlyContinue -WarningAction SilentlyContinue } |
               Should -Throw -ExpectedMessage 'not-found-item-1.dll' -ErrorId 'PathNotFound,Microsoft.PowerShell.Commands.ResolvePathCommand'
         }
      }

      Context 'Expansion when ItemGroups are given by arguments.' {
         It 'returns empty when expanding an empty ItemGroup.' {
            Expand-ItemGroup -ItemGroup @{ } -InformationAction SilentlyContinue | Should -BeNullOrEmpty
         }
         It 'returns an empty ItemGroup when expanding an ItemGroup made only of a default Item.' {
            $itemGroup = @{
               Group1 = @( @{ Name = '*'; Condition = ($false) } )
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $itemGroup -InformationAction SilentlyContinue

            $expectedItemGroup = @{ Group1 = @() }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'returns an empty ItemGroup when expanding duplicate ItemGroups whose one is made only of a default Item.' {
            $itemGroup = @(
               @{ Group1 = @( @{ Name = '*'; Condition = $true } ) }
               @{ Group1 = @(
                     @{ Name = '*'; Condition = $false }
                     @{ Name = 'Item' }
                  )
               }
            )

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $itemGroup -InformationAction SilentlyContinue -WarningAction SilentlyContinue

            $expectedItemGroups = @{ Group1 = @( ) }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroups -DifferenceItemGroup $expandedItemGroup -Verbose | Should -BeNullOrEmpty
         }
         It 'returns one ItemGroup when expanding one ItemGroup.' {
            $itemGroup = @{
               Group1 = @(
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12'; Condition = $true }
               )
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $itemGroup -InformationAction SilentlyContinue

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'Item11' }
                  ConvertTo-Item @{ Name = 'Item12'; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'filters out Items whose Condition predicate is not satisfied.' {
            $itemGroup = @{
               Group1 = @(
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12'; Condition = $false }
               )
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $itemGroup -InformationAction SilentlyContinue

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'Item11' }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'returns several ItemGroups when expanding several ItemGroups.' {
            $itemGroup = @(
               @{ Group1 = @( @{ Name = 'Item11' } , @{ Name = 'Item12'; Condition = $true } ) }
               @{ Group2 = @( @{ Name = 'Item21' } , @{ Name = 'Item22'; Condition = $true } ) }
            )

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $itemGroup -InformationAction SilentlyContinue

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'Item11' }
                  ConvertTo-Item @{ Name = 'Item12'; Condition = $true }
               )
               Group2 = @(
                  ConvertTo-Item @{ Name = 'Item21' }
                  ConvertTo-Item @{ Name = 'Item22'; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'merges default Item''s properties back into every Item.' {
            $itemGroup = @{
               Group1 = @(
                  @{ Name = '*'; Account = 'Account' }
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12'; Condition = $true }
               )
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $itemGroup -InformationAction SilentlyContinue

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'Item11'; Account = 'Account' }
                  ConvertTo-Item @{ Name = 'Item12'; Account = 'Account' ; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'merges default Item''s condition property back in every Item but does not overwrite it.' {
            $itemGroup = @{
               Group1 = @(
                  @{ Name = '*'; Condition = $false }
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12'; Condition = $true }
               )
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $itemGroup -InformationAction SilentlyContinue

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'Item12'; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
      }

      Context 'Expansion when ItemGroups are given by pipeline.' {
         It 'returns empty when expanding an empty ItemGroup.' {
            @{ } | Expand-ItemGroup -InformationAction SilentlyContinue | Should -BeNullOrEmpty
         }
         It 'returns an empty ItemGroup when expanding an ItemGroup made only of a default Item.' {
            $itemGroup = @{
               Group1 = @( @{ Name = '*'; Condition = ($false) } )
            }

            $expandedItemGroup = $itemGroup | Expand-ItemGroup -InformationAction SilentlyContinue

            $expectedItemGroup = @{ Group1 = @() }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'returns an empty ItemGroup when expanding duplicate ItemGroups whose one is made only of a default Item.' {
            $itemGroup = @(
               @{ Group1 = @( @{ Name = '*'; Condition = $true } ) }
               @{ Group1 = @(
                     @{ Name = '*'; Condition = $false }
                     @{ Name = 'Item' }
                  )
               }
            )

            $expandedItemGroup = $itemGroup | Expand-ItemGroup -InformationAction SilentlyContinue -WarningAction SilentlyContinue

            $expectedItemGroups = @{ Group1 = @( ) }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroups -DifferenceItemGroup $expandedItemGroup -Verbose | Should -BeNullOrEmpty
         }
         It 'returns one ItemGroup when expanding one ItemGroup.' {
            $itemGroup = @{
               Group1 = @(
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12'; Condition = $true }
               )
            }

            $expandedItemGroup = $itemGroup | Expand-ItemGroup -InformationAction SilentlyContinue

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'Item11' }
                  ConvertTo-Item @{ Name = 'Item12'; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'filters out Items whose Condition predicate is not satisfied.' {
            $itemGroup = @{
               Group1 = @(
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12'; Condition = $false }
               )
            }

            $expandedItemGroup = $itemGroup | Expand-ItemGroup -InformationAction SilentlyContinue

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'Item11' }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'returns several ItemGroups when expanding several ItemGroups.' {
            $itemGroup = @(
               @{ Group1 = @( @{ Name = 'Item11' } , @{ Name = 'Item12'; Condition = $true } ) }
               @{ Group2 = @( @{ Name = 'Item21' } , @{ Name = 'Item22'; Condition = $true } ) }
            )

            $expandedItemGroup = $itemGroup | Expand-ItemGroup -InformationAction SilentlyContinue

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'Item11' }
                  ConvertTo-Item @{ Name = 'Item12'; Condition = $true }
               )
               Group2 = @(
                  ConvertTo-Item @{ Name = 'Item21' }
                  ConvertTo-Item @{ Name = 'Item22'; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'merges default Item''s properties back into every Item.' {
            $itemGroup = @{
               Group1 = @(
                  @{ Name = '*'; Account = 'Account' }
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12'; Condition = $true }
               )
            }

            $expandedItemGroup = $itemGroup | Expand-ItemGroup -InformationAction SilentlyContinue

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'Item11'; Account = 'Account' }
                  ConvertTo-Item @{ Name = 'Item12'; Account = 'Account' ; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'merges default Item''s condition property back in every Item but does not overwrite it.' {
            $itemGroup = @{
               Group1 = @(
                  @{ Name = '*'; Condition = $false }
                  @{ Name = 'Item11' }
                  @{ Name = 'Item12'; Condition = $true }
               )
            }

            $expandedItemGroup = $itemGroup | Expand-ItemGroup -InformationAction SilentlyContinue

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'Item12'; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
      }

      Context 'Expansion flattens Item.Path property' {
         Mock -CommandName Get-Item -ModuleName Item -MockWith { [PSCustomObject]@{ PSIsContainer = $false } }
         Mock -CommandName Test-Item -ParameterFilter { $Valid.IsPresent } -MockWith { $true <# assumes every Item is valid #> }
         Mock -CommandName Resolve-Path -MockWith { [PSCustomObject]@{ ProviderPath = $Path } }
         It 'flattens Items whose Path property denotes a list of paths.' {
            $itemGroup = @( @{ Group1 = @(
                     @{ Path = @('z:\folder\Item1.dll', 'z:\folder\Item2.dll', 'z:\folder\Item3.dll') ; Condition = $true }
                  )
               }
            )

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $itemGroup -InformationAction SilentlyContinue

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'Item1.dll'; Path = 'z:\folder\Item1.dll'; Condition = $true }
                  ConvertTo-Item @{ Name = 'Item2.dll'; Path = 'z:\folder\Item2.dll'; Condition = $true }
                  ConvertTo-Item @{ Name = 'Item3.dll'; Path = 'z:\folder\Item3.dll'; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'flattens Items whose Path property denotes a list of paths and merges default Item''s properties.' {
            $itemGroup = @{ Group1 = @(
                  @{ Name = '*'; Condition = $false; Extra = 'Dummy' }
                  @{ Path = @('z:\folder\Item1.dll', 'z:\folder\Item2.dll', 'z:\folder\Item3.dll') ; Condition = $true }
               )
            }

            $expandedItemGroup = $itemGroup | Expand-ItemGroup -InformationAction SilentlyContinue

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{ Name = 'Item1.dll'; Path = 'z:\folder\Item1.dll'; Condition = $true; Extra = 'Dummy' }
                  ConvertTo-Item @{ Name = 'Item2.dll'; Path = 'z:\folder\Item2.dll'; Condition = $true; Extra = 'Dummy' }
                  ConvertTo-Item @{ Name = 'Item3.dll'; Path = 'z:\folder\Item3.dll'; Condition = $true; Extra = 'Dummy' }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
      }

      Context 'Expansion informs about progress' {
         Mock -CommandName Write-Information
         It 'Informs about each ItemGroup that is expanded.' {
            $itemGroup = @(
               @{ ApplicationBindings = @(@{ Name = 'a'; Condition = $false }) }
               @{ Schemas = @(@{ Name = 's'; Condition = $false }) }
               @{ Transforms = @(@{ Name = 't'; Condition = $false }) }
               @{ Orchestrations = @(@{ Name = 'o'; Condition = $false }) }
            )
            Expand-ItemGroup -ItemGroup $itemGroup -InformationAction Continue

            Assert-MockCalled -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''ApplicationBindings''.' }
            Assert-MockCalled -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Schemas''.' }
            Assert-MockCalled -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Transforms''.' }
            Assert-MockCalled -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Orchestrations''.' }
            Assert-MockCalled -CommandName Write-Information -Exactly 4
         }
      }

      Context 'Expansion warns about every issue' {
         Mock -CommandName Write-Warning -ModuleName Group
         Mock -CommandName Write-Warning -ModuleName Item
         It 'warns about every invalid Item.' {
            $itemGroup = @{ Group = @(@{ LastName = 'Stark' }, @{ LastName = 'Potts' }) }
            Expand-ItemGroup -ItemGroup $itemGroup -InformationAction SilentlyContinue

            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'The following Item is invalid because it is either ill-formed or misses either a valid Path or Name property:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'LastName\s+:\s+Stark' } -Exactly 1
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'LastName\s+:\s+Potts' } -Exactly 1
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -Exactly 4
         }
         It 'warns about each duplicate Item.' {
            $itemGroup = @{
               ApplicationBindings = @(
                  @{ Name = 'a'; Condition = $false }
                  @{ Name = 'a'; Condition = $false }
               )
            }
            Expand-ItemGroup -ItemGroup $itemGroup

            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'The following Item ''a'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'Condition\s+:\s+False' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'Name\s+:\s+a' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -Exactly 6
         }
         It 'warns about each duplicate ItemGroup.' {
            $itemGroup = @(
               @{ ApplicationBindings = @(@{ Name = 'a'; Condition = $false }) }
               @{ ApplicationBindings = @(@{ Name = 'a'; Condition = $false }) }
            )
            Expand-ItemGroup -ItemGroup $itemGroup

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''ApplicationBindings'' has been defined multiple times.' } -Exactly 1
         }
         It 'warns about every redefined ItemGroup.' {
            $itemGroup = @(
               @{ ApplicationBindings = @(@{ Name = 'a'; Condition = $false }) }
               @{ ApplicationBindings = @(@{ Name = 'a'; Condition = $false }) }
            )
            Expand-ItemGroup -ItemGroup $itemGroup

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''ApplicationBindings'' is being redefined.' } -Exactly 1
         }
      }

   }
}
