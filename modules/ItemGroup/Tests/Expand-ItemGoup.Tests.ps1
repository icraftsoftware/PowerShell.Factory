#region Copyright & License

# Copyright © 2012 - 2018 François Chabot
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

Import-Module ItemGroup -Force

Describe 'Expand-ItemGroup' {
   InModuleScope ItemGroup {
      Context 'When ItemGroups are given by arguments.' {
         Mock Write-Information # avoid cluttering Pester output
         Mock Write-Warning # avoid cluttering Pester output
         Mock Resolve-Path -MockWith { [PSCustomObject]@{ ProviderPath = $Path } }
         It 'Expands an empty ItemGroup.' {
            $itemGroup = @{}
            Expand-ItemGroup -ItemGroup $itemGroup | Should -BeNullOrEmpty
         }
         It 'Expands an ItemGroup made only of a default item.' {
            $itemGroup = @{
               Group1 = @(
                  @{Path = '*'; Condition = ($false)}
               )
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $itemGroup

            $expectedItemGroup = @{ Group1 = @() }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Expands one ItemGroup.' {
            $itemGroup = @{
               Group1 = @(
                  @{Path = 'Item11'}
                  @{Path = 'Item12'; Condition = $true}
               )
               Group2 = @(
                  @{Path = 'Item21'}
                  @{Path = 'Item22'; Condition = $true}
               )
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $itemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Path = 'Item11'}
                  ConvertTo-Item @{Path = 'Item12'; Condition = $true}
               )
               Group2 = @(
                  ConvertTo-Item @{Path = 'Item21'}
                  ConvertTo-Item @{Path = 'Item22'; Condition = $true}
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Expands several ItemGroups.' {
            $itemGroups = @(
               @{ Group1 = @( @{Path = 'Item11'} , @{Path = 'Item12'; Condition = $true} ) }
               @{ Group2 = @( @{Path = 'Item21'} , @{Path = 'Item22'; Condition = $true} ) }
            )

            $expandedItemGroups = Expand-ItemGroup -ItemGroup $itemGroups

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Path = 'Item11'}
                  ConvertTo-Item @{Path = 'Item12'; Condition = $true}
               )
               Group2 = @(
                  ConvertTo-Item @{Path = 'Item21'}
                  ConvertTo-Item @{Path = 'Item22'; Condition = $true}
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroups | Should -BeNullOrEmpty
         }
         It 'Merges default item''s properties in every item.' {
            $itemGroup = @{
               Group1 = @(
                  @{Path = '*'; Condition = $false}
                  @{Path = 'Item11'}
                  @{Path = 'Item12'; Condition = $true}
               )
            }

            $expandedItemGroup = Expand-ItemGroup -ItemGroup $itemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Path = 'Item11'; Condition = $false}
                  ConvertTo-Item @{Path = 'Item12'; Condition = $true}
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Expands duplicate ItemGroup whose one is made only of a default item.' {
            $itemGroups = @(
               @{Group1 = @( @{Path = '*'; Condition = $true} ) }
               @{Group1 = @(
                     @{Path = '*'; Condition = ($false)}
                     @{Path = 'Item'}
                  )
               }
            )

            $expandedItemGroups = Expand-ItemGroup -ItemGroup $itemGroups

            $expectedItemGroups = @{ Group1 = @( ConvertTo-Item @{Path = 'Item'; Condition = $false} ) }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroups -DifferenceItemGroup $expandedItemGroups -Verbose | Should -BeNullOrEmpty
         }
         It 'Informs about progress.' {
            $itemGroups = @(
               @{ ApplicationBindings = @(@{Path = 'a'; Condition = $false}) }
               @{ Schemas = @(@{Path = 's'; Condition = $false}) }
               @{ Transforms = @(@{Path = 't'; Condition = $false}) }
               @{ Orchestrations = @(@{Path = 'o'; Condition = $false}) }
            )

            Expand-ItemGroup -ItemGroup $itemGroups

            Assert-MockCalled Write-Information -Times 4 # has been called only twice
            Assert-MockCalled Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''ApplicationBindings''.' } -Times 1
            Assert-MockCalled Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Schemas''.' } -Times 1
            Assert-MockCalled Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Transforms''.' } -Times 1
            Assert-MockCalled Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Orchestrations''.' } -Times 1
         }
         It 'Traces ItemGroup duplicates.' {
            $itemGroups = @(
               @{ ApplicationBindings = @(@{Path = 'a'; Condition = $false}) }
               @{ ApplicationBindings = @(@{Path = 'a'; Condition = $false}) }
            )

            Expand-ItemGroup -ItemGroup $itemGroups

            Assert-MockCalled Write-Warning -Times 2 # has been called only once
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''ApplicationBindings'' has been defined multiple times.' } -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Items of ItemGroup ''ApplicationBindings'' have been redefined.' } -Times 1
         }
         It 'Traces item duplicates.' {
            $itemGroup = @{
               ApplicationBindings = @(
                  @{Path = 'a'; Condition = $false}
                  @{Path = 'a'; Condition = $false}
               )
            }

            Expand-ItemGroup -ItemGroup $itemGroup

            Assert-MockCalled Write-Warning -Times 1 # has been called only once
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''a'' has been defined multiple times.' } -Times 1
         }
         It 'Warns about every redefined ItemGroup.' {
            $itemGroups = @(
               @{ ApplicationBindings = @(@{Path = 'a'; Condition = $false}) }
               @{ ApplicationBindings = @(@{Path = 'a'; Condition = $false}) }
            )

            Expand-ItemGroup -ItemGroup $itemGroups

            Assert-MockCalled Write-Warning -Times 1 # has been called only once
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Items of ItemGroup ''ApplicationBindings'' have been redefined.' } -Times 1
         }
      }
      Context 'When ItemGroups are given by pipeline.' {
         Mock Write-Information # avoid cluttering Pester output
         Mock Write-Warning # avoid cluttering Pester output
         Mock Resolve-Path -MockWith { [PSCustomObject]@{ ProviderPath = $Path } }
         It 'Expands one ItemGroup.' {
            $itemGroup = @{
               Group1 = @(
                  @{Path = 'Item11'}
                  @{Path = 'Item12'; Condition = $true}
               )
               Group2 = @(
                  @{Path = 'Item21'}
                  @{Path = 'Item22'; Condition = $true}
               )
            }

            $expandedItemGroup = $itemGroup | Expand-ItemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Path = 'Item11'}
                  ConvertTo-Item @{Path = 'Item12'; Condition = $true}
               )
               Group2 = @(
                  ConvertTo-Item @{Path = 'Item21'}
                  ConvertTo-Item @{Path = 'Item22'; Condition = $true}
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Expands an ItemGroup made only of a default item.' {
            $itemGroup = @{
               Group1 = @(
                  @{Path = '*'; Condition = ($false)}
               )
            }

            $expandedItemGroup = $itemGroup | Expand-ItemGroup

            $expectedItemGroup = @{ Group1 = @() }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Expands serveral ItemGroups.' {
            $itemGroups = @(
               @{ Group1 = @( @{Path = 'Item11'} , @{Path = 'Item12'; Condition = $true} ) }
               @{ Group2 = @( @{Path = 'Item21'} , @{Path = 'Item22'; Condition = $true} ) }
            )

            $expandedItemGroups = $itemGroups | Expand-ItemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Path = 'Item11'}
                  ConvertTo-Item @{Path = 'Item12'; Condition = $true}
               )
               Group2 = @(
                  ConvertTo-Item @{Path = 'Item21'}
                  ConvertTo-Item @{Path = 'Item22'; Condition = $true}
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroups | Should -BeNullOrEmpty

         }
         It 'Expands duplicate ItemGroup whose one is made only of a default item.' {
            $itemGroups = @(
               @{Group1 = @( @{Path = '*'; Condition = $true} ) }
               @{Group1 = @(
                     @{Path = '*'; Condition = ($false)}
                     @{Path = 'Item'}
                  )
               }
            )

            $expandedItemGroups = $itemGroups | Expand-ItemGroup

            $expectedItemGroups = @{ Group1 = @( ConvertTo-Item @{Path = 'Item'; Condition = $false} ) }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroups -DifferenceItemGroup $expandedItemGroups -Verbose | Should -BeNullOrEmpty
         }
         It 'Flattens vector items.' {
            $itemGroups = @(
               @{ Group1 = @( @{Path = @('Item1', 'Item2', 'Item3') ; Condition = $true} ) }
            )

            $expandedItemGroups = $itemGroups | Expand-ItemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Path = 'Item1'; Condition = $true}
                  ConvertTo-Item @{Path = 'Item2'; Condition = $true}
                  ConvertTo-Item @{Path = 'Item3'; Condition = $true}
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroups | Should -BeNullOrEmpty
         }
         It 'Flattens vector items and merges default item''s properties.' {
            $itemGroups = @{ Group1 = @(
                  @{Path = '*'; Condition = $false; Extra = 'Dummy'}
                  @{Path = @('Item1', 'Item2', 'Item3') ; Condition = $true}
               )
            }

            $expandedItemGroups = $itemGroups | Expand-ItemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Path = 'Item1'; Condition = $true; Extra = 'Dummy'}
                  ConvertTo-Item @{Path = 'Item2'; Condition = $true; Extra = 'Dummy'}
                  ConvertTo-Item @{Path = 'Item3'; Condition = $true; Extra = 'Dummy'}
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroups | Should -BeNullOrEmpty
         }
         It 'Merges default item''s properties in every item.' {
            $itemGroup = @{
               Group1 = @(
                  @{Path = '*'; Condition = $false}
                  @{Path = 'Item11'}
                  @{Path = 'Item12'; Condition = $true}
               )
            }

            $expandedItemGroup = $itemGroup | Expand-ItemGroup

            $expectedItemGroup = @{
               Group1 = @(
                  ConvertTo-Item @{Path = 'Item11'; Condition = $false}
                  ConvertTo-Item @{Path = 'Item12'; Condition = $true}
               )
            }
            Compare-ItemGroup -ReferenceItemGroup $expectedItemGroup -DifferenceItemGroup $expandedItemGroup | Should -BeNullOrEmpty
         }
         It 'Informs about progress.' {
            $itemGroup = @{
               ApplicationBindings = @(@{Path = 'a'; Condition = $false})
               Schemas             = @(@{Path = 's'; Condition = $false})
               Transforms          = @(@{Path = 't'; Condition = $false})
               Orchestrations      = @(@{Path = 'o'; Condition = $false})
            }

            $itemGroup | Expand-ItemGroup

            Assert-MockCalled Write-Information -Times 4 # has been called only four times
            Assert-MockCalled Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''ApplicationBindings''.' } -Times 1
            Assert-MockCalled Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Schemas''.' } -Times 1
            Assert-MockCalled Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Transforms''.' } -Times 1
            Assert-MockCalled Write-Information -ParameterFilter { $MessageData -eq 'Expanding ItemGroup ''Orchestrations''.' } -Times 1
         }
      }
      Context 'Fails when Item.Path is not foumd.' {
         Mock Write-Information # avoid cluttering Pester output
         Mock Write-Warning # avoid cluttering Pester output
         It 'Throws on the first item that is not found.' {
            $itemGroup = @{ Group1 = @(@{Path = 'not-found-item-1.dll'}, @{Path = 'not-found-item-2.exe'}) }

            { Expand-ItemGroup -ItemGroup $itemGroup } | Should -Throw -ExpectedMessage 'not-found-item-1.dll' -ErrorId 'PathNotFound,Microsoft.PowerShell.Commands.ResolvePathCommand'
         }
      }
   }
}
