function Get-CimType
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$DscResourceName,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName
    )

    $cimType = $allDscResourcePropertiesTable."$ResourceName-$PropertyName"

    if ($null -eq $cimType)
    {
        Write-Verbose "The CIM Type for DSC resource '$DscResourceName' with the name '$PropertyName'. It is not a CIM type."
        return
    }

    return $cimType
}
