
function New-DynamicParameter
{
    [CmdletBinding(DefaultParameterSetName = 'Core')]    
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)][string] $Name,
        [Parameter(Mandatory = $true, ParameterSetName = 'Core')][Parameter(Mandatory = $true, ParameterSetName = 'ValidateSet')][type] $Type,
        [Parameter(Mandatory = $false)][string] $ParameterSetName = '__AllParameterSets',
        [Parameter(Mandatory = $false)][bool] $Mandatory = $false,
        [Parameter(Mandatory = $false)][int] $Position,
        [Parameter(Mandatory = $false)][bool] $ValueFromPipelineByPropertyName = $false,
        [Parameter(Mandatory = $false)][string] $HelpMessage,
        [Parameter(Mandatory = $true, ParameterSetName = 'ValidateSet')][string[]] $ValidateSet,
        [Parameter(Mandatory = $false, ParameterSetName = 'ValidateSet')][bool] $IgnoreCase = $true
    )

    process
    {
        # Define Parameter Attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.ParameterSetName = $ParameterSetName
        $ParameterAttribute.Mandatory = $Mandatory
        $ParameterAttribute.Position = $Position
        $ParameterAttribute.ValueFromPipelineByPropertyName = $ValueFromPipelineByPropertyName
        $ParameterAttribute.HelpMessage = $HelpMessage

        # Define Parameter Validation Options if ValidateSet set was used
        if ($PSCmdlet.ParameterSetName -eq 'ValidateSet')
        {
            $ParameterValidateSet = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $ValidateSet -Strict (!$IgnoreCase)
        }

        # Add Parameter Attributes and ValidateSet to an Attribute Collection
        $AttributeCollection = New-Object Collections.ObjectModel.Collection[System.Attribute]
        $AttributeCollection.Add($ParameterAttribute)
        $AttributeCollection.Add($ParameterValidateSet)

        # Add parameter to parameter list
        $Parameter = New-Object System.Management.Automation.RuntimeDefinedParameter -ArgumentList @($Name, $Type, $AttributeCollection)

        # Expose parameter to the namespace
        $ParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $ParameterDictionary.Add($Name, $Parameter)
        return $ParameterDictionary
    }
}
Export-ModuleMember -Function New-DynamicParameter
Function Enter-Block {
	Param(
		[string] $Name
	)
	
	if(-not $Global:_enableTrace){
		return
	}
	
	Write-Output "$((Get-Date -Format "MM/dd/yyyy hh:mm:ss.ff"))`tEnter`t$($Name)" >> $Global:_traceFile

}
Function Exit-Block {
	Param(
		[string] $Name
	)
	if(-not $Global:_enableTrace){
		return
	}
	Write-Output "$((Get-Date -Format "MM/dd/yyyy hh:mm:ss.ff"))`tExit`t$($Name)" >> $Global:_traceFile

}
Function Get-BiConditional {
   Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,
        [Parameter(Position = 0, Mandatory=$true)]
        $IfExists,
        [Parameter(Position = 1, Mandatory=$true)]
        $DummyColChar,
        [Parameter(Position = 2, Mandatory=$true)]
        $IfNotExists,
		
		[Parameter()]
        $ExistedCallback,
		[Parameter()]
        $NotExistedCallback
		
   ) 
   
   # Quick check to make sure syntax is followed
   if($DummyColChar -ne ":"){
      throw "Incorrect use of '?:' operator. Must be in the following syntax `r`nValue | ?: {'true'} : {'false'}"
   }
   
   $leftSide = $InputObject
   if($leftSide -is [ScriptBlock]){
	  $leftSide = .$leftSide
   }
   
   # Choose the result based on the condition
   if($leftSide){
	  $chose    = $IfExists
	  $callback = $ExistedCallback
   }
   else{
     $chose     = $IfNotExists
	 $callback = $NotExistedCallback
   }
   
   # [ScriptBlock]
   if($chose -and $chose -is [ScriptBlock]){
	  $prev_ = $_
      Set-Variable -Name "_" -Value $leftSide
      .$chose
	  if($prev_){
		  Set-Variable -Name "_" -Value $prev_	
	   }
   }
   # [Basic Value]
   else{
	  $chose
   }
   
   if($callback){
	  
   }
}
Export-ModuleMember -Function Get-BiConditional
New-Alias -Name "?:" -Value Get-BiConditional
Export-ModuleMember -Alias "?:"

Function Get-OrDefault {
   Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,
        [Parameter(Position = 0)]
        $IfNotExists
   ) 
   
   $leftSide = $InputObject
   if($leftSide -is [ScriptBlock]){
	  $leftSide = .$leftSide
   }
   
   if($leftSide){
      $leftSide
   }
   else{
      $IfNotExists
   }
}
Export-ModuleMember -Function Get-OrDefault
New-Alias -Name "??:" -Value Get-OrDefault
Export-ModuleMember -Alias "??:"

Function XConfigMaster-ExpectedToExists {
   Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,
		
		[Parameter()]
        [String] $ErrorMessage,
		[Parameter()]
        [ScriptBlock] $ErrorCallback
		
   ) 
   
   $leftSide = $InputObject
   if($leftSide -is [ScriptBlock]){
	  $leftSide = .$leftSide
   }
   
   # Choose the result based on the condition
   if($leftSide){
	  $leftSide
	  return
   }
   
   if($Global:automationContext.CurrentScope()){
	  $Global:automationContext.CurrentScope().Error($ErrorMessage)
   }
   else{
	$Global:automationContext.Error($ErrorMessage)
   }
  
   if($ErrorCallback){
	.$ErrorCallback
   }
}
Export-ModuleMember -Function XConfigMaster-ExpectedToExists
New-Alias -Name "?expected" -Value XConfigMaster-ExpectedToExists
Export-ModuleMember -Alias "?expected"

function Format-Xml {
<#
.SYNOPSIS
Format the incoming object as the text of an XML document.
#>
    param(
        ## Text of an XML document.
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$Text
    )

    begin {
        $data = New-Object System.Collections.ArrayList
    }
    process {
        [void] $data.Add($Text -join "`n")
    }
    end {
        $doc=New-Object System.Xml.XmlDataDocument
        $doc.LoadXml($data -join "`n")
        $sw=New-Object System.Io.Stringwriter
        $writer=New-Object System.Xml.XmlTextWriter($sw)
        $writer.Formatting = [System.Xml.Formatting]::Indented
        $doc.WriteContentTo($writer)
        $sw.ToString()
    }
}
Export-ModuleMember -Function Format-Xml
# Credits to
# https://stackoverflow.com/questions/5588689/redirect-write-host-statements-to-file
# Usage:
# &'Script-With-Write-Hosts.ps1' [Argument List] | Select-WriteHost [-Quiet] | out-file .\test.txt
function Select-WriteHost
{
   [CmdletBinding(DefaultParameterSetName = 'FromPipeline')]
   param(
     [Parameter(ValueFromPipeline = $true, ParameterSetName = 'FromPipeline')]
     [object] $InputObject,

     [Parameter(Mandatory = $true, ParameterSetName = 'FromScriptblock', Position = 0)]
     [ScriptBlock] $ScriptBlock,

     [switch] $Quiet
   )

   begin
   {
     function Cleanup
     {
       # clear out our proxy version of write-host
       remove-item function:\write-host -ea 0
     }

     function ReplaceWriteHost([switch] $Quiet, [string] $Scope)
     {
         # create a proxy for write-host
         $metaData = New-Object System.Management.Automation.CommandMetaData (Get-Command 'Microsoft.PowerShell.Utility\Write-Host')
         $proxy = [System.Management.Automation.ProxyCommand]::create($metaData)

         # change its behavior
         $content = if($quiet)
                    {
                       # in quiet mode, whack the entire function body, simply pass input directly to the pipeline
                       $proxy -replace '(?s)\bbegin\b.+', '$Object' 
                    }
                    else
                    {
                       # in noisy mode, pass input to the pipeline, but allow real write-host to process as well
                       $proxy -replace '(\$steppablePipeline\.Process)', '$Object; $1'
                    }  

         # load our version into the specified scope
         Invoke-Expression "function ${scope}:Write-Host { $content }"
     }

     Cleanup

     # if we are running at the end of a pipeline, need to immediately inject our version
     #    into global scope, so that everybody else in the pipeline uses it.
     #    This works great, but dangerous if we don't clean up properly.
     if($pscmdlet.ParameterSetName -eq 'FromPipeline')
     {
        ReplaceWriteHost -Quiet:$quiet -Scope 'script'
     }
   }

   process
   {
      # if a scriptblock was passed to us, then we can declare
      #   our version as local scope and let the runtime take it out
      #   of scope for us.  Much safer, but it won't work in the pipeline scenario.
      #   The scriptblock will inherit our version automatically as it's in a child scope.
      if($pscmdlet.ParameterSetName -eq 'FromScriptBlock')
      {
        . ReplaceWriteHost -Quiet:$quiet -Scope 'local'
        & $scriptblock
      }
      else
      {
         # in pipeline scenario, just pass input along
         $InputObject
      }
   }

   end
   {
      Cleanup
   }  
}

function Write-Color() {
    Param (
        [string] $text = $(Write-Error "You must specify some text"),
        [switch] $NoNewLine = $false
    )
	
    $startColor = $host.UI.RawUI.ForegroundColor;
	# $regex = ([regex]'(.+?)(?:\{(red|cyan|green|blue|magenta)\}|$)(.*)')
	# while(-not ([String]::IsNullOrEmpty($text))){
		# $before = $regex.Replace($text,'$1')
		# $color  = $regex.Replace($text,'$2')
		# $after  = $regex.Replace($text,'$3')
		 # if ($_ -in [enum]::GetNames("ConsoleColor")) {
			# $host.UI.RawUI.ForegroundColor = ($_ -as [System.ConsoleColor]);
		# }
	# }
	
    $text.Split( [char]"{", [char]"}" ) | ForEach-Object { $i = 0; } {
        if ($i % 2 -eq 0) {
            Write-Host $_ -NoNewline;
        } else {
            if ($_ -in [enum]::GetNames("ConsoleColor")) {
                $host.UI.RawUI.ForegroundColor = ($_ -as [System.ConsoleColor]);
            }
			else{
				 Write-Host "{$($_)}" -NoNewline;
			}
        }

        $i++;
    }

    if (!$NoNewLine) {
        Write-Host;
    }
    $host.UI.RawUI.ForegroundColor = $startColor;
}
Export-ModuleMember -Function Write-Color
function Expand-AsHtml() {
    Param (
        [string] $text = $(Write-Error "You must specify some text"),
        [switch] $NoNewLine = $false
    )
	
    
	# $regex = ([regex]'(.+?)(?:\{(red|cyan|green|blue|magenta)\}|$)(.*)')
	# while(-not ([String]::IsNullOrEmpty($text))){
		# $before = $regex.Replace($text,'$1')
		# $color  = $regex.Replace($text,'$2')
		# $after  = $regex.Replace($text,'$3')
		 # if ($_ -in [enum]::GetNames("ConsoleColor")) {
			# $host.UI.RawUI.ForegroundColor = ($_ -as [System.ConsoleColor]);
		# }
	# }
	$final = "<div><span style='color:black'>"
    $text.Split( [char]"{", [char]"}" ) | ForEach-Object { $i = 0; } {
        if ($i % 2 -eq 0) {
			$final += $_
        } else {
            if ($_ -in [enum]::GetNames("ConsoleColor")) {
				$final += "<span style='color:$($_)'>"
            }
			else{
				$final += $_
				$final += "</span>"
				 
			}
        }

        $i++;
    }
	$final += "</span></div>"
    return $final
}
Export-ModuleMember -Function Expand-AsHtml
class Helper{

	static [System.Xml.XmlElement] CloneWithParents([System.Xml.XmlElement[]] $elements){
		$newElements = [XML]"<ConfigAutomation></ConfigAutomation>"
		$rootChanged = $false
		foreach($element in $elements){
			$newNode = $element.CloneNode($false)
			$node    = $element
			while($node.ParentNode -and -not ($node.ParentNode -is [System.Xml.XmlDocument])){
				$nodeParent = $node.ParentNode.CloneNode($false)
				if($nodeParent.HasAttribute("Ref") -and $nodeParent.HasAttribute("Name")){
					$nodeParent.RemoveAttribute("Name")
				}
				
				$test = $nodeParent.AppendChild($newNode)
				$node = $node.ParentNode
				$newNode = $nodeParent
			}
			
			if($newNode.LocalName -eq $newElements.FirstChild.LocalName){
				Foreach ($Node in $newNode.ChildNodes) {
					$test = $newElements.FirstChild.AppendChild($newElements.ImportNode($Node, $true))
				}
			}
			elseif($rootChanged){
				throw "Root alreay changed twice..."
			}
			else{
				$rootChanged = $true
				$newElements.ReplaceChild($newElements.ImportNode($newNode, $true),$newElements.FirstChild)
			}
		}
		
		
		return $newElements.FirstChild
	}
	static [bool] HasProperty([object] $obj, [string] $name){
		if(-not ([Helper]::GetAllProperties($obj) | Where {$_.Name -eq $name})){
			return $false
		}
		return $true
	}
	static [void] SetPropertyIfNotExists([object] $obj, [string] $typeName, [string] $name, [object] $value){
		if(-not ([Helper]::GetAllProperties($obj) | Where {$_.Name -eq $name})){
			$obj | Add-Member -MemberType NoteProperty -TypeName $typeName -Name $name -Value $value -Force
			return
		}
		
	}
	static [void] SetProperty([object] $obj, [string] $typeName, [string] $name, [object] $value){
		[Helper]::SetPropertyIfNotExists($obj, $typeName, $name, $value)

		$obj.$name = $value
	}
	static [System.Collections.ArrayList] GetAllProperties([object] $obj){
		return [Helper]::GetAllProperties($obj, @("_currentScope", "_parentScope", "rootScope", "_savedCurrentScope", "_context", "_overrideScope"))
	}
	# Get all properties for an object
	static [System.Collections.ArrayList] GetAllProperties([object] $obj, [string[]] $skipParameters){
		$properties = New-Object System.Collections.ArrayList	

		$test = ($obj | Select-Object -Property * ).psobject.Members  `
						| Where {$_.IsGettable -and $_.IsSettable} `
						| Foreach {$_.Name} `
						| Where {-not $skipParameters.Contains($_)} `
						| Where {$obj.$_} `
						| Foreach {@{PropertyType = $obj.$_.GetType(); Name = $_}} `
						| Foreach {$properties.Add($_)}
						
		$test = $obj.GetType().GetProperties() | Where {-not $skipParameters.Contains($_.Name)} `
											   | Foreach {@{PropertyType = $_.PropertyType; Name = $_.Name}} `
											   | Foreach {$properties.Add($_)}
		return $properties
	}
}
class HasContext{
	hidden [bool]                         $_invalid = $false
	hidden [bool]                         $_hidden = $false
	hidden [string]                       $_id
    hidden [ConfigAutomationContext]      $_context
    hidden [UIInputScopeBase]     	      $_currentScope
	hidden [UIInputScopeBase]     	      $_savedCurrentScope
	hidden [String]                	      $_generatedFromFile
	hidden [HasContext]            	      $_cloning 
	hidden [String]                	      $_name
	hidden [hashtable]             	      $_localVariables
	hidden [bool]                  	      $_isOverride
	static [String]                	      $Prefix = ""
	hidden [hashtable]             	      $_properties
	hidden [string]                	      $_bodyContent
	hidden [int]                   	      $_order = 0
	hidden [System.Collections.ArrayList] $_xmlDefinitions
	hidden [System.Collections.ArrayList] $_savedXmlDefinitions
	hidden [bool]                         $_childrenLoaded = $false
	hidden [string]                       $_sessionId
	hidden [hashtable] 					  $_fromCollections
	hidden [string]                       $_fromCollectionActiveId
    [UIInputScopeBase] Scope(){
        return $this._currentScope
    }
	
	
	
	##################################################################
	# Constructors
	##################################################################
	HasContext([ConfigAutomationContext] $_context){
		# Write-Color "{red} Calling empty constructor - {white}$($this.GetType().Name){gray}"
        $this._context               = $_context
        $this._currentScope          = $this.Context().CurrentScope()
		$this._savedCurrentScope     =  $this._currentScope
		$this._generatedFromFile     = $this.Context().CurrentLocation()
		$this._name                  = "NOT SET"
		$this._cloning               = $null
		$this._localVariables        = new-object hashtable
		$this._isOverride            = $false
		$this._properties            = new-object hashtable
		$this._xmlDefinitions        = new-object System.Collections.ArrayList
		$this._savedXmlDefinitions = new-object System.Collections.ArrayList
		$this._sessionId             = $this.Context().SessionId()
		$this._fromCollections       = new-object hashtable
		$this._id                    = Get-Random
		$this._fromCollectionActiveId= $null
		
		if((-not $this._generatedFromFile) -and $this.CurrentScope()){
			$this._generatedFromFile = $this.CurrentScope()._generatedFromFile
		}
		
		$this._localVariables.Add("Constants.Empty", " ")
		if([System.IO.File]::Exists($this._generatedFromFile)){
			$value = [System.IO.Path]::GetDirectoryName($this._generatedFromFile)
			#$this.Context().Display("XMLParsing", "Adding new Local Variable {white}ThisFolder{gray}  as {white}$value{gray}")
			$this._localVariables.Add("ThisFolder", $value)
			$this._localVariables.Add("ThisFile", $this._generatedFromFile)
		}
		else{
			$this._localVariables.Add("ThisFolder", "Unkown from type {white}$($this.GetType().Name){gray}")
			$this._localVariables.Add("ThisFile", "Unkown from type {white}$($this.GetType().Name){gray}")
			# $this.Context().Warning("XMLParsing", "Generated file '{white}$($this._generatedFromFile){gray}' does not exists, will not populate local variable {white}ThisFolder{gray}")
		}
    }

    HasContext([ConfigAutomationContext] $_context, [string] $name){
		try{
			throw "{red} Calling empty constructor - {white}$($name){gray} of type {white}$($this.GetType().Name){gray}"
		}
		catch{
			Write-Color "$($_.Exception.Message)`r`n{white}Stack Trace:{gray}`r`n$($_.ScriptStackTrace)"
		}
			
		
        $this._context               = $_context
        $this._currentScope          = $this.Context().CurrentScope()
		$this._savedCurrentScope     =  $this._currentScope
		$this._generatedFromFile     = $this.Context().CurrentLocation()
		$this._name                  = $name
		$this._cloning               = $null
		$this._localVariables        = new-object hashtable
		$this._isOverride            = $false
		$this._properties            = new-object hashtable
		$this._xmlDefinitions        = new-object System.Collections.ArrayList
		$this._savedXmlDefinitions   = new-object System.Collections.ArrayList
		$this._sessionId             = $this.Context().SessionId()
		$this._fromCollections       = new-object hashtable
		$this._id                    = Get-Random
		$this._fromCollectionActiveId= $null
		if((-not $this._generatedFromFile) -and $this.CurrentScope()){
			$this._generatedFromFile = $this.CurrentScope()._generatedFromFile
		}
		
		$this._localVariables.Add("Constants.Empty", " ")
		if([System.IO.File]::Exists($this._generatedFromFile)){
			$value = [System.IO.Path]::GetDirectoryName($this._generatedFromFile)
			#$this.Context().Display("XMLParsing", "Adding new Local Variable {white}ThisFolder{gray}  as {white}$value{gray}")
			$this._localVariables.Add("ThisFolder", $value)
			$this._localVariables.Add("ThisFile", $this._generatedFromFile)
		}
		else{
			$this._localVariables.Add("ThisFolder", "Unkown from type {white}$($this.GetType().Name){gray}")
			$this._localVariables.Add("ThisFile", "Unkown from type {white}$($this.GetType().Name){gray}")
			# $this.Context().Warning("XMLParsing", "Generated file '{white}$($this._generatedFromFile){gray}' does not exists, will not populate local variable {white}ThisFolder{gray}")
		}
    }

	##################################################################
    HasContext([ConfigAutomationContext] $_context, [UIInputScopeBase] $scope, [string] $name){
		if(-not $scope){
			Write-Color "{red} Calling constructor with no scope - {white}$($name){gray} of type {white}$($this.GetType().Name){gray}"
		}
        $this._context               = $_context
        $this._currentScope          = $scope
		$this._savedCurrentScope     = $this._currentScope 
		$this._generatedFromFile     = $this.Context().CurrentLocation()
		$this._name                  = $name
		$this._localVariables        = new-object hashtable
		$this._isOverride            = $false
		$this._properties            = new-object hashtable
		$this._xmlDefinitions        = new-object System.Collections.ArrayList
		$this._savedXmlDefinitions = new-object System.Collections.ArrayList
		$this._sessionId             = $this.Context().SessionId()
		$this._fromCollections       = new-object hashtable
		$this._id                    = Get-Random
		
		if((-not $this._generatedFromFile) -and $scope){
			$this._generatedFromFile = $scope._generatedFromFile
		}
		$this._localVariables.Add("Constants.Empty", " ")
		if([System.IO.File]::Exists($this._generatedFromFile)){
			$value = [System.IO.Path]::GetDirectoryName($this._generatedFromFile)
			#$this.Context().Display("XMLParsing", "Adding new Local Variable {white}ThisFolder{gray}  as {white}$value{gray}")
			$this._localVariables.Add("ThisFolder", $value)
			$this._localVariables.Add("ThisFile", $this._generatedFromFile)
		}
		else{
			$this._localVariables.Add("ThisFolder", "Unkown from type {white}$($this.GetType().Name){gray}")
			$this._localVariables.Add("ThisFile", "Unkown from type {white}$($this.GetType().Name){gray}")
			# $this.Context().Warning("XMLParsing", "Generated file '{white}$($this._generatedFromFile){gray}' does not exists, will not populate local variable {white}ThisFolder{gray}")
		}
	}
	[String] LocalVariables([string] $name){
		return $this._localVariables[$name]
	}
	[void] LocalVariables([string] $name, [string] $value){
		$this._localVariables[$name] = $value
	}
	[void] PrintParameterBreakdown(){
		
		$notDefinedParameters = [hashtable]::new()
		$missingParameters   = $this.Context().RequiredParameters() | Where-Object {$_.IsRequired() -and $_.IsMissing()}

		if($missingParameters.Count -gt 0)
		{
			Write-Host "`r`nParameters:"
			foreach($parameter in $missingParameters){
				$content = "   $($parameter.ToString()) {gray} "
				if($parameter.InputStrategies().Items().Count -eq 0){
					$content += "{white}[{red}Not Defined{white}]"
					if($notDefinedParameters[$parameter.ParameterName()]){
						$notDefinedParameters[$parameter.ParameterName()] += $parameter
					}
					else{
						$notDefinedParameters[$parameter.ParameterName()] = @($parameter)
					}
				}
				else{
					$contentText = ($parameter.InputStrategies().Items() | Foreach {return "{gray}{white}$($input.Shorthand()){gray}"} )
					$contentText = $contentText -join " {magenta}OR{gray} "
					$content += $contentText
				}
				Write-Color $content
			}
		}
		
		if($notDefinedParameters.Count -gt 0)
		{
			Write-Host "`r`nParameters (Not Defined):"
			
			$notDefinedParameters = $notDefinedParameters.GetEnumerator() | % {$_.Name}
			$notDefinedNames = $notDefinedParameters
			foreach($parameterName in $notDefinedNames){
				$parameterName = "{0,-50}" -f $parameterName
				$content = "   {white}$($parameterName){gray} {gray}[{red}Not Defined{gray}]"
				Write-Color $content
			}
		}
	}
	
