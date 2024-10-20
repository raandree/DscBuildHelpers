#Region '.\Private\Assert-DscModuleResourceIsValid.ps1' -1

function Assert-DscModuleResourceIsValid
{
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $DscResources
    )

    begin
    {
        Write-Verbose 'Testing for valid resources.'
        $failedDscResources = @()
    }

    process
    {
        foreach ($DscResource in $DscResources)
        {
            $failedDscResources += Get-FailedDscResource -DscResource $DscResource
        }
    }

    end
    {
        if ($failedDscResources.Count -gt 0)
        {
            Write-Verbose 'Found failed resources.'
            foreach ($resource in $failedDscResources)
            {
                Write-Warning "`t`tFailed Resource - $($resource.Name) ($($resource.Version))"
            }

            throw 'One or more resources is invalid.'
        }
    }
}
#EndRegion '.\Private\Assert-DscModuleResourceIsValid.ps1' 38
#Region '.\Private\Get-RequiredModulesFromMOF.ps1' -1

#author Iain Brighton, from here: https://gist.github.com/iainbrighton/9d3dd03630225ee44126769c5d9c50a9
# Not sure that takes all possibilities into account:
# i.e. when using Import-DscResource -Name ResourceName #even if it's bad practice
# Also need to return PSModuleInfo, instead of @{ModuleName='<version>'}
# Then probably worth promoting to public
function Get-RequiredModulesFromMOF
{
    <#
    .SYNOPSIS
        Scans a Desired State Configuration .mof file and returns the declared/
        required modules.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Path
    )

    process
    {
        $modules = @{}
        $moduleName = $null
        $moduleVersion = $null

        Get-Content -Path $Path -Encoding Unicode | ForEach-Object {

            $line = $_
            if ($line -match '^\s?Instance of')
            {
                ## We have a new instance so write the existing one
                if (($null -ne $moduleName) -and ($null -ne $moduleVersion))
                {
                    $modules[$moduleName] = $moduleVersion
                    $moduleName = $null
                    $moduleVersion = $null
                    Write-Verbose "Module Instance found: '$moduleName $moduleVersion'."
                }
            }
            elseif ($line -match '(?<=^\s?ModuleName\s?=\s?")\S+(?=";)')
            {
                ## Ignore the default PSDesiredStateConfiguration module
                if ($Matches[0] -notmatch 'PSDesiredStateConfiguration')
                {
                    $moduleName = $Matches[0]
                    Write-Verbose "Found Module Name '$modulename'."
                }
                else
                {
                    Write-Verbose 'Excluding PSDesiredStateConfiguration module'
                }
            }
            elseif ($line -match '(?<=^\s?ModuleVersion\s?=\s?")\S+(?=";)')
            {
                $moduleVersion = $Matches[0] -as [System.Version]
                Write-Verbose "Module version = '$moduleVersion'."
            }
        }

        $modules
    }
}
#EndRegion '.\Private\Get-RequiredModulesFromMOF.ps1' 64
#Region '.\Private\Get-StandardCimType.ps1' -1

function Get-StandardCimType
{
    $types = @{
        Boolean               = 'System.Boolean'
        UInt8                 = 'System.Byte'
        SInt8                 = 'System.SByte'
        UInt16                = 'System.UInt16'
        SInt16                = 'System.Int16'
        UInt32                = 'System.UInt32'
        SInt32                = 'System.Int32'
        UInt64                = 'System.UInt64'
        SInt64                = 'System.Int64'
        Real32                = 'System.Single'
        Real64                = 'System.Double'
        Char16                = 'System.Char'
        DateTime              = 'System.DateTime'
        String                = 'System.String'
        Reference             = 'Microsoft.Management.Infrastructure.CimInstance'
        Instance              = 'Microsoft.Management.Infrastructure.CimInstance'
        BooleanArray          = 'System.Boolean[]'
        UInt8Array            = 'System.Byte[]'
        SInt8Array            = 'System.SByte[]'
        UInt16Array           = 'System.UInt16[]'
        SInt16Array           = 'System.Int16[]'
        UInt32Array           = 'System.UInt32[]'
        SInt32Array           = 'System.Int32[]'
        UInt64Array           = 'System.UInt64[]'
        SInt64Array           = 'System.Int64[]'
        Real32Array           = 'System.Single[]'
        Real64Array           = 'System.Double[]'
        Char16Array           = 'System.Char[]'
        DateTimeArray         = 'System.DateTime[]'
        StringArray           = 'System.String[]'

        MSFT_Credential       = 'System.Management.Automation.PSCredential'
        'MSFT_KeyValuePair[]' = 'System.Collections.Hashtable'
        MSFT_KeyValuePair     = 'System.Collections.Hashtable'
    }

    try
    {
        $types.GetEnumerator() | ForEach-Object {
            $null = Invoke-Command -ScriptBlock ([scriptblock]::Create("[$($_.Value)]")) -ErrorAction Stop
            [PSCustomObject]@{
                CimType    = $_.Key
                DotNetType = $_.Value
            }
        }
    }
    catch
    {
        Write-Error -Message "Failed to load CIM Types. The error was: $($_.Exception.Message)"
    }
}
#EndRegion '.\Private\Get-StandardCimType.ps1' 55
#Region '.\Private\Resolve-ModuleMetadataFile.ps1' -1


