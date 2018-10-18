Clear-Host
# ------------------------------------------------------------------------------------------------
function getOuParams($mask)
{
    $result = new-object PSObject | select-object ou_Ws, ou_Srv
    
    $filtr = '(name='+$mask+'*)'

    $ouList = Get-ADOrganizationalUnit -LDAPFilter $filtr
    foreach ($item in $ouList)
    {
        $ou_DistinguishedName = $item.DistinguishedName.ToLower()
    
        if ($ou_DistinguishedName.IndexOf('ou=ws') -gt -1)
        {
            $result.ou_Ws = $item
        }

        if ($ou_DistinguishedName.IndexOf('ou=srv') -gt -1)
        {
            $result.ou_Srv = $item
        }      
    }

    return $result
}

function getPcParams($pc_name)
{
    $result = new-object PSObject | select-object pc_zone, pc_type
    
    $result.pc_zone = ''
    $result.pc_type = ''
    
    $pos = $pc_name.IndexOf('-')
    if ($pos -gt -1)
    {
        $result.pc_zone = $pc_name.Substring(0, $pos)
        if ($pc_name.Length -gt $pos +3)
        {
            $result.pc_type = $pc_name.Substring($pos +1, 3).ToLower()

            $pos = $result.pc_type.IndexOf('ws')
            if ($pos -gt -1)
            {
                $result.pc_type = 'ws'
            }
            $pos = $result.pc_type.IndexOf('srv')
            if ($pos -gt -1)
            {
                $result.pc_type = 'srv'
            }
        }
    }

    return $result
}

function movePcToOu($pc, $ou)
{
    if ($pc -ne $null -and $ou -ne $null)
    {
        $pc | Move-ADObject -TargetPath $ou.DistinguishedName
    }
}

# ------------------------------------------------------------------------------------------------

$pc_list = Get-ADComputer -Filter * -SearchBase 'OU=NewUnconfigured,DC=severotorg,DC=local'

foreach ($item in $pc_list)
{
    $pcParams = getPcParams($item.Name)
    if ($pcParams.pc_zone.Length -gt 0 -and $pcParams.pc_type.Length -gt 0)
    {
        $OuParams = getOuParams($pcParams.pc_zone)
        
        if ($pcParams.pc_type -eq 'ws')
        {
            movePcToOu $item $OuParams.ou_Ws
        }

        if ($pcParams.pc_type -eq 'srv')
        {
            movePcToOu $item $OuParams.ou_Srv
        }
    }
}