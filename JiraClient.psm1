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
			Write-Host -NoNewline "Fetching issue status $IssueKey... "
			$issue = $proxy.getIssue($token, $IssueKey)
			if (-not $issue) {
				Write-Host "[not found]"
				continue
			}

			$statusId = $issue.status
			$status = $statuses | ? { $_.id -eq $statusId }
			$statusName = $status.name

			Write-Host "[$statusName]"

			$info = [pscustomobject] @{ Key = $issueKey; Status = $statusName }
			$info
		}
	}

	end {
		$proxy.logout($token)
   		Write-Host 'Successfully logged out'
	}
}

function Get-JiraIssue {
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
	}

	process {
		foreach ($issueKey in $IssueKeys) {
			Write-Host "Fetching issue $IssueKey"
			$issue = $proxy.getIssue($token, $IssueKey)
			if (-not $issue) {
				Write-Error "Issue $issueKey not found"
				continue
			}

			$issue
		}
	}

	end {
		$proxy.logout($token)
		Write-Host 'Successfully logged out'
	}
}

function Get-CurrentUserJiraIssue {
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

	$wsdl = "$Url/rpc/soap/jirasoapservice-v2?wsdl"
	$proxy = New-WebServiceProxy $wsdl
	try {
		Write-Host "Fetching WSDL from $wsdl"

		$token = $proxy.login($Login, $Password)
		if ($token) {
			Write-Host "Succesfully logged in as $Login"
		} else {
			throw "Cannot login to JIRA as $Login"
		}

		$proxy.getIssuesFromJqlSearch(
			$token,
			'assignee = currentUser() AND resolution = unresolved ORDER BY priority DESC, created ASC',
			[int]::MaxValue)
	} finally {
		$proxy.logout($token)
		Write-Host 'Successfully logged out'
	}
}

Export-ModuleMember Get-JiraIssueStatus
Export-ModuleMember Get-JiraIssue
Export-ModuleMember Get-CurrentUserJiraIssue
