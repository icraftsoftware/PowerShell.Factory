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

Import-Module Psx -Force

Describe 'Compare-Hashtable' {
   Context 'When both are empty' {
      $left, $right = @{}, @{}

      It 'should return nothing.' {
         Compare-Hashtable $left $right | Should -BeNullOrEmpty
      }
   }

   Context 'When both have one identical entry' {
      $left, $right = @{ a = 'x' }, @{ a = 'x' }

      It 'should return nothing.' {
         Compare-Hashtable $left $right | Should -BeNullOrEmpty
      }
   }

   Context 'When reference contains a key with a null value' {
      $left, $right = @{ a = $null }, @{}

      It 'should return a: <.' {
         [object[]]$result = Compare-Hashtable $left $right

         $result.Length | Should -Be 1
         $result.Key | Should -Be 'a'
         $result.ReferenceValue | Should -Be $null
         $result.SideIndicator | Should -Be '<'
         $result.DifferenceValue | Should -Be $null
      }
   }

   Context 'When difference contains a key with a null value' {
      $left, $right = @{}, @{ a = $null }

      It 'should return a: >.' {
         [object[]]$result = Compare-Hashtable $left $right

         $result.Length | Should -Be 1
         $result.Key | Should -Be 'a'
         $result.ReferenceValue | Should -Be $null
         $result.SideIndicator | Should -Be '>'
         $result.DifferenceValue | Should -Be $null
      }
   }

   Context 'When both contain various stuff' {
      $left = @{ a = 1; b = 2; c = 3; f = $null; g = 6; k = $null }
      $right = @{ b = 2; c = 4; e = 5; f = $null; g = $null; k = 7 }
      $results = Compare-Hashtable $left $right

      It 'should contain 5 differences.' {
         $results.Length | Should -Be 5
      }
      It 'should return a: 1 <.' {
         $result = $results | Where-Object { $_.Key -eq 'a' }
         $result.ReferenceValue | Should -Be 1
         $result.SideIndicator | Should -Be '<'
         $result.DifferenceValue | Should -Be $null
      }
      It 'should return c: 3 <> 4.' {
         $result = $results | Where-Object { $_.Key -eq 'c' }
         $result.ReferenceValue | Should -Be 3
         $result.SideIndicator | Should -Be '<>'
         $result.DifferenceValue | Should -Be 4
      }
      It 'should return e: > 5.' {
         $result = $results | Where-Object { $_.Key -eq 'e' }
         $result.ReferenceValue | Should -Be $null
         $result.SideIndicator | Should -Be '>'
         $result.DifferenceValue | Should -Be 5
      }
      It 'should return g: 6 <>.' {
         $result = $results | Where-Object { $_.Key -eq 'g' }
         $result.ReferenceValue | Should -Be 6
         $result.SideIndicator | Should -Be '<>'
         $result.DifferenceValue | Should -Be $null
      }
      It 'should return k: <> 7.' {
         $result = $results | Where-Object { $_.Key -eq 'k' }
         $result.ReferenceValue | Should -Be $null
         $result.SideIndicator   | Should -Be '<>'
         $result.DifferenceValue | Should -Be 7
      }
   }
}

