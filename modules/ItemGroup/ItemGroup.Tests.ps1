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

# Describe 'Import-ItemGroup' {
#    InModuleScope ItemGroup {
#    }
# }

# Describe 'Merge-ItemGroup' {
#    InModuleScope ItemGroup {
#    }
# }

Describe 'Compare-ItemGroup' {
   InModuleScope ItemGroup {
      Context 'When both ItemGroups are empty' {
         It "should return nothing." {
            $left = @{}
            $right = @{}
            Compare-ItemGroup $left $right | Should -BeNullOrEmpty
         }
      }
      Context "When both ItemGroups have different groups" {
         It "should return Group1: < and Group2: >." {
            $left = @{Group1 = @()}
            $right = @{Group2 = @()}

            [object[]]$result = Compare-ItemGroup $left $right

            $result.Length | Should -Be 2
            $result[0].Key | Should -Be 'Group1'
            $result[0].ReferenceValue | Should -BeNullOrEmpty
            $result[0].SideIndicator | Should -Be "<"
            $result[0].DifferenceValue | Should -BeNullOrEmpty
            $result[1].Key | Should -Be 'Group2'
            $result[1].ReferenceValue | Should -BeNullOrEmpty
            $result[1].SideIndicator | Should -Be ">"
            $result[1].DifferenceValue | Should -BeNullOrEmpty
         }
      }
      Context "When both ItemGroups have no item" {
         It "should return nothing." {
            $left = @{Group1 = @()}
            $right = @{Group1 = @()}
            Compare-ItemGroup $left $right | Should -BeNullOrEmpty
         }
      }
      Context "When both ItemGroups have one identical item" {
         It "should return nothing." {
            $left = @{Group1 = @(ConvertTo-Item @{Path = 'Item'})}
            $right = @{Group1 = @(ConvertTo-Item @{Path = 'Item'})}
            Compare-ItemGroup $left $right | Should -BeNullOrEmpty
         }
      }
      Context "When both ItemGroups have one partially different item" {
         It "should return nothing." {
            $left = @{Group1 = @(ConvertTo-Item @{Path = 'Item1'; Condition = $true})}
            $right = @{Group1 = @(ConvertTo-Item @{Path = 'Item2'; Condition = $true})}

            [object[]]$result = Compare-ItemGroup $left $right

            $result.Length | Should -Be 1
            $result.Key | Should -Be 'Group1[0].Path'
            $result.ReferenceValue | Should -Be 'Item1'
            $result.SideIndicator | Should -Be "<>"
            $result.DifferenceValue | Should -Be 'Item2'
         }
      }
      Context "When one reference ItemGroup has an item more than the other" {
         It "should return nothing." {
            $left = @{Group1 = @(ConvertTo-Item @{Path = 'Item'})}
            $right = @{Group1 = @()}

            [object[]]$result = Compare-ItemGroup $left $right

            $result.Length | Should -Be 1
            $result.Key | Should -Be 'Group1[0]'
            $result.ReferenceValue | Should -Be '@{Path=Item}'
            $result.SideIndicator | Should -Be "<"
            $result.DifferenceValue | Should -BeNullOrEmpty
         }
      }
      Context "When one difference ItemGroup has an item more than the other" {
         It "should return nothing." {
            $left = @{Group1 = @()}
            $right = @{Group1 = @(ConvertTo-Item @{Path = 'Item'})}

            [object[]]$result = Compare-ItemGroup $left $right

            $result.Length | Should -Be 1
            $result.Key | Should -Be 'Group1[0]'
            $result.ReferenceValue | Should -BeNullOrEmpty
            $result.SideIndicator | Should -Be ">"
            $result.DifferenceValue | Should -Be '@{Path=Item}'
         }
      }
   }
}

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

