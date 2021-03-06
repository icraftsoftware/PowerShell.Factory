﻿#region Copyright & License

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
    RootModule            = 'Tfs.psm1'
    ModuleVersion         = '1.0.0.0'
    GUID                  = 'c3ecee78-0920-45dd-bc46-4b46033825d6'
    Author                = 'François Chabot'
    CompanyName           = 'be.stateless'
    Copyright             = '(c) 2012 - 2019 be.stateless. All rights reserved.'
    Description           = 'Team Foundation Server Workspace Commands.'
    ProcessorArchitecture = 'None'
    PowerShellVersion     = '3.0'
    RequiredAssemblies    = @()
    RequiredModules       = @('Psx', 'MSBuild')
  
    AliasesToExport       = @()
    CmdletsToExport       = @()
    FunctionsToExport     = @('Get-Workspace', 'New-Workspace', 'New-WorkspaceShortcut', 'Test-Workspace')
    VariablesToExport     = @()
}