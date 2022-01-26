#script to enumerate all ediscoveries that have holds, with details on those holds
$output = @()
$cases = get-compliancecase
$total = $cases.count
$completed = 1
foreach ($case in $cases)
    {
    $holds = get-caseholdpolicy -case $case.name -distributiondetail
    foreach ($hold in $holds)
        {
        $outputobj = new-object pscustomobject -Property @{
            'casename' = $case.Name
            'casedescription' = $case.description
            'casestatus' = $case.status
            'closingstatus' = $case.closingstatus
            'casecreatedtime' = $case.createddatetime
            'caselastmodifiedtime' = $case.lastmodifieddatetime
            'caseclosedtime' = $case.closeddatetime
            'caselastmodifiedby' = $case.lastmodifiedby
            'holdname' = $hold.name
            'exchangelocation' = $hold.exchangelocation
            'sharepointlocation' = $hold.sharepointlocation
            'holdcomment' = $hold.comment
            'holdenabled' = $hold.enabled
            }
        $output += $outputobj
        }
    ($completed++).tostring() + "/" + $total.tostring()
    }

$output | Select-Object -Property casename, casedescription, casestatus, closingstatus, casecreatedtime, caselastmodifiedtime, caseclosedtime, caselastmodifiedby, holdname, exchangelocation, sharepointlocation, holdcomment, holdenabled | export-csv -notypeinformation -path ediscovery.csv