Describe 'Test-ItemGroup' {
   InModuleScope ItemGroup {
      Context 'When ItemGroups are given by arguments' {
         Mock Write-Warning
         It 'Has no duplicate.' {
            $itemGroup = @( @{One = @(@{})}, @{Two = @(@{})} )

            Test-ItemGroup -ItemGroup $itemGroup -Unique

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Warns about each duplicate item group.' {
            $itemGroup = @( @{One = @(@{})}, @{One = @(@{})} )

            Test-ItemGroup -ItemGroup $itemGroup -Unique

            Assert-MockCalled Write-Warning -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''One'' has been defined multiple times.' } -Times 1
         }
         It 'Warns about each duplicate item across arrays.' {
            $itemGroups = @(
               @( @{One = @(@{})}, @{Two = @(@{})} )
               @( @{One = @(@{})}, @{Two = @(@{})} )
            )
            Test-ItemGroup -ItemGroup $itemGroups -Unique

            Assert-MockCalled Write-Warning -Times 2
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''Two'' has been defined multiple times.' } -Times 1
         }
      }
      Context 'When ItemGroups are given by pipeline' {
         Mock Write-Warning
         It 'Has no duplicate.' {
            $itemGroup = @( @{One = @(@{})}, @{Two = @(@{})} )

            $itemGroup | Test-ItemGroup -Unique
         }
         It 'Warns about each duplicate item group.' {
            $itemGroup = @( @{One = @(@{})}, @{One = @(@{})} )

            $itemGroup | Test-ItemGroup -Unique

            Assert-MockCalled Write-Warning -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''One'' has been defined multiple times.' } -Times 1
         }
         It 'Warns about each duplicate item across arrays.' {
            $itemGroups = @(
               @( @{One = @(@{})}, @{Two = @(@{})} )
               @( @{One = @(@{})}, @{Two = @(@{})} )
            )
            $itemGroups | Test-ItemGroup -Unique

            Assert-MockCalled Write-Warning -Times 2 # has been called only once
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''Two'' has been defined multiple times.' } -Times 1
         }
      }
   }
}

Describe 'Compare-Item' {
   InModuleScope ItemGroup {
      Context "When both items are $null" {
         It "should return nothing." {
            Compare-Item $null $null | Should -BeNullOrEmpty
         }
      }
      Context "When both items have one identical entry" {
         It "should return nothing." {
            $left = ConvertTo-Item @{a = "x"}
            $right = ConvertTo-Item @{a = "x"}
            Compare-Item $left $right | Should -BeNullOrEmpty
         }
      }
      Context "When reference item contains a key with a null value" {
         It "should return a <." {
            $left = ConvertTo-Item @{a = $null}
            $right = ConvertTo-Item @{}

            [object[]]$result = Compare-Item $left $right

            $result.Length | Should -Be 1
            $result.Key | Should -Be 'a'
            $result.ReferenceValue | Should -Be $null
            $result.SideIndicator | Should -Be "<"
            $result.DifferenceValue | Should -Be $null
         }
      }
      Context "When difference item contains a key with a null value" {
         It "should return a >." {
            $left = ConvertTo-Item @{}
            $right = ConvertTo-Item @{a = $null}

            [object[]]$result = Compare-Item $left $right

            $result.Length | Should -Be 1
            $result.Key | Should -Be 'a'
            $result.ReferenceValue | Should -Be $null
            $result.SideIndicator | Should -Be ">"
            $result.DifferenceValue | Should -Be $null
         }
      }
   }
}

