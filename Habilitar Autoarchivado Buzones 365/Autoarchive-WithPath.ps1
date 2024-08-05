$FILE = Get-Content "C:/Path del archivo/test.txt"
foreach ($LINE in $FILE)  
{
Enable-RemoteMailbox -Identity $LINE -Archive
}

