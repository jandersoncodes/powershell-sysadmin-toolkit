<#
        .DESCRIPTION
        Uses Get-ADComputer and WMI to query a list of computers for IP, Logged on user, and local computer description. Easily extensible 
		for other information such as logged on time and other WMI queries. 
		Supports -Verbose output. 

        .PARAMETER Computers
        A PSObject such as a string or array containing one or many computers to run against. As it is a workflow it cannot support pipeline input.
		
		ALIAS: cn
		Position: 0

        .PARAMETER Credentials
        Accepts a PSCredential object (generated by get-credential)

        .PARAMETER HideOffline
        Hides offline or connection refused PCs from the results. 

        .EXAMPLE
        Get-ADStatusParallel -Computername COMPUTER1,COMPUTER2,COMPUTER3

		Output:
		\:>Get-ADStatusParallel Computer123, Computer124


			Computer              : Computer123
			IPAddress             : 192.168.1.15
			Username              : DOMAIN\username
			Description           : ASSET# 123 - Microsoft Surface Pro 5 - ABCD1234
			PSComputerName        : localhost
			PSSourceJobInstanceId : a753409e-4588-485d-a020-21e2550d2062

			Computer              : Computer124
			IPAddress             : 192.168.1.16
			Username              : DOMAIN\username
			Description           : ASSET# 124 - Microsoft Surface Pro 5 - XYZ9876
			PSComputerName        : localhost
			PSSourceJobInstanceId : a753409e-4588-485d-a020-56e3550h9876


        .NOTES
        AUTHOR: James Anderson
		LAST UPDATED: 6/11/2015
#>
Workflow Get-ADStatusParallel {
    [cmdletbinding()]
    param(
		[alias("cn")]
		[Parameter(Position=0,Mandatory=$true)]
        [psobject[]]$Computers,
        [System.Management.Automation.PSCredential] $Credentials,
        [switch]$HideOffline
    )

    foreach -parallel ($computer in $computers) {

        Write-Verbose -Message "Running against $($computer)"

		# InlineScript Required to use variables in a sane way. 
        InlineScript {

            # Move credentials in to the inline script for easier manipulation

            $creds = $using:Credentials

            # If none are provided create an empty PSCredential Object to force use of current user token.

            if (!$creds){

                $creds = ([PSCredential]::Empty)

            }

			# Test to see if we can talk to WMI on port 135. 
            $TCPclient = new-Object system.Net.Sockets.TcpClient
            $Connection = $TCPclient.BeginConnect($using:computer,135,$null,$null)
            $TimeOut = $Connection.AsyncWaitHandle.WaitOne(3000,$false)

			# Close the connection if cannot establish a wait handle. 
            if(!$TimeOut) {
                $TCPclient.Close()

                Write-Verbose "Could not connect to $($using:computer) port 135."

				# Add offline computers to our output if HideOffline flag is not switched. 
                if(!$using:HideOffline){
                $objprops =[ordered] @{
                    'Computer'=$Using:computer;
                    'IPAddress'="OFFLINE";
                    'Username' = "OFFLINE";
                    'Description' = "OFFLINE"}
                    
                    [PSCustomObject]$objprops
                }
            }

            else {
                Try {
                    Write-Verbose -Message "Closing TCP on: $($using:computer)"
					# We successfully connected, lets close the TCP connection and do some work. 
                    $TCPclient.EndConnect($Connection) | out-Null
                    $TCPclient.Close()

                    # Check each computer for the info.
                    Write-Verbose -Message "Checking $($using:computer)"
					
					# Query various WMI information.
					Write-Verbose -Message "Checking $($using:computer) for IP"
                    $PCQuery_IP = Get-WmiObject -ComputerName $using:computer -Query "SELECT IpAddress FROM Win32_NetworkAdapterConfiguration" -ErrorAction SilentlyContinue| where {$_.IPAddress } | Select -First 1
					Write-Verbose -Message "Checking $($using:computer) for Username"
                    $PCQuery_Username = Get-WmiObject -ComputerName $using:computer -Query "SELECT UserName FROM Win32_ComputerSystem" -Credential $creds -ErrorAction SilentlyContinue 
					Write-Verbose -Message "Checking $($using:computer) for Computer Description"
                    $PCQuery_Description = Get-WmiObject -ComputerName $using:computer -Query "SELECT Description FROM Win32_OperatingSystem"-Credential $creds -ErrorAction SilentlyContinue

                    # Process each query into a custom object for output.

                    Write-Verbose -Message "Queries completed for $($using:computer)"

                            $objprops =[ordered] @{
                                'Computer'=$Using:computer;
                                'IPAddress'=$PCQuery_IP.IPAddress.Replace("{","").Replace("}","");
                                'Username' = $PCQuery_Username.UserName;
                                'Description' = $PCQuery_Description.Description}

                            [PSCustomObject]$objprops
              }
               Catch {
					# Catch any error and output it to verbose output in case something us unhappy.
					Write-Verbose $_.Exception.ToString()
					# If the TCP ENDCONNECT client operations up top fail they will end up here too.
					write-verbose "Connection to $($using:computer) on port 135 was refused."

              }

          }

      }

   }

}