Describe 'ConvertTo-Item' {
   InModuleScope ItemGroup {
      It 'Converts a hash table with script block to a custom object with script property.' {
         $hashTable = @{FirstName = 'Tony'; LastName = 'Stark'; DisplayName = {"{0} {1}" -f $this.FirstName, $this.LastName}}
         $object = ConvertTo-Item -HashTable $hashTable
         $object | Should -BeOfType [PSCustomObject]
         $object | Get-Member -Name DisplayName | Select-Object -ExpandProperty MemberType | Should -Be ([System.Management.Automation.PSMemberTypes]::ScriptProperty)
         $object.DisplayName | Should -Be 'Tony Stark'
      }
      It 'Converts a hash table without script block to a custom object without script property.' {
         $hashTable = @{FirstName = 'Tony'; LastName = 'Stark'}
         $object = ConvertTo-Item -HashTable $hashTable
         $object | Should -BeOfType [PSCustomObject]
         $object | Get-Member -Name FirstName | Select-Object -ExpandProperty MemberType | Should -Be ([System.Management.Automation.PSMemberTypes]::NoteProperty)
         $object | Get-Member -Name LastName | Select-Object -ExpandProperty MemberType | Should -Be ([System.Management.Automation.PSMemberTypes]::NoteProperty)
      }
      Context 'When inputs are given by argument' {
         It 'Returns $null for empty hashtable.' {
            ConvertTo-Item -HashTable @{} | Should -Be $null
         }
         It 'Returns $null for an empty array.' {
            $hashTables = @()
            ConvertTo-Item -HashTable $hashTables | Should -Be $null
         }
         It 'Returns $null for an array of empty hashtables.' {
            $hashTables = @( @{} , @{} )
            ConvertTo-Item -HashTable $hashTables | Should -Be $null
         }
         It 'Converts an array of hastables.' {
            $hashTables = @(
               @{FirstName = 'Tony'; LastName = 'Stark'}
               @{FirstName = 'Peter'; LastName = 'Parker'}
            )

            $items = ConvertTo-Item -HashTable $hashTables

            $expectedItems = @(
               [PSCustomObject]@{FirstName = 'Tony'; LastName = 'Stark'}
               [PSCustomObject]@{FirstName = 'Peter'; LastName = 'Parker'}
            )
            $items.Count | Should -Be 2
            Compare-Item -ReferenceItem $expectedItems[0] -DifferenceItem $items[0] | Should -BeNullOrEmpty
            Compare-Item -ReferenceItem $expectedItems[1] -DifferenceItem $items[1] | Should -BeNullOrEmpty
         }
         It 'Skips empty hashtables.' {
            $hashTables = @(
               @{FirstName = 'Tony'; LastName = 'Stark'}
               @{} , @{}
               @{FirstName = 'Peter'; LastName = 'Parker'}
            )

            $items = ConvertTo-Item -HashTable $hashTables

            $expectedItems = @(
               [PSCustomObject]@{FirstName = 'Tony'; LastName = 'Stark'}
               [PSCustomObject]@{FirstName = 'Peter'; LastName = 'Parker'}
            )
            $items.Count | Should -Be 2
            Compare-Item -ReferenceItem $expectedItems[0] -DifferenceItem $items[0] | Should -BeNullOrEmpty
            Compare-Item -ReferenceItem $expectedItems[1] -DifferenceItem $items[1] | Should -BeNullOrEmpty
         }
      }
      Context 'When inputs are given by pipeline' {
         It 'Returns $null for empty hashtable.' {
            @{} | ConvertTo-Item | Should -Be $null
         }
         It 'Returns $null for an empty array.' {
            @() | ConvertTo-Item | Should -Be $null
         }
         It 'Returns $null for an array of empty hashtables.' {
            @( @{} , @{} ) | ConvertTo-Item | Should -Be $null
         }
         It 'Converts an array of hastables.' {
            $hashTables = @(
               @{FirstName = 'Tony'; LastName = 'Stark'}
               @{FirstName = 'Peter'; LastName = 'Parker'}
            )

            $items = $hashTables | ConvertTo-Item

            $expectedItems = @(
               [PSCustomObject]@{FirstName = 'Tony'; LastName = 'Stark'}
               [PSCustomObject]@{FirstName = 'Peter'; LastName = 'Parker'}
            )
            $items.Count | Should -Be 2
            Compare-Item -ReferenceItem $expectedItems[0] -DifferenceItem $items[0] | Should -BeNullOrEmpty
            Compare-Item -ReferenceItem $expectedItems[1] -DifferenceItem $items[1] | Should -BeNullOrEmpty
         }
      }
   }
}

