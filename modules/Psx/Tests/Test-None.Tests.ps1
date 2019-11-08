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

Import-Module Psx -Force

Describe 'Test-None' {
   InModuleScope Psx {
      It 'Returns true for empty array.' {
         @() | Test-None | Should -Be $true
      }
      It 'Returns true for nested empty array.' {
         @( @() ) | Test-None | Should -Be $true
      }
      It 'Returns false for array of arrays, even empty.' {
         @( @() , @() ) | Test-None | Should -Be $false
      }
      It 'Returns false for $null.' {
         $null | Test-None | Should -Be $false
      }
      It 'Returns false for array with $null.' {
         @( $null , @() ) | Test-None | Should -Be $false
      }
      It 'Works with arguments too.' {
         Test-None -InputObject @( @() , @() ) | Should -Be $false
      }
   }
}