function Resolve-ModuleMetadataFile
{
    [CmdletBinding(DefaultParameterSetName = 'ByDirectoryInfo')]
    param (
        [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $Path,

        [Parameter(ParameterSetName = 'ByDirectoryInfo', Mandatory = $true, ValueFromPipeline = $true)]
        [System.IO.DirectoryInfo]
        $InputObject
    )

    process
    {
        $metadataFileFound = $true
        $metadataFilePath = ''
        Write-Verbose "Using Parameter set - $($PSCmdlet.ParameterSetName)."
        switch ($PSCmdlet.ParameterSetName)
        {
            'ByPath'
            {
                Write-Verbose "Testing Path - $path."
                if (Test-Path -Path $Path)
                {
                    Write-Verbose "`tFound $path."
                    $item = (Get-Item -Path $Path)
                    if ($item.PSIsContainer)
                    {
                        Write-Verbose "`t`tIt is a folder."
                        $moduleName = Split-Path $Path -Leaf
                        $metadataFilePath = Join-Path -Path $Path -ChildPath "$moduleName.psd1"
                        $metadataFileFound = Test-Path -Path $metadataFilePath
                    }
                    else
                    {
                        if ($item.Extension -like '.psd1')
                        {
                            Write-Verbose "`t`tIt is a module metadata file."
                            $metadataFilePath = $item.FullName
                            $metadataFileFound = $true
                        }
                        else
                        {
                            $modulePath = Split-Path -Path $Path
                            Write-Verbose "`t`tSearching for module metadata folder in '$ModulePath'."
                            $moduleName = Split-Path $modulePath -Leaf
                            Write-Verbose "`t`tModule name is '$moduleName'."
                            $metadataFilePath = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"
                            Write-Verbose "`t`tChecking for '$metadataFilePath'."
                            $metadataFileFound = Test-Path -Path $metadataFilePath
                        }
                    }
                }
                else
                {
                    $metadataFileFound = $false
                }
            }
            'ByDirectoryInfo'
            {
                $moduleName = $InputObject.Name
                $metadataFilePath = Join-Path -Path $InputObject.FullName -ChildPath "$moduleName.psd1"
                $metadataFileFound = Test-Path -Path $metadataFilePath
            }
        }

        if ($metadataFileFound -and (-not [string]::IsNullOrEmpty($metadataFilePath)))
        {
            Write-Verbose "Found a module metadata file at '$metadataFilePath'."
            Convert-Path -Path $metadataFilePath
        }
        else
        {
            Write-Error "Failed to find a module metadata file at '$metadataFilePath'."
        }
    }
}
#EndRegion '.\Private\Resolve-ModuleMetadataFile.ps1' 80
#Region '.\Public\Clear-CachedDscResource.ps1' -1

function Clear-CachedDscResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWMICmdlet', '', Justification = 'Not possible via CIM')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param ()

    if ($pscmdlet.ShouldProcess($env:computername))
    {
        Write-Verbose 'Stopping any existing WMI processes to clear cached resources.'

        ### find the process that is hosting the DSC engine
        $dscProcessID = Get-WmiObject msft_providers |
            Where-Object { $_.provider -like 'dsccore' } |
                Select-Object -ExpandProperty HostProcessIdentifier

        ### Stop the process
        if ($dscProcessID -and $PSCmdlet.ShouldProcess('DSC Process'))
        {
            Get-Process -Id $dscProcessID | Stop-Process
        }
        else
        {
            Write-Verbose 'Skipping killing the DSC Process'
        }

        Write-Verbose 'Clearing out any tmp WMI classes from tested resources.'
        Get-DscResourceWmiClass -Class tmp* | Remove-DscResourceWmiClass
    }
}
#EndRegion '.\Public\Clear-CachedDscResource.ps1' 30
#Region '.\Public\Compress-DscResourceModule.ps1' -1

function Compress-DscResourceModule
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $DscBuildOutputModules,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        [PSModuleInfo[]]
        $Modules
    )

    begin
    {
        if (-not (Test-Path -Path $DscBuildOutputModules))
        {
            mkdir -Path $DscBuildOutputModules -Force
        }
    }

    process
    {
        foreach ($module in $Modules)
        {
            if ($PSCmdlet.ShouldProcess("Compress $Module $($Module.Version) from $(Split-Path -Parent $Module.Path) to $DscBuildOutputModules"))
            {
                Write-Verbose "Publishing Module $(Split-Path -Parent $Module.Path) to $DscBuildOutputModules"
                $destinationPath = Join-Path -Path $DscBuildOutputModules -ChildPath "$($module.Name)_$($module.Version).zip"
                Compress-Archive -Path "$($module.ModuleBase)\*" -DestinationPath $destinationPath

                (Get-FileHash -Path $destinationPath).Hash | Set-Content -Path "$destinationPath.checksum" -NoNewline
            }
        }
    }
}
#EndRegion '.\Public\Compress-DscResourceModule.ps1' 39
#Region '.\Public\Find-ModuleToPublish.ps1' -1

