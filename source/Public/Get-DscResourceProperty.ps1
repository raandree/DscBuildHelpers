function Get-DscResourceProperty
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ModuleInfo')]
        [System.Management.Automation.PSModuleInfo]
        $ModuleInfo,

        [Parameter(Mandatory, ParameterSetName = 'ModuleName')]
        [string]
        $ModuleName,

        [Parameter(Mandatory)]
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
        $foundScriptSchema = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportScriptKeywordsFromModule($ModuleInfo, $ResourceName, [ref] $SchemaFilePath, $functionsToDefine)
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
                ElementType         = $null
                Type                = $null
                IsArray             = $false
            }

            try
            {
                $result.Type = Invoke-Expression "[$($TypeName)]"

                if ($result.Type.IsArray)
                {
                    $result.ElementType = $result.Type.GetElementType().FullName
                    $result.IsArray = $true
                }
            }
            catch
            {
            }

            return $result

        } $resourceProperty.TypeConstraint

        $isArrayType = if ($null -ne $dscClassParameterInfo.Type){
            $dscClassParameterInfo.IsArray
        }
        else
        {
            $resourceProperty.TypeConstraint -match '.+\[\]'
        }

        [PSCustomObject]@{
            Name                = $resourceProperty.Name
            ModuleName          = $ModuleInfo.Name
            ResourceName        = $ResourceName
            TypeConstraint      = $resourceProperty.TypeConstraint
            Attributes          = $resourceProperty.Attributes
            Values              = $resourceProperty.Values
            ValueMap            = $resourceProperty.ValueMap
            Mandatory           = $resourceProperty.Mandatory
            IsKey               = $resourceProperty.IsKey
            Range               = $resourceProperty.Range
            IsArray             = $isArrayType
            ElementType         = $dscClassParameterInfo.ElementType
            Type                = $dscClassParameterInfo.Type
        }
    }
}
