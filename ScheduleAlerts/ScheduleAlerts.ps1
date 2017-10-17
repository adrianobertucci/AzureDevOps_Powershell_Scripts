<#
Sample excute: ScheduleAlerts.ps1 -VSTSToken "Personal Token VSTS" -Office365PS "password"

We can create a scheduled release in VSTS to execute the script, thus leaving the same with execution recurrence
#>

Param(
    #Secrets Variables
    [string]$VSTSToken,
    [string]$Office365PS
 )

#Variables VSTS
$vstsAccount = $env:VSTSAccount
$projectName = $env:projectName
$user = $env:VSTSUser
$token = $VSTSToken
$queryid = $env:QueryID
$SMTPServer = $env:SMTPOffice365
$EmailFrom = $env:EmailFrom
$EmailTo = $env:EmailTo
$Sub = $env:Subject

# Base64-encodes the Personal Access Token (PAT) appropriately
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$token)))

$uri = "https://$($vstsAccount).visualstudio.com/$($projectName)/_apis/wit/wiql/$($queryid)?api-version=1.0"

# Invoke the REST call and capture the results in VSTS Query (notice this uses the PATCH method)
$query = Invoke-RestMethod -Uri $uri -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method Get

$emailValues = @()

foreach($i in $query.WorkItems) 
{
    $WI = $i.Url+"?api-version=1.0"
    # Invoke the REST call and capture the detail from work item
    $query2 = Invoke-RestMethod -Uri $WI -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method Get

    $values = New-Object System.Object
    $values | Add-Member -type NoteProperty -Name id -Value $i.id
    $values | Add-Member -type NoteProperty -Name Title -Value $query2.fields.'System.Title'
    $values | Add-Member -type NoteProperty -Name sstate -Value $query2.fields.'System.State'
    $values | Add-Member -type NoteProperty -Name uurl -Value $query2._links.'html'.href

    $emailValues += $values
}     

#HTML - Body Mail Message
$Bmessage = "VSTS Query Work Items:
                <br>
                <br>
                <br>
                <table>
                <tr> 
                    <td style=""padding-right:40px;"" bgcolor=#106EBE><font color=white><b>ID</b></td></font>
                    <td style=""padding-right:300px;""bgcolor=#106EBE><font color=white><b>Title</b></td></font>
                    <td style=""padding-right:40px;"" bgcolor=#106EBE><font color=white><b>State</b></td></font>
                </tr>"

foreach($i in $emailValues)
{

    $wi =("<tr> 
    <td bgcolor=#F8F8F8><a href=""{3}"" target=""_blank"" tabindex=""-1""><font color=#1a75ff>{0}</font></a></td>
    <td bgcolor=#F8F8F8>{1}</td>
    <td bgcolor=#F8F8F8>{2}</td>
        </tr>" -f $i.id,$i.Title,$i.sstate,$i.uurl)

    $Bmessage += $wi;
}


$Bmessage +="</table>"

#Send Mail Message  
$username = $env:Office365UserName
$password = $Office365PS
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr

Send-MailMessage -From $EmailFrom -To $EmailTo -Subject $Sub -Body $Bmessage -BodyAsHtml -SmtpServer $SMTPServer -Credential $cred -UseSsl -Port 587