	[bool] ValidateValue([string] $value, [string] $loggingName){
		return $this.ValidateValue($value, $loggingName, $true)
	}
	[bool] ValidateValue([string] $value, [string] $loggingName, [bool] $throwErrors){
		return $this.ValidateValue($value, $loggingName, "$", $throwErrors)
	}
	[bool] ValidateValue([string] $value, [string] $loggingName, [string] $variablePrefix, [bool] $throwErrors){
		Enter-Block "ValidateValue"
		$regexStr = '(['+$variablePrefix+'][(][^)\'+$variablePrefix+']*?[)])'
		$matches = ([regex]$regexStr).Matches($value)
		if($matches.Count -gt 0){			
			$valueWithRed = $value -replace $regexStr, '{red}$1{white}'
			
			if($throwErrors){
				$this.Error("Parameters", "{white}$($loggingName){gray} : Exepcted value to have no dependent parameters not filled but found {red}$($matches.Count) missing dependencies{gray} in pipeline {white}$($this.CurrentScope().FullName()){gray}:`r`n`r`n$([HasContext]::Prefix)       {gray}Value: `r`n$([HasContext]::Prefix)       {white}$($valueWithRed){gray}`r`n")
			}
			else{
				$this.Context().Warning("Parameters", "{white}$($loggingName){gray} : Exepcted value to have no dependent parameters not filled but found {red}$($matches.Count) missing dependencies{gray}  in pipeline {white}$($this.CurrentScope().FullName()){gray}:`r`n`r`n$([HasContext]::Prefix)       {gray}Value: `r`n$([HasContext]::Prefix)       {white}$($valueWithRed){gray}]`r`n")
			}
			Exit-Block "ValidateValue"
			return $false
		}
		Exit-Block "ValidateValue"
		return $true
	}
	
	[String] ParameterizeString([string] $value){
		return $this.ParameterizeString($value, $true, "$")
	}
	[String] ParameterizeString([string] $value, [string] $variablePrefix){
		return $this.ParameterizeString($value, $true, $variablePrefix)
	}
	[String] ParameterizeString([string] $value, [bool] $deepSearch, [string] $variablePrefix){
		return $this.ParameterizeString($value, $true, $variablePrefix, $false)
	}
	[String] ParameterizeStringAsPlainText([string] $value){
		return $this.ParameterizeString($value, $true, '$', $true)
	}
	[String] ParameterizeString([string] $value, [bool] $deepSearch, [string] $variablePrefix, [bool] $inPlanTxt){
		
		$originalValue = $value
		Enter-Block "ParameterizeString"
		$this.RefreshSessionIfNeeded()
		# $this.Display("Value {magenta}$value{gray}")
		$this.PushIndent()
		################################################################
		# Quickly Replace Values already known
		$this._localVariables.GetEnumerator() | % { 
			# Regex Expression is like so:
			# $_Name          = 'Var'
			# $variablePrefix = '$'
			#
			# [$][{(]Var[})]
			$thisPattern = '[' + $variablePrefix +'][(]'+($_.Name)+'[)]'
			if($value -match $thisPattern){
				# $this.Display("{magenta}Local Parameterizing {white}$($_.Name){gray} with value {white}$($_.Value){gray} inside of value {white}$($value){gray}")
				$newStr = $value -replace $thisPattern,($_.Value)
				$value = $newStr
			}
			
		}
		
		################################################################
		if($this.Context().IsParmeterizingDisabled()){
			$this.PopIndent()
			Exit-Block "ParameterizeString"
			return $value
		}
		
		$oldArguments = $this.Context().arguments["LogGroups"]
		if($this.Context().arguments["LogIgnoreMethods"] -and "$($this.GetType().Name).ParameterizeString" -match $this.Context().arguments["LogIgnoreMethods"]){
			$this.Context().arguments.Remove("LogGroups")
		}
		
		
		$this.Context().PushParmeterizing()
		#TEMP $this.Action("Parameterizing String {magenta}$($value){gray}")
		
		$this.Context().PopParmeterizing()
		
		$oldValue = $null
		
		
		$this.Context().PushParmeterizing()
		#TEMP $this.Action("Local Variable Replacing...")
		$this.Context().PopParmeterizing()
		
		
		$regex = [regex]('[\'+$variablePrefix+']\(((?>\((?<c>)|[^()]+|\)(?<-c>))*(?(c)(?!)))\)')
		
		if($this.Context().IsParmeterizingDisabled()){
			$this.Context().PushParmeterizing()
			$this.Display("{yellow}Skipping{gray}, due to {magenta}locked parameterizations{gray} - Value $($value)")
			$this.Context().PopParmeterizing()
		}
		elseif(-not ($value -match ('[`'+$variablePrefix+'][(]([^)\`'+$variablePrefix+']*?)[)]'))){
			$this.Context().PushParmeterizing()
			#TEMP $this.Action("{yellow}Skipping{gray}, due to {magenta}no dependent parameters found{gray}")
			$this.Context().PopParmeterizing()
		}
		else{
			$passes = 1
			# Make all inner "'" into "''" to account for the outer "'"
			while($oldValue -ne $value -and $value -match ('[`'+$variablePrefix+'][(]([^)\`'+$variablePrefix+']*?)[)]') -and -not $this.Context().IsParmeterizingDisabled()){
				#TEMP $this.Action("Run [{white}$($passes){gray}]")
				$this.PushIndent()
				
				$oldValue = $value
				$this.Context().PushParmeterizing()

				$currentScope = $this.Context().CurrentScope()
				
				$variables = new-object hashtable

				$replaceBlock2 = {
					Param( [System.Text.RegularExpressions.Match] $match)
					
					$name = $match.Groups[1].Value

					# If we have more variables to resolve inside, then contain them inside of a classic $() to capture the entire expression in the string
					if($regex.Match($name).Success){
						return '$(' + $($regex.Replace($name, $replaceBlock2)) + ')'
					}

					# If we have it, then return it
					if($variables[$name]){
						if($inPlanTxt){
							return $variables[$name]
						}
						return "`$(`$variables['$($name)'])"
					}
					$parameter = $currentScope.Parameters().Get($name, $deepSearch)
					
					if(-not $parameter){
						$this.Error("Parameter {magenta}$($name){gray} came back with null when trying to parameterize '{magenta}$($value){value}'")
						return $match.Value
					}
					
					$this.PushIndent()
					$value = $parameter.Value()
					$this.PopIndent()
					
					if($value -match ('([`'+$variablePrefix+'][(])(' + $name + ')([)])')){
						if(-not  $parameter.CurrentScope().ParentScope()){
							$this.Error("Found recursive parameter setting '$($foundParameter.ParameterName())' and there is no parent scope to grab from to resolve the recursion")
						}
						else{
							# Write-Host "Found Parameter: $($original___Input)"
							$currentScope = $parameter.CurrentScope().ParentScope()
							$name= "Parent $($name)"
							$value = $regex.Replace($Matches[1], $replaceBlock2)
							$currentScope = $this.Context().CurrentScope()
						}
					}
					if(-not $value){
						return "`$('`$(' + '$($name)' + ')')"
					}
					else{
						$variables[$name] = $value
						# $this.Display("Adding Variables[{magenta}$($name){gray}] = {magenta}$($value.GetType()){gray}/{magenta}$($value){gray}")
					}
					if($inPlanTxt){
						return $variables[$name]
					}
					return "`$(`$variables['$($name)'])"
				}
				$replaceBlock = {
					Param( [System.Text.RegularExpressions.Match] $match)

					$name = $match.Groups[1].Value

					# If the variable name is an expression. We need to resolve the execution of the expression, not the content
					if($name -match '^\@Expression\=(.*)$'){
						if($inPlanTxt){
							return $regex.Replace($Matches[1], $replaceBlock2)
						}
						
						return Invoke-Expression ($regex.Replace($Matches[1], $replaceBlock2))
					}

					# If the name of the variable has also variables in it
					if($regex.Match($name).Success){
						if($inPlanTxt){
							return $regex.Replace($name, $replaceBlock)
						}
						return $($regex.Replace($name, $replaceBlock))
					}	 
					
					# If we have already resolve this value, send it
					if($variables[$name]){
						if($inPlanTxt){
							return $variables[$name]
						}
						return $variables[$name]
					}
					
					# Find resolving variable
					$parameter = $currentScope.Parameters().Get($name, $deepSearch)
					
					# Not found. 
					if(-not $parameter){
						$this.Error("Parameter {magenta}$($name){gray} came back with null when trying to parameterize '{magenta}$($value){value}'")
						return "`$(`$variables['$($name)'])"
					}
					
					# Resolve value of parameter. THis is the recursive side of things
					$this.PushIndent()
					$value = $parameter.Value()
					$this.PopIndent()

					# If the value of the variable is referencing its self...
					# Meaning, $(VariableName) == "Some Text $(VariableName)"
					# This will need to reresolve but from the parent scope if its available
					if($value -match ('([`'+$variablePrefix+'][(])(' + $name + ')([)])')){
						if(-not  $parameter.CurrentScope().ParentScope()){
							$this.Error("Found recursive parameter setting '$($foundParameter.ParameterName())' and there is no parent scope to grab from to resolve the recursion")
						}
						else{
							# Write-Host "Found Parameter: $($original___Input)"
							$currentScope = $parameter.CurrentScope().ParentScope()
							$name= "Parent $($name)"
							$value = $regex.Replace($Matches[1], $replaceBlock)
							$currentScope = $this.Context().CurrentScope()
						}
					}
					
					# Value not found, send back $(name)
					if(-not $value){
						return "`$($($name))"
					}

					# Save it for later use
					$variables[$name] = $value
					
					
					if($inPlanTxt){
						return $variables[$name]
					}
					return $variables[$name]
				}
				
				try{
					$paramerizedValue = $regex.Replace($value, $replaceBlock)
					
					if($inPlanTxt){
						$newValue = $paramerizedValue
					}
					else{
						$valueExpression = '@"' + "`r`n" + $paramerizedValue + "`r`n" + '"@'
						$valueExpression = $valueExpression -replace '([^`]|^)\$(\([a-zA-Z\@])','$1`$$$2'  
						# $this.Display("Expression:`r`n$($valueExpression)")
						$newValue = Invoke-Expression $valueExpression
					}
					$value = $newValue
				}
				catch{
					$this.Error("Failed to parameterize $($originalValue): $($_.Exception.Message)`r`n$($_.Exception.StackTrace)`r`n$($_.ScriptStackTrace)")
					$value = $null
					
					$this.Context().PopParmeterizing()
					$this.PopIndent()
					$passes += 1
					break
				}
				
				
				$this.Context().PopParmeterizing()
				$this.PopIndent()
				
				$passes += 1
			}
		}
		
		if($this.Context().arguments["LogIgnoreMethods"] -and "$($this.GetType().Name).ParameterizeString" -match $this.Context().arguments["LogIgnoreMethods"] ){
			$this.Context().arguments["LogGroups"] = $oldArguments
		}
		#$this.Display("Ending Value {magenta}$($value){gray}")
		$this.PopIndent()
		Exit-Block "ParameterizeString"
		return $value
	}
	PushIndent([string] $grouping){
		$this.Context().PushIndent($grouping)
	}
	PopIndent([string] $grouping){
		$this.Context().PopIndent($grouping)
	}
	[String] FullName(){
		return $this.FullName(".")
	}
	[String] FullName([string] $joinText){
		
		return $this.CurrentScope().FullName($joinText) + " | "+$this.GetType().Name + " {gray}[{magenta}"+$($this.Name())+"{gray}]"
	}
	[String] Id(){
		return $this._id
	}
	PushIndent(){
		$this.Context().PushIndent()
	}
	PopIndent(){
		$this.Context().PopIndent()
	}
	[bool] IsRoot(){
		return $($this.Id()) -eq $($this.Context().GetRootScope().Id())
	}
	[object] GetProperty([string] $name){
		return $this.ParameterizeString($this._properties[$name]);
	}
	[bool] TestProperty([string] $name, [string] $value){
		return $this.TestProperty($name, $value, $true)
	}
	[bool] TestProperty([string] $name, [string] $value, [bool] $ignoreCase){
		$valueFound = $this._properties[$name]
		if(-not $valueFound){
			return $false
		}
		if($ignoreCase){
			return $valueFound -ieq $value
		}
		return $valueFound -eq $value
	}
	[void] ActiveFromCollection([HasCollectionContext] $hasContext){
		$this._fromCollectionActiveId = $hasContext.Id()
	}
	[Object] ActiveFromCollection(){
		return $this.FromCollections($this._fromCollectionActiveId)
	}
	[hashtable] FromCollections(){
		return $this._fromCollections
	}
	[Object] FromCollections([String] $id){
		return $this._fromCollections[$id]
	}
	
	[bool] FromCollections([HasCollectionContext] $fromCollection, [hashtable] $properties){
		
		# Is Null Check
		if(-not $fromCollection){
			$this.Warning("Trying to add null collection to context $($this.FullName())")
			return $false;
		}
		
		# Already part of this collection check. If the collection is handling duplicates correctly we should never see this...
		if($this.FromCollections($fromCollection.Id())){
			$this.Warning("Collection $($fromCollection.FullName()) should not be added since it was already added to $($this.FullName()), something is wrong")
			return $false;
		}
		
		# Add new collection
		$this._fromCollections.Add($fromCollection.Id(), @{Collection = $fromCollection; Properties = $properties})
		return $true
	}
	Error([string] $grouping, [string] $message){
		$this.Context().Error($grouping, "[{gray}$($this.GetType().Name){gray}] {magenta}$($this.Name()){gray} ::  $($message) - $($this.GetScopeString())")
	}
	Action([string] $grouping, [string] $message){	
		$this.Context().Action($grouping, "[{gray}$($this.GetType().Name){gray}] {magenta}$($this.Name()){gray} :: $($message) - $($this.GetScopeString())")
	}
	Warning([string] $grouping, [string] $message){
		$this.Context().Warning($grouping, "[{gray}$($this.GetType().Name){gray}] {magenta}$($this.Name()){gray} :: $($message) - $($this.GetScopeString())")
	}
	Log([string] $grouping, [string] $message){
		$this.Context().Log($grouping, "[{gray}$($this.GetType().Name){gray}] {magenta}$($this.Name()){gray} :: $($message) - $($this.GetScopeString())")
	}
	Display([string] $grouping, [string] $message){
		$this.Context().Display($grouping, "[{gray}$($this.GetType().Name){gray}] {magenta}$($this.Name()){gray} :: $($message) - $($this.GetScopeString())")
	}
	Error([string] $message){
		$this.Context().Error($this.GetType().Name, "[{gray}$($this.GetType().Name){gray}] {magenta}$($this.Name()){gray} ::  $($message) - $($this.GetScopeString())")
	}
	Display([string] $message){
		$this.Display($this.GetType().Name, $message)
	}
	Action([string] $message){	
		$this.Action($this.GetType().Name, $message)
	}
	Warning([string] $message){
		$this.Warning($this.GetType().Name, $message)
	}
	Log([string] $message){
		$this.Log($this.GetType().Name, $message)
	}
	########################################################################
	# Getters/Settings
	########################################################################
	[int] Order(){
		if($this._properties.ContainsKey("Order")){
			$order = $this._properties["Order"]
			if(-not ([int]::TryParse($order, [ref]$order))){
				$this.Error("XMLParsing", "Incorrect value for 'Order' given to {white}$($this.GetType().Name) $($this.Name()){gray}, must be a number")
				return $this._order
			}
			$this._order = $order
			$this._properties.Remove("Order")
			return $this._order
		}
		return $this._order
    }
	[void] Order([int] $order){
		$this._order = $order
	}
	[System.Collections.ArrayList] SavedXmlDefinitions(){
		return $this._savedXmlDefinitions
	}
	[System.Collections.ArrayList] XmlDefinitions(){
		return $this._xmlDefinitions
	}
	
	
	[void] AddXmlDefinition([System.Xml.XmlElement] $xmlDefinition, [string] $location){
	
		
		if(-not $xmlDefinition -or (-not $this.Context().SaveXmlEnabled())){
			return
		}

		$currentFormated = ($xmlDefinition.Outerxml | Format-Xml)
		foreach($saved in $this._savedXmlDefinitions){
			$savedFormated = ($saved.Xml.Outerxml | Format-Xml)
			if($currentFormated -eq $savedFormated){
				#$this.Display("Skipping ingestion of xml since it has already been injected in the past")
				return
			}
		}
			
		# Wrapped XmlDefinition
		$this._savedXmlDefinitions.Add(@{Xml = $xmlDefinition.CloneNode($true); Location = $location})
		
		# Set the normal xml definition
		$this._xmlDefinitions.Add(@{Xml = $xmlDefinition.CloneNode($true); Location = $location})
		
		return
	}
	
	
	# Current Scope
	[UIInputScopeBase] CurrentScope(){
        return $this._currentScope
    }
	[void] CurrentScope([UIInputScopeBase] $scope){
		$this._currentScope = $scope
	}

	# Context
	[ConfigAutomationContext] Context(){
        return $this._context
    }
	
	# Context
	[String] Name(){
        return $this._name
    }
	# Hidden
	[bool] IsHidden(){
		if($this._properties["Condition"]){
			if(-not ($this -is [UIAction])){
				$this.Error("Trying to use 'Condition' when its not usable in this type of element")
			}
			# $expression = $this.ParameterizeString($this._properties["Condition"])
			# $isEnabled = Invoke-Expression $expression
			# if(-not $isEnabled){
			# 	$this.Dispaly("{yellow}Hiding {gray} {white}(Condition = false){gray}")
			# 	$this.IsHidden($true)
			# }
		}
		return $this._hidden
	}
	[void] IsHidden([bool] $hidden){
		if($this.IsHidden() -ne $hidden){
			$this.Context().Action("Parameters", "Setting hidden for [{white}$($this.GetType().Name){gray}] {white}$($this.Name()){gray} to {white}$($hidden){gray}")
		}
		$this._hidden = $hidden
	}
	# Invalid
	[bool] IsInvalid(){
		return $this._invalid
	}
	[void] IsInvalid([bool] $isIvalid){
		if($this.IsInvalid() -ne $isIvalid){
			$this.Context().Action("Parameters", "Setting invalid for [{white}$($this.GetType().Name){gray}] {white}$($this.Name()){gray} to {white}$($isIvalid){gray}")
		}
		$this._invalid = $isIvalid
	}
	# Override
	[bool] IsOverride(){
		return $this._isOverride
	}
	[void] IsOverride([bool] $isOverride){
		if($this.IsOverride() -ne $isOverride){
			$this.Context().Action("Parameters", "Setting override for [{white}$($this.GetType().Name){gray}] {white}$($this.Name()){gray} to {white}$($isOverride){gray}")
		}
		$this._isOverride = $isOverride
	}
	
	########################################################################
	# 1 off helpers
	########################################################################
	[string] GetScopeString(){
		$content = ""
		if($this.Context().arguments["ShowScopeInfo"] -ieq "true"){
			if($this.CurrentScope().ParentScope()){
				$content = "{white}Scope [{Magenta}$($this.CurrentScope().Name()){white}], Parent Scope [{Magenta}$($this.CurrentScope().ParentScopeName()){white}]{gray}, {white}File Name [{magenta}$([System.IO.Path]::GetFileName($this._generatedFromFile)){gray}]"
			}
			else{
				$content = "{white}Scope [{Magenta}$($this.CurrentScope().Name()){white}], Parent Scope [{Magenta}No Parent{white}]{gray}, {white}File Name [{magenta}$([System.IO.Path]::GetFileName($this._generatedFromFile)){gray}]"
			}

			if($this.CloneId){
				$content += "{white}Clone Id [{magenta}$($this.CloneId){white}]"
			}
		}
		return $content
		
	}

	########################################################################
	# Cloning
	########################################################################
	[object] CloneUnderNewScope([UIInputScopeBase] $newScope){
		return $this.CloneUnderNewScope($newScope, $null)
	}
	[object] CloneUnderNewScope([UIInputScopeBase] $newScope,  [Object] $type){
		$this.Context().PushScope($newScope)
		$id = Get-Random
		$newItem = $this.Clone($id, $type)
		$newItem.CurrentScope($newScope)
		$this.Context().PopScope($newScope)
		return $newItem
	}
	
	[object] Clone(){
		$id = Get-Random
		return $this.Clone($id, $null)
	}
	[object] Clone([string] $cloneId){
		return $this.Clone($cloneId, $null)
	}
	[object] Clone([string] $cloneId, [Object] $type){
		return $this.Clone($cloneId, $type, $null)
	}
	
	[void] RefreshSessionIfNeeded(){
		if($this.IsNewSession()){
			if(-not $this.RefreshSession()){
				$this.Error("Failed to refresh the session")
			}
		}
	}
	[bool] IsNewSession(){
		if($this._sessionId -ne $this.Context().SessionId()){
			return $true
		}
		return $false
	}
	[bool] RefreshSession(){
		$this._sessionId = $this.Context().SessionId()
		
		return $true
	}
	[bool] InitialProps([hashtable] $props, [string] $body, [System.Xml.XmlElement] $element, [string] $location){
		$this._properties = $props
		$this._bodyContent = $body
		$this.AddXmlDefinition($element, $location)
		
		# Deal with 'Ref' Attribute
		if($props.ContainsKey("Ref") -and ($props.ContainsKey("Name"))){
			$ref = $props["Ref"]
			if(-not ($this.Context().AddRef($ref, $this, $false))){
				$this.Error("Unable to add ref {white}$ref{gray}")
				return $false
			}
			
			if($props.ContainsKey("Name")){
				 $element.RemoveAttribute("Name")
			}
		}
		
		return $true
	}
	[bool] UpdateProps([hashtable] $props, [string] $body, [System.Xml.XmlElement] $element, [string] $location){
		$props.GetEnumerator() | % {
			#TEMP $this.Action("Props","Adding Property {white}$($_.Name){gray} with value {white}$($_.Value){gray}")
			$this._properties[$_.Name] = $_.Value
		}
		$this._bodyContent = $body
		$this.AddXmlDefinition($element, $location)
		
		# Deal with 'Ref' Attribute
		if($props.ContainsKey("Ref") -and ($props.ContainsKey("Name"))){
			$ref = $props["Ref"]
			if(-not ($this.Context().AddRef($ref, $this, $false))){
				$this.Error("Unable to add ref {white}$ref{gray}")
				return $false
			}
			
			if($props.ContainsKey("Name")){
				 $element.RemoveAttribute("Name")
			}
			
		}
		
		
		return $true
	}
	[object] Clone([string] $cloneId, [Object] $type, [UIInputScopeBase] $newScope){
		
		# Handle Type if user needs to specify
		if(-not $type){
			$type = $this.GetType()
		}

		# If we have already cloned this item...
		if($this.CloneId -eq $cloneId){
			return $this
		}
		
		# If we are currently cloning this item... Return that currently cloning item
		if($this._cloning){
			return $this._cloning 
		}

		
		$properties = [Helper]::GetAllProperties($this, @("_currentScope", "_parentScope", "rootScope", "_savedCurrentScope", "savedRootScope", "_cloning", "_overrideScope"))
		
		$this.Context().Action("Cloning", "$([HasContext]::Prefix)*** Cloning type '{white}$($this.GetType()){gray}' as '{white}$($type){gray}' - [{magenta}$($properties.Count){white} Properties to Clone{gray}]")

		# If This is a Scope Type - Posh/Pop Scopes
		if($this -is [UIInputScopeBase]){
			
			$this.Context().Action("Cloning", "$([HasContext]::Prefix)*** Clone has been configured for scope traversal")

			$newThis = new-object $type -ArgumentList $this.Context()
			$newThis.CurrentScope($newThis)
			$newThis.ParentScope($this.Context().CurrentScope())
			$this.Context().PushScope($newThis)

			$this.Context().Action("Cloning", "$([HasContext]::Prefix)*** Done configuring clone")
		}
		else{
			$newThis = new-object $type -ArgumentList $this.Context()
		}
		
		# Is used above incase there are nested references
		$this._cloning = $newThis
		
		
		foreach($property in $properties){
			
			$propertyName = $property.Name
			$currentValue = $this.$propertyName
			
			$this.Context().Action("Cloning", "$([HasContext]::Prefix)*** Looking at property {magenta}$($propertyName){gray} of type {white}$($property.PropertyType){gray} with base {white}$($property.PropertyType.BaseType){white}")

			if($propertyName -eq "_context"){
				$newThis._context = $this.Context()
				continue
			}

			###############################################################
			# Found Parameter Value, Perform Cloning Activity
			###############################################################
			if($currentValue){
				
				###########################################################
				# Handle - [Array]
				###########################################################
				if($currentValue -is [System.Array] -or $currentValue -is [System.Collections.ArrayList]){
					
					$newValue = new-object $currentValue.GetType() 
					
					
					$hasContextTypes = $currentValue | Where {$_ -is [HasContext]}
					$index = 0

					[HasContext]::Prefix += " "
					foreach($_ in $hasContextTypes){
						$this.Context().Action("Cloning", "$([HasContext]::Prefix)*** Array[$($index)]")
						[HasContext]::Prefix += " "
						$thisNewValue = $_.Clone($cloneId)
						$newValue += $thisNewValue
						[HasContext]::Prefix = [HasContext]::Prefix.Substring(1)
						$index += 1
					}
					[HasContext]::Prefix = [HasContext]::Prefix.Substring(1)
				}

				###########################################################
				# Handle - [HasContext]
				###########################################################
				elseif($currentValue -is [HasContext]){
					[HasContext]::Prefix += " "
					$newValue = $currentValue.Clone($cloneId)
					[HasContext]::Prefix = [HasContext]::Prefix.Substring(1)
					
				}

				###########################################################
				# Handle - [Any]
				###########################################################
				else{
					$newValue = $currentValue
				}
			}
			else{
				$newValue = $null
			}

			if($newValue){
				[Helper]::SetProperty($newThis, $newValue.GetType().Name, $propertyName, $newValue)
			}
			[Helper]::SetProperty($newThis, "String"                , "CloneId"    , $cloneId)
        } 

		if($this -is [UIInputScopeBase]){
			$this.Context().PopScope()
		}
		return $newThis
	}
	[void] LoadChildren(){
		
		Enter-Block "LoadChildren"
		if($this.Context().ExitRequested()){
			$this.Warning("User Exiting...")
			Exit-Block "LoadChildren"
			return
		}
		$this.RefreshSessionIfNeeded()
		$this.Context().PushLocation($this._generatedFromFile)

		if($this._xmlDefinitions.Count -gt 0){

			# $this.Display("Loading Children [{white}$($this._xmlDefinitions.Count){gray} xmls to load]")
			$this.PushIndent()
			foreach($xmlDefinition in $this._xmlDefinitions){
				# this.Display("Loading XML`r`n$($xmlDefinition.Xml.Outerxml | Format-Xml)`r`n")
				$this.Context().PushLocation($xmlDefinition.Location)
				$this.Context().PopulateFromXml($xmlDefinition.Xml, $this)
				$this.Context().PopLocation()
			}
			# $this.Display("{darkgreen}[{green}Done{darkgreen}]{gray}")
			$this._xmlDefinitions.Clear()
			$this.PopIndent()
		}
		
		
		
		if(-not [Object]::ReferenceEquals($this, $this.CurrentScope())){
			$this.CurrentScope().LoadChildren()
		}
		elseif($this.CurrentScope().ParentScope()){
			$this.CurrentScope().ParentScope().LoadChildren()
		}
		
		if($this._xmlDefinitions.Count -gt 0){

			# $this.Display("Loading Children [{white}$($this._xmlDefinitions.Count){gray} xmls to load]")
			$this.PushIndent()
			foreach($xmlDefinition in $this._xmlDefinitions){
				# this.Display("Loading XML`r`n$($xmlDefinition.Xml.Outerxml | Format-Xml)`r`n")
				$this.Context().PushLocation($xmlDefinition.Location)
				$this.Context().PopulateFromXml($xmlDefinition.Xml, $this)
				$this.Context().PopLocation()
			}
			# $this.Display("{darkgreen}[{green}Done{darkgreen}]{gray}")
			$this._xmlDefinitions.Clear()
			$this.PopIndent()
		}
		
		$this.Context().PopLocation()
		Exit-Block "LoadChildren"
		
	}
	static [HasContext] FromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [HasCollectionContext] $collection, [Type] $type){
		
		Enter-Block "HasContext.FromXML"
		$requirementsMethod = $type | Get-Member -Type Method -Static | Where {$_.Name -eq "Requirements"}
		if(-not $requirementsMethod){
			$context.Error("Type '{white}$($type.Name){gray}' does not have the static function 'Requirements' defined")
			Exit-Block "HasContext.FromXML"
			return $null
		}
		
		$requirementsCommand = "[$($type.Name)]::Requirements()"
		$requirements = Invoke-Expression $requirementsCommand
		if(-not $requirements){
			$context.Error("Type '{white}$($type.Name){gray}' Requirements Method returned with null when we were expecting the requirements for the type")
			Exit-Block "HasContext.FromXML"
			return $null
		}
		if(-not $requirements.PrimaryKey){
			$context.Error("Type '{white}$($type.Name){gray}' Requirements Method returned no '{white}PrimaryKey{gray}' which is essential for uniqueness")
			Exit-Block "HasContext.FromXML"
			return $null
		}
		if(-not $requirements.ElementNames){
			$context.Error("Type '{white}$($type.Name){gray}' Requirements Method returned no '{white}ElementNames{gray}' which is essential for identity")
			Exit-Block "HasContext.FromXML"
			return $null
		}
		if(-not ($requirements.ElementNames | Where {$_ -eq $element.LocalName})){
			$context.Error("Type '{white}$($type.Name){gray}' Element Name '{white}$($element.LocalName){gray}' does not match expected name '{white}$($requirements.ElementNames){gray}'")
			Exit-Block "HasContext.FromXML"
			return $null
		}
		
		$properties = new-object hashtable
		foreach($attr in $element.Attributes ){
			$properties.Add($attr.Name, $attr.Value)
		}
		$bodyContent = ""
		if($element."#text"){
			$bodyContent = $element."#text"
		}
		
		$item = $null
		
		if(-not $properties.ContainsKey($requirements.PrimaryKey)){
			
			if($properties.ContainsKey("Ref")){
				$ref = $properties["Ref"]
				$item = $context.Ref($ref, $type, $true)
				if(-not $item){
					$context.Error("Type '{white}$($type.Name){gray}' Required attribute not found ({white}$($requirements.PrimaryKey){gray}) - Tried to use the ref {white}$($ref){gray} but was not resolved correctly")
					Exit-Block "HasContext.FromXML"
					return $null
				}
				
				# Update Props
				if(-not $item.UpdateProps($properties, $null, $element, $context.CurrentLocation())){
					$context.Error("Type '{white}$($type.Name){gray}' Updating Properties failed")
					Exit-Block "HasContext.FromXML"
					return $null
				}
				
				# Moving Loading of Children on demand
				if($context.FullParsing()){
					$context.PopulateFromXml($element, $item)
				}
				
				# Adding to list
				if(-not ($collection.Add($item, $properties))){
					$context.Error("Type '{white}$($type.Name){gray}' Adding to list failed")
					Exit-Block "HasContext.FromXML"
					return $null
				}

				Exit-Block "HasContext.FromXML"
				return $item
			}
			else{
				$context.Error("Type '{white}$($type.Name){gray}' Required attribute not found ({white}$($requirements.PrimaryKey){gray}) - Used for uniqueness")
				Exit-Block "HasContext.FromXML"
				return $null
			}
		}
		
		# Get/Create Item
		if(-not $item){
			$item      = $collection._items[$properties[$requirements.PrimaryKey].ToLower()] # Get($($properties[$requirements.PrimaryKey]), $false)
		}
		
		# Add it
		if(-not $item){
			$item = new-object $type -ArgumentList ($context, $collection.CurrentScope(), $($properties[$requirements.PrimaryKey]))
			
			# Incoming Initial Props
			if(-not $item.InitialProps($properties, $bodyContent, $element, $context.CurrentLocation())){
				$context.Error("Type '{white}$($type.Name){gray}' Updating Properties failed")
				Exit-Block "HasContext.FromXML"
				return $null
			}
			
			# Moving Loading of Children on demand
			if($context.FullParsing()){
				$context.PopulateFromXml($element, $item)
			}
			
			# Adding to list
			if(-not ($collection.Add($item, $properties))){
				$context.Error("Type '{white}$($type.Name){gray}' Adding to list failed")
				Exit-Block "HasContext.FromXML"
				return $null
			}
			Exit-Block "HasContext.FromXML"
			return $item
		}
		
		# Update Props
		if(-not $item.UpdateProps($properties, $bodyContent, $element, $context.CurrentLocation())){
			$context.Error("Type '{white}$($type.Name){gray}' Updating Properties failed")
			Exit-Block "HasContext.FromXML"
			return $null
		}
		
		# Update Children
		# Moving Loading of Children on demand
		if($context.FullParsing()){
			$context.PopulateFromXml($element, $item)
		}

		Exit-Block "HasContext.FromXML"
		return $item
    }
	
	
   
	
}

class HasConsumableContext: HasContext{
	
	HasConsumableContext([ConfigAutomationContext] $_context):base($_context){
    }
	HasConsumableContext([ConfigAutomationContext] $_context, [UIInputScopeBase] $scope, [String] $name):base($_context, $scope, $name){
    }
    HasConsumableContext([ConfigAutomationContext] $_context, [UIInputScopeBase] $scope, [String] $name, [string] $referenceName):base($_context, $scope, $name){
    }
	
	[void] PopulateFromXML([System.Xml.XmlElement] $XmlElement){
		$this.Context().PopulateFromXml($this, $XmlElement)
	}
}
class HasCollectionContext: HasConsumableContext{
	
	[string] $_referenceName
	[bool] $_hierarchical = $true
	[bool] $_overridesEnabled = $false
	
    HasCollectionContext([ConfigAutomationContext] $_context):base($_context){
		$this._items = new-object hashtable
		$this._shallowItems = new-object hashtable
		
    }
	HasCollectionContext([ConfigAutomationContext] $_context, [UIInputScopeBase] $scope, [String] $name):base($_context, $scope, $name){
		$this._items = new-object hashtable
		$this._shallowItems = new-object hashtable
		$this._referenceName = $name
    }
    HasCollectionContext([ConfigAutomationContext] $_context, [UIInputScopeBase] $scope, [String] $name, [string] $referenceName):base($_context, $scope, $name){
		$this._items = new-object hashtable
		$this._shallowItems = new-object hashtable
		$this._referenceName = $name
    }
	[bool] Hierarchical(){
		return $this._hierarchical
	}
	[void] Hierarchical([bool] $hierarchical){
		$this._hierarchical = $hierarchical
	}
	[bool] OverridesEnabled(){
		return $this._overridesEnabled
	}
	[void] OverridesEnabled([bool] $overridesEnabled){
		$this._overridesEnabled = $overridesEnabled
	}
	[hashtable] $_items
	[hashtable] $_shallowItems

	[string] ReferenceName(){
		return $this._referenceName
	}
	[bool] Clean(){
		$allClean = $true
		foreach($item in $this.Items()){
			$allClean = $item.Clean() -and $allClean
		}
		
		return $allClean
	}
	[bool] RefreshSession(){
		if(-not (([HasContext]$this).RefreshSession())){
			return $false
		}
		$isValid = $true
		foreach($item in $this.Items()){
			$isValid = $item.RefreshSession() -and $isValid
		}

		$this._shallowItems = new-object hashtable
		return $isValid
	}
    [System.Collections.ArrayList] Items(){
		if($this.Context().ExitRequested()){
			return (new-object System.Collections.ArrayList)
		}
		
		$array = new-object System.Collections.ArrayList
		
        $this._items.GetEnumerator() | % {$_.Value} | Sort-Object -Property @{Expression = {$_.Order()}} | Foreach{ $_.ActiveFromCollection($this); $array.Add($_) }  
		return $array
    }
	[void] Remove([string] $name){
		if($this._items.ContainsKey($name)){
			$this._items.Remove($name)
		}
	}
    [HasContext] Get([string]$name){
		# TODO, Move to a parameter based system instead of this weird argument index which is getting out of hand
        return $this.Get($name, $true, $false, $false, $false, $false, $false)
    }
	[HasContext] Get([string]$name, [bool] $IncludeParent){
		return $this.Get($name, $IncludeParent, $false, $false, $false)
	}
	[HasContext] Get([string]$name, [bool] $IncludeParent , [bool] $isOverride){
		return $this.Get($name, $IncludeParent, $isOverride, $false)
    }
	[HasContext] Get([string]$name, [bool] $IncludeParent , [bool] $isOverride, [bool] $ignoreOverride){
		return $this.Get($name, $IncludeParent, $isOverride, $ignoreOverride, $false)
    }
	[HasContext] Get([string]$name, [bool] $IncludeParent , [bool] $isOverride, [bool] $ignoreOverride, [bool] $ignoreCurrentScopeCheck){
		return $this.Get($name, $IncludeParent, $isOverride, $ignoreOverride, $ignoreCurrentScopeCheck, $false)
    }
	[HasContext] Get([string]$name, [bool] $IncludeParent , [bool] $isOverride, [bool] $ignoreOverride, [bool] $ignoreCurrentScopeCheck, [bool] $includeInvalidItems){
		return $this.Get($name, $IncludeParent, $isOverride, $ignoreOverride, $ignoreCurrentScopeCheck, $includeInvalidItems, $false)
    }
	[HasContext] Get([string]$name, [bool] $IncludeParent , [bool] $isOverride, [bool] $ignoreOverride, [bool] $ignoreCurrentScopeCheck, [bool] $includeInvalidItems, [bool] $includeHiddenItems){
		return $this.InnerGet($name, $IncludeParent, $isOverride, $ignoreOverride, $ignoreCurrentScopeCheck, $includeInvalidItems, $includeHiddenItems)
    }
	[bool] $_lock = $false
	
	[HasContext] InnerGet([string]$name, [bool] $IncludeParent , [bool] $isOverride, [bool] $ignoreOverride, [bool] $ignoreCurrentScopeCheck, [bool] $includeInvalidItems, [bool] $includeHiddenItems){
		$action = {
			$this.RefreshSessionIfNeeded()
			
			if(-not $this.Hierarchical()){
				$foundItem = $this._items[$name.ToLower()]
				if($foundItem){
					$foundItem.RefreshSessionIfNeeded()
				}
				return $foundItem
			}
			
			
			$foundItem = $null
			
			
			$currentScope = $this.CurrentScope()
			$parentScope  = $currentScope.ParentScope()
			
			if($this.OverridesEnabled())
			{
				if($isOverride -and -not $currentScope.IsOverride() ){
					#TEMP $this.Action("{white}Returning null{gray} since we are trying to fetch 'override' $($this.Name()) from a scope that is not an override - $($this.GetScopeString())")
					return $null
				}
			
				if((-not $ignoreOverride) -and ($this.Context().OverrideScope()) -and (-not $currentScope.IsOverride())){
					#TEMP $this.Action("{white}Fetching from override scope $($this.Context().OverrideScope().GetScopeString())")
					$foundItem = $this.Context().OverrideScope().Get($this.ReferenceName()).Get($name, $IncludeParent, $true, $false, $true, $includeInvalidItems, $includeHiddenItems)
					
					if(-not $foundItem){
						#TEMP $this.Action("{red}Not found{gray} in {magenta}override{gray} list")
					}
					else{
						#TEMP $this.Action("{green}    found{gray} in {magenta}override{gray} list")
					}
				}
			}
			
			if(-not $foundItem){
				$foundItem = $this._shallowItems[$name.ToLower()]

				# Remove Invalid Items
				if($foundItem -and ($foundItem.IsInvalid()) -and -not $includeInvalidItems){
					$foundItem = $null
				}
				
				# Remove Hidden Items
				if($foundItem -and ($foundItem.IsHidden()) -and -not $includeHiddenItems){
					$foundItem = $null
				}
			}

			if(-not $foundItem) {
				$foundItem = $this._items[$name.ToLower()]
				
				# Remove Invalid Items
				if($foundItem -and ($foundItem.IsInvalid()) -and -not $includeInvalidItems){
					$foundItem = $null
				}
				
				# Remove Hidden Items
				if($foundItem -and ($foundItem.IsHidden()) -and -not $includeHiddenItems){
					$foundItem = $null
				}
				
				if(-not $foundItem){
					#TEMP $this.Action("{red}Not found{gray} in {magenta}local{gray} list")
				}
				else{
					#TEMP $this.Action("{green}    found{gray} in {magenta}local{gray} list")
				}
			}
			
			# If we are not in the 
			if(-not $foundItem -and -not $ignoreCurrentScopeCheck -and -not [Object]::ReferenceEquals($currentScope.Get($this.ReferenceName()), $this)){
				#TEMP $this.Action("{gray}starting search{gray} in {magenta}current scope{gray} list")
				$foundItem = $currentScope.Get($this.ReferenceName()).Get($name, $IncludeParent, $isOverride, $true, $true)
				if(-not $foundItem){
					#TEMP $this.Action("{red}Not found{gray} in {magenta}current scope{gray} list")
				}
				else{
					#TEMP $this.Action("{green}    found{gray} in {magenta}current scope{gray} list")
				}
			}
			
			if(-not $foundItem -and $IncludeParent -and $parentScope ){
				#TEMP $this.Action("{gray}starting search{gray} in {magenta}parent{gray} list")
				$foundItem = $parentScope.Get($this.ReferenceName()).Get($name, $IncludeParent, $isOverride, $true, $true)
				if(-not $foundItem){
					#TEMP $this.Action("{red}Not found{gray} in {magenta}parent{gray} list")
				}
				else{
					#TEMP $this.Action("{green}    found{gray} in {magenta}parent{gray} list")
				}
			}
			elseif(-not $foundItem -and -not $IncludeParent){
				#TEMP $this.Action("{gray}canceled search{gray} in {magenta}parent{gray} list - Due to User Input")
			}
			elseif(-not $foundItem -and -not $parentScope){
				#TEMP $this.Action("{gray}canceled search{gray} in {magenta}parent{gray} list - Due to No Parent Scopes")
			}
			else{
				#TEMP $this.Action("{gray}canceled search{gray} in {magenta}parent{gray} list - {red}Unknown Reason{gray}")
			}
			
			# if(-not $foundItem -and $IncludeParent -and (-not $isOverride)){
				# $foundItem = $this.Add($name, "String")
			# }
		
			
				
			if($this.OverridesEnabled())
			{
				if($foundItem -and $isOverride){
					$foundItem.IsOverride($isOverride)
				}
			}

			if($foundItem){
				$foundItem.RefreshSessionIfNeeded()
			}
			
			if($foundItem){
				$this._shallowItems[$name.ToLower()] = $foundItem
			}

			return $foundItem
		}
		if($this._lock){
			return $null;
		}
		
		$this._lock = $true
		$this.Action("{white}Getting $($this.Name()){gray} '{magenta}$($name){gray}', {white}IncludeParent:{gray} $($IncludeParent), {white}isOverride:{gray} $($isOverride) ")
		$this.PushIndent()
		try{
			$result = .$action
		}
		catch{
			$this.Error("Getting $($this.Name()) '$($name)' failed with exception {white}$($_.Exception.Message){gray}`r`n$($_.Exception.StackTrace)`r`n{magenta}::::{gray}`r`n$($_.ScriptStackTrace)")
		}
		
		$this.PopIndent()
		if($result){
			$result.Action("{green} Found")
		}
		
		$this._lock = $false
		return $result
	}
    
	[HasContext] Add([string] $name) {
		$type = $this.GetType()
		
        $requirementsMethod = $type | Get-Member -Type Method -Static | Where {$_.Name -eq "Requirements"}
		if(-not $requirementsMethod){
			$this.Error("Type '{white}$($type.Name){gray}' does not have the static function 'Requirements' defined")
			return $null
		}
		
		$requirementsCommand = "[$($type.Name)]::Requirements()"
		$requirements = Invoke-Expression $requirementsCommand
		if(-not $requirements){
			$this.Error("Type '{white}$($type.Name){gray}' Requirements Method returned with null when we were expecting the requirements for the type")
			return $null
		}
		
		$item = new-object $type -ArgumentList ($this.Context(), $this.CurrentScope(), $name.ToLower())
		if(-not ($this.Add($item))){
			$this.Error("Unable to add item by name '{white}$($name){gray}'")
			return $null
		}
		
		return $item
	}
	[bool] Add([HasContext]$item) {
		return $this.Add($item, (new-object hashtable))
	}
	[bool] Add([HasContext]$item, [hashtable] $properties) {
		
		#ERRCK
		if(-not $item){
			$this.Error("Logic error, Trying to add a null value, not excepted");
			return $false
		}
		
		#DISP
		if((-not ($item -is [HasCollectionContext])) -or ($item -is [UIInputScopeBase])){
			 # $item.Display("Adding new item {magenta}$($item.Name()){gray}")
		}
		
		# Some Trackers
		$extraLogs    = ""
		$itemAdding   = $item
		$itemKey      = $null
		
		# T y p e s   ( C o l l e c t i o n )
		if($item -is [HasCollectionContext]){
			$extraLogs = "(Classified as {white}HasCollectionContext{gray})"
			$itemKey   = $item.ReferenceName()
		}
		
		# T y p e s   ( G e n e r a l )
		elseif($item -is [HasContext]){
			$extraLogs = "(Classified as {white}HasContext{gray})"
			$itemKey   = $item.Name()
		}
		
		# T y p e s   ( U k n o w n )
		else{
			$this.Error("Unable to add item of type '{white}$($item.GetType()){gray}' due to it not being a supported type")
			return $false
		}
		
		# Check Item Key
		if((-not $itemKey)){
			$this.Error("Unable to add item of type '{white}$($item.GetType()){gray}' due to it having null for the wanted '{white}itemKey{gray}'")
			return $false
		}
		
		$itemKey = $itemKey.ToLower()
		if(-not ($this._items.ContainsKey($itemKey)) -or ($this._items[$itemKey].Id() -ne $itemAdding.Id())){
			$this._items[$itemKey] = $itemAdding
			$itemAdding.Order($this._items.Count)
			if(-not ($itemAdding.FromCollections($this, $properties))){
				$this.Error("Unable to add item '{white}$($item.FullName()){gray}' due to it failing to be added to this list")
				return $false
			}
		}
		
		return $true
		
		
	}
    
	[String] ToString(){
		if($this.Items().Count -eq 0){
			return ""
		}
		return "$($this.Name()) `r`n  $($this.Items() | Where {$_} | Foreach {"  "+$_.ToString().Replace("`r`n","`r`n  ")+"`r`n  "})"
	}
	
	
	[void] PopulateFromXML([System.Xml.XmlElement] $xml) {
		
		
		
		#TEMP $this.Action("XMLParsing", "Evaluating '$($xml.LocalName)'")
		$this.PushIndent("XMLParsing")
		$context = $this.Context()
		$type = $this.GetType()
		
        $requirementsMethod = $type | Get-Member -Type Method -Static | Where {$_.Name -eq "Requirements"}
		if(-not $requirementsMethod){
			$context.Error("Type '{white}$($type.Name){gray}' does not have the static function 'Requirements' defined")
			$this.PopIndent("XMLParsing")
			return
		}
		
		$requirementsCommand = "[$($type.Name)]::Requirements()"
		$requirements = Invoke-Expression $requirementsCommand
		if(-not $requirements){
			$context.Error("Type '{white}$($type.Name){gray}' Requirements Method returned with null when we were expecting the requirements for the type")
			$this.PopIndent("XMLParsing")
			return
		}
		
		if(-not $requirements.ChildType){
			$context.Error("Type '{white}$($type.Name){gray}' Requirements Method returned no '{white}ChildType{gray}' which is essential for identity")
			$this.PopIndent("XMLParsing")
			return 
		}
		if(-not ($requirements.ChildType -is [Type])){
			$context.Error("Type '{white}$($type.Name){gray}' Requirements Method returned '{white}ChildType{gray}' as type '{white}$($requirements.ChildType.GetType()){gray} when expecting type '{white}Type{gray}'")
			$this.PopIndent("XMLParsing")
			return
		}
		if(-not $requirements.ParentElementNames){
			$context.Error("Type '{white}$($type.Name){gray}' Requirements Method returned no '{white}ParentElementNames{gray}' which is essential for identity")
			$this.PopIndent("XMLParsing")
			return
		}
		if(-not $requirements.ChildElementNames){
			$context.Error("Type '{white}$($type.Name){gray}' Requirements Method returned no '{white}ChildElementNames{gray}' which is essential for identity")
			$this.PopIndent("XMLParsing")
			return
		}
		if($xml -is [System.Xml.XmlComment]){
			$this.PopIndent("XMLParsing")
			return
		}
		if($xml -is [System.Xml.XmlText]){
			$this.PopIndent("XMLParsing")
			return
		}
		
		
		
		
		$parentSelector = $requirements.ParentElementNames -join "|"
		$parents = $xml.SelectNodes($parentSelector)
		foreach($xmlChild in $parents){
			# Gather Element Properties
			$properties = new-object hashtable
			foreach($attr in $xmlChild.Attributes ){
				$properties.Add($attr.Name, $attr.Value)
			}
			
			# Update Props
			if(-not $this.UpdateProps($properties, $null, $xmlChild, $this.Context().CurrentLocation())){
				$context.Error("Type '{white}$($type.Name){gray}' Updating Properties failed")
				# $this.PopIndent("XMLParsing")
				continue
			}
			
			#TEMP $this.Action("XMLParsing", "Found Parent XML '$($xmlChild.LocalName)' going through all {white}$($xmlChild.ChildNodes.Count){gray} children")
			$xmlChild = $this.Context().GetRootScope().Extensions().ApplyExtension($xmlChild)
			$this.PopulateFromXML($xmlChild)
			#TEMP $this.Action("XMLParsing", "{magenta}    matched{gray} '$($xmlChild.LocalName)'")
			# $this.PopIndent("XMLParsing")
			$xmlChild.ParentNode.RemoveChild($xmlChild)
			continue 
		}
		
		
		
		$childSelectors = $requirements.ChildElementNames -join "|"
		$children = $xml.SelectNodes($childSelectors)
		foreach($xmlChild in $children){
			$item = [HasContext]::FromXML($this.Context(), $xmlChild, $this, $($requirements.ChildType))
			if(-not $item){
				#TEMP $this.Action("XMLParsing", "{magenta}    Failed to match correctly{gray} '$($xmlChild.LocalName)'")
				#$this.PopIndent("XMLParsing")
				continue
			}
			
			
			#TEMP $this.Action("XMLParsing", "{magenta}    matched{gray} '$($xmlChild.LocalName)'")
			#$this.PopIndent("XMLParsing")
			$xmlChild.ParentNode.RemoveChild($xmlChild)
			continue
		}
		
		
		#TEMP $this.Action("XMLParsing", "{magenta}Not matched{gray} '$($xml.LocalName)'")
		$this.PopIndent("XMLParsing")
		return
		
		
    }
	
	
}
class UIInputScopeBase : HasCollectionContext{
	hidden [UIImportTemplateCollection]                  $_importTemplates
	hidden [UIActionCollection]                          $_actions
	hidden [UIPreActionCollection]                       $_preActions
	hidden [UIPostActionCollection]                      $_postActions
	hidden [UIActionTypeDefinitionCollection]            $_actionTypes
	
