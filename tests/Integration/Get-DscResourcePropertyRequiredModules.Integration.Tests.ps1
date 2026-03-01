BeforeDiscovery {

    Import-Module -Name DscBuildHelpers -Force

    # Derive $requiredModulesPath if not already set by the build pipeline (InvokeBuild).
    # In PS5, InvokeBuild script-scope variables are not visible inside Pester's scope.
    if (-not $requiredModulesPath)
    {
        $requiredModulesPath = Join-Path -Path $PSScriptRoot -ChildPath '../../output/RequiredModules' | Convert-Path
    }

    $allModules = Get-ModuleFromFolder -ModuleFolder $requiredModulesPath
    $allDscResources = Get-DscResourceFromModuleInFolder -ModuleFolder $requiredModulesPath -Modules $allModules
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
