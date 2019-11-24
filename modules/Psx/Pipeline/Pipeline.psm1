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

<#
.SYNOPSIS
    Tests whether there is anything in a pipeline.
.DESCRIPTION
    This command will return $true if there is anything in the pipeline, or $false otherwise.
.EXAMPLE
    PS> Get-ChildItem | Test-Any
.NOTES
    See https://blogs.msdn.microsoft.com/jaredpar/2008/06/12/is-there-anything-in-that-pipeline/
    © 2018 be.stateless.
#>
function Test-Any {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [AllowEmptyCollection()]
        [psobject[]]
        $InputObject
    )
    begin {
        $any = $false
    }
    process {
        $any = $true
    }
    end {
        $any
    }
}

<#
.SYNOPSIS
    Tests whether there is nothing in a pipeline.
.DESCRIPTION
    This command will return $true if there is nothing in the pipeline, or $false otherwise.
.EXAMPLE
    PS> Get-ChildItem | Test-None
.NOTES
    © 2018 be.stateless.
#>
function Test-None {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [AllowEmptyCollection()]
        [psobject[]]
        $InputObject
    )
    begin {
        $none = $true
    }
    process {
        $none = $false
    }
    end {
        $none
    }
}
