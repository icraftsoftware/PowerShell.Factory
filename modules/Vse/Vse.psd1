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
    RootModule            = 'Vse.psm1'
    ModuleVersion         = '2.0.0.0'
    GUID                  = '27f145fc-2b18-46a0-a9e9-260136597924'
    Author                = 'François Chabot'
    CompanyName           = 'be.stateless'
    Copyright             = '(c) 2012 - 2019 be.stateless. All rights reserved.'
    Description           = 'Utility command to determine which versions of Visual Studio are installed and easily switch between their shell environments to get their respective tools on path.'
    ProcessorArchitecture = 'None'
    PowerShellVersion     = '4.0'
    RequiredAssemblies    = @()
    RequiredModules       = @('Pscx', 'Psx', 'VSSetup')

    AliasesToExport       = @('*')
    CmdletsToExport       = @()
    FunctionsToExport     = @('Assert-VisualStudioEnvironment', 'Clear-VisualStudioEnvironment', 'Get-VisualStudioEnvironment', 'Switch-VisualStudioEnvironment', 'Test-VisualStudioEnvironment')
    VariablesToExport     = @()

    PrivateData           = @{ InstalledVisualStudioVersionNumbers = $null }
}