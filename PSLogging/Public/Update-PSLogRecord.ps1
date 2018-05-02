function Update-PSLogRecord
{
    <#
        .SYNOPSIS
            Selects existing record from the PSLogging table
    
        .DESCRIPTION
            Selects existing record from the PSLogging table
    
        .PARAMETER Server
            A SQL instance to run against. For default instances, only specify the computer name: "MyComputer". For named instances, use the format "ComputerName\InstanceName".
    
        .PARAMETER Database
            A string specifying the name of a database.
    
        .PARAMETER Port
            Port to connect to.  Defaults to 1433

        .PARAMETER SQLConnection
            Hash table specifying connection details (Server, Database, Port)

        .PARAMETER RecordID
            ID specified in where clause
        
        .PARAMETER RunbookName
            Working runbook name
        
        .PARAMETER Stage
            Current task or process being performed

        .PARAMETER Job
            Client or target for the task
        
        .PARAMETER Exception
            Exception message

        .PARAMETER IncidentNumber
            Incident number created in ITSM application
        
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
            Update-PSLogRecord -SQLConnection $sqlconnection -RecordID 1234 -Status Checkpoint -Stage CreateUser -CustomField01 Username
        
        .EXAMPLE
            $sqlconnection = @{
                server = "myserver"
                database = "mydb"
                port = "1433"
            }
            Update-PSLogRecord -SQLConnection $sqlconnection -RecordID 1234 -Status Error -Exception "ExectionMessage" -CustomField02 "Failed on task to create user"
    
    #>

    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true, ParameterSetName = "IndividualConnection")]
        [String]$Server,
        [parameter(Mandatory = $true, ParameterSetName = "IndividualConnection")]
        [String]$Database,
        [parameter(Mandatory = $true, ParameterSetName = "IndividualConnection")]
        [String]$Port = '1433',
        [parameter(Mandatory = $true, ParameterSetName = "ConnectionTable")]
        [Object]$SQLConnection,
        [Parameter(Mandatory = $true)]
        [Int64]$RecordID,
        [Parameter(Mandatory = $false)]
        $RunbookName = [DBNull]::Value,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Checkpoint", "Complete", "End", "Warning", "Error")]
        $Status = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $Stage = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $Job = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $Exception = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $IncidentNumber = [DBNull]::Value,
        [Parameter(Mandatory = $false)]
        $Restart = 0,
        [Parameter(Mandatory = $false)]
        $Restarted = 0,
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
    
    if ($status -in ("Complete", "End", "Warning", "Error"))
    {
        $enddatetime = Get-Date
    }
    else
    {
        $enddatetime = [DBNull]::Value
    }

    $runbookworker = $env:COMPUTERNAME
    $runbookpid = $PID
    
    $record = Get-PSLogRecord -SQLConnection $sqlconnection -RecordID $recordid
    
    $query = @"
Update [PSLogging]

Set
    [UpdateDateTime] = current_timestamp,
    [EndDateTime] = @enddatetime,
    [RunbookName] = @runbookname,
    [RunbookWorker] = @runbookworker,
    [RunbookPID] = @runbookpid,
    [Status] = @status,
    [Stage] = @stage,
    [Job] = @job,
    [Exception] = @exception,
    [IncidentNumber] = @incidentnumber,
    [Restart] = @restart,
    [Restarted] = @restarted,
    [CustomField01] = @customfield01,
    [CustomField02] = @customfield02,
    [CustomField03] = @customfield03,
    [CustomField04] = @customfield04,
    [CustomField05] = @customfield05,
    [CustomField06] = @customfield06,
    [CustomField07] = @customfield07,
    [CustomField08] = @customfield08,
    [CustomField09] = @customfield09,
    [CustomField10] = @customfield10
Where [RecordID] = $recordid

Select *
From PSLogging
Where RecordID = $recordid
"@
	
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = "Data Source=$server,$port;database='$database';trusted_connection=true;" 
    $connection.Open()
    $command = New-Object System.Data.SqlClient.SqlCommand
    $command.Connection = $connection
    $command.CommandText = $query
    $command.Parameters.AddWithValue("@enddatetime", $enddatetime) | Out-Null
    $command.Parameters.AddWithValue("@runbookname", ($(if ($runbookname -ne [DBNull]::Value)
                {
                    $runbookname
                }
                else
                {
                    ($record.RunbookName)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@runbookworker", ($(if ($runbookworker -ne [DBNull]::Value)
                {
                    $runbookworker
                }
                else
                {
                    ($record.RunbookWorker)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@runbookpid", ($(if ($runbookpid -ne [DBNull]::Value)
                {
                    $runbookpid
                }
                else
                {
                    ($record.RunbookPID)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@status", $status) | Out-Null
    $command.Parameters.AddWithValue("@stage", ($(if ($stage -ne [DBNull]::Value)
                {
                    $stage
                }
                else
                {
                    ($record.Stage)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@job", ($(if ($job -ne [DBNull]::Value)
                {
                    $job
                }
                else
                {
                    ($record.Job)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@exception", ($(if ($exception -ne [DBNull]::Value)
                {
                    $exception
                }
                else
                {
                    ($record.Exception)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@incidentnumber", ($(if ($incidentnumber -ne [DBNull]::Value)
                {
                    $incidentnumber
                }
                else
                {
                    ($record.IncidentNumber)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@restart", $restart) | Out-Null
    $command.Parameters.AddWithValue("@restarted", $restarted) | Out-Null
    $command.Parameters.AddWithValue("@customfield01", ($(if ($customfield01 -ne [DBNull]::Value)
                {
                    $customfield01
                }
                else
                {
                    ($record.CustomField01)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@customfield02", ($(if ($customfield02 -ne [DBNull]::Value)
                {
                    $customfield02
                }
                else
                {
                    ($record.CustomField02)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@customfield03", ($(if ($customfield03 -ne [DBNull]::Value)
                {
                    $customfield03
                }
                else
                {
                    ($record.CustomField03)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@customfield04", ($(if ($customfield04 -ne [DBNull]::Value)
                {
                    $customfield04
                }
                else
                {
                    ($record.CustomField04)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@customfield05", ($(if ($customfield05 -ne [DBNull]::Value)
                {
                    $customfield05
                }
                else
                {
                    ($record.CustomField05)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@customfield06", ($(if ($customfield06 -ne [DBNull]::Value)
                {
                    $customfield06
                }
                else
                {
                    ($record.CustomField06)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@customfield07", ($(if ($customfield07 -ne [DBNull]::Value)
                {
                    $customfield07
                }
                else
                {
                    ($record.CustomField07)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@customfield08", ($(if ($customfield08 -ne [DBNull]::Value)
                {
                    $customfield08
                }
                else
                {
                    ($record.CustomField08)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@customfield09", ($(if ($customfield09 -ne [DBNull]::Value)
                {
                    $customfield09
                }
                else
                {
                    ($record.CustomField09)
                }))) | Out-Null
    $command.Parameters.AddWithValue("@customfield10", ($(if ($customfield10 -ne [DBNull]::Value)
                {
                    $customfield10
                }
                else
                {
                    ($record.CustomField10)
                }))) | Out-Null
    $results = $command.ExecuteScalar()
    $connection.Close()
    
    return $results
	
}