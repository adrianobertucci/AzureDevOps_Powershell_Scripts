function New-AzureDevOpsPullRequest {

    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][System.String]$token,
          [Parameter(Mandatory=$true)][System.String]$vstsAccount,
          [Parameter(Mandatory=$true)][System.String]$projectName,
          [Parameter(Mandatory=$true)][System.String]$repositoryId,
          [Parameter(Mandatory=$true)][System.String]$BranchSourceRefName,
          [Parameter(Mandatory=$true)][System.String]$BranchTargetRefName,
          [Parameter(Mandatory=$true)][System.String]$Title,
          [Parameter(Mandatory=$true)][System.String]$Description,
          [Parameter(Mandatory=$true)][System.String]$reviewersId,
          [Parameter(Mandatory=$false)][System.Int32]$pullRequestId=$null)

        #Base64-encodes the Personal Access Token (PAT) appropriately
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "",$token)))

        #API do Azure DevOps para criarmos o pull request. Documentação: https://docs.microsoft.com/pt-br/rest/api/azure/devops/git/pull%20requests?view=azure-devops-rest-5.1
        $uri = "https://dev.azure.com/$($vstsAccount)/$($projectName)/_apis/git/repositories/$($repositoryId)/pullrequests?api-version=5.1"

        #Informações básicas para criarmos um pull request. Enviaremos as informações no corpo da chamada da API.
        $body = @"
                {
                    "sourceRefName": "$BranchSourceRefName",
                    "targetRefName": "$BranchTargetRefName",
                    "title": "$Title",
                    "description": "$Description",
                    "status": "completed",
                    "reviewers": [
                                    {
                                        "id": "$reviewersId"
                                    }
                                ]
                }
"@

        #Chamada da API, criando o pull request
        $result = Invoke-RestMethod -Uri $uri -Method 'POST' -ContentType "application/json" -Body $body -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
        
        return $result.pullRequestId;
}

function Get-AzureDevOpsPullRequestReviewer {

    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][System.String]$token,
          [Parameter(Mandatory=$true)][System.String]$vstsAccount,
          [Parameter(Mandatory=$true)][System.String]$projectName,
          [Parameter(Mandatory=$true)][System.String]$repositoryId,
          [Parameter(Mandatory=$true)][System.String]$pullRequestId,
          [Parameter(Mandatory=$false)][System.String]$reviewerId=$null)

    $uri = "https://dev.azure.com/$vstsAccount/$projectName/_apis/git/repositories/$repositoryId/pullrequests/$pullrequestId/reviewers";

    if ($reviewerId) { $uri = "$uri/$reviewerId" }

    $uri = "$uri`?api-version=5.0";

    #Base64-encodes the Personal Access Token (PAT) appropriately
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "",$token)))


    #Busca revisores
    $result = Invoke-RestMethod -Uri $uri -Method 'GET' -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
    
    return $result.value[0]
}

function Approve-AzureDevOpsPullRequest {

    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][System.String]$token,
          [Parameter(Mandatory=$true)][System.String]$vstsAccount,
          [Parameter(Mandatory=$true)][System.String]$projectName,
          [Parameter(Mandatory=$true)][System.String]$repositoryId,
          [Parameter(Mandatory=$true)][System.String]$pullRequestId,
          [Parameter(Mandatory=$true)]$reviewer)

    $uri = "https://dev.azure.com/$vstsAccount/$projectName/_apis/git/repositories/$repositoryId/pullrequests/$pullRequestId/reviewers/$($reviewer.id)`?api-version=5.0"

    #Base64-encodes the Personal Access Token (PAT) appropriately
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "",$token)))

    $body = ConvertTo-Json($reviewer);

    $result = Invoke-RestMethod -Uri $uri -Method 'PUT' -ContentType "application/json" -Body $body -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
    
    return $result;
}

function Complete-AzureDevOpsPullRequest {

    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][System.String]$token,
          [Parameter(Mandatory=$true)][System.String]$vstsAccount,
          [Parameter(Mandatory=$true)][System.String]$projectName,
          [Parameter(Mandatory=$true)][System.String]$repositoryId,
          [Parameter(Mandatory=$true)][System.String]$autoCompleteSetBy,
          [Parameter(Mandatory=$true)][System.String]$deleteSourceBranch,
          [Parameter(Mandatory=$true)][System.String]$mergeCommitMessage,
          [Parameter(Mandatory=$true)][System.String]$squashMerge,
          [Parameter(Mandatory=$true)][System.Int32]$pullRequestId)

        #Base64-encodes the Personal Access Token (PAT) appropriately
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "",$token)))

        $uri = "https://dev.azure.com/$($vstsAccount)/$($projectName)/_apis/git/repositories/$($repositoryId)/pullrequests/$($pullRequestId)?api-version=5.0"
        
        $body = @"
        {
            "autoCompleteSetBy": {
              "id": "$autoCompleteSetBy"
            },
            "completionOptions": {
              "deleteSourceBranch": "$deleteSourceBranch",
              "mergeCommitMessage": "$mergeCommitMessage",
              "squashMerge": "$squashMerge"
            }
          }
"@

        $result = Invoke-RestMethod -Uri $uri -Method PATCH -ContentType "application/json" -Body $body -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

        return $result
}


$vstsAccount = "konia";
$projectName = "Demo_Git";
$repositoryId = "7f7a7a24-4afc-4632-83XXXXX-ddsadas";
$token = "asdasfjnfas82387234823478293fjsdfasdfsafs";
$reviewerId = "558f88c1-e5ba-asdasdasdasdas-8481-asddsfksdfgj9990ds";


$pullRequestId = New-AzureDevOpsPullRequest -token $token -vstsAccount $vstsAccount -projectName $projectName -repositoryId $repositoryId -BranchSourceRefName "refs/heads/master" -BranchTargetRefName "refs/heads/stage" -Title "Titulo do Pull Request" -Description "Descricao do pull request" -reviewersId $reviewerId

$reviewer = Get-AzureDevopsPullRequestReviewer -token $token -vstsAccount $vstsAccount -projectName $projectName -repositoryId $repositoryId -pullRequestId $reviewerId

$reviewer.vote = 10; #aprovado

Approve-AzureDevOpsPullRequest -token $token -vstsAccount $vstsAccount -projectName $projectName -repositoryId $repositoryId -pullRequestId $pullRequestId -reviewer $reviewer;

Complete-AzureDevOpsPullRequest -token $token -vstsAccount $vstsAccount -projectName $projectName -repositoryId $repositoryId -pullRequestId $pullRequestId -autoCompleteSetBy $reviewerId -deleteSourceBranch "false" -mergeCommitMessage "Commit do pull request" -squashMerge "false"


