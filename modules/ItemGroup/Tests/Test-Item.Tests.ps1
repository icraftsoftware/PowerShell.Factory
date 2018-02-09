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

Describe 'Test-Item -Unique' {
   InModuleScope ItemGroup {
      Context 'When Items are given by arguments' {
         Mock Write-Warning
         It 'Does not trace an empty array.' {
            $item = @()

            Test-Item -Item $item -Unique | Should -Be $true

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Does not trace an array of empty arrays.' {
            $items = @( @(), @() )

            Test-Item -Item $items -Unique | Should -Be $true

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Does not trace an array of empty hashtables.' {
            $items = @( @{}, @{} )

            Test-Item -Item $items -Unique | Should -Be $true

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Does not trace an array of arrays of empty hashtables.' {
            $items = @( @( @{}, @{} ) , @( @{}, @{} ) )

            Test-Item -Item $items -Unique | Should -Be $true

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Does not trace an array of empty Items.' {
            $items = @( (ConvertTo-Item @{}) , (ConvertTo-Item @{}) )

            Test-Item -Item $items -Unique | Should -Be $true

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Does not trace an array of arrays of empty Items.' {
            $items = @( @( @{}, @{} ) , @( @{}, @{} ) )

            Test-Item -Item $items -Unique | Should -Be $true

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Has no duplicate.' {
            $item = @( @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'Three'} )

            Test-Item -Item $item -Unique | Should -Be $true

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Warns about each duplicate item in array.' {
            $item = @( @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'Three'} )

            Test-Item -Item $item -Unique | Should -Be $false

            Assert-MockCalled Write-Warning -Times 2
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''Two'' has been defined multiple times.' } -Times 1
         }
         It 'Warns about each duplicate item across arrays.' {
            $items = @(
               @( @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'One'} )
               @( @{Path = 'Two'}, @{Path = 'Three'} )
            )

            Test-Item -Item $items -Unique | Should -Be $false

            Assert-MockCalled Write-Warning -Times 2
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''Two'' has been defined multiple times.' } -Times 1
         }
      }
      Context 'When Items are given by pipeline' {
         Mock Write-Warning
         It 'Does not trace an empty array.' {
            $item = @()

            $item | Test-Item -Unique | Should -Be $true

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Has no duplicate.' {
            $item = @( @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'Three'} )

            $item | Test-Item -Unique | Should -Be $true

            Assert-MockCalled Write-Warning -Times 0
         }
         It 'Warns about each duplicate item in array.' {
            $item = @( @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'Three'} )

            $item | Test-Item -Unique | Should -Be $false

            Assert-MockCalled Write-Warning -Times 2
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''Two'' has been defined multiple times.' } -Times 1
         }
         It 'Warns about each duplicate item across arrays.' {
            $items = @(
               @( @{Path = 'One'}, @{Path = 'Two'}, @{Path = 'One'} )
               @( @{Path = 'Two'}, @{Path = 'Three'} )
            )

            $items | Test-Item -Unique | Should -Be $false

            Assert-MockCalled Write-Warning -Times 2
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''One'' has been defined multiple times.' } -Times 1
            Assert-MockCalled Write-Warning -ParameterFilter { $Message -eq 'Item ''Two'' has been defined multiple times.' } -Times 1
         }
      }
   }
}

Describe 'Test-Item -Property' {
   InModuleScope ItemGroup {
      It 'Is false for empty hashtable.' {
         @{} | Test-Item -Property 'Condition' | Should -Be $false
      }
      It 'Is false for an array of empty hashtables.' {
         @( @{} , @{} ) | Test-Item -Property 'Condition' | Should -Be @($false, $false)
      }
      It 'Is false for hashtable.' {
         @{Path = 1} | Test-Item -Property 'Condition' | Should -Be $false
      }
      It 'Is true for hashtable.' {
         @{Condition = $null} | Test-Item -Property 'Condition' | Should -Be $true
      }
      It 'Is false for empty custom object.' {
         ([pscustomobject]@{}) | Test-Item -Property 'Condition' | Should -Be $false
      }
      It 'Is false for an array of empty custom objects.' {
         @( [pscustomobject]@{} , [pscustomobject]@{} ) | Test-Item -Property 'Condition' | Should -Be @($false, $false)
      }
      It 'Is false for custom object.' {
         ([pscustomobject]@{Path = 1}) | Test-Item -Property 'Condition' | Should -Be $false
      }
      It 'Is true for custom object.' {
         ([pscustomobject]@{Condition = $null}) | Test-Item -Property 'Condition' | Should -Be $true
      }
   }
}

Describe 'Test-Item -Valid' {
   InModuleScope ItemGroup {
      It 'Is false for $null.' {
         $null | Test-Item -Valid | Should -Be $false
      }
      It 'Is false for an empty hashtable.' {
         @{} | Test-Item -Valid | Should -Be $false
      }
      It 'Is false for an empty custom object.' {
         ([pscustomobject]@{}) | Test-Item -Valid | Should -Be $false
      }
      It 'Is false for an empty array.' {
         @() | Test-Item -Valid | Should -Be $false
      }
      It 'Is false for an array of empty hashtables.' {
         @( @{} , @{} ) | Test-Item -Valid | Should -Be $false
      }
      It 'Is false for an array of empty custom objects.' {
         @( ([pscustomobject]@{}) , ([pscustomobject]@{}) ) | Test-Item -Valid | Should -Be $false
      }
      It 'Is true for a hashtable with property.' {
         @{x = $null} | Test-Item -Valid | Should -Be $true
      }
      It 'Is true for a custom object with property.' {
         ([pscustomobject]@{x = $null}) | Test-Item -Valid | Should -Be $true
      }
      It 'Is true for an array with one non-empty hashtable.' {
         @( @{x = $null} , @{} ) | Test-Item -Valid | Should -Be $true
      }
      It 'Is true for an array with one non-empty custom object.' {
         @( ([pscustomobject]@{x = $null}) , ([pscustomobject]@{}) ) | Test-Item -Valid | Should -Be $true
      }
      It 'Accepts arguments of mixed hashtable and custom object items' {
         Test-Item -Valid -Item @( @{x = $null} , ([pscustomobject]@{x = $null}) ) | Should -Be $true
      }
   }
}
