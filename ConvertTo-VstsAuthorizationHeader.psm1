function ConvertTo-VstsAuthorizationHeader {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $PersonalAccessToken
    )

    $vstsAuthType = "Basic"
    $vstsBasicAuthBase64String = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($vstsAuthType):$PersonalAccessToken"))
    $vstsBasicAuthHeader = "$vstsAuthType $vstsBasicAuthBase64String"
    $requestHeaders = @{Authorization = "$vstsBasicAuthHeader"}

    Write-Output $requestHeaders
}