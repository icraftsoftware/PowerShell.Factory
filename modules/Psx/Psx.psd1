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

@{
   RootModule            = 'Psx.psm1'
   ModuleVersion         = '2.0.0.0'
   GUID                  = '217de01f-f2e1-460a-99a4-b8895d0dd071'
   Author                = 'François Chabot'
   CompanyName           = 'be.stateless'
   Copyright             = '(c) 2012 - 2019 be.stateless. All rights reserved.'
   Description           = 'Useful PowerShell function helpers.'
   ProcessorArchitecture = 'None'
   PowerShellVersion     = '4.0'
   NestedModules         = @(
      'Alias\Alias.psm1',
      'Bitness\Bitness.psm1',
      'HashTable\HashTable.psm1',
      'Pipeline\Pipeline.psm1',
      'ScriptBlock\ScriptBlock.psm1',
      'UAC\UAC.psm1'
   )
   RequiredModules       = @('Pscx')

   AliasesToExport       = @('*')
   CmdletsToExport       = @()
   FunctionsToExport     = @(
      # Alias.psm1
      'Get-CommandAlias',
      # Bitness.psm1
      'Assert-32bitProcess',
      'Assert-64bitProcess',
      'Test-32bitArchitecture',
      'Test-32bitProcess',
      'Test-64bitArchitecture',
      'Test-64bitProcess',
      # HastTable.psm1
      'Compare-HashTable',
      'Merge-HashTable',
      # Pipeline.psm1
      'Test-Any',
      'Test-None',
      # ScriptBlock.psm1
      'Convert-ScriptBlockParametersToDynamicParameters',
      'Invoke-ScriptBlock',
      # UAC.psm1
      'Assert-Elevated',
      'Test-Elevated'
   )
   VariablesToExport     = @()
}
