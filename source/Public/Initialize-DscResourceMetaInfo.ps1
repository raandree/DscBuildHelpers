function Initialize-DscResourceMetaInfo
{
    param (
        [Parameter(Mandatory)]
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
    $script:allDscSchemaClasses = @()

    $script:allDscResourceProperties = foreach ($dscResource in $allDscResources)
    {
        $moduleInfo = $modulesWithDscResources |
            Where-Object { $_.Name -EQ $dscResource.ModuleName -and $_.Version -eq $dscResource.Version }

        try
        {
            $m = [System.Tuple]::Create($dscResource.Module.Name, [System.Version]$dscResource.Version)
            $exceptionCollection = [System.Collections.ObjectModel.Collection[System.Exception]]::new()
            $f = [System.IO.Path]::ChangeExtension($dscResource.Path, 'schema.mof')

            $dscSchemaClasses = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportClasses($f, $m, $exceptionCollection)
            foreach ($dscSchemaClass in $dscSchemaClasses)
            {
                $dscSchemaClass | Add-Member -Name ModuleName -MemberType NoteProperty -Value $dscResource.ModuleName
                $dscSchemaClass | Add-Member -Name ModuleVersion -MemberType NoteProperty -Value $dscResource.Version
                $dscSchemaClass | Add-Member -Name ResourceName -MemberType NoteProperty -Value $dscResource.Name
            }
            $script:allDscSchemaClasses += $dscSchemaClasses
        }
        catch
        {
            Write-Warning "Failed to import schema for DSC resource '$($dscResource.Name)' from module '$($dscResource.ModuleName)'. $_"
        }

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
