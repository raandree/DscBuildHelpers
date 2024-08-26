function Write-CimPropertyValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Text.StringBuilder]$StringBuilder,

        [Parameter(Mandatory = $true)]
        [object]$CimProperty,

        [Parameter(Mandatory = $true)]
        [string[]]$Path,

        [Parameter(Mandatory = $true)]
        [string]$ResourceName
    )

    $type = Get-DynamicTypeObject -Object $CimProperty
    if ($type.IsArray)
    {
        if ($type -is [pscustomobject])
        {
            $typeName = $type.TypeConstraint -replace '\[\]', ''
            $typeProperties = ($allDscSchemaClasses.Where({ $_.CimClassName -eq $typeName -and $_.ResourceName -eq $ResourceName })).CimClassProperties
        }
        else
        {
            $typeName = $type.Name -replace '\[\]', ''
            $typeProperties = $type.GetElementType().GetProperties().Where({ $_.CustomAttributes.AttributeType.Name -eq 'DscPropertyAttribute' })
        }
    }
    else
    {
        if ($type -is [pscustomobject])
        {
            $typeName = $type.TypeConstraint
            $typeProperties = ($allDscSchemaClasses.Where({ $_.CimClassName -eq $typeName -and $_.ResourceName -eq $ResourceName })).CimClassProperties
        }
        elseif ($type -is [type])
        {
            $typeName = $type.Name
            $typeProperties = $type.GetProperties().Where({ $_.CustomAttributes.AttributeType.Name -eq 'DscPropertyAttribute' })
        }
        elseif ($type.GetType().FullName -eq 'Microsoft.Management.Infrastructure.Internal.Data.CimClassPropertyOfClass')
        {
            $typeName = $type.ReferenceClassName
            $typeProperties = ($allDscSchemaClasses.Where({ $_.CimClassName -eq $typeName -and $_.ResourceName -eq $ResourceName })).CimClassProperties
        }
    }

    $null = $StringBuilder.AppendLine($typeName)
    $null = $StringBuilder.AppendLine('{')

    foreach ($property in $typeProperties)
    {
        $isCimProperty = if ($property.GetType().Name -eq 'CimClassPropertyOfClass')
        {
            if ($property.CimType -in 'Instance', 'InstanceArray')
            {
                $true
            }
            else
            {
                $property.CimType -notin $standardCimTypes.CimType
            }
        }
        else
        {
            $property.PropertyType.FullName -notin $standardCimTypes.DotNetType
        }

        $pathValue = Get-PropertiesData -Path ($Path + $property.Name)

        if ($null -ne $pathValue)
        {
            if ($isCimProperty)
            {
                Write-CimProperty -StringBuilder $StringBuilder -CimProperty $property -Path ($Path + $property.Name) -ResourceName $ResourceName
            }
            else
            {
                $paths = foreach ($p in $Path)
                {
                    "['$p']"
                }
                $null = $StringBuilder.AppendLine("$($property.Name) = `$Parameters$($paths -join '')['$($property.Name)']")
            }
        }
    }
    $null = $StringBuilder.AppendLine('}')
}