function Find-ModuleToPublish
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $DscBuildSourceResources,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Microsoft.PowerShell.Commands.ModuleSpecification[]]
        $ExcludedModules = $null,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $DscBuildOutputModules
    )

    $modulesAvailable = Get-ModuleFromFolder -ModuleFolder $DscBuildSourceResources -ExcludedModules $ExcludedModules

    foreach ($module in $modulesAvailable)
    {
        $publishTargetZip = [System.IO.Path]::Combine(
            $DscBuildOutputModules,
            "$($module.Name)_$($module.version).zip"
        )
        $publishTargetZipCheckSum = [System.IO.Path]::Combine(
            $DscBuildOutputModules,
            "$($module.Name)_$($module.version).zip.checksum"
        )

        $zipExists = Test-Path -Path $publishTargetZip
        $checksumExists = Test-Path -Path $publishTargetZipCheckSum

        if (-not ($zipExists -and $checksumExists))
        {
            Write-Debug "ZipExists = $zipExists; CheckSum exists = $checksumExists"
            Write-Verbose -Message "Adding $($Module.Name)_$($Module.Version) to the Modules To Publish"
            Write-Output -InputObject $Module
        }
        else
        {
            Write-Verbose -Message "$($Module.Name) does not need to be published"
        }
    }
}
#EndRegion '.\Public\Find-ModuleToPublish.ps1' 48
#Region '.\Public\Get-DscCimInstanceReference.ps1' -1

function Get-DscCimInstanceReference
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification='For debugging purposes')]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ResourceName,

        [Parameter(Mandatory = $true)]
        [string]
        $ParameterName,

        [Parameter()]
        [object]
        $Data
    )

    if ($Script:allDscResourcePropertiesTable)
    {
        if ($allDscResourcePropertiesTable.ContainsKey("$($ResourceName)-$($ParameterName)"))
        {
            $p = $allDscResourcePropertiesTable."$($ResourceName)-$($ParameterName)"
            $typeConstraint = $p.TypeConstraint -replace '\[\]', ''
            Get-DscSplattedResource -ResourceName $typeConstraint -Properties $Data -NoInvoke
        }
    }
    else
    {
        Write-Host "No DSC Resource Properties metadata was found, cannot translate CimInstance parameters. Call 'Initialize-DscResourceMetaInfo' first is this is needed."
    }
}
#EndRegion '.\Public\Get-DscCimInstanceReference.ps1' 32
#Region '.\Public\Get-DscFailedResource.ps1' -1

function Get-DscFailedResource
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo[]]
        $DscResource
    )

    process
    {
        foreach ($resource in $DscResource)
        {
            if ($resource.Path)
            {
                $resourceNameOrPath = Split-Path $resource.Path -Parent
            }
            else
            {
                $resourceNameOrPath = $resource.Name
            }

            if (-not (Test-xDscResource -Name $resourceNameOrPath))
            {
                Write-Warning "`tResources $($_.name) is invalid."
                $resource
            }
            else
            {
                Write-Verbose ('DSC Resource Name {0} {1} is Valid' -f $resource.Name, $resource.Version)
            }
        }
    }
}
#EndRegion '.\Public\Get-DscFailedResource.ps1' 35
#Region '.\Public\Get-DscResourceFromModuleInFolder.ps1' -1

function Get-DscResourceFromModuleInFolder
{
    [CmdletBinding()]
    [OutputType([object[]])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleFolder,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSModuleInfo[]]
        $Modules
    )

    begin
    {
        $oldPSModulePath = $env:PSModulePath
        $env:PSModulePath = $ModuleFolder

        Write-Verbose "Retrieving all resources for '$ModuleFolder'."
        $dscResources = Get-DscResource

        $env:PSModulePath = $oldPSModulePath

        $result = @()
    }

    process
    {
        Write-Verbose "Filtering the $($dscResources.Count) resources."
        Write-Debug ($dscResources | Format-Table -AutoSize | Out-String)

        foreach ($dscResource in $dscResources)
        {
            if ($null -eq $dscResource.Module)
            {
                Write-Debug "Excluding resource '$($dscResource.Name) - $($dscResource.Version)', it is not part of a module."
                continue
            }

            foreach ($module in $Modules)
            {
                if (-not (Compare-Object -ReferenceObject $dscResource.Module -DifferenceObject $Module -Property ModuleType, Version, Name))
                {
                    Write-Debug "Resource $($dscResource.Name) matches one of the supplied Modules."
                    Write-Debug "`tIncluding $($dscResource.Name) $($dscResource.Version)"
                    $result += $dscResource
                }
            }
        }
    }

    end
    {
        $result
    }
}
#EndRegion '.\Public\Get-DscResourceFromModuleInFolder.ps1' 60
#Region '.\Public\Get-DscResourceProperty.ps1' -1

