This Script has 4 functions
	1) Main-Menu: self-explanitory
	2) check-passNeverExpiresFlag
		A) gets current date/time
		B) subtracts wiggle room from today's date (default 70)
		C) gets users matching the following critereon:
			i)   PASSWORDLEVEREXPIRES flag set to TRUE
			ii)  ENABLED flag set to TRUE
			iii) Password age is within the wiggle period 
			iv)  their name is not like "Service_"
		D) for each of these users
			i)   checks to make sure user CAN change their password, if not, service account is assumed and the remainder are skipped
			ii)  returns the password age
			iii) if the PASSWORDNEVEREXPIRES flag is set to true, say so in green
			iv)  if the PASSWORDNEVEREXPIRES flag is set to false, say so in red
			v)   additionally return the following properties:
				a) PasswordLastSet
				b) LastLogonDate
				c) Password Expiry date
			vi)  if the user CANNOTCHANGEPASSWORD flag is set true, say so in red
			vii) if the user CANNOTCHANGEPASSWORD flag is set false, say so in green
	3) remove-PassNeverExpiresFlag
		A) gets current date/time
		B) subtracts wiggle room from today's date (default 70)
		C) gets users matching the following critereon:
			i)   PASSWORDNEVEREXPIRES flag set to TRUE
			ii)  ENABLED flag set to TRUE
			iii) Password age within the wiggle period
			iv)  Their NAME is not like "Service_"
		D) if this user count is 0, then write to host 'No users match criteria.'
		E) for each of the users do the following
			i)   if CANNOTCHANGEPASSWORD flag is set to true, say so in red, displaying user NAME and SAMACCOUNTNAME
			ii)  otherwise do the following: 
				a) display "Removing 'password never expires' for:" username
				b) set the AD user account property PASSWORDNEVEREXPIRES to FALSE
				c) get the user again and confirm PASSWORDNEVEREXPIRES is set to FALSE
				d) display success or failure message
