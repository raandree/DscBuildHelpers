@{
    RootModule        = 'DscBuildHelpers.psm1'

    ModuleVersion     = '0.2.0'

    GUID              = '23ccd4bf-0a52-4077-986f-c153893e5a6a'

    Author            = 'Gael Colas'

    Copyright         = '(c) 2022 Gael Colas. All rights reserved.'

    Description       = 'Build Helpers for DSC Resources and Configurations'

    PowerShellVersion = '5.0'

    RequiredModules   = @(
        @{ ModuleName = 'xDscResourceDesigner'; ModuleVersion = '1.9.0.0' } #tested with 1.9.0.0
    )

    FunctionsToExport = @('Clear-CachedDscResource','Compress-DscResourceModule','Find-ModuleToPublish','Get-DscCimInstanceReference','Get-DscFailedResource','Get-DscResourceFromModuleInFolder','Get-DscResourceProperty','Get-DscResourceWmiClass','Get-DscSplattedResource','Get-ModuleFromFolder','Initialize-DscResourceMetaInfo','Publish-DscConfiguration','Publish-DscResourceModule','Push-DscConfiguration','Push-DscModuleToNode','Remove-DscResourceWmiClass','Test-DscResourceFromModuleInFolderIsValid')

    AliasesToExport = ''

    PrivateData       = @{

        PSData = @{

            Prerelease   = 'test'

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'BuildHelpers', 'DSCResource')

            # A URL to the license for this module.
            #LicenseUri = 'https://github.com/gaelcolas/DscBuildHelpers/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/gaelcolas/DscBuildHelpers'

            # A URL to an icon representing this module.
            IconUri      = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # ReleaseNotes of this module
            ReleaseNotes = '## [0.2.0-test] - 2024-10-21

### Changed

- Updated build scripts.
- Aligned dependencies with other related projects.
- Set gitversion in Azure pipeline to 5.*.
- Use ''ModuleFast'' in Azure pipeline.
- Aligned ''build.yml'' with one from other related projects.
- Added dummy test.
- Made code HQRM compliant.
- Added Pester tests for ''Get-DscSplattedResource''.

'

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}