function Get-DscResourceProperty
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ModuleInfo')]
        [System.Management.Automation.PSModuleInfo]
        $ModuleInfo,

        [Parameter(Mandatory = $true, ParameterSetName = 'ModuleName')]
        [string]
        $ModuleName,

        [Parameter(Mandatory = $true)]
        [string]
        $ResourceName
    )

    $ModuleInfo = if ($ModuleName)
    {
        Import-Module -Name $ModuleName -PassThru -Force
    }
    else
    {
        Import-Module -Name $ModuleInfo.Name -PassThru -Force
    }

    [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ClearCache()
    $functionsToDefine = New-Object -TypeName 'System.Collections.Generic.Dictionary[string,ScriptBlock]'([System.StringComparer]::OrdinalIgnoreCase)
    [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::LoadDefaultCimKeywords($functionsToDefine)

    $schemaFilePath = $null
    $keywordErrors = New-Object -TypeName 'System.Collections.ObjectModel.Collection[System.Exception]'

    $foundCimSchema = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportCimKeywordsFromModule($ModuleInfo, $ResourceName, [ref] $SchemaFilePath, $functionsToDefine, $keywordErrors)
    if ($foundCimSchema)
    {
        [void][Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportScriptKeywordsFromModule($ModuleInfo, $ResourceName, [ref] $SchemaFilePath, $functionsToDefine)
    }
    else
    {
        [System.Collections.Generic.List[string]]$resourceNameAsList = $ResourceName
        [void][Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportClassResourcesFromModule($ModuleInfo, $resourceNameAsList, $functionsToDefine)
    }

    $resourceProperties = ([System.Management.Automation.Language.DynamicKeyword]::GetKeyword($ResourceName)).Properties

    foreach ($key in $resourceProperties.Keys)
    {
        $resourceProperty = $resourceProperties.$key

        $dscClassParameterInfo = & $ModuleInfo {

            param (
                [Parameter(Mandatory = $true)]
                [string]$TypeName
            )

            $result = @{
                ElementType = $null
                Type        = $null
            }

            try
            {
                $result.Type = Invoke-Command -ScriptBlock ([scriptblock]::Create("[$($TypeName)]"))

                if ($result.Type.IsArray)
                {
                    $result.ElementType = $result.Type.GetElementType().FullName
                }
            }
            catch
            {
                Write-Verbose "The type '$TypeName' could not be resolved."
            }

            return $result

        } $resourceProperty.TypeConstraint

        [PSCustomObject]@{
            Name           = $resourceProperty.Name
            ModuleName     = $ModuleInfo.Name
            ResourceName   = $ResourceName
            TypeConstraint = $resourceProperty.TypeConstraint
            Attributes     = $resourceProperty.Attributes
            Values         = $resourceProperty.Values
            ValueMap       = $resourceProperty.ValueMap
            Mandatory      = $resourceProperty.Mandatory
            IsKey          = $resourceProperty.IsKey
            Range          = $resourceProperty.Range
            ElementType    = $dscClassParameterInfo.ElementType
            Type           = $dscClassParameterInfo.Type
        }
    }
}
#EndRegion '.\Public\Get-DscResourceProperty.ps1' 97
#Region '.\Public\Get-DscResourceWmiClass.ps1' -1

function Get-DscResourceWmiClass
{
    <#
        .Synopsis
            Retrieves WMI classes from the DSC namespace.
        .Description
            Retrieves WMI classes from the DSC namespace.
        .Example
            Get-DscResourceWmiClass -Class tmp*
        .Example
            Get-DscResourceWmiClass -Class 'MSFT_UserResource'
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWMICmdlet', '', Justification = 'Not possible via CIM')]
    param (
        #The WMI Class name search for. Supports wildcards.
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [string]
        $Class
    )

    begin
    {
        $dscNamespace = 'root/Microsoft/Windows/DesiredStateConfiguration'
    }

    process
    {
        Get-WmiObject -Namespace $dscNamespace -List @PSBoundParameters
    }
}
#EndRegion '.\Public\Get-DscResourceWmiClass.ps1' 33
#Region '.\Public\Get-DscSplattedResource.ps1' -1

function Get-DscSplattedResource
{
    [CmdletBinding()]
    [OutputType([scriptblock])]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $ResourceName,

        [Parameter()]
        [String]
        $ExecutionName,

        [Parameter()]
        [hashtable]
        $Properties,

        [Parameter()]
        [switch]
        $NoInvoke
    )

    if (-not $script:allDscResourcePropertiesTable -and -not $script:allDscResourcePropertiesTableWarningShown)
    {
        Write-Warning -Message "The 'allDscResourcePropertiesTable' is not defined. This will be an expensive operation. Resources with MOF sub-types are only supported when calling 'Initialize-DscResourceMetaInfo' once before starting the compilation process."
        $script:allDscResourcePropertiesTableWarningShown = $true
    }

    $standardCimTypes = Get-StandardCimType

    # Remove Case Sensitivity of ordered Dictionary or Hashtables
    $Properties = @{} + $Properties

    $stringBuilder = [System.Text.StringBuilder]::new()
    $null = $stringBuilder.AppendLine("Param([hashtable]`$Parameters)")
    $null = $stringBuilder.AppendLine()

    if ($ExecutionName)
    {
        $null = $stringBuilder.AppendLine("$ResourceName '$ExecutionName' {")
    }
    else
    {
        $null = $stringBuilder.AppendLine("$ResourceName {")
    }

    foreach ($PropertyName in $Properties.Keys)
    {
        $cimType = $allDscResourcePropertiesTable."$ResourceName-$PropertyName"
        if ($cimType)
        {
            $isCimArray = $cimType.TypeConstraint.EndsWith('[]')
            $cimProperties = $Properties.$PropertyName
            $null = $stringBuilder.AppendLine("$PropertyName = {0}" -f $(if ($isCimArray)
                    {
                        '@('
                    }
                    else
                    {
                        "$($cimType.TypeConstraint.Replace('[]', '')) {"
                    }))
            if ($isCimArray)
            {
                if ($Properties.$PropertyName -isnot [array])
                {
                    Write-Warning -Message "The property '$PropertyName' is an array and the BindingInfo data is not an array" -ErrorAction Stop
                }

                $i = 0
                foreach ($cimPropertyValue in $cimProperties)
                {
                    $null = $stringBuilder.AppendLine($cimType.TypeConstraint.Replace('[]', ''))
                    $null = $stringBuilder.AppendLine('{')

                    foreach ($cimSubProperty in $cimPropertyValue.GetEnumerator())
                    {
                        if ($cimType.Type.GetElementType().GetProperty($cimSubProperty.Name).PropertyType.IsArray)
                        {
                            $null = $stringBuilder.AppendLine("$($cimSubProperty.Name) = @(")
                            $arrayItemTypeName = $cimType.Type.GetElementType().GetProperty($cimSubProperty.Name).PropertyType.GetElementType().Name

                            $j = 0

                            $isCimSubArray = $cimType.Type.GetElementType().GetProperty($cimSubProperty.Name).PropertyType.GetElementType().FullName -notin $standardCimTypes.DotNetType

                            foreach ($arrayItem in $cimSubProperty.Value)
                            {
                                if ($isCimSubArray)
                                {
                                    $null = $stringBuilder.AppendLine("$arrayItemTypeName {")

                                    foreach ($arrayItemKey in $arrayItem.Keys)
                                    {
                                        $null = $stringBuilder.AppendLine("$arrayItemKey = `$Parameters['$PropertyName'][$($i)]['$($cimSubProperty.Name)'][$($j)]['$($arrayItemKey)']")
                                    }

                                    $null = $stringBuilder.AppendLine('}')
                                }
                                else
                                {
                                    $null = $stringBuilder.AppendLine("@(`$Parameters['$PropertyName'][$($i)]['$($cimSubProperty.Name)'])[$($j)]")
                                }
                                $j++
                            }
                            $null = $stringBuilder.AppendLine(')')
                        }
                        else
                        {
                            $null = $stringBuilder.AppendLine("$($cimSubProperty.Name) = `$Parameters['$PropertyName'][$($i)]['$($cimSubProperty.Name)']")
                        }
                    }

                    $null = $stringBuilder.AppendLine('}')
                    $i++
                }

                $null = $stringBuilder.AppendLine('{0}' -f $(if ($isCimArray)
                        {
                            ')'
                        }))
            }
            else
            {
                foreach ($cimProperty in $cimProperties.GetEnumerator())
                {
                    $null = $stringBuilder.AppendLine("$($cimProperty.Name) = `$Parameters['$PropertyName']['$($($cimProperty.Name))']")
                }

                $null = $stringBuilder.AppendLine('}')
            }
        }
        else
        {
            $null = $stringBuilder.AppendLine("$PropertyName = `$Parameters['$PropertyName']")
        }
    }

    $null = $stringBuilder.AppendLine('}')
    Write-Debug -Message ('Generated Resource Block = {0}' -f $stringBuilder.ToString())

    if ($NoInvoke)
    {
        [scriptblock]::Create($stringBuilder.ToString())
    }
    else
    {
        if ($Properties)
        {
            [scriptblock]::Create($stringBuilder.ToString()).Invoke($Properties)
        }
        else
        {
            [scriptblock]::Create($stringBuilder.ToString()).Invoke()
        }
    }
}

Set-Alias -Name x -Value Get-DscSplattedResource -Scope Global
#EndRegion '.\Public\Get-DscSplattedResource.ps1' 159
#Region '.\Public\Get-ModuleFromFolder.ps1' -1

function Get-ModuleFromFolder
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSModuleInfo[]])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.DirectoryInfo[]]
        $ModuleFolder,

        [Parameter()]
        [AllowNull()]
        [Microsoft.PowerShell.Commands.ModuleSpecification[]]
        $ExcludedModules
    )

    begin
    {
        $allModulesInFolder = @()
    }

    process
    {
        foreach ($folder in $ModuleFolder)
        {
            Write-Debug -Message "Replacing Module path with $folder"
            $oldPSModulePath = $env:PSModulePath
            $env:PSModulePath = $folder
            Write-Debug -Message 'Discovering modules from folder'
            $allModulesInFolder += Get-Module -Refresh -ListAvailable
            Write-Debug -Message 'Reverting PSModulePath'
            $env:PSModulePath = $oldPSModulePath
        }
    }

    end
    {

        $allModulesInFolder | Where-Object {
            $source = $_
            Write-Debug -Message "Checking if module '$source' is sxcluded."
            $isExcluded = foreach ($excludedModule in $ExcludedModules)
            {
                Write-Debug "`t Excluded module '$ExcludedModule'"
                if (($excludedModule.Name -and $excludedModule.Name -eq $source.Name) -and
                    (
                        (-not $excludedModule.Version -and
                        -not $excludedModule.Guid -and
                        -not $excludedModule.MaximumVersion -and
                        -not $excludedModule.RequiredVersion ) -or
                        ($excludedModule.Version -and $excludedModule.Version -eq $source.Version) -or
                        ($excludedModule.Guid -and $excludedModule.Guid -ne $source.Guid) -or
                        ($excludedModule.MaximumVersion -and $excludedModule.MaximumVersion -ge $source.Version) -or
                        ($excludedModule.RequiredVersion -and $excludedModule.RequiredVersion -eq $source.Version)
                    )
                )
                {
                    Write-Debug ('Skipping {0} {1} {2}' -f $source.Name, $source.Version, $source.Guid)
                    return $false
                }
            }
            if (-not $isExcluded)
            {
                return $true
            }
        }
    }

}
#EndRegion '.\Public\Get-ModuleFromFolder.ps1' 70
#Region '.\Public\Initialize-DscResourceMetaInfo.ps1' -1

