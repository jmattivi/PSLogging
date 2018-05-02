Function Get-PSLogRecord
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
    
        .EXAMPLE
            Get-PSLogRecord -SQLConnection
    
    #>
    [cmdletBinding(DefaultParameterSetName = "IndividualConnection")]
    Param (
        [parameter(Mandatory = $true, ParameterSetName = "IndividualConnection")]
        [String]$Server,
        [parameter(Mandatory = $true, ParameterSetName = "IndividualConnection")]
        [String]$Database,
        [parameter(Mandatory = $true, ParameterSetName = "IndividualConnection")]
        [String]$Port = '1433',
        [parameter(Mandatory = $true, ParameterSetName = "ConnectionTable")]
        [Object]$SQLConnection,
        [parameter(Mandatory = $true)]
        [String]$RecordID
    )
    
    if ($sqlconnection)
    {
        [String]$server = $sqlconnection.Server
        [String]$database = $sqlconnection.Database
        [String]$port = $sqlconnection.Port
    }

    $query = "Select * From PSLogging Where RecordID = $recordid"
    
    $datatable = New-Object System.Data.DataTable 
    $connection = New-Object System.Data.SQLClient.SQLConnection 
    $connection.ConnectionString = "Data Source=$server,$port;database='$database';trusted_connection=true;" 
    $connection.Open() 
    $command = New-Object System.Data.SQLClient.SQLCommand 
    $command.Connection = $connection 
    $command.CommandText = $query 
    $reader = $command.ExecuteReader() 
    $datatable.Load($reader) 
    $connection.Close() 
      
    return $datatable 
}