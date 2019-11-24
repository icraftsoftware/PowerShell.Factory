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

      Context 'Name property is required.' {
         Mock -Command Resolve-Path -MockWith { [PSCustomObject]@{ ProviderPath = $Path } }
         Mock -Command Write-Information # avoid cluttering Pester output
         It 'Traces invalid items.' {
            Mock -Command Write-Warning -ModuleName Item

            $itemGroup = @{ Group = @(@{LastName = 'Stark' }, @{LastName = 'Potts' }) }

            { Expand-ItemGroup -ItemGroup $itemGroup } | Should -Not -Throw

            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'The following Item is invalid because it is either ill-formed or misses either a Name or Path property:' } -Times 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'Name\s+Value' } -Times 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'LastName\s+Stark' }
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'LastName\s+Potts' }
         }
         It 'Computes Name property after Path property.' {
            $itemGroups = @(
               @{ Group = @( @{Path = '\\Server\Folder\Item' } ) }
            )

            $expandedItemGroups = $itemGroups | Expand-ItemGroup

            $expectedItemGroup = @{
               Group = @(
                  ConvertTo-Item @{Name = 'Item'; Path = '\\Server\Folder\Item' }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroups | Should -BeNullOrEmpty
         }
         It 'Does not overwrite Name property after Path property.' {
            $itemGroups = @(
               @{ Group = @( @{Name = 'item-name' ; Path = '\\Server\Folder\Item' } ) }
            )

            $expandedItemGroups = $itemGroups | Expand-ItemGroup

            $expectedItemGroup = @{
               Group = @(
                  ConvertTo-Item @{Name = 'item-name'; Path = '\\Server\Folder\Item' }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroups | Should -BeNullOrEmpty
         }
      }

      Context 'When ItemGroups are given by arguments.' {
         Mock -Command Write-Information # avoid cluttering Pester output
         It 'Expands an empty ItemGroup.' {
            $itemGroup = @{ }
            Expand-ItemGroup -ItemGroup $itemGroup | Should -BeNullOrEmpty
         }
         It 'Expands an ItemGroup made only of a default item.' {
            $itemGroup = @{
               Group1 = @(
                  @{Name = '*'; Condition = ($false) }
               )
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $itemGroup

            $expectedItemGroup = @{ Group1 = @() }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Expands one ItemGroup.' {
            $itemGroup = @{
               Group1 = @(
                  @{Name = 'Item11' }
                  @{Name = 'Item12'; Condition = $true }
               )
               Group2 = @(
                  @{Name = 'Item21' }
                  @{Name = 'Item22'; Condition = $true }
               )
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $itemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Name = 'Item11' }
                  ConvertTo-Item @{Name = 'Item12'; Condition = $true }
               )
               Group2 = @(
                  ConvertTo-Item @{Name = 'Item21' }
                  ConvertTo-Item @{Name = 'Item22'; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Expands several ItemGroups.' {
            $itemGroups = @(
               @{ Group1 = @( @{Name = 'Item11' } , @{Name = 'Item12'; Condition = $true } ) }
               @{ Group2 = @( @{Name = 'Item21' } , @{Name = 'Item22'; Condition = $true } ) }
            )

            $expandedItemGroups = Expand-ItemGroup -ItemGroup $itemGroups

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Name = 'Item11' }
                  ConvertTo-Item @{Name = 'Item12'; Condition = $true }
               )
               Group2 = @(
                  ConvertTo-Item @{Name = 'Item21' }
                  ConvertTo-Item @{Name = 'Item22'; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroups | Should -BeNullOrEmpty
         }
         It 'Merges default item''s properties in every item.' {
            $itemGroup = @{
               Group1 = @(
                  @{Name = '*'; Condition = $false }
                  @{Name = 'Item11' }
                  @{Name = 'Item12'; Condition = $true }
               )
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $itemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Name = 'Item11'; Condition = $false }
                  ConvertTo-Item @{Name = 'Item12'; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Expands duplicate ItemGroups where one is made only of a default item.' {
            Mock -Command Write-Warning
            Mock -Command Write-Warning -ModuleName Item

            $itemGroups = @(
               @{Group1 = @( @{Name = '*'; Condition = $true } ) }
               @{Group1 = @(
                     @{Name = '*'; Condition = ($false) }
                     @{Name = 'Item' }
                  )
               }
            )

            $expandedItemGroups = Expand-ItemGroup -ItemGroup $itemGroups

            $expectedItemGroups = @{ Group1 = @( ConvertTo-Item @{Name = 'Item'; Condition = $false } ) }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroups -DifferenceItemGroup $expandedItemGroups -Verbose | Should -BeNullOrEmpty

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''Group1'' has been defined multiple times.' }
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'Item ''*'' has been defined multiple times.' }
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'Items of ItemGroup ''Group1'' have been redefined.' }
         }
         It 'Informs about progress.' {
            $itemGroups = @(
               @{ ApplicationBindings = @(@{Name = 'a'; Condition = $false }) }
               @{ Schemas = @(@{Name = 's'; Condition = $false }) }
               @{ Transforms = @(@{Name = 't'; Condition = $false }) }
               @{ Orchestrations = @(@{Name = 'o'; Condition = $false }) }
            )

            Expand-ItemGroup -ItemGroup $itemGroups

            Assert-MockCalled -Scope It -CommandName Write-Information -Times 4 # has been called only twice
            Assert-MockCalled -Scope It -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''ApplicationBindings''.' }
            Assert-MockCalled -Scope It -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Schemas''.' }
            Assert-MockCalled -Scope It -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Transforms''.' }
            Assert-MockCalled -Scope It -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Orchestrations''.' }
         }
         It 'Traces ItemGroup duplicates.' {
            Mock -Command Write-Warning -ModuleName Group
            Mock -Command Write-Warning -ModuleName Item

            $itemGroups = @(
               @{ ApplicationBindings = @(@{Name = 'a'; Condition = $false }) }
               @{ ApplicationBindings = @(@{Name = 'a'; Condition = $false }) }
            )

            Expand-ItemGroup -ItemGroup $itemGroups

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''ApplicationBindings'' has been defined multiple times.' }
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'Items of ItemGroup ''ApplicationBindings'' have been redefined.' }
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'Item ''a'' has been defined multiple times.' }
         }
         It 'Traces item duplicates.' {
            Mock -Command Write-Warning -ModuleName Item

            $itemGroup = @{
               ApplicationBindings = @(
                  @{Name = 'a'; Condition = $false }
                  @{Name = 'a'; Condition = $false }
               )
            }

            Expand-ItemGroup -ItemGroup $itemGroup

            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'Item ''a'' has been defined multiple times.' }
         }
         It 'Warns about every redefined ItemGroup.' {
            Mock -Command Write-Warning -ModuleName Group
            Mock -Command Write-Warning -ModuleName Item

            $itemGroups = @(
               @{ ApplicationBindings = @(@{Name = 'a'; Condition = $false }) }
               @{ ApplicationBindings = @(@{Name = 'a'; Condition = $false }) }
            )

            Expand-ItemGroup -ItemGroup $itemGroups

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'Items of ItemGroup ''ApplicationBindings'' have been redefined.' }
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'Item ''a'' has been defined multiple times.' }
         }
      }

      Context 'When ItemGroups are given by pipeline.' {
         Mock -Command Write-Information # avoid cluttering Pester output
         Mock -Command Resolve-Path -MockWith { [PSCustomObject]@{ ProviderPath = $Path } }
         It 'Expands one ItemGroup.' {
            $itemGroup = @{
               Group1 = @(
                  @{Name = 'Item11' }
                  @{Name = 'Item12'; Condition = $true }
               )
               Group2 = @(
                  @{Name = 'Item21' }
                  @{Name = 'Item22'; Condition = $true }
               )
            }

            $expandedItemGroup = $itemGroup | Expand-ItemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Name = 'Item11' }
                  ConvertTo-Item @{Name = 'Item12'; Condition = $true }
               )
               Group2 = @(
                  ConvertTo-Item @{Name = 'Item21' }
                  ConvertTo-Item @{Name = 'Item22'; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Expands an ItemGroup made only of a default item.' {
            $itemGroup = @{
               Group1 = @(
                  @{Name = '*'; Condition = ($false) }
               )
            }

            $expandedItemGroup = $itemGroup | Expand-ItemGroup

            $expectedItemGroup = @{ Group1 = @() }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Expands serveral ItemGroups.' {
            $itemGroups = @(
               @{ Group1 = @( @{Name = 'Item11' } , @{Name = 'Item12'; Condition = $true } ) }
               @{ Group2 = @( @{Name = 'Item21' } , @{Name = 'Item22'; Condition = $true } ) }
            )

            $expandedItemGroups = $itemGroups | Expand-ItemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Name = 'Item11' }
                  ConvertTo-Item @{Name = 'Item12'; Condition = $true }
               )
               Group2 = @(
                  ConvertTo-Item @{Name = 'Item21' }
                  ConvertTo-Item @{Name = 'Item22'; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroups | Should -BeNullOrEmpty

         }
         It 'Expands duplicate ItemGroups where one is made only of a default item.' {
            Mock -Command Write-Warning
            # TODO Mock -Command Write-Warning -ModuleName Item

            $itemGroups = @(
               @{Group1 = @( @{Name = '*'; Condition = $true } ) }
               @{Group1 = @(
                     @{Name = '*'; Condition = ($false) }
                     @{Name = 'Item' }
                  )
               }
            )

            $expandedItemGroups = $itemGroups | Expand-ItemGroup

            $expectedItemGroups = @{ Group1 = @( ConvertTo-Item @{Name = 'Item'; Condition = $false } ) }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroups -DifferenceItemGroup $expandedItemGroups -Verbose | Should -BeNullOrEmpty

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'Items of ItemGroup ''Group1'' have been redefined.' }
            # TODO Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'Item ''*'' has been defined multiple times.' }
         }
         It 'Flattens vector items.' {
            $itemGroups = @(
               @{ Group1 = @( @{Path = @('Item1', 'Item2', 'Item3') ; Condition = $true } ) }
            )

            $expandedItemGroups = $itemGroups | Expand-ItemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Name = 'Item1'; Path = 'Item1'; Condition = $true }
                  ConvertTo-Item @{Name = 'Item2'; Path = 'Item2'; Condition = $true }
                  ConvertTo-Item @{Name = 'Item3'; Path = 'Item3'; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroups | Should -BeNullOrEmpty
         }
         It 'Flattens vector items and merges default item''s properties.' {
            $itemGroups = @{ Group1 = @(
                  @{Name = '*'; Condition = $false; Extra = 'Dummy' }
                  @{Path = @('Item1', 'Item2', 'Item3') ; Condition = $true }
               )
            }

            $expandedItemGroups = $itemGroups | Expand-ItemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Name = 'Item1'; Path = 'Item1'; Condition = $true; Extra = 'Dummy' }
                  ConvertTo-Item @{Name = 'Item2'; Path = 'Item2'; Condition = $true; Extra = 'Dummy' }
                  ConvertTo-Item @{Name = 'Item3'; Path = 'Item3'; Condition = $true; Extra = 'Dummy' }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroups | Should -BeNullOrEmpty
         }
         It 'Merges default item''s properties in every item.' {
            $itemGroup = @{
               Group1 = @(
                  @{Name = '*'; Condition = $false }
                  @{Name = 'Item11' }
                  @{Name = 'Item12'; Condition = $true }
               )
            }

            $expandedItemGroup = $itemGroup | Expand-ItemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Name = 'Item11'; Condition = $false }
                  ConvertTo-Item @{Name = 'Item12'; Condition = $true }
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Informs about progress.' {
            $itemGroup = @{
               ApplicationBindings = @(@{Path = 'a'; Condition = $false })
               Schemas             = @(@{Path = 's'; Condition = $false })
               Transforms          = @(@{Path = 't'; Condition = $false })
               Orchestrations      = @(@{Path = 'o'; Condition = $false })
            }

            $itemGroup | Expand-ItemGroup

            Assert-MockCalled -Scope It -CommandName Write-Information -Times 4 # has been called only four times
            Assert-MockCalled -Scope It -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''ApplicationBindings''.' }
            Assert-MockCalled -Scope It -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Schemas''.' }
            Assert-MockCalled -Scope It -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Transforms''.' }
            Assert-MockCalled -Scope It -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Orchestrations''.' }
         }
      }

      Context 'Fails when file location denoted by Item.Path is not found.' {
         Mock -Command Write-Information # avoid cluttering Pester output
         Mock -Command Write-Warning # avoid cluttering Pester output
         It 'Throws on the first item that is not found.' {
            $itemGroup = @{ Group1 = @(@{Path = 'not-found-item-1.dll' }, @{Path = 'not-found-item-2.exe' }) }

            { Expand-ItemGroup -ItemGroup $itemGroup } | Should -Throw -ExpectedMessage 'not-found-item-1.dll' -ErrorId 'PathNotFound,Microsoft.PowerShell.Commands.ResolvePathCommand'
         }
      }
   }
}