	hidden [UIParameterCollection]                       $_parameters
	hidden [UIParameterTypeDefinitionCollection]         $_parameterTypes
	hidden [UILoggingTypeDefinitionCollection]           $_loggingTypes
	hidden [UILoggerCollection]                          $_loggers
	
    # hidden [UIInputCollection]                           $_inputs
    hidden [UIInputScopecollection]                      $_inputScopes
	hidden [UIResourceTypeCollection]                    $_resourceTypes
	hidden [UIResourceCollection]                        $_resources
	hidden [UIInputScopeBase]                            $_parentScope
	hidden [UIConfigMasterExtensionTypeCollection]       $_configMasterExtensionTypes
	hidden [UIConfigMasterExtensionCollection]           $_configMasterExtensions
    hidden [UIReleaseDefinitionCollection]               $_releaseDefinitions
	hidden [UIInputTypeDefinitionCollection]             $_inputTypes
	
	
	hidden [UIActionTemplateCollection]                  $_actionTemplates
	hidden [UIActionOverrideCollection]                  $_actionOverrides
	hidden [UISectionCollection]                         $_sections
	hidden [UITemplateCollection]                        $_templates
	hidden [UIActionPluginCollection]                    $_actionPlugin
	
	
    UIInputScopeBase([ConfigAutomationContext] $context):base($context){
		Write-Color "{red}Error, {gray}Empty Constructor {white}{gray}of type {white}$($this.GetType().Name){red} came in with null scope{gray}"
		
		$this._parameterTypes             = [UIParameterTypeDefinitionCollection]::new($this.Context())
		$this._loggingTypes               = [UILoggingTypeDefinitionCollection]::new($this.Context())
		$this._loggers                    = [UILoggerCollection]::new($this.Context())
        # $this._inputs                     = [UIInputCollection]::new($this.Context())
        $this._inputScopes                = [UIInputScopecollection]::new($this.Context())
		$this._parameters                 = [UIParameterCollection]::new($this.Context())
		$this._resourceTypes              = [UIResourceTypeCollection]::new($this.Context())
		$this._resources                  = [UIResourceCollection]::new($this.Context())
		$this._configMasterExtensionTypes = [UIConfigMasterExtensionTypeCollection]::new($this.Context())
		$this._configMasterExtensions     = [UIConfigMasterExtensionCollection]::new($this.Context())
        $this._releaseDefinitions         = [UIReleaseDefinitionCollection]::new($this.Context())
		$this._inputTypes                 = [UIInputTypeDefinitionCollection]::new($this.Context())
		$this._actionTypes                = [UIActionTypeDefinitionCollection]::new($this.Context())
		$this._actions                    = [UIActionCollection]::new($this.Context())
		$this._actionTemplates            = [UIActionTemplateCollection]::new($this.Context())
		$this._preActions                 = [UIPreActionCollection]::new($this.Context())
		$this._postActions                = [UIPostActionCollection]::new($this.Context())
		$this._actionOverrides            = [UIActionOverrideCollection]::new($this.Context())
		$this._sections          		  = [UISectionCollection]::new($this.Context())
		$this._templates          		  = [UITemplateCollection]::new($this.Context())
		$this._importTemplates     		  = [UIImportTemplateCollection]::new($this.Context())
		$this._actionPlugin  			  = [UIActionPluginCollection]::new($this.Context())
		
		$wasAbleToAdd = $true
		$wasAbleToAdd =  $this.Add($this._importTemplates) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._parameterTypes) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._loggingTypes) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._loggers) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._inputScopes) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._parameters) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._resourceTypes) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._resources) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._configMasterExtensionTypes) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._configMasterExtensions) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._releaseDefinitions) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._inputTypes) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._actionTypes) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._actions) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._actionTemplates) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._preActions) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._postActions) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._actionOverrides) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._sections) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._templates) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._actionPlugin) -and $wasAbleToAdd
		
		if(-not $wasAbleToAdd){
			$this.Error("Unable to add some of the items")
		}
		
	}
    UIInputScopeBase([ConfigAutomationContext] $context, [UIInputScopeBase] $parentScope, [String] $name, [string] $referenceName):base($context, $this, $name, $referenceName){
		if(-not $parentScope -and $name -ne "ROOT_AUTOMATION"){
			Write-Color "{red}Error, {white}$($name){red} of type {white}$($this.GetType().Name){red} came in with null scope{gray}"
		}
		$this._parentScope = $parentScope

		$this._parameterTypes             = [UIParameterTypeDefinitionCollection]::new($this.Context(), $this)
		$this._loggingTypes               = [UILoggingTypeDefinitionCollection]::new($this.Context(), $this)
		$this._loggers                    = [UILoggerCollection]::new($this.Context(), $this)
        # $this._inputs                     = [UIInputCollection]::new($this.Context(), $this)
        $this._inputScopes                = [UIInputScopecollection]::new($this.Context(), $this)
		$this._parameters                 = [UIParameterCollection]::new($this.Context(), $this)
		$this._resourceTypes              = [UIResourceTypeCollection]::new($this.Context(), $this)
		$this._resources                  = [UIResourceCollection]::new($this.Context(), $this)
		$this._configMasterExtensionTypes = [UIConfigMasterExtensionTypeCollection]::new($this.Context(), $this)
		$this._configMasterExtensions     = [UIConfigMasterExtensionCollection]::new($this.Context(), $this)
        $this._releaseDefinitions         = [UIReleaseDefinitionCollection]::new($this.Context(), $this)
		$this._inputTypes                 = [UIInputTypeDefinitionCollection]::new($this.Context(), $this)
		$this._actionTypes                = [UIActionTypeDefinitionCollection]::new($this.Context(), $this)
		$this._actions                    = [UIActionCollection]::new($this.Context(), $this)
		$this._actionTemplates            = [UIActionTemplateCollection]::new($this.Context(), $this)
		$this._preActions                 = [UIPreActionCollection]::new($this.Context(), $this)
		$this._postActions                = [UIPostActionCollection]::new($this.Context(), $this)
		$this._actionOverrides            = [UIActionOverrideCollection]::new($this.Context(), $this)
		$this._sections                   = [UISectionCollection]::new($this.Context(), $this)
		$this._templates                  = [UITemplateCollection]::new($this.Context(), $this)
		$this._importTemplates            = [UIImportTemplateCollection]::new($this.Context(), $this)
		$this._actionPlugin  			  = [UIActionPluginCollection]::new($this.Context(), $this)
		
		$wasAbleToAdd = $true
		$wasAbleToAdd =  $this.Add($this._importTemplates) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._parameterTypes) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._loggingTypes) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._loggers) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._inputScopes) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._parameters) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._resourceTypes) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._resources) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._configMasterExtensionTypes) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._configMasterExtensions) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._releaseDefinitions) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._inputTypes) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._actionTypes) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._actions) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._actionTemplates) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._preActions) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._postActions) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._actionOverrides) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._sections) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._templates) -and $wasAbleToAdd
		$wasAbleToAdd =  $this.Add($this._actionPlugin) -and $wasAbleToAdd
		
		if(-not $wasAbleToAdd){
			$this.Error("Unable to add some of the items")
		}
		
	}
	[void] Milestone([string] $message, [string] $type){
		$this.Loggers().Milestone($message, $type)
    }
	[void] Log([string] $message){
		$this.Loggers().Log($message)
    }
    [void] Indent([int] $amount){
		$this.Loggers().Indent($amount)
    }
	[UIInputScopeBase] CurrentScope(){
        return $this._currentScope
    }
	[void] CurrentScope([UIInputScopeBase] $scope){
		$this._currentScope = $scope
	}
	[object] CloneUnderNewScope([UIInputScopeBase] $newScope){
		$newItem = $this.Clone()
		$newItem.CurrentScope($newScope)
		$newItem._parentScope = $newScope
		return $newItem
	}
	[String] FullName(){
		return $this.FullName(".")
	}
	[String] FullName([string] $joinText){
		$allParentScopes = @($this.GetAllParents($true) | ForEach {$_.Name()}) | Where {$_ -ne "ROOT_AUTOMATION"}
		$actualScope    = $allParentScopes -join $joinText

		if([String]::IsNullOrEmpty($actualScope)){
			return "[root]"
		}
		return $actualScope
	}
	[System.Collections.ArrayList] GetAllParents([bool] $includingSelf){
		$parents =[System.Collections.ArrayList]::new()
		
		$parent = $this.ParentScope()
		if(-not $parent){
			if($includingSelf){
				$parents.Add($this)
			}
			return $parents
		}
		
		$parents.AddRange($parent.GetAllParents($true))
		
		if($includingSelf){
			$parents.Add($this)
		}
		
        return $parents
    }
	[bool] IsAMatch([string] $match){
		$allParentScopes = @($this.GetAllParents($true) | ForEach {$_.Name()}) | Where {$_ -ne "ROOT_AUTOMATION"}
		$actualScope    = $allParentScopes -join "."
		
		$chosen = $true
		if(-not ($actualScope -match $match)){
			Write-Host "[$($actualScope)] was not Found in match"
			$chosen = $false;
		} 
		if(-not $chosen){
			foreach($scope in $this.Scopes().Items($false)){
				if($scope.IsAMatch($match)){
					$chosen = $true
				}
			}	
		}
		
		return $chosen
	}
	[bool] IsChosen(){
		$allParentScopes = @($this.GetAllParents($true) | ForEach {$_.Name()}) | Where {$_ -ne "ROOT_AUTOMATION"}
		$includedScopes = $this.Context().GetIncludedScopes()
		$excludedScopes = $this.Context().GetExcludedScopes()
		$actualScope    = $allParentScopes -join "."
		
		$chosen = $true
		if(-not $($includedScopes | Where { $actualScope -match "$($_)"})){
			Write-Host "[$($actualScope)] was not Found in included scope"
			$chosen = $false;
		} 
		if($($excludedScopes | Where {$_} | Where {$_.StartsWith($actualScope)})){
			Write-Host "[$($actualScope)] was Found in excluded scope"
			$chosen = $false;
		}
		
		
		if(-not $chosen){
			foreach($scope in $this.Scopes().Items($false)){
				if($scope.IsChosen()){
					$chosen = $true
				}
			}	
		}
		
		return $chosen
	}
	
	[UIAction[]] FindActions($match){
		$actions = $this.GetAllRecursiveActions()
		return $actions | Where {$_.Name() -match $match}
    }
	[UIAction[]] GetAllRecursiveActions(){
		$scopes = @()
		
		if($this.GetType() -eq [UIAction]){
			$scopes += $this
		}
		$moreScopes = $this.CurrentScope().Scopes()
		foreach($scope in $moreScopes.Items()){
			$innerScopes = $scope.GetAllRecursiveActions()
			foreach($innerScope in $innerScopes){
				$scopes += $innerScope
			}
		}
		$actions = $this.CurrentScope().Actions()
		foreach($scope in $actions.Items()){
			$innerScopes = $scope.GetAllRecursiveActions()
			foreach($innerScope in $innerScopes){
				$scopes += $innerScope
			}
		}
		
        return $scopes
    }
	[UIInputScopeBase[]] GetAllRecursiveChildren(){
		$scopes = @()
		
		$finalInputs+=$input
		
		$scopes += $this
		$myScopes = $this.Scopes()
		foreach($scope in $myScopes.Items()){
			$innerScopes = $scope.GetAllRecursiveChildren()
			foreach($innerScope in $innerScopes){
				$scopes += $innerScope
			}
		}
		
		
        return $scopes
    }
	[string] ParentScopeName(){
		if($this._parentScope){
			return $this.ParentScope().Name()
		}
		return "";
    }
	[string] ParentScopeFullName(){
		if($this._parentScope){
			return $this.ParentScope().FullName()
		}
		return "";
    }
	[string] ParentScopeFullName([String] $prefix){
		if($this._parentScope){
			return $this.ParentScope().FullName($prefix)
		}
		return "";
    }
	[UIInputScopeBase] ParentScope(){
		$parentScopeName = ""
		if($this._parentScope){
			$parentScopeName = $this._parentScope.Name()
		}
		# $this.Context().Action("Scopes", "Getting Parent Scope '$($parentScopeName)' from scope '$($this.Name())'")
        return $this._parentScope
    }
	[void] ParentScope([UIInputScopeBase] $parentScope){
		$newParentScopeName = ""
		if($parentScope){
			$newParentScopeName = $parentScope.Name()
		}
		$oldParentScopeName = ""
		if($oldParentScopeName){
			$oldParentScopeName = $oldParentScopeName.Name()
		}
		$this.Display("Scopes", "`r`n`r`n{white}Setting Parent Scope{gray} to {magenta}$($newParentScopeName){gray} from scope {white}'$($oldParentScopeName){gray}'`r`n`r`n")
        $this._parentScope = $parentScope
    }
	
    [UIInputScopeCollection] Scopes(){
        return $this._inputScopes
    }
	[UIParameterTypeDefinitionCollection] ParameterTypes(){
        return $this._parameterTypes
    }
    # [UIInputCollection] Inputs(){
    #     return $this._inputs
	# }
	[UILoggingTypeDefinitionCollection] LoggingTypes(){
        return $this._loggingTypes
    }
	[UIConfigMasterExtensionTypeCollection] ExtensionTypes(){
        return $this._configMasterExtensionTypes
    }
	[UIConfigMasterExtensionCollection] Extensions(){
        return $this._configMasterExtensions
    }
	[UIResourceTypeCollection] ResourceTypes(){
        return $this._resourceTypes
    }
	[UIParameterCollection] Parameters(){
        return $this._parameters
    }
    [UIInputScopecollection] InputScopes(){
        return $this._inputScopes
    }
	[UIInputTypeDefinitionCollection] InputTypes(){
        return $this._inputTypes
    }
	[UIActionTypeDefinitionCollection] ActionTypes(){
        return $this._actionTypes
    }
	[UIActionCollection] Actions(){
        return $this._actions
	}
	[UILoggerCollection] Loggers(){
        return $this._loggers
    }
	[UIPreActionCollection] PreActions(){
        return $this._preActions
    }
	[UIPostActionCollection] PostActions(){
        return $this._postActions
    }
	[UIActionOverrideCollection] ActionOverrides(){
        return $this._actionOverrides
    }
    static [UIInputScopeBase] FromXML([ConfigAutomationContext] $context, [UIInputScopeBase] $_parentScope, [System.Xml.XmlElement] $element){
        
        if(-not ($element.GetAttribute("Name") )) {
            throw "Not all the attributes to build the input scope element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n $($element.OuterXml)"
        }

        if(-not $context) {
            throw "Context is null which is being passed to UI Parameter inside of UI UIInputScopeBase.FromXML"
        }
		if($element.GetAttribute("Exclude") -eq "True"){
			return $null
		}
		
		
		$scopeName = $element.GetAttribute("Name")
		if($_parentScope.Scopes().Get($scopeName)){
			return $null
		}
        $scope = [UIInputScopeBase]::new($context, $_parentScope, $element.GetAttribute("Name"))
        
        return $scope

    }
	
	
	
    
}



class UIInputScope : UIInputScopeBase{
	UIInputScope([ConfigAutomationContext] $context):base($context){
	}
	UIInputScope([ConfigAutomationContext] $context, [UIInputScopeBase] $_parentScope, [String] $name):base($context, $_parentScope, $name, "Scopes"){

    }
    UIInputScope([ConfigAutomationContext] $context, [UIInputScopeBase] $_parentScope, [String] $name, [string] $referenceName):base($context, $_parentScope, $name, $referenceName){

    }
    static [UIInputScopeBase] FromXML([ConfigAutomationContext] $context, [UIInputScope] $_parentScope, [System.Xml.XmlElement] $element){
        
        if(-not ($element.GetAttribute("Name") )) {
            throw "Not all the attributes to build the input scope element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n $($element.OuterXml)"
        }

        if(-not $context) {
            throw "Context is null which is being passed to UI Parameter inside of UI UIInputScope.FromXML"
        }
		if($element.GetAttribute("Exclude") -eq "True"){
			return $null
		}
		
		$scopeName = $element.GetAttribute("Name")
		
		
		
        $scope = [UIInputScope]::new($context, $_parentScope, $element.GetAttribute("Name"))
        
        return $scope

    }
    [void] PopulateFromXML([System.Xml.XmlElement] $xml) {
        $this.Context().PopulateFromXml($xml, $this)
    }
}
class UITypeDefinition: HasContext {

    hidden [String]                $_contentType
	hidden [String] 			   $_content
	hidden [String]                $_typeLabel
	hidden [object]                $_typeDefinition
	
	UITypeDefinition([ConfigAutomationContext] $_context) : base($_context){
    }
    UITypeDefinition([ConfigAutomationContext] $_context, [String] $name, [string] $contentType, [String] $content, [string] $typeLabel, [UIInputScopeBase] $scope) : base($_context,$scope, $name){
        $this._content 	      = $content
		$this._contentType    = $contentType
		$this._typeLabel      = $typeLabel
		$this._typeDefinition = $null
    }
	[bool] RefreshSession(){
		if(-not ([HasContext]$this).RefreshSession()){
			return $false
		}
		$this._typeDefinition = $null
		return $true
	}
	[string] TypeLabel(){
		return $this._typeLabel
	}
	[string] LogGroup(){
		return $this._typeLabel -replace " ",""
	}
	[string] ContentType(){
		return $this._contentType
	}
	[string] Content(){
		return $this.ParameterizeString($this._content)
	}
	[bool] InitialProps([hashtable] $props, [string] $bodyContent, [System.Xml.XmlElement] $element, [string] $location){
		#TEMP $this.Action("Initial Props")
		if(-not ([HasContext]$this).InitialProps($props, $bodyContent,$element, $location)){
			return $false
		}
		if($props.ContainsKey("ScriptPath") -and $props.ContainsKey("ScriptContent")){
			$this.Error("Not allowed to have both '{white}ScriptContent{gray}' and '{white}ScriptPath{gray}' as properties")
			return $false
		}
		elseif($props.ContainsKey("ScriptPath")){
			$this._contentType = "ScriptFile"
			$this._content = $props["ScriptPath"]
			$this._typeDefinition = $null
		}
		elseif($props.ContainsKey("ScriptContent")){
			$this._contentType = "ScriptContent"
			$this._content = $props["ScriptContent"]
			$this._typeDefinition = $null
		}
		
		return $true
		 
	}
	[bool] UpdateProps([hashtable] $props, [string] $bodyContent, [System.Xml.XmlElement] $element, [string] $location){
		if(-not ([HasContext]$this).UpdateProps($props, $bodyContent, $element, $location)){
			return $false
		}
		if($props.ContainsKey("ScriptPath") -and $props.ContainsKey("ScriptContent")){
			$this.Error("Not allowed to have both '{white}ScriptContent{gray}' and '{white}ScriptPath{gray}' as properties")
			return $false
		}
		elseif($props.ContainsKey("ScriptPath")){
			$this._contentType = "ScriptFile"
			$this._content = $props["Scriptpath"]
			$this._typeDefinition = $null
		}
		elseif($props.ContainsKey("ScriptContent")){
			$this._contentType = "ScriptContent"
			$this._content = $props["ScriptContent"]
			$this._typeDefinition = $null
		}
		return $true
	}

	[object] TypeDefinition(){
		if($this._typeDefinition){
			return $this._typeDefinition
		}
		if(-not ($this.ValidateValue($this.ContentType(), "$($this.TypeLabel()) {gray}[{magenta}$($this.Name()){gray}]{white} (Content Type)") -and $this.ValidateValue($this.Content(),"Action Type {gray}[{magenta}$($this.Name()){gray}]{white} (Content)"))){
			return $null
		}
		if($this._contentType -eq "ScriptContent"){
			$_script = New-TemporaryFile
			ren $_script "$($_script).ps1"
			$_script = "$($_script).ps1"
			$this.Content() | Set-Content $_script
			$typeDefinition = .$_script
			del $_script

			$this._typeDefinition = $typeDefinition
			return $typeDefinition
		}
		
		if($this._contentType -eq "ScriptFile"){
			$_script = $this.Content()
			if(-not (Test-Path $_script)){
				$this.Error($this.LogGroup(),"$($this.TypeLabel()) {white}$($this.Name()){gray} source file {white}$($_script){gray} was not found")
				return $null
			}
			$content = Get-Content $_script
			$_script = New-TemporaryFile
			ren $_script "$($_script).ps1"
			$_script = "$($_script).ps1"
			$content | Set-Content $_script
			$typeDefinition = .$_script
			del $_script

			$this._typeDefinition = $typeDefinition
			return $typeDefinition
		}

		throw "Content Type was found to be '$($this._contentType)' which is not supported"
	}
	[bool] TypeDefinitionProperty([string] $name, [Type] $typeExpected, [ref]$callbackRef){
		$typeDefinition = $this.TypeDefinition()
		if(-not $typeDefinition){
			$this.Error($this.LogGroup(),"$($this.TypeLabel()) {white}$($this.Name()){gray} required a valid type definition but {white}null was found{gray} during the executing of its content")
			return $false
		}

		$typeDefinitionProperty = $typeDefinition.$name
		if(-not $typeDefinitionProperty){
			$this.Error($this.LogGroup(),"$($this.TypeLabel()) {white}$($this.Name()){gray}, property {white}$($name){gray} was required but {white}null was found{gray} during the executing of its content")
			return $false
		}

		$type = $typeDefinitionProperty.GetType()
		if($type -ne $typeExpected){
			$this.Error($this.LogGroup(),"$($this.TypeLabel()) {white}$($this.Name()){gray}, property {white}$($name){gray} was required to be of type {white}$($typeExpected){gray} but {white}$($type){gray} was found during the executing of its content")
			return $false
		}

		$callbackRef.Value = $typeDefinitionProperty
		return $true
	}
	[object] InvokeCallback([String] $callbackName, [object[]] $argumentList){
		return $this.InvokeCallback($callbackName, $argumentList, $true)
	}
	[object] InvokeCallback([String] $callbackName, [object[]] $argumentList, [bool] $expectContent){
		$context = $this.Context() 
        if(-not $context){
            throw "Context is null when calling UIActionTypeDefinition"
        }

        $scriptBlock = $null
		if(-not $this.TypeDefinitionProperty($callbackName, [ScriptBlock], ([ref]$scriptBlock))){
			return $false
		}
		
		# Write-Color "$($this.TypeLabel()) {white}$($this.Name()){gray}, Arguments $($argumentList.Count)"
		$newScriptBlock = '.$scriptBlock '
		for($i = 0 ; $i -lt $argumentList.Count; $i += 1){
			# Write-Color "   $($this.TypeLabel()) {white}$($this.Name()){gray}, Argument[$($i)] = $($argumentList[$i].GetType())"
			$newScriptBlock += '$argumentList['+$i+'] '
		}
		
		try{
			if($expectContent){
				$return = Invoke-Expression $newScriptBlock # Invoke-Command $scriptBlock -ArgumentList $argumentList -NoNewScope
				return $return
			}
			
			Invoke-Expression $newScriptBlock
			return $null
		}
		catch{
			if(-not $Global:FinalError){
				$Global:FinalError = @()
			}
			$Global:FinalError += $_
			$this.Error($this.LogGroup(),"$($this.TypeLabel()) {white}$($this.Name()){gray}, Failed with error {red}$($_.Exception.Message){gray}`r`n{white}Stack Trace{gray}`r`n$($_.Exception.StackTrace)`r`n{white}Script Trace{gray}`r`n$($_.ScriptStackTrace)`r`n{white}Exported to{gray}`r`nReal Error has been exported to {white}FinalErrors{gray}")
			
			Write-Color "$($this.TypeLabel()) {white}$($this.Name()){gray}, Arguments $($argumentList.Count)"
			$newScriptBlock = '.$scriptBlock '
			for($i = 0 ; $i -lt $argumentList.Count; $i += 1){
				Write-Color "   $($this.TypeLabel()) {white}$($this.Name()){gray}, Argument[$($i)] = $($argumentList[$i].GetType())"
				if($argumentList[$i] -is [HasContext]){
					Write-Color "      Item Name {magenta}$($argumentList[$i].Name()){gray}"
				}
				# $newScriptBlock += '$argumentList['+$i+'] '
			}
			
		}
		
		return $null
	}
    static [UITypeDefinition] FromXML([ConfigAutomationContext] $_context, [System.Xml.XmlElement] $element, [Type] $typeCreating, [UIInputScopeBase] $scope ){
        if(-not ($element.GetAttribute("Name") )){
            throw "Not all the attributes to build the parameter type element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n )"
        }
		$name = $element.GetAttribute("Name")
		if($element.GetAttribute("SourceFile") ){
			$script = $element.GetAttribute("SourceFile")
			
			$actionType = New-Object ($typeCreating.Name) -ArgumentList $_context, $name, "ScriptFile", $script, $scope
			$_context.PopulateFromXml($element, $actionType)

			return $actionType
        }

		if($element.ChildNodes | Where {$_.LocalName -eq "ScriptBlock"}){
			
			$scriptBlock = $element.ChildNodes | Where {$_.LocalName -eq "ScriptBlock"}
			if($scriptBlock.'#text'){
				
				$scriptContent = $scriptBlock.'#text'
				$actionType = New-Object ($typeCreating.Name) -ArgumentList $_context, $name,"ScriptContent", $scriptContent , $scope
				$_context.PopulateFromXml($element, $actionType)
	
				return $actionType
			}
		}
	
		if($element.'#text'){
			$scriptContent = $element.'#text'
			$actionType = New-Object ($typeCreating.Name) -ArgumentList $_context, $name,"ScriptContent", $scriptContent , $scope
			$_context.PopulateFromXml($element, $actionType)

			return $actionType
		}
		if($element.InnerText){
			$scriptContent = $element.InnerText
			$actionType = New-Object ($typeCreating.Name) -ArgumentList $_context, $name,"ScriptContent", $scriptContent , $scope
			$_context.PopulateFromXml($element, $actionType)

			return $actionType
		}
		throw "Expected ScriptBlock but was not found on Type Definition"
		
		
		
	}
}
class HasReleaseDefinitionContext: HasContext{
    [UIReleaseDefinition] $_definition
    hidden [object] $_rawContent
    HasReleaseDefinitionContext([ConfigAutomationContext] $_context, [UIReleaseDefinition] $definition, [string] $name):base($_context, $definition.CurrentScope(), $name){
        $this._definition = $definition
    }
	[UIReleaseDefinition] ReleaseDefinition(){
        return $this._definition
    }
    [void] SetRawContent([object] $content){
        $this._rawContent = $content
    }

}
class HasConsumableReleaseDefinitionContext: HasConsumableContext{

	[UIReleaseDefinition] $_definition
    hidden [object] $_rawContent
    HasConsumableReleaseDefinitionContext([ConfigAutomationContext] $_context, [UIReleaseDefinition] $definition, [string] $name):base($_context, $definition.CurrentScope(), $name){
        $this._definition = $definition
    }
	[UIReleaseDefinition] ReleaseDefinition(){
        return $this._definition
    }
    [void] SetRawContent([object] $content){
        $this._rawContent = $content
    }
	
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#  - - - - - - - - - - - - - - Release Definition - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIReleaseDefinitionCollection : HasCollectionContext{
    [System.Collections.ArrayList] $_releaseDefinitions
	UIReleaseDefinitionCollection([ConfigAutomationContext] $context):base($context, "Release Definition"){
        $this._releaseDefinitions = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionCollection([ConfigAutomationContext] $context,[UIInputScopeBase] $_parentScope):base($context, $_parentScope, "Release Definition"){
        $this._releaseDefinitions = New-Object System.Collections.ArrayList
    }
	[System.Collections.ArrayList] Items(){
		return $this._releaseDefinitions
	}
    [UIReleaseDefinition] Get([string]$name){
        return $this.Get($name, $true)
    }
    [UIReleaseDefinition] Get([string]$name, [bool] $IncludeParent ){
        $this.Context().Warning("Release Def Collection - Getting Parameter Key '$($name)' ")
        foreach($release in $this._releaseDefinitions){
            if($release.ReleaseName() -eq $name){
				$this.Context().Warning("** Release Collection - Found It!!")
                return $release
            }
        }
		
		if($IncludeParent -and $this.CurrentScope().ParentScope()){
			return $this.CurrentScope().ParentScope().ReleaseDefinitions().Get($name)
		}
        return $null
    }
    [UIReleaseDefinition] Add([string]$name){
        $release = $this.Get($name, $false)
        if($release -eq $null){

            if(-not $this.Context()){
                throw "Context is null which is being passed to UI Release Def inside of UI UIReleaseDefinitionCollection.Add"
            }
			
            $release = [UIReleaseDefinition]::new($this.Context(), $this.CurrentScope(), $name)
            $this._releaseDefinitions.Add($release)
			$this.Context().Log("Adding Release $($release.ReleaseName())") 
        }

        return $release
    }
    
    [void] PopulateFromXML([System.Xml.XmlElement] $xml) {
		
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "ReleaseDefinitions") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "ReleaseDefinition") {
						$this.Context().Warning("Input Collection - Found Inputs in Xml ")
                        
                        [UIReleaseDefinition]::PopulateFromXML($this.Context(), $step, $this)
                    }
                }
            }
        }
    }
}
class UIReleaseDefinition : HasContext{
    
    hidden [UIReleaseDefinitionEnvironmentCollection] $_environments
    hidden [UIReleaseDefinitionVariableCollection] $_variables
    hidden [UIReleaseDefinitionVariableGroupReferenceCollection] $_variableGroups
    hidden [UIReleaseDefinitionArtifactCollection] $_artifacts
    hidden [UIReleaseDefinitionTriggerCollection] $_triggers

    hidden [object] $_rawContent
	UIReleaseDefinition([ConfigAutomationContext] $context):base($context){
        $this._environments = [UIReleaseDefinitionEnvironmentCollection]::new($context, $this)
        $this._variables = [UIReleaseDefinitionVariableCollection]::new($context, $this)
        $this._variableGroups = [UIReleaseDefinitionVariableGroupReferenceCollection]::new($context, $this)
        $this._artifacts = [UIReleaseDefinitionArtifactCollection]::new($context, $this)
        $this._triggers = [UIReleaseDefinitionTriggerCollection]::new($context, $this)
    }
    UIReleaseDefinition([ConfigAutomationContext] $context,[UIInputScopeBase] $_parentScope, [string] $_name):base($context, $_parentScope, $_name){
        
        $this._environments = [UIReleaseDefinitionEnvironmentCollection]::new($context, $this)
        $this._variables = [UIReleaseDefinitionVariableCollection]::new($context, $this)
        $this._variableGroups = [UIReleaseDefinitionVariableGroupReferenceCollection]::new($context, $this)
        $this._artifacts = [UIReleaseDefinitionArtifactCollection]::new($context, $this)
        $this._triggers = [UIReleaseDefinitionTriggerCollection]::new($context, $this)
    }
    [void] CreateRelease(){
        
                
    }
    [string] ReleaseName(){
        return $this._name
    }
    [void] FromID([string] $releaseID){
        $this._rawContent = $this.Context().VSTSService().GetRelease($releaseID)
    }
    [object] RawContent(){
        return $this._rawContent
    }
    static [void] PopulateFromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIReleaseDefinitionCollection] $releases){
        if(-not ($element.GetAttribute("Name") )){
            throw "Not all the attributes to build the parameter element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n  )"
        }

        if(-not $context){
            throw "Context is null which is being passed to UI Parameter inside of UI Parameter.FromXML"
        }

        $release = $releases.Get($element.Name)
        if(-not $release){
            $release = $releases.Add($element.Name)
        }
        if($element.GetAttribute("BasedOnRelease")){
            $release.FromID($element.GetAttribute("BasedOnRelease"))
        }
        $context.PopulateFromXml($element, $release)

        
    }
    [String] ToString(){
		return "Release $($this.ReleaseName())`r`n$($this._environments | Where {$_} | Foreach {"  "+$_.ToString().Replace("`r`n","`r`n  ")+"`r`n"})"
	}

}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - Release Definition Change - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIReleaseDefinitionVariableGroupReferenceCollection : HasConsumableReleaseDefinitionContext{
    [System.Collections.ArrayList] $_releaseDefinitionVariableGroupReferences
	UIReleaseDefinitionVariableGroupReferenceCollection([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionVariableGroupReferences = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionVariableGroupReferenceCollection([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        $this._releaseDefinitionVariableGroupReferences = New-Object System.Collections.ArrayList
    }
    [UIReleaseDefinitionVariableGroupReference] Get([string]$id, [bool] $IncludeParent ){
        $this.Context().Warning("Variable Group Collection - Getting Parameter Key '$($id)' ")
        foreach($entitie in $this._releaseDefinitionVariableGroupReferences){
            if($entitie.ReleaseName() -eq $id){
				$this.Context().Warning("** Release Collection - Found It!!")
                return $entitie
            }
        }
		
		if($IncludeParent -and $this.CurrentScope().ParentScope()){
			return $this.CurrentScope().ParentScope().VariableGroups().Get($id)
		}
        return $null
    }
    [UIReleaseDefinitionVariableGroupReference] Add([string]$id){
        $entitie = $this.Get($id, $false)
        if($entitie -eq $null){

            if(-not $this.Context()){
                throw "Context is null which is being passed to UI Variable Group inside of UI UIReleaseDefinitionVariableGroupReferenceCollection.Add"
            }
			
            $entitie = [UIReleaseDefinitionVariableGroupReference]::new($this.Context(), $this.ReleaseDefinition(), $id)
            $this._releaseDefinitionVariableGroupReferences.Add($entitie)
			$this.Context().Log("Adding Release $($entitie.VariableGroupName())") 
        }

        return $entitie
    }
    [void] PopulateFromXML([System.Xml.XmlElement] $xml) {
		
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "VariableGroups") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "VariableGroup") {
						$this.Context().Warning("Input Collection - Found Inputs in Xml ")
                        
                        [UIReleaseDefinitionVariableGroupReference]::PopulateFromXML($this.Context(), $step, $this)
                    }
                }
            }
        }
    }
}
class UIReleaseDefinitionVariableGroupReference : HasReleaseDefinitionContext{
    hidden [int] $_variableGroup
    UIReleaseDefinitionVariableGroupReference([ConfigAutomationContext] $context):base($context){
    }
    UIReleaseDefinitionVariableGroupReference([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope, [int] $_variableGroup):base($context, $_parentScope){
        $this._variableGroup = $_variableGroup
    }
    [int] VariableGroupName(){
        return $this._variableGroup
    }
    static [void] PopulateFromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIReleaseDefinitionVariableGroupReferenceCollection] $variables){
        if(-not ($element.GetAttribute("GroupId") )){
            throw "Not all the attributes to build the parameter element were found:`r`n  Name:$($element.GetAttribute("GroupId"))`r`n  )"
        }

        if(-not $context){
            throw "Context is null which is being passed to UI Parameter inside of UI Parameter.FromXML"
        }

        $variable = $variables.Get($element.GroupId)
        if(-not $variable){
            $variable = $variables.Add($element.GroupId)
        }
        $context.PopulateFromXml($element, $variable)

        
    }
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - Release Definition Change - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIReleaseDefinitionVariableCollection : HasConsumableReleaseDefinitionContext{
    [System.Collections.ArrayList] $_releaseDefinitionVariables
	UIReleaseDefinitionVariableCollection([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionVariables = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionVariableCollection([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        $this._releaseDefinitionVariables = New-Object System.Collections.ArrayList
    }

    [UIReleaseDefinitionVariable] Get([string]$id ){
        $this.Context().Warning("Variable Collection - Getting Parameter Key '$($id)' ")
        foreach($entitie in $this._releaseDefinitionVariables){
            if($entitie.VariableName() -eq $id){
				$this.Context().Warning("** Variable Collection - Found It!!")
                return $entitie
            }
        }
        return $null
    }
    [UIReleaseDefinitionVariable] Add([string]$id){
        $entitie = $this.Get($id)
        if($entitie -eq $null){

            if(-not $this.Context()){
                throw "Context is null which is being passed to UI Variable Group inside of UI UIReleaseDefinitionVariableGroupReferenceCollection.Add"
            }
			
            $entitie = [UIReleaseDefinitionVariable]::new($this.Context(), $this.ReleaseDefinition(), $id, $null)
            $this._releaseDefinitionVariables.Add($entitie)
			$this.Context().Log("Adding Variable $($entitie.VariableName())") 
        }

        return $entitie
    }
    [void] PopulateFromXML([System.Xml.XmlElement] $xml) {
		
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "Variables" -or $roots.LocalName -eq "Inputs") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "Variable") {
						$this.Context().Warning("Input Collection - Found Inputs in Xml ")
                        
                        [UIReleaseDefinitionVariable]::PopulateFromXML($this.Context(), $step, $this)
                    }
                }
            }
        }
    }
    [String] ToString(){
		$content = "Variables`r`n"
		$content += $this._releaseDefinitionVariables | Where {$_} | Foreach {"  "+$_.ToString().Replace("`r`n","`r`n  ")+"`r`n"}
        return $content
	}

}
class UIReleaseDefinitionVariable : HasReleaseDefinitionContext{
    
