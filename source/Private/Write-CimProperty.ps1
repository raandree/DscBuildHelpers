function Write-CimProperty
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

    $null = $StringBuilder.Append("$($CimProperty.Name) = ")
    if ($CimProperty.IsArray -or $CimProperty.PropertyType.IsArray -or $CimProperty.CimType -eq 'InstanceArray')
    {
        $null = $StringBuilder.Append("@(`n")

        $pathValue = Get-PropertiesData -Path $Path

        $i = 0
        foreach ($element in $pathValue)
        {
            $p = $Path + $i
            Write-CimPropertyValue -StringBuilder $StringBuilder -CimProperty $CimProperty -Path $p -ResourceName $ResourceName
            $i++
        }

        $null = $StringBuilder.Append(")`n")
    }
    else
    {
        Write-CimPropertyValue -StringBuilder $StringBuilder -CimProperty $CimProperty -Path $Path -ResourceName $ResourceName
    }
}
