@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'Sampler.psm1'

    # Version number of this module.
    ModuleVersion     = '0.118.1'

    # Supported PSEditions
    # CompatiblePSEditions = @('Desktop','Core') # Removed to support PS 5.0

    # ID used to uniquely identify this module
    GUID              = 'b59b8442-9cf9-4c4b-bc40-035336ace573'

    # Author of this module
    Author            = 'Gael Colas'

    # Company or vendor of this module
    CompanyName       = 'SynEdgy Limited'

    # Copyright statement for this module
    Copyright         = '(c) Gael Colas. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Sample Module with Pipeline scripts and its Plaster template to create a module following some of the community accepted practices.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @(
        'Plaster'
    )

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules     = @()

    # Functions to export from this module
    FunctionsToExport = @('Add-Sample','Convert-SamplerHashtableToString','Get-BuildVersion','Get-BuiltModuleVersion','Get-ClassBasedResourceName','Get-CodeCoverageThreshold','Get-MofSchemaName','Get-OperatingSystemShortName','Get-PesterOutputFileFileName','Get-Psm1SchemaName','Get-SamplerAbsolutePath','Get-SamplerBuiltModuleBase','Get-SamplerBuiltModuleManifest','Get-SamplerCodeCoverageOutputFile','Get-SamplerCodeCoverageOutputFileEncoding','Get-SamplerModuleInfo','Get-SamplerModuleRootPath','Get-SamplerProjectName','Get-SamplerSourcePath','Invoke-SamplerGit','Merge-JaCoCoReport','New-SampleModule','New-SamplerJaCoCoDocument','New-SamplerPipeline','Out-SamplerXml','Set-SamplerPSModulePath','Split-ModuleVersion','Update-JaCoCoStatistic')

    # Cmdlets to export from this module
    CmdletsToExport   = ''

    # Variables to export from this module
    VariablesToExport = ''

    # Aliases to export from this module
    AliasesToExport   = '*'

    # List of all modules packaged with this module
    ModuleList        = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
        PSData = @{
            # Extension for Plaster Template discoverability with `Get-PlasterTemplate -IncludeInstalledModules`
            Extensions   = @(
                @{
                    Module         = 'Plaster'
                    minimumVersion = '1.1.3'
                    Details        = @{
                        TemplatePaths = @(
                            'Templates\Classes'
                            'Templates\ClassResource'
                            'Templates\Composite'
                            'Templates\Enum'
                            'Templates\MofResource'
                            'Templates\PrivateFunction'
                            'Templates\PublicCallPrivateFunctions'
                            'Templates\PublicFunction'
                            'Templates\Sampler'
                        )
                    }
                }
            )

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('Template', 'pipeline', 'plaster', 'DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource', 'Windows', 'MacOS', 'Linux')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/gaelcolas/Sampler/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/gaelcolas/Sampler'

            # A URL to an icon representing this module.
            IconUri      = 'https://raw.githubusercontent.com/gaelcolas/Sampler/main/Sampler/assets/sampler.png'

            # ReleaseNotes of this module
            ReleaseNotes = '## [0.118.1] - 2024-07-20

### Added

- Added extensions.json for vscode
- Automatic wiki documentation for public commands.

### Changed

- Update template for SECURITY.md and add it to Sampler repository as well.
- Built module is now built in a separate folder. This is to split the paths
  for the built module and all required modules, to avoid returning duplicate
  modules when using `Get-Module -ListAvailable`. The templates already has
  this configuration.
- Now PSResourceGet always default to the latest released version if no
  specific version is configured or passed as parameter.
- Templates was changed to use PSResourceGet as the default method
  of resolving dependencies. It is possible to change to the method
  PowerShellGet & PSDepend by changing the configuration. Also default to
  using PowerShellGet v3 which is a compatibility module that is a wrapper
  for the equivalent command in PSResourceGet.
- Switch to build worker `windows-latest` for the build phase of the pipeline
  due to a issue using `Publish-Module` on the latest updated build worker in
  Azure Pipelines.
- Public command documentation has been moved from README.md to the GitHub
  repository Wiki.
- Update order of deploy tasks for the Plaster templates to make it easier
  to re-run a deploy phase when a GitHub token has expired.

### Fixed

- Update template for module.tests.ps1. Fixes [#465](https://github.com/gaelcolas/Sampler/issues/465)
- Now the tasks work when using `Set-SamplerTaskVariable` with tasks that
  do not have the parameter `ChocolateyBuildOutput`.
- Remove duplicate SECURITY.md template files, and fix templates to
  point to the single version.
- Correct description of the parameter `GalleryApiToken` in the build task
  script release.module.build.ps1. Fixes [#442](https://github.com/gaelcolas/Sampler/issues/442)
- ModuleFast now supports resolving individual pre-release dependencies
  that is part of _RequiredModules.psd1_. It is also possible to specify
  [NuGet version ranges](https://learn.microsoft.com/en-us/nuget/concepts/package-versioning#version-ranges)
  in _RequiredModules.psd1_, although then the file is not compatible with
  PSResourceGet or PSDepend (so no fallback can happen).
- Now it won''t import legacy PowerShellGet and PackageManagement when
  PSResourceGet or ModuleFast is used.
- Now it works saving PowerShellGet compatibility module when configured.
- Now if both ModuleFast and PowerShellGet compatibility module is configured
  PSResourceGet is automatically added as a dependency. This is for example
  needed for publishing built module to the gallery.
- Update pipeline so build not fail.

'

            Prerelease   = ''
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