    hidden [string] $_value
    UIReleaseDefinitionVariable([ConfigAutomationContext] $context):base($context){
    }
    UIReleaseDefinitionVariable([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope, [string] $_name, [string] $_value):base($context, $_parentScope, $_name){
        
        $this._value = $_value
    }
    [string] VariableName(){
        return $this._name
    }
    [void] SetVariableValue([string] $value){
        $this._value = $value
    }
    static [void] PopulateFromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIReleaseDefinitionVariableCollection] $variables){
        if(-not ($element.GetAttribute("Name") -or -not ($element.GetAttribute("Value")  ))){
            throw "Not all the attributes to build the parameter element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n  Name:$($element.GetAttribute("Value"))`r`n )"
        }

        if(-not $context){
            throw "Context is null which is being passed to UI Variable inside of UI Variable.FromXML"
        }

        $variable = $variables.Get($element.Name)
        if(-not $variable){
            $variable = $variables.Add($element.Name)
        }
        $variable.SetVariableValue($element.Value)
        $context.PopulateFromXml($element, $variable)

        
    }
    
    [String] ToString(){
		$content = "$($this.VariableName()) = $($this._value)`r`n"
        return $content
	}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - Environment - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIReleaseDefinitionEnvironmentCollection : HasConsumableReleaseDefinitionContext{
    [System.Collections.ArrayList] $_releaseDefinitionEnvironment
	UIReleaseDefinitionEnvironmentCollection([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionEnvironment = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionEnvironmentCollection([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        $this._releaseDefinitionEnvironment = New-Object System.Collections.ArrayList
    }
    [UIReleaseDefinitionEnvironment] Get([string]$id ){
        $this.Context().Warning("Environment Collection - Getting Parameter Key '$($id)' ")
        foreach($entitie in $this._releaseDefinitionEnvironment){
            if($entitie.Name() -eq $id){
				$this.Context().Warning("** Environment Collection - Found It!!")
                return $entitie
            }
        }
        return $null
    }
    [UIReleaseDefinitionEnvironment] Add([string]$id){
        $entitie = $this.Get($id)
        if($entitie -eq $null){

            if(-not $this.Context()){
                throw "Context is null which is being passed to UI Variable Group inside of UI UIReleaseDefinitionEnvironmentCollection.Add"
            }
			
            $entitie = [UIReleaseDefinitionEnvironment]::new($this.Context(), $this.ReleaseDefinition(), $id)
            $this._releaseDefinitionEnvironment.Add($entitie)
			$this.Context().Log("Adding Environment $($entitie.Name())") 
        }

        return $entitie
    }
    
    [void] PopulateFromXML([System.Xml.XmlElement] $xml) {
		
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "Environments" -or $roots.LocalName -eq "Stages") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "Environment" -or $step.LocalName -eq "Stage") {
					    $this.Context().Warning("Input Collection - Found Inputs in Xml ")
                        
                        [UIReleaseDefinitionEnvironment]::PopulateFromXML($this.Context(), $step, $this)
                    }
                }
            }
        }
    }
}
class UIReleaseDefinitionEnvironment : HasReleaseDefinitionContext{
    
    hidden [UIReleaseDefinitionDeploymentPhaseCollection] $_phases
    hidden [UIReleaseDefinitionEnvironmentConditionCollection] $_conditions
    hidden [UIReleaseDefinitionVariableCollection] $_variables
    hidden [UIReleaseDefinitionVariableGroupReferenceCollection] $_variableGroups

	UIReleaseDefinitionEnvironment([ConfigAutomationContext] $context):base($context){
       
    }
    UIReleaseDefinitionEnvironment([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope, [string] $_name):base($context, $_parentScope, $_name){
        
        $this._phases = [UIReleaseDefinitionDeploymentPhaseCollection]::new($context, $_parentScope)
        $this._variables = [UIReleaseDefinitionVariableCollection]::new($context, $_parentScope)
        $this._variableGroups = [UIReleaseDefinitionVariableGroupReferenceCollection]::new($context, $_parentScope)
        $this._conditions = [UIReleaseDefinitionEnvironmentConditionCollection]::new($context, $_parentScope)
    }
    static [void] PopulateFromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIReleaseDefinitionEnvironmentCollection] $environments){
        if(-not ($element.GetAttribute("Name"))){
            throw "Not all the attributes to build the parameter element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n   )"
        }

        if(-not $context){
            throw "Context is null which is being passed to UI Variable inside of UI Variable.FromXML"
        }

        $environment = $environments.Get($element.Name)
        if(-not $environment){
            $environment = $environments.Add($element.Name)
        }

        $foundEnvironment = $environment.ReleaseDefinition().RawContent().environments | Where {$_.name -eq $element.Name}
        if(-not $foundEnvironment) 
        {
            
            $maxRank =  ($environment.ReleaseDefinition().RawContent().environments | Foreach {$_.rank} | Sort -Descending)[0]
            if(-not $maxRank) {
			    throw "Unable to get the max rank"
		    }
            $foundEnvironment = @{}
            $foundEnvironment.rank = $maxRank

            if($element.BasedOnEnvironmentWithRank)
            {
                $templateEnvironment = $environment.ReleaseDefinition().RawContent().environments | Where {$_.rank -eq $element.BasedOnEnvironmentWithRank}
                $foundEnvironment.conditions = $templateEnvironment.conditions
		        $foundEnvironment.preDeployApprovals = $templateEnvironment.preDeployApprovals
		        $foundEnvironment.postDeployApprovals = $templateEnvironment.postDeployApprovals
                $foundEnvironment.owner = $templateEnvironment.owner
                $foundEnvironment.retentionPolicy = $templateEnvironment.retentionPolicy
		        $foundEnvironment.variableGroups = $templateEnvironment.variableGroups
		        $foundEnvironment.variables = $templateEnvironment.variables
            }
        }
        $environment.SetRawContent($foundEnvironment)
        

        $context.PopulateFromXml($element, $environment)

        

        
    }
    [String] ToString(){
		$content = "Environment $($this.Name())`r`n"
		
		$content += $this._phases | Foreach {"  "+$_.ToString().Replace("`r`n","`r`n  ")+"`r`n"}
		$content += $this._conditions | Foreach {"  "+$_.ToString().Replace("`r`n","`r`n  ")+"`r`n"}
		$content += $this._variables | Foreach {"  "+$_.ToString().Replace("`r`n","`r`n  ")+"`r`n"}
		$content += $this._variableGroups | Foreach {"  "+$_.ToString().Replace("`r`n","`r`n  ")+"`r`n"}
        return $content
	}
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - Environment - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIReleaseDefinitionDeploymentPhaseCollection : HasConsumableReleaseDefinitionContext{
    [System.Collections.ArrayList] $_releaseDefinitionDeploymentPhases

	UIReleaseDefinitionDeploymentPhaseCollection([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionDeploymentPhases = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionDeploymentPhaseCollection([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        $this._releaseDefinitionDeploymentPhases = New-Object System.Collections.ArrayList
    }

    [UIReleaseDefinitionDeploymentPhase] Get([string]$id ){
        $this.Context().Warning("Environment Phase Collection - Getting Parameter Key '$($id)' ")
        foreach($entitie in $this._releaseDefinitionEnvironment){
            if($entitie.Name() -eq $id){
				$this.Context().Warning("** Environment Phase Collection - Found It!!")
                return $entitie
            }
        }
        return $null
    }
    [UIReleaseDefinitionDeploymentPhase] Add([string]$id){
        $entitie = $this.Get($id)
        if($entitie -eq $null){

            if(-not $this.Context()){
                throw "Context is null which is being passed to UI Variable Group inside of UI UIReleaseDefinitionDeploymentPhaseCollection.Add"
            }
			
            $entitie = [UIReleaseDefinitionDeploymentPhase]::new($this.Context(), $this.ReleaseDefinition(), $id)
            $this._releaseDefinitionDeploymentPhases.Add($entitie)
			$this.Context().Log("Adding Environment Phase $($entitie.Name())") 
        }

        return $entitie
    }

    [void] PopulateFromXML([System.Xml.XmlElement] $xml) {
		
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "Phases") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "Phase") {
					    $this.Context().Warning("Environment Phase Collection - Found Inputs in Xml ")
                        
                        [UIReleaseDefinitionDeploymentPhase]::PopulateFromXML($this.Context(), $step, $this)
                    }
                }
            }
        }
    }
    [String] ToString(){
		$content = ""
		$content += $this._releaseDefinitionDeploymentPhases | Foreach {"  "+$_.ToString().Replace("`r`n","`r`n  ")+"`r`n"}
        return $content
	}
}
class UIReleaseDefinitionDeploymentPhase : HasReleaseDefinitionContext{
    
    hidden [UIReleaseDefinitionTaskCollection] $_releaseDefinitionTasks
    hidden [UIReleaseDefinitionDeploymentPhaseInput] $_releaseDefinitionDeploymentPhaseInput
	UIReleaseDefinitionDeploymentPhase([ConfigAutomationContext] $context):base($context){
    }
    UIReleaseDefinitionDeploymentPhase([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope, [string] $_name):base($context, $_parentScope, $_name){
        
        $this._releaseDefinitionTasks = [UIReleaseDefinitionTaskCollection]::new($context, $_parentScope)
        $this._releaseDefinitionDeploymentPhaseInput = [UIReleaseDefinitionDeploymentPhaseInput]::new($context, $_parentScope)
    }
    static [void] PopulateFromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIReleaseDefinitionDeploymentPhaseCollection] $environmentPhases){
        if(-not ($element.GetAttribute("Name"))){
            throw "Not all the attributes to build the parameter element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n   )"
        }

        if(-not $context){
            throw "Context is null which is being passed to UI Variable inside of UI Variable.FromXML"
        }

        $environmentPhase = $environmentPhases.Get($element.Name)
        if(-not $environmentPhase){
            $environmentPhase = $environmentPhases.Add($element.Name)
        }

        

        $context.PopulateFromXml($element, $environmentPhase)

        
    }
    [String] ToString(){
		$content = "Phase $($this.Name())`r`n"
		$content += $this._releaseDefinitionDeploymentPhaseInput | Foreach {"  "+$_.ToString().Replace("`r`n","`r`n  ")+"`r`n"}
        $content += $this._releaseDefinitionTasks | Foreach {"  "+$_.ToString().Replace("`r`n","`r`n  ")+"`r`n"}
        return $content
	}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - Environment - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIReleaseDefinitionTaskCollection : HasConsumableReleaseDefinitionContext{
    [System.Collections.ArrayList] $_releaseDefinitionTasks
	UIReleaseDefinitionTaskCollection([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionTasks = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionTaskCollection([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        $this._releaseDefinitionTasks = New-Object System.Collections.ArrayList
    }
    [UIReleaseDefinitionTask] Get([string]$id ){
        $this.Context().Warning("Tasks Collection - Getting Parameter Key '$($id)' ")
        foreach($entitie in $this._releaseDefinitionTasks){
            if($entitie.Name() -eq $id){
				$this.Context().Warning("** Tasks Collection - Found It!!")
                return $entitie
            }
        }
        return $null
    }
    [UIReleaseDefinitionTask] Add([string]$id){
        $entitie = $this.Get($id)
        if($entitie -eq $null){

            if(-not $this.Context()){
                throw "Context is null which is being passed to UI Variable Group inside of UI UIReleaseDefinitionTaskCollection.Add"
            }
			
            $entitie = [UIReleaseDefinitionTask]::new($this.Context(), $this.ReleaseDefinition(), $id)
            $this._releaseDefinitionTasks.Add($entitie)
			$this.Context().Log("Adding Task Phase $($entitie.Name())") 
        }

        return $entitie
    }
    [void] PopulateFromXML([System.Xml.XmlElement] $xml) {
		
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "Tasks") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "Task") {
					    $this.Context().Warning("Tasks Collection - Found Inputs in Xml ")
                        
                        [UIReleaseDefinitionTask]::PopulateFromXML($this.Context(), $step, $this)
                    }
                }
            }
        }
    }
    [String] ToString(){
		$content = "Tasks`r`n"
		$content += $this._releaseDefinitionTasks | Where {$_} | Foreach {"  "+$_.ToString().Replace("`r`n","`r`n  ")+"`r`n"}
        return $content
	}
}
class UIReleaseDefinitionTask : HasReleaseDefinitionContext{
    hidden [string] $_taskId
    hidden [string] $_version
    
    hidden [string] $_displayName
    hidden [UIReleaseDefinitionVariableCollection] $_inputs
    UIReleaseDefinitionTask([ConfigAutomationContext] $context):base($context){
    }
    UIReleaseDefinitionTask([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope, [string] $_name):base($context, $_parentScope, $_name){
        
        $this._inputs = [UIReleaseDefinitionVariableCollection]::new($context, $_parentScope)
    }
    static [void] PopulateFromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIReleaseDefinitionTaskCollection] $tasks){
        if(-not ($element.GetAttribute("Name"))){
            throw "Not all the attributes to build the parameter element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n   )"
        }

        if(-not $context){
            throw "Context is null which is being passed to UI Variable inside of UI Variable.FromXML"
        }

        $task = $tasks.Get($element.Name)
        if(-not $task){
            $task = $tasks.Add($element.Name)
        }
        $context.PopulateFromXml($element, $task)

        
    }
    [String] ToString(){
		$content = "Task $($this._name)`r`n"
		$content += $this._inputs | Foreach {"  "+$_.ToString().Replace("`r`n","`r`n  ")+"`r`n"}
        return $content
	}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - Environment - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIReleaseDefinitionEnvironmentConditionCollection : HasConsumableReleaseDefinitionContext{
    [System.Collections.ArrayList] $_releaseDefinitionEnvironmentConditions
	UIReleaseDefinitionEnvironmentConditionCollection([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionEnvironmentConditions = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionEnvironmentConditionCollection([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        $this._releaseDefinitionEnvironmentConditions = New-Object System.Collections.ArrayList
    }

    [void] PopulateFromXML([System.Xml.XmlElement] $xml) {
		
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "Conditions") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "Condition") {
					    $this.Context().Warning("Tasks Collection - Found Inputs in Xml ")
                        
                        $this._releaseDefinitionEnvironmentConditions.Add([UIReleaseDefinitionEnvironmentCondition]::FromXML($this.Context(), $step, $this))
                    }
                }
            }
        }
    }

}
class UIReleaseDefinitionEnvironmentCondition : HasReleaseDefinitionContext{
    
    
    hidden [string] $_branch
    hidden [string] $_tag
    UIReleaseDefinitionEnvironmentCondition([ConfigAutomationContext] $context):base($context){
    }
    UIReleaseDefinitionEnvironmentCondition([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope, [string] $_name):base($context, $_parentScope, $_name){
        
    }
    static [UIReleaseDefinitionEnvironmentCondition] FromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIReleaseDefinitionEnvironmentConditionCollection] $conditions){
        if(-not ($element.GetAttribute("Name"))){
            throw "Not all the attributes to build the parameter element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n   )"
        }

        if(-not $context){
            throw "Context is null which is being passed to UI Variable inside of UI Variable.FromXML"
        }

        $condition = [UIReleaseDefinitionEnvironmentCondition]::new($context, $conditions.ReleaseDefinition(), $element.Name)
        return $condition

        
    }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - Environment - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIReleaseDefinitionTriggerCollection : HasConsumableReleaseDefinitionContext{
    [System.Collections.ArrayList] $_releaseDefinitionTriggers
	UIReleaseDefinitionTriggerCollection([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionTriggers = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionTriggerCollection([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        $this._releaseDefinitionTriggers = New-Object System.Collections.ArrayList
    }
    [void] PopulateFromXML([System.Xml.XmlElement] $xml) {
		
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "Triggers") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "Trigger") {
					    $this.Context().Warning("Triggers Collection - Found Inputs in Xml ")
                        
                        $this._releaseDefinitionTriggers.Add([UIReleaseDefinitionTrigger]::FromXML($this.Context(), $step, $this))
                    }
                }
            }
        }
    }
}
class UIReleaseDefinitionTrigger : HasReleaseDefinitionContext{
    
    
    hidden [UIReleaseDefinitionTriggerConditionCollection] $_releaseDefinitionTriggerConditionCollection
    UIReleaseDefinitionTrigger([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionTriggerConditionCollection = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionTrigger([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope, [string] $_name):base($context, $_parentScope, $_name){
        
        $this._releaseDefinitionTriggerConditionCollection = New-Object System.Collections.ArrayList
    }
    static [UIReleaseDefinitionTrigger] FromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIReleaseDefinitionTriggerCollection] $conditions){
        if(-not ($element.GetAttribute("Name"))){
            throw "Not all the attributes to build the parameter element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n   )"
        }

        if(-not $context){
            throw "Context is null which is being passed to UI Variable inside of UI Variable.FromXML"
        }

        $trigger = [UIReleaseDefinitionTrigger]::new($context, $conditions.ReleaseDefinition(), $element.Name)
        return $trigger

        
    }
    
}
class UIReleaseDefinitionTriggerConditionCollection : HasConsumableReleaseDefinitionContext{
    [System.Collections.ArrayList] $_releaseDefinitionTriggerCondition
	UIReleaseDefinitionTriggerConditionCollection([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionTriggerCondition = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionTriggerConditionCollection([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        $this._releaseDefinitionTriggerCondition = New-Object System.Collections.ArrayList
    }
    [void] PopulateFromXML([System.Xml.XmlElement] $xml) {
		
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "Conditions") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "Condition") {
					    $this.Context().Warning("Triggers Collection - Found Inputs in Xml ")
                        
                        $this._releaseDefinitionTriggerCondition.Add([UIReleaseDefinitionTriggerCondition]::FromXML($this.Context(), $step, $this))
                    }
                }
            }
        }
    }

}
class UIReleaseDefinitionTriggerCondition : HasReleaseDefinitionContext{
    
    
    hidden [string] $_branch
    hidden [string] $_tag
    UIReleaseDefinitionTriggerCondition([ConfigAutomationContext] $context):base($context){
    }
    UIReleaseDefinitionTriggerCondition([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope, [string] $_name):base($context, $_parentScope, $_name){
        
    }
    static [UIReleaseDefinitionTriggerCondition] FromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIReleaseDefinitionTriggerConditionCollection] $conditions){
        if(-not ($element.GetAttribute("Name"))){
            throw "Not all the attributes to build the parameter element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n   )"
        }

        if(-not $context){
            throw "Context is null which is being passed to UI Variable inside of UI Variable.FromXML"
        }

        $triggerCondition = [UIReleaseDefinitionTriggerCondition]::new($context, $conditions.ReleaseDefinition(), $element.Name)
        return $triggerCondition

        
    }
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - Environment - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIReleaseDefinitionArtifactCollection : HasConsumableReleaseDefinitionContext{
    [System.Collections.ArrayList] $_releaseDefinitionArtifacts

	UIReleaseDefinitionArtifactCollection([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionArtifacts = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionArtifactCollection([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        $this._releaseDefinitionArtifacts = New-Object System.Collections.ArrayList
    }

    [void] PopulateFromXML([System.Xml.XmlElement] $xml) {
		
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "Artifacts") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "Artifact") {
					    $this.Context().Warning("Triggers Collection - Found Inputs in Xml ")
                        
                        $this._releaseDefinitionArtifacts.Add([UIReleaseDefinitionArtifact]::FromXML($this.Context(), $step, $this))
                    }
                }
            }
        }
    }
}
class UIReleaseDefinitionArtifact : HasReleaseDefinitionContext{
    hidden [string] $_defaultVersionBranch
    hidden [string] $_defaultVersionSpecific
    hidden [string] $_defaultVersionTags
    hidden [string] $_defaultVersionType
    hidden [string] $_project
    hidden [string] $_type
    hidden [string] $_sourceId

