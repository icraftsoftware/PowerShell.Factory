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

      Context 'Unicity check when ItemGroups are given by arguments' {
         It 'is true when there is no duplicate ItemGroup.' {
            $itemGroup = @(
               @{ One = @( @{ Name = 'one' } ) }, @{ Two = @( @{ Name = 'two' } ) }
            )
            Test-ItemGroup -ItemGroup $itemGroup -Unique | Should -Be $true
         }
         It 'is false when there is no duplicate ItemGroup but duplicate Items.' {
            $itemGroup = @(
               @{ One = @( @{ Name = 'one' } ) }, @{ Two = @( @{ Name = 'one' } ) }
            )
            Test-ItemGroup -ItemGroup $itemGroup -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
         It 'is true when there is no duplicate ItemGroup across input arrays.' {
            $itemGroup = @(
               @( @{ One = @( @{ Name = 'one' } ) }, @{ Two = @( @{ Name = 'two' } ) } )
               @( @{ Six = @( @{ Name = 'six' } ) }, @{ Ten = @( @{ Name = 'ten' } ) } )
            )
            Test-ItemGroup -ItemGroup $itemGroup -Unique | Should -Be $true
         }
         It 'is false when there is no duplicate ItemGroup across input arrays but duplicate Items.' {
            $itemGroup = @(
               @( @{ One = @( @{ Name = 'one' } ) }, @{ Two = @( @{ Name = 'two' } ) } )
               @( @{ Six = @( @{ Name = 'one' } ) }, @{ Ten = @( @{ Name = 'two' } ) } )
            )
            Test-ItemGroup -ItemGroup $itemGroup -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
         It 'is false when there is one duplicate ItemGroup.' {
            $itemGroup = @(
               @{ One = @( @{ Name = 'one' } ) }, @{ One = @( @{ Name = 'one' } ) }
            )
            Test-ItemGroup -ItemGroup $itemGroup -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
         It 'is false when there is one duplicate ItemGroup across input arrays.' {
            $itemGroup = @(
               @( @{ One = @( @{ Name = 'one' } ) }, @{ Two = @( @{ Name = 'two' } ) } )
               @( @{ One = @( @{ Name = 'one' } ) }, @{ Two = @( @{ Name = 'two' } ) } )
            )
            Test-ItemGroup -ItemGroup $itemGroup -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
      }

      Context 'Unicity check when ItemGroups are given by pipeline' {
         It 'is true when there is no duplicate ItemGroup.' {
            $itemGroup = @(
               @{ One = @( @{ Name = 'one' } ) }, @{ Two = @( @{ Name = 'two' } ) }
            )
            $itemGroup | Test-ItemGroup -Unique | Should -Be $true
         }
         It 'is false when there is no duplicate ItemGroup but duplicate Items.' {
            $itemGroup = @(
               @{ One = @( @{ Name = 'one' } ) }, @{ Two = @( @{ Name = 'one' } ) }
            )
            $itemGroup | Test-ItemGroup -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
         It 'is true when there is no duplicate ItemGroup across input arrays.' {
            $itemGroup = @(
               @( @{ One = @( @{ Name = 'one' } ) }, @{ Two = @( @{ Name = 'two' } ) } )
               @( @{ Six = @( @{ Name = 'six' } ) }, @{ Ten = @( @{ Name = 'ten' } ) } )
            )
            $itemGroup | Test-ItemGroup -Unique | Should -Be $true
         }
         It 'is false when there is no duplicate ItemGroup across input arrays but duplicate Items.' {
            $itemGroup = @(
               @( @{ One = @( @{ Name = 'one' } ) }, @{ Two = @( @{ Name = 'two' } ) } )
               @( @{ Six = @( @{ Name = 'one' } ) }, @{ Ten = @( @{ Name = 'two' } ) } )
            )
            $itemGroup | Test-ItemGroup -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
         It 'is false when there is one duplicate ItemGroup.' {
            $itemGroup = @(
               @{ One = @( @{ Name = 'one' } ) }, @{ One = @( @{ Name = 'one' } ) }
            )
            $itemGroup | Test-ItemGroup -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
         It 'is false when there is one duplicate ItemGroup across input arrays.' {
            $itemGroup = @(
               @( @{ One = @( @{ Name = 'one' } ) }, @{ Two = @( @{ Name = 'two' } ) } )
               @( @{ One = @( @{ Name = 'one' } ) }, @{ Two = @( @{ Name = 'two' } ) } )
            )
            $itemGroup | Test-ItemGroup -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
      }

      Context 'Warns about each duplicate ItemGroup' {
         Mock -Command Write-Warning
         It 'warns about each duplicate ItemGroup.' {
            $itemGroup = @(
               @{ One = @( @{ Name = 'one' } ) }, @{ One = @( @{ Name = 'two' } ) }
            )
            Test-ItemGroup -ItemGroup $itemGroup -Unique | Should -Be $false

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''One'' has been defined multiple times.' } -Exactly 1
            Assert-MockCalled -Scope It -CommandName Write-Warning -Exactly 1
         }
         It 'warns about each duplicate ItemGroup across arrays.' {
            $itemGroup = @(
               @( @{ One = @( @{ Name = 'abc' } ) }, @{ Two = @( @{ Name = 'def' } ) } )
               @( @{ One = @( @{ Name = 'cba' } ) }, @{ Two = @( @{ Name = 'fed' } ) } )
            )
            Test-ItemGroup -ItemGroup $itemGroup -Unique | Should -Be $false

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''One'' has been defined multiple times.' } -Exactly 1
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''Two'' has been defined multiple times.' } -Exactly 1
            Assert-MockCalled -Scope It -CommandName Write-Warning -Exactly 2
         }
      }

      Context 'Warns about each duplicate Item' {
         Mock -Command Write-Warning -ModuleName Item
         It 'warns about each duplicate Item.' {
            $itemGroup = @(
               @{ One = @( @{ Name = 'one' } ) }
               @{ Two = @( @{ Name = 'one' }, @{ Name = 'two' } ) }
            )
            $itemGroup | Test-ItemGroup -Unique | Should -Be $false

            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'The following Item ''one'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'Name\s+:\s+one' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -Exactly 4
         }
         It 'Warns about each duplicate Item across arrays.' {
            $itemGroup = @(
               @(
                  @{One = @( @{ Name = 'one' } ) }
                  @{Two = @( @{ Name = 'one' }, @{ Name = 'two' } ) }
               )
               @(
                  @{Six = @( @{ Name = 'one' } ) }
                  @{Ten = @( @{ Name = 'one' }, @{ Name = 'two' } ) }
               )
            )
            $itemGroup | Test-ItemGroup -Unique | Should -Be $false

            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'The following Item ''one'' has been defined multiple times:' } -Exactly 4
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'Name\s+:\s+one' } -Exactly 4
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -eq 'The following Item ''two'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -ParameterFilter { $Message -match 'Name\s+:\s+two' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ModuleName Item -Exactly 12
         }
      }

   }
}
