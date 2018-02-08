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