	UIReleaseDefinitionArtifact([ConfigAutomationContext] $context):base($context){
    }
    UIReleaseDefinitionArtifact([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope, [string] $_name):base($context, $_parentScope, $_name){
    }


    static [UIReleaseDefinitionArtifact] FromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIReleaseDefinitionArtifactCollection] $conditions){
        if(-not ($element.GetAttribute("Name"))){
            throw "Not all the attributes to build the parameter element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n   )"
        }

        if(-not $context){
            throw "Context is null which is being passed to UI Variable inside of UI Variable.FromXML"
        }

        $triggerCondition = [UIReleaseDefinitionArtifact]::new($context, $conditions.ReleaseDefinition(), $element.Name)
        return $triggerCondition

        
    }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - Environment - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIReleaseDefinitionDeploymentPhaseInput : HasReleaseDefinitionContext{
    [System.Collections.ArrayList] $_releaseDefinitionDeploymentPhaseInputArtifactDownloadCollection

	UIReleaseDefinitionDeploymentPhaseInput([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionDeploymentPhaseInputArtifactDownloadCollection = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionDeploymentPhaseInput([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        $this._releaseDefinitionDeploymentPhaseInputArtifactDownloadCollection = New-Object System.Collections.ArrayList
    }
}
class UIReleaseDefinitionDeploymentPhaseInputArtifactDownloadCollection : HasReleaseDefinitionContext{
    [System.Collections.ArrayList] $_releaseDefinitionDeploymentPhaseInputArtifactDownloads

	UIReleaseDefinitionDeploymentPhaseInputArtifactDownloadCollection([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionDeploymentPhaseInputArtifactDownloads = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionDeploymentPhaseInputArtifactDownloadCollection([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope, [string] $artifactAlisas):base($context, $_parentScope){
        $this._releaseDefinitionDeploymentPhaseInputArtifactDownloads = New-Object System.Collections.ArrayList
    }
}
class UIReleaseDefinitionDeploymentPhaseInputArtifactDownload : HasReleaseDefinitionContext{
    
	UIReleaseDefinitionDeploymentPhaseInputArtifactDownload([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionTasks = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionDeploymentPhaseInputArtifactDownload([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope, [string] $artifactAlisas):base($context, $_parentScope){
        $this._releaseDefinitionTasks = New-Object System.Collections.ArrayList
    }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - Release Definition Change - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIReleaseDefinitionPreDeployApprovalSettings : HasReleaseDefinitionContext{
    [System.Collections.ArrayList] $_releaseDefinitionPreDeployApprovals
	UIReleaseDefinitionPreDeployApprovalSettings([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionPreDeployApprovals = [UIReleaseDefinitionPreDeployApprovalCollection]::new($context)
    }
    UIReleaseDefinitionPreDeployApprovalSettings([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        $this._releaseDefinitionPreDeployApprovals = [UIReleaseDefinitionPreDeployApprovalCollection]::new($context, $_parentScope)
    }
}
class UIReleaseDefinitionPreDeployApprovalCollection : HasReleaseDefinitionContext{
    [System.Collections.ArrayList] $_releaseDefinitionPreDeployApprovals
	
	UIReleaseDefinitionPreDeployApprovalCollection([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionPreDeployApprovals = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionPreDeployApprovalCollection([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        $this._releaseDefinitionPreDeployApprovals = New-Object System.Collections.ArrayList
    }
}
class UIReleaseDefinitionPreDeployApproval : HasContext{
    hidden [bool] $_isAutomated
		
	UIReleaseDefinitionPreDeployApproval([ConfigAutomationContext] $context):base($context){
        
    }
    UIReleaseDefinitionPreDeployApproval([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        
    }
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - Release Definition Change - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIReleaseDefinitionPostDeployApprovalSettings : HasReleaseDefinitionContext{
    [System.Collections.ArrayList] $_releaseDefinitionPostDeployApprovals

	UIReleaseDefinitionPostDeployApprovalSettings([ConfigAutomationContext] $context):base($context){
    }
    UIReleaseDefinitionPostDeployApprovalSettings([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        $this._releaseDefinitionPostDeployApprovals = [UIReleaseDefinitionPostDeployApprovalCollection]::new($context, $_parentScope)
    }
}
class UIReleaseDefinitionPostDeployApprovalCollection : HasReleaseDefinitionContext{
    [System.Collections.ArrayList] $_releaseDefinitionPostDeployApprovals
    
	UIReleaseDefinitionPostDeployApprovalCollection([ConfigAutomationContext] $context):base($context){
        $this._releaseDefinitionPostDeployApprovals = New-Object System.Collections.ArrayList
    }
    UIReleaseDefinitionPostDeployApprovalCollection([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        $this._releaseDefinitionPostDeployApprovals = New-Object System.Collections.ArrayList
    }
}
class UIReleaseDefinitionPostDeployApproval : HasReleaseDefinitionContext{
    hidden [bool] $_isAutomated
    
	UIReleaseDefinitionPostDeployApproval([ConfigAutomationContext] $context):base($context){
        
    }
    UIReleaseDefinitionPostDeployApproval([ConfigAutomationContext] $context,[UIReleaseDefinition] $_parentScope):base($context, $_parentScope){
        
    }
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - -UIParameterTypeCollection Collection - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIInputTypeDefinitionCollection: HasCollectionContext {


	UIInputTypeDefinitionCollection([ConfigAutomationContext] $context) : base($context,"Input Type Definitions"){
       
    }
    UIInputTypeDefinitionCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope) : base($context, $scope,"Input Type Definitions"){
       
    }
    [void] PopulateFromXML([System.Xml.XmlElement] $xml){
		
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "InputTypes")
            {
				# #TEMP $this.Action("XMLParsing", "{magenta}Consuming Input Types{gray} '{white}$($roots.GetAttribute("Name")){gray}'")
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "InputType") {
						# #TEMP $this.Action("XMLParsing", "{magenta}Consuming Input Type{gray} '{white}$($step.GetAttribute("Name")){gray}'")
                        $this.Add([UIInputTypeDefinition]::FromXML($this.Context(), $step, $this.CurrentScope()))
                    }
                }
            }
        }
        
    }
}
class UIInputTypeDefinition: UITypeDefinition {

	UIInputTypeDefinition([ConfigAutomationContext] $_context) : base($_context){
    }
    UIInputTypeDefinition([ConfigAutomationContext] $_context, [String] $name, [String] $contentType, [String] $content, [UIInputScopeBase] $scope) : base($_context, $name, $contentType, $content, "Input Type", $scope){
    }

    [object] GetInputValue([UIInputStrategy] $inputStrategy){
		return $this.InvokeCallback("InputValue", @($($this.Context()), $inputStrategy, $PSBoundParameters))
    }
    [object] GetInputMetadata([UIInputStrategy] $inputStrategy, [System.Xml.XmlElement] $xmlInput){
		return $this.InvokeCallback("InputMetadata", @($($this.Context()), $inputStrategy, $xmlInput))
    }
	[bool] Clean([UIInputStrategy] $inputStrategy){
		return $this.InvokeCallback("Clean", @($($this.Context()), $inputStrategy))
	}
    static [UIInputTypeDefinition] FromXML([ConfigAutomationContext] $_context, [System.Xml.XmlElement] $element, [UIInputScopeBase] $scope){
		return [UITypeDefinition]::FromXml($_context, $element, [UIInputTypeDefinition], $scope)
    }
	[String] ToString(){
		return $this.Name()
	}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - UIParameterTypeReferenceCollection Collection - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIInputTypeReferenceCollection : HasContext {

    [System.Collections.ArrayList] $_inputTypeReferences

    UIInputTypeReferenceCollection([ConfigAutomationContext] $context) : base($context) {
        $this._inputTypeReferences = New-Object System.Collections.ArrayList
    }
    [UIInputTypeReference[]] Items(){
        return $this._inputTypeReferences
    }
    [UIInputTypeReference] Get([string]$name){
        
        foreach($inputTypeReference in $this._inputTypeReferences){
            if($inputTypeReference.Name() -eq $name){
                return $inputTypeReference
            }
        }
        return $null
    }
}
class UIInputTypeReference : HasContext{

    [UIInputTypeDefinition] $_definition
	UIInputTypeReference([ConfigAutomationContext] $_context) : base($_context) {
    }
    UIInputTypeReference([ConfigAutomationContext] $_context, [String] $name, [UIInputScopeBase] $scope) : base($_context, $scope, $name) {
    }

    [UIInputTypeDefinition] Definition(){
        $this.Context().Log("InputTypes", "Referencing UI Input Type '$($this.Name())'")
		
		if($this._definition){
			return $this._definition
		}
		$this._definition = $this.Context().InputTypes().Get($this.Name())
        return $this._definition
    }
	[String] ToString(){
		return $this.Name()
	}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - -UIParameterTypeCollection Collection - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIActionTypeDefinitionCollection: HasCollectionContext {

    [hashtable] $_actionTypes
	
	UIActionTypeDefinitionCollection([ConfigAutomationContext] $context) : base($context){
		
    }
    UIActionTypeDefinitionCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope) : base($context, $scope, "ActionTypes"){
		
    }
    [UIActionTypeDefinition] Add([String] $name, [String] $contentType, [String] $content){
        if($this.Get($name)){
            throw "UI Parameter Type '$($name)' has already been added, unable to add again"
        }
        
        $definition = [UIActionTypeDefinition]::new($this._context, $name, $contentType, $content, $this.CurrentScope())
		$this.Add($definition)
        return $definition
    }
    [void] PopulateFromXML([System.Xml.XmlElement] $xml){
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "ActionTypes") 
            {
				# #TEMP $this.Action("XMLParsing", "{magenta}Consuming Action Types{gray} '{white}$($roots.GetAttribute("Name")){gray}'")
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "ActionType") {
						# #TEMP $this.Action("XMLParsing", "{magenta}Consuming Action Type{gray} '{white}$($step.GetAttribute("Name")){gray}'")
                        if(-not ($this.Add([UIActionTypeDefinition]::FromXML($this.Context(), $step, $this.CurrentScope())))){
							$this.Error("Failed to add action from xml snippet:`r`n$($step.Outerxml)")
						}
                    }
                }
            }
        }
    }
}

class UIActionTypeDefinition: UITypeDefinition {

	hidden [UIParameterCollection] $_parameters
	
	UIActionTypeDefinition([ConfigAutomationContext] $_context) : base($_context){
    }
    UIActionTypeDefinition([ConfigAutomationContext] $_context, [String] $name, [string] $contentType, [String] $content, [UIInputScopeBase] $scope) : base($_context, $name, $contentType, $content, "Action Type", $scope){
		$this._parameters     = [UIParameterCollection]::new($_context, $_context.CurrentScope())
    }
	[UIParameterCollection] Parameters(){
		return $this._parameters
	}
	[bool] Clean([UIAction] $action){
		return $this.Clean($action, @{})
	}
	[bool] Clean([UIAction] $action, [hashtable] $arguments){
		return $this.InvokeCallback("Clean", @(($this.Context()), $action, $arguments))
    }
	[bool] Validate([UIAction] $action){
		return $this.Validate($action, @{})
	}
	[bool] Validate([UIAction] $action, [hashtable] $arguments){
		return $this.InvokeCallback("Validate", @(($this.Context()), $action, $arguments))
    }
	[bool] Execute([UIAction] $action){
		return $this.Execute($action, @{})
	}
    [bool] Execute([UIAction] $action, [hashtable] $arguments){
        $result = $this.InvokeCallback("Action", @(($this.Context()), $action, $arguments))
		if($result){
			if($result -is [bool]){
				if($result -eq $false){
					return $null
				}
				return $true
			}
			if($result -is [array] -and ($result[$result.length - 1] -is [bool])){
				$result = $result[$result.length - 1]
				if($result -eq $false){
					return $null
				}
				return $true
			}
			$this.Error( "Output of Execute is not supported - $($result.GetType())")
			return $false
		}
		
		return $true
    }
	[bool] CanExecute([UIAction] $action){
		return $this.CanExecute($action, @{})
	}
    [bool] CanExecute([UIAction] $action, [hashtable] $arguments){
        return $this.InvokeCallback("CanExecute", @(($this.Context()), $action, $arguments))
    }
    static [UIActionTypeDefinition] FromXML([ConfigAutomationContext] $_context, [System.Xml.XmlElement] $element, [UIInputScopeBase] $scope){
		return [UITypeDefinition]::FromXML($_context, $element, [UIActionTypeDefinition], $scope)
	}
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - UIParameterTypeReferenceCollection Collection - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIActionTypeReferenceCollection : HasContext {

    [System.Collections.ArrayList] $_actionTypeReferences

    UIActionTypeReferenceCollection([ConfigAutomationContext] $context) : base($context) {
        $this._actionTypeReferences = New-Object System.Collections.ArrayList
    }
    [UIActionTypeReference[]] Items(){
        return $this._actionTypeReferences
    }
    [UIActionTypeReference] Get([string]$name){
        
        foreach($actionTypeReference in $this._actionTypeReferences){
            if($actionTypeReference.Name() -eq $name){
                return $actionTypeReference
            }
        }
        return $null
    }
}
class UIActionTypeReference : HasContext{


    
    UIActionTypeReference([ConfigAutomationContext] $_context) : base($_context) {
    }
    UIActionTypeReference([ConfigAutomationContext] $_context, [UIInputScopeBase]$_parentScope, [String] $name) : base($_context, $_parentScope, $name) {
        
    }
    [UIActionTypeDefinition] Definition(){
        $this.Context().Log("Referencing UI Action Type '$($this.Name())'")
		
        return $this.CurrentScope().ActionTypes().Get($this.Name())
    }
	[String] ToString(){
		return $this.Name()
	}
}
class UISectionCollection : HasCollectionContext{

	UISectionCollection([ConfigAutomationContext] $context):base($context,"Sections"){
    }
	UISectionCollection([ConfigAutomationContext] $context, [string] $name):base($context,$name){
    }
    UISectionCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope):base($context, $scope,"Sections"){
    }
	UISectionCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope, [string] $name):base($context, $scope,$name){
    }
    
	
	static [object] Requirements(){
		return [PSCustomObject]@{
			ParentElementNames =@("Sections");
			ChildElementNames = @("Section");
			ChildType = [UISection]
		}
	}
}

class UISection : UIInputScope{

	UISection([ConfigAutomationContext] $context):base($context){
		$this.Hierarchical($false)
    }
	UISection([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name):base($context, $_parent, $name, "Sections"){
		$this.Hierarchical($false)
		}
    UISection([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name, [string] $referenceName):base($context, $_parent, $name, $referenceName){
		$this.Hierarchical($false)
    }
	static [object] Requirements(){
		return [PSCustomObject]@{
			PrimaryKey = "Name";
			ElementNames =@("Section")
		}
	}
	static [UISection] FromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIActionCollection] $actions){
	
		return [HasContext]::FromXML($context, $element, $actions, [UISection])
    }
	[void] PopulateFromXML([System.Xml.XmlElement] $xml) {
        $this.Context().PopulateFromXml($xml, $this)
    }
}
class UIActionCollection : HasCollectionContext{

	UIActionCollection([ConfigAutomationContext] $context):base($context,"Actions"){
		
    }
	UIActionCollection([ConfigAutomationContext] $context, [string] $name):base($context,$name){
		$this._lockPerforms = new-object hashtable
    }
    UIActionCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope):base($context, $scope,"Actions"){
		$this._lockPerforms = new-object hashtable
    }
	UIActionCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope, [string] $name):base($context, $scope,$name){
		$this._lockPerforms = new-object hashtable
    }
	[bool] RefreshSession(){
		if(-not ([HasContext]$this).RefreshSession()){
			return $false
		}
		$this._lockPerforms = new-object hashtable
		return $true
	}
    [hashtable] $_lockPerforms 
	[bool] Perform([ScriptBlock] $action, [string] $actionName){
		return $this.Perform($action, $actionName, $false)
	}
	[bool] Perform([ScriptBlock] $action, [string] $actionName, [bool] $executeParents){
		$this.RefreshSessionIfNeeded()
		if($this._lockPerforms[$actionName]){
			return $true
		}
		$this._lockPerforms.Add($actionName, $true)
		$valid = $true
		
		if($executeParents)
		{
			if($this.CurrentScope().ParentScope()){		
				$valid = $this.CurrentScope().ParentScope().Get("PreActions").Perform($action, $actionName) -and $valid
			}
		}
		
		foreach($uiAction in $this.Items()){
			$valid = $uiAction.Perform($action, $actionName) -and $valid
		}
		
		if($executeParents)
		{
			if($this.CurrentScope().ParentScope()){		
				$valid = $this.CurrentScope().ParentScope().Get("PostActions").Perform($action, $actionName) -and $valid
			}
		}
		
		$this._lockPerforms.Remove($actionName)
		return $valid
		
	}
	
	static [object] Requirements(){
		return [PSCustomObject]@{
			ParentElementNames =@("Actions");
			ChildElementNames = @("Action");
			ChildType = [UIAction]
		}
	}
}

class UIAction : UIInputScope{

    hidden [UIActionTypeReference]        $_type
	hidden [hashtable]                    $_variableOrigins
	hidden [hashtable] 					  $_actionsAlreadyPerformed
	UIAction([ConfigAutomationContext] $context):base($context){
		$this._variableOrigins = New-Object hashtable
		$this._actionsAlreadyPerformed = new-object hashtable
		$this.Hierarchical($false)
    }
	UIAction([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name):base($context, $_parent, $name, "Actions"){
		$this._variableOrigins = New-Object hashtable
		$this._actionsAlreadyPerformed = new-object hashtable
		$this.Hierarchical($false)
		}
    UIAction([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name, [string] $referenceName):base($context, $_parent, $name, $referenceName){
		$this._variableOrigins = New-Object hashtable
		$this._actionsAlreadyPerformed = new-object hashtable
		$this.Hierarchical($false)
	}
	[bool] RefreshSession(){
		if(-not ([HasContext]$this).RefreshSession()){
			return $false
		}
		$this._variableOrigins         = New-Object hashtable
		$this._actionsAlreadyPerformed = new-object hashtable
		return $true
	}
	[string] DisplayName([string] $color){
		return $this.Name()
	}
	[bool] CanPerform([ref] $reason){
		if($this._properties["Condition"]){
			$rawExpression = $this._properties["Condition"]
			
			$expression = $this.ParameterizeString($rawExpression, $true, "$", $true)
			$isEnabled = Invoke-Expression $expression
			if(-not $isEnabled){
				$reason.Value = "{yellow}Skipping{gray} {magenta}Condition {gray}={white} $($rawExpression) {gray}={white} $($expression) {gray}={white} {magenta}$($isEnabled){gray}"
				return $false
			}
		}

		if($this._properties["RunWhen"]){
			if($this._properties["RunWhen"] -ieq "failed"){
				if($this.Context().IsValid()){
					$reason.Value = "{yellow}Skipping{gray} {magenta}RunWhen {gray}={white} failed {gray} Current Status is Passing"
					return $false
				}
			}
			elseif($this._properties["RunWhen"] -ieq "succeeded"){
				if(-not $this.Context().IsValid()){
					$reason.Value = "{yellow}Skipping{gray} {magenta}RunWhen {gray}={white} succeeded {gray} Current Status is Failure"
					return $false
				}
			}
			elseif($this._properties["RunWhen"] -ieq "always"){
				return $true
			}
			else{
				$this.Error("{white}RunWhen{gray} is set to {magenta}$($this._properties["RunWhen"]){gray} which is not recognized, only acceptable values are 'failed','succeeded', and 'always'")
			}
		}
		return $true
	}
	[bool] Perform([ScriptBlock] $scriptAction, [string] $actionName){
		$this._localVariables.Add("PerformingAction", $actionName)
		

		
		if($this.Context().ExitRequested()){
			$this.Warning("User Exiting...")
			$this._localVariables.Remove("PerformingAction")
			return $false
		}
		
		$this.RefreshSessionIfNeeded()
		if($this._actionsAlreadyPerformed.ContainsKey($actionName)){
			$this._localVariables.Remove("PerformingAction")
			return $this._actionsAlreadyPerformed[$actionName]
		}
		
		
		$shortMessage = ""
		$isValid = $true
		$this._actionsAlreadyPerformed.Add($actionName, $true)
		$isRootLevel = $this.Context().ActionLevel() -eq 0
		
		$activeCollection           = $this.ActiveFromCollection()
		$activeCollectionProperties = (new-object hashtable) 
		if(-not $activeCollection){
			if(-not ($isRootLevel)){
				$this.Warning("Active Collection was not found... Needed to check collection specific properties")
				# $isValid = $false
			}
		}
		else{
			$activeCollectionProperties = $($activeCollection.Properties)
		}
		
		$this.Context().StartLoggingContext("$($this.Name())")
		$this.Context().PushActionLevel()
		
		if($activeCollectionProperties["ScopeType"] -ieq "Parent"){
			$this.Context().PushScope($($this.Context().CurrentScope()))
		}
		elseif($activeCollectionProperties["ScopeType"] -ieq "Self"){
			$this.Context().PushScope($this)
		}
		elseif($activeCollectionProperties.Contains("ScopeType")){
			$this.Error("{white}ScopeType{gray} is set to {magenta}$($this._properties["ScopeType"]){gray} which is not recognized, only acceptable values are 'Parent','Self'")
			$isValid = $false
		}
		else{
			$this.Context().PushScope($this)
		}
		
		$this.LoadChildren()

		$this.Context().StartLoggingContext("can-perform")
		$canRun = $this.CanPerform(([ref]$shortMessage))
		$this.Context().EndLoggingContext()

		# Check for Conditions for running...
		if($canRun){
			$this.Context().StartLoggingContext("pre-actions")
			$isValid = $this.Get("PreActions").Perform($scriptAction, $actionName, $isRootLevel) -and $isValid
			$this.LoadChildren()
			$this.Context().EndLoggingContext()
		}
		# $this.Context().DisableLog()
		
		$this.Context().Display("{white}:: {white}[{magenta}$($this.DisplayName('magenta')){white}] - $($shortMessage)")
		[HasContext]::Prefix += "   "
		
		# $this.Context().DelayLogging($true)
		if($canRun){
			$isValid = (.$scriptAction $this) -and $isValid
		}
		
		
		# $this.Context().DelayLogging($false)
		[HasContext]::Prefix = [HasContext]::Prefix.Substring(3)

		#$this.Context().EnableLog()
		if($canRun)
		{
			if($isValid){
				$this.Context().Display("{white}:: {white}[{green}$($this.DisplayName('green')){white}] - {green}Success{gray}")
			}
			else{
				$this.Context().Display("{white}:: {white}[{red}$($this.DisplayName('red')){white}] - {red}Failed{gray}")
			}
		}
		
		$this.Context().PopActionLevel()
		$this.Context().PopScope()
		
		if($canRun)
		{
			$this.Context().StartLoggingContext("post-actions")
			$isValid = $this.Get("PostActions").Perform($scriptAction, $actionName, $isRootLevel) -and $isValid
			$this.Context().EndLoggingContext()

			$this._actionsAlreadyPerformed[$actionName] = $isValid
			$this._localVariables.Remove("PerformingAction")
			$this.Context().EndLoggingContext()
			return $isValid
		}
		
		$this._actionsAlreadyPerformed[$actionName] = $isValid
		$this._localVariables.Remove("PerformingAction")
		$this.Context().EndLoggingContext()

		return $isValid
	}
    [UIActionTypeReference] ActionType(){
		return [UIActionTypeReference]::new($this.Context(), $this, $this._properties["Type"])
        # return $this._type
    }
	[void] ActionType([UIActionTypeReference] $type){
        $this._type = $type
    }
	[bool] ExecuteAction(){
		return $this.ExecuteAction(@{})
	}
	[bool] Clean(){
		return $this.Clean(@{})
	}
	
	[bool] Clean([hashtable] $arguments){
		
		$testValid = {
			Param([UIAction] $action)
			$actionType = $action.ActionType().Definition()
			if(-not $actionType){
				$action.Error("Actions", "Action {white}$($action.CurrentScope().ParentScopeFullName()){gray}|{white}$($action.Name()){gray} is referencing non-exsiting action type {white}$($action.ActionType().Name()){gray}, unable to execute for this reason")
				return $false;
			}
			if(-not $actionType.Clean($action, $arguments)){
				$action.Error("Action '$($action.Name())' failed cleaning")
				return $false
			}
			if(-not $action.Parameters().Clean()){
				$action.Error("Action '$($action.Name())' parameters failed cleaning")
				return $false
			}
			return $true
		}
		$this._actionsAlreadyPerformed = new-object hashtable
		return $this.Perform($testValid, "Cleaning")
	}
	
	[bool] Validate(){
		return $this.Validate(@{})
	}
	
	[bool] Validate([hashtable] $arguments){
		
		$testValid = {
			Param([UIAction] $action)
			$actionType = $action.ActionType().Definition()
			if(-not $actionType){
				$action.Error("Actions", "Action {white}$($action.CurrentScope().ParentScopeFullName()){gray}|{white}$($action.Name()){gray} is referencing non-exsiting action type {white}$($action.ActionType().Name()){gray}, unable to execute for this reason")
				return $false;
			}
			if(-not $actionType.Validate($action, $arguments)){
				$action.Error("Action '$($this.Name())' failed validation")
				return $false
			}
			if(-not $action.Parameters().ValidateRequiredParameters()){
				$action.Error("Action '$($action.Name())' parameters failed validation")
				return $false
			}
			return $true
		}
		return $this.Perform($testValid, "Validating")
	}
    [bool] ExecuteAction([hashtable] $arguments){
		$testValid = {
			Param([UIAction] $action)
			$actionType = $action.ActionType().Definition()
			if(-not $actionType){
				$action.Error("Actions", "Action {white}$($action.CurrentScope().ParentScopeFullName()){gray}|{white}$($action.Name()){gray} is referencing non-exsiting action type {white}$($action.ActionType().Name()){gray}, unable to execute for this reason")
				return $false;
			}
			
			# if(-not $actionType.Validate($action, $arguments)){
			# 	$action.Error("Action '$($action.Name())' failed validation")
			# 	return $false
			# }
			
			if(-not $actionType.CanExecute($action, $arguments)){
				$action.Context().Display("{white}[{magenta}$($action.Name()){white}] - {yellow}Skipping...{gray}")
				$action.Error("Action '$($action.Name())' has been flagged to to not be executable")
				return $false
			}
			
			if(-not $actionType.Execute($action, $arguments)){
				$action.Error("Action '$($action.Name())' failed to execute")
				return $false
			}
			return $true
		}
		
		return $this.Perform($testValid, "Executing")
    }
	static [object] Requirements(){
		return [PSCustomObject]@{
			PrimaryKey = "Name";
			ElementNames =@("Action")
		}
	}
	static [UIAction] FromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIActionCollection] $actions){
	
		return [HasContext]::FromXML($context, $element, $actions, [UIAction])
    }
	[void] PopulateFromXML([System.Xml.XmlElement] $xml) {
        $this.Context().PopulateFromXml($xml, $this)
    }
}
class UIActionTemplateCollection : HasCollectionContext {
	UIActionTemplateCollection([ConfigAutomationContext] $context):base($context,"ActionTemplates"){
    }
    UIActionTemplateCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope):base($context, $scope,"ActionTemplates"){
    }
	
	static [object] Requirements(){
		return [PSCustomObject]@{
			ParentElementNames =@("ActionTemplates");
			ChildElementNames = @("ActionTemplate");
			ChildType = [UIActionTemplate]
		}
	}
}
class UIPreActionCollection : UIActionCollection {
	UIPreActionCollection([ConfigAutomationContext] $context):base($context,"PreActions"){
    }
    UIPreActionCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope):base($context, $scope,"PreActions"){
    }
	
	[void] PopIndentAllPreActions(){
		if($this.CurrentScope().ParentScope()){		
			# $this.PopIndent()
			$valid = $this.CurrentScope().ParentScope().Get("PreActions").PopIndentAllPreActions()
		}
	}
	[bool] Perform([ScriptBlock] $action, [string] $actionName, [bool] $executeParents, [bool] $isRoot){
		$this.RefreshSessionIfNeeded()
		if($this._lockPerforms[$actionName]){
			return $true
		}
		$this._lockPerforms.Add($actionName, $true)
		
		# Import Templates
		if(-not $this.CurrentScope().Get("ImportTemplates").Import()){
			$this.Error("Failed to import templates")
			return $false
		}
		
		$valid = $true
		if($this.CurrentScope().ParentScope()){		
			$valid = $this.CurrentScope().ParentScope().Get("PreActions").Perform($action, $actionName, $true, $false) -and $valid
			# $this.PushIndent()
		}
		
		foreach($uiAction in $this.Items()){
			$valid = $uiAction.Perform($action, $actionName) -and $valid
		}
		
		if($isRoot){		
			# $this.PopIndentAllPreActions()
		}
		$this._lockPerforms.Remove($actionName)
		return $valid
	}
	[bool] Perform([ScriptBlock] $action, [string] $actionName, [bool] $executeParents){
		return $this.Perform($action, $actionName, $executeParents, $true)
		
		
	}
	static [object] Requirements(){
		return [PSCustomObject]@{
			ParentElementNames =@("PreActions");
			ChildElementNames = @("PreAction");
			ChildType = [UIPreAction]
		}
	}
}
class UIPostActionCollection : UIActionCollection {
	UIPostActionCollection([ConfigAutomationContext] $context):base($context,"PostActions"){
    }
    UIPostActionCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope):base($context, $scope,"PostActions"){
    }
	
	[bool] Perform([ScriptBlock] $action, [string] $actionName, [bool] $executeParents){
		$this.RefreshSessionIfNeeded()
		if($this._lockPerforms[$actionName]){
			#TEMP $this.Action("PostAction", "Action '{white}$actionName{gray}' is currently {magenta}locked{gray}")
			return $true
		}
		$this._lockPerforms.Add($actionName, $true)
		$valid = $true
		
		#TEMP $this.Action("PostAction", "Running all {white}$($this.Items().Count){gray} child actions")
		# $this.PushIndent("PostAction")
		foreach($uiAction in $this.Items()){
			$valid = $uiAction.Perform($action, $actionName) -and $valid
		}
		# $this.PopIndent("PostAction")
		
		if($executeParents)
		{
			#TEMP $this.Action("PostAction", "Running parent post actions")
			if($this.CurrentScope().ParentScope()){		
				#TEMP $this.Action("PostAction", "Post {magenta}Parent Actions{gray}: Running")
				$valid = $this.CurrentScope().ParentScope().Get("PostActions").Perform($action, $actionName, $true) -and $valid
			}
			else{
				#TEMP $this.Action("PostAction", "Post {magenta}Parent Actions{gray}: No Parent")
			}
		}
		else{
			#TEMP $this.Action("PostAction", "Post {magenta}Parent Actions{gray}: User said to not include")
		}
		
		$this._lockPerforms.Remove($actionName)
		return $valid
		
	}
	
	static [object] Requirements(){
		return [PSCustomObject]@{
			ParentElementNames =@("PostActions");
			ChildElementNames = @("PostAction");
			ChildType = [UIPostAction]
		}
	}
}
class UIActionOverrideCollection : UIActionCollection {
	UIActionOverrideCollection([ConfigAutomationContext] $context):base($context,"ActionOverrides"){
    }
    UIActionOverrideCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope):base($context, $scope,"ActionOverrides"){
    }
	
	static [object] Requirements(){
		return [PSCustomObject]@{
			ParentElementNames =@("ActionOverrides");
			ChildElementNames = @("ActionOverride");
			ChildType = [UIActionOverride]
		}
	}
}
class UIActionPluginCollection : UIActionCollection {
	UIActionPluginCollection([ConfigAutomationContext] $context):base($context,"ActionPlugins"){
    }
    UIActionPluginCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope):base($context, $scope,"ActionPlugins"){
    }
	
	static [object] Requirements(){
		return [PSCustomObject]@{
			ParentElementNames =@("ActionPlugins");
			ChildElementNames = @("ActionPlugin");
			ChildType = [UIActionPlugin]
		}
	}
}
class UIActionTemplate : UIAction{
	UIActionTemplate([ConfigAutomationContext] $context):base($context){
    }
    UIActionTemplate([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name):base($context, $_parent, $name, "ActionTemplates"){	
    }
	UIActionTemplate([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name, [string] $referenceName):base($context, $_parent, $name, $referenceName){	
    }
	static [object] Requirements(){
		return [PSCustomObject]@{
			PrimaryKey = "Name";
			ElementNames =@("ActionTemplate")
		}
	}
	static [HasContext] FromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIActionCollection] $actions){
	
		return [HasContext]::FromXML($context, $element, $actions, [UIActionTemplate])
    }
	[void] PopulateFromXML([System.Xml.XmlElement] $xml) {
        $this.Context().PopulateFromXml($xml, $this)
    }
	
}
class UIPreAction : UIAction{
	UIPreAction([ConfigAutomationContext] $context):base($context){
    }
    UIPreAction([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name):base($context, $_parent, $name, "UIPreActions"){	
    }
	UIPreAction([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name, [string] $referenceName):base($context, $_parent, $name, $referenceName){	
    }
	[string] DisplayName([string] $color){
		$parentText = $this.CurrentScope().ParentScopeName()
		return "{$($color)}$($parentText) {gray}(Pre) {gray} | {$($color)}" + $this.Name()
	}
	static [object] Requirements(){
		return [PSCustomObject]@{
			PrimaryKey = "Name";
			ElementNames =@("PreAction")
		}
	}
	static [HasContext] FromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIPreActionCollection] $actions){
	
		return [HasContext]::FromXML($context, $element, $actions, [UIPreAction])
    }
	[void] PopulateFromXML([System.Xml.XmlElement] $xml) {
        $this.Context().PopulateFromXml($xml, $this)
    }
	
}
class UIPostAction : UIAction{
	UIPostAction([ConfigAutomationContext] $context):base($context){
    }
    UIPostAction([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name):base($context, $_parent, $name, "UIPostActions"){	
    }
	UIPostAction([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name, [string] $referenceName):base($context, $_parent, $name, $referenceName){	
    }
	[string] DisplayName([string] $color){
		$parentText = $this.CurrentScope().ParentScopeName()
		return "{$($color)}$($parentText) {gray}(Post) {gray} | {$($color)}" + $this.Name()
	}
	static [object] Requirements(){
		return [PSCustomObject]@{
			PrimaryKey = "Name";
			ElementNames =@("PostAction")
		}
	}
	static [HasContext] FromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIPostActionCollection] $actions){
	
		return [HasContext]::FromXML($context, $element, $actions, [UIPostAction])
    }
	[void] PopulateFromXML([System.Xml.XmlElement] $xml) {
        $this.Context().PopulateFromXml($xml, $this)
    }
	
}
class UIActionOverride : UIAction{
	UIActionOverride([ConfigAutomationContext] $context):base($context){
    }
    UIActionOverride([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name):base($context, $_parent, $name, "UIActionOverrides"){	
    }
	UIActionOverride([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name, [string] $referenceName):base($context, $_parent, $name, $referenceName){	
    }
	static [object] Requirements(){
		return [PSCustomObject]@{
			PrimaryKey = "Name";
			ElementNames =@("ActionOverride")
		}
	}
	static [HasContext] FromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIPreActionCollection] $actions){
	
		return [HasContext]::FromXML($context, $element, $actions, [UIActionOverride])
    }
	[void] PopulateFromXML([System.Xml.XmlElement] $xml) {
        $this.Context().PopulateFromXml($xml, $this)
    }
	
}
class UIActionPlugin : UIAction{
	UIActionPlugin([ConfigAutomationContext] $context):base($context){
    }
    UIActionPlugin([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name):base($context, $_parent, $name, "UIActionPlugins"){	
    }
	UIActionPlugin([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name, [string] $referenceName):base($context, $_parent, $name, $referenceName){	
    }
	static [object] Requirements(){
		return [PSCustomObject]@{
			PrimaryKey = "Name";
			ElementNames =@("ActionPlugin")
		}
	}
	static [HasContext] FromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIActionPluginCollection] $actions){
	
		return [HasContext]::FromXML($context, $element, $actions, [UIActionPlugin])
    }
	[void] PopulateFromXML([System.Xml.XmlElement] $xml) {
        $this.Context().PopulateFromXml($xml, $this)
    }
	
}
class UIInputStrategyCollection : HasCollectionContext{

    UIInputStrategyCollection([ConfigAutomationContext] $context):base($context,"Input Strategies"){
    }
    UIInputStrategyCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $_parentScope):base($context, $_parentScope,"Input Strategies"){
    }
	[bool] Clean(){
		$allClean = $true
		foreach($strategy  in $this.Items()){
			$allClean = $strategy.Clean() -and $allClean
		}
		return $allClean
	}
    [UIInputStrategy] Add([string]$name, [string]$type){
		$this.Context().Warning("Input Strategy Collection - Adding Input Strategy $($name)")
        $inputStrategy = $this.Get($name, $false)
        if($inputStrategy -eq $null){
            $inputStrategy = [UIInputStrategy]::new($this.Context(), $name, [UIInputTypeReferenceCollection]::new($this.Context(), $type, $this.CurrentScope()))
            if(-not ($this.Add($inputStrategy))){
				$this.Error("Unable to add input strategy '{white}$($name){gray}' of type '{white}$($type){gray}'")
				return $null
			}
        }
        return $inputStrategy
    }
	[int] Order(){
		return $this.Priority()
	}
	[object] ExecuteStrategies([UIParameter] $parameter){
		$sortedStrategies = $this.Items()
		foreach($strategy in $sortedStrategies){
			$value = $strategy.ExecuteStrategy()
			

			if($value){
				return $value
			}
		}
		return $null
	}
	[void] PopulateFromXML([System.Xml.XmlElement] $xml) {
		
		if($xml.GetAttribute("Value")){
			$value = $xml.GetAttribute("Value")
			$quicky = [XML]"<Root><InputStrategy Type=`"DefaultValue`" DefaultValue=`"$($value)`"/></Root>"
			if(-not ($this.Add([UIInputStrategy]::FromXML($this.Context(), $quicky.Root.InputStrategy, $this)))){
				$this.Error("Unable to add input strategy from {white}Value{gray} attribute of parameter")
			}
		}
		if($xml.GetAttribute("DefaultValue")){
			$value = $xml.GetAttribute("DefaultValue")
			$quicky = [XML]"<Root><InputStrategy Type=`"DefaultValue`" DefaultValue=`"$($value)`"/></Root>"
			if(-not ($this.Add([UIInputStrategy]::FromXML($this.Context(), $quicky.Root.InputStrategy, $this)))){
				$this.Error("Unable to add input strategy from {white}DefaultValue{gray} attribute of parameter")
			}
		}
		if($xml.'#text'){
			$value = $xml.'#text'
			$quicky = [XML]"<Root><InputStrategy Type=`"DefaultValue`">$($value)</InputStrategy></Root>"
			if(-not ($this.Add([UIInputStrategy]::FromXML($this.Context(), $quicky.Root.InputStrategy, $this)))){
				$this.Error("Unable to add input strategy from {white}#text{gray} attribute of parameter")
			}
		}
		if($xml.'#cdata-section'){
			$value = $xml.'#cdata-section'
			$quicky = [XML]"<Root><InputStrategy Type=`"DefaultValue`"><![CDATA[`r`n$($value)`r`n]]></InputStrategy></Root>"
			if(-not ($this.Add([UIInputStrategy]::FromXML($this.Context(), $quicky.Root.InputStrategy, $this)))){
				$this.Error("Unable to add input strategy from {white}#text{gray} attribute of parameter")
			}
		}
		
        foreach($roots in $xml.ChildNodes) 
        {
			if($roots.LocalName -eq "InputStrategy") 
            {
				$this.Context().Warning("Input Strategy Collection - Found Input Strategy in Xml ")
				if(-not ($this.Add([UIInputStrategy]::FromXML($this.Context(), $roots, $this)))){
					$this.Error("Unable to add input strategy from xml:`r`n$($roots.Outerxml)`r`n")
				}
			}
            if($roots.LocalName -eq "InputStrategies") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "InputStrategy") {
						$this.Context().Warning("Input Strategy Collection - Found Input Strategies in Xml ")
                        if(-not ($this.Add([UIInputStrategy]::FromXML($this.Context(), $step, $this)))){
							$this.Error("Unable to add input strategy from xml:`r`n$($step.Outerxml)`r`n")
						}
                    }
                }
            }
        }
    }
}
class UIInputStrategy : HasContext{

	hidden [int] 				  $_priority
    hidden [UIInputTypeReference] $_type
	hidden [object]               $_cachedValue
    UIInputStrategy([ConfigAutomationContext] $context ):base($context){
    }
    UIInputStrategy([ConfigAutomationContext] $context, [String] $name, [int] $priority, [UIInputTypeReference] $type, [UIInputScopeBase] $_parentScope ):base($context, $_parentScope, $name){
		$this._type = $type
		$this._priority = $priority
    }
	[object] GetCacheValue(){
		return $this._cachedValue
	}
	[void] SetCacheValue([object] $cache){
		$this._cachedValue = $cache
	}
	[int] Priority(){
        return $this._priority
    }
    [UIInputTypeReference] InputType(){
        return $this._type
    }
	[bool] Clean(){
		$this._cachedValue = $null
		$definition = $this.InputType().Definition()
		return $definition.Clean($this)
	}
	[string] Shorthand(){
		return $this.InputType().Name()
	}
    [object] ExecuteStrategy(){
		if($this.GetCacheValue()){
			$this.Context().Log("Executing Strategy $($this.Name()) - Cached")
			return $this.GetCacheValue();
		}
		$this.Context().Action("InputTypes", "Executing Strategy {white}$($this.Name()){gray}")
		$definition = $this.InputType().Definition()
		if($definition){
			return $definition.GetInputValue($this)
		}
	
		return $null
    }
	[String] ToString(){
		return "$($this.Name()) $($this.InputType().Name()) - $($this.GetScopeString())"
	}
	static [UIInputStrategy] FromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIInputStrategyCollection] $strategies){
        if(-not ($element.GetAttribute("Type"))){
            throw "Not all the attributes to build the input strategy element were found:`r`n  Type:$($element.GetAttribute("Type"))"
        }

        if(-not $context){
            throw "Context is null which is being passed to UI Input Strategy inside of UI Strategy.FromXML"
        }
		
		$name = $element.GetAttribute("Name")
		$type = $element.GetAttribute("Type")
		$priority = $element.GetAttribute("Priority")
		
		# Fix Priority
		if(-not ([int]::TryParse($priority, [ref]$priority))){
			$priority = @($strategies.Items()).Count
		}

		# Fix Name
		if(-not $name){
			# $countExisting = @($strategies.Items() | Where {$_.InputType().Name() -ieq $type}).Count
			$name = "$($type)_$($priority)"
		}
		
        $strategy = [UIInputStrategy]::new($context, $name, $priority, [UIInputTypeReference]::new($context, $type, $strategies.CurrentScope()), $strategies.CurrentScope())
		if(-not $strategy.InputType().Definition()){
			$context.Error("Strategy {white}$($type){gray} was not found")
			return $null
		}
		$strategy.InputType().Definition().GetInputMetadata($strategy, $element)
		
		return $strategy
    }
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - -I n p u t   S c o p e  - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIInputScopeCollection : HasCollectionContext {

    [System.Collections.ArrayList] $_inputScopes
    [UIInputScopeBase] $_parentScope
	
	UIInputScopeCollection([ConfigAutomationContext] $context):base($context, "Scopes"){
	}
    UIInputScopeCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $_parentScope):base($context,$_parentScope, "Scopes"){
        $this._inputScopes = New-Object System.Collections.ArrayList
		$this._parentScope = $_parentScope
    }
	UIInputScopeCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $_parentScope, [string] $name):base($context,$_parentScope, $name){
        $this._inputScopes = New-Object System.Collections.ArrayList
		$this._parentScope = $_parentScope
    }
	[UIInputScopeBase] ParentScope(){
        return $this._parentScope
    }
	[UIInputScopeBase[]] Items($onlyChosenScopes){
		if($onlyChosenScopes){
			return $this._inputScopes | Where {$_.IsChosen()}
		}
		return $this._inputScopes
    }
    [UIInputScopeBase[]] Items(){
        return $this.Items($false)
    }
    [UIInputScopeBase] Get([string]$name){
        
        foreach($input in $this._inputScopes){
            if($input.Name() -eq $name){
                return $input
            }
        }
        return $null
    }
    [UIInputScopeBase] Add([string]$name){
		
        $inputScope = $this.Get($name)
        if($inputScope -eq $null){
            $inputScope = [UIInputScopeBase]::new($this.Context(), $name)
            $this._inputScopes.Add($inputScope)
        }
        return $inputScope
    }
    [UIInputScopeBase] Add([UIInputScopeBase]$scope){
		$inputScope = $this.Get($scope.Name())
        if($inputScope -eq $null){
            $this._inputScopes.Add($scope)
			$inputScope = $scope
        }
        return $inputScope
		
        $this._inputScopes.Add($scope)
		return $scope
    }
    [void] PopulateFromXML([System.Xml.XmlElement] $xml) {
        foreach($roots in $xml.ChildNodes) 
        {
			if($roots -is [System.Xml.XmlComment]){
				continue
			}
			if($roots -is [System.Xml.XmlText]){
				continue
			}
			# $roots = $this.Context().Extensions().ApplyExtension($roots)
            if($roots.LocalName -eq "Scopes" -or $roots.LocalName -eq "Scope.Scopes") 
            {
                foreach($step in $roots.ChildNodes)
                {
					if($step -is [System.Xml.XmlComment]){
						continue
					}
                    if($step.LocalName -eq "Scope") {
						# step = $this.Context().Extensions().ApplyExtension($step)
						$scope = [UIInputScope]::FromXML($this.Context(), $this.ParentScope(), $step)
						if(-not $scope){
							continue
						}
                        $scope = $this.Add($scope)
						
						$scope.PopulateFromXml($step)
                    }
                }
            }
        }
    }


}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - UIParameterTypeReferenceCollection Collection - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIInputReferenceCollection : HasContext{

    [System.Collections.ArrayList] $_parameterTypeReferences

    UIInputReferenceCollection([ConfigAutomationContext] $context):base($context){
        $this._parameterTypeReferences = New-Object System.Collections.ArrayList
    }
    [UIParameterTypeReference[]] Items(){
        return $this._parameterTypeReferences
    }
    [UIParameterTypeReference] Get([string]$name){
        
        foreach($parameterTypeReference in $this._parameterTypeReferences){
            if($parameterTypeReference.ParameterName() -eq $name){
                return $parameterTypeReference
            }
        }
        return $null
    }
}
class UIInputReference: HasContext {

    hidden [String] $_key
    UIInputReference([ConfigAutomationContext] $_context):base($_context){
    }
    UIInputReference([ConfigAutomationContext] $_context, [String] $key):base($_context){
        $this._key = $key
    }

    [string] Key(){
        return $this._key
    }

    [UIParameterTypeDefinition] Definition(){
        Write-Verbose "Referencing UI Input '$($this.Key())'"
		
        return $this.Context().ParameterTypes().Get($this.ParameterTypeName())
    }

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - -UIInput Collection - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIParameterCollection : HasCollectionContext {

    UIParameterCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope) :base($context, $scope, "Parameters"){
		$this.OverridesEnabled($true)
    }
	UIParameterCollection([ConfigAutomationContext] $context) :base($context, "Parameters"){
		$this.OverridesEnabled($true)
    }
	
	[object] Extract([array] $expectedParameters){
		$returnObj = new-object psobject
		foreach($expectedParameter in $expectedParameters){
			$parameter = $this.Get($expectedParameter, $true)
			if(-not $parameter){
				continue
			}

			$name  = $parameter.ParameterName()
			$value = $parameter.Value($false)
			if(-not $value){
				continue
			}

			$returnObj | Add-Member -MemberType NoteProperty -Name $name -Value $value -TypeName String -Force
		}

		return $returnObj
	}
	
	[HasContext] Get([string]$name, [bool] $IncludeParent , [bool] $isOverride, [bool] $ignoreOverride, [bool] $ignoreCurrentScopeCheck, [bool] $includeInvalidItems, [bool] $includeHiddenItems){
		if($this._lock){
			return $null
		}
		
		$this._lock = $true
		#TEMP $this.Action("ParametersOverride", "Override Get {magenta}$name{gray}")
		$this.PushIndent("ParametersOverride")
		$this._lock = $false
		
		$original = $this.InnerGet($name, $IncludeParent, $isOverride, $ignoreOverride, $ignoreCurrentScopeCheck, $includeInvalidItems, $includeHiddenItems)
		if(-not $original -and [Object]::ReferenceEquals($this.CurrentScope(), $this.Context().CurrentScope())){
		
			$this._lock = $true
			#TEMP $this.Action("ParametersOverride", "Didnt find so adding... {magenta}$name{gray}")
			$this.PushIndent("ParametersOverride")
			$this._lock = $false
			
			$original = $this.Add($name, "String")
			
			$this._lock = $true
			$this.PopIndent("ParametersOverride")
			$this._lock = $false
			
		}
		
		$this._lock = $true
		$this.PopIndent("ParametersOverride")
		$this._lock = $false
		
		return $original
	}
	[bool] Clean(){
		$allClean = $true
		foreach($parameter in $this.Items()){
			$allClean = $parameter.Clean() -and $allClean
		}
		
		return $allClean
	}
	[bool] ValidateAllParameters(){
		
		$keys = $this.Items() | Foreach { $_.Name() }
		return $this.Validate($keys, $true, $true, $false)
	}
	[bool] ValidateRequiredParameters(){
		
		$passed = $true
		foreach($parameter in $this.CurrentScope().Parameters().Items()){
			if($parameter.IsRequired() -and $parameter.IsMissing()){
				$this.Error("Parameters", "Exepcted parameter {white}'$($parameter.Name())'{gray} to exists but was missing in scope {white}$($this.CurrentScope().FullName()){gray}")
				$passed= $false
			}
		}	
		return $passed

	}
	[bool] Validate([array] $expectedParameters){
		return $this.Validate($expectedParameters, $true, $true, $true)
	}
	[bool] Validate([array] $expectedParameters, [bool] $throwErrors, [bool] $expectValues, [bool] $includeParents){
		
		$this.PushIndent()
		$isValid = $true
		foreach($expectedParameter in $expectedParameters){
			$parameter = $this.Get($expectedParameter, $includeParents)
			if(-not $parameter){
				if($throwErrors){
					$this.Error("Parameters", "Exepcted parameter {white}'$($expectedParameter)'{gray} to exists but was not even defined in scope {white}$($this.CurrentScope().FullName()){gray}")
				}
				else{
					$this.Context().Warning("Parameters", "Exepcted parameter {white}'$($expectedParameter)'{gray} to exists but was not even defined in scope {white}$($this.CurrentScope().FullName()){gray}")
				}
				$isValid = $false
				continue
			}


			if(-not $expectValues){
				continue;	
			}

			$value = $parameter.Value()
			if(-not $value){
				if($throwErrors){
					$this.Error("Parameters", "Exepcted parameter {white}'$($expectedParameter)'{gray} to have a value but no value was found {white}$($this.CurrentScope().FullName()){gray}")
				}
				else{
					$this.Context().Warning("Parameters", "Exepcted parameter {white}'$($expectedParameter)'{gray} to have a value but no value was found {white}$($this.CurrentScope().FullName()){gray}")
				}
				
				$parameter.IsMissing($true)
				$isValid = $false
			}
			
			if(-not $this.ValidateValue($value, "Parameter {magenta}$($expectedParameter){white}")){
				# $parameter.IsMissing($true)
				$isValid = $false
			}
		}
		# $this.Display("Validating Parameters: $($expectedParameter -join ',') - {green}Completed{gray}")
		$this.PopIndent()
		return $isValid
	}
    [string] ValidateKeysAreEqual([UIParameterCollection] $parameters, [string] $nameOfFirstCollection, [string]$nameOfSecondCollection){
        $finalString = ""
        foreach($parameter in $this.Items()){
            if(-not $parameters.Get($parameter.ParameterName())){
                $finalString+="Parameter '$($parameter.ParameterName())' was found in '$($nameOfFirstCollection) but not in '$($nameOfSecondCollection)'"
            }
        }

        foreach($parameter in $parameters.Items()){
            if(-not $this.Get($parameter.ParameterName())){
                $finalString+="Parameter '$($parameter.ParameterName())' was found in '$($nameOfSecondCollection) but not in '$($nameOfFirstCollection)'"
            }
        }

        if([String]::IsNullOrEmpty($finalString)){
            return $null
        }
        return $finalString
    }
    
	
    [UIParameter] Add([string]$name, [string]$type){
		$this.Context().Log("Parameters", "Adding Parameter {white}$($name){gray} of type {white}$($type){gray}") 
		
		if(-not $this.Context()){
			throw "Context is null which is being passed to UI Parameter inside of UI UIParameterCollection.Add"
		}

		$parameter = [UIParameter]::new($this.Context(), $this.CurrentScope(), $name)
		$parameter._properties.Add("Type", $type)
		$parameter.InitialProps($parameter._properties, $null, $null, $null)
		$this.Add($parameter)
		
        return $parameter
    }
    [void] ValidateInput(){
        foreach($parameter in $this.Items()){

			$value = $parameter.Value()
            $this.context.Log().Log("Validating Input $($parameter.ParameterName()) whichs value is $($value)")
            # Validate input value with the type that it is associated to
            $parameter.ParameterType().Definition().ValidateInput($value, $parameter)
        }
    }
    
