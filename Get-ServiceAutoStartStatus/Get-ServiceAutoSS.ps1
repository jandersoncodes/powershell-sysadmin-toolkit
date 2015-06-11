<#
        .DESCRIPTION
        Gets the 'Automatically Start' Service Status of a Given Computer

        .PARAMETER computername
        Specifies the computername. Accepts String Objects. Defaults to env:COMPUTERNAME

        .EXAMPLE
        Get-ServiceAutoSS -Computername COMPUTER1,COMPUTER2,COMPUTER3

		:\>Get-ServiceAutoSS -Computername COMPUTER1,COMPUTER2,COMPUTER3 | format-table

		Computername            Name                    DisplayName            StartMode              State                  Status
		------------		----                    -----------            ---------              -----                  ------
		COMPUTER1		gpsvc                   Group Policy Client    Auto                   Stopped                OK
		COMPUTER2		gupdate                 Google Update Servi... Auto                   Stopped                OK
		COMPUTER2		Net Driver HPZ12        Net Driver HPZ12       Auto                   Stopped                OK
		COMPUTER3		gpsvc			Pml Driver HPZ12       Auto                   Stopped                OK

	.EXAMPLE
	Get-ADComputer -Filter {OperatingSystem -like "Window*Server*"} | Select Name | %{Get-ServiceAutoSS -Computername $_.Name -VERBOSE} | ft


        .NOTES
        AUTHOR: James Anderson
	LAST UPDATED: 6/9/2015
#>
Function Get-ServiceAutoSS {
[cmdletbinding()]
Param(
[Parameter(Position=0,ValueFromPipeline=$True)]
[alias("cn","pscomputername")]
[string[]]$Computername = $env:COMPUTERNAME
)
 
Begin {
    Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"  
 
    $wmiParam=@{
     class = 'Win32_Service'
     filter= "StartMode='Auto' AND State='Stopped'"
     ComputerName= $Null
     ErrorAction= "SilentlyContinue"
    }
	# List of Services to Ignore. 
	$Ignore=@( 
		'Microsoft .NET Framework NGEN v4.0.30319_X64', 
		'Microsoft .NET Framework NGEN v4.0.30319_X86', 
		'Multimedia Class Scheduler', 
		'Performance Logs and Alerts', 
		'SBSD Security Center Service', 
		'Shell Hardware Detection', 
		'Software Protection', 
		'TPM Base Services'; 
	) 

} #begin
 
Process {
 
foreach ($computer in $computername) {
     Write-Verbose "Querying $computer.toUpper())"
     $wmiParam.Computername=$Computer
    Try {
     Get-WMIObject @wmiParam | Select @{name="Computername";Expression={$_.SystemName}},
     Name,DisplayName,StartMode,State,Status | Where-Object {$Ignore -notcontains $_.Displayname}
    }
    Catch {
      Write-Warning "Failed to retrieve WMI information from $computername"
      Write-Warning $_.Exception.Message
    }
 } #foreach
} #process
 
End {
    Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
} #end
 
} #end function
