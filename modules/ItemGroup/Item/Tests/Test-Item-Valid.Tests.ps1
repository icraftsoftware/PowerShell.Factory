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
Import-Module ItemGroup\Utils -Force

Describe 'Test-Item-Valid' {
   InModuleScope Item {

      Context 'Validity check is conditionned by the well-formedness check' {
         It 'is always false for an ill-formed Item.' {
            $item = @{ Name = 'Stark' }
            # although the Item is well formed
            Test-Item -Item $item -WellFormed | Should -Be $true
            # and Validity check is satisfied
            Test-Item -Item $item -Valid | Should -Be $true

            # it will be assumed not to be well formed
            Mock -CommandName Test-Item -ParameterFilter { $WellFormed.IsPresent } -MockWith { $false <# assumes Item is not wellformed #> }
            Test-Item -Item $item -WellFormed | Should -Be $false

            Test-Item -Item $item -Valid -WarningAction SilentlyContinue | Should -Be $false

            Assert-MockCalled -CommandName Test-Item -ParameterFilter { $WellFormed.IsPresent } -Times 2
         }
      }

      Context 'Validity check when Items are given by argument.' {
         It 'Is false when Item does not have a Name nor a Path property.' {
            Test-Item -Item @(@{ Condition = $true }, [PSCustomObject]@{ Condition = $true }) -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Is false when Item has a null Name property.' {
            Test-Item -Item @(@{ Name = $null }, [PSCustomObject]@{ Name = $null }) -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Is true when Item has a non-null Name property.' {
            Test-Item -Item @(@{ Name = 'Stark' }, [PSCustomObject]@{ Name = 'Parker' }) -Valid | Should -Be ($true, $true)
         }
         It 'Is false when Item has a null Path property.' {
            Test-Item -Item @(@{ Path = $null }, [PSCustomObject]@{ Path = $null }) -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Is false when Item has an invalid Path property.' {
            Mock -CommandName Test-Path -MockWith { $false <# assumes every path is invalid #> }
            Test-Item -Item @(@{ Path = 'a:\notfound\file.txt' }, [PSCustomObject]@{ Path = 'a:\notfound\file.txt' }) -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Is true when Item has a valid Path property and no Name property.' {
            Mock -CommandName Test-Path -MockWith { $true <# assumes every path is valid #> }
            Test-Item -Item @(@{ Path = 'a:\folder\file.txt' }, [PSCustomObject]@{ Path = 'a:\folder\file.txt' }) -Valid | Should -Be ($true, $true)
         }
         It 'Is false when Item.Path is invalid although Item.Name is non-null because Path has precedence.' {
            Mock -CommandName Test-Path -MockWith { $false <# assumes every path is invalid #> }
            Test-Item -Item @(@{ Path = 'a:\notfound\file.txt' ; Name = 'Stark' }, [PSCustomObject]@{ Path = 'a:\notfound\file.txt' ; Name = 'Stark' }) -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Is true when Item.Path is valid although Item.Name is null because Path has precedence.' {
            Mock -CommandName Test-Path -MockWith { $true <# assumes every path is valid #> }
            Test-Item -Item @(@{ Path = 'a:\folder\file.txt' ; Name = $null }, [PSCustomObject]@{ Path = 'a:\folder\file.txt' ; Name = $null }) -Valid | Should -Be ($true, $true)
         }
      }

      Context 'Validity check when Items are given by pipeline.' {
         It 'Is false when Item does not have a Name nor a Path property.' {
            @{ Condition = $true }, [PSCustomObject]@{ Condition = $true } | Test-Item -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Is false when Item has a null Name property.' {
            @{ Name = $null }, [PSCustomObject]@{ Name = $null } | Test-Item -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Is true when Item has a non-null Name property.' {
            @{ Name = 'Stark' }, [PSCustomObject]@{ Name = 'Parker' } | Test-Item -Valid | Should -Be ($true, $true)
         }
         It 'Is false when Item has a null Path property.' {
            @{ Path = $null }, [PSCustomObject]@{ Path = $null } | Test-Item -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Is false when Item has an invalid Path property.' {
            Mock -CommandName Test-Path -MockWith { $false <# assumes every path is invalid #> }
            @(@{ Path = 'a:\notfound\file.txt' }, [PSCustomObject]@{ Path = 'a:\notfound\file.txt' }) | Test-Item -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Is true when Item has a valid Path property and no Name property.' {
            Mock -CommandName Test-Path -MockWith { $true <# assumes every path is valid #> }
            @(@{ Path = 'a:\folder\file.txt' }, [PSCustomObject]@{ Path = 'a:\folder\file.txt' }) | Test-Item -Valid | Should -Be ($true, $true)
         }
         It 'Is false when Item.Path is invalid although Item.Name is non-null because Path has precedence.' {
            Mock -CommandName Test-Path -MockWith { $false <# assumes every path is invalid #> }
            @(@{ Path = 'a:\notfound\file.txt' ; Name = 'Stark' }, [PSCustomObject]@{ Path = 'a:\notfound\file.txt' ; Name = 'Stark' }) | Test-Item -Valid -WarningAction SilentlyContinue | Should -Be ($false, $false)
         }
         It 'Is true when Item.Path is valid although Item.Name is null because Path has precedence.' {
            Mock -CommandName Test-Path -MockWith { $true <# assumes every path is valid #> }
            @(@{ Path = 'a:\folder\file.txt' ; Name = $null }, [PSCustomObject]@{ Path = 'a:\folder\file.txt' ; Name = $null }) | Test-Item -Valid | Should -Be ($true, $true)
         }
      }

      Context 'Validity check warns about any invalid Item.' {
         Mock -CommandName Write-Warning
         Mock -CommandName Test-Path -MockWith { $false <# assumes every path is invalid #> }
         It 'Warns about every property, whether null or invalid, for every invalid Item.' {
            @(@{ Path = 'a:\folder\file.txt' ; Name = $null ; Condition = $null }, [PSCustomObject]@{ Path = 'a:\folder\file.txt' ; Name = $null ; Condition = $null }) | Test-Item -Valid | Should -Be ($false, $false)

            Assert-MockCalled -CommandName Write-Warning -Scope It -ParameterFilter { $Message -eq 'The following Item is invalid because it is either ill-formed or misses either a valid Path or Name property:' } -Times 2
            Assert-MockCalled -CommandName Write-Warning -Scope It -ParameterFilter { $Message -match 'Path\s+:\s+a:\\folder\\file\.txt' } -Times 2
            Assert-MockCalled -CommandName Write-Warning -Scope It -ParameterFilter { $Message -match 'Name\s+:' } -Times 2
            Assert-MockCalled -CommandName Write-Warning -Scope It -ParameterFilter { $Message -match 'Condition\s+:' } -Times 2
            Assert-MockCalled -CommandName Write-Warning -Times 8
         }
         It 'Warns about every property for every invalid Item.' {
            @(@{ Path = 'a:\folder\file.txt' ; Name = 'Stark' ; Condition = $false }, [PSCustomObject]@{ Path = 'a:\folder\file.txt' ; Name = 'Stark' ; Condition = $false }) | Test-Item -Valid | Should -Be ($false, $false)

            Assert-MockCalled -CommandName Write-Warning -Scope It -ParameterFilter { $Message -eq 'The following Item is invalid because it is either ill-formed or misses either a valid Path or Name property:' } -Times 2
            Assert-MockCalled -CommandName Write-Warning -Scope It -ParameterFilter { $Message -match 'Path\s+:\s+a:\\folder\\file\.txt' } -Times 2
            Assert-MockCalled -CommandName Write-Warning -Scope It -ParameterFilter { $Message -match 'Name\s+:\s+Stark' } -Times 2
            Assert-MockCalled -CommandName Write-Warning -Scope It -ParameterFilter { $Message -match 'Condition\s+:\s+False' } -Times 2
            Assert-MockCalled -CommandName Write-Warning -Times 8
         }
      }

   }
}
