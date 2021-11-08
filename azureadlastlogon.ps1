#you'll need to get an access token first, that is done with a function I re-use all the time against the identity of an app registration with the appropriate API rights for the particular script

#what this script does is retrieve all of the user objects (the graph API returns 100 at a time), if it fails it keeps trying because Microsoft sometimes throttles or fails to return a request
#it sleeps 10 seconds inbetween requests, to avoid additional throttling
#this beta query that includes signInActivity does not support filtering. If you try and filter the total user scope, it will fail to give a NextLink that functions.
#because depending on the number of users (10's of thousands or more) it could take longer than 1 hour, every 50 queries it generates a fresh access token as they are only valid for 1 hour.


#get access token
accesstoken

#define the uri query
$Uri = "https://graph.microsoft.com/beta/users?" + '$' + "select=displayName,userPrincipalName,signInActivity"
$requestcount = 0
$allusers = @()
# fetch all users
$allusersrequest = ""
$requestcount ++
$allusersrequest = Invoke-RestMethod -Uri $Uri -Headers $global:Header -Method Get -ContentType "application/json"
$allusers += $allusersrequest.value
$usercount = $allusersrequest.value.count
$usercount
$allusersrequest.'@Odata.NextLink'
while ($allusersrequest.'@Odata.NextLink' -ne $null)
	{
	$Uri = $allusersrequest.'@Odata.NextLink'
    $allusersrequest = ""
    while ($allusersrequest -eq "")
        {
        if ($requestcount % 50 -eq 0)
            {
            accesstoken
            }
        sleep 10
        "getting next request"
        $requestcount ++
        $allusersrequest = Invoke-RestMethod -Uri $Uri -Headers $global:Header -Method Get -ContentType "application/json"
        }
	$allusers += $allusersrequest.value
	$usercount += $allusersrequest.value.count
	$usercount
    $allusersrequest.'@Odata.NextLink'
	}


$signinactivity = @()
foreach ($alluseruser in $allusers)
	{
	if ($alluseruser.signInActivity -ne $null)
		{
		$signinactivity += $alluseruser
		}
	}
$signinactivity | Export-Csv -NoTypeInformation userslastlogon.csv


$csv = $signinactivity


#cleanup signinactivity column
foreach ($row in $csv)
	{
	$row.signInActivity = $row.signInActivity -replace "@{", ""
	$row.signInActivity = $row.signInActivity -replace "}", ""
	$row.signInActivity = ($row.signInActivity -split ";")[0]
	$row.signInActivity = $row.signInActivity -replace "lastSignInDateTime=", ""
	}

$csv | export-csv -NoTypeInformation userslastlogonparsed.csv
