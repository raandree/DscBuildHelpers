BeforeDiscovery {

    $here = $PSScriptRoot
    $modulePath = "$here\Assets\DscResources\"

    Import-Module -Name PSDesiredStateConfiguration
    Import-Module -Name DscBuildHelpers -Force

    $allModules = Get-ModuleFromFolder -ModuleFolder $modulePath
    $allDscResources = Get-DscResourceFromModuleInFolder -ModuleFolder $modulePath -Modules $allModules
    $modulesWithDscResources = $allDscResources | Select-Object -ExpandProperty ModuleName -Unique
    $modulesWithDscResources = $allModules | Where-Object Name -In $modulesWithDscResources

    [hashtable[]]$testCases = @()
    foreach ($dscResource in $allDscResources)
    {
        $testCases += @{
            DscResourceName            = $dscResource.Name
            DscResourceType            = $dscResource.ImplementedAs
            DscResourceProperties      = $dscResource.Properties
            DscResourcePropertiesCount = $dscResource.Properties.Count
            DscModuleName              = $dscResource.ModuleName
        }
    }

    Write-Host "Discovered $($allDscResources.Count) DSC Resources in $($modulesWithDscResources.Count) modules."
}

Describe 'Get-DscResourceProperty Tests' -Tags FunctionalQuality {

    It "'Get-DscResourceProperty' with '<DscResourceName>' does not throw" -TestCases $testCases {

        InModuleScope DscBuildHelpers -Parameters $_ {
            {
                Get-DscResourceProperty -ModuleName $DscModuleName -ResourceName $DscResourceName -ErrorAction Stop
            } | Should -Not -Throw
        }
    }

    It "'Get-DscResourceProperty' with '<DscResourceName>' returns <DscResourcePropertiesCount> properties" -TestCases $testCases {

        if ($DscResourceType -eq 'Composite')
        {
            Set-ItResult -Skipped -Because 'Composite DSC resources are not supported'
        }

        InModuleScope DscBuildHelpers -Parameters $_ {
            $result = Get-DscResourceProperty -ModuleName $DscModuleName -ResourceName $DscResourceName
            $result.Count | Should -Be $DscResourceProperties.Count
        }
    }

}
