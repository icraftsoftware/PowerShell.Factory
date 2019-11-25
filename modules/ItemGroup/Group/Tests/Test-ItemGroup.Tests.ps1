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

Describe 'Test-ItemGroup' {
   InModuleScope Group {

      Context 'When ItemGroups are given by arguments' {
         Mock -Command Write-Warning -ModuleName Item # avoid cluttering Pester output
         It 'Has no duplicate.' {
            Mock -Command Write-Warning

            $itemGroup = @( @{One = @( @{ } ) }, @{Two = @( @{ } ) } )
            Test-ItemGroup -ItemGroup $itemGroup -Unique | Should -Be $true

            Assert-MockCalled -CommandName Write-Warning -Times 0
         }
         It 'Warns about each duplicate ItemGroup.' {
            Mock -Command Write-Warning

            $itemGroup = @( @{One = @( @{ } ) }, @{One = @( @{ } ) } )
            Test-ItemGroup -ItemGroup $itemGroup -Unique | Should -Be $false

            Assert-MockCalled -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled -CommandName Write-Warning -Times 1
         }
         It 'Warns about each duplicate ItemGroup across arrays.' {
            Mock -Command Write-Warning

            $itemGroups = @(
               @( @{One = @( @{ } ) }, @{Two = @( @{ } ) } )
               @( @{One = @( @{ } ) }, @{Two = @( @{ } ) } )
            )
            Test-ItemGroup -ItemGroup $itemGroups -Unique | Should -Be $false

            Assert-MockCalled -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''Two'' has been defined multiple times.' } -Times 1
            Assert-MockCalled -CommandName Write-Warning -Times 2
         }
      }

      Context 'When ItemGroups are given by pipeline' {
         Mock -Command Write-Warning -ModuleName Item # avoid cluttering Pester output
         It 'Has no duplicate.' {
            Mock -Command Write-Warning

            $itemGroup = @( @{One = @( @{ } ) }, @{Two = @( @{ } ) } )
            $itemGroup | Test-ItemGroup -Unique | Should -Be $true

            Assert-MockCalled -CommandName Write-Warning -Times 0
         }
         It 'Warns about each duplicate ItemGroup.' {
            Mock -Command Write-Warning

            $itemGroup = @( @{One = @( @{ } ) }, @{One = @( @{ } ) } )
            $itemGroup | Test-ItemGroup -Unique | Should -Be $false

            Assert-MockCalled -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled -CommandName Write-Warning -Times 1
         }
         It 'Warns about each duplicate ItemGroup across arrays.' {
            Mock -Command Write-Warning

            $itemGroups = @(
               @( @{One = @( @{ } ) }, @{Two = @( @{ } ) } )
               @( @{One = @( @{ } ) }, @{Two = @( @{ } ) } )
            )
            $itemGroups | Test-ItemGroup -Unique | Should -Be $false

            Assert-MockCalled -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''Two'' has been defined multiple times.' } -Times 1
            Assert-MockCalled -CommandName Write-Warning -Times 2
         }
      }

      Context "When duplicate ItemGroups have duplicate Items" {
         It 'Warns about each duplicate Item.' {
            Mock -Command Write-Warning -ModuleName Item

            $itemGroup = @( @{One = @( @{ Name = 'one' } ) }, @{Two = @( @{ Name = 'one' }, @{ Name = 'two' } ) } )
            $itemGroup | Test-ItemGroup -Unique | Should -Be $false

            Assert-MockCalled -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'The following Item ''one'' has been defined multiple times:' } -Times 2
            Assert-MockCalled -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'Name\s+:\s+one' } -Times 2
            Assert-MockCalled -CommandName Write-Warning -ModuleName Item -Times 4
         }
         It 'Warns about each duplicate ItemGroup across arrays.' {
            Mock -Command Write-Warning -ModuleName Item
            Mock -Command Write-Warning

            $itemGroups = @(
               @( @{One = @( @{ Name = 'one' } ) }, @{Two = @( @{ Name = 'one' }, @{ Name = 'two' } ) } )
               @( @{One = @( @{ Name = 'one' } ) }, @{Two = @( @{ Name = 'one' }, @{ Name = 'two' } ) } )
            )
            $itemGroups | Test-ItemGroup -Unique | Should -Be $false

            Assert-MockCalled -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''Two'' has been defined multiple times.' } -Times 1
            Assert-MockCalled -CommandName Write-Warning -Times 2
            Assert-MockCalled -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'The following Item ''one'' has been defined multiple times:' } -Times 4
            Assert-MockCalled -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'Name\s+:\s+one' } -Times 4
            Assert-MockCalled -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'The following Item ''two'' has been defined multiple times:' } -Times 2
            Assert-MockCalled -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'Name\s+:\s+two' } -Times 2
            Assert-MockCalled -CommandName Write-Warning -ModuleName Item -Times 12
         }
      }

   }
}
