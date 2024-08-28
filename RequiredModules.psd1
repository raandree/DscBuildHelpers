@{

    InvokeBuild                  = 'latest'
    PSScriptAnalyzer             = 'latest'
    Pester                       = 'latest'
    Plaster                      = 'latest'
    PlatyPS                      = 'latest'
    ModuleBuilder                = 'latest'
    MarkdownLinkCheck            = 'latest'
    ChangelogManagement          = 'latest'
    Sampler                      = @{
        Version    = 'latest'
        Parameters = @{
            AllowPrerelease = $true
        }
    }
    'Sampler.GitHubTasks'        = 'latest'
    'DscResource.Test'           = 'latest'
    'DscResource.AnalyzerRules'  = 'latest'
    'DscResource.DocGenerator'   = 'latest'
    datum                        = 'latest'
    'Datum.ProtectedData'        = 'latest'
    PSDesiredStateConfiguration  = '2.0.7'

    xDscResourceDesigner         = 'latest'
    xPSDesiredStateConfiguration = 'latest'

}