Describe 'Resolve-DefaultItem' {
   InModuleScope ItemGroup {
      It 'Returns an empty default item if there are no default item.' {
         $hashTables = @( @{Path = 'fn'; FirstName = 'Tony'}, @{Path = 'ln'; LastName = 'Stark'}, @{Path = 'dn'; DisplayName = 'Tony Stark'}, @{Path = 'an'; Alias = 'Iron Man'} )

         $defaultItem = Resolve-DefaultItem -ItemGroup $hashTables

         $expectedResult = @{}
         Compare-HashTable -ReferenceHashTable $expectedResult -DifferenceHashTable $defaultItem | Should -BeNullOrEmpty
      }
      It 'Merges all default items.' {
         $hashTables = @( @{Path = '*'; FirstName = 'Tony'}, @{Path = '*'; LastName = 'Stark'}, @{Path = 'dn'; DisplayName = 'Tony Stark'}, @{Path = 'an'; Alias = 'Iron Man'} )

         $defaultItem = Resolve-DefaultItem -ItemGroup $hashTables

         $expectedResult = @{Path = '*'; FirstName = 'Tony'; LastName = 'Stark'}
         Compare-HashTable -ReferenceHashTable $expectedResult -DifferenceHashTable $defaultItem | Should -BeNullOrEmpty
      }
      It 'Overwrites common properties when merging all default items.' {
         $hashTables = @( @{Path = '*'; FirstName = 'Peter'}, @{Path = '*'; FirstName = 'Tony'; LastName = 'Stark'}, @{Path = 'dn'; DisplayName = 'Tony Stark'}, @{Path = 'an'; Alias = 'Iron Man'} )

         $defaultItem = Resolve-DefaultItem -ItemGroup $hashTables

         $expectedResult = @{Path = '*'; FirstName = 'Tony'; LastName = 'Stark'}
         Compare-HashTable -ReferenceHashTable $expectedResult -DifferenceHashTable $defaultItem | Should -BeNullOrEmpty
      }
   }
}

Describe 'Test-Item-Unique' {
   InModuleScope ItemGroup {
      Context 'When Items are given by arguments' {
         Mock Write-Warning
         It 'Does not trace an empty array.' {
            $item = @()

            Test-Item -Item $item -Unique

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Does not trace an array of empty arrays.' {
            $items = @( @(), @() )

            Test-Item -Item $items -Unique

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Does not trace an array of empty hashtables.' {
            $items = @( @{}, @{} )

            Test-Item -Item $items -Unique

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Does not trace an array of arrays of empty hashtables.' {
            $items = @( @( @{}, @{} ) , @( @{}, @{} ) )

            Test-Item -Item $items -Unique

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Does not trace an array of empty Items.' {
            $items = @( (ConvertTo-Item @{}) , (ConvertTo-Item @{}) )

            Test-Item -Item $items -Unique

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Does not trace an array of arrays of empty Items.' {
            $items = @( @( @{}, @{} ) , @( @{}, @{} ) )

            Test-Item -Item $items -Unique

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Has no duplicate.' {
            $item = @( @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'Three'} )

            Test-Item -Item $item -Unique

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Warns about each duplicate item in array.' {
            $item = @( @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'Three'} )

            Test-Item -Item $item -Unique

            Assert-MockCalled Write-Warning -Times 2
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''Two'' has been defined multiple times.' } -Times 1
         }
         It 'Warns about each duplicate item across arrays.' {
            $items = @(
               @( @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'One'} )
               @( @{Path = 'Two'}, @{Path = 'Three'} )
            )

            Test-Item -Item $items -Unique

            Assert-MockCalled Write-Warning -Times 2
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''Two'' has been defined multiple times.' } -Times 1
         }
      }
      Context 'When Items are given by pipeline' {
         Mock Write-Warning
         It 'Does not trace an empty array.' {
            $item = @()

            $item | Test-Item -Unique

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Has no duplicate.' {
            $item = @( @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'Three'} )

            $item | Test-Item -Unique

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Warns about each duplicate item in array.' {
            $item = @( @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'Three'} )

            $item | Test-Item -Unique

            Assert-MockCalled Write-Warning -Times 2
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''Two'' has been defined multiple times.' } -Times 1
         }
         It 'Warns about each duplicate item across arrays.' {
            $items = @(
               @( @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'One'} )
               @( @{Path = 'Two'}, @{Path = 'Three'} )
            )

            $items | Test-Item -Unique

            Assert-MockCalled Write-Warning -Times 2
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''Two'' has been defined multiple times.' } -Times 1
         }
      }
   }
}

