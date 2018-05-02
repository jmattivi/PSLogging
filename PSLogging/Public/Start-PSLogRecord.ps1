function Start-PSLogRecord
{
    <#
        .SYNOPSIS
            Inserts new record into the PSLogging table
    
        .DESCRIPTION
            Inserts new record into the PSLogging table
    
        .PARAMETER Server
            A SQL instance to run against. For default instances, only specify the computer name: "MyComputer". For named instances, use the format "ComputerName\InstanceName".
    
        .PARAMETER Database
            A string specifying the name of a database.
    
        .PARAMETER Port
            Port to connect to.  Defaults to 1433

        .PARAMETER SQLConnection
            Hash table specifying connection details (Server, Database, Port)

        .PARAMETER RunbookName
            Working runbook name
        
        .PARAMETER Stage
            Current task or process being performed

        .PARAMETER Job
            Client or target for the task
        
        .PARAMETER CustomField01
            Additional comments
    
        .PARAMETER CustomField02
            Additional comments

        .PARAMETER CustomField03
            Additional comments

        .PARAMETER CustomField04
            Additional comments

        .PARAMETER CustomField05
            Additional comments

        .PARAMETER CustomField06
            Additional comments

        .PARAMETER CustomField07
            Additional comments

        .PARAMETER CustomField08
            Additional comments

        .PARAMETER CustomField09
            Additional comments

        .PARAMETER CustomField10
            Additional comments

        .EXAMPLE
            $sqlconnection = @{
                server = "myserver"
                database = "mydb"
                port = "1433"
            }
            
            Start-PSLogRecord -SQLConnection $sqlconnection -RunbookName myawesomerunbook -job serverA
    
    #>

    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true, ParameterSetName = "IndividualConnection")]
        [String]$Server,
        [parameter(Mandatory = $true, ParameterSetName = "IndividualConnection")]
        [String]$Database,
        [parameter(Mandatory = $true, ParameterSetName = "IndividualConnection")]
        [int]$Port = '1433',
        [parameter(Mandatory = $true, ParameterSetName = "ConnectionTable")]
        [Object]$SQLConnection,
        [Parameter(Mandatory = $true)]
        $RunbookName,
        [Parameter(Mandatory = $false)]
        $Stage = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $Job = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $CustomField01 = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $CustomField02 = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $CustomField03 = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $CustomField04 = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $CustomField05 = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $CustomField06 = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $CustomField07 = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $CustomField08 = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $CustomField09 = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $CustomField10 = [DBNull]::Value
    )

    if ($sqlconnection)
    {
        [String]$server = $sqlconnection.Server
        [String]$database = $sqlconnection.Database
        [String]$port = $sqlconnection.Port
    }
    
    $status = "Start"
    $runbookworker = $env:COMPUTERNAME
    $runbookpid = $PID
    	
    $query = @"
DECLARE @RecordID bigint

INSERT INTO [PSLogging]
(
    [StartDateTime],
    [UpdateDateTime],
    [RunbookName],
    [RunbookWorker],
    [RunbookPID],
    [Status],
    [Stage],
    [Job],
    [CustomField01],
    [CustomField02],
    [CustomField03],
    [CustomField04],
    [CustomField05],
    [CustomField06],
    [CustomField07],
    [CustomField08],
    [CustomField09],
    [CustomField10]
)
VALUES
(
    current_timestamp,
    current_timestamp,
    @runbookname,
    @runbookworker,
    @runbookpid,
    @status,
    @stage,
    @job,
    @customfield01,
    @customfield02,
    @customfield03,
    @customfield04,
    @customfield05,
    @customfield06,
    @customfield07,
    @customfield08,
    @customfield09,
    @customfield10
)

Set @RecordID = SCOPE_IDENTITY()
Select RecordID
From PSLogging
Where RecordID = @RecordID
"@
	
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = "Data Source=$server,$port;database='$database';trusted_connection=true;" 
    $connection.Open()
    $command = New-Object System.Data.SqlClient.SqlCommand
    $command.Connection = $connection
    $command.CommandText = $query
    $command.Parameters.AddWithValue("@runbookname", $runbookname) | Out-Null
    $command.Parameters.AddWithValue("@runbookworker", $runbookworker) | Out-Null
    $command.Parameters.AddWithValue("@runbookpid", $runbookpid) | Out-Null
    $command.Parameters.AddWithValue("@status", $status) | Out-Null
    $command.Parameters.AddWithValue("@stage", $stage) | Out-Null
    $command.Parameters.AddWithValue("@job", $job) | Out-Null
    $command.Parameters.AddWithValue("@customfield01", $customfield01) | Out-Null
    $command.Parameters.AddWithValue("@customfield02", $customfield02) | Out-Null
    $command.Parameters.AddWithValue("@customfield03", $customfield03) | Out-Null
    $command.Parameters.AddWithValue("@customfield04", $customfield04) | Out-Null
    $command.Parameters.AddWithValue("@customfield05", $customfield05) | Out-Null
    $command.Parameters.AddWithValue("@customfield06", $customfield06) | Out-Null
    $command.Parameters.AddWithValue("@customfield07", $customfield07) | Out-Null
    $command.Parameters.AddWithValue("@customfield08", $customfield08) | Out-Null
    $command.Parameters.AddWithValue("@customfield09", $customfield09) | Out-Null
    $command.Parameters.AddWithValue("@customfield10", $customfield10) | Out-Null
    $results = $command.ExecuteScalar()
    $connection.Close()
    
    return $results
	
}