Describe 'Merge-HashTable' {
   InModuleScope Psx {
      Context 'When hashtables are given by arguments.' {
         It 'Merges hashtables.' {
            $hashTables = @( @{FirstName = 'Tony'}, @{LastName = 'Stark'}, @{DisplayName = 'Tony Stark'}, @{Alias = 'Iron Man'} )

            $mergedHashTable = Merge-HashTable -HashTable $hashTables

            $mergedHashTable | Should -BeOfType [hashtable]
            $expectedResult = @{Alias = 'Iron Man'; DisplayName = 'Tony Stark'; FirstName = 'Tony'; LastName = 'Stark'}
            Compare-HashTable -ReferenceHashTable $expectedResult -DifferenceHashTable $mergedHashTable | Should -BeNullOrEmpty
         }
         It 'Does not overwrite merged properties by default.' {
            $hashTables = @( @{FirstName = 'Tony'}, @{FirstName = 'Peter'}, @{FirstName = 'Natacha'}, @{Alias = 'Iron Man'} )

            $mergedHashTable = Merge-HashTable -HashTable $hashTables

            $mergedHashTable | Should -BeOfType [hashtable]
            $expectedResult = @{Alias = 'Iron Man'; FirstName = 'Tony'}
            Compare-HashTable -ReferenceHashTable $expectedResult -DifferenceHashTable $mergedHashTable -Verbose | Should -BeNullOrEmpty
         }
      }
      Context 'When hashtables are given by pipeline.' {
         It 'Merges hashtables.' {
            $hashTables = @( @{FirstName = 'Tony'}, @{LastName = 'Stark'}, @{DisplayName = 'Tony Stark'}, @{Alias = 'Iron Man'} )

            $mergedHashTable = $hashTables | Merge-HashTable

            $mergedHashTable | Should -BeOfType [hashtable]
            $expectedResult = @{Alias = 'Iron Man'; DisplayName = 'Tony Stark'; FirstName = 'Tony'; LastName = 'Stark'}
            Compare-HashTable -ReferenceHashTable $expectedResult -DifferenceHashTable $mergedHashTable | Should -BeNullOrEmpty
         }
         It 'Returns an empty hashtable if there are no hashtables to merge.' {
            $hashTables = @()

            $mergedHashTable = $hashTables | Merge-HashTable

            $mergedHashTable | Should -BeOfType [hashtable]
            $expectedResult = @{}
            Compare-HashTable -ReferenceHashTable $expectedResult -DifferenceHashTable $mergedHashTable | Should -BeNullOrEmpty
         }
         It 'Does not overwrite merged properties by default.' {
            $hashTables = @( @{FirstName = 'Tony'}, @{FirstName = 'Peter'}, @{FirstName = 'Natacha'}, @{Alias = 'Iron Man'} )

            $mergedHashTable = $hashTables | Merge-HashTable

            $mergedHashTable | Should -BeOfType [hashtable]
            $expectedResult = @{Alias = 'Iron Man'; FirstName = 'Tony'}
            Compare-HashTable -ReferenceHashTable $expectedResult -DifferenceHashTable $mergedHashTable | Should -BeNullOrEmpty
         }
         It 'Overwrites merged properties if forced to.' {
            $hashTables = @( @{FirstName = 'Tony'}, @{FirstName = 'Natacha'}, @{FirstName = 'Peter'}, @{Alias = 'Spider Man'} )

            $mergedHashTable = $hashTables | Merge-HashTable -Force

            $mergedHashTable | Should -BeOfType [hashtable]
            $expectedResult = @{Alias = 'Spider Man'; FirstName = 'Peter'}
            Compare-HashTable -ReferenceHashTable $expectedResult -DifferenceHashTable $mergedHashTable | Should -BeNullOrEmpty
         }
         It 'Overwrites merged properties if forced to unless properties are excluded.' {
            $hashTables = @( @{Path = 'fn'; FirstName = 'Tony'}, @{Path = 'ln'; LastName = 'Stark'}, @{Path = 'dn'; DisplayName = 'Tony Stark'}, @{Path = 'an'; Alias = 'Iron Man'} )

            $mergedHashTable = $hashTables | Merge-HashTable -Exclude 'Path' -Force

            $mergedHashTable | Should -BeOfType [hashtable]
            $expectedResult = @{Alias = 'Iron Man'; DisplayName = 'Tony Stark'; FirstName = 'Tony'; LastName = 'Stark' ; Path = 'fn'}
            Compare-HashTable -ReferenceHashTable $expectedResult -DifferenceHashTable $mergedHashTable | Should -BeNullOrEmpty
         }
         It 'Is verbose about every overwritten property.' {
            Mock Write-Verbose
            $hashTables = @( @{FirstName = 'Tony'}, @{FirstName = 'Natacha'}, @{FirstName = 'Peter'}, @{Alias = 'Spider Man'} )

            $hashTables | Merge-HashTable -Force -Verbose

            Assert-MockCalled Write-Verbose -Times 2 # has -been called only twice
            Assert-MockCalled Write-Verbose -ParameterFilter { $Message -eq 'Property ''FirstName'' has been overwritten because it has been defined multiple times.' } -Times 2
         }
      }
   }
}

Describe 'Test-Any' {
   InModuleScope Psx {
      It 'Returns false for empty array.' {
         @() | Test-Any | Should -Be $false
      }
      It 'Returns false for nested empty array.' {
         @( @() ) | Test-Any | Should -Be $false
      }
      It 'Returns true for array of arrays, even empty.' {
         @( @() , @() ) | Test-Any | Should -Be $true
      }
      It 'Returns true for $null.' {
         $null | Test-Any | Should -Be $true
      }
      It 'Returns true for array with $null.' {
         @( $null , @() ) | Test-Any | Should -Be $true
      }
      It 'Works with arguments too.' {
         Test-Any -InputObject @( @() , @() ) | Should -Be $true
      }
   }
}
