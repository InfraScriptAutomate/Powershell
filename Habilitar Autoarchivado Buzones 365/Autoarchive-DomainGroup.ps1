$Users=Get-ADGroupMember -Identity "Grupo de Usuario para habilitar autoarchivado" | select -expand samaccountname
foreach ($LINE in $Users)  
{
Enable-RemoteMailbox -Identity $LINE -Archive
}
