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

Describe 'Import-ItemGroup' {
    InModuleScope Group {

        Context 'Getting help about Import-ItemGroup command' {
            It 'extracts ItemGroup file path from command invocation.' {
                Mock -Verifiable -CommandName Test-Path -ParameterFilter { $Path -eq 'Variable:Path' } -MockWith { $false }
                Mock -Verifiable -CommandName Get-PSCallStack -MockWith { @( [PSCustomObject]@{ } , [PSCustomObject]@{ Position = [PSCustomObject]@{ Text = 'Get-Help -Name Import-ItemGroup -Path c:\files\ItemGroup.psd1' } } ) }
                Mock -Verifiable -CommandName Test-Path -ParameterFilter { $Path -eq 'c:\files\ItemGroup.psd1' }-MockWith { $true }
                Mock -Verifiable -CommandName Get-Item -ParameterFilter { $Path -eq 'c:\files\ItemGroup.psd1' } -MockWith { [PSCustomObject]@{ PSIsContainer = $false } }
                Mock -Verifiable -CommandName Get-Content -ParameterFilter { $Path -eq 'c:\files\ItemGroup.psd1' -and $Raw.IsPresent }

                Get-Help -Name Import-ItemGroup -Path c:\files\ItemGroup.psd1

                Assert-VerifiableMock
            }
            It 'describes CmdletBinding''s parameter section of referenced ItemGroup file.' {
                Mock -CommandName Test-Path -ParameterFilter { $Path -eq 'Variable:Path' } -MockWith { $false }
                Mock -CommandName Get-PSCallStack -MockWith { @( [PSCustomObject]@{ } , [PSCustomObject]@{ Position = [PSCustomObject]@{ Text = 'Get-Help -Name Import-ItemGroup -Path c:\files\ItemGroup.psd1' } } ) }
                Mock -CommandName Test-Path -ParameterFilter { $Path -eq 'c:\files\ItemGroup.psd1' }-MockWith { $true }
                Mock -CommandName Get-Item -ParameterFilter { $Path -eq 'c:\files\ItemGroup.psd1' } -MockWith { [PSCustomObject]@{ PSIsContainer = $false } }
                Mock -CommandName Get-Content -ParameterFilter { $Path -eq 'c:\files\ItemGroup.psd1' -and $Raw.IsPresent } -MockWith { @'
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, HelpMessage = 'File Layout Configuration')]
    [ValidateSet('Debug', 'Release', 'Package')]
    [string]
    $Configuration = 'Debug',

    [Parameter(Mandatory = $false)]
    [switch]
    $IncludeTestArtifacts
)
@{ }
'@ }

                $syntax = Get-Help -Name Import-ItemGroup -Path c:\files\ItemGroup.psd1 |
                    Select-Object -ExpandProperty syntax |
                    Select-Object -ExpandProperty syntaxItem

                # asserts that Get-Help outputs
                # SYNTAX
                #    Import-ItemGroup [-Path] <string> [-Configuration {Debug | Release | Package}] [-IncludeTestArtifacts]
                #    [<CommonParameters>]
                $syntax.parameter | Should -HaveCount 3

                $syntax.parameter[0].name | Should -Be 'Path'
                $syntax.parameter[0].isDynamic | Should -Be 'false'
                $syntax.parameter[0].type.name | Should -Be 'string'

                $syntax.parameter[1].name | Should -Be 'Configuration'
                $syntax.parameter[1].isDynamic | Should -Be 'true'
                $syntax.parameter[1].type.name | Should -Be 'string'
                $syntax.parameter[1].parameterValueGroup | Select-Object -ExpandProperty parameterValue | Should -Be @('Debug', 'Release', 'Package')

                $syntax.parameter[2].name | Should -Be 'IncludeTestArtifacts'
                $syntax.parameter[2].isDynamic | Should -Be 'true'
                $syntax.parameter[2].type.name | Should -Be 'switch'

                $syntax.CommonParameters | Should -BeTrue
            }
        }

    }
}
