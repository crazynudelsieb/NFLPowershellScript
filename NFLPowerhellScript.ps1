#NFLPowershellScript

function get-nflresults {

    <#
      .SYNOPSIS
      get-nflresults fetches the weekly results from Footballdb.com
      .DESCRIPTION
      This function is the base of our pickem league, the game will be build around it for a full automated setup
      I use powershell because I am lazy
      .PARAMETER week
      Current week is default, can be used for fetching older results
      .PARAMETER season
      Current Year is default, can be used for fetching older results
      .EXAMPLE
      get-nflresults -week 3
      get-nflresults -season 2019
      .NOTES
      Created by    : Michael van der Heijden
      Script Version: 1.0.0.0
      Copyright    : NudelvanSieb
  #>

    [CmdletBinding()]
    param(
        [int]$week = (get-date -UFormat %V) - 36, 
        [int]$season = (get-date -Format yyyy))

    $url = "http://www.footballdb.com/scores/index.html?lg=NFL&yr=" + "$season" + "&type=reg&wk=" + "$week"
    $webresponse = Invoke-WebRequest $url
    $results = ($webresponse.AllElements | Where-Object { $_.Tagname -eq "Table" }).outerhtml
    
    $array = @()

    foreach ($Result in $results) {
    
      
        $matches = $null
        $result -match '.*\n.*\n.*\n.*>(?<Date>.*)<\/th>\n.*\n.*\n.*\n.*\n.*="(?<Visitor>.*)\sS.*\n.*<b>(?<VResult>.*)<\/b>.*\n.*\n.*e="(?<Home>.*)\sS.*\n.*<b>(?<HResult>.*)<\/b' | out-null
        
        if ($matches) {
    
            $object = New-Object -TypeName PSObject
            $object | Add-Member -Name 'Home' -MemberType Noteproperty -Value $Matches.Home
            $object | Add-Member -Name 'Visitor' -MemberType Noteproperty -Value $Matches.Visitor
            $object | Add-Member -Name 'HResult' -MemberType Noteproperty -Value $Matches.HResult
            $object | Add-Member -Name 'VResult' -MemberType Noteproperty -Value $Matches.VResult
            $object | Add-Member -Name 'Date' -MemberType Noteproperty -Value $Matches.Date
            if ($Matches.HResult -ne $Matches.VResult) {
                if ($Matches.HResult -gt $Matches.VResult) {
                    $object | Add-Member -Name 'Winner' -MemberType Noteproperty -Value $Matches.Home
                }
                else {
                    $object | Add-Member -Name 'Winner' -MemberType Noteproperty -Value $Matches.Visitor
                }
            }
            Else {
                $object | Add-Member -Name 'Winner' -MemberType Noteproperty -Value "Unendschieden"
            }
            $array += $object
    
        }
        else {
            break
        }
            
    }
    
    

    
    
    $array = $array | Sort-Object date -Descending
    
    
    Write-Host -BackgroundColor Yellow -ForegroundColor Black "The Results of Week $week of the $season Season:"
    write-host
    foreach ($entry in $array) {
    
        $date = $entry.date
        $winner = $entry.winner
        $hteam = $entry.Home
        $vteam = $entry.Visitor
        $homeresult = $entry.HResult
        $visitorresult = $entry.VResult
    
    
        Write-Host "$date -> $hteam ($homeresult) : ($visitorresult) $vteam -> " -NoNewline
        if ($winner -eq "Unendschieden") {
            write-host -ForegroundColor Green "Winner: $winner"
        }
        else {
            write-host -ForegroundColor Yellow "Winner: $winner"
        }
    }
}


function get-nflseasonresults {

    <#
      .SYNOPSIS
      get-nflseasonresults fetches the weekly results from Footballdb.com for a whole season
      .DESCRIPTION
      This function is the base of our pickem league, the game will be build around it for a full automated setup
      I use powershell because I am lazy
      .PARAMETER season
      Year of the season, no garantie, that this will work for older seasons
      .EXAMPLE
      get-nflseasonresults
      get-nflseasonresults -season 2018
      
      .NOTES
      Created by    : Michael van der Heijden
      Script Version: 1.0.0.0
      Copyright    : NudelvanSieb
  #>
    [CmdletBinding()]
    param( 
        [int]$season = (get-date -Format yyyy))


    $req01 = invoke-webrequest "http://www.footballdb.com/scores/index.html"
    $weekurls = $req01.Links | Where-Object { $_.innerHTML -like "Regular Season Week*" }  | Select-Object href


    foreach ($weekurl in $weekurls) {
        $weeknumbers = $weekurl.href.replace('/scores/index.html?lg=NFL&amp;yr=2020&amp;type=reg&amp;wk=', '') -as [int]
        
        foreach ($weeknumber in $weeknumbers) {
          
            if ($season -eq (get-date -Format yyyy)) {

                if ($weeknumber -le ((get-date -UFormat %V) - 36)) {
     
                    get-nflresults $weeknumber

                }
                else {

                    break

                }



            }
            else {
                get-nflresults $weeknumber $season
            }
        }


    

    }
}