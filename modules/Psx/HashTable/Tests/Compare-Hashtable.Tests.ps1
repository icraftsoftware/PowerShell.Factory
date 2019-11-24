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

Import-Module Psx\HashTable -Force

Describe 'Compare-Hashtable' {
    InModuleScope HashTable {

        Context 'When both are empty' {
            $left, $right = @{ }, @{ }

            It 'should return nothing.' {
                Compare-HashTable $left $right | Should -BeNullOrEmpty
            }
        }

        Context 'When both have one identical entry' {
            $left, $right = @{ a = 'x' }, @{ a = 'x' }

            It 'should return nothing.' {
                Compare-HashTable $left $right | Should -BeNullOrEmpty
            }
        }

        Context 'When reference contains a key with a null value' {
            $left, $right = @{ a = $null }, @{ }

            It 'should return a: <.' {
                [object[]]$result = Compare-HashTable $left $right

                $result.Length | Should -Be 1
                $result.Key | Should -Be 'a'
                $result.ReferenceValue | Should -Be $null
                $result.SideIndicator | Should -Be '<'
                $result.DifferenceValue | Should -Be $null
            }
        }

        Context 'When difference contains a key with a null value' {
            $left, $right = @{ }, @{ a = $null }

            It 'should return a: >.' {
                [object[]]$result = Compare-HashTable $left $right

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
            $results = Compare-HashTable $left $right

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
                $result.SideIndicator | Should -Be '<>'
                $result.DifferenceValue | Should -Be 7
            }
        }

    }
}