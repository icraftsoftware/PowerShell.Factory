﻿#region Copyright & License

# Copyright © 2012 - 2015 François Chabot, Yves Dierick
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
    GUID                  = '0c7067a3-79aa-468c-b4c8-aaa3e15a5d96'
    Author                = 'François Chabot'
    CompanyName           = 'be.stateless'
    Copyright             = '(c) 2012 - 2015 be.stateless. All rights reserved.'
    Description           = 'Functions to Bind, Build, Install and Update BizTalk Server flows, or applications, via BizTalk Deployment Framework scripts.'
    ModuleToProcess       = 'MSBuild.psm1'
    ModuleVersion         = '2.0'
    ProcessorArchitecture = 'None'
    PowerShellVersion     = '4.0'
    RequiredAssemblies    = @('Microsoft.Build')
    RequiredModules       = @('Psx')

    AliasesToExport       = @('*')
    CmdletsToExport       = @()
    FunctionsToExport     = @('Invoke-MSBuild', 'Get-MSBuildTargets', 'Clear-Project', 'Get-VisualStudioVersionNumbers', '*-VisualStudioEnvironment')
    VariablesToExport     = @()

    PrivateData           = @{ InstalledVisualStudioVersionNumbers = $null }
}