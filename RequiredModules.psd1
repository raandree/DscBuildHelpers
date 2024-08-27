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

    xDscResourceDesigner         = 'latest'
    xPSDesiredStateConfiguration = 'latest'

}
