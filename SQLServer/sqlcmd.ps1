#Importing SQL Server Management Pack
Import-Module SQLPS

#Variable with the addresses of the T-SQL scripts
$pathSQLFiles = $env:PathFiles

#Leitura dos arquivos disponiveis no diretório informado para execução
$tsqlFiles = Get-ChildItem -Force $pathSQLFiles -Recurse

#Read the available files in the directory you have entered for execution
foreach($tsqlfile in $tsqlFiles)
{
    Invoke-Sqlcmd -ServerInstance $env:SQLServerInstance -Database $env:DataBaseName -InputFile $tsqlfile.FullName
}

