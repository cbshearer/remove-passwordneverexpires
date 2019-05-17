import-module ActiveDirectory

clear-host  

$searchbaseROOT = "DC=your,DC=local"
$searchbase     = $searchbaseROOT
$Days           = 70                     ## How many days back you want to go looking for passwords, keep in mind what your policy is
$n              = 0
$server         = "your-dc01.your.local" ## FQDN of you primary DC where all data will be read from and changes made to

Function remove-PassNeverExpiresFlag 

    
    {   $date           = Get-Date
        $MaxAge         = ($Date).Adddays(-($Days)) 
        $users          = Get-ADUser -server $server -Properties LastLogondate, passwordlastset, cannotchangepassword, DistinguishedName -Filter {(PasswordNeverExpires -eq "True") -And (Enabled -eq "True") -And (Passwordlastset -gt $MaxAge)  -And (Name -notlike "*HealthMailbox*")  -AND (name -notlike "IUSR_*") -And (Name -notlike "IWAM_*") -And (Name -notlike "Service_*") -And (Name -notlike "LDAP_ANONYMOUS") } -SearchBase $SearchBase 
       
        if (($users.count -eq 0) -or ($user.passwordneverexpires -like 'true') )
            { write-host "`nNo users match criteria." }
        else {
        
        foreach ($user in $users)
            {
               if ($user.CannotChangePassword -eq 'True') 
                   { 
                     write-host "`nRemoving 'password never expires for: " -nonewline; write-host -f cyan $user.name
                     write-host "     ..." -nonewline; write-host -f red "failure" -nonewline; write-host ". User cannot change password." $user.samaccountname
                   }

               Else {
                
                 write-host "`nRemoving 'password never expires' for: " -nonewline; write-host -f cyan $user.name                
                 
                 Set-ADUser -server $server $user -PasswordNeverExpires $false
                 
                 # check to make sure it took.
                 $check = Get-ADUser -server $server $user -properties *
                 
                 if ($check.passwordneverexpires -like 'false')
                    {
                        write-host "     ..." -nonewline; write-host -f green "success" -nonewline; write-host "."
                    }
                 else { write-host -f red "     something went wrong :(" }

               }
            }
            }
    }

Function check-PassNeverExpiresFlag
    {   $date           = Get-Date
        $MaxAge         = ($Date).Adddays(-($Days)) 
        $users          = Get-ADUser -server $server -Properties LastLogondate, passwordlastset, cannotchangepassword, DistinguishedName -Filter {(PassWordNeverExpires -eq "True") -And (Enabled -eq "True") -And (Passwordlastset -gt $MaxAge) -And (Name -notlike "*HealthMailbox*")  -AND (name -notlike "IUSR_*") -And (Name -notlike "IWAM_*") -And (Name -notlike "Service_*") -And (Name -notlike "LDAP_ANONYMOUS") } -SearchBase $SearchBase 
        
        foreach ($user in $users) {
            $check   = Get-ADUser -server $server -identity $user -Properties PasswordNeverExpires, PasswordLastSet, LastLogonDate, CannotChangePassword, whencreated # | select-object PasswordNeverExpirs, PasswordLastSet, LastLogonDate, CannotChangePassword, WhenCreated, name, @{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}} #| ft name,passwordneverexpires,passwordlastset
            $expDate = Get-ADUser -server $server -identity $user –Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed" | Select-Object -Property @{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}
            
            if (($check.PasswordNeverExpires -like 'true' ) -and ($check.CannotChangePassword -like 'true')) 
                { }                                                                                                                                                                                                                                                                                                                                                     
        
        else {
        
            write-host "User: " -NoNewline; write-host -f cyan $check.Name
            
            # Find password age in days
                            $pwage = $date - $check.passwordlastset
                            $pwage = [math]::Round($pwage.totaldays,2)
                            write-host "Password Age    :                " $pwage "days"
                                

            # If it never expires, say so in red
                if ($check.PasswordNeverExpires -like 'true')
                    {
                        write-host "Pass never expires? " -NoNewline; write-host -f Red "             " $check.PasswordNeverExpires
                    }
    
            # If it expires, say so in happy green
                if ($check.PasswordNeverExpires -like 'false')
                    {
                            write-host "Pass never expires? " -NoNewline; write-host -f Green "             " $check.PasswordNeverExpires
                    }
                            write-host "Pass last set on:                " $check.PasswordLastSet
                            write-host "User last logon :                " $check.LastLogontimestamp
                            write-host "User created on :                " $check.whencreated
                            write-host "Pass exp. date  :                " $expDate.ExpiryDate
                            write-host "SAMAccountName  :                " $user.samaccountname

            # If user cannot change their password, say so in red
                if ($check.CannotChangePassword -like 'true')
                    {
                        write-host "Cannot change password? " -NoNewline; write-host -f Red "         " $check.CannotChangePassword
                        # i should also add these to an object to output at the end 
                        ## Removing 1 from the count
                        $n = $n - 1 
                    }
   
            # If they can, say so in happy green
                if ($check.CannotChangePassword -like 'false')
                    {write-host "Cannot change password?" -NoNewline; write-host -f Green "          " $check.CannotChangePassword}
            
            #Counter and last line  
            $n = $n + 1
            write-host "Count" $n
            write-host ""
            }
    }
        
        $endtime = get-date
        if ($n -eq 0) 
             { write-host -f green "`n`nNo users found for selected time period " -nonewline; write-host $days -nonewline; write-host -f green " days."
               write-host "Completed check at: " -nonewline; write-host -f cyan $endtime }
        else { write-host -f green "`n`nNumber of users with non-expiring passwords: " -nonewline; write-host $n 
               write-host -f green "And changed within the past: " -nonewline; write-host $days -nonewline; write-host -f green " days"
               write-host "Completed check at: " -nonewline; write-host -f cyan $endtime }
    
    }
    
