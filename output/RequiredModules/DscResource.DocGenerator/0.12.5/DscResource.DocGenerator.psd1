@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'DscResource.DocGenerator.psm1'

    # Version number of this module.
    ModuleVersion     = '0.12.5'

    GUID              = 'fa8b017d-8e6e-414d-9ab7-c8ab9cb9e9a4'

    # Author of this module
    Author            = 'DSC Community'

    # Company or vendor of this module
    CompanyName       = 'DSC Community'

    # Copyright statement for this module
    Copyright         = '(c) DSC Community contributors.'

    # Description of the functionality provided by this module
    Description       = 'Functionality to help generate documentation for modules.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # RequiredModules = @('Sampler') # The Sampler Pack task does not support recursive pack yet.

    <#
        Functions to export from this module, for best performance, do not use
        wildcards and do not delete the entry, use an empty array if there are
        no functions to export.

        This will be automatically update by the build pipeline.
    #>
    FunctionsToExport = @('Add-NewLine','Edit-CommandDocumentation','Invoke-Git','New-DscResourcePowerShellHelp','New-DscResourceWikiPage','New-GitHubWikiSidebar','Publish-WikiContent','Remove-MarkdownMetadataBlock','Set-WikiModuleVersion')

    <#
        Cmdlets to export from this module, for best performance, do not use
        wildcards and do not delete the entry, use an empty array if there are
        no cmdlets to export.
    #>
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    <#
        Aliases to export from this module, for best performance, do not use
        wildcards and do not delete the entry, use an empty array if there are
        no aliases to export.

        This must be set to the aliases to export since there is no way to tell
        the module builder (build pipeline) which aliases to add.
    #>
    AliasesToExport   = @('Task.Clean_Markdown_Metadata','Task.Clean_Markdown_Of_Public_Commands','Task.Copy_Source_Wiki_Folder','Task.Create_Wiki_Output_Folder','Task.Generate_Conceptual_Help','Task.Generate_External_Help_File_For_Public_Commands','Task.Generate_Markdown_For_DSC_Resources','Task.Generate_Markdown_For_Public_Commands','Task.Generate_Wiki_Content','Task.Generate_Wiki_Sidebar','Task.Package_Wiki_Content','Task.Publish_GitHub_Wiki_Content')

    # DSC resources to export from this module
    DscResourcesToExport = @()

    <#
        Private data to pass to the module specified in RootModule/ModuleToProcess.
        This may also contain a PSData hashtable with additional module metadata
        used by PowerShell.
    #>
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DSC', 'Modules', 'documentation')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/dsccommunity/DscResource.DocGenerator/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/dsccommunity/DscResource.DocGenerator'

            # ReleaseNotes of this module
            ReleaseNotes = '## [0.12.5] - 2024-08-14

- `Get-ClassResourceProperty`
  - Check for a prefixed and non-prefixed class names [issue #132](https://github.com/dsccommunity/DscResource.DocGenerator/issues/132).
- `azure-pipelines`
  - Pin gitversion to V5.
- Update README with the tasks that were not documented.
- `Generate_Wiki_Content`
  - Change the order of the tasks to avoid getting and exception when
    `source/WikiSource` contain additional markdown files that are copied
    to `output/WikiContent`.

'

            # Prerelease string of this module
            Prerelease = ''
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
