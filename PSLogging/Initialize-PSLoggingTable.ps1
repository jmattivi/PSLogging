function Initialize-PSLoggingTable
{
    <#	
    .SYNOPSIS
        Creates database and table for PSLogging
    
    .DESCRIPTION
        Instantiates requirements for the module to work

    .PARAMETER Server
        A SQL instance to run against. For default instances, only specify the computer name: "MyComputer". For named instances, use the format "ComputerName\InstanceName"
    
    .PARAMETER DBName
        A string specifying the name of a database

    .PARAMETER UseExistingDB
        Switch to only create PSLogging table on existing database
    
    .PARAMETER SysFileSize
        Initial file setup

    .PARAMETER LogFileSize
        Initial file setup

    .PARAMETER SysFileGrowth
        Initial file setup

    .PARAMETER SysFileMaxSize
        Initial file setup

    .PARAMETER LogFileGrowth
        Initial file setup

    .PARAMETER LogFileMaxSize
        Initial file setup

    .PARAMETER DBRecModel
        Database recovery model

    .EXAMPLE
    	Initialize-PSLoggingTable -Server myserver -DBName PSLogging
    
    .EXAMPLE
        Initialize-PSLoggingTable -Server myserver -DBName CustomTasks -UseExistingDB
    
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Server ,
        [Parameter(Mandatory = $true)]
        [String]$DBName,
        [Parameter(Mandatory = $false)]
        [Switch]$UseExistingDB,
        [Parameter(Mandatory = $false)]
        [int]$SysFileSize = 25,
        [Parameter(Mandatory = $false)]
        [int]$LogFileSize = 25,
        [Parameter(Mandatory = $false)]
        [int]$SysFileGrowth = 50,
        [Parameter(Mandatory = $false)]
        [int]$SysFileMaxSize = 1024,
        [Parameter(Mandatory = $false)]
        [int]$LogFileGrowth = 50,
        [Parameter(Mandatory = $false)]
        [int]$LogFileMaxSize = 1024,
        [Parameter(Mandatory = $false)]
        [ValidateSet("SIMPLE", "FULL")]
        [String]$DBRecModel = 'FULL'
    )

    try
    {
        # Set server object
        Add-Type -Path $(gci -Path 'C:\Program Files\Microsoft SQL Server\*\SDK\Assemblies\Microsoft.SqlServer.Smo.dll' | Select -Last 1 -ExpandProperty fullname)
        $srv = New-Object ('Microsoft.SqlServer.Management.SMO.Server') $server
        $db = $srv.Databases[$DBName]
        
        if (-not $UseExistingDB)
        {
            if ($srv.Databases[$DBName])
            {
                Write-Warning "$DBName already exists on $Server"
                break
            }
        
            # Define the variables
            # Set the file sizes (sizes are in KB, so multiply here to MB)
            $SysFileSize = [double]($SysFileSize * 1024.0)
            $LogFileSize = [double] ($LogFileSize * 1024.0)
            $SysFileGrowth = [double] ($SysFileGrowth * 1024.0)
            $SysFileMaxSize = [double] ($SysFileMaxSize * 1024.0)
            $LogFileGrowth = [double] ($LogFileGrowth * 1024.0)
            $LogFileMaxSize = [double] ($LogFileMaxSize * 1024.0)
   

            Write-Output "Creating database: $DBName on $Server"
 
            # Set the Default File Locations
            $DefaultDataLoc = $srv.Settings.DefaultFile
            $DefaultLogLoc = $srv.Settings.DefaultLog
 
            # If these are not set, then use the location of the master db mdf/ldf
            if ($DefaultDataLoc.Length -EQ 0)
            {
                $DefaultDataLoc = $srv.Information.MasterDBPath
            }
            if ($DefaultLogLoc.Length -EQ 0)
            {
                $DefaultLogLoc = $srv.Information.MasterDBLogPath
            }
 
            # new database object
            $DB = New-Object ('Microsoft.SqlServer.Management.SMO.Database') ($srv, $DBName)
 
            # new filegroup object
            $PrimaryFG = New-Object ('Microsoft.SqlServer.Management.SMO.FileGroup') ($DB, 'PRIMARY')
            # Add the filegroup object to the database object
            $DB.FileGroups.Add($PrimaryFG)
 
            # Create the database files
            # First, create a data file on the primary filegroup.
            $SystemFileName = $DBName
            $SysFile = New-Object ('Microsoft.SqlServer.Management.SMO.DataFile') ($PrimaryFG , $SystemFileName)
            $PrimaryFG.Files.Add($SysFile)
            $SysFile.FileName = $DefaultDataLoc + $SystemFileName + ".MDF"
            $SysFile.Size = $SysFileSize
            $SysFile.GrowthType = "KB"
            $SysFile.Growth = $SysFileGrowth
            $SysFile.MaxSize = $SysFileMaxSize
            $SysFile.IsPrimaryFile = 'True'
 
            # Create a log file for this database
            $LogFileName = $DBName + "_Log"
            $LogFile = New-Object ('Microsoft.SqlServer.Management.SMO.LogFile') ($DB, $LogFileName)
            $DB.LogFiles.Add($LogFile)
            $LogFile.FileName = $DefaultLogLoc + $LogFileName + ".LDF"
            $LogFile.Size = $LogFileSize
            $LogFile.GrowthType = "KB"
            $LogFile.Growth = $LogFileGrowth
            $LogFile.MaxSize = $LogFileMaxSize
 
            #Set the Recovery Model
            $DB.RecoveryModel = $DBRecModel
            #Create the database
            $DB.Create()

            Write-Output "Database $DBName created"
        }
        
        if (-not $srv.Databases[$DBName])
        {
            Write-Warning "$DBName doesn't exist on $Server"
            break
        }
        
        Write-Output "Specified existing database - $dbname.  Creating table...."
        # Create the table
        $table = new-object ('Microsoft.SqlServer.Management.SMO.Table') ($db, "PSLogging", "dbo")
        if ($table)
        {
            Write-Warning "PSLogging table already exists on $Server\$dbname"
            break
        }

        $col1 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "RecordID", [Microsoft.SqlServer.Management.Smo.Datatype]::BigInt)
        $col1.Identity = $true
        $col1.IdentitySeed = 1
        $col1.IdentityIncrement = 1
        $col1.Nullable = $false
        $col2 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "StartDateTime", [Microsoft.SqlServer.Management.Smo.Datatype]::DateTime)
        $col2.Nullable = $false
        $col3 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "UpdateDateTime", [Microsoft.SqlServer.Management.Smo.Datatype]::DateTime)
        $col3.Nullable = $false
        $col4 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "EndDateTime", [Microsoft.SqlServer.Management.Smo.Datatype]::DateTime)
        $col4.Nullable = $true
        $col5 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "RunbookName", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(250))
        $col5.Nullable = $false
        $col6 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "RunbookWorker", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(50))
        $col6.Nullable = $false
        $col7 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "RunbookPID", [Microsoft.SqlServer.Management.Smo.Datatype]::Int)
        $col7.Nullable = $false
        $col8 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "Status", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(25))
        $col8.Nullable = $false
        $col9 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "Stage", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(100))
        $col9.Nullable = $true
        $col10 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "Job", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(100))
        $col10.Nullable = $true
        $col11 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "Exception", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarCharMax)
        $col11.Nullable = $true
        $col12 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "IncidentNumber", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(25))
        $col12.Nullable = $true
        $col13 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "Restart", [Microsoft.SqlServer.Management.Smo.Datatype]::Bit)
        $col13.Nullable = $true
        $col14 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "Restarted", [Microsoft.SqlServer.Management.Smo.Datatype]::Bit)
        $col14.Nullable = $true
        $col15 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "CustomField01", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(250))
        $col15.Nullable = $true
        $col16 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "CustomField02", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(250))
        $col16.Nullable = $true
        $col17 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "CustomField03", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(250))
        $col17.Nullable = $true
        $col18 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "CustomField04", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(250))
        $col18.Nullable = $true
        $col19 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "CustomField05", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(250))
        $col19.Nullable = $true
        $col20 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "CustomField06", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(250))
        $col20.Nullable = $true
        $col21 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "CustomField07", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(250))
        $col21.Nullable = $true
        $col22 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "CustomField08", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(250))
        $col22.Nullable = $true
        $col23 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "CustomField09", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(250))
        $col23.Nullable = $true
        $col24 = new-object ('Microsoft.SqlServer.Management.SMO.Column') ($table, "CustomField10", [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(250))
        $col24.Nullable = $true
        $table.Columns.Add($col1)
        $table.Columns.Add($col2)
        $table.Columns.Add($col3)
        $table.Columns.Add($col4)
        $table.Columns.Add($col5)
        $table.Columns.Add($col6)
        $table.Columns.Add($col7)
        $table.Columns.Add($col8)
        $table.Columns.Add($col9)
        $table.Columns.Add($col10)
        $table.Columns.Add($col11)
        $table.Columns.Add($col12)
        $table.Columns.Add($col13)
        $table.Columns.Add($col14)
        $table.Columns.Add($col15)
        $table.Columns.Add($col16)
        $table.Columns.Add($col17)
        $table.Columns.Add($col18)
        $table.Columns.Add($col19)
        $table.Columns.Add($col20)
        $table.Columns.Add($col21)
        $table.Columns.Add($col22)
        $table.Columns.Add($col23)
        $table.Columns.Add($col24)

        $idxrecordid = new-object ('Microsoft.SqlServer.Management.SMO.Index') ($table, "idx_RecordID")
        $idxrecordid.IsUnique = $true
        $idxrecordid.IsClustered = $false
        $idxrecordid.IndexKeyType = "None"
        $idxrecordidcol = new-object ('Microsoft.SqlServer.Management.SMO.IndexedColumn') ($idxrecordid, "RecordID")
        $idxrecordid.IndexedColumns.Add($idxrecordidcol)
        $table.Indexes.Add($idxrecordid)

        $chkstatus = new-object ('Microsoft.SqlServer.Management.SMO.Check') ($table, "check_Status")
        $chkstatus.Text = "([Status]='Warning' OR [Status]='Start' OR [Status]='Error' OR [Status]='Complete' OR [Status]='Checkpoint')"
        $chkstatus.IsChecked = $true
        $chkstatus.IsEnabled = $true
        $chkstatus.NotForReplication = $false
        $table.Checks.Add($chkstatus)

        $table.Create()

        Write-Output "Table $DBName created"
    }
    Catch
    {
        Write-Error $($_.Exception.Message)
    }
}