Function check-PasswordAge
    {    $outfile          = "c:\logs\PasswordNotChangers-$(get-date -f yyyy-MM-dd_h-m-ss_tt).csv"
         $ExpiredFile      = "c:\logs\PasswordNotChangers-Expired-$(get-date -f yyyy-MM-dd_h-m-ss_tt).csv"
         $date             = Get-Date
         $MaxAge           = ($Date).Adddays(-($Days)) 
         $policyMaxAgeDays = 90
         $policyMaxAge     = ($date).Adddays(-($policyMaxAgeDays)) 
         $m                = 0
         $p                = 0
         $d                = 0
         $a                = 0
         $l                = 0
               
          ## users with old passwords that DONT have to change them
             $users            = Get-ADUser -server $server -Properties passwordlastset,cannotchangepassword,msDS-UserPasswordExpiryTimeComputed,passwordneverexpires,lastLogontimestamp -Filter { (Enabled -eq "True") -And (Passwordlastset -lt $policyMaxAge) -And (passwordneverexpires -eq $true) -And (Enabled -eq "True") -And (Name -notlike "*HealthMailbox*")  -AND (name -notlike "IUSR_*") -And (Name -notlike "IWAM_*") -And (Name -notlike "Service*") -And (Name -notlike "LDAP_ANONYMOUS") } -SearchBase $SearchBase 
                                                                                                                                                                             
          ## users with old passwords that need to change them
             $middleUsers      = Get-ADUser -server $server -Properties passwordlastset,cannotchangepassword,msDS-UserPasswordExpiryTimeComputed,passwordneverexpires,lastLogontimestamp -Filter { (Enabled -eq "True") -And (Passwordlastset -lt $policyMaxAge) -And (passwordneverexpires -eq $false) -And (Enabled -eq "True") -And (Name -notlike "*HealthMailbox*")  -AND (name -notlike "IUSR_*") -And (Name -notlike "IWAM_*") -And (Name -notlike "Service*") -And (Name -notlike "LDAP_ANONYMOUS")  } -SearchBase $SearchBase 
      
          ## users with young passwords
             $otherUsers       = Get-ADUser -server $server -Properties passwordlastset,cannotchangepassword,msDS-UserPasswordExpiryTimeComputed,passwordneverexpires,lastLogontimestamp -Filter { (Enabled -eq "True") -And (Passwordlastset -ge $policyMaxAge) -And (Enabled -eq "True") -And (Passwordlastset -gt $MaxAge) -And (Name -notlike "*HealthMailbox*")  -AND (name -notlike "IUSR_*") -And (Name -notlike "IWAM_*") -And (Name -notlike "Service*") -And (Name -notlike "LDAP_ANONYMOUS") } -SearchBase $SearchBase 
                
         write-host ""
         write-host ""
         write-host "Passwords must have been created on or after " -nonewline; write-host -f green $policyMaxAge -nonewline; write-host " to be compliant with policy."

         ## Users that can change their passwords, AND have old ones any ways AND passwords never expire
             foreach ($user in $users) 
                {
                    ## connvert LastLogonTimesttamp to human-readable format
                    $l = [DateTime]::FromFileTime($user.lastlogontimestamp)
                  
                    if (($user.cannotchangepassword -eq $false) -and ($user.PasswordLastSet)) ## Users with old passswords AND can change them AND never forced to change them
                        {
                            $m = $m +1
                            Get-ADUser -server $server $user -properties title,manager,mail,created,lastlogondate,passwordlastset,msDS-UserPasswordExpiryTimeComputed,passwordneverexpires,office,lastLogontimestamp | 
                                sort-object name | 
                                Select-Object -Property name,samaccountname,title,office,created,passwordlastset,mail,manager,passwordneverexpires, `
                                @{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}, `
                                @{Name="LastLogon";Expression={[datetime]::fromfiletime($_."LastLogontimestamp")}} | 
                                export-csv $outfile -append
                            
                        }
                }
         
         ## Users that can change their passwords, AND have old ones, AND have to change them - these are probably expired passwords
             foreach ($donkey in $middleUsers)
                {
                    if (($donkey.cannotchangepassword -eq $false) -and ($donkey.passwordlastset)) ## Users with young passwords and CAN change them
                        {
                            $d = $d + 1
                            Get-ADUser -server $server $donkey -properties title,manager,mail,created,lastlogondate,passwordlastset,msDS-UserPasswordExpiryTimeComputed,passwordneverexpires,office,lastLogontimestamp | 
                                sort-object name | 
                                Select-Object -Property name,samaccountname,title,office,created,passwordlastset,mail,manager,passwordneverexpires, `
                                @{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}},`
                                @{Name="Last Logon";Expression={[datetime]::fromfiletime($_."LastLogontimestamp")}} | 
                                export-csv $ExpiredFile -append
                        }
                }
                     
         ## Users that can change their passwords, and have passwords less than 90 days old.
             foreach ($Person in $otherUsers)
                {
                    if (($person.cannotchangepassword -eq $false) -and ($person.passwordlastset)) ## Users with young passwords and CAN change them
                        {
                            $p = $p + 1
                        }
                }
         
             $A = $users.count - $m ## all users minus the users taht are non compliant

         write-host ""
         write-host -f cyan $m -nonewline; write-host " users passwords never expire and they have old passwords."
         write-host -f cyan $d -nonewline; write-host " users have old passwords that are expired."
         write-host -f cyan $a -nonewline; write-host " user accounts cannot change their own password AND have passwords older than " -nonewline; write-host -f green $policyMaxAgeDays -nonewline; write-host " days (likely service accounts)."
         write-host -f cyan $p -NoNewline; write-host " users have accounts with passwords younger than " -nonewline; write-host -f green $policyMaxAgeDays -nonewline; write-host " days and can change them."
         write-host "Password not changers exported to: " -nonewline; write-host -f green $outfile
         write-host "Expired password not changers exported to: " -nonewline; write-host -f green $ExpiredFile
      
    }

