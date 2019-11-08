function _BizTalk.Factory: {
    Set-Location 'C:\Files\Projects\be.stateless\BizTalk.Factory\src\'
}

function cpr {
    Clear-Project -Recurse
}

function cppr {
    Clear-Project -Packages -Recurse
}

function Restore-NugetPackages {
    Get-ChildItem *.sln | ForEach-Object { .\.nuget\NuGet.exe restore $_.Name }
}

function npr { 
    Restore-NugetPackages
}

Import-Module posh-git
#Start-SshAgent -Quiet