<#
        .DESCRIPTION
        An easy to edit menu interface for Get-ADStatusParallel. Supports -Verbose output. 

        .PARAMETER Credentials
        Accepts a PSCredential object (generated by get-credential)

        .PARAMETER HideOffline
        Hides offline or connection refused PCs from the results. 

        .EXAMPLE
        Get-ADStatusParallelMenu

		Output:
		\:>Get-ADStatusParallelMenu

		This Generates User Logon Status By Organizational Unit. 

		Choose your OU.
		1 - Accounting
		2 - Human Resources
		3 - Executive Management
		4 - Sales
		IT - IT
		ALL - All Pcs (No Servers)

		Select Branch Number: : 1

			Computer              : Computer123
			IPAddress             : 192.168.1.15
			Username              : DOMAIN\username
			Description           : ASSET# 123 - Microsoft Surface Pro 5 - ABCD1234
			PSComputerName        : localhost
			PSSourceJobInstanceId : a753409e-4588-485d-a020-21e2550d2062

			Computer              : Computer124
			IPAddress             : 192.168.1.16
			Username              : DOMAIN\username
			Description           : ASSET# 124 - Microsoft Surface Pro 5 - XYZ9876
			PSComputerName        : localhost
			PSSourceJobInstanceId : a753409e-4588-485d-a020-56e3550h9876


        .NOTES
        AUTHOR: James Anderson
		LAST UPDATED: 6/11/2015
#>
 Function Get-ADStatusParallelMenu{
    [cmdletbinding()]
    param(
        [System.Management.Automation.PSCredential] $Credentials,
        [switch]$HideOffline
		)
	# Explain what the Menu does 
	Write-Host " " 
	Write-Host "This Generates User Logon Status By Organizational Unit" -foregroundcolor "DarkBlue" -backgroundcolor "Yellow"
	Write-Host " " 
 
	# Select environment MENU
	Write-Host "Choose your Branch." -foregroundcolor "DarkBlue" -backgroundcolor "Yellow"
	Write-Output "1 - Accounting"
	Write-Output "2 - Human Resources"
	Write-Output "3 - Executive Management"
	Write-Output "4 - Sales"
	Write-Output "IT - Information Technology"
	Write-Output "ALL - All Computers (No Servers)"
	Write-Output " "
	$a = Read-Host "Select Branch Number: "

	switch ($a) {
		"1" {
			$ou = get-adcomputer -filter * -SearchBase "OU=Computers,OU=Accounting,DC=MyDomain,DC=COM"
			if (!$HideOffline){Get-ADStatusParallel -Computers $ou.name -Credentials $Credentials} else {Get-ADStatusParallel -Computers $ou.name -Credentials $Credentials -HideOffline}
		}
		"2" {
			$ou = get-adcomputer -filter * -SearchBase "OU=Computers,OU=Human Resources,DC=MyDomain,DC=COM"
			if (!$HideOffline){Get-ADStatusParallel -Computers $ou.name -Credentials $Credentials} else {Get-ADStatusParallel -Computers $ou.name -Credentials $Credentials -HideOffline}
		}
		"3" {
			$ou = get-adcomputer -filter * -SearchBase "OU=Computers,OU=Executive Management,DC=MyDomain,DC=COM"
			if (!$HideOffline){Get-ADStatusParallel -Computers $ou.name -Credentials $Credentials} else {Get-ADStatusParallel -Computers $ou.name -Credentials $Credentials -HideOffline}
		}
		"4" {
			$ou = get-adcomputer -filter * -SearchBase "OU=Computers,OU=Sales,DC=MyDomain,DC=COM"
			if (!$HideOffline){Get-ADStatusParallel -Computers $ou.name -Credentials $Credentials} else {Get-ADStatusParallel -Computers $ou.name -Credentials $Credentials -HideOffline}
		}
		"IT" {
			$ou = get-adcomputer -filter * -SearchBase "OU=IT,DC=MyDomain,DC=COM"
			if (!$HideOffline){Get-ADStatusParallel -Computers $ou.name -Credentials $Credentials} else {Get-ADStatusParallel -Computers $ou.name -Credentials $Credentials -HideOffline}
		}
		"ALL" {
			$ou = get-adcomputer -filter {OperatingSystem -notlike "Windows*Server*"}
			if (!$HideOffline){Get-ADStatusParallel -Computers $ou.name -Credentials $Credentials} else {Get-ADStatusParallel -Computers $ou.name -Credentials $Credentials -HideOffline}
		}
	}
}