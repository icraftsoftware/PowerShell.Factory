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

Describe 'Test-Item-Property' {
   InModuleScope Item {

      Context 'Property membership check is conditionned by the well-formedness check' {
         It 'is always false for an ill-formed Item.' {
            $item = @{ Condition = $null }
            # even though the Item is well formed
            Test-Item -Item $item -WellFormed | Should -Be $true
            # and property membership is satisfied
            Test-Item -Item $item -Property Condition | Should -Be $true

            # it will be assumed not to be well formed
            Mock -CommandName Test-Item -ParameterFilter { $WellFormed.IsPresent } -MockWith { $false <# assumes Item is not wellformed #> } -Verifiable
            Test-Item -Item $item -WellFormed | Should -Be $false

            # and property membership will not be satisfied anymore
            Test-Item -Item $item -Property Condition | Should -Be $false

            Assert-VerifiableMock
         }
      }

      Context 'When checking the membership of all of the properties and Items are given by argument.' {
         It 'Is false when testing for all of one property.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Firstname -Mode All | Should -Be @($false, $false)
         }
         It 'Is true when testing for all of one property.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Condition -Mode All | Should -Be @($true, $true)
         }
         It 'Is false when testing for all of several properties.' {
            Test-Item -Item @( @{ Condition = $false } , [pscustomobject]@{ Condition = $false } ) -Property Condition, Name -Mode All | Should -Be @($false, $false)
         }
         It 'Is true when testing for all of several properties.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Condition, Name -Mode All | Should -Be @($true, $true)
         }
      }

      Context 'When checking the membership of all of the properties and Items are given by pipeline.' {
         It 'Is false when testing for all of one property.' {
            @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } | Test-Item -Property Firstname -Mode All | Should -Be @($false, $false)
         }
         It 'Is true when testing for all of one property.' {
            @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } | Test-Item -Property Condition -Mode All | Should -Be @($true, $true)
         }
         It 'Is false when testing for all of several properties.' {
            @(@{ Condition = $false } , [pscustomobject]@{ Condition = $false }) | Test-Item -Property Condition, Name -Mode All | Should -Be @($false, $false)
         }
         It 'Is true when testing for all of several properties.' {
            @(@{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' }) | Test-Item -Property Condition, Name -Mode All | Should -Be @($true, $true)
         }
      }

      Context 'When checking the membership of any of the properties and Items are given by argument.' {
         It 'Is false when testing for any of one property.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Fisrtname -Mode Any | Should -Be @($false, $false)
         }
         It 'Is true when testing for any of one property.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Condition -Mode Any | Should -Be @($true, $true)
         }
         It 'Is false when testing for any of several properties.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Fisrtname, Lastname -Mode Any | Should -Be @($false, $false)
         }
         It 'Is true when testing for any of several properties.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Condition, Name -Mode Any | Should -Be @($true, $true)
         }
      }

      Context 'When checking the membership of any of the properties and Items are given by pipeline.' {
         It 'Is false when testing for any of one property.' {
            @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } | Test-Item -Property Fisrtname -Mode Any | Should -Be @($false, $false)
         }
         It 'Is true when testing for any of one property.' {
            @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } | Test-Item -Property Condition -Mode Any | Should -Be @($true, $true)
         }
         It 'Is false when testing for any of several properties.' {
            @(@{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' }) | Test-Item -Property Fisrtname, Lastname -Mode Any | Should -Be @($false, $false)
         }
         It 'Is true when testing for any of several properties.' {
            @(@{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' }) | Test-Item -Property Condition, Name -Mode Any | Should -Be @($true, $true)
         }
      }

      Context 'When checking the membership of none of the properties and Items are given by argument.' {
         It 'Is false when testing for none of one property.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Name -Mode None | Should -Be @($false, $false)
         }
         It 'Is true when testing for none of one property.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Fisrtname -Mode None | Should -Be @($true, $true)
         }
         It 'Is false when testing for none of several properties.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Name, Fisrtname -Mode None | Should -Be @($false, $false)
         }
         It 'Is true when testing for none of several properties.' {
            Test-Item -Item @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) -Property Firstname, Lastname -Mode None | Should -Be @($true, $true)
         }
      }

      Context 'When checking the membership of none of the properties and Items are given by pipeline.' {
         It 'Is false when testing for none of one property.' {
            @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } | Test-Item -Property Name -Mode None | Should -Be @($false, $false)
         }
         It 'Is true when testing for none of one property.' {
            @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } | Test-Item -Property Fisrtname -Mode None | Should -Be @($true, $true)
         }
         It 'Is false when testing for none of several properties.' {
            @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) | Test-Item -Property Name, Fisrtname -Mode None | Should -Be @($false, $false)
         }
         It 'Is true when testing for none of several properties.' {
            @( @{ Condition = $false ; Name = 'Stark' } , [pscustomobject]@{ Condition = $false ; Name = 'Stark' } ) | Test-Item -Property Firstname, Lastname -Mode None | Should -Be @($true, $true)
         }
      }

   }
}