    static [UIParameterCollection] FromParameterizedString([ConfigAutomationContext] $context, [String] $inputString, [UIInputScopeBase]$scope){
        if(-not $context){
            throw "Context is null which is being passed to UI Parameter Collection inside of UIParameterCollection.FromParameterizedString"
        }
        $parameters = [UIParameterCollection]::new($context, [UIInputScopeBase]::new($context, $null, "Parameterized", "Parameterized"))
        $parameters.PopulateFromParameterizedString($inputString)

        return $parameters
    }
	
	static [object] Requirements(){
		return [PSCustomObject]@{
			ParentElementNames =@("Parameters");
			ChildElementNames = @("Parameter");
			ChildType = [UIParameter]
		}
	}
    [void] PopulateFromParameterizedString([String] $inputString){
        $matches = ([regex]'[$][{(]([^)\$]*?)[})]').Matches($inputString)
        foreach($match in $matches){
            $varName = $match.Groups[1].Value
            $this.Add($varName, "String")
        }
		$this.Context().Warning("Parameter Collection (PopulateFromParameterizedString) ")
    }
	
}
class UIParameter : HasContext{

	hidden [bool]   $_isRequired
	hidden [bool]   $_isMissing
	hidden [string] $_cached
    hidden [UIParameterTypeReference] $_type
	hidden [UIInputStrategyCollection] $_strategies
	UIParameter([ConfigAutomationContext] $_context) : base($_context){
		# Write-Color "{magenta}P A R E M E T E R {white}$($this.Name()){gray} - $($this._generatedFromFile)"
    }
    UIParameter([ConfigAutomationContext] $_context, [UIInputScopeBase] $scope, [String] $name) : base($_context, $scope, $name){
		$this._isRequired = $false
		$this._isMissing  = $false
		$this._strategies = [UIInputStrategyCollection]::new($_context, $scope)
		# Write-Color "{magenta}P A R E M E T E R {white}$($this.Name()){gray} - $($this._generatedFromFile)"
    }
	[bool] RefreshSession(){
		if(-not ([HasContext]$this).RefreshSession()){
			return $false
		}
		$this._isRequired = $false
		$this._isMissing  = $false
		$this._cached     = $null
		return $true
		# return $this.InputStrategies().Clean()
	}
	[bool] InitialProps([hashtable] $props, [string] $bodyContent, [System.Xml.XmlElement] $element, [string] $location){
		#TEMP $this.Action("Initial Props")
		if(-not ([HasContext]$this).InitialProps($props, $bodyContent,$element, $location)){
			return $false
		}
		if(-not $props.ContainsKey("Type")){
			$props.Add("Type","String")
		}
		if(-not $props.ContainsKey("Type")){
			$this.Error("Requires attribute '{white}Type{gray}'")
			return $false
		}
		if($props.ContainsKey("Type")){
			$this._type = [UIParameterTypeReference]::new($this.Context(), $props["Type"])
		}
		if($element){
			$this.Context().PopulateFromXml($element, $this)
		}
		
		return $true
		 
	}
	[bool] UpdateProps([hashtable] $props, [string] $bodyContent, [System.Xml.XmlElement] $element, [string] $location){
		if(-not ([HasContext]$this).UpdateProps($props, $bodyContent, $element, $location)){
			return $false
		}
		if($props.ContainsKey("Type")){
			if($this.ParameterType() -and $this.ParameterType().ParameterTypeName() -ne $props["Type"]){
				$this.Error("Attempting to set parameter type to a different type then it was already defined in a separate definition, Currently {magenta}$($this.ParameterType().ParameterTypeName()){gray} wanting to change to {magenta}$($props["Type"]){gray}")
				return $false
			}
			
			$this._type = [UIParameterTypeReference]::new($this.Context(), $props["Type"])
		}
		$this.Context().PopulateFromXml($element, $this)
		return $true
	}
	
	
	[bool] IsRequired(){
		return $this._isRequired
	}
	
	[void] IsRequired([bool] $_isRequired){
		
		if($_isRequired -and (-not $this._isRequired)){
			$this.Context().AddRequiredParammeter($this)
		}
		elseif(-not $_isRequired -and ($this._isRequired)){
			$this.Context().RemoveRequiredParammeter($this)
		}
		$this._isRequired = $_isRequired
	}
	[bool] IsMissing(){
		return $this._isMissing
	}
	
	[void] IsMissing([bool] $_isMissing){
		$this._isMissing = $_isMissing
	}
	[UIInputStrategyCollection] InputStrategies(){
        return $this._strategies
    }
    [string] ParameterName(){
        return $this._name
    }
    [UIParameterTypeReference] ParameterType(){
        return $this._type
    }
	[bool] Clean(){
		$this.Context().Action("Parameters", "Clearing Parameter {white}$($this.Name()){gray}")
		$this.IsRequired($false)
		return $this.InputStrategies().Clean()
	}
	
	static [object] Requirements(){
		return [PSCustomObject]@{
			ElementNames = @("Parameter");
			PrimaryKey = "Name"
		}
	}
	[String] ToString(){
		$parameterName = $this.ParameterName()
		$parameterName = "{0,-50}" -f $parameterName
		$scopeName = "{0,-50}" -f $($this.CurrentScope().FullName())

		$value = $this.Value()
		$parameterColor = "white"
		$inputColor     = "gray"
		if(-not $value){
			 $value = ""
			$inputColor     = "white"
			$parameterColor = "red"
		}
		$value = "{0,-50}" -f $value
		if($value.length -gt 50){
			# $value = "{0,-50}" -f "..."
		}
		$value = $value -replace '([`$][{(]([^)\`$]*?)[})])','{red}$1{white}'
		$content = "{$($inputColor)}Input {$($parameterColor)}$($parameterName){white}$($value){gray}"
		
		# $content += $this._strategies | Foreach {"  "+$_.ToString().Replace("`r`n","`r`n  ")+"`r`n"}
		
		return $content
	}
	[object] Value(){
		return $this.Value($true)
	}
    [object] Value([bool] $expectToExists){
		if($expectToExists){
			$this.IsRequired($true)
		}
		
		$value = $this.InputStrategies().ExecuteStrategies($this)
		
		$parameterType = $this.ParameterType().Definition()
		if(-not $parameterType){
			$this.Error("Parameter Type {white}$($this.ParameterType().ParameterTypeName()){gray} was not found")
			return $null
		}
		if(-not $parameterType.ValidateInput($value, $this)){
			$this.Error("Parameter {white}$($this.Name()){gray} failed validation against its type '{white}$($parameterType.ParameterTypeName()){gray}'")
			return $null
		}
		$transformedValue = $parameterType.TransformInputValue($value, $this)
		
		if(-not $transformedValue -and -not $this.IsMissing() -and $expectToExists){
			$this.IsMissing($true)
		}
		elseif($transformedValue -and $this.IsMissing()){
			$this.IsMissing($false)
		}
		return $transformedValue
	}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - -UIInput Collection - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UITemplateCollection : HasCollectionContext {

    UITemplateCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope) :base($context, $scope, "Templates"){
		$this.OverridesEnabled($true)
    }
	UITemplateCollection([ConfigAutomationContext] $context) :base($context, "Templates"){
		$this.OverridesEnabled($true)
    }
	
	static [object] Requirements(){
		return [PSCustomObject]@{
			ParentElementNames =@("Templates");
			ChildElementNames = @("Template");
			ChildType = [UITemplate]
		}
	}
	
}
class UITemplate : HasContext{

	[System.Collections.ArrayList] $_xmlElements
	UITemplate([ConfigAutomationContext] $_context) : base($_context){
		$this._xmlElements = new-object System.Collections.ArrayList
    }
    UITemplate([ConfigAutomationContext] $_context, [UIInputScopeBase] $scope, [String] $name) : base($_context, $scope, $name){
		$this._xmlElements = new-object System.Collections.ArrayList
    }
	[void] AddXmlDefinition([System.Xml.XmlElement] $xmlDefinition, [string] $location){
	
		if(-not $xmlDefinition){
			return
		}

		$currentFormated = ($xmlDefinition.Outerxml | Format-Xml)
		foreach($saved in $this._savedXmlDefinitions){
			$savedFormated = ($saved.Xml.Outerxml | Format-Xml)
			if($currentFormated -eq $savedFormated){
				#$this.Display("Skipping ingestion of xml since it has already been injected in the past")
				return
			}
		}
			
		# Wrapped XmlDefinition
		$this._savedXmlDefinitions.Add(@{Xml = $xmlDefinition.CloneNode($true); Location = $location})
		
		# Set the normal xml definition
		$this._xmlDefinitions.Add(@{Xml = $xmlDefinition.CloneNode($true); Location = $location})
		
		return
	}
	[bool] InitialProps([hashtable] $props, [string] $body, [System.Xml.XmlElement] $element, [string] $location){
		if(-not ([HasContext]$this).InitialProps($props, $body, $element, $location)){
			return $false
		}
		if(-not $element){
			$this.Error("Element was needed for a template to work properly")
			return $false
		}
		$this._xmlElements.Add($element.CloneNode($true))
		return $true
	}
	[bool] UpdateProps([hashtable] $props, [string] $body, [System.Xml.XmlElement] $element, [string] $location){
		if(-not ([HasContext]$this).UpdateProps($props, $body, $element, $location)){
			return $false
		}
		if(-not $element){
			$this.Error("Element was needed for a template to work properly")
			return $false
		}
		$this._xmlElements.Add($element.CloneNode($true))
		return $true
	}
	[bool] Load([UIImportTemplate] $importTemplate){

		if($this.Context().ExitRequested()){
			$this.Warning("User Exiting...")
			return $false
		}
		$importTemplate.LoadChildren()
		$isValid = $true
		$actualPlaceholdersMet = $false
		
		
		
		# Load up This XML
		$thisXml = "<Root>"
		foreach($xmlDefinition in $this.SavedXmlDefinitions()){
			$thisXml += $xmlDefinition.Xml.InnerXml
		}
		$thisXml += "</Root>"
		[XML]$thisXmlDoc = $thisXml
		
		# Load up Template Xml
		$templateXml = "<Root>"
		foreach($xmlDefinition in $importTemplate.SavedXmlDefinitions()){
			$templateXml += $xmlDefinition.Xml.InnerXml
		}
		$templateXml += "</Root>"
		[XML]$templateXmlDoc = $templateXml
		
		$thisXmlDoc.SelectNodes("//*[@RepeatFor]") | Foreach {
			$templateRepeater = $_
			$repeatFor = $templateRepeater.GetAttribute("RepeatFor")
			$repeaters = $templateXmlDoc.SelectNodes("//$($repeatFor)")
			foreach($repeater in $repeaters){
				$repeatContent = $repeater.InnerText
				$newRepeater = $templateRepeater.CloneNode($true)
				foreach($attr in $newRepeater.Attributes){
					$newRepeater.SetAttribute($attr.Name, $newRepeater.GetAttribute($attr.Name).Replace("@($($repeatFor))",$repeatContent))				
				}
				$newRepeater.RemoveAttribute("RepeatFor")
				$templateRepeater.ParentNode.InsertBefore($newRepeater, $templateRepeater)
			}
			$templateRepeater.ParentNode.RemoveChild($templateRepeater)
		}
		
		# Search for placeholders
		$placeHoldersActual      = $templateXmlDoc.SelectNodes("//Placeholder")
		$placeHoldersExpected    = $thisXmlDoc.SelectNodes("//RenderPlaceholder")
		
		foreach($placeHolder in $placeHoldersActual){
				
			$placeholderName = $placeHolder.GetAttribute("Name")
			if(-not $placeholderName){
				$this.Error("Placeholder has no name attribute in {white}import template{gray} '{magenta}$($importTemplate.Name()){gray}' ")
				$isValid = $false
				continue
			}
			
			if(-not ($placeHoldersExpected | Where {$_.GetAttribute("Name")} | Where {$_.Name -eq $placeholderName})){
				$this.Error("Placeholder '{white}$($placeHolderName){gray}' was not found in the expected placeholders in template '{white}$($this.Name()){gray}`r`n$($templateXmlDoc.Outerxml | Format-Xml)'")
				$isValid = $false
				continue
			}
		}
		
		
		
		foreach($placeHolder in $placeHoldersExpected){
			
			$placeholderName = $placeHolder.GetAttribute("Name")
			$isOptional      = $placeHolder.GetAttribute("Optional")
			$isContainer      = $placeHolder.GetAttribute("Container")
			
			if(-not $placeholderName){
				$this.Error("Placeholder has no name attribute in {white}template{gray} '{magenta}$($this.Name()){gray}'  ")
				$isValid = $false
				continue
			}
			
			$actualPlaceholder = ($placeHoldersActual | Where {$_.GetAttribute("Name")} | Where {$_.Name -eq $placeholderName})
			if($isOptional -ine 'true' -and -not $actualPlaceholder){
				$this.Error("[Required] Placeholder '{white}$($placeHolderName){gray}' was not found in the actual placeholders in import template '{white}$($importTemplate.Name()){gray}'")
				$isValid = $false
				continue
			}
			
			
			foreach($childNode in $actualPlaceholder.ChildNodes){
				
				$new_childNode = $thisXmlDoc.ImportNode($childNode, $true)
				# $this.Display("{white}placeHolder: `r`n{gray}$($placeHolder.Outerxml | Format-Xml){gray}")
				# $this.Display("{white}new_childNode: `r`n{gray}$($new_childNode.Outerxml | Format-Xml){gray}`r`n`r`n")
				if($isContainer -ieq "true"){
					$placeHolder.AppendChild($new_childNode)
				}
				else{
					$placeHolder.ParentNode.InsertBefore($new_childNode, $placeHolder)
				}
			}
			if(-not ($isContainer -ieq "true")){
				$placeHolder.ParentNode.RemoveChild($placeHolder)
			}
		}
		
		if(-not $isValid){
			return $false
		}
		
		$xmlTxt = $importTemplate.ParameterizeString($thisXmlDoc.Outerxml, $false, "@")
		
		$scope = $importTemplate.CurrentScope().ParentScope()
		if(-not $scope){
			$this.Error("Expected ImportTemplate to have a parent scope for importing of the template but was there was not parent scope... Why?")
			return $false
		}

		if(-not $this.ValidateValue($xmlTxt, "XML Content for $($scope.FullName())", "@", $true)){
			$this.Error("Validation of the XML Content failed")
			return $false
		}
		
		[XML]$finalCurrentXmlDefinition = $xmlTxt
		
		$this.Context().PushScope($importTemplate)
		$this.Context().PushLocation($importTemplate._generatedFromFile)
		# $this.Display("Loading Template {white}$($this.Name()){gray} for scope {white}$($scope.FullName()){gray}`r`n`r`n{magenta}Template XML{gray}:`r`n$($currentXmlDefinition.OuterXml)")
		$this.Context().PopulateFromXml($finalCurrentXmlDefinition.FirstChild, $scope)
		$this.Context().PopLocation()
		$this.Context().PopScope()
		$scope.LoadChildren()
		
		return $true
	}
	
	static [object] Requirements(){
		return [PSCustomObject]@{
			ElementNames = @("Template");
			PrimaryKey = "Name"
		}
	}
}
class UIImportTemplateCollection : HasCollectionContext {

    UIImportTemplateCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope) :base($context, $scope, "ImportTemplates"){
		# $this.OverridesEnabled($true)
    }
	UIImportTemplateCollection([ConfigAutomationContext] $context) :base($context, "ImportTemplates"){
		# $this.OverridesEnabled($true)
    }
	
	[bool] Import(){
		if($this.Context().ExitRequested()){
			$this.Warning("User Exiting...")
			return $false
		}
		
		$isValid = $true
		
		if($this._properties["SkipLoading"] -ieq "true"){
			return $true
		}
		while(-not $this.HasBeenLoaded()){
			foreach($import in $this.Items()){
				$isValid = $import.Import() -and $isValid
			}	
		}
		
		if($this.CurrentScope().ParentScope()){
			return $this.CurrentScope().ParentScope().Get("ImportTemplates").Import() -and $isValid
		}
		
		return $isValid
	}
	[bool] HasBeenLoaded(){
		$isLoaded = $true
		foreach($item in $this.Items()){
			$isLoaded = $item.HasBeenLoaded() -and $isLoaded
		}
		return $isLoaded
	}
	static [object] Requirements(){
		return [PSCustomObject]@{
			ParentElementNames =@("ImportTemplates");
			ChildElementNames = @("ImportTemplate");
			ChildType = [UIImportTemplate]
		}
	}
	
}
class UIImportTemplate :  UIInputScope{

	[bool] $_hasBeenImported = $false
	UIImportTemplate([ConfigAutomationContext] $context):base($context){
		$this.Hierarchical($false)
    }
	UIImportTemplate([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name):base($context, $_parent, $name, "ImportTemplates"){
		$this.Hierarchical($false)
	}
    UIImportTemplate([ConfigAutomationContext] $context, [UIInputScopeBase] $_parent, [String] $name, [string] $referenceName):base($context, $_parent, $name, $referenceName){
		$this.Hierarchical($false)
    }
	[bool] InitProps([hashtable] $props, [string] $body, [System.Xml.XmlElement] $element, [string] $location){
		if(-not (([HasContext]$this).InitProps($props, $body, $element, $location))){
			return $false
		}
		
		# Need to fix, basicly I dont want this to happen if it is a shallow pass... 
		# A short cut is to check if "Ref" is in the initial creation, which indicates that
		# it is a shallow pass since shallow passes are specificly for ref elements
		if( (-not $props["Ref"]) -and ($props["LoadNow"] -ieq "true")){
			$this._hasBeenImported = $false
			$this.Display("Item Init: Importing {white}$($this.Name()){gray} now since {magenta}LoadNow{gray} was set to {white}true{gray}")
			return $this.Import()
		}
		return $true
	}
	[bool] UpdateProps([hashtable] $props, [string] $body, [System.Xml.XmlElement] $element, [string] $location){
		if(-not (([HasContext]$this).UpdateProps($props, $body, $element, $location))){
			return $false
		}
		
		if($props["LoadNow"] -ieq "true"){
			$this._hasBeenImported = $false
			# $this.Display("Item Update: Importing {white}$($this.Name()){gray} now since {magenta}LoadNow{gray} was set to {white}true{gray}")
			return $this.Import()
		}
		
		return $true
		
	}
	[bool] RefreshSession(){
		if(-not ([HasContext]$this).RefreshSession()){
			return $false
		}
		$this._hasBeenImported = $false
		return $true
	}
	[string] TemplateId(){
		$templateId = $this._properties["TemplateId"]
		if(-not $templateId){
			$this.Error("TemplateId was not found in import template definition")
		}
		return $templateId
	}
	
	[bool] HasBeenLoaded(){
		return $this._hasBeenImported
	}
	[bool] Import(){
		if($this.Context().ExitRequested()){
			$this.Warning("User Exiting...")
			return $false
		}
		if($this._hasBeenImported){
			return $true
		}
		
		$this.LoadChildren()
		
		$this._hasBeenImported = $true
		
		
		$scope = $this.CurrentScope().ParentScope()
		if(-not $scope){
			$this.Error("Expected ImportTemplate to have a parent scope for importing of the template but was there was not parent scope... Why?")
			return $false
		}
		
		$this.Context().PushScope($this)
		$this.Context().PushLocation($this._generatedFromFile)
		$this.Context().PushParmeterizingEnabled($true)
		$this.PushIndent()
		$this.Display("{gray}Importing {white}$($this.Name()){gray} into scope {white}$($scope.FullName()){gray}")
		$this.PopIndent()
		
		$template = $this.CurrentScope().Get("Templates").Get($this.TemplateId())
		if(-not $template){
			$this.Error("Template {white}$($this.TemplateId()){gray} was not found so failed to import template {white}$($this.Name()){gray}")
			$this.Context().PopParmeterizingEnabled()
			$this.Context().PopLocation()
			$this.Context().PopScope()
			return $false
		}
		if(-not $template.Load($this)){
			$this.Error("Importing Template {white}$($this.Name()){gray} failed")
			$this.Context().PopParmeterizingEnabled()
			$this.Context().PopLocation()
			$this.Context().PopScope()
			return $false
		}
		$this.Context().PopParmeterizingEnabled()
		$this.Context().PopLocation()
		$this.Context().PopScope()
		
		
		
		return $true
	}
	
	static [object] Requirements(){
		return [PSCustomObject]@{
			ElementNames = @("ImportTemplate");
			PrimaryKey = "Name"
		}
	}
	static [UISection] FromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element, [UIImportTemplateCollection] $actions){
		return [HasContext]::FromXML($context, $element, $actions, [UIImportTemplate])
    }
	[void] PopulateFromXML([System.Xml.XmlElement] $xml) {
        $this.Context().PopulateFromXml($xml, $this)
    }
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - -UIResources Collection - - - - - - - - - - - - - - 
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIResourceCollection : HasCollectionContext {

    [System.Collections.ArrayList] $_resources

	UIResourceCollection([ConfigAutomationContext] $context) :base($context, "Resources"){
        $this._resources = New-Object System.Collections.ArrayList
    }
    UIResourceCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope) :base($context, $scope, "Resources"){
        $this._resources = New-Object System.Collections.ArrayList
    }
    [UIResource[]] Items(){
        return $this._resources
    }
    
    [UIResource] Get([string]$name){
        
        foreach($resource in $this._resources){
            if($resource.Name() -eq $name){
                return $resource
            }
        }
		
		if($this.CurrentScope().ParentScope()){
			return $this.CurrentScope().ParentScope().Resources().Get($name)
		}
        return $null
    }
    [UIResource] Add([string]$name, [string]$type){
        $resource = $this.Get($name)
        if($resource -eq $null){

            if(-not $this.Context()){
                throw "Context is null which is being passed to UI Resource inside of UI UIResourceCollection.Add"
            }

            $resource = [UIResource]::new($this.Context(), $name, [UIResourceTypeReference]::new($this.Context(), $type))
            $this._resources.Add($resource)
        }

        if($resource.ResourceType().ResourceTypeName() -ne $type){
            throw "UIResource '$($name)' is already defined with different type '$($resource.ResourceType().ResourceTypeName())' != '$($type)'"
        }

        return $resource
    }
    
    [void] PopulateFromXML([System.Xml.XmlElement] $xml) {
		
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "Resources") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "Resource") {
                        $this._resources.Add([UIResource]::FromXML($this.Context(), $step))
                    }
                }
            }
        }
    }
	
}
class UIResource : HasContext{

    
    hidden [UIResourceTypeReference] $_type
	UIResource([ConfigAutomationContext] $_context) : base($_context){
    }
    UIResource([ConfigAutomationContext] $_context, [String] $name, [UIResourceTypeReference] $type) : base($_context, $name){
        $this._name = $name
        $this._type = $type
    }
    [UIResourceTypeReference] ResourceType(){
        return $this._type
    }
	[String] ToString() {
		return "$($this.Name()) $($this.ResourceType().ToString())"
	}
    
    static [UIResource] FromXML([ConfigAutomationContext] $context, [System.Xml.XmlElement] $element){
        if(-not ($element.GetAttribute("Name") -and $element.GetAttribute("Type"))){
            throw "Not all the attributes to build the parameter element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n  Type:$($element.GetAttribute("Type"))"
        }

        if(-not $context){
            throw "Context is null which is being passed to UI Parameter inside of UI Parameter.FromXML"
        }
        $resource = [UIResource]::new($context, $element.GetAttribute("Name"), [UIResourceTypeReference]::new($context, $element.GetAttribute("Type")))
		$resource.ResourceType().Definition().PopulateFromXmlForResource($element, $resource)
		return $resource
    }
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - -UIParameterTypeCollection Collection - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIParameterTypeDefinitionCollection: HasCollectionContext {

	UIParameterTypeDefinitionCollection([ConfigAutomationContext] $context) : base($context, "Parameter Types"){
    }
    UIParameterTypeDefinitionCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope) : base($context, $scope,"Parameter Types"){
    }
    [void] PopulateFromXML([System.Xml.XmlElement] $xml){
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "ParameterTypes") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "ParameterType") {
                        $this._parameterTypes.Add([UIParameterTypeDefinition]::FromXML($this.Context(), $step))
                    }
                }
            }
        }
        
    }
}

class UIParameterTypeDefinition: UITypeDefinition {

	UIParameterTypeDefinition([ConfigAutomationContext] $_context) : base($_context){
    }
    UIParameterTypeDefinition([ConfigAutomationContext] $_context, [String] $name, [string] $contentType, [String] $content, [UIInputScopeBase] $scope) : base($_context, $name, $contentType, $content, "Action Type", $scope){
		
    }

    [string] ParameterTypeName(){
        return $this.Name()
    }

    [bool] ValidateInput([String] $input, [UIParameter] $parameter){
        $context = $this.Context() 
        if(-not $context){
            throw "Context is null when calling UIParameterTypeDefinition"
        }
        return $this.InvokeCallback("Validate", @($context, $input, $parameter))
    }
    [object] TransformInputValue([String] $input, [UIParameter] $parameter){
        $context = $this.Context()
        if(-not $context){
            throw "Context is null when calling UIParameterTypeDefinition"
        }
        return $this.InvokeCallback("TransformInput", @($context, $input, $parameter))
    }
    [String] TransformParameterToCodeType(){
        $context = $this.Context()
        if(-not $context){
            throw "Context is null when calling UIParameterTypeDefinition"
        }

        return $this.InvokeCallback("TransformParameterType", @($context))
    }
    [String] TransformParameterToCodeUse([object] $inputObj){
        $context = $this.Context()
        if(-not $context){
            throw "Context is null when calling UIParameterTypeDefinition"
        }
        return $this.InvokeCallback("TransformParameterUse", @($context, $inputObj))
    }
    [String] GenerateDynamicParameters([System.Management.Automation.RuntimeDefinedParameterDictionary] $dynamicParameters, [UIParameter] $parameter){
        $context = $this.Context()
        if(-not $context){
            throw "Context is null when calling UIParameterTypeDefinition"
        }
        return $this.InvokeCallback("GenerateDynamicParameters", @($context, $dynamicParameters, $parameter))
    }
    static [UIParameterTypeDefinition] FromXML([ConfigAutomationContext] $_context, [System.Xml.XmlElement] $element, [UIInputScopeBase] $scope){
        return [UITypeDefinition]::FromXml($_context, $element, [UIParameterTypeDefinition], $scope)
    }
	[String] ToString(){
		return $this.ParameterTypeName()
	}
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - -UILoggingTypeDefinitionCollection Collection - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UILoggingTypeDefinitionCollection: HasCollectionContext {

	UILoggingTypeDefinitionCollection([ConfigAutomationContext] $context) : base($context, "Logging Types"){
    }
    UILoggingTypeDefinitionCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope) : base($context, $scope,"Logging Types"){
    }
    [void] PopulateFromXML([System.Xml.XmlElement] $xml){
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "LoggingTypes") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "LoggingType") {
                        if(-not ($this.Add([UILoggingTypeDefinition]::FromXML($this.Context(), $step, $this.CurrentScope())))){
							$this.Error("Failed to add logging type from xml snippet:`r`n$($step.Outerxml)")
						}
                    }
                }
            }
        }
        
    }
}

class UILoggingTypeDefinition: UITypeDefinition {
	hidden [UIParameterCollection] $_parameters
	
	UILoggingTypeDefinition([ConfigAutomationContext] $_context) : base($_context){
		$this._parameters     = [UIParameterCollection]::new($_context, $_context.CurrentScope())
    }
    UILoggingTypeDefinition([ConfigAutomationContext] $_context, [String] $name, [string] $contentType, [String] $content, [UIInputScopeBase] $scope) : base($_context, $name, $contentType, $content, "Logging Type", $scope){
		$this._parameters     = [UIParameterCollection]::new($_context, $_context.CurrentScope())
	}
	[UIParameterCollection] Parameters(){
		return $this._parameters
	}
	[void] Init([UILogger] $logger){
		$this.InvokeCallback("Init", @($($this.Context()), $logger), $false)
    }
	[void] Milestone([string] $message, [string] $type, [UILogger] $logger){
		$this.InvokeCallback("Milestone", @($($this.Context()), $logger, $message, $type), $false)
    }
	[void] Log([string] $message, [UILogger] $logger){
		$this.InvokeCallback("Log", @($($this.Context()), $logger, $message), $false)
    }
    [void] Indent([int] $amount, [UILogger] $logger){
		$this.InvokeCallback("Indent", @($($this.Context()), $logger, $amount), $false)
    }
    [string] LoggingTypeName(){
        return $this.Name()
    }
    static [UILoggingTypeDefinition] FromXML([ConfigAutomationContext] $_context, [System.Xml.XmlElement] $element, [UIInputScopeBase] $scope){
        return [UITypeDefinition]::FromXml($_context, $element, [UILoggingTypeDefinition], $scope)
    }
	[String] ToString(){
		return $this.LoggingTypeName()
	}
}
class UILoggingTypeReference : HasContext {

    hidden [String] $_typeName
    UILoggingTypeReference([ConfigAutomationContext] $_context) : base($_context) {
    }
    UILoggingTypeReference([ConfigAutomationContext] $_context, [String] $name) : base($_context) {
        $this._typeName = $name
    }
	UILoggingTypeReference([ConfigAutomationContext] $_context, [UIInputScopeBase] $scope, [String] $name) : base($_context,$scope, "NOT_SET") {
        $this._typeName = $name
    }
    [string] LoggingTypeName(){
        return $this._typeName
    }

    [UILoggingTypeDefinition] Definition(){
        # Write-Host "Referencing UI Extension Type '$($this.ExtensionTypeName())'"
		
        return $this.Context().LoggingTypes().Get($this.LoggingTypeName())
    }
	[String] ToString(){
		return $this.LoggingTypeName()
	}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - -UILoggerCollection Collection - - - - - - - - - - - - - - 
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UILoggerCollection : HasCollectionContext {
	hidden [bool] $_skipLogger = $false
	UILoggerCollection([ConfigAutomationContext] $context) :base($context, "Loggers"){
    }
    UILoggerCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope) :base($context, $scope, "Loggers"){
    }
    [void] Milestone([string] $message, [string] $type){
		if($this._skipLogger){
			return
		}
		$this._skipLogger = $true
		foreach($logger in $this.Items()){
			$logger.Milestone($message, $type)
		}
		if($this.CurrentScope().Loggers().Id() -ne $this.Id()){
			$this.CurrentScope().Loggers().Milestone($message, $type)
		}
		if($this.CurrentScope().ParentScope()){
			$this.CurrentScope().ParentScope().Milestone($message, $type)
		}
		$this._skipLogger = $false
    }
	[void] Log([string] $message){
		if($this._skipLogger){
			return
		}
		$this._skipLogger = $true
		foreach($logger in $this.Items()){
			$logger.Log($message)
		}
		if($this.CurrentScope().Loggers().Id() -ne $this.Id()){
			$this.CurrentScope().Loggers().Log($message)
		}
		if($this.CurrentScope().ParentScope()){
			$this.CurrentScope().ParentScope().Log($message)
		}
		
		$this._skipLogger = $false
    }
    [void] Indent([int] $amount){
		if($this._skipLogger){
			return
		}
		$this._skipLogger = $true
		foreach($logger in $this.Items()){
			$logger.Indent($amount)
		}
		if($this.CurrentScope().Loggers().Id() -ne $this.Id()){
			$this.CurrentScope().Loggers().Indent($amount)
		}
		if($this.CurrentScope().ParentScope()){
			$this.CurrentScope().ParentScope().Indent($amount)
		}
		$this._skipLogger = $false
    }
	static [object] Requirements(){
		return [PSCustomObject]@{
			ParentElementNames =@("Loggers");
			ChildElementNames = @("Logger");
			ChildType = [UILogger]
		}
	}
	
}
class UILogger : HasContext{

	hidden [UILoggingTypeReference] $_type
	
	UILogger([ConfigAutomationContext] $_context) : base($_context){
    }
    UILogger([ConfigAutomationContext] $_context, [UIInputScopeBase] $parent, [String] $name) : base($_context, $parent, $name){
    }

    [UILoggingTypeReference] LoggingType(){
        return $this._type
    }
	[String] ToString() {
		return "$($this.Name()) $($this.LoggingType().ToString())"
	}
	[void] Milestone([string] $message, [string] $type){
		
		$this.LoggingType().Definition().Milestone($message, $type, $this)
    }
	[void] Log([string] $message){
		
		$this.LoggingType().Definition().Log($message, $this)
    }
    [void] Indent([int] $amount){
		$this.LoggingType().Definition().Indent($amount, $this)
    }
	[bool] UpdateProps([hashtable] $props, [string] $body, [System.Xml.XmlElement] $element, [string] $location){
		if(-not (([HasContext]$this).UpdateProps($props, $body, $element, $location))){
			return $false
		}
		
		return $true
	}
	[bool] InitialProps([hashtable] $props, [string] $body, [System.Xml.XmlElement] $element, [string] $location){
		if(-not (([HasContext]$this).InitialProps($props, $body, $element, $location))){
			return $false
		}
		
		if(-not ($element.GetAttribute("Type"))){
            $this.Error("Not all the attributes to build the parameter element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n  Type:$($element.GetAttribute("Type")) `r`n   XPath:$($element.GetAttribute("XPath"))")
			return $false
        }

		$this._type  =  [UILoggingTypeReference]::new($this.Context(), $this.CurrentScope(), $element.GetAttribute("Type"))
		$this.LoggingType().Definition().Init($this)
		return $true
	}
	
	static [object] Requirements(){
		return [PSCustomObject]@{
			ElementNames = @("Logger");
			PrimaryKey = "Name"
		}
	}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - -UIResources Collection - - - - - - - - - - - - - - 
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIConfigMasterExtensionCollection : HasCollectionContext {

    [System.Collections.ArrayList] $_configMasterExtensions
	UIConfigMasterExtensionCollection([ConfigAutomationContext] $context) :base($context, "ConfigMasterExtensions"){
        $this._configMasterExtensions = New-Object System.Collections.ArrayList
    }
    UIConfigMasterExtensionCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope) :base($context, $scope, "ConfigMasterExtensions"){
        $this._configMasterExtensions = New-Object System.Collections.ArrayList
    }
    
