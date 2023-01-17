cls
$welcome = @"
 ______  _____ _______ _     _         _____   ______
 |     \   |   |______ |____/  |      |     | |  ____
 |_____/ __|__ ______| |    \_ |_____ |_____| |_____|
                                              W.S.S.D
								 
"@
write-host $welcome
$fname = "disklog-"+[DateTime]::Now.ToString("yyyyMMdd-HHmmss")+".html"
$folder = 'C:\Dell'
$filename = $folder + "\" + $fname
$filenamez= $filename -replace ".html",".zip"
Write-host "Please wait for 3-5 minutes"
Write-host "Output file path :"$filenamez

if (!(Test-Path $folder)) { mkdir C:\Dell }
$html = ''
$html = '<html>'
$html += '<style>body { font-family:Helvetica; } h1 { font-size:22px;font-weight:bold;margin-bottom: auto; } h2 { font-size:20px;font-weight:bold;padding-top:25px;margin-bottom:0px; } h3 { margin-bottom:0px; } label { font-family:monospace; font-size:10px;} table { border-collapse:collapse; min-width:550px; max-width:899px;padding:8px; } 
th, td { text-align:left;padding:5px;font-size:12px;border:1px solid #ddd; } tr:nth-child(even) { background-color: #f2f2f2 } th { background-color: #04AA6D; color: white; }</style>'
if ((Get-Command "Get-Cluster" -ErrorAction SilentlyContinue)) {
$html += '<h1>Disk Log</h1>'
$html += '<label>Running at ' + $env:COMPUTERNAME + ' Time : ' + [DateTime]::Now.ToString("yyyyMMdd-HHmmss") + '</label>'
$html += '<body>'
$html += '<h2>Cluster Info</h2>'
$getCluster = Get-Cluster | select Name,Domain,CrossSiteDelay,CrossSiteThreshold,CrossSubnetDelay,CrossSubnetThreshold
$html += $getCluster | ConvertTo-html -Fragment
}

if ((Get-Command "Get-ClusterPerf" -ErrorAction SilentlyContinue)) {
Get-ClusterPerf | out-file C:\Dell\temp.txt
$File = Get-Content C:\Dell\temp.txt
$clusperf = @()
Foreach ($Line in $File) {
    if (!($Line.Contains("Series") -or $Line.Contains("Time") -or $Line.Contains("Value") -or $Line.Contains("Unit") -or $Line.Contains("-"))) {
        $mystring = ($Line -replace "\s+"," ").Trim()
        $mystring = $mystring.Split(" ")
        $clusperf += @(
            [PSCustomObject]@{
                series = $mystring[0];
                time = $mystring[1] + " " + $mystring[2];
                value = $mystring[3];
                unit = $mystring[4];
            }
        )
    }
}

$html += '<h2>Cluster Statistic</h2>'
$html += '<table style="width:100%;border:1px solid black;">'
$html += '<thead style="background-color: #f2f2f2;text-align:left;"><tr>'
$html += '<th style="border:1px solid black;">Series</th>'
$html += '<th style="border:1px solid black;">Time</th>'
$html += '<th style="border:1px solid black;">Value</th>'
$html += '</tr></thead><tbody>'

$i = 0
foreach ($data in $clusperf) {
    if ($data.series) {
		if (!$data.series.Contains("Object")) {
			if($i % 2 -eq 0){
				$html += '<tr style="border:1px solid black;background-color: #f2f2f2;">'
			}else{
				$html += '<tr style="border:1px solid black;">'
			}
			
			$html += '<td style="border:1px solid black;">' + $data.series + '</td>'
			$html += '<td style="border:1px solid black;">' + $data.time + '</td>'
			$html += '<td style="border:1px solid black;">' + $data.value + " " + $data.unit + '</td>'
			$html += '</tr>'
			$i++
		}
    }
}

$html += '</tbody></table>'
}

if ((Get-Command "Get-ClusterNode" -ErrorAction SilentlyContinue)) {
$html += '<h2>Cluster Nodes</h2>'
$getClusterNode = Get-ClusterNode | select Name, State, Type, SerialNumber -ErrorAction SilentlyContinue
$html += $getClusterNode | ConvertTo-html -Fragment
}

$html += '<h2>Virtual Disk</h2>'
$getVirtualDisk = Get-VirtualDisk | select FriendlyName, ResiliencySettingName,PhysicalDiskRedundancy,NumberOfDataCopies,OperationalStatus,HealthStatus,@{label="Size(GB)";expression={[math]::round($_.Size/1GB,2)}},@{label="FootprintOnPool(GB)";expression={[math]::round($_.FootprintOnPool/1GB,2)}},@{label="Provisioning";expression={$_.ProvisioningType}},@{label="Dedup";expression={$_.IsDeduplicationEnabled}}              
$html += $getVirtualDisk | ConvertTo-html -Fragment

if ((Get-Command "Get-ClusterSharedVolume" -ErrorAction SilentlyContinue)) {
$html += '<h2>Virtual Disk (CSV) Owner</h2>'
$getCSV = Get-ClusterSharedVolume | select Name,State,OwnerNode | Sort OwnerNode
$html += $getCSV | ConvertTo-html -Fragment
}

$html += '<h2>Virtual Disk - Volume</h2>'
$getvdks = Get-VirtualDisk
$stovdks = foreach ($vdk in $getvdks) {
	Get-VirtualDisk -UniqueId $vdk.UniqueId | Get-Disk | Get-Partition | Get-Volume | select FileSystemLabel,DriveLetter,FileSystem,FileSystemType,HealthStatus,OperationalStatus,AllocationUnitSize,@{label="SizeRemaining (GB)";expression={[math]::round($_.SizeRemaining/1GB,2)}},@{label="Size (GB)";expression={[math]::round($_.Size/1GB,2)}}
}
$html += $stovdks | ConvertTo-html -Fragment

$html += '<h2>StoragePool</h2>'
$getstgpool = Get-StoragePool | select FriendlyName,OperationalStatus,HealthStatus,IsPrimordial,IsReadOnly,ResiliencySettingNameDefault,@{label="Size(GB)";expression={[math]::round($_.Size/1GB,2)}},@{label="AllocatedSize(GB)";expression={[math]::round($_.AllocatedSize/1GB,2)}},SupportedProvisioningTypes,ProvisioningTypeDefault
$html += $getstgpool | ConvertTo-html -Fragment

$getStoJob = Get-StorageJob | select Name, IsBackgroundTask, ElapsedTime, JobState, PercentComplete, BytesProcessed, BytesTotal
if ($getStoJob) {
$html += '<h2>StorageJob</h2>'
$html += $getStoJob | ConvertTo-html -Fragment
}

$getLC = Get-PhysicalDisk | ? {$_.OperationalStatus -match 'Lost Communication'} | Select FriendlyName,SerialNumber,CanPool,OperationalStatus,HealthStatus,VirtualDiskFootprint,Usage,@{label="Size (GB)";expression={[math]::round($_.Size/1GB,2)}},PhysicalLocation,ObjectId
if ($getLC) {
$html += '<h2>Disk Loss Communication : ' + ($getLC).count + '</h2>'
$html += $getLC | ConvertTo-html -Fragment
}

$getTE = Get-PhysicalDisk | ? {$_.OperationalStatus -match 'Transient Error'} | Select FriendlyName,SerialNumber,CanPool,OperationalStatus,HealthStatus,VirtualDiskFootprint,Usage,@{label="Size (GB)";expression={[math]::round($_.Size/1GB,2)}},PhysicalLocation,ObjectId
if ($getTE) {
$html += '<h2>Transient Error : ' + ($getTE).count + '</h2>'
$html += $getTE | ConvertTo-html -Fragment
}

$getIOE = Get-PhysicalDisk | ? {$_.OperationalStatus -match 'IO error'} | Select FriendlyName,SerialNumber,CanPool,OperationalStatus,HealthStatus,VirtualDiskFootprint,Usage,@{label="Size (GB)";expression={[math]::round($_.Size/1GB,2)}},PhysicalLocation,ObjectId
if ($getIOE) {
$html += '<h2>Disk IO Error : ' + ($getIOE).count + '</h2>'
$html += $getIOE | ConvertTo-html -Fragment
}

$getRFP = Get-PhysicalDisk | ? {$_.OperationalStatus -match 'Remove From Pool'} | Select FriendlyName,SerialNumber,CanPool,OperationalStatus,HealthStatus,VirtualDiskFootprint,Usage,@{label="Size (GB)";expression={[math]::round($_.Size/1GB,2)}},PhysicalLocation,ObjectId
if ($getRFP) {
$html += '<h2>Remove From Pool : ' + ($getRFP).count + '</h2>'
$html += $getRFP | ConvertTo-html -Fragment
}

$errCode = @()
$errCode = @(
    'OK'
    'IO error'
    'Transient Error'
    'Lost Communication'
    'In Maintenance Mode'
    'Removing From Pool, OK'
)

$getNOk = Get-PhysicalDisk | ? {$_.OperationalStatus -notin $errCode} | Select FriendlyName,SerialNumber,CanPool,OperationalStatus,HealthStatus,VirtualDiskFootprint,Usage,@{label="Size (GB)";expression={[math]::round($_.Size/1GB,2)}},PhysicalLocation,ObjectId
if ($getNOk) {
$html += '<h2>Non Okay Drive : ' + ($getNOk).count + '</h2>'
$html += $getNOk | ConvertTo-html -Fragment
}

if ((Get-Command "Get-StorageNode" -ErrorAction SilentlyContinue)) {
$html += '<h2>Connected Hard Disks Per Node</h2>'
$Nodes = Get-StorageNode | Select Name -Unique | Sort Name
ForEach($Node in $Nodes){
$html += '<h3>Hostname : ' + $Node.name + ' Total Disks : ' + (Get-StorageNode -Name $Node.name | Get-PhysicalDisk -PhysicallyConnected).count + '</h3>'
   $getNode = Get-StorageNode -Name $Node.name | Get-PhysicalDisk -PhysicallyConnected | Select FriendlyName,SerialNumber,CanPool,OperationalStatus,HealthStatus,Usage,@{label="Size (GB)";expression={[math]::round($_.Size/1GB,2)}},@{label="Percentage (%)";expression={[math]::round(($_.VirtualDiskFootprint/$_.Size)*100,2)}},PhysicalLocation -Unique | sort PhysicalLocation
   $html += $getNode | ConvertTo-html -Fragment
}

$tbhead = @()
$tbhead = @(
  'Hostname'
  'FriendlyName'
  'SerialNumber' 
  'CanPool'
  'OperationalStatus' 
  'HealthStatus'  
  'PhysicalLocation'
  'PowerOnHours'
  'Temperature'
  'ReadEC'
  'ReadET'
  'ReadEU'
  'WriteEC'
  'WriteET'
  'WriteEU'
  'ObjectId'
)

$html += '<h2>Physically Connected Hard Disk Details</h2>'
$html += '<table><tr>'
foreach ($item in $tbhead) {
$html += '<th>' + $item + '</th>'	
}
$html += '</tr>'

$gdisksto = @()
$fnodes = Get-StorageNode | Select Name -Unique | Sort Name
ForEach($Node in $fnodes){
   $gdisks = Get-StorageNode -Name $Node.name | Get-PhysicalDisk -PhysicallyConnected | Select FriendlyName,SerialNumber,ObjectId | sort PhysicalLocation
   
   foreach ($gdisk in $gdisks) {
		$gdid = $gdisk.ObjectId
		$gid = $gdid.split(":")
		$gidc = $gid[2] -replace "[^a-zA-Z0-9]"
		$gdisksto += @(
    	[PSCustomObject]@{Name = $Node.name;  
						  FriendlyName = $gdisk.FriendlyName;
						  SerialNumber = $gdisk.SerialNumber;
						  ObjectId = $gdisk.ObjectId;
						  UniqueId = $gidc;					  
						}
		)
   }  
}

$vdisks = Get-Physicaldisk | sort PhysicalLocation
$storects = foreach ($mydisk in $vdisks) {
	Get-PhysicalDisk -UniqueId $mydisk.UniqueId | Get-StorageReliabilityCounter | select UniqueId, ReadErrorsCorrected, ReadErrorsTotal, ReadErrorsUncorrected, WriteErrorsCorrected, WriteErrorsTotal, WriteErrorsUncorrected, PowerOnHours, Temperature 
}

$stordwr = @()
foreach ($gdsk in $storects) {
$stauid = $gdsk.UniqueId
$uid = $stauid.split(":")
$suid = $uid[2] -replace "[^a-zA-Z0-9]"
$stordwr += @(
    	[PSCustomObject]@{ReadErrorsCorrected = $gdsk.ReadErrorsCorrected;  
						  ReadErrorsTotal = $gdsk.ReadErrorsTotal;
						  ReadErrorsUncorrected = $gdsk.ReadErrorsUncorrected;
						  WriteErrorsCorrected = $gdsk.WriteErrorsCorrected;
						  WriteErrorsTotal = $gdsk.WriteErrorsTotal;
						  WriteErrorsUncorrected = $gdsk.WriteErrorsUncorrected;
						  PowerOnHours = $gdsk.PowerOnHours;
						  Temperature = $gdsk.Temperature;
						  UniqueId = $suid;						  
						}
	)
}

$ston2d = @()
foreach ($dt in $stordwr) {
   foreach ($gd in $gdisksto) {
		if ($dt.UniqueId -eq $gd.UniqueId) {
		$ston2d += @(
    	[PSCustomObject]@{Name = $gd.name
		                  ReadErrorsCorrected = $dt.ReadErrorsCorrected;  
						  ReadErrorsTotal = $dt.ReadErrorsTotal;
						  ReadErrorsUncorrected = $dt.ReadErrorsUncorrected;
						  WriteErrorsCorrected = $dt.WriteErrorsCorrected;
						  WriteErrorsTotal = $dt.WriteErrorsTotal;
						  WriteErrorsUncorrected = $dt.WriteErrorsUncorrected;
						  PowerOnHours = $dt.PowerOnHours;
						  Temperature = $dt.Temperature;
						  UniqueId = $dt.UniqueId;
						  ObjectId = $gd.ObjectId;
						}
		)
		}		
   }
}

$xout = foreach ($md in $vdisks) {
$oid = $md.ObjectId
$ouid = $oid.split(":")
$uuid = $ouid[2] -replace "[^a-zA-Z0-9]"
	foreach($vvdisk in $ston2d) {
		if ($uuid -eq $vvdisk.UniqueId) {
		   $fname = $vvdisk.name
		   $sname = $fname.split(".")
		   $html += '<tr><td data-toggle="tooltip" title="' + $fname + '">' + $sname[0].toUpper() + '</td><td>' + $md.friendlyname + '</td><td>' + $md.serialnumber + '</td><td>' + $md.CanPool + '</td><td>' + $md.OperationalStatus + '</td><td>' + $md.HealthStatus + '</td><td>' + $md.PhysicalLocation + '</td><td>' + $vvdisk.PowerOnHours + '</td><td>' + $vvdisk.Temperature + '</td><td>' + $vvdisk.ReadErrorsCorrected + '</td><td>' + $vvdisk.ReadErrorsTotal + '</td><td>' + $vvdisk.ReadErrorsUncorrected + '</td><td>' + $vvdisk.WriteErrorsCorrected + '</td><td>' + $vvdisk.WriteErrorsTotal + '</td><td>' + $vvdisk.WriteErrorsUncorrected + '</td><td>' + $vvdisk.ObjectId + '</td></tr>'
		}
	}
} 
$html += $xout
$html += '</table>'
}

$getConDisk = Get-Physicaldisk | Select FriendlyName,SerialNumber,CanPool,OperationalStatus,HealthStatus,Usage,@{label="Size(GB)";expression={[math]::round($_.Size/1GB,2)}},PhysicalLocation | sort PhysicalLocation
$html += '<h2>All Hard Disk : ' + ($getConDisk).count + '</h2>'
$html += $getConDisk | ConvertTo-html -Fragment

$fldisk = Get-Physicaldisk | select FriendlyName,HealthStatus,OperationalStatus, SerialNumber,AdapterSerialNumber,Manufacturer,Model,BusType,FirmwareVersion,MediaType,LogicalSectorSize,PhysicalSectorSize,ObjectId | sort PhysicalLocation
$html += '<h2>All Hard Disk Format-List : ' + ($fldisk).count + '</h2>'
$html += $fldisk | ConvertTo-html -Fragment

$v2pdisk = Get-VirtualDisk | sort PhysicalLocation
foreach ($v in $v2pdisk){
	$html += '<h3>Physical Disks used by ' + $v.FriendlyName + '</h3>'
    $v2p = Get-PhysicalDisk -VirtualDisk $v | select DeviceId, FriendlyName, SerialNumber, MediaType, CanPool, OperationalStatus, HealthStatus, Usage, @{label="Size (GB)";expression={[math]::round($_.Size/1GB,2)}}, FirmwareVersion, PhysicalLocation
	$html += $v2p | ConvertTo-html -Fragment
}

$html += '<h2>StorageSpaceDriver-Operational</h2>'
$date = (get-date).AddDays(-30)
$ssdo = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-StorageSpaces-Driver/Operational';Level=1,2,3;StartTime = $date} | select TimeCreated,Id,LevelDisplayName,Message | sort ProviderName,TimeCreated -Descending
$html += $ssdo | ConvertTo-html -Fragment

$html += '<h2>System Log</h2>'
$ssdo = Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Disk','Chkdsk','Microsoft-Windows-Kernel-Power';Level=1,2,3;StartTime = $date} | select TimeCreated,Id,LevelDisplayName,Message | sort ProviderName,TimeCreated -Descending
$html += $ssdo | ConvertTo-html -Fragment

$html += '</body></html>' 
$html | out-file $filename -Append
Compress-Archive -Path $filename -DestinationPath $filenamez
rm C:\Dell\temp.txt
rm $filename
Write-host "Done!"
