function Get-PropertiesData
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Path
    )

    $paths = foreach ($p in $Path)
    {
        "['$p']"
    }

    $pathValue = try
    {
        Invoke-Expression "`$Properties$($paths -join '')"
    }
    catch
    {
        $null
    }

    return $pathValue
}
