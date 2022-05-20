#this script grabs all your users with the specific 365 license (subsitute your SKU used), and shows you details about those users such as the last time they signed in either interactively or non-interactively (refresh token used for mobile outlook etc) to locate wasted accounts.
#look up the graph endpoint on docs.microsoft.com to find out what kind of app registration graph api permission you'll need.

$global:accesstoken = ""
$global:Header = ""
$authAppId = 'enter your app reg's appid here'
$authAppSecret = 'here is where you put your appid's secret'
$Scope = "https://graph.microsoft.com/.default"
$TenantName = "[wxyz].onmicrosoft.com"

function accesstoken ()
	{
	$Url = "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token"
	# Add System.Web for urlencode
	Add-Type -AssemblyName System.Web

	# Create body
	$Body = @{
		client_id = $authAppId
		client_secret = $authAppSecret
		scope = $Scope
		grant_type = 'client_credentials'
		}

	# Splat the parameters for Invoke-Restmethod for cleaner code
	$PostSplat = @{
	    ContentType = 'application/x-www-form-urlencoded'
	    Method = 'POST'
	    # Create string by joining bodylist with '&'
	    Body = $Body
	    Uri = $Url
		}

	# Request the token!
	$Request = Invoke-RestMethod @PostSplat
	$global:accesstoken = $request
	# Create header
	$global:Header = @{
		Authorization = "$($global:accesstoken.token_type) $($global:accesstoken.access_token)"
		}
	}

accesstoken

#retrieve user details, this filters only for users who have the SKU for the M365 E5 license, can substitute for a different SKU's GUID.
$Uri = "https://graph.microsoft.com/beta/users?" + '$' + "select=id,accountEnabled,createdDateTime,displayName,jobTitle,onPremisesDistinguishedName,onPremisesSamAccountName,userPrincipalName,mail,officeLocation,signInActivity,&" + '$' + "filter=assignedLicenses/any(u:u/skuId eq 06ebc4ee-1bb5-47dd-8120-11324bc54e06)"

$e5usersrequest = Invoke-RestMethod -Uri $Uri -Headers $global:Header -Method Get -ContentType "application/json"

$requestcount = 0
$e5users = @()
# fetch all users
$e5usersrequest = ""
$requestcount ++
$e5usersrequest = Invoke-RestMethod -Uri $Uri -Headers $global:Header -Method Get -ContentType "application/json"
$e5users += $e5usersrequest.value
$usercount = $e5usersrequest.value.count
$usercount
$e5usersrequest.'@Odata.NextLink'
while ($e5usersrequest.'@Odata.NextLink' -ne $null)
	{
	$Uri = $e5usersrequest.'@Odata.NextLink'
    $e5usersrequest = ""
    while ($e5usersrequest -eq "")
        {
        if ($requestcount % 50 -eq 0)
            {
            accesstoken
            }
        sleep 10
        "getting next request"
        $requestcount ++
        $e5usersrequest = Invoke-RestMethod -Uri $Uri -Headers $global:Header -Method Get -ContentType "application/json"
        }
	$e5users += $e5usersrequest.value
	$usercount += $e5usersrequest.value.count
	$usercount
    $e5usersrequest.'@Odata.NextLink'
	}

$e5users | Add-Member -MemberType NoteProperty "LastInteractiveLogin" -Value ""
$e5users | Add-Member -MemberType NoteProperty "LastNonInteractiveLogin" -Value ""

#cleanup signinactivity column
foreach ($row in $e5users)
	{
	$row.LastInteractiveLogin = $row.signInActivity -replace "@{", ""
	$row.LastInteractiveLogin = $row.LastInteractiveLogin -replace "}", ""
	$row.LastInteractiveLogin = ($row.LastInteractiveLogin -split ";")[0]
	$row.LastInteractiveLogin = $row.LastInteractiveLogin -replace "lastSignInDateTime=", ""

	$row.LastNonInteractiveLogin = $row.signInActivity -replace "@{", ""
	$row.LastNonInteractiveLogin = $row.LastNonInteractiveLogin -replace "}", ""
	$row.LastNonInteractiveLogin = ($row.LastNonInteractiveLogin -split ";")[2]
	$row.LastNonInteractiveLogin = $row.LastNonInteractiveLogin -replace "lastNonInteractiveSignInDateTime=", ""
	
	}

$e5users | export-csv -NoTypeInformation e5users.csv