function Initialize-DscResourceMetaInfo
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ModulePath,

        [Parameter()]
        [switch]
        $ReturnAllProperties,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [switch]
        $PassThru
    )

    if ($script:allDscResourcePropertiesTable.Count -ne 0 -and -not $Force)
    {
        if ($PassThru)
        {
            return $script:allDscResourcePropertiesTable
        }
        else
        {
            return
        }
    }

    $allModules = Get-ModuleFromFolder -ModuleFolder $ModulePath
    $allDscResources = Get-DscResourceFromModuleInFolder -ModuleFolder $ModulePath -Modules $allModules
    $modulesWithDscResources = $allDscResources | Select-Object -ExpandProperty ModuleName -Unique
    $modulesWithDscResources = $allModules | Where-Object Name -In $modulesWithDscResources

    $standardCimTypes = Get-StandardCimType

    $script:allDscResourcePropertiesTable = @{}

    $script:allDscResourceProperties = foreach ($dscResource in $allDscResources)
    {
        $moduleInfo = $modulesWithDscResources |
            Where-Object { $_.Name -EQ $dscResource.ModuleName -and $_.Version -eq $dscResource.Version }

        $cimProperties = if ($ReturnAllProperties)
        {
            Get-DscResourceProperty -ModuleInfo $moduleInfo -ResourceName $dscResource.Name
        }
        else
        {
            Get-DscResourceProperty -ModuleInfo $moduleInfo -ResourceName $dscResource.Name |
                Where-Object TypeConstraint -NotIn $standardCimTypes.CimType
        }

        foreach ($cimProperty in $cimProperties)
        {
            [PSCustomObject]@{
                Name           = $cimProperty.Name
                TypeConstraint = $cimProperty.TypeConstraint
                IsKey          = $cimProperty.IsKey
                Mandatory      = $cimProperty.Mandatory
                Values         = $cimProperty.Values
                Range          = $cimProperty.Range
                ModuleName     = $dscResource.ModuleName
                ResourceName   = $dscResource.Name
            }
            $script:allDscResourcePropertiesTable."$($dscResource.Name)-$($cimProperty.Name)" = $cimProperty
        }

    }

    if ($PassThru)
    {
        $script:allDscResourcePropertiesTable
    }
}
#EndRegion '.\Public\Initialize-DscResourceMetaInfo.ps1' 79
#Region '.\Public\Publish-DscConfiguration.ps1' -1

