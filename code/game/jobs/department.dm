/*
	Department Datums
	Currently only used for a non-shitcode way of having variable initial balances in department accounts
	in future, should be a holder for job datums
*/

/datum/department
	var/name = "unspecified department"	//Name may be shown in UIs, proper capitalisation
	var/id	= "department" //This should be one of the DEPARTMENT_XXX defines in __defines/jobs.dm
	var/account_number = 0
	var/account_pin
	var/account_initial_balance = 3500	//How much money this account starts off with
	var/list/jobs_in_department = list()

	//Account Funding
	/*
		Every payday, department accounts recieve money.
		Part of this is their budget, it stays in the account and is to be used for department purchases
		Most of it is wages, that are immediately paid onwards to individual crewmembers/
	*/
	var/account_budget = 2500	//How much money is paid into this account and kept, every payday

	//Must be one of the FUNDING_XXX defines in __defines/economy.dm
	var/funding_type = FUNDING_INTERNAL

	//Where the money for wages and budget actually comes from. With internal, this is a department account ID
	//With external, this is the name of an organisation
	var/funding_source = DEPARTMENT_COMMAND

	//This is a key value list of datacore records and their total owed wage
	//When payday comes, accounts in the department are added here, and removed once the balance is paid off
	//They are not removed until they are paid, so multiple paydays could rollover and stack up if unpaid
	var/list/pending_wages

	// The total of the values in the above wage list. Just cached for convenience
	var/pending_wage_total = 0

	//Increased by account_budget every payday, reset to zero when paid, works like above
	var/pending_budget_total = 0


//Populates the pending wage total
/datum/department/proc/sum_wages()
	pending_wage_total = 0
	for (var/a in pending_wages)
		pending_wage_total += pending_wages[a]

/*************
	Command
**************/
/datum/department/command
	name = "Nadezhda Council"
	id = DEPARTMENT_COMMAND
	/*
	The command account is the ship account. It is the master account that retainer departments are paid from,
	and represents the Captain's wealth, assets and holdings

	For now, it is set to an effectively infinitely high amount which shouldn't run out in normal gameplay
	In future, we will implement largescale missions and research contracts to earn money, and then set it
	to a much lower starting value
	*/
	account_initial_balance = 20000
	funding_type = FUNDING_EXTERNAL


/*************
	Retainers
**************/
//These departments are paid out of ship funding
/datum/department/ironhammer
	name = "Marshal and Blackshield Division"
	id = DEPARTMENT_SECURITY
	funding_type = FUNDING_EXTERNAL
	account_initial_balance = 5000

/datum/department/technomancers
	name = "Artificer's Guild"
	id = DEPARTMENT_ENGINEERING
	funding_type = FUNDING_EXTERNAL

/datum/department/civilian
	name = "Nadezhda Contractors"
	id = DEPARTMENT_CIVILIAN
	account_budget = 0
	account_initial_balance = 0
	funding_type = FUNDING_EXTERNAL
	//No standing balance is kept in the account, this is just for paying gardener, janitor and actor


/******************
	Benefactors
*******************/
//Departments subsidised by an external organisation. These pay their own employees
/datum/department/moebius_medical
	name = "Soteria Institution: Medical Division"
	id = DEPARTMENT_MEDICAL
	funding_type = FUNDING_EXTERNAL
	funding_source = "Soteria Institution."

/datum/department/moebius_research
	name = "Soteria Institution: Research Division"
	id = DEPARTMENT_SCIENCE
	account_budget = 5000 //For buying materials and components and things of scientific value
	funding_type = FUNDING_EXTERNAL
	funding_source = "Soteria Institution."

/datum/department/church
	name = "Church of Absolute"
	id = DEPARTMENT_CHURCH
	funding_type = FUNDING_EXTERNAL
	funding_source = "Church of Absolute"



/******************
	Independant
*******************/
//Self funds and pays wages out of its earnings
/datum/department/guild
	name = "Lonestar Shipping Solutions"
	id = DEPARTMENT_LSS

	/*
		The LSS account represents the holdings of the local branch, and CEO.
	*/
	/* if you want to change this remember to do so in code\game\gamemodes\score.dm as well,
	if you manage to get this variable refferenced there you're a better man than me. godspeed
	*/
	account_initial_balance = 15000
	funding_type = FUNDING_NONE //So we want to trade and make money not magiclly get it every hour

/datum/department/prospector
	name = "Prospectors"
	id = DEPARTMENT_PROSPECTOR
	account_initial_balance = 7500
	funding_type = FUNDING_EXTERNAL

/datum/department/independent
	name = "Independent Allied Factions"
	id = DEPARTMENT_INDEPENDENT
	account_initial_balance = 0
	funding_type = FUNDING_NONE
