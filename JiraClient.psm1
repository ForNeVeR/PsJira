function Get-JiraIssueStatus {
    param(
		[Parameter(Mandatory = $true)]
		$Url,

		[Parameter(Mandatory = $true)]
		$Login,

		[Parameter(Mandatory = $true)]
		$Password,

		[Parameter(ValueFromPipeLine = $true)]
		$IssueKeys
    )

    begin { 
    	$wsdl = "$Url/rpc/soap/jirasoapservice-v2?wsdl"
	    $proxy = New-WebServiceProxy $wsdl
	    Write-Host "Fetching WSDL from $wsdl"

	    $token = $proxy.login($Login, $Password)
	    if ($token) {
	    	Write-Host "Succesfully logged in as $Login"
	    }

	    Write-Host 'Fetching statuses...'
    	$statuses = $proxy.getStatuses($token)
    }

    process {
    	foreach ($issueKey in $IssueKeys) {
    		Write-Host "Fetching issue $IssueKey"
	    	$issue = $proxy.getIssue($token, $IssueKey)
	    	if (-not $issue) {
	    		Write-Error "Issue $issueKey not found"
	    		continue
	    	}

	    	$statusId = $issue.status
	    	$status = $statuses | ? { $_.id -eq $statusId }

	    	$info = [pscustomobject] @{ Key = $issueKey; Status = $status.name }
	    	$info
    	}
    }

    end {
    	$proxy.logout($token)
   		Write-Host 'Successfully logged out'
    }
}

Export-ModuleMember Get-JiraIssueStatus