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

Set-StrictMode -Version Latest

function Convert-ScriptBlockParametersToDynamicParameters {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.RuntimeDefinedParameterDictionary])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [scriptblock]
        $ScriptBlock
    )
    begin {
        # https://stackoverflow.com/questions/26910789/is-it-possible-to-reuse-a-param-block-across-multiple-functions
        $commonParameterNames = [FormatterServices]::GetUninitializedObject([CommonParameters]) |
            Get-Member -MemberType Properties |
                Select-Object -ExpandProperty Name
        $dynamicParameters = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    }
    process {
        $ScriptBlock.Ast.ParamBlock | Select-Object -ExpandProperty Parameters |
            Where-Object -FilterScript { $commonParameterNames -notcontains $_.Name.VariablePath.UserPath } |
                ForEach-Object -Process {
                    $paramName = $_.Name.VariablePath.UserPath
                    $paramAttributes = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                    $_.Attributes | ForEach-Object -Process {
                        $attributeType = Invoke-Expression -Command "[$($_.TypeName.FullName)]"
                        if ([System.Management.Automation.Internal.CmdletMetadataAttribute].IsAssignableFrom($attributeType)) {
                            $attribute = New-Object -TypeName $attributeType.FullName -ArgumentList @($_.PositionalArguments | ForEach-Object Value)
                            $_.NamedArguments | ForEach-Object -Process {
                                $attribute.($_.ArgumentName) = Invoke-Expression -Command ($_.Argument.Extent.Text)
                            }
                            $paramAttributes.Add($attribute)
                        }
                    }
                    $param = New-Object System.Management.Automation.RuntimeDefinedParameter $paramName, $_.StaticType, $paramAttributes
                    $dynamicParameters.Add($paramName, $param)
                }
}
end {
    $dynamicParameters
}
}

function Invoke-ScriptBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter(Mandatory = $true)]
        [psobject]
        $Parameters
    )
    process {
        $expectedParameters = @( $ScriptBlock.Ast.ParamBlock | Select-Object -ExpandProperty Parameters | ForEach-Object -Process { $_.Name.VariablePath.UserPath } )
        $unexpectedParameters = @( $Parameters.Keys | Where-Object -FilterScript { $_ -notin $expectedParameters } )
        $unexpectedParameters | ForEach-Object -Process { $Parameters.Remove($_) | Out-Null }
        & $ScriptBlock @Parameters
    }
}

<#
 # Main
 #>

# https://stackoverflow.com/questions/48703289/how-to-get-powershell-type-accelerator-list-in-an-accelerated-way
[accelerators]::Add('CommonParameters', 'System.Management.Automation.Internal.CommonParameters')
[accelerators]::Add('FormatterServices', 'System.Runtime.Serialization.FormatterServices')
