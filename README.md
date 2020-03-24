This Script has 4 functions  
1.  Main-Menu: self-explanitory  
2.  check-passNeverExpiresFlag  
    1. gets current date/time  
    2. subtracts wiggle room from today's date (default 70)  
    3. gets users matching the following critereon:  
        1. PASSWORDLEVEREXPIRES flag set to TRUE  
        2. ENABLED flag set to TRUE  
        3. Password age is within the wiggle period  
        4. iv)  their name is not like "Service_"  
    4. for each of these users  
        1. checks to make sure user CAN change their password, if not, service account is assumed and the remainder are skipped  
        2. returns the password age  
        2. if the PASSWORDNEVEREXPIRES flag is set to true, say so in green  
        2. if the PASSWORDNEVEREXPIRES flag is set to false, say so in red  
        2. additionally return the following properties:  
            1. PasswordLastSet  
            2. LastLogonDate  
            3. Password Expiry date  
        2. if the user CANNOTCHANGEPASSWORD flag is set true, say so in red  
        2. if the user CANNOTCHANGEPASSWORD flag is set false, say so in green  
    2. remove-PassNeverExpiresFlag  
        1. gets current date/time  
        2. subtracts wiggle room from today's date (default 70)  
        3. gets users matching the following critereon:  
            1. PASSWORDNEVEREXPIRES flag set to TRUE  
            2. ENABLED flag set to TRUE  
            3. Password age within the wiggle period  
            4. Their NAME is not like "Service_"  
        4. if this user count is 0, then write to host 'No users match criteria.'  
        5. for each of the users do the following  
            1. if CANNOTCHANGEPASSWORD flag is set to true, say so in red, displaying user NAME and SAMACCOUNTNAME  
            2. otherwise do the following:  
                1. display "Removing 'password never expires' for:" username  
                2. set the AD user account property PASSWORDNEVEREXPIRES to FALSE  
                3. get the user again and confirm PASSWORDNEVEREXPIRES is set to FALSE  
                4. display success or failure message  