function Publish-DscConfiguration
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $DscBuildOutputConfigurations,

        [Parameter()]
        [string]
        $PullServerWebConfig = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer\web.config"
    )

    process
    {
        Write-Verbose "Publishing Configuration MOFs from '$DscBuildOutputConfigurations'."

        Get-ChildItem -Path (Join-Path -Path $DscBuildOutputConfigurations -ChildPath '*.mof') |
            ForEach-Object {
                if (-not (Test-Path -Path $PullServerWebConfig))
                {
                    Write-Warning "The Pull Server configg '$PullServerWebConfig' cannot be found."
                    Write-Warning "`t Skipping Publishing Configuration MOFs"
                }
                elseif ($PSCmdlet.shouldprocess($_.BaseName))
                {
                    Write-Verbose -Message "Publishing $($_.Name)"
                    Publish-MofToPullServer -FullName $_.FullName -PullServerWebConfig $PullServerWebConfig
                }
            }
    }
}
#EndRegion '.\Public\Publish-DscConfiguration.ps1' 33
#Region '.\Public\Publish-DscResourceModule.ps1' -1


function Publish-DscResourceModule
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $DscBuildOutputModules,

        [Parameter()]
        [System.IO.FileInfo]
        $PullServerWebConfig = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer\web.config"
    )

    begin
    {
        if (-not (Test-Path $PullServerWebConfig))
        {
            if ($PSBoundParameters['ErrorAction'] -eq 'SilentlyContinue')
            {
                Write-Warning -Message "Could not find the Web.config of the pull Server at '$PullServerWebConfig'."
            }
            else
            {
                throw "Could not find the Web.config of the pull Server at '$PullServerWebConfig'."
            }
            return
        }
        else
        {
            $webConfigXml = [xml](Get-Content -Raw -Path $PullServerWebConfig)
            $configXElement = $webConfigXml.SelectNodes("//appSettings/add[@key = 'ConfigurationPath']")
            $OutputFolderPath = $configXElement.Value
        }
    }

    process
    {
        if ($OutputFolderPath)
        {
            Write-Verbose 'Moving Processed Resource Modules from'
            Write-Verbose "`t$DscBuildOutputModules to"
            Write-Verbose "`t$OutputFolderPath"

            if ($PSCmdlet.ShouldProcess("copy '$DscBuildOutputModules' to '$OutputFolderPath'"))
            {
                Get-ChildItem -Path $DscBuildOutputModules -Include @('*.zip', '*.checksum') |
                    Copy-Item -Destination $OutputFolderPath -Force
            }
        }
    }
}
#EndRegion '.\Public\Publish-DscResourceModule.ps1' 53
#Region '.\Public\Push-DscConfiguration.ps1' -1