    [System.Xml.XmlElement] ApplyExtension([System.Xml.XmlElement] $element){
		
		# $this.Display("{white}Apply Extension to {gray}`r`n$($element.OuterXml | Format-Xml)`r`n")
		# if($element.FirstChild){
		# 	$this.Display("{white}Child Apply Extension to {gray}`r`n$($element.FirstChild.OuterXml )`r`n")
		# }
		$this.PushIndent()
		$originalElement = $element
		$found = $false
		$stillParsing = $false
		$extensionsFound = @()
		$maxNumberOfIterations = 10
		do{
			$maxNumberOfIterations -= 1
			$stillParsing = $false
			foreach($extension in $this.Items()){
				if($extension.Test($element)){
					$element = $extension.ApplyExtensionType($element)
					$stillParsing = $true
					$extensionsFound += $extension.Name()
					$found = $true
				}
			}
			
			if($maxNumberOfIterations -lt 0){
				$this.Error("There seems to be a recursive config extension causing an infinite loop:`r`n{white}Extensions Found:{gray}`r`n$($extensionsFound)`r`n{white}XML:{gray} `r`n$($element.Outerxml | Format-Xml)")
				$stillParsing = $false
			}
		}while($stillParsing)
		
		$this.PopIndent()
		if($found){
			
			if($originalElement.ParentNode){
				$newElement = $originalElement.OwnerDocument.ImportNode($element, $true)
				$originalElement.ParentNode.ReplaceChild($newElement, $originalElement)
			
				return $newElement
			}
		}
		return $element
		
    }
    
	static [object] Requirements(){
		return [PSCustomObject]@{
			ParentElementNames =@("ConfigMasterExtensions");
			ChildElementNames = @("ConfigMasterExtension");
			ChildType = [UIConfigMasterExtension]
		}
	}
	
}
class UIConfigMasterExtension : HasContext{

    
	hidden [String] $_xPath
    hidden [UIConfigMasterExtensionTypeReference] $_type
	UIConfigMasterExtension([ConfigAutomationContext] $_context) : base($_context){
    }
    UIConfigMasterExtension([ConfigAutomationContext] $_context, [UIInputScopeBase] $parent, [String] $name) : base($_context, $parent, $name){
    }

	[string] XPath(){
        return $this._xPath
    }
    [UIConfigMasterExtensionTypeReference] ExtensionType(){
        return $this._type
    }
	[String] ToString() {
		return "$($this.Name()) $($this.ExtensionType().ToString())"
	}
	[bool] Test([System.Xml.XmlElement] $element){
		if(-not $element.SelectSingleNode($this.XPath())){
			# $this.Display("XPath {magenta}$($this.XPath()){gray} failed...")
			return $false
		}

		if($element -is [System.Xml.XmlComment]){
			return $false
		}
		return $true
	}
    [System.Xml.XmlElement] ApplyExtensionType([System.Xml.XmlElement] $element){
		if(-not $element.SelectSingleNode($this.XPath())){
			# $this.Display("XPath {magenta}$($this.XPath()){gray} failed...")
			return $element
		}

		if($element -is [System.Xml.XmlComment]){
			return $element
		}
		return $this.ExtensionType().Definition().ApplyExtensionType($element, $this)
    }
	[bool] UpdateProps([hashtable] $props, [string] $body, [System.Xml.XmlElement] $element, [string] $location){
		if(-not (([HasContext]$this).UpdateProps($props, $body, $element, $location))){
			return $false
		}
		
		return $true
	}
	[bool] InitialProps([hashtable] $props, [string] $body, [System.Xml.XmlElement] $element, [string] $location){
		if(-not (([HasContext]$this).InitialProps($props, $body, $element, $location))){
			return $false
		}
		
		if(-not ($element.GetAttribute("XPath") -and $element.GetAttribute("Type") -and $element.GetAttribute("XPath"))){
            $this.Error("Not all the attributes to build the parameter element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n  Type:$($element.GetAttribute("Type")) `r`n   XPath:$($element.GetAttribute("XPath"))")
			return $false
        }

		$this._type  =  [UIConfigMasterExtensionTypeReference]::new($this.Context(), $element.GetAttribute("Type"))
		$this._xPath = $element.GetAttribute("XPath")
		$this.ExtensionType().Definition().DefineExtension($element, $this)
		return $true
	}
	
	static [object] Requirements(){
		return [PSCustomObject]@{
			ElementNames = @("ConfigMasterExtension");
			PrimaryKey = "Name"
		}
	}
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - -UIParameterTypeCollection Collection - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIConfigMasterExtensionTypeCollection: HasCollectionContext {

	UIConfigMasterExtensionTypeCollection([ConfigAutomationContext] $context) : base($context, "ConfigMasterExtensionType"){
        
    }
    UIConfigMasterExtensionTypeCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope) : base($context, $scope, "ConfigMasterExtensionType"){
        
    }
    [void] PopulateFromXML([System.Xml.XmlElement] $xml){
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "ConfigMasterExtensionTypes") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "ConfigMasterExtensionType") {
                        $this.Add([UIConfigMasterExtensionType]::FromXML($this.Context(), $step, $this.CurrentScope()))
                    }
                }
            }
        }
        
    }
}
class UIConfigMasterExtensionType: UITypeDefinition {

	UIConfigMasterExtensionType([ConfigAutomationContext] $_context) : base($_context){
    }
    UIConfigMasterExtensionType([ConfigAutomationContext] $_context, [String] $name, [String] $contentType, [String] $content, [UIInputScopeBase] $scope) : base($_context, $name, $contentType, $content, "Input Type", $scope){
    }


    [string] ExtensionTypeName(){
        return $this.Name()
    }

    [void] DefineExtension([System.Xml.XmlElement] $element, [UIConfigMasterExtension] $extension){
		$this.InvokeCallback("DefineExtension", @($($this.Context()), $extension, $element), $false)
    }
    [System.Xml.XmlElement] ApplyExtensionType([System.Xml.XmlElement] $element, [UIConfigMasterExtension] $extension){
        return $this.InvokeCallback("AppyExtension", @($($this.Context()), $extension, $element))
    }
    
    static [UIConfigMasterExtensionType] FromXML([ConfigAutomationContext] $_context, [System.Xml.XmlElement] $element, [UIInputScopeBase] $scope){
		return [UITypeDefinition]::FromXml($_context, $element, [UIConfigMasterExtensionType], $scope)
    }
	[String] ToString(){
		return $this.ExtensionTypeName()
	}
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - UIParameterTypeReferenceCollection Collection - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIConfigMasterExtensionTypeReferenceCollection : HasContext {

    [System.Collections.ArrayList] $_configMasterExtensionTypeReferences

    UIConfigMasterExtensionTypeReferenceCollection([ConfigAutomationContext] $context) : base($context) {
        $this._configMasterExtensionTypeReferences = New-Object System.Collections.ArrayList
    }
    [UIConfigMasterExtensionTypeReference[]] Items(){
        return $this._configMasterExtensionTypeReferences
    }
    [UIConfigMasterExtensionTypeReference] Get([string]$name){
        
        foreach($configMasterExtensionTypeReference in $this._configMasterExtensionTypeReferences){
            if($configMasterExtensionTypeReference.ExtensionTypeName() -eq $name){
                return $configMasterExtensionTypeReference
            }
        }
        return $null
    }
}
class UIConfigMasterExtensionTypeReference : HasContext {

    hidden [String] $_typeName
    UIConfigMasterExtensionTypeReference([ConfigAutomationContext] $_context) : base($_context) {
    }
    UIConfigMasterExtensionTypeReference([ConfigAutomationContext] $_context, [String] $name) : base($_context) {
        $this._typeName = $name
    }

    [string] ExtensionTypeName(){
        return $this._typeName
    }

    [UIConfigMasterExtensionType] Definition(){
        # Write-Host "Referencing UI Extension Type '$($this.ExtensionTypeName())'"
		
        return $this.Context().ExtensionTypes().Get($this.ExtensionTypeName())
    }
	[String] ToString(){
		return $this.ExtensionTypeName()
	}
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - -UIResourceTypeCollection Collection - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIResourceTypeCollection: HasCollectionContext {

    [System.Collections.ArrayList] $_resourceTypes

	UIResourceTypeCollection([ConfigAutomationContext] $context) : base($context, "Resource Types"){
        $this._resourceTypes = New-Object System.Collections.ArrayList
    }
    UIResourceTypeCollection([ConfigAutomationContext] $context, [UIInputScopeBase] $scope) : base($context, $scope, "Resource Types"){
        $this._resourceTypes = New-Object System.Collections.ArrayList
    }
    [UIResourceType[]] Items(){
        return $this._resourceTypes
    }
    [UIResourceType] Get([string]$name){
        
        foreach($resourceType in $this._resourceTypes){
            if($resourceType.ResourceTypeName() -eq $name){
                return $resourceType
            }
        }
		
		if($this.CurrentScope().ParentScope()){
			return $this.CurrentScope().ParentScope().ResourceTypes().Get($name)
		}
		
        return $null
    }
    [UIResourceType] Add([String] $name, 
							[ScriptBlock] $_validateCallback, 
							[ScriptBlock] $_deployConfigurationsCallback){
        if($this.Get($name)){
            throw "UI Parameter Type '$($name)' has already been added, unable to add again"
        }
        
        $definition = [UIResourceType]::new($this._context, $name, $_validateCallback, $_deployConfigurationsCallback)

        $this._resourceTypes.Add($definition)
        return $definition
    }
    [UIResourceType] Add([String] $name, 
                                    [String] $_script){
        $typeDefinition = &$_script
        return $this.Add($name, $typeDefinition.Validate,
                                $typeDefinition.DeployConfigurations)

    }
    [void] PopulateFromXML([System.Xml.XmlElement] $xml){
        foreach($roots in $xml.ChildNodes) 
        {
            if($roots.LocalName -eq "ResourceTypes") 
            {
                foreach($step in $roots.ChildNodes)
                {
                    if($step.LocalName -eq "ResourceType") {
                        $this._resourceTypes.Add([UIResourceType]::FromXML($this.Context(), $step))
                    }
                }
            }
        }
        
    }
}
class UIResourceType: HasContext {

    hidden [String] $_typeName
    hidden [ScriptBlock] $_validateCallback
    hidden [ScriptBlock] $_deployConfigurationsCallback
	hidden [ScriptBlock] $_populateFromXmlCallback

	UIResourceType([ConfigAutomationContext] $_context) : base($_context){
    }
    UIResourceType([ConfigAutomationContext] $_context, 
                              [String] $name, 
                              [ScriptBlock] $_validateCallback, 
                              [ScriptBlock] $_deployConfigurationsCallback,
							  [ScriptBlock] $_populateFromXmlCallback) : base($_context){
        $this._typeName = $name
        $this._validateCallback = $_validateCallback
        $this._deployConfigurationsCallback = $_deployConfigurationsCallback
		$this._populateFromXmlCallback = $_populateFromXmlCallback
    }

    [string] ResourceTypeName(){
        return $this._typeName
    }

    [void] ValidateInput([String] $input){
        $context = $this.Context() 
        if(-not $context){
            throw "Context is null when calling UIResourceType"
        }
        $scriptBlock = $this._validateCallback
        &$scriptBlock $context $input
    }
    [object] DeployConfigurations(){
        $context = $this.Context()
        $scriptBlock = $this._deployConfigurationsCallback
        
        return &$scriptBlock $context 
    }
    [void] PopulateFromXmlForResource([System.Xml.XmlElement] $element, [UIResource] $resource){
		if(-not $this._populateFromXmlCallback){
			return 
		}
        $context = $this.Context()
        $scriptBlock = $this._populateFromXmlCallback
        
        &$scriptBlock $context $element $resource
    }
    static [UIResourceType] FromXML([ConfigAutomationContext] $_context, [System.Xml.XmlElement] $element){
        if(-not ($element.GetAttribute("Name") )){
            throw "Not all the attributes to build the resource type element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n )"
        }
		$name = $element.GetAttribute("Name")
		if($element.GetAttribute("SourceFile") ){
			$_script = $element.GetAttribute("SourceFile")
            $typeDefinition = &$_script
			
			if($typeDefinition.Validate -and $typeDefinition.DeployConfigurations){
				$resourceType = [UIResourceType]::new($_context,$name, $typeDefinition.Validate,$typeDefinition.DeployConfigurations, $typeDefinition.PopulateFromXml)
				
				return $resourceType
			}

			throw "When using Source File '$($_script)', the type definition being defined is not defined correctly"
        }

		if($element.'#text'){
			$_scriptContent = $element.'#text'
			$_script = New-TemporaryFile
			ren $_script "$($_script).ps1"
			$_script = "$($_script).ps1"
			$_scriptContent | Set-Content $_script

            $typeDefinition = &$_script
			del $_script
			if($typeDefinition.Validate -and $typeDefinition.DeployConfigurations){
				$resourceType = [UIResourceType]::new($_context, 
											 $name, 
											 $typeDefinition.Validate,
											 $typeDefinition.DeployConfigurations,
											 $typeDefinition.PopulateFromXml)
				
				return $resourceType
			}

			throw "When using Source Code '$($_scriptContent)', the type definition being defined is not defined correctly"
        }
        throw "Not all the attributes to build the parameter type element were found:`r`n  Name:$($element.GetAttribute("Name"))`r`n )"
    }
	[String] ToString(){
		return $this.ResourceTypeName()
	}
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - UIParameterTypeReferenceCollection Collection - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIResourceTypeReferenceCollection : HasContext {

    [System.Collections.ArrayList] $_resourceTypeReferences

    UIResourceTypeReferenceCollection([ConfigAutomationContext] $context) : base($context) {
        $this._resourceTypeReferences = New-Object System.Collections.ArrayList
    }
    [UIResourceTypeReference[]] Items(){
        return $this._resourceTypeReferences
    }
    [UIResourceTypeReference] Get([string]$name){
        
        foreach($resourceTypeReference in $this._resourceTypeReferences){
            if($resourceTypeReference.ResourceTypeName() -eq $name){
                return $resourceTypeReference
            }
        }
        return $null
    }
}
class UIResourceTypeReference : HasContext {

    hidden [String] $_typeName
    UIResourceTypeReference([ConfigAutomationContext] $_context) : base($_context) {
    }
    UIResourceTypeReference([ConfigAutomationContext] $_context, [String] $name) : base($_context) {
        $this._typeName = $name
    }

    [string] ResourceTypeName(){
        return $this._typeName
    }

    [UIResourceType] Definition(){
        Write-Verbose "Referencing UI Resource Type '$($this.ResourceTypeName())'"
		
        return $this.Context().ResourceTypes().Get($this.ResourceTypeName())
    }
	[String] ToString(){
		return $this.ResourceTypeName()
	}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - UIParameterTypeReferenceCollection Collection - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class UIParameterTypeReferenceCollection : HasContext {

    [System.Collections.ArrayList] $_parameterTypeReferences

    UIParameterTypeReferenceCollection([ConfigAutomationContext] $context) : base($context) {
        $this._parameterTypeReferences = New-Object System.Collections.ArrayList
    }
    [UIParameterTypeReference[]] Items(){
        return $this._parameterTypeReferences
    }
    [UIParameterTypeReference] Get([string]$name){
        
        foreach($parameterTypeReference in $this._parameterTypeReferences){
            if($parameterTypeReference.ParameterName() -eq $name){
                return $parameterTypeReference
            }
        }
        return $null
    }
}
class UIParameterTypeReference : HasContext{

    hidden [String] $_typeName
    UIParameterTypeReference([ConfigAutomationContext] $_context) : base($_context) {
    }
    UIParameterTypeReference([ConfigAutomationContext] $_context, [String] $name) : base($_context) {
        $this._typeName = $name
    }

    [string] ParameterTypeName(){
        return $this._typeName
    }

    [UIParameterTypeDefinition] Definition(){
        $this.Context().Log("Referencing UI Parameter Type '$($this.ParameterTypeName())'")
		
        return $this.Context().ParameterTypes().Get($this.ParameterTypeName())
    }
	[String] ToString(){
		return $this.ParameterTypeName()
	}
}



class ConfigAutomationContext{
	[int]                      $_parameterizingSem = 0
	[bool]                     $_parameterizingEnabled = $true
	[int]                      $_parameterizingMaxSem = 10
	[bool]                     $_parameterizingErrorTriggered = $false
	[System.Collections.Stack] $_parameterizingEnabledStack
	[UIInputScope]     $savedRootScope
	[UIInputScope]     $rootScope
	[UIInputScope]     $_overrideScope

	[System.Collections.Stack] $rootScopes
	[string[]] $includedScopes
	[string[]] $excludedScopes
	[object] $arguments
	[bool] $failed
	[string] $_sessionId
	[bool]             $_exitRequested
	

	hidden [bool] $_logLock = $false
	hidden [bool] $_loggingEnabled = $true
	[String] 		           $_currentLocation
	[System.Collections.Stack] $_locations

	[System.Collections.Stack] $_deplayConfigurationStack
	[object]       			   $_deplayConfiguration
	[object]       			   $_lastDeplayConfiguration
	[hashtable]                $_requiredParameters
	[int]                      $_actionLevel = 0
	[hashtable]                $_refs
	[bool]                     $_fullParsing = $false
	[bool]                     $_saveXmlEnabled = $true

	[System.Collections.Stack] $_currentLoggingContextStack
	[object]       			   $_currentLoggingContext
	[object]       			   $_rootLoggingContext
	
