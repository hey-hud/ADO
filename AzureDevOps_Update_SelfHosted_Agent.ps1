param (
    [string]$URL,
    [string]$PAT,
    [string]$POOL,
    [string]$AGENT
)

Write-Host "start"

Get-Service vstsagent.devops.$POOL.$AGENT | Stop-Service -Force

if (test-path "c:\$AGENT")
{
    #Remove-Item -Path "c:\$AGENT" -Confirm:$false -Recurse -Force 
    $Path = "c:\$AGENT"

    function Get-Tree($Path,$Include='*') { 
    @(Get-Item $Path -Include $Include -Force) + 
        (Get-ChildItem $Path -Recurse -Include $Include -Force) | 
        sort pspath -Descending -unique
    } 

    function Remove-Tree($Path,$Include='*') { 
        Get-Tree $Path $Include | Remove-Item -force -recurse
    } 

    Remove-Tree $Path
}

new-item -ItemType Directory -Force -Path "c:\$AGENT"
set-location "c:\$AGENT"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$wr = Invoke-WebRequest https://api.github.com/repos/Microsoft/azure-pipelines-agent/releases/latest
$tag = ($wr | ConvertFrom-Json)[0].tag_name
$tag = $tag.Substring(1)

write-host "$tag is the latest version"
$url = "https://vstsagentpackage.azureedge.net/agent/$tag/vsts-agent-win-x64-$tag.zip"

Invoke-WebRequest $url -Out agent.zip
Expand-Archive -Path agent.zip -DestinationPath $PWD
.\config.cmd --unattended --url $URL --auth pat --token $PAT --pool $POOL --agent $AGENT --acceptTeeEula --runAsService
