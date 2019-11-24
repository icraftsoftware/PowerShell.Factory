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

Import-Module ItemGroup\Item -Force

Describe 'ConvertTo-Item' {
   InModuleScope Item {

      Context 'When input is a plain old hashtable' {
         It 'Returns a plain old custom object with no script property.' {
            $hashTable = @{ FirstName = 'Tony'; LastName = 'Stark' }
            $object = ConvertTo-Item -HashTable $hashTable
            $object | Should -BeOfType [PSCustomObject]
            $object | Get-Member -Name FirstName | Select-Object -ExpandProperty MemberType | Should -Be ([System.Management.Automation.PSMemberTypes]::NoteProperty)
            $object | Get-Member -Name LastName | Select-Object -ExpandProperty MemberType | Should -Be ([System.Management.Automation.PSMemberTypes]::NoteProperty)
         }
      }

      Context 'When input is a hashtable with a script block' {
         It 'Returns a plain old custom object with a script property.' {
            $hashTable = @{ FirstName = 'Tony'; LastName = 'Stark'; DisplayName = { "{0} {1}" -f $this.FirstName, $this.LastName } }
            $object = ConvertTo-Item -HashTable $hashTable
            $object | Should -BeOfType [PSCustomObject]
            $object | Get-Member -Name DisplayName | Select-Object -ExpandProperty MemberType | Should -Be ([System.Management.Automation.PSMemberTypes]::ScriptProperty)
            $object.DisplayName | Should -Be 'Tony Stark'
         }
      }

      Context 'When inputs are given by argument' {
         It 'Returns $null for an empty hashtable.' {
            ConvertTo-Item -HashTable @{ } | Should -Be $null
         }
         It 'Returns $null for an empty array.' {
            $hashTables = @()
            ConvertTo-Item -HashTable $hashTables | Should -Be $null
         }
         It 'Returns $null for an array of empty hashtables.' {
            $hashTables = @( @{ } , @{ } )
            ConvertTo-Item -HashTable $hashTables | Should -Be $null
         }
         It 'Converts an array of hastables.' {
            $hashTables = @(
               @{FirstName = 'Tony'; LastName = 'Stark' }
               @{FirstName = 'Peter'; LastName = 'Parker' }
            )

            $items = ConvertTo-Item -HashTable $hashTables

            $expectedItems = @(
               [PSCustomObject]@{ FirstName = 'Tony'; LastName = 'Stark' }
               [PSCustomObject]@{ FirstName = 'Peter'; LastName = 'Parker' }
            )
            $items.Count | Should -Be 2
            Compare-Item -ReferenceItem $expectedItems[0] -DifferenceItem $items[0] | Should -BeNullOrEmpty
            Compare-Item -ReferenceItem $expectedItems[1] -DifferenceItem $items[1] | Should -BeNullOrEmpty
         }
         It 'Skips empty hashtables.' {
            $hashTables = @(
               @{ FirstName = 'Tony'; LastName = 'Stark' }
               @{ }, @{ }
               @{ FirstName = 'Peter'; LastName = 'Parker' }
               @{ }
            )

            $items = ConvertTo-Item -HashTable $hashTables

            $expectedItems = @(
               [PSCustomObject]@{ FirstName = 'Tony'; LastName = 'Stark' }
               [PSCustomObject]@{ FirstName = 'Peter'; LastName = 'Parker' }
            )
            $items.Count | Should -Be 2
            Compare-Item -ReferenceItem $expectedItems[0] -DifferenceItem $items[0] | Should -BeNullOrEmpty
            Compare-Item -ReferenceItem $expectedItems[1] -DifferenceItem $items[1] | Should -BeNullOrEmpty
         }
      }

      Context 'When inputs are given by pipeline' {
         It 'Returns $null for empty hashtable.' {
            @{ } | ConvertTo-Item | Should -Be $null
         }
         It 'Returns $null for an empty array.' {
            @() | ConvertTo-Item | Should -Be $null
         }
         It 'Returns $null for an array of empty hashtables.' {
            @( @{ } , @{ } ) | ConvertTo-Item | Should -Be $null
         }
         It 'Converts an array of hastables.' {
            $hashTables = @(
               @{ FirstName = 'Tony'; LastName = 'Stark' }
               @{ FirstName = 'Peter'; LastName = 'Parker' }
            )

            $items = $hashTables | ConvertTo-Item

            $expectedItems = @(
               [PSCustomObject]@{ FirstName = 'Tony'; LastName = 'Stark' }
               [PSCustomObject]@{ FirstName = 'Peter'; LastName = 'Parker' }
            )
            $items.Count | Should -Be 2
            Compare-Item -ReferenceItem $expectedItems[0] -DifferenceItem $items[0] | Should -BeNullOrEmpty
            Compare-Item -ReferenceItem $expectedItems[1] -DifferenceItem $items[1] | Should -BeNullOrEmpty
         }
         It 'Skips empty hashtables.' {
            $hashTables = @(
               @{ FirstName = 'Tony'; LastName = 'Stark' }
               @{ }, @{ }
               @{ FirstName = 'Peter'; LastName = 'Parker' }
               @{ }
            )

            $items = $hashTables | ConvertTo-Item

            $expectedItems = @(
               [PSCustomObject]@{ FirstName = 'Tony'; LastName = 'Stark' }
               [PSCustomObject]@{ FirstName = 'Peter'; LastName = 'Parker' }
            )
            $items.Count | Should -Be 2
            Compare-Item -ReferenceItem $expectedItems[0] -DifferenceItem $items[0] | Should -BeNullOrEmpty
            Compare-Item -ReferenceItem $expectedItems[1] -DifferenceItem $items[1] | Should -BeNullOrEmpty
         }
      }

   }
}
