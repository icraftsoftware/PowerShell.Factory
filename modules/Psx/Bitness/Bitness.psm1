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
    Ensures the current process is 32 bit.
.DESCRIPTION
    This command will throw if the current process is not a 32 bit process and will silently complete otherwise.
.EXAMPLE
    PS> Assert-32bitProcess
.EXAMPLE
    PS> Assert-32bitProcess -Verbose
    With the -Verbose switch, this command will confirm this process is 32 bit.
.NOTES
    © 2012 be.stateless.
#>
function Assert-32bitProcess {
    [CmdletBinding()]
    param()

    if (-not(Test-32bitProcess)) {
        throw "A 32 bit process is required to run this function!"
    }
    Write-Verbose "Process is 32 bit."
}

<#
.SYNOPSIS
    Ensures the current process is 64 bit.
.DESCRIPTION
    This command will throw if the current process is not a 64 bit process and will silently complete otherwise.
.EXAMPLE
    PS> Assert-64bitProcess
.EXAMPLE
    PS> Assert-64bitProcess -Verbose
    With the -Verbose switch, this command will confirm this process is 64 bit.
.NOTES
    © 2012 be.stateless.
#>
function Assert-64bitProcess {
    [CmdletBinding()]
    param()

    if (-not(Test-64bitProcess)) {
        throw "A 64 bit process is required to run this function!"
    }
    Write-Verbose "Process is 64 bit."
}

<#
.SYNOPSIS
    Returns whether the current operating system is 32 bit.
.DESCRIPTION
    This command will return $true if the current operating system is 32 bit, or $false otherwise.
.EXAMPLE
    PS> Test-32bitArchitecture
.NOTES
    © 2012 be.stateless.
#>
function Test-32bitArchitecture {
    [CmdletBinding()]
    param()

    # http://msdn.microsoft.com/en-us/library/windows/desktop/aa394373(v=vs.85).aspx
    # On a 32-bit operating system, the value is 32 and on a 64-bit operating system it is 64
    [bool]((Get-WmiObject -Class Win32_Processor -ComputerName $Env:COMPUTERNAME | Select-Object -First 1).AddressWidth -eq 32)
}

<#
.SYNOPSIS
    Returns whether the current process is 32 bit.
.DESCRIPTION
    This command will return $true if the current process is 32 bit, or $false otherwise.
.EXAMPLE
    PS> Test-32bitProcess
.NOTES
    © 2012 be.stateless.
#>
function Test-32bitProcess {
    [CmdletBinding()]
    param()

    [bool]($Env:PROCESSOR_ARCHITECTURE -eq 'x86')
}

<#
.SYNOPSIS
    Returns whether the current operating system is 64 bit.
.DESCRIPTION
    This command will return $true if the current operating system is 64 bit, or $false otherwise.
.EXAMPLE
    PS> Test-64bitArchitecture
.NOTES
    © 2012 be.stateless.
#>
function Test-64bitArchitecture {
    [CmdletBinding()]
    param()

    # http://msdn.microsoft.com/en-us/library/windows/desktop/aa394373(v=vs.85).aspx
    # On a 32-bit operating system, the value is 32 and on a 64-bit operating system it is 64
    [bool]((Get-WmiObject -Class Win32_Processor -ComputerName $Env:COMPUTERNAME | Select-Object -First 1).AddressWidth -eq 64)
}

<#
.SYNOPSIS
    Returns whether the current process is 64 bit.
.DESCRIPTION
    This command will return $true if the current process is 64 bit, or $false otherwise.
.EXAMPLE
    PS> Test-64bitProcess
.NOTES
    © 2012 be.stateless.
#>
function Test-64bitProcess {
    [CmdletBinding()]
    param()

    [bool]($Env:PROCESSOR_ARCHITECTURE -match '64')
}
