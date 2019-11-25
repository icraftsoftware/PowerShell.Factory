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

Describe 'Resolve-DefaultItem' {
   InModuleScope Group {
      It 'Returns an empty default Item if there are no default Item.' {
         $hashTables = @(
            @{ Name = 'fn'; FirstName = 'Tony' },
            @{ Name = 'ln'; LastName = 'Stark' },
            @{ Name = 'dn'; DisplayName = 'Tony Stark' },
            @{ Name = 'an'; Alias = 'Iron Man' }
         )

         $defaultItem = Resolve-DefaultItem -ItemGroup $hashTables

         $expectedResult = @{ }
         Compare-HashTable -ReferenceHashTable $expectedResult -DifferenceHashTable $defaultItem | Should -BeNullOrEmpty
      }
      It 'Merges all default Items.' {
         $hashTables = @(
            @{ Name = '*'; FirstName = 'Tony' },
            @{ Name = '*'; LastName = 'Stark' },
            @{ Name = 'dn'; DisplayName = 'Tony Stark' },
            @{ Name = 'an'; Alias = 'Iron Man' }
         )

         $defaultItem = Resolve-DefaultItem -ItemGroup $hashTables

         $expectedResult = @{ Name = '*'; FirstName = 'Tony'; LastName = 'Stark' }
         Compare-HashTable -ReferenceHashTable $expectedResult -DifferenceHashTable $defaultItem | Should -BeNullOrEmpty
      }
      It 'Overwrites common properties with last met default Item''s ones when merging all default Items.' {
         $hashTables = @(
            @{ Name = '*'; FirstName = 'Peter' },
            @{ Name = '*'; FirstName = 'Tony'; LastName = 'Stark' },
            @{ Name = 'dn'; DisplayName = 'Tony Stark' },
            @{ Name = 'an'; Alias = 'Iron Man' }
         )

         $defaultItem = Resolve-DefaultItem -ItemGroup $hashTables

         $expectedResult = @{ Name = '*'; FirstName = 'Tony'; LastName = 'Stark' }
         Compare-HashTable -ReferenceHashTable $expectedResult -DifferenceHashTable $defaultItem | Should -BeNullOrEmpty
      }
      It 'Is based on Name property only.' {
         Mock -CommandName Test-Path -ModuleName Item -MockWith { $true <# assumes every path is valid #> }
         $hashTables = @(
            @{ Path = '*'; FirstName = 'Tony' },
            @{ Path = '*'; LastName = 'Stark' },
            @{ Path = 'dn'; DisplayName = 'Tony Stark' },
            @{ Path = 'an'; Alias = 'Iron Man' }
         )

         $defaultItem = Resolve-DefaultItem -ItemGroup $hashTables

         $expectedResult = @{ }
         Compare-HashTable -ReferenceHashTable $expectedResult -DifferenceHashTable $defaultItem | Should -BeNullOrEmpty

      }
      It 'Ignores invalid Items even when Name is ''*''.' {
         Mock -CommandName Test-Path -ModuleName Item -MockWith { $false <# assumes every path is invalid #> }
         $hashTables = @(
            @{ Path = 'z:\notfound\file.txt'; Name = '*' },
            @{ Path = $null; Name = '*' },
            @{ Name = $null }
         )

         $defaultItem = Resolve-DefaultItem -ItemGroup $hashTables

         $expectedResult = @{ }
         Compare-HashTable -ReferenceHashTable $expectedResult -DifferenceHashTable $defaultItem | Should -BeNullOrEmpty
      }
   }
}
