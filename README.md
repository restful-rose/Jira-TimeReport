# Jira-TimeReport

Sums all the seconds the user spent working on issues and reports that.

## Installation

To use this script, you need to create a Jira API-key.
- Go to [Atlassian account API tokens](https://id.atlassian.com/manage-profile/security/api-tokens).
- Click "Create API token with scopes"
- Choose an arbitrary name and set the expiration date
- Select "Jira" as the API token app
- Search and choose the scopes `read:jira-user` and `read:jira-work`.
- Click "Create token"
- Copy the token to your 1Password vault.

For maximum security, we will be using
a scoped Jira API-key, which means you also have to get the *cloudId*/*tenantId* for your instance.
- In your browser, go to `https://<tenant name>.atlassian.net/_edge/tenant_info`.
- This will give your your *cloudId* for your tenant (also known as *tenantId*).
- Copy the cloud Id to a separate field in your 1Password vault entry.

Install the gathered information into your script
- Go to your 1Password vault entry, click the arrow to the right of your previously stored API-key and choose "Copy Secret Reference"
- Paste the secret reference into the script where it says `$apiKey = op read "<secret reference>"`. Notice that it might be a previously used secret reference here. This can and should be replaced.
- Do the same for your cloud Id for the place in the script where it says `$cloudId = op read "<secret reference>"`
- Finally insert your email in the "username"-field, copy the secret reference and paste it into the script where it says `$username = op read "<secret reference>"`.

## Use

```
Jira-TimeReport.ps1 -StartDate "<yyyy-mm-dd>" -EndDate "<yyyy-mm-dd>"
```

## Endpoints

This script collects information from Jira using the Atlassian-endpoints below.

### Get current user

`/rest/api/3/myself`

Scopes:
- `read:jira-user`

### Search for issues using JQL enhanced search (GET)

`rest/api/3/search/jql?jql=worklogAuthor=currentUser()%20AND%20sprint%20in%20openSprints()&fields=id,key`

Scopes:
- `read:jira-work`

### Get issue worklogs

`/rest/api/3/issue/<issue id>/worklog`

Scopes:
- `read:jira-work`