function Push-DscConfiguration
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Runspaces.PSSession]
        $Session,

        [Parameter()]
        [Alias('MOF', 'Path')]
        [System.IO.FileInfo]
        $ConfigurationDocument,

        [Parameter()]
        [System.Management.Automation.PSModuleInfo[]]
        $WithModule,

        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true, Position = 1)]
        [Alias('DscBuildOutputModules')]
        $StagingFolderPath = "$Env:TMP\DSC\BuildOutput\modules\",

        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true, Position = 3)]
        $RemoteStagingPath = '$Env:TMP\DSC\modules\',

        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true, Position = 4)]
        [switch]
        $Force
    )

    process
    {
        if ($PSCmdlet.ShouldProcess($Session.ComputerName, "Applying MOF '$ConfigurationDocument'"))
        {
            if ($WithModule)
            {
                Push-DscModuleToNode -Module $WithModule -StagingFolderPath $StagingFolderPath -RemoteStagingPath $RemoteStagingPath -Session $Session
            }

            Write-Verbose 'Removing previously pushed configuration documents'
            $resolvedRemoteStagingPath = Invoke-Command -Session $Session -ScriptBlock {
                $resolvedStagingPath = $ExecutionContext.InvokeCommand.ExpandString($Using:RemoteStagingPath)
                $null = Get-Item "$resolvedStagingPath\*.mof" | Remove-Item -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $resolvedStagingPath))
                {
                    mkdir -Force $resolvedStagingPath -ErrorAction Stop
                }
                $resolvedStagingPath
            } -ErrorAction Stop

            $remoteConfigDocumentPath = [System.IO.Path]::Combine($ResolvedRemoteStagingPath, 'localhost.mof')

            Copy-Item -ToSession $Session -Path $ConfigurationDocument -Destination $remoteConfigDocumentPath -Force -ErrorAction Stop

            Write-Verbose "Attempting to apply '$remoteConfigDocumentPath' on '$($session.ComputerName)'"
            Invoke-Command -Session $Session -ScriptBlock {
                Start-DscConfiguration -Wait -Force -Path $Using:resolvedRemoteStagingPath -Verbose -ErrorAction Stop
            }
        }
    }
}
#EndRegion '.\Public\Push-DscConfiguration.ps1' 63
#Region '.\Public\Push-DscModuleToNode.ps1' -1

<#
    .SYNOPSIS
    Injects Modules via PS Session.

    .DESCRIPTION
    Injects the missing modules on a remote node via a PSSession.
    The module list is checked again the available modules from the remote computer,
    Any missing version is then zipped up and sent over the PS session,
    before being extracted in the root PSModulePath folder of the remote node.

    .PARAMETER Module
    A list of Modules required on the remote node. Those missing will be packaged based
    on their Path.

    .PARAMETER StagingFolderPath
    Staging folder where the modules are being zipped up locally before being sent accross.

    .PARAMETER Session
    Session to use to gather the missing modules and to copy the modules to.

    .PARAMETER RemoteStagingPath
    Path on the remote Node where the modules will be copied before extraction.

    .PARAMETER Force
    Force all modules to be re-zipped, re-sent, and re-extracted to the target node.

    .EXAMPLE
    Push-DscModuleToNode -Module (Get-ModuleFromFolder C:\src\SampleKitchen\modules) -Session $RemoteSession -StagingFolderPath "C:\BuildOutput"

