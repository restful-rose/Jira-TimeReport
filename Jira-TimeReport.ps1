param (
    [Parameter(Mandatory=$true)]
    [ValidatePattern('\d{4}-\d{2}-\d{2}')]
    [string]$StartDate,

    [Parameter(Mandatory=$false)]
    [ValidatePattern('\d{4}-\d{2}-\d{2}')]
    [string]$EndDate
)

$inputFormat = "yyyy-MM-dd"
$startDateTime = [DateTime]::ParseExact($StartDate, $inputFormat, $null)
$startDateTime = $startDateTime.Date
$startDateTimeOffset = [DateTimeOffset]::new($startDateTime)

if (-not $EndDate -or [string]::IsNullOrWhiteSpace($EndDate)) {
    $EndDate = (Get-Date -Format 'yyyy-MM-dd')
}
$endDateTime = [DateTime]::ParseExact($EndDate, $inputFormat, $null)
$endDateTime = $endDateTime.Date.AddHours(23).AddMinutes(59)
$endDateTimeOffset = [DateTimeOffset]::new($endDateTime)

$apiKey = op read "op://Employee/Jira Time-tracking API-token/credential"
$username = op read "op://Employee/Jira Time-tracking API-token/username"

$text = "${username}:$apiKey"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
$encodedText = [Convert]::ToBase64String($bytes)

$accountUri = "https://nveprojects.atlassian.net/rest/api/3/myself"

$uri = "https://nveprojects.atlassian.net/rest/api/3/search/jql?jql=worklogAuthor=currentUser()%20AND%20sprint%20in%20openSprints()&fields=id,key"

$headers = @{
    Authorization = "Basic $encodedText"
    "Content-Type" = "application/json"
}

$res = Invoke-WebRequest -Uri $accountUri -Method Get -Headers $headers
$content = $res.Content | ConvertFrom-Json
$accountId = $content.accountId
$accountName = $content.displayName

$outputFormat = "yyyy-MM-dd HH:mm:ss"
Write-Host "Getting issues in current sprint for account with`nName:`t$accountName`nId:`t$accountId"
Write-Host "Between $($startDateTimeOffset.ToString($outputFormat)) and $($endDateTimeOffset.ToString($outputFormat))`n"

$res = Invoke-WebRequest -Uri $uri -Method Get -Headers $headers

$content = $res.Content | ConvertFrom-Json

$issues = $content.issues
Write-Host "Found $($issues.Count) issues in current sprint"

#$issues[0] | format-list

$sumSeconds = 0
foreach ($issue in $issues) {
    $id = $issue.id
    $key = $issue.key
    $issueUri = "https://nveprojects.atlassian.net/rest/api/3/issue/${id}/worklog"
    $res = Invoke-WebRequest -Uri $issueUri -Method Get -Headers $headers

    $content = $res.Content | ConvertFrom-Json

    # Go through worklog and sum seconds
    foreach ($logEntry in $content.worklogs) {
        $author = $logEntry.author
        $updateAuthor = $logEntry.updateAuthor

        #$logEntry | format-list
        $timeString = $logEntry.started
        $preProcessedTimestamp = $timeString -replace "([+-]\d{2})(\d{2})$", '$1:$2'
        $startedTime = [DateTimeOffset]::Parse($preProcessedTimestamp)
        #$startedTime.GetType().Name
        #exit

        if ($author.accountId -eq $accountId -and $author.accountId -eq $updateAuthor.accountId -and $startDateTimeOffset -le $startedTime -and $startedTime.AddSeconds($logEntry.timeSpendSeconds) -le $endDateTimeOffset) {
            Write-Host "Issue: $key, Work-id: $($logEntry.id), Date: $($startedTime.ToString($outputFormat)), Time:`t$($logEntry.timeSpentSeconds)"
            $sumSeconds += $logEntry.timeSpentSeconds
        }
    }
}

$timespan = [TimeSpan]::FromSeconds($sumSeconds)
Write-Host "`nTotal number of seconds: $sumSeconds ($($timespan.ToString()))`n"

