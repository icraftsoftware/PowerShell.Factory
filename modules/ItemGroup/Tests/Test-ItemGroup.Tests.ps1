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

Describe 'Test-ItemGroup' {
   InModuleScope ItemGroup {
      Context 'When ItemGroups are given by arguments' {
         Mock Write-Warning
         It 'Has no duplicate.' {
            $itemGroup = @( @{One = @(@{})}, @{Two = @(@{})} )

            Test-ItemGroup -ItemGroup $itemGroup -Unique | Should -Be $true

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Warns about each duplicate item group.' {
            $itemGroup = @( @{One = @(@{})}, @{One = @(@{})} )

            Test-ItemGroup -ItemGroup $itemGroup -Unique | Should -Be $false

            Assert-MockCalled Write-Warning -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''One'' has been defined multiple times.' } -Times 1
         }
         It 'Warns about each duplicate item across arrays.' {
            $itemGroups = @(
               @( @{One = @(@{})}, @{Two = @(@{})} )
               @( @{One = @(@{})}, @{Two = @(@{})} )
            )
            Test-ItemGroup -ItemGroup $itemGroups -Unique | Should -Be $false

            Assert-MockCalled Write-Warning -Times 2
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''Two'' has been defined multiple times.' } -Times 1
         }
      }
      Context 'When ItemGroups are given by pipeline' {
         Mock Write-Warning
         It 'Has no duplicate.' {
            $itemGroup = @( @{One = @(@{})}, @{Two = @(@{})} )

            $itemGroup | Test-ItemGroup -Unique | Should -Be $true
         }
         It 'Warns about each duplicate item group.' {
            $itemGroup = @( @{One = @(@{})}, @{One = @(@{})} )

            $itemGroup | Test-ItemGroup -Unique | Should -Be $false

            Assert-MockCalled Write-Warning -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''One'' has been defined multiple times.' } -Times 1
         }
         It 'Warns about each duplicate item across arrays.' {
            $itemGroups = @(
               @( @{One = @(@{})}, @{Two = @(@{})} )
               @( @{One = @(@{})}, @{Two = @(@{})} )
            )
            $itemGroups | Test-ItemGroup -Unique | Should -Be $false

            Assert-MockCalled Write-Warning -Times 2 # has been called only once
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'ItemGroup ''Two'' has been defined multiple times.' } -Times 1
         }
      }
   }
}