#>
function Push-DscModuleToNode
{
    [CmdletBinding()]
    [OutputType([void])]
    param (
        # Param1 help description
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true)]
        [Alias('ModuleInfo')]
        [System.Management.Automation.PSModuleInfo[]]
        $Module,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true)]
        [Alias('DscBuildOutputModules')]
        $StagingFolderPath = "$Env:TMP\DSC\BuildOutput\modules\",

        [Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true)]
        [System.Management.Automation.Runspaces.PSSession]
        $Session,

        [Parameter(Position = 3, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true)]
        $RemoteStagingPath = '$Env:TMP\DSC\modules\',

        [Parameter(Position = 4, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true)]
        [switch]
        $Force
    )

    process
    {
        # Find the modules already available remotely
        if (-not $Force)
        {
            $remoteModuleAvailable = Invoke-Command -Session $Session -ScriptBlock {
                Get-Module -ListAvailable
            }
        }

        $resolvedRemoteStagingPath = Invoke-Command -Session $Session -ScriptBlock {
            $ResolvedStagingPath = $ExecutionContext.InvokeCommand.ExpandString($using:RemoteStagingPath)
            if (-not (Test-Path $ResolvedStagingPath))
            {
                mkdir -Force $ResolvedStagingPath
            }
            $resolvedStagingPath
        }

        # Find the modules missing on remote node
        $missingModules = $Module.Where{
            $matchingModule = foreach ($remoteModule in $RemoteModuleAvailable)
            {
                if (
                    $remoteModule.Name -eq $_.Name -and
                    $remoteModule.Version -eq $_.Version -and
                    $remoteModule.Guid -eq $_.Guid
                )
                {
                    Write-Verbose "Module match: '$($remoteModule.Name)'."
                    $remoteModule
                }
            }
            if (-not $matchingModule)
            {
                Write-Verbose "Module not found: '$($_.Name)'."
                $_
            }
        }
        Write-Verbose "The Missing modules are '$($MissingModules.Name -join ', ')'."

        # Find the missing modules from the staging folder
        #  and publish it there
        Write-Verbose "Looking for missing zip modules in '$($StagingFolderPath)'."
        $missingModules.Where{ -not (Test-Path -Path "$StagingFolderPath\$($_.Name)_$($_.version).zip") } |
            Compress-DscResourceModule -DscBuildOutputModules $StagingFolderPath

        # Copy missing modules to remote node if not present already
        foreach ($module in $missingModules)
        {
            $fileName = "$($StagingFolderPath)/$($module.Name)_$($module.Version).zip"
            $testPathResult = Invoke-Command -Session $Session -ScriptBlock {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]
                    $FileName
                )
                Test-Path -Path $FileName
            } -ArgumentList $fileName

            if ($Force -or -not ($testPathResult))
            {
                Write-Verbose "Copying '$fileName*' to '$ResolvedRemoteStagingPath'."
                Invoke-Command -Session $Session -ScriptBlock {
                    param (
                        [Parameter(Mandatory = $true)]
                        [string]
                        $PathToZips
                    )
                    if (-not (Test-Path -Path $PathToZips))
                    {
                        mkdir -Path $PathToZips -Force
                    }
                } -ArgumentList $resolvedRemoteStagingPath

                $param = @{
                    ToSession   = $Session
                    Path        = "$($StagingFolderPath)/$($module.Name)_$($module.Version)*"
                    Destination = $ResolvedRemoteStagingPath
                    Force       = $true
                }
                Copy-Item @param | Out-Null
            }
            else
            {
                Write-Verbose 'The File is already present remotely.'
            }
        }

        # Extract missing modules on remote node to PSModulePath
        Write-Verbose "Expanding '$resolvedRemoteStagingPath/*.zip' to '$env:CommonProgramW6432\WindowsPowerShell\Modules\$($Module.Name)\$($module.version)'."
        Invoke-Command -Session $Session -ScriptBlock {
            param (
                [Parameter()]
                $MissingModules,
                [Parameter()]
                $PathToZips
            )
            foreach ($module in $MissingModules)
            {
                $fileName = "$($module.Name)_$($module.version).zip"
                Write-Verbose "Expanding '$PathToZips/$fileName' to '$Env:CommonProgramW6432\WindowsPowerShell\Modules\$($Module.Name)\$($module.version)'."
                Expand-Archive -Path "$PathToZips/$fileName" -DestinationPath "$Env:ProgramW6432\WindowsPowerShell\Modules\$($Module.Name)\$($module.version)" -Force
            }
        } -ArgumentList $missingModules, $resolvedRemoteStagingPath
    }
}
#EndRegion '.\Public\Push-DscModuleToNode.ps1' 165
#Region '.\Public\Remove-DscResourceWmiClass.ps1' -1

<#
    .Synopsis
        Removes a WMI class from the DSC namespace.
    .Description
        Removes a WMI class from the DSC namespace.
    .Example
        Get-DscResourceWmiClass -Class tmp* | Remove-DscResourceWmiClass
    .Example
        Remove-DscResourceWmiClass -Class 'tmpD460'
#>
function Remove-DscResourceWmiClass
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWMICmdlet', '', Justification = 'Not possible via CIM')]
    [CmdletBinding()]
    param (
        #The WMI Class name to remove.  Supports wildcards.
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [string]
        $ResourceType
    )

    begin
    {
        $dscNamespace = 'root/Microsoft/Windows/DesiredStateConfiguration'
    }

    process
    {
        #Have to use WMI here because I can't find how to delete a WMI instance via the CIM cmdlets.
        (Get-WmiObject -Namespace $dscNamespace -List -Class $ResourceType).psbase.Delete()
    }
}
#EndRegion '.\Public\Remove-DscResourceWmiClass.ps1' 34
#Region '.\Public\Test-DscResourceFromModuleInFolderIsValid.ps1' -1

function Test-DscResourceFromModuleInFolderIsValid
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.DirectoryInfo]
        $ModuleFolder,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [System.Management.Automation.PSModuleInfo[]]
        [AllowNull()]
        $Modules
    )

    process
    {
        foreach ($module in $Modules)
        {
            $Resources = Get-DscResourceFromModuleInFolder -ModuleFolder $ModuleFolder -Modules $module

            $Resources.Where{ $_.ImplementedAs -eq 'PowerShell' } | Assert-DscModuleResourceIsValid
        }
    }
}
#EndRegion '.\Public\Test-DscResourceFromModuleInFolderIsValid.ps1' 26
