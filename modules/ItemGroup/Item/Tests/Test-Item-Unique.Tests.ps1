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

Describe 'Test-Item-Unique' {
   InModuleScope Item {

      Context 'Unicity check is conditionned by the Validity check.' {
         It 'ignores invalid Items during Unicity check.' {
            $items = @( @{ Name = 'one' }, @{ Name = 'two' }, @{ Path = $null; Name = 'same' }, @{Path = $null; Name = 'same' } )
            # even though last two Items have the same Name they are invalid
            Test-Item -Item $items -Valid -WarningAction SilentlyContinue | Should -Be @($true, $true, $false, $false)
            # and unicity check is consequently satisfied
            Test-Item -Item $items -Unique -WarningAction SilentlyContinue | Should -Be $true

            # whereas if all Items are assumed to be valid
            Mock -CommandName Test-Item -ParameterFilter { $Valid.IsPresent } -MockWith { @($true, $true, $true, $true) <# assumes Items are not valid #> } -Verifiable
            Test-Item -Item $items -Valid | Should -Be @($true, $true, $true, $true)

            # unicity check will not be satisfied anymore because the last two Items have the same Name
            Test-Item -Item $items -Unique -WarningAction SilentlyContinue | Should -Be $false

            Assert-VerifiableMock
         }
      }

      Context 'Unicity check when Items are given by argument.' {
         Mock -CommandName Test-Item -ParameterFilter { $Valid.IsPresent } -MockWith { $true <# assumes every Item is valid #> }
         It 'Is true when Items have different Names.' {
            Test-Item -Item @( @{ Name = 'one' }, [PSCustomObject]@{ Name = 'two' } ) -Unique | Should -Be $true
         }
         It 'Is false when Items have the same Name.' {
            Test-Item -Item @( @{ Name = 'one' }, [PSCustomObject]@{ Name = 'one' } ) -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
         It 'Is true when Items have different Paths.' {
            Test-Item -Item @( @{ Path = 'z:\one' }, [PSCustomObject]@{ Path = 'z:\two' } ) -Unique | Should -Be $true
         }
         It 'Is false when Items have the same Path.' {
            Test-Item -Item @( @{ Path = 'z:\one' }, [PSCustomObject]@{ Path = 'z:\one' } ) -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
         It 'Is false when Items have different Names but the same Path beause Path has precedence.' {
            Test-Item -Item @( @{ Name = 'Stark' ; Path = 'z:\one' }, [PSCustomObject]@{ Stark = 'Parker' ; Path = 'z:\one' } ) -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
         It 'Is true when Items have the same Name but different Paths because Path has precedence.' {
            Test-Item -Item @( @{ Name = 'same' ; Path = 'z:\one' }, [PSCustomObject]@{ Stark = 'same' ; Path = 'z:\two' } ) -Unique | Should -Be $true
         }
         It 'Is false for an array of Items.' {
            $items = @( @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'Three' } )
            Test-Item -Item $items -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
         It 'Is false for an array of array of Items.' {
            $items = @(
               @( @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'One' } )
               @( @{Name = 'Two' }, @{Name = 'Three' } )
            )
            Test-Item -Item $items -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
      }

      Context 'Unicity check when Items are given by pipeline.' {
         Mock -CommandName Test-Item -ParameterFilter { $Valid.IsPresent } -MockWith { $true <# assumes every Item is valid #> }
         It 'Is true when Items have different Names.' {
            @{ Name = 'one' }, [PSCustomObject]@{ Name = 'two' } | Test-Item -Unique | Should -Be $true
         }
         It 'Is false when Items have the same Name.' {
            @{ Name = 'one' }, [PSCustomObject]@{ Name = 'one' } | Test-Item -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
         It 'Is true when Items have different Paths.' {
            @{ Path = 'z:\one' }, [PSCustomObject]@{ Path = 'z:\two' } | Test-Item -Unique | Should -Be $true
         }
         It 'Is false when Items have the same Path.' {
            @( @{ Path = 'z:\one' }, [PSCustomObject]@{ Path = 'z:\one' } ) | Test-Item -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
         It 'Is false when Items have different Names but the same Path beause Path has precedence.' {
            @( @{ Name = 'Stark' ; Path = 'z:\one' }, [PSCustomObject]@{ Stark = 'Parker' ; Path = 'z:\one' } ) | Test-Item -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
         It 'Is true when Items have the same Name but different Paths because Path has precedence.' {
            @( @{ Name = 'same' ; Path = 'z:\one' }, [PSCustomObject]@{ Stark = 'same' ; Path = 'z:\two' } ) | Test-Item -Unique | Should -Be $true
         }
         It 'Is false for an array of Items.' {
            $items = @( @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'Three' } )
            $items | Test-Item -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
         It 'Is false for an array of array of Items.' {
            $items = @(
               @( @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'One' } )
               @( @{Name = 'Two' }, @{Name = 'Three' } )
            )
            $items | Test-Item -Unique -WarningAction SilentlyContinue | Should -Be $false
         }
      }

      Context "Unicity check warns about any duplicate Item." {
         Mock -CommandName Write-Warning
         It 'Warns about every property for every duplicate Item.' {
            @{ Name = 'One' ; City = 'City' }, @{ Name = 'Two' ; City = 'City' }, @{ Name = 'One' ; City = 'City' } | Test-Item -Unique | Should -Be $false

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item ''One'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'City\s+:\s+City' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:\s+One' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -Exactly 6
         }
         It 'Warns about each duplicate Item given by the pipeline.' {
            @{ Name = 'One' }, @{ Name = 'Two' }, @{ Name = 'One' }, @{ Name = 'Two' }, @{ Name = 'Three' } | Test-Item -Unique | Should -Be $false

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item ''One'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:\s+One' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item ''Two'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:\s+Two' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -Exactly 8
         }
         It 'Warns about each duplicate Item in an array given by argument.' {
            $item = @( @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'Three' } )
            Test-Item -Item $item -Unique | Should -Be $false

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item ''One'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:\s+One' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item ''Two'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:\s+Two' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -Exactly 8
         }
         It 'Warns about each duplicate Item across arrays given by argument.' {
            $items = @(
               @( @{Name = 'One' }, @{Name = 'Two' }, @{Name = 'One' } )
               @( @{Name = 'Two' }, @{Name = 'Three' } )
            )
            Test-Item -Item $items -Unique | Should -Be $false

            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item ''One'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:\s+One' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -eq 'The following Item ''Two'' has been defined multiple times:' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -ParameterFilter { $Message -match 'Name\s+:\s+Two' } -Exactly 2
            Assert-MockCalled -Scope It -CommandName Write-Warning -Exactly 8
         }
      }

   }
}
