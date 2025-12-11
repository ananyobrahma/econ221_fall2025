
clear
set more off

global data "C:\Users\anany\Dropbox\Data"
global dir "C:\Users\anany\Dropbox\UCSC - Year 4\Quarter 1 - Fall 2025\Econ 221A\Research"

use "$data\TUS (2024)\tus106per.dta", clear

assert Activity_Serial_No == "" if Age < 6
drop if Activity_Serial_No == ""
//isid FSU_Serial_No Sample_HH_No Person_Serial_No Activity_Serial_No
keep if Type_of_Day == "1" // normal day
keep if Sector == "1" // restrict to rural 

gen time_end = clock(Time_To, "hm")
gen time_start = clock(Time_From, "hm")
gen time_spent = minutes(time_end - time_start)
replace time_spent = time_spent + 1440 if time_spent < 0

egen personid = group(FSU_Serial_No Sample_HH_No Person_Serial_No)
egen hhid = group(FSU_Serial_No Sample_HH_No)

* Simplifying assumption: If multiple activities are performed in a time slot, apportion time equally.
destring Multiple_Activity_Flag, replace
replace Multiple_Activity_Flag = 0 if Multiple_Activity_Flag == 2
bys personid Time_From Time_To: egen nacty = sum(Multiple_Activity_Flag)
la var nacty "Number of activities"
replace time_spent = time_spent/nacty if nacty != 0

bys personid: egen totaltime = sum(time_spent) // just checking that it sums to 24 hours
drop totaltime

gen acty_1d = real(substr(Activity_Code_3Digit, 1, 1))
gen acty_2d = real(substr(Activity_Code_3Digit, 1, 2))
destring Activity_Code_3Digit Principal_Activity_Status Unpaid_Paid_Status Gender, replace

cap erase table-1.tex
cap erase table-1.txt
cap erase table-2.tex
cap erase table-2.txt
cap erase table-3.tex
cap erase table-3.txt

* Time use of working-age population
preserve
keep if inrange(Age, 15, 64)

forval i = 1/9 {
	gen labor_`i' = time_spent * (acty_1d == `i')
}

gen statecode_24 = real(substr(NSS_Region), 1, 2)
destring District, gen(districtcode_24)

collapse (sum) labor_* (mean) MULT, by(personid hhid state district)
merge m:1 statecode_24 districtcode_24 using "$dir\data\concordance_24tonew.dta", keepusing(area) nogen

gen wgt= MULT/100
collapse (mean) labor_* [pw = wgt], by(area)
saveold "$dir\data\tus-district.dta", replace

est drop _all
merge 1:m area using "$dir\data\exposure.dta", nogen 
la var labor_1 "Employment"
la var labor_2 "Production"
la var labor_3 "Unpaid domestic"
la var labor_4 "Unpaid caregiving"
la var labor_5 "Unpaid volunteer"
la var labor_6 "Learning"
la var labor_7 "Socializing"
la var labor_8 "Culture"
la var labor_9 "Self-care"
forval i = 1/9 {
	reghdfe labor_`i' sh_exposed, a(pc11_state_id) vce(cluster pc11_state_id)
	est sto m`i'
	outreg2 using table-1.tex, tex(frag) bdec(3) append label 
}

coefplot m1 m2 m3 m4 m5 m6 m7 m8 m9, aseq swapnames drop(_cons) coeflabels(m1 = "Employment & related activities" m2 = "Production for own final use" m3 = "Unpaid domestic services for household members" m4 = "Unpaid caregiving services for household members" m5 = "Unpaid volunteer, trainee, & other unpaid work" m6 = "Learning" m7 = "Socializing & communciation" m8 = "Culture, leisure, mass-media, & sports practices" m9 = "Self-care & maintenance") legend(off) xtitle("Minutes") xline(0) level(90)
graph export "$dir\figures\coefplot-timeuse-wa.png", as(png) replace

restore

* Paid/Unpaid activity status
preserve
keep if inrange(Age, 15, 64)
keep if inrange(Principal_Activity_Status, 11, 81)

gen statecode_24 = real(substr(NSS_Region), 1, 2)
destring District, gen(districtcode_24)

gen labor_paid = time_spent * inrange(Unpaid_Paid_Status, 13, 18)
gen labor_self = time_spent * inlist(Unpaid_Paid_Status, 13, 14)
gen labor_wage = time_spent * inlist(Unpaid_Paid_Status, 15, 16)
gen labor_casl = time_spent * inlist(Unpaid_Paid_Status, 17, 18)

collapse (sum) labor_* (mean) MULT, by(personid hhid state district)
merge m:1 statecode_24 districtcode_24 using "$dir\data\concordance_24tonew.dta", keepusing(area) nogen

gen wgt= MULT/100
collapse (mean) labor_* [pw = wgt], by(area)
saveold "$dir\data\tus-district.dta", replace

est drop _all
merge 1:m area using "$dir\data\exposure.dta", nogen 
la var labor_paid "Paid labor"
la var labor_self "Self-employment"
la var labor_wage "Wage employment"
la var labor_casl "Casual employment"

foreach var of varlist labor_* {
	reghdfe `var' sh_exposed, a(pc11_state_id) vce(cluster pc11_state_id)
	est sto m`var'
	outreg2 using table-2.tex, tex(frag) bdec(3) append label
}

coefplot mlabor_paid mlabor_self mlabor_wage mlabor_casl, aseq swapnames drop(_cons) coeflabels(mlabor_paid = "Paid employment" mlabor_self = "Self employment" mlabor_wage = "Wage employment" mlabor_casl = "Casual employment") legend(off) xtitle("Minutes") xline(0) level(90)
graph export "$dir\figures\coefplot-paid.png", as(png) replace

restore

* Look at monthly expenditures at the household level.
use "$data\TUS (2024)\tus106HH.dta", clear
keep if Sector == "1"
gen statecode_24 = real(substr(NSS_Region), 1, 2)
destring District, gen(districtcode_24)
merge m:1 statecode_24 districtcode_24 using "$dir\data\concordance_24tonew.dta", keepusing(area) nogen

gen wgt= MULT/100
collapse (mean) exp_total=Monthly_Exp_E_Total [pw = wgt], by(area)
merge 1:m area using "$dir\data\exposure.dta", nogen 
reghdfe exp_total sh_exposed, absorb(pc11_state_id) vce(cluster pc11_state_id)