Function byebye
    {   Clear-Host
$smiley = "
                          oooo############oooo
                      oo########################o
                   oo##############################o         o#   ## o#
   o # oo        o####################################o       ## ## ##o#
oo # #  #      o#########    #############    #########o       ###o##o#
'######o#     o#########      ###########      ##########o    ########
  #######    ###########      ###########      ######################
  #######################    #############    ##############  ''''###
   '###''''#################################################     '###
    ###   o##################################################     '###o
   o##'   ###################################################       ###o
   ###    #############################################' '######ooooo####o
  o###oooo#####  #####################################   o#################
  ########'####   ##################################     ####''''''''
 ''''       ####    '############################'      o###
            '###o     '''##################'##'         ###
              ###o                                    o###
               ####o        HAVE A NICE DAY         o###'
                '####o                           o####
                  '#####oo     ''####o#####o   o####''
                     ''#####oooo  '###o#########'''
                        ''#######oo ##########
                                ''''###########
                                    ############
                                     ##########'
                                      '###''''"
        write-host $smiley
        exit
    }

Function eliminate-PassNeverExpiresFlag
    {
         $date             = Get-Date
         $MaxAge           = ($Date).Adddays(-($Days)) 
         $policyMaxAgeDays = 90
         $policyMaxAge     = ($date).Adddays(-($policyMaxAgeDays))
         $w                = 0
         
        ## users with old passwords that DONT have to change them
            $users = Get-ADUser -server $server -Properties passwordlastset,cannotchangepassword,msDS-UserPasswordExpiryTimeComputed,passwordneverexpires -Filter { (Enabled -eq "True") -And (Passwordlastset -lt $policyMaxAge) -And (passwordneverexpires -eq $true) -And (Name -notlike "*HealthMailbox*")  -AND (name -notlike "IUSR_*") -And (Name -notlike "IWAM_*") -And (Name -notlike "Service*") -And (Name -notlike "LDAP_ANONYMOUS") } -SearchBase $SearchBase 
            foreach ($z in $users) { if ($z.cannotchangepassword -eq $false) {$w = $w + 1}} ## count how many users do not have "cannot change password" flag set.

        ##write-host "You are about to remove the 'Password Never Expires' flag for $users.count users. Are you sure you want to do this?"
        write-host "You are about to remove the 'Password Never Expires' flag for " -nonewline; write-host -f cyan $w -nonewline; write-host " users. Are you sure you want to do this?"
        $confirm = read-host "Please confirm by typinng 'YES'"
        Switch ($confirm) 
            { 'YES'   {write-host -f green "You crazy." 
                        $n = 0
                        ## Users that can change their passwords, AND have old ones any ways AND passwords never expire
                         foreach ($user in $users) 
                            { 
                                if (($user.cannotchangepassword -eq $false) -and ($user.PasswordLastSet)) ## Users with old passswords AND can change them AND never forced to change them
                                    {   write-host "`nRemoving 'password never expires' for: " -nonewline; write-host -f cyan $user.name
                                        $n = $n + 1
                                        write-host "Users attempted so far:" $n
                 
                                        Set-ADUser -server $server $user -PasswordNeverExpires $false
                                            ##write-host -f Magenta "syke"
                                        ## Check my work to see if it took.
                                        $check = Get-ADUser -server $server $user -properties *
                 
                                        if ($check.passwordneverexpires -like 'false') 
                                            { write-host "     ..." -nonewline; write-host -f green "success" -nonewline; write-host "." }
                                        else 
                                            { write-host -f red "     something went wrong :(" }
                                     }
                            }
                     }
            'No'    {write-host -f green "You selected 'no'."
                     main-menu}
            'X'     {byebye}
            default {write-host -f red "Invalid input."
                     main-menu}
            }
    }
   
function main-menu {
    $value = read-host "
        C: Check password never expires flag`
        E: Eliminate password never expires flag for user accounts regardless of age (usercannotchangepassword=0 passwordneverexpires=1)`
        M: Maximum password age compliance`
        R: Remove password never expires flag for users with passwords younger than $days days`
        X: Exit`

    Please make a selection (C/E/M/R/X)"
            Switch ($value)
                {
                'C' {check-PassNeverExpiresFlag
                     Main-Menu}
                'E' {eliminate-PassNeverExpiresFlag
                     main-menu}
                'M' {check-PasswordAge
                     Main-Menu}
                'R' {check-PassNeverExpiresFlag
                     remove-PassNeverExpiresFlag
                     Main-Menu}
                'X' {byebye}
                default {main-menu}
                }
                }
                
main-menu   