	[System.Collections.ArrayList] $_errors
	[System.Collections.ArrayList] $_filesVisited 	
	[System.Collections.ArrayList] $_azureRmResources
    ConfigAutomationContext([string]$personalAccessToken, [string]$account){
		$this._filesVisited = new-object System.Collections.ArrayList
        $this.arguments = [hashtable]::new()
		$this.rootScopes = New-Object System.Collections.Stack
		$this._locations = New-Object System.Collections.Stack
		
		$this.rootScope = [UIAction]::new($this, $null, "ROOT_AUTOMATION")
		$this.rootScope.InitialProps(@{Type="Component"}, "", $null, $null)
		$this.rootScope.CurrentScope($this.rootScope)
		$this.savedRootScope = $this.rootScope
		$this.rootScope.ActionTypes().Add("Component", "ScriptContent", ({
                                    {
										Param([ConfigAutomationContext] $context,[UIAction] $action)
										Write-Color "{white}Actions:{gray}`r`n   $(($action.CurrentScope().Actions().Items() | Where {$_} | Foreach {"$($_.Name())"}) -join "`r`n   ")"
										Write-Color "`r`n{white}Common Actions:{gray}`r`n   $((@($action.CurrentScope().Actions().Templates() | Where {$_}) | Foreach {"$($_.Name())"}) -join "`r`n   ")"
									},
                                    {
										Param([ConfigAutomationContext] $context,[UIAction] $action)
										return $true
									}, 
                                    {
										Param([ConfigAutomationContext] $context,[UIAction] $action)
										return $true
									}}).ToString())

		
		$this._overrideScope              = $null
		$this._deplayConfiguration        = [PSCustomObject]@{IsDelayed = $false; DelayLogs = @()}
		$this._lastDeplayConfiguration    = $null
		$this._deplayConfigurationStack   = New-Object System.Collections.Stack
		$this._requiredParameters         = new-object hashtable
		$this._refs                       = new-object hashtable
		$this._parameterizingEnabledStack = New-Object System.Collections.Stack
		$this._azureRmResources           = new-object System.Collections.ArrayList
		$this._currentLoggingContext      = [PSCustomObject]@{id = 'init'; Children = $(new-object System.Collections.ArrayList)}
		$this._currentLoggingContextStack = New-Object System.Collections.Stack
		$this._rootLoggingContext         = $this._currentLoggingContext
		$this.StartSession()

    }
	[void] StartSession(){
		$this._errors = new-object System.Collections.ArrayList
		$this.failed = $false
		$this._sessionId = Get-Random
		$this._filesVisited = new-object System.Collections.ArrayList
        $this.arguments = [hashtable]::new()
		$this.rootScopes = New-Object System.Collections.Stack
		$this._locations = New-Object System.Collections.Stack
		$this._overrideScope = $null
		$this._exitRequested = $false
		[HasContext]::Prefix = ""
		$this._actionLevel = 0
		$this._parameterizingEnabledStack = New-Object System.Collections.Stack
		$this._azureRmResources           = new-object System.Collections.ArrayList
	}
	[string] SessionId(){
		return $this._sessionId
	}
	[void] PushParmeterizing(){
		$this._parameterizingSem += 1
	}
	[void] PopParmeterizing(){
		$this._parameterizingSem -= 1
	}
	[bool] ExitRequested(){
		if($this._exitRequested){
			return $true
		}
		
		$measure = Measure-Command {
			if($Global:Host.UI.RawUI.KeyAvailable -and (3 -eq [int]$Global:Host.UI.RawUI.ReadKey("AllowCtrlC,IncludeKeyUp,NoEcho").Character)){
				$this.Context().ExitRequested($true)
			}
		}
		# $this.Display("Checking Exit Request - $($measure.TotalMilliseconds)")
		return $this._exitRequested
	}
	[object] CurrentLoggingContext(){
		return $this._currentLoggingContext
	}
	[void] StartLoggingContext([string] $id){
		$this.PushLoggingContext([PSCustomObject]@{id = $id; Children = $(new-object System.Collections.ArrayList)})
	}
	[void] EndLoggingContext(){
		$this.PopLoggingContext()
	}
	[void] PushLoggingContext([object] $context){
		$this.CurrentLoggingContext().Children.Add([PSCustomObject]@{Type = 'Child'; Value = $context})
		$this._currentLoggingContextStack.Push($this._currentLoggingContext)
		$this._currentLoggingContext = $context
	}
	[void] PopLoggingContext(){
		$this._currentLoggingContext = $this._currentLoggingContextStack.Pop()
	}
	[void] ExitRequested([string] $exitRequested){
		 $this._exitRequested = $exitRequested
	}
	[bool] IsParmeterizingDisabled(){
		if($this._parameterizingErrorTriggered){
			return $true
		}
		if(-not $this._parameterizingEnabled){
			return $true
		}
		
		if($this._parameterizingSem -gt $this._parameterizingMaxSem){
			$this.Warning("Parameterizing has reached a recursive count of $($this._parameterizingMaxSem), there must be something wrong. Disabling all parameterizing from now on")
			# $this._parameterizingErrorTriggered = $true
			return $true
		}
		
		return $false
	}
	[void] PushParmeterizingEnabled([bool] $enabled){
		$this._parameterizingEnabledStack.Push($this._parameterizingEnabled)
		$this._parameterizingEnabled = $enabled
	}
	[void] PopParmeterizingEnabled(){
		$this._parameterizingEnabled = $this._parameterizingEnabledStack.Pop()
	}
	[bool] FullParsing(){
		return $this._fullParsing
	}
	[void] FullParsing([bool] $fullParsing){
		$this._fullParsing = $fullParsing
	}
	[bool] SaveXmlEnabled(){
		return $this._saveXmlEnabled
	}
	[void] SaveXmlEnabled([bool] $saveXml){
		$this._saveXmlEnabled = $saveXml
	}
	[UIInputScopeBase] GetRootScope(){
		return $this.savedRootScope
	}
	[bool] IsLoggingEnabled(){
		return $this._loggingEnabled
	}
	[void] IsLoggingEnabled([bool] $enabled){
		$this._loggingEnabled = $enabled
	}
	[void] AddRef([string] $name, [object] $obj){
		$this.AddRef($name, $obj, $false)
	}
	[bool] AddRef([string] $name, [object] $obj, [bool] $allowReplace){
		$this.Display("Adding ref {magenta}$($name){gray} as type {white}$($obj.GetType()){gray}")
		if(-not $allowReplace -and ($this.Ref($name))){
			$this.Error("Ref {white}$($name){gray} is already populated and trying to override is not allowed")
			return $false
		}
		$this._refs[$name] = $obj
		return $true
	}
	[object] Ref([string] $name){
		return $this.Ref($name, $null, $false)
	}
	[object] Ref([string] $name, [Type] $expectedType, [bool] $expectedToExists){
		return $this.Ref($name, $expectedType, $expectedToExists, $false)
	}
	[object] Ref([string] $name, [Type] $expectedType, [bool] $expectedToExists, [bool] $expectTypeToBeEqual){
		return $this.Ref($name, $expectedType, $expectedToExists, $expectTypeToBeEqual, $false)
	}
	[int] $_lockRef = 0
	[object] Ref([string] $name, [Type] $expectedType, [bool] $expectedToExists, [bool] $expectTypeToBeEqual, [bool] $checkForXml){
		# $this.Display("Fetching {white}Ref{magenta} $name{gray}")
		$this.PushIndent()
		if($this._lockRef -gt 10){
			$this.Error("Looks like ref is about to go into a loop...")
			$this.PopIndent()
			return $null
		}
		
		$this._lockRef += 1
		$obj = $this._refs[$name]
		
		if($checkForXml -and $obj -is [System.Xml.XmlElement]){
			$this.PopulateFromXml($obj, $this.GetRootScope())
			
			$item = $this.Ref($name, $expectedType, $expectedToExists, $expectTypeToBeEqual)
			$this.PopIndent()
			return $item
		}
		if(-not $obj){
			if($expectedToExists){
				$this.Error("Ref {white}$($name){gray} was not found")
			}
			$this._lockRef-=1
			$this.PopIndent()
			return $obj
		}
		
		if($expectedType -and -not $obj.GetType() -eq $expectedType){
			if($expectTypeToBeEqual){
				$this.Error("Ref {white}$($name){gray} was expected to be of type '{white}$($expectedType){gray}' but was found to be of type '{white}$($obj.GetType()){gray}'")
			}
			$this._lockRef-=1
			$this.PopIndent()
			return $null
		}
		$this._lockRef-=1
		$this.PopIndent()
		return $obj
	}
	[void] PushActionLevel(){
		$this._actionLevel += 1
	}
	[void] PopActionLevel(){
		$this._actionLevel -= 1
	}
	[int] ActionLevel(){
		return $this._actionLevel
	}
	[void] AddRequiredParammeter([UIParameter] $parameter){
		$this._requiredParameters[$parameter.CurrentScope().FullName() + "|" + $parameter.Name()] = $parameter
	}
	[void] RemoveRequiredParammeter([UIParameter] $parameter){
		$this._requiredParameters.Remove($parameter.CurrentScope().FullName() + "|" + $parameter.Name())
	}
	[UIParameter[]] RequiredParameters(){
		return $this._requiredParameters.GetEnumerator() | % {$_.Value} | Where {$_}
	}
	[bool] DelayLogging(){
		return $this._deplayConfiguration.IsDelayed
	}
	[void] DelayLogging([bool] $delay){
		if($delay -eq $true){
			$delayConfig = [PSCustomObject]@{IsDelayed = $delay; DelayLogs = @()}
			
			$this._lastDeplayConfiguration = $null
			$this._deplayConfigurationStack.Push($this._deplayConfiguration)
			$this._deplayConfiguration = $delayConfig
			
		}
		else{
			$this._lastDeplayConfiguration = $this._deplayConfiguration
			$this._deplayConfiguration = $this._deplayConfigurationStack.Pop()
		}
	}
	[object[]] AzureRmResources([string] $name, [string] $resourceGroup, [string] $resourceType){
		
		$this.Display("{magenta}Azure RM Resource: `r`n"+ `
		 	($name          | ?: "   {white}ResourceName.: {gray}'{magenta}$($name){gray}'`r`n"          : "") +`
		 	($resourceGroup | ?: "   {white}ResourceGroup: {gray}'{magenta}$($resourceGroup){gray}'`r`n"          : "") +`
		 	($resourceType  | ?: "   {white}ResourceType.: {gray}'{magenta}$($resourceType){gray}'`r`n"          : ""))
	
		$resources = $this._azureRmResources | Where { `
			(($name          -and $_.ResourceName)      | ?: ($_.ResourceName      -ieq $name)          : $true) -and
			(($resourceGroup -and $_.ResourceGroupName) | ?: ($_.ResourceGroupName -ieq $resourceGroup) : $true) -and
			(($resourceType  -and $_.ResourceType)      | ?: ($_.ResourceType      -ieq $resourceType)  : $true) }
			
		
		if(-not $resources){
			
			$resources = [System.Collections.ArrayList]::new()
			
			
			$expression = ("Get-AzureRmResource " + `
			($name          | ?: "-ResourceName '$($name)' "          : "") +`
			($resourceGroup | ?: "-ResourceGroup '$($resourceGroup)' "          : "") + `
			($resourceType  | ?: "-ResourceType '$($resourceType)' "          : "")) + `
			"-ExpandProperties"
			
			$this.Display("{magenta}Fetching Azure RM Resources:{gray}`r`n   $($expression)")
			
			$resourceObjs = Invoke-Expression $expression
			
			if(-not $resourceObjs){
				$resource = @{
					IsFound = $false;
					ResourceName      = $name;
					ResourceGroupName = $resourceGroup;
					ResourceType      = $resourceType;
					Resource          = $null
				}
				$resources.Add($resource)
			}
			else{
				foreach($resourceObj in $resourceObjs){
					$resource = @{
						IsFound = $true;
						ResourceName      = $resourceObj.ResourceName;
						ResourceGroupName = $resourceObj.ResourceGroupName;
						ResourceType      = $resourceObj.ResourceType;
						Resource = $resourceObj
					}
					
					$resources.Add($resource)
					
					$this._azureRmResources.Add($resource)
				}
				
				# Load all resources in group, just to speed up things
				$uniqueResourceGroupNames = $resourceObjs | Foreach {$_.ResourceGroupName} | Get-Unique
				foreach($resourceGroup in $uniqueResourceGroupNames){
					$expression = ("Get-AzureRmResource -ODataQuery `"```$filter=resourcegroup eq '$($resourceGroup)'`" -ExpandProperties")
						
					$this.Display("{magenta}Fetching Azure RM Resources (In Group):{gray}`r`n   $($expression)")
					
					$resourceObjs = Invoke-Expression $expression
					foreach($resourceObj in $resourceObjs){
						$resource = @{
							IsFound           = $true;
							ResourceName      = $resourceObj.ResourceName;
							ResourceGroupName = $resourceObj.ResourceGroupName;
							ResourceType      = $resourceObj.ResourceType;
							Resource = $resourceObj
						}
						
						$name          = $resourceObj.ResourceName
						$resourceGroup = $resourceObj.ResourceGroupName
						$resourceType  = $resourceObj.ResourceType
						
						$isAlreadyAdded = $this._azureRmResources | Where { `
										(($name          -and $_.ResourceName)      | ?: ($_.ResourceName      -ieq $name)          : $true) -and
										(($resourceGroup -and $_.ResourceGroupName) | ?: ($_.ResourceGroupName -ieq $resourceGroup) : $true) -and
										(($resourceType  -and $_.ResourceType)      | ?: ($_.ResourceType      -ieq $resourceType)  : $true) }
						
						if(-not $isAlreadyAdded){
							$this._azureRmResources.Add($resource)
						}
					}
				}
				
			}
		}
		
		return $resources | Where {$_.IsFound} | Foreach {$_.Resource}
		
	}
	[void] LogDelayedLogs(){
		if($this._lastDeplayConfiguration){
			# Write-Color "{magenta}LogDelayedLogs: {gray} We are logging all [{white}$($this._deplayConfiguration.DelayLogs.Count) entries{gray}]"
			foreach($delayedLog in $this._lastDeplayConfiguration.DelayLogs){
				$this.GenericLog($delayedLog["Grouping"], $delayedLog["Message"], $delayedLog["ActionName"], $delayedLog["Backup"], $delayedLog["PerformCheck"])
			}
			$this._lastDeplayConfiguration.DelayLogs = @()
		}
	}
	[bool] AreWeDelayingLogging([string] $grouping, [string] $message, [string] $actionName, [string] $backup, [bool] $performCheck){
		
		return (-not $this.IsLoggingEnabled())
		if(($this.DelayLogging())){
			# Write-Color "{magenta}AreWeDelayingLogging: {gray} Adding {gray}[$($backup){gray]] to the list of [{white}$($this._deplayConfiguration.DelayLogs.Count) entries{gray}]"

			$delayedLogging = [hashtable]::new()
			$delayedLogging.Add("Grouping", $grouping)	
			$delayedLogging.Add("Message", $message)
			$delayedLogging.Add("ActionName", $actionName)
			$delayedLogging.Add("Backup", $backup)
			$delayedLogging.Add("PerformCheck", $performCheck)
			$this._deplayConfiguration.DelayLogs += $delayedLogging

			return $true
		}

		return $false
	}
	[hashtable[]] DelayedLogging(){
		return $this._deplayConfiguration.DelayLogs
	}

	PushIndent(){
		$this.PushIndent($this.arguments["LogGroups"])
	}
	PopIndent(){
		$this.PopIndent($this.arguments["LogGroups"])
	}
	PushIndent([string] $grouping){
		try{
		# if($this.arguments["LogGroups"] -eq $grouping -or $this.arguments["LogGroups"] -eq "All"){
			[HasContext]::Prefix += "  "
			# $this.rootScope.Indent(1)
		# }
		}
		catch{
			Write-Color "{red}Error, {gray}Push Indent Mismatch`r`n{white}Error Message:{gray}`r`n$($_.Exception.Message)`r`n`r`n{white}Stack Trace:{gray}`r`n$($_.ScriptStackTrace)"
			throw
		}
	}
	PopIndent([string] $grouping){
	
		try{
			# if($this.arguments["LogGroups"] -eq $grouping -or $this.arguments["LogGroups"] -eq "All"){
				[HasContext]::Prefix = [HasContext]::Prefix.Substring(2)
				# $this.rootScope.Indent(-1)
			# }
		}
		catch{
			Write-Color "{red}Error, {gray}Pop Indent Mismatch`r`n{white}Error Message:{gray}`r`n$($_.Exception.Message)`r`n`r`n{white}Stack Trace:{gray}`r`n$($_.ScriptStackTrace)"
			throw
		}
	}
	Error([string] $message){
		$this.Error("General", $message)
		$this.failed = $true
	}
	Action([string] $message){
		return;
		if($this.arguments["LogGroups"] -ne "General" -and $this.arguments["LogGroups"] -ne "All"){
			return;
		}
		#TEMP $this.Action("General", $message)
	}
	Warning([string] $message){
		if($this.arguments["LogGroups"] -ne "General" -and $this.arguments["LogGroups"] -ne "All"){
			return;
		}
		$this.Warning("General", $message)
	}
	Log([string] $message){
		return;
		if($this.arguments["LogGroups"] -ne "General" -and $this.arguments["LogGroups"] -ne "All"){
			return;
		}
		#TEMP $this.Log("General", $message)
	}
	Display([string] $message){
		$this.Display("General", $message)
	}
	GenericLog([string] $grouping, [string] $message, [string] $actionName, [string] $backup, [bool] $performCheck){
		if($this.arguments["StartLogFilter"]){
			if(-not ($message -match $this.arguments["StartLogFilter"])){
				return
			}
			$this.arguments.Remove("StartLogFilter")
		}
		
		if($performCheck -and $this.arguments["LogFilter"] -and -not ($message -match $this.arguments["LogFilter"])){
			return;
		}
		$this._logLock = $true
		if(-not $performCheck -or $this.arguments["LogGroups"] -eq $grouping -or $this.arguments["LogGroups"] -eq "All"){

			if($this.AreWeDelayingLogging($grouping, $message, $actionName, $backup, $performCheck)){
				$this._logLock = $false
				return;
			}
			$this.rootScope.Log($backup)
			$this.CurrentLoggingContext().Children.Add([PSCustomObject]@{Type = 'Log'; Value = $backup})
			# Write-Color $backup
		}	
		$this._logLock = $false
	}
	Error([string] $grouping, [string] $message){
	
		$this.failed = $true
		$this._errors.Add($message)
		$message = $message -replace "`n","`n$( [HasContext]::Prefix)"
		$message = [HasContext]::Prefix + "{red}Error, {gray}$($message)"
		$this.GenericLog($grouping, $message, "log-error", $message, $false)
		$rawMessage = $message -replace "\{.*?\}",""
		if(-not ($this.arguments["SkipAzureDevOpsLogging"] -ieq "true")){
			Write-Host "##vso[task.logissue type=error]$($rawMessage)"
		}
		
	}
	Action([string] $grouping, [string] $message){	
		return;
		$message = $message -replace "`n","`n$( [HasContext]::Prefix)"
		$this.GenericLog($grouping, $message, "log-action", [HasContext]::Prefix + "{gray}$($grouping) {magenta}:: {gray}$($message)",$true)
	}
	Warning([string] $grouping, [string] $message){
		
		$message = $message -replace "`n","`n$( [HasContext]::Prefix)"
		$message = [HasContext]::Prefix + "{gray}$($grouping) {yellow}Warning, {gray}$($message)"
		$this.GenericLog($grouping, $message, "log-warning", $message,$false)
		$rawMessage = $message -replace "\{.*?\}",""
		
		if(-not ($this.arguments["SkipAzureDevOpsLogging"] -ieq "true")){
			Write-Host "##vso[task.logissue type=warning]$($rawMessage)"
		}
	}
	Log([string] $grouping, [string] $message){
		return;	
		$message = $message -replace "`n","`n$( [HasContext]::Prefix)"
		$this.GenericLog($grouping, $message, "log-log", [HasContext]::Prefix + "{gray}$($message)",$true)
	}
	Display([string] $grouping, [string] $message){
		$message = $message -replace "`n","`n$( [HasContext]::Prefix)"
		$this.GenericLog($grouping, $message, "log-log", [HasContext]::Prefix + "$($message)",$false)
	}
	Title([string] $grouping, [string] $message){
		$border = ""
		$maxLength = ((($message -split "`n") | Foreach {$_ -replace "[`r`n]",''} | Foreach {$_.length}) | Measure -Max).Maximum
		for($i=0;$i -lt $maxLength; $i++){
			$border += "__"
		}
		
		$message = $message -replace "([^`r`n])",'$1 '
		$message = $message -replace "`r`n","`r`n$( [HasContext]::Prefix)"
		$message = $message -replace "[`r`n]+$",""
		$message += "`r`n$([HasContext]::Prefix){magenta}$($border){gray}"
		$this.GenericLog($grouping, $message, "log-log", [HasContext]::Prefix + "{white}$($message){gray}`r`n",$false)
	}
	Title([string] $message){
		$this.Title("General", $message)
	}
	[void] SetExcludedScopes([string[]] $scopes){
		$this.excludedScopes = $scopes
	}
	[void] SetIncludedScopes([string[]] $scopes){
		$this.includedScopes = $scopes
	}
	[string[]] GetExcludedScopes()
	{
		return $this.excludedScopes
	}
	[string[]] GetIncludedScopes()
	{
		return $this.includedScopes
	}
	[object] ParameterArguments()
	{
		return $this.arguments
	}
	[UIInputScopeBase] OverrideScope()
	{
		if($this._overrideScope){
			$this._overrideScope.IsOverride($true)
			$this._overrideScope.LoadChildren()
			
		}
		
		return $this._overrideScope
	}
	[void] OverrideScope([UIInputScopeBase] $scope)
	{
		
		if($scope){
			if([Object]::ReferenceEquals($this.OverrideScope(), $scope)){
				return;
			}
			#TEMP $this.Action("Override", "Setting Scope Override to $($scope.GetScopeString())")
		}
		
		if(-not $scope -and $this.OverrideScope()){
			$scope.IsOverride($false) # TODO add to some "Clean" method and allow it to clean all parents a swell
		}
		
		if($this.OverrideScope()){
			$scope.ParentScope($this.OverrideScope())
		}
		$scope.IsOverride($true)
		$this._overrideScope = $scope
	}
	[bool] IsValid(){
		return -not $this.failed
	}
	[void] PushLocation([string] $location){

		#$this.Context().Display("XMLParsing", "{magenta}Pushing Location{gray} (Old) to '{white}$($this._currentLocation){gray}'") 
		$this._locations.Push($this._currentLocation)
		$this._currentLocation = $location
		#$this.Context().Display("XMLParsing", "{magenta}                {gray} (New) to '{white}$($this._currentLocation){gray}'") 
	}
	[void] PopLocation(){
		
		#$this.Context().Display("XMLParsing", "{magenta}Poping Location{gray} (Old) to '{white}$($this._currentLocation){gray}'") 
		$this._currentLocation = $this._locations.Pop()
		#$this.Context().Display("XMLParsing", "{magenta}               {gray} (New) to '{white}$($this._currentLocation){gray}'") 
	}
	[string] CurrentLocation(){
		return $this._currentLocation
	}
	[void] PushScope([UIInputScopeBase] $scope){
		
		$this.rootScopes.Push($this.rootScope)
		$this.rootScope = $scope
		$this.Context().Action("Pushing Scope to '$($this.rootScope.Name())'") 
	}
	[void] PopScope(){
		
		$this.rootScope = $this.rootScopes.Pop()
		$this.Context().Action("Poping Scope to '$($this.rootScope.Name())'") 
	}
	[UIInputScopeBase[]] GetAllScopes(){
		return $this.rootScope.GetAllRecursiveChildren()
	}
	[ConfigAutomationContext] Context(){
		return $this
	}
	[UIInputScopeBase] CurrentScope(){
		return $this.rootScope
	}
	[UIInputScopeBase] PreviousScope(){
		return $this.rootScopes.Peek()
	}
	[UILoggingTypeDefinitionCollection] LoggingTypes(){
        return $this.rootScope.LoggingTypes()
    }
	[UIConfigMasterExtensionTypeCollection] ExtensionTypes(){
        return $this.rootScope.ExtensionTypes()
    }
	[UIActionCollection] Actions(){
        return $this.rootScope.Actions()
    }
	[UIConfigMasterExtensionCollection] Extensions(){
        return $this.rootScope.Extensions()
    }
	[UIParameterCollection] Parameters(){
        return $this.rootScope.Parameters()
    }
    [UIParameterTypeDefinitionCollection] ParameterTypes(){
        return $this.rootScope.ParameterTypes()
    }
	[UIActionTypeDefinitionCollection] ActionTypes(){
        return $this.rootScope.ActionTypes()
    }
	[UIResourceTypeCollection] ResourceTypes(){
        return $this.rootScope.ResourceTypes()
    }
    # [UIInputCollection] Inputs(){
    #     return $this.rootScope.Inputs()
    # }
    [UIInputScopecollection] InputScopes(){
        return $this.rootScope.InputScopes()
    }
	[UIInputTypeDefinitionCollection] InputTypes(){
        return $this.rootScope.InputTypes()
    }
	[void] PopulateFromArguments([object] $arguments){
		$this.arguments = $arguments
	}
	
	[UIInputScopeBase[]] FindActions($match){
		return $this.rootScope.FindActions($match)
    }
	[void] ExecuteActionInFull([UIAction] $actialAction){
		$parentText = ""
		if($actialAction.ParentScope()){
			$parentText = "{gray}{white}" + $actialAction.ParentScope().FullName("{gray} > {white}") + "{gray}"
		}
		$this.Context().StartLoggingContext("Start")
		$this.Display("$($parentText) > {white}{magenta}$($actialAction.Name()){white}{gray}")
		
		$success = $true
		if(-not $actialAction.TestProperty("SkipValidate", "true", $true))
		{
			$this.Context().StartLoggingContext("Validate")
			$this.Title("`r`n Validating `r`n")
			[HasContext]::Prefix += "  "
			$success = $actialAction.Validate()
			[HasContext]::Prefix = [HasContext]::Prefix.Substring(2)
			$this.Context().EndLoggingContext()
		}
		
		if(-not $actialAction.TestProperty("SkipClean", "true", $true) -and -not $actialAction.TestProperty("SkipValidate", "true", $true))
		{
			$this.Context().StartLoggingContext("Cleaning")
			$this.Title("`r`n Cleaning `r`n")
			[HasContext]::Prefix += "  "
			$success = $actialAction.Clean()
			[HasContext]::Prefix = [HasContext]::Prefix.Substring(2)
			$this.Context().EndLoggingContext()
		}
		
		if($success -and -not $actialAction.TestProperty("SkipExecute", "true", $true))
		{
			$this.Context().StartLoggingContext("Executing")
			$this.Title("`r`n Executing `r`n")
			[HasContext]::Prefix += "  "
			$success = $actialAction.ExecuteAction()
			[HasContext]::Prefix = [HasContext]::Prefix.Substring(2)
			$this.Context().EndLoggingContext()
		}
		$this.Context().EndLoggingContext()

		if(-not $success){
			$actialAction.PrintParameterBreakdown()
			$this.Display("`r`n{red}:: {red}F a i l e d {red}::{gray}`r`n")
		}
		else{
			$actialAction.PrintParameterBreakdown()
			$this.Display("`r`n{green}:: {green}S u c c e s s {green}::{gray}`r`n")
		}
	}
	[void] WriteHtmlLog([string] $filePath){
		$root = $this._rootLoggingContext
		$html = $this.OutputAsHtml($root)
		[System.IO.File]::WriteAllText($filePath, $html)
	}
	[string] OutputAsHtml([object] $context){
		if($context.Children.Count -eq 0){
			return ""
		}

		$html = ""
		$html += "<div class='item'>`r`n"
		$html += "  <div class='title'>$($context.id)</div>`r`n"
		$html += "  <div class='children'>`r`n"
		foreach($child in $context.Children){
			if($child.Type -eq "Log"){
				$html += Expand-AsHtml $($child.Value)
			}
			elseif($child.Type -eq "Child"){
				$html += $this.OutputAsHtml($($child.Value))
			}
		}
		$html += "  </div>`r`n"
		$html += "</div>`r`n"
		return $html
	}
	[array] ResolveAction([string[]] $txtActions, [bool] $expected){
		if($this.arguments["Execution:LogGroups"]){
			$this.arguments["LogGroups"] = $this.arguments["Execution:LogGroups"]
		}
		
		[HasContext]::Prefix = ""
		
		$preUiActions       = new-object System.Collections.ArrayList
		$uiActionBreadcrums = new-object System.Collections.ArrayList
		$PostuiActions      = new-object System.Collections.ArrayList
		$uiAction           = $null
		$txtAction          = $null
		$txtActionIndex     = -1
		$includeAction      = $false
		$notFoundActionStr  = "{red}Not Set{gray}"
		do{
			if($includeAction){
				$uiActionBreadcrums.Add($uiAction)
				
				if(-not $uiAction.Get("ImportTemplates").Import()){
					$this.Error("Failed to import $($uiAction.Name()) templates, can cause action searching to be incorrect")
					$uiAction.PrintParameterBreakdown()
				}
			}
			
			$includeAction = $true
			$uiActionFound = $null
			
			# R o o t   A c t i o n
			# The first action to use
			if(-not $txtAction){
				$uiActionFound = $this.CurrentScope()
			}
			
			# R e f   A c t i o n 
			# A referenced action, an actions 'Ref' attribute... Must be the first action
			if(-not $uiActionFound -and $txtActionIndex -eq 0){
				$uiActionFound = $this.Ref($txtAction, [UIAction], $false, $false)
			}
			
			# A c t i o n - Find Normal Action
			# The general action
			if(-not $uiActionFound){
				$uiActionFound  =  $uiAction.Get("Actions").Get($txtAction, $false)
			}
			
			# A c t i o n - Find Normal Action
			# The general action
			if(-not $uiActionFound){
				$uiActionFound  =  $uiAction.Get("ActionPlugins").Get($txtAction, $true)
			}
			
			# A c t i o n   T e m p l a t e 
			# Have no idea what im doing with this so called 'ActionTemplate'
			# if(-not $uiActionFound){
			#	$uiActionFound = $uiAction.Get("ActionTemplates").Get($action)
			# }
			
			# A c t i o n   O v e r r i d e s 
			# Have no idea what im doing with this so called 'ActionTemplate'
			if(-not $uiActionFound){
				$uiActionFound = $uiAction.Get("ActionOverrides").Get($txtAction)
				
				if($uiActionFound){
					$uiActionFound.LoadChildren()
					$this.OverrideScope($uiActionFound)
					$includeAction = $false
				}
			}
			
			# N o t   F o u n d
			if(-not $uiActionFound){
				if($expected){
					$this.Error("Action '{white}$($txtAction){gray}' was not found")
				}
				$uiAction = $null
				return $null
			}
			
			
			$uiActionName = $notFoundActionStr
			if($uiAction){
				$uiActionName = $uiAction.FullName()
			}
			if($uiActionName -ne $notFoundActionStr){
				$this.Display("Found Action '{white}$($uiActionFound.Name()){gray}' in '{white}$($uiActionName){gray}'")
			}
			
			
			if($includeAction){
				$uiActionName = "{red}Not Set{gray}"
				if($uiAction){
					$uiActionName = $uiAction.FullName()
				}	
				$uiAction = $uiActionFound
				$this.PushScope($uiAction)
				$uiAction.LoadChildren()
			}
			
			
			
			$txtActionIndex += 1
			$txtAction = $txtActions[$txtActionIndex]
			
		}while($txtActionIndex -lt $txtActions.Count)


		return $uiActionBreadcrums + @($uiAction)
	}
	[void] ExecuteActionsFromArguments([string[]] $txtActions){
		
		$uiActions = $this.ResolveAction($txtActions, $true)
		if(-not $uiActions){
			$this.Error("Cmd", "No Actions Correspond to '$($txtActions -join ' ')'")
			return
		}
		
		# Execute Pre Actions
		# $this.Display("{white}::::::::::::::::::::::::::::::{gray} {magenta}Pre Actions{white} ::::::::::::::::::::::::::::::::{gray}")
		
		# for($i = 0; $i -lt $uiActionBreadcrums.Count; $i += 1)
		# {
			# $this.PushIndent()
			# foreach($preAction in $uiActionBreadcrums[$i].Get("PreActions").Items()){
				# $this.ExecuteActionInFull($preAction)
			# }
		# }
		# for($i = 0; $i -lt $uiActionBreadcrums.Count; $i += 1)
		# {
			# $this.PopIndent()
		# }
		
		$this.Display("{white}::::::::::::::::::::::::::::::{gray} {magenta}Main Actions{white} :::::::::::::::::::::::::::::::{gray}")
		
		# Execute main action
		$this.ExecuteActionInFull($uiActions[$uiActions.Count - 1])
		
		# $this.Display("{white}::::::::::::::::::::::::::::::{gray} {magenta}Post Actions{white} :::::::::::::::::::::::::::::::{gray}")
		
		for($i = 0; $i -lt ($uiActions.Count - 1); $i += 1)
		{
			$this.PopScope()
		}
		
		if($this._errors.Count -gt 0){
			#throw ($this._errors -join "`r`n")
		}
		# # Execute Post Actions
		# for($i = $uiActionBreadcrums.Count - 1; $i -ge 0; $i -= 1)
		# {
			# foreach($postAction in $uiActionBreadcrums[$i].Get("PostActions").Items()){
				# $this.ExecuteActionInFull($postAction)
			# }
			# $this.PopIndent()
		# }
	}
	[void] PopulateFromFiles([String[]] $files){
		$this.PushParmeterizingEnabled($false)
		
        foreach($file in $files){
			if(-not ($file -like "*PackageTmp*" )){
				if($this._filesVisited.Contains($file)){
					continue
				}
				
				$this.PushLocation($file)
				
				try{
					[XML]$xmlContent = Get-Content $file
					
					
					$xmlLoadingGroup = $xmlContent.FirstChild.GetAttribute("LoadingGroup") 
					$argLoadingGroup = $this.arguments["LoadingGroup"]
					if($argLoadingGroup){
						if(-not (($xmlLoadingGroup -ieq $argLoadingGroup) -or (($xmlLoadingGroup -eq "*")))){
							# Write-Color "    {yellow}XML Skipped{gray} - {white}Arg Loading Group: {gray}$($argLoadingGroup), {white}Xml Loading Group: {gray}$($xmlLoadingGroup)"
							continue
						}
					}
					else{
						if(-not ((-not $xmlLoadingGroup) -or ($xmlLoadingGroup -eq "*"))){
							# Write-Color "    {yellow}XML Skipped{gray} - {white}Arg Loading Group: {gray}$($argLoadingGroup), {white}Xml Loading Group: {gray}$($xmlLoadingGroup)"
							continue
						}
					}
					
					Write-Color "  {write}Found:{gray} $($file)"
					Write-Color "     XML Loaded"
					
					$this.PopulateFromXml($xmlContent.FirstChild, $this.rootScope)
					Write-Color "     {green}XML Parsed{gray}"
				}
				catch{
					Write-Color "     {red}XML Failed{gray}"
				    $this.Error("XMLParsing", "Failed to parse xml file {white}$($file){gray}`r`n{gray}$($_.Exception.Message)`r`n$($_.Exception.StackTrace)`r`n$($_.ScriptStackTrace)")
				}	
                

				$this.PopLocation()
				$this._filesVisited.Add($file)
			}
		}
		$this.PopParmeterizingEnabled()
	}
	[hashtable] ExtractXHeading([String] $file){
		if(-not ([System.IO.File]::Exists($file))){
			$this.Error("File '{white}$($file){gray}' was not found. Unable to extract the {white}XHeading{gray}")
			return $null;
		}

		$content = Get-Content $file -Raw
		if(-not $content){
			$this.Error("No content found in '{white}$($file){gray}'. Unable to extract the {white}XHeading{gray}")
			return $null;
		}

		$header = [regex]::Match($content, '\:xheader\:([\s\S]+)\:xheader\:')
		if(-not $header -or -not $header.Success){
			$this.Error("Failed to find the header of the file '{white}$($file){gray}'. Unable to extract the {white}XHeading{gray}")
			return $null;
		}

		$header = $header.Groups[1].Value
		$matches = [regex]::Matches($header, '#([^\=]+)\=([^;]+)')
		$heading = [hashtable]::new()
		foreach($match in $matches){
			$name = $match.Groups[1].Value
			$value = $match.Groups[2].Value

			$heading.Add($name, $value)
		}

		return $heading

	}
	[void] PopulateFromXScript([string] $file){

        
        
		$heading = $this.ExtractXHeading($file)
		if(-not $heading){
			$this.Error("Unable to populate using the XScript '{white}$file{gray}'. No Heading was found")
			return;
		}

		if(-not $heading.Type){
			$this.Error("Unable to populate using the XScript '{white}$file{gray}'. No type was found in heading")
			return;
		}

		$name = [regex]::Replace($([System.IO.Path]::GetFileName($file)), '^(.*)\.xscript\.ps1$', '$1') 
		# Write-Color "Loading {white}$($name){gray}"; 
		if($heading.Type -eq "ParameterType"){
			$type = [UIParameterTypeDefinition]::new($this.Context(), $name, "ScriptFile", $file, $this.CurrentScope())
			$collection = $this.CurrentScope().ParameterTypes()
		}
		elseif($heading.Type -eq "InputType"){
			$type = [UIInputTypeDefinition]::new($this.Context(), $name, "ScriptFile", $file, $this.CurrentScope())
			$collection = $this.CurrentScope().InputTypes()
		}
		elseif($heading.Type -eq "ActionType"){
			$type = [UIActionTypeDefinition]::new($this.Context(), $name, "ScriptFile", $file, $this.CurrentScope())
			$collection = $this.CurrentScope().ActionTypes()
		}
		elseif($heading.Type -eq "ExtensionType"){
			$type = [UIConfigMasterExtensionType]::new($this.Context(), $name, "ScriptFile", $file, $this.CurrentScope())
			$collection = $this.CurrentScope().ExtensionTypes()
		}
		elseif($heading.Type -eq "LoggingType"){
			$type = [UILoggingTypeDefinition]::new($this.Context(), $name, "ScriptFile", $file, $this.CurrentScope())
			$collection = $this.CurrentScope().LoggingTypes()
		}
		else{
			$this.Error("Unknown heading type '{white}$($heading.Type){gray} found in XScript '{white}$file{gray}'. `r`n"+ `
			            "   Only {white}ParameterType{gray}, {white}InputType{gray}, {white}ActionType{gray}, or {white}ExtensionType{gray} are current available")
			return;
		}

		
		if(-not $type.InitialProps($heading, $(Get-Content $file -Raw), $null, $file)){
			$this.Error("Unable to update the props for '{white}$($name){gray}' of type '{white}$($heading.Type){gray}' from xscript '{white}$($file){gray}'")
			return;	
		}

		if(-not $collection.Add($type)){
			$this.Error("Unable to add '{white}$($name){gray}' of type '{white}$($heading.Type){gray}' from xscript '{white}$($file){gray}' to collection named '{white}$($collection.Name()){gray}'")
			return;	
		}

	}
	
    [void] PopulateFromXScriptsInFolder([String] $folder, [int] $maxDepth){
		$this.Context().StartLoggingContext("Load Xscript(s)")
		$xscriptFiles = Get-ChildItem -Path $folder -Filter "*.xscript.ps1" -Recurse -Depth 5 | Where {[System.IO.File]::Exists($_.FullName)} | Foreach {$_.FullName}
		$this.Title("XScripts Files")
		$this._logLock = $true
		$xscriptFiles | ForEach-Object { 
			# Write-Color "Loading {white}$($_){gray}"; 
			$this.PushLocation($_)
			$this.PopulateFromXScript($_)
			$this.PopLocation()
			# Write-Color "";
		}
		$this._logLock = $false
		$this.Context().EndLoggingContext()
		
	}
    [void] PopulateFromFolder([String] $folder, [int] $maxDepth){
		
		$this.Context().StartLoggingContext("Load XConfigMaster Files")
		$files = Get-ChildItem -Path $folder -Filter "*.xconfigmaster" -Recurse -Depth $maxDepth | Where {[System.IO.File]::Exists($_.FullName)} | Foreach {$_.FullName}
		$xmls  = $files | Foreach {@{Xml = ([XML](Get-Content $_ -Raw)); File = $_; Used = "Yes"}}
		
		$inits = @($xmls  | Foreach {@{Xml = $_.Xml.SelectSingleNode("//XConfigMaster.Init"); File = $_.File; Original = $_}} | Where {$_.Xml} | Where {-not ([String]::IsNullOrEmpty($_.Xml.InnerXml)) }) | Foreach {@{Xml = (([XML]"<XConfigMaster.Init>$($_.Xml.InnerXml)</XConfigMaster.Init>").FirstChild); File=($_.File)}}   
		$pre   = @($xmls  | Foreach {@{Xml = $_.Xml.SelectSingleNode("//XConfigMaster.PreLoad"); File = $_.File}}             | Where {$_.Xml} | Where {-not ([String]::IsNullOrEmpty($_.Xml.InnerXml)) }) | Foreach {@{Xml = (([XML]"<XConfigMaster.PreLoad>$($_.Xml.InnerXml)</XConfigMaster.PreLoad>").FirstChild); File=($_.File)}}      
		$main  = @($xmls  | Foreach {@{Xml = $_.Xml.SelectSingleNode("//XConfigMaster.Load"); File = $_.File}}                | Where {$_.Xml} | Where {-not ([String]::IsNullOrEmpty($_.Xml.InnerXml)) }) | Foreach {@{Xml = (([XML]"<XConfigMaster.Load>$($_.Xml.InnerXml)</XConfigMaster.Load>").FirstChild); File=($_.File)}}      
		$post  = @($xmls  | Foreach {@{Xml = $_.Xml.SelectSingleNode("//XConfigMaster.PostLoad"); File = $_.File}}            | Where {$_.Xml} | Where {-not ([String]::IsNullOrEmpty($_.Xml.InnerXml)) }) | Foreach {@{Xml = (([XML]"<XConfigMaster.PostLoad>$($_.Xml.InnerXml)</XConfigMaster.PostLoad>").FirstChild); File=($_.File)}}      
		$na    = @($xmls  | Where {$_.Used -eq "No"})
		if($na){
			$this.Error("There were $($na.Count) files that had no loading tags in existence:   $(@($na | Foreach {$_.File}) -join "`r`n   ")")
			return
		}
		###################################################################
		#                        I N I T   F I L E S                      #
		###################################################################
		$this.Title("Init Files")
		$this._logLock = $true
		$inits | Foreach {
			Write-Color "Loading {white}$($_.File){gray}"; 
			$this.PushLocation($_.File)
			$this.PopulateFromXml($_.Xml, $this.rootScope)
			$this.PopLocation()
			Write-Color "";
		}
		$this._logLock = $false
		
		

		###################################################################
		#                        P R E     F I L E S                      #
		###################################################################
		$this.Title("Pre Files")
		$pre | Foreach {
			Write-Color "{magenta}:: {white}$($_.File){gray}";
			$this.PushIndent()
			$this.PushLocation($_.File)
			$this.PopulateFromXml($_.Xml, $this.rootScope)
			$this.PopLocation()
			$this.PopIndent()
			Write-Color "";
		}
		
		
		###################################################################
		#                        M A I N   F I L E S                      #
		###################################################################
		$this.Title("Main Files")
		$main | Foreach {
			Write-Color "{magenta}:: {white}$($_.File){gray}";
			$this.PushIndent()
			$this.PushLocation($_.File)
			$this.PopulateFromXml($_.Xml, $this.rootScope)
			$this.PopLocation()
			$this.PopIndent()
			Write-Color "";
		}
		
		###################################################################
		#                        P O S T   F I L E S                      #
		###################################################################
		$this.Title("Post Files")
		$post | Foreach {
			Write-Color "{magenta}:: {white}$($_.File){gray}";
			$this.PushIndent()
			$this.PushLocation($_.File)
			$this.PopulateFromXml($_.Xml, $this.rootScope)
			$this.PopLocation()
			$this.PopIndent()
			Write-Color "";
		}

		$this.Context().EndLoggingContext()
		

    }
    [void] PopulateFromXml([System.Xml.XmlElement] $xmlElement, [System.Object] $for){
		$this.PopulateFromXml($xmlElement, $for, $true)
	}
    [void] PopulateFromXml([System.Xml.XmlElement] $xmlElement, [System.Object] $for, [bool] $splitRefs){
		
		if($this.ExitRequested()){
			$this.Error("User Exiting...")
			return
		}
		
		try{
			$this.PushIndent()
			
			### INFO: Does Transformations of the XML based on UIConfigMasterExtensionCollection ###
			### BUG CHECK: From the look of this line, it seems like there will be issues when you are expecting extensions to be consumed based on hiercy ###
			###            Essentially, this is saying it will get the 'RootScope' and use the extensions from there, instead of using the 'CurrentScope'  ###
			$xmlElement = $this.Context().GetRootScope().Extensions().ApplyExtension($xmlElement)

			# $this.Display("{magenta}FullParsing {white}$($this.FullParsing()){gray}")

			### INFO: We dont want to dig deep into the XmlTree if we are not doing full parsing ###
			### INFO: This is mainly used to avoid real parsing... But we need to find more on why this was done ###
			if(-not $this.FullParsing()){
				
				# $this.Display("{magenta}Owner Filter: {white}$($xmlElement.OwnerDocument.FirstChild.GetAttribute("Filtered")){gray}")
				
				### INFO: Not sure if this is still valid, since no where we are setting this attribute ###
				if(-not ($xmlElement.OwnerDocument.FirstChild.GetAttribute("Filtered") -ieq "true") -and ($xmlElement.LocalName -ne "Template"))
				{
					
					if($xmlElement.SelectNodes("//*[@Ref and @Name]").Count -gt 0){
					
						$measured = Measure-Command {
							$new = $xmlElement.CloneNode($true)

							$root = $new.SelectSingleNode("//ConfigAutomation")
							if(-not $root){
								$root = $new
							}
							
							### INFO: Essentially removing any xml elements that either are or have 'Ref' defining items so that all thats left are 'Ref' defining items ###
							$items = $null
							do{
								$items = $root.SelectNodes(".//*[not((@Ref and @Name) or count(.//*[@Ref and @Name]) != 0)]") | Foreach {$_.ParentNode.RemoveChild($_)}
							}while($items)
							
							# $this.Display($new.OuterXml)

							### INFO: We want to now populate the XML that contains only 'Ref' defining items ###
							### BUG CHECK: Why are we setting 'FullParsing' to true. This will cause it to do another filtering on the xml item ###
							$this.FullParsing($true)
							$this.SaveXmlEnabled($false)
							$this.PopulateFromXml($new, $this.GetRootScope(), $false)
							$this.SaveXmlEnabled($true)
							$this.FullParsing($false)
							
							
							$refElements = $xmlElement.SelectNodes("//*[@Ref and @Name]")
							foreach($element in $refElements){
								$element.RemoveAttribute("Name")
							}
							
						}
						# $this.Display("{yellow}Refs{gray} - Populating XML - {magenta}$($measured.TotalMilliseconds) milisec{gray} {white}$($xmlElement.LocalName) | {magenta}$((($xmlElement.ChildNodes | Foreach {$_.LocalName} | Get-Unique) -join ',')){gray}")
					}
					# $xmlElement.OwnerDocument.FirstChild.SetAttribute("Filtered","true")
				}
			}
			
			
			# $this.Context().Display("Traversing", "Consuming Xml for $($for.FullName()){gray}`r`n{white}XML:{gray}`r`n$($xmlElement.Outerxml | Format-Xml)`r`n`r`n")
			# - - - - - - - - Consume all Consumable Xml Items - - - - - - - - 
			$measured = Measure-Command {
				$propertiesMeasured = Measure-Command {
					if($for.psobject.properties -match "__ALL_PROPERTIES__"){
						$properties = $for.__ALL_PROPERTIES__
					}
					else{
						$properties = [Helper]::GetAllProperties($for)
						$for | Add-Member -MemberType NoteProperty -TypeName Array -Name "__ALL_PROPERTIES__" -Value $properties -Force
					}
				}
				# $this.Display("{yellow}Get Props{gray} - $($properties.Count) Properties found - {magenta}$($propertiesMeasured.TotalMilliseconds) milisec{gray}")
				foreach($property in $properties){
					
					if($property.Name -match ".*_local$"){
						continue
					}
					
					$propertyName  = $property.Name
					$propertyValue = $for.$propertyName
					
					# $this.Context().Display("Traversing", "{magenta}$($for.GetType().Name){gray} - {white}$($property.Name){gray} - {magenta}$($propertyValue.GetType().Name){gray}")
					
					if($propertyValue -and $propertyValue -is [HasConsumableContext]){
						$propertyValue.PopulateFromXML($xmlElement)
					}
				} 
			}
			
			# $this.Display("{yellow}Normal{gray} - Populating XML - {magenta}$($measured.TotalMilliseconds) milisec{gray} {white}$($xmlElement.LocalName) | {magenta}$((($xmlElement.ChildNodes | Foreach {$_.LocalName} | Get-Unique) -join ',')){gray}")
			$this.PopIndent()
		}
		catch{
			$this.Error("Parsing of XML failed.`r`n{white}Error Message:{gray}`r`n$($_.Exception.Message)`r`n`r`n{white}Stack Trace:{gray}`r`n$($_.ScriptStackTrace)")
		}
    }
    [void] PopulateFromXml([System.Xml.XmlElement] $xmlElement){
        $this.PopulateFromXml($xmlElement, $this)
    }

    # [System.Management.Automation.RuntimeDefinedParameterDictionary] CreateRuntimeArgumentDictionary(){
        # $dictionary = $this.Context().GetDynamicParameters()
        # Parameter Attributes...
		
		# $scopes           = $this.GetAllScopes()
		# $scopesNames      = $scopes | Foreach { $_.Name() }
		# $scopesNamesSplit = $scopesNames -join ","
		
		# Write-Host $scopesNamesSplit
		
		# foreach($scope in $scopes){
			# Write-Host "Gathering Parameters for $($scope.Name())"
			# $parameters = $scope.Parameters().Items()
			# Go through parameters
			# foreach($parameter in $parameters) {
				# Write-Host "   Parameter $($parameter.ParameterName())"
				# $parameter.ParameterType().Definition().GenerateDynamicParameters($dictionary, $parameter, $scope.Inputs())
			# }
		# }
        
    #    return $dictionary

    # }
	
	[String] ToString(){
		$content = "Automation ConfigMaster`r`n"
		$content += "  "+$this.rootScope.ToString().Replace("`r`n","`r`n  ")+"`r`n"
		
		return $content
	}
}
Function New-ConfigAutomationContext([string]$personalAccessToken, [string]$account){
    return [ConfigAutomationContext]::new($personalAccessToken, $account)
}

Export-ModuleMember -Function New-ConfigAutomationContext

Function Start-XConfigMaster{
	Process{ 
		 #######################################################################
		 #######################################################################
		 #######################################################################
		 try{
			if(-not ($args -and $args[0] -eq "AllowStop")){
				write-host "Turning Off Ctrl-C Exit"
				[console]::TreatControlCAsInput = $true
			}
			else{
				write-host "Turning On Ctrl-C Exit"
				[console]::TreatControlCAsInput = $false
				$args = $args[1..$(@($args.Count))]
			}
		 }
		 catch{
			write-host "Unable to turn off ctrl-C exits"
		 }
		 
		 #######################################################################
		 #######################################################################
		 #######################################################################
		 $rootpath = Get-Location

		#######################################################################
		#######################################################################
		#######################################################################
		$parameters = New-Object System.Collections.Hashtable( (new-Object System.Collections.CaseInsensitiveHashCodeProvider), (New-Object System.Collections.CaseInsensitiveComparer) )
		$actions    = @()
		for($i=0;$i -lt$args.length;$i+=1){
			
			if(-not ($args[$i].GetType() -eq [string])){
				$automationContext.Error("Arg[$($i)] - Not a string and was expecting it to be")
				continue
			}
			
			if($args[$i] -match "^\-+(.*)"){
				$argName = $Matches[1]
				if(($i+1) -ge $args.length){
					$parameters.Add($argName, $true)
					continue
				}
				
				$parameters.Add($argName, $args[$i+1])
				$i+=1
				continue
			}
			
			if($args[$i] -match "^\/(.*)"){
				$actions += $Matches[1]	
				continue
			}
			
			$actions += $args[$i]
			
		}

		#######################################################################
		#######################################################################
		#######################################################################
		$version = (Get-Module XConfigMaster).Version
		$version = $version.ToString()
		Write-Host $version

		if($parameters["Version"]){
			$expectedVersion = $parameters["Version"]
			
			if($expectedVersion -ne $version){
				$versions = Get-InstalledModule -Name XConfigMaster -AllVersions | ForEach-Object {$_.Version.ToString()}
				$command = ""
				if(-not ($expectedVersion -in $versions)){
					$command += "Update-Module XConfigMaster -RequiredVersion $expectedVersion -Force `r`n"
				}
				$command += "Remove-Module XConfigMaster -Force`r`n"
				$command += "Import-Module XConfigMaster -RequiredVersion $expectedVersion -Force`r`n"
				$argumentList = ""
				for($i=0;$i -lt$args.length;$i+=1){
					$argumentList += $args[$i] + " "
				}
				$workingDirectory = $rootpath
				$command += "xcm $($argumentList)`r`n"
				Write-Host "$expectedVersion -ne $version (Switching)"
				Write-Host $command
				$scriptBlock = [ScriptBlock]::Create($command)
				&$scriptBlock
				return
			}
		}

		$parseFolder = [System.IO.Path]::Combine($rootpath, ".\")
		$toolingFolder = [System.IO.Path]::Combine($PSScriptRoot,"..\")
		$htmlOutputFile = [System.IO.Path]::Combine($rootpath, ".\xlog.html")

		#######################################################################
		#######################################################################
		#######################################################################
		if(-not $Global:automationContext -or $parameters["Force"]){
			$Global:automationContext = New-ConfigAutomationContext
			$Global:automationContext.PopulateFromArguments($parameters)
			
			
			# Read in Settings
			Write-Host "Reading in Settings..." 
			
			
			$Global:automationContext.PopulateFromXScriptsInFolder($toolingFolder, 12)
			$Global:automationContext.PopulateFromXScriptsInFolder($parseFolder, 12)

			$Global:automationContext.PopulateFromFolder($toolingFolder, 12)
			$Global:automationContext.PopulateFromFolder($parseFolder, 12)
		}
		else {
			$Global:automationContext.StartSession()
			$Global:automationContext.PopulateFromArguments($parameters)
		}
		
		#######################################################################
		#######################################################################
		#######################################################################
		if($Global:automationContext.IsValid()) {
			Write-Host "Parsing Passed!`r`n" -ForegroundColor Green
			
			$Global:automationContext.ExecuteActionsFromArguments($actions)
			$Global:automationContext.WriteHtmlLog($htmlOutputFile)
			if($Global:automationContext.IsValid()){
				Write-Host "Execution Passed!`r`n" -ForegroundColor Green
			}
			else{
				throw "Execution Failed`r`n" 
			}
		}
		else {
			$Global:automationContext.WriteHtmlLog($htmlOutputFile)
			throw "Parsing Failed`r`n"
		}
	}

}
Export-ModuleMember -Function Start-XConfigMaster
New-Alias -Name "xcm" -Value Start-XConfigMaster
Export-ModuleMember -Alias "xcm"