Describe 'Test-Item-Property' {
   InModuleScope ItemGroup {
      It 'Is false for empty hashtable.' {
         @{} | Test-Item -Property 'Condition' | Should -Be $false
      }
      It 'Is false for an array of empty hashtables.' {
         @( @{} , @{} ) | Test-Item -Property 'Condition' | Should -Be @($false, $false)
      }
      It 'Is false for hashtable.' {
         @{Path = 1} | Test-Item -Property 'Condition' | Should -Be $false
      }
      It 'Is true for hashtable.' {
         @{Condition = $null} | Test-Item -Property 'Condition' | Should -Be $true
      }
      It 'Is false for empty custom object.' {
         ([pscustomobject]@{}) | Test-Item -Property 'Condition' | Should -Be $false
      }
      It 'Is false for an array of empty custom objects.' {
         @( [pscustomobject]@{} , [pscustomobject]@{} ) | Test-Item -Property 'Condition' | Should -Be @($false, $false)
      }
      It 'Is false for custom object.' {
         ([pscustomobject]@{Path = 1}) | Test-Item -Property 'Condition' | Should -Be $false
      }
      It 'Is true for custom object.' {
         ([pscustomobject]@{Condition = $null}) | Test-Item -Property 'Condition' | Should -Be $true
      }
   }
}

Describe 'Test-Item-IsValid' {
   InModuleScope ItemGroup {
      It 'Is false for $null.' {
         $null | Test-Item -IsValid | Should -Be $false
      }
      It 'Is false for an empty hashtable.' {
         @{} | Test-Item -IsValid | Should -Be $false
      }
      It 'Is false for an empty custom object.' {
         ([pscustomobject]@{}) | Test-Item -IsValid | Should -Be $false
      }
      It 'Is false for an empty array.' {
         @() | Test-Item -IsValid | Should -Be $false
      }
      It 'Is false for an array of empty hashtables.' {
         @( @{} , @{} ) | Test-Item -IsValid | Should -Be $false
      }
      It 'Is false for an array of empty custom objects.' {
         @( ([pscustomobject]@{}) , ([pscustomobject]@{}) ) | Test-Item -IsValid | Should -Be $false
      }
      It 'Is true for a hashtable with property.' {
         @{x = $null} | Test-Item -IsValid | Should -Be $true
      }
      It 'Is true for a custom object with property.' {
         ([pscustomobject]@{x = $null}) | Test-Item -IsValid | Should -Be $true
      }
      It 'Is true for an array with one non-empty hashtable.' {
         @( @{x = $null} , @{} ) | Test-Item -IsValid | Should -Be $true
      }
      It 'Is true for an array with one non-empty custom object.' {
         @( ([pscustomobject]@{x = $null}) , ([pscustomobject]@{}) ) | Test-Item -IsValid | Should -Be $true
      }
      It 'Accepts arguments of mixed hashtable and custom object items' {
         Test-Item -IsValid -Item @( @{x = $null} , ([pscustomobject]@{x = $null}) ) | Should -Be $true
      }
   }
}
