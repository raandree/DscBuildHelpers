BeforeDiscovery {

    $here = $PSScriptRoot
    $modulePath = Resolve-Path -Path $here\Assets\DscResources\ | Select-Object -ExpandProperty Path

    # Remove empty entries from PSModulePath to prevent PS5's Get-DscResource from
    # failing with "Cannot bind argument to parameter 'Path' because it is an empty string".
    $env:PSModulePath = ($env:PSModulePath -split [System.IO.Path]::PathSeparator).Where({ $_ -ne '' }) -join [System.IO.Path]::PathSeparator
    $env:PSModulePath = "$modulePath;$($env:PSModulePath)"

    $dscResources = Get-DscResource -Name MofBased*, ClassBased* -ErrorAction SilentlyContinue

    $skippedDscResources = ''

    Import-Module -Name datum
    Import-Module -Name DscBuildHelpers -Force

    $datum = New-DatumStructure -DefinitionFile $here\Assets\Datum.yml
    $allNodes = Get-Content -Path $here\Assets\AllNodes.yml -Raw | ConvertFrom-Yaml

    Write-Host 'Reading DSC Resource metadata for supporting CIM based DSC parameters...'
    Initialize-DscResourceMetaInfo -ModulePath $modulePath
    Write-Host 'Done'

    $global:configurationData = @{
        AllNodes = [array]$allNodes
        Datum    = $Datum
    }

    # ClassBasedResource1-3 is excluded from the main tests because it intentionally
    # contains unquoted integer values in a hashtable property. It is tested separately
    # in the 'PS5 integer in class-based resource hashtable' Describe block below.
    $skippedConfigFiles = @('ClassBasedResource1-3')

    [hashtable[]]$testCases = @()
    $configFiles = $datum.Config | Get-Member -MemberType ScriptProperty | Select-Object -ExpandProperty Name
    foreach ($dscResource in $dscResources)
    {
        foreach ($configFile in $configFiles | Where-Object { $_ -like "$($dscResource.Name)*" -and $_ -notin $skippedConfigFiles })
        {
            $testCases += @{
                DscResourceName = $dscResource.Name
                DscModuleName   = $dscResource.ModuleName
                Skip            = ($dscResource.Name -in $skippedDscResources)
                ConfigPath      = $configFile
            }
        }
    }

    $finalTestCases = @()
    $finalTestCases += @{
        AllDscResources      = $DscResources.Name
        FilteredDscResources = $DscResources | Where-Object Name -NotIn $skippedDscResources
        TestCaseCount        = @($testCases | Where-Object Skip -EQ $false).Count
    }
}

Describe 'DSC Composite Resources compile' -Tags FunctionalQuality {

    It "'<DscResourceName>' compiles" -TestCases $testCases {

        if ($Skip)
        {
            Set-ItResult -Skipped -Because "Tests for '$DscResourceName' are skipped"
        }

        $nodeData = @{
            NodeName                    = "localhost_$dscResourceName"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
        }
        $configurationData.AllNodes = @($nodeData)

        $dscConfiguration = @'
configuration TestConfig {

    #<importStatements>

    node 'localhost_<DscResourceName>_<ConfigPath>' {

        $data = $configurationData.Datum.Config.'<ConfigPath>'
        if (-not $data)
        {
            $data = @{}
        }

        (Get-DscSplattedResource -ResourceName <DscResourceName> -ExecutionName _<DscResourceName> -Properties $data -NoInvoke).Invoke($data)
    }
}
'@

        $dscConfiguration = $dscConfiguration.Replace('#<importStatements>', "Import-DscResource -ModuleName $DscModuleName -Name $DscResourceName")
        $dscConfiguration = $dscConfiguration.Replace('<DscResourceName>', $dscResourceName)
        $dscConfiguration = $dscConfiguration.Replace('<ConfigPath>', $configPath)

        $data = $configurationData.Datum.Config.$configPath
        Invoke-Expression -Command $dscConfiguration

        {
            TestConfig -ConfigurationData $configurationData -OutputPath $OutputDirectory -ErrorAction Stop
        } | Should -Not -Throw
    }

    It "'<DscResourceName>' should have created a mof file" -TestCases $testCases {

        if ($Skip)
        {
            Set-ItResult -Skipped -Because "Tests for '$DscResourceName' are skipped"
        }

        $mofFile = Get-Item -Path "$($OutputDirectory)\localhost_$($DscResourceName)_$($ConfigPath).mof" -ErrorAction SilentlyContinue
        $mofFile | Should -BeOfType System.IO.FileInfo
    }

}

Describe 'Final tests' -Tags FunctionalQuality {

    It 'Every DSC resource has compiled' -TestCases $finalTestCases {

        $mofFiles = Get-ChildItem -Path $OutputDirectory -Filter *.mof
        Write-Host "Number of compiled MOF files: $($mofFiles.Count)"
        $TestCaseCount | Should -Be $mofFiles.Count

    }

}

Describe 'PS5 integer in class-based resource hashtable' -Tags FunctionalQuality {

    BeforeAll {
        $here = $PSScriptRoot
        $modulePath = Resolve-Path -Path $here\Assets\DscResources\ | Select-Object -ExpandProperty Path

        Import-Module -Name datum
        Import-Module -Name DscBuildHelpers -Force

        $datum = New-DatumStructure -DefinitionFile $here\Assets\Datum.yml
        $allNodes = Get-Content -Path $here\Assets\AllNodes.yml -Raw | ConvertFrom-Yaml

        Initialize-DscResourceMetaInfo -ModulePath $modulePath

        $script:integerConfigData = @{
            AllNodes = @(
                @{
                    NodeName                    = 'localhost_ClassBasedResource1'
                    PSDscAllowPlainTextPassword = $true
                    PSDscAllowDomainUser        = $true
                }
            )
            Datum = $Datum
        }

        $script:integerData = $datum.Config.'ClassBasedResource1-3'

        # Use a separate output directory to avoid polluting the main MOF output
        # directory, which would cause the 'Final tests' MOF count to be off.
        $script:integerOutputDir = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath 'DscIntegerTest'
        New-Item -Path $script:integerOutputDir -ItemType Directory -Force | Out-Null
    }

    AfterAll {
        Remove-Item -Path $script:integerOutputDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'Compiling a class-based resource with integer hashtable values' {

        $dscConfiguration = @'
configuration IntegerTestConfig {
    Import-DscResource -ModuleName ClassBased -Name ClassBasedResource1

    node 'localhost_ClassBasedResource1_ClassBasedResource1-3' {
        $data = $configurationData.Datum.Config.'ClassBasedResource1-3'
        if (-not $data)
        {
            $data = @{}
        }

        (Get-DscSplattedResource -ResourceName ClassBasedResource1 -ExecutionName _ClassBasedResource1 -Properties $data -NoInvoke).Invoke($data)
    }
}
'@

        Invoke-Expression -Command $dscConfiguration

        if ($PSVersionTable.PSEdition -eq 'Desktop')
        {
            {
                IntegerTestConfig -ConfigurationData $script:integerConfigData -OutputPath $script:integerOutputDir -ErrorAction Stop
            } | Should -Throw -Because "PS5's DSC engine does not allow System.Int32 values in class-based resource hashtable properties"
        }
        else
        {
            {
                IntegerTestConfig -ConfigurationData $script:integerConfigData -OutputPath $script:integerOutputDir -ErrorAction Stop
            } | Should -Not -Throw -Because "PS7's DSC engine accepts System.Int32 values in class-based resource hashtable properties"
        }
    }

}
