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

Describe 'Test-Item-Wellformed' {
   InModuleScope Item {
      It 'Is false for $null.' {
         $null | Test-Item -Wellformed | Should -Be $false
      }
      It 'Is false for an empty hashtable.' {
         @{ } | Test-Item -Wellformed | Should -Be $false
      }
      It 'Is true for a hashtable with a property.' {
         @{Name = 'name' ; x = $null } | Test-Item -Wellformed | Should -Be $true
      }
      It 'Is false for an empty custom object.' {
         ([pscustomobject]@{ }) | Test-Item -Wellformed | Should -Be $false
      }
      It 'Is true for a custom object with a property.' {
         [pscustomobject]@{Name = 'name' ; x = $null } | Test-Item -Wellformed | Should -Be $true
      }
      It 'Is empty for an empty array.' {
         @() | Test-Item -Wellformed | Should -Be @()
      }
      It 'Is false for each empty hashtable in an array.' {
         @( @{ } , @{ } ) | Test-Item -Wellformed | Should -Be @($false, $false)
      }
      It 'Is true for each hashtable with a property in an array.' {
         @( @{Name = 'name' ; x = $null } , @{ } ) | Test-Item -Wellformed | Should -Be ($true, $false)
      }
      It 'Is false for each empty custom object in an array.' {
         @( ([pscustomobject]@{ }) , ([pscustomobject]@{ }) ) | Test-Item -Wellformed | Should -Be @($false, $false)
      }
      It 'Is true for each custom object with a property in an array.' {
         @( [pscustomobject]@{Name = 'name' ; x = $null } , [pscustomobject]@{ } ) | Test-Item -Wellformed | Should -Be ($true, $false)
      }
   }
}