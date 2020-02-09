#:xheader:
#Type=ActionType;
#:xheader:


@{
    Base = 
    {
        Param(
            [ConfigAutomationContext] $context,
            [UIAction] $action,
            [string] $extraParameters,
            [string] $lifeCycle,
            [hashtable] $results
        )
    
        # Parameters expected on the action type
        $expectedSetupNeededParameters = @("OutputVariableName")
    
        # Get all Parameters given to the action
        $expectedInputParameters = $action.Parameters().Items() | ForEach-Object {$_.Name()} | Where-Object {-not ($_ -in $expectedSetupNeededParameters)}
    
        
        $actionType = $action.ActionType().Definition()

        if(-not ($action.Parameters().Validate($expectedInputParameters))){
            $context.Error("Action some invalid parameters")
            return $false
        }
        
        $inputParameters = $action.Parameters().Extract($expectedInputParameters)
        $setupNeededParameters = $action.Parameters().Extract($expectedSetupNeededParameters)
        $setupParameters = @{
            mainScriptPath=$($actionType.GetProperty("mainScriptPath"));
            requiresOutputVariable=$($actionType.GetProperty("requiresOutputVariable"));
            includeActionTypeParameters=$($actionType.GetProperty("includeActionTypeParameters"));
            hideVerbose=$($actionType.GetProperty("hideVerbose"));
        }

        $arguments = ""
        foreach($inputParameter in $inputParameters.psobject.properties){
            $arguments += "-$($inputParameter.Name) `$(`$inputParameters.$($inputParameter.Name)) "
        }

        if($setupParameters.includeActionTypeParameters -ieq "true"){
            $arguments += "-context `$(`$context) "
            $arguments += "-action `$(`$action) "
            $arguments += "-lifeCycle `$(`$lifeCycle) "
        }

        $scriptCommand = "&'$($setupParameters.mainScriptPath)' $arguments $extraParameters"      
        $temp = New-TemporaryFile
        $scriptCommand += " | out-file '$temp'"   
    
        if($setupParameters.requiresOutputVariable -and -not ($setupNeededParameters.OutputVariableName)){
            $context.Error("Action requires parameter '{white}OutputVariableName{gray}'")
            return $false
        }
        if($setupParameters.hideVerbose -eq "true"){
        }
        else{
            $context.Display("{white}Parameters:{gray}`r`n$(($inputParameters | ConvertTo-Json))")
            $context.Display("{white}Command:{gray}`r`n$($scriptCommand)")
        }

        ##################################################################
        # Run Script
        ##################################################################
        try{
            $results = Invoke-Expression $scriptCommand
        }
        catch [System.Management.Automation.ParameterBindingException]{
            [System.Management.Automation.ParameterBindingException]$exception = $_.Exception
            $context.Error("Script Parameter '{white}$($exception.ParameterName){gray}' failed validation with message:`r`n`t$($exception.Message)`r`n{white}Script Trace{gray}`r`n$($_.ScriptStackTrace)")
            return $false
        }
        finally{
            $content = Get-Content $temp
            $context.Display($content)
            Remove-Item $temp   
        }
        ##################################################################


        if($result -eq $false){
            $context.Display("Script returned with failing result")
            return $false
        }

        foreach($object in $results){
            if($object -is [System.Management.Automation.ErrorRecord]){
                $context.Error($object)
            }
            else{
                $context.Display($object)
            }
        }
        
        if($setupParameters._requiresOutputVariable){
            $context.InjectOutputVariable($action, $setupNeededParameters.OutputVariableName, $content)
        }
        return $true
    };
	Clean = 
	{
        Param([ConfigAutomationContext] $context,[UIAction] $action)

        $actionType = $action.ActionType().Definition()

        $setupParameters = @{
            cleanEnabled=$($actionType.GetProperty("cleanEnabled"));
        }

        if($setupParameters.cleanEnabled -ieq "true"){
            # Parameters expected on the action type
            $success = $actionType.InvokeCallback("Base",@(($actionType.Context()), $action, "-Clean", "Clean", $results))
            if(-not $success){
                return $false
            }
        }
        
        return $true
	};
	Action = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
        $actionType = $action.ActionType().Definition()
        
        $results = [hashtable]::new()

        $success = $actionType.InvokeCallback("Base",@(($action.Context()), $action, "-Execute",  "Execute", $results))
        if(-not $success){
            return $false
        }
        return $true
	};
	CanExecute = 
	{
		Param([ConfigAutomationContext] $context,[UIAction] $action)
		return $true
	};
	Validate = 
	{
        Param([ConfigAutomationContext] $context,[UIAction] $action)
        
        $actionType = $action.ActionType().Definition()
        
        $results = [hashtable]::new()

        $success = $actionType.InvokeCallback("Base",@(($actionType.Context()), $action, "-Validate -WhatIf", "Validate", $results))
        if(-not $success){
            return $false
        }
        return $true
	};
	
}