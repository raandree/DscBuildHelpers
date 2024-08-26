function Get-DynamicTypeObject
{
    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)]
        [object]$Object
    )

    if ($Object.ElementType)
    {
        return $Object.Type.GetElementType()
    }
    elseif ($Object.PropertyType)
    {
        return $Object.PropertyType
    }
    elseif ($Object.Type)
    {
        return $Object.Type
    }
    else
    {
        return $Object
    }
}
