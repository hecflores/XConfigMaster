#:xheader:
#Type=LoggingType;
#:xheader:

function WriteColor() {
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

return @{

    Init = 
    {
        Param([ConfigAutomationContext] $context, [UILogger]$logger)

        [Helper]::SetPropertyIfNotExists($logger, "string", "Indention", [HasContext]::Prefix)
    };
    Log = 
    {
        Param([ConfigAutomationContext] $context, [UILogger]$logger, [string] $log)
        
        Write-Color "$log"
    };
    Indent = 
    {
        Param([ConfigAutomationContext] $context, [UILogger]$logger, [int] $indention)
        $indentionSize = 2
        $indentionChars = (@(0..$indentionSize) | Foreach-Object {" "}) -join ""

        if($indention -gt 0){
            $logger.Indention += (@(0..$indention) | Foreach-Object {$indentionChars}) -join ""
        }
        elseif($indention -lt 0){
            $logger.Indention = $logger.Indention.Substring($indentionSize * ($indention * -1))
        }
        else{
            throw "Unable to indent by 0"
        }
    };
    Milestone = 
    {
        Param([ConfigAutomationContext] $context, [UILogger]$logger, [string] $message, [string] $type)

        Write-Color "`r`n$($logger.Indention):: $type - $message ::`r`n"
    }
}