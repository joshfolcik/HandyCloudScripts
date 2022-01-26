#if you need to release thousands of emails from quarantine with a specific sender/subject and date range, this can be much faster than using the UI which only lets you select a small number at a time.
$done = 0
while ($done -eq 0)
    {
    $messages = Get-QuarantineMessage -SenderAddress "<senderemailaddy@domain.com>" -Subject "<putsubject_here>" -StartReceivedDate <update for start date such as 1/4/2022> -EndReceivedDate <similarly update end date such as 1/5/2022> -PageSize 250 -ReleaseStatus NotReleased
    $qids = ""
    if ($messages -ne $null)
        {
        foreach ($message in $messages) 
            {
            $qids = $qids + '"' + $message.Identity + '"' + ","
            }
            $qids = $qids.Substring(0,$qids.length-1)
            $cmd = "Release-QuarantineMessage -ReleaseToAll -Identities " + $qids
            "releasing " + ($messages.count).tostring() + " emails"
            invoke-expression $cmd
            "command executed, sleeping 2.5 minutes"
            #sleeping to avoid being throttled
            sleep 150
        }
    else
        {
        $done = 1
        }
    }
