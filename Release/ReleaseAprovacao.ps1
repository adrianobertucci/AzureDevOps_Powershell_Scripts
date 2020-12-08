Param(
   [string]$Collecitonurl = "https://vsrm.dev.azure.com/<<NAMECOLLECTION>>",
   [string]$projectName = "<<TeamProjectName>>",
   [string]$keepForever = "true",
   [string]$user = "",
   [string]$token = "<<PAT_TOKEM>>",
   [string]$releaseid = "<<RELEASEID>>"
)

# Base64-encodes the Personal Access Token (PAT) appropriately
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$token)))

#Get releaseresponse
$Releaseurl= "$Collecitonurl/$projectName/_apis/Release/releases/$releaseid/?api-version=5.1" 
$releaseresponse = Invoke-RestMethod -Method Get -UseDefaultCredentials -ContentType application/json -Uri $Releaseurl

#Get all of the environment IDs from the release response:
$environmentIDs = $releaseresponse.environments.ForEach("id")

#Get the specific environment ID by grabbing the element in the environment IDs array:
$firstEnvironment = $environmentIDs[0]
#$secondEnvironment = $environmentIDs[1]
#$thirdEnvironment = $environmentIDs[2] # ...

#Create the JSON body for the deployment:
$deploymentbody = @" 
{
    "status": "inprogress"
    "scheduledDeploymentTime": null,
    "comment": "comentario",
    "variables": {}
} 
"@

#Invoke the REST method to redeploy the release:
$DeployUrl = "$Collecitonurl/$projectName/_apis/release/releases/$releaseid/environments/"+$firstEnvironment+"?api-version=3.2-preview" # Change the envrionment ID accordingly based on your requirement. 
$DeployRelease = Invoke-RestMethod -Method Patch -ContentType application/json -Uri $DeployUrl -Headers @{Authorization=("Basic {0}" -f $base64authinfo)} -Body $deploymentbody


write-host "environmentIDs:" $environmentIDs