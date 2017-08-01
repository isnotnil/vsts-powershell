[CmdletBinding()]
param (
    [string]
    $InstanceName,

    [string]
    $ProjectName,

    [string]
    $PersonalAccessToken
)

class Commit {
    [string]$AuthorName
    [string]$AuthorEmail
    [string]$RepositoryName
    [string]$CommitId
    [DateTime]$Date
    [int]$Edits
    [int]$Adds
    [int]$Deletes
}

$allRepositoriesApiUrl = "https://$InstanceName.visualstudio.com/DefaultCollection/$ProjectName/_apis/git/repositories/?api-version=1.0"

$vstsAuthType = "Basic"
$vstsBasicAuthBase64String = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $vstsAuthType, $PersonalAccessToken)))
$vstsBasicAuthHeader = "$vstsAuthType $vstsBasicAuthBase64String"
$requestHeaders = @{Authorization = "$vstsBasicAuthHeader"}

$response = Invoke-RestMethod `
    -Method Get `
    -Uri $allRepositoriesApiUrl `
    -ContentType "application/json" `
    -Headers $requestHeaders `
    -Verbose:$VerbosePreference

Write-Verbose "Found $($response.count) Repositories"

$response.value | ForEach-Object {
    $repositoryName = $_.name
    $repositoryApiUrl = $_.url

    Write-Verbose "Found Repo $($repositoryName)"

    $skip = 0
    $take = 100
    $lastGetCount = 0

    do {
        $commitsForRepoApiUrl = "$repositoryApiUrl/commits?api-version=1.0&skip=$skip&take=$take"

        $response = Invoke-RestMethod `
            -Method Get `
            -Uri $commitsForRepoApiUrl `
            -ContentType "application/json" `
            -Headers $requestHeaders `
            -Verbose:$VerbosePreference

        $lastGetCount = $response.count

        $response.value | ForEach-Object {
            $commit = [Commit]::new()
            $commit.AuthorName = $_.author.name
            $commit.AuthorEmail = $_.authoer.email
            $commit.RepositoryName = $repositoryName
            $commit.CommitId = $_.commitId
            $commit.Date = $_.author.Date
            $commit.Adds = $_.changeCounts.Add
            $commit.Edits = $_.changeCounts.Edit
            $commit.Deletes = $_.changeCounts.Delete

            Write-Output $commit
        }

        $skip = $skip + $take
    }
    while ($lastGetCount -gt 0)
}