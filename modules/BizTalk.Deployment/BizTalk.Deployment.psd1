#region Copyright & License

# Copyright © 2012 - 2017 François Chabot
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
   GUID                  = '533b5f59-49ce-4f51-a293-cb78f5cf81b5'
   Author                = 'François Chabot'
   CompanyName           = 'be.stateless'
   Copyright             = '(c) 2017 be.stateless. All rights reserved.'
   Description           = 'BizTalk Server deployment task to be used in conjunction with InvokeBuild module.'
   ModuleToProcess       = 'BizTalk.Deployment.psm1'
   ModuleVersion         = '1.0'
   ProcessorArchitecture = 'None'
   PowerShellVersion     = '4.0'
   RequiredAssemblies    = @('Microsoft.BizTalk.ExplorerOM', 'Microsoft.BizTalk.Operations')
   RequiredModules       = @('InvokeBuild')

   AliasesToExport       = @('*')
   CmdletsToExport       = @()
   FunctionsToExport     = @('*')
   VariablesToExport     = @()

   PrivateData           = @{ MgmtDbServer = $null ; MgmtDbName = $null }
}
