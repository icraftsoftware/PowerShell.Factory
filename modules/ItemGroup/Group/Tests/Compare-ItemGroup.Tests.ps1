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

Describe 'Compare-ItemGroup' {
   InModuleScope Group {

      Context 'When both ItemGroups are empty' {
         It "should return nothing." {
            $left = @{ }
            $right = @{ }
            Compare-ItemGroup $left $right | Should -BeNullOrEmpty
         }
      }

      Context "When both ItemGroups have different groups" {
         It "should return Group1 {} < and Group2 > {}." {
            $left = @{ Group1 = @() }
            $right = @{ Group2 = @() }

            $result = Compare-ItemGroup $left $right

            $result | Measure-Object | Select-Object -ExpandProperty Count | Should -Be 2
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

      Context "When both ItemGroups have a common group with no Item" {
         It "should return nothing." {
            $left = @{ Group1 = @() }
            $right = @{ Group1 = @() }
            Compare-ItemGroup $left $right | Should -BeNullOrEmpty
         }
      }

      Context "When both ItemGroups have a common group with one identical Item" {
         It "should return nothing." {
            $left = @{ Group1 = @(ConvertTo-Item @{ Path = 'Item' }) }
            $right = @{ Group1 = @(ConvertTo-Item @{ Path = 'Item' }) }
            Compare-ItemGroup $left $right | Should -BeNullOrEmpty
         }
      }

      Context "When both ItemGroups have a common group with one partially different Item" {
         It "should return Group1[0].Path Item1 <> Item2." {
            $left = @{ Group1 = @(ConvertTo-Item @{ Path = 'Item1'; Condition = $true }) }
            $right = @{ Group1 = @(ConvertTo-Item @{ Path = 'Item2'; Condition = $true }) }

            $result = Compare-ItemGroup $left $right

            $result | Measure-Object | Select-Object -ExpandProperty Count | Should -Be 1
            $result.Key | Should -Be 'Group1[0].Path'
            $result.ReferenceValue | Should -Be 'Item1'
            $result.SideIndicator | Should -Be "<>"
            $result.DifferenceValue | Should -Be 'Item2'
         }
      }

      Context "When both ItemGroups have a common group and reference ItemGroup has one more Item" {
         It "should return Group1[0] @{Path=Item} <." {
            $left = @{ Group1 = @(ConvertTo-Item @{Path = 'Item' }) }
            $right = @{ Group1 = @() }

            $result = Compare-ItemGroup $left $right

            $result | Measure-Object | Select-Object -ExpandProperty Count | Should -Be 1
            $result.Key | Should -Be 'Group1[0]'
            $result.ReferenceValue | Should -Be '@{Path=Item}'
            $result.SideIndicator | Should -Be "<"
            $result.DifferenceValue | Should -BeNullOrEmpty
         }
      }

      Context "When both ItemGroups have a common group and difference ItemGroup has one more Item" {
         It "should return Group1[0] > @{Path=Item}." {
            $left = @{ Group1 = @() }
            $right = @{ Group1 = @(ConvertTo-Item @{ Path = 'Item' }) }

            $result = Compare-ItemGroup $left $right

            $result | Measure-Object | Select-Object -ExpandProperty Count | Should -Be 1
            $result.Key | Should -Be 'Group1[0]'
            $result.ReferenceValue | Should -BeNullOrEmpty
            $result.SideIndicator | Should -Be ">"
            $result.DifferenceValue | Should -Be '@{Path=Item}'
         }
      }

   }
}
