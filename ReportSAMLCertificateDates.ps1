$global:accesstoken = ""
$global:Header = ""
$authAppId = 'put your app reg's app id guid here'
$authAppSecret = 'put your app reg's secret here'
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

#retrieve enterprise apps
$Uri = "https://graph.microsoft.com/v1.0/servicePrincipals"

$requestcount = 0
$allapps = @()
$allappsrequest = ""
$requestcount ++
$allappsrequest = Invoke-RestMethod -Uri $Uri -Headers $global:Header -Method Get -ContentType "application/json"
$allapps += $allappsrequest.value
$appcount = $allappsrequest.value.count
$appcount
$allappsrequest.'@Odata.NextLink'
while ($allappsrequest.'@Odata.NextLink' -ne $null)
	{
	$Uri = $allappsrequest.'@Odata.NextLink'
    $allappsrequest = ""
    while ($allappsrequest -eq "")
        {
        if ($requestcount % 50 -eq 0)
            {
            accesstoken
            }
        sleep 10
        "getting next request"
        $requestcount ++
        $allappsrequest = Invoke-RestMethod -Uri $Uri -Headers $global:Header -Method Get -ContentType "application/json"
        }
	$allapps += $allappsrequest.value
	$appcount += $allappsrequest.value.count
	$appcount
    $allappsrequest.'@Odata.NextLink'
	}

$report = @()

foreach ($app in $allapps)
    {
    if ($app.keyCredentials[0].displayName -like "*SSO*")
        {
        $appname = ""
        $appid = ""
        $appcertexpire = ""
        $appname = $app.displayName
        $appid = $app.id
        $appcertexpire = $app.keyCredentials[0].endDateTime

        			$resultsobj = new-object pscustomobject -Property @{
					'appname' = $appname
					'appid' = $appid
					'appcertexpire' = $appcertexpire
					}
        $report += $resultsobj
        }
    }

$report | export-csv -notypeinformation enterpriseappssaml.csv
