
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

cap erase results.xls
cap erase results.txt

preserve
//keep if Gender == 1
keep if inrange(Age, 6, 14)
//keep if Principal_Activity_Status == 91

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
la var labor_1 "Employment & related activities"
la var labor_2 "Production of goods for own final use"
la var labor_3 "Unpaid domestic services for household members"
la var labor_4 "Unpaid caregiving services for household members"
la var labor_5 "Unpaid volunteer, trainee, & other unpaid work"
la var labor_6 "Learning"
la var labor_7 "Socializing & communciation"
la var labor_8 "Culture, leisure, mass-media, & sports practices"
la var labor_9 "Self-care & maintenance"
forval i = 1/9 {
	reghdfe labor_`i' sh_exposed, a(pc11_state_id) vce(cluster pc11_state_id)
	est sto m`i'
	outreg2 using results.xls, excel bdec(3) append label addtext(Sample, Age 6 to 14)
}

coefplot m1 m2 m3 m4 m5 m6 m7 m8 m9, aseq swapnames drop(_cons) coeflabels(m1 = "Employment and related activities" m2 = "Production for own final use" m3 = "Unpaid domestic services for household members" m4 = "Unpaid caregiving services for household members" m5 = "Unpaid volunteer, trainee, & other unpaid work" m6 = "Learning" m7 = "Socializing and communciation" m8 = "Culture, leisure, mass-media, and sports practices" m9 = "Self-care and maintenance") legend(off) xtitle("Minutes") xline(0) level(90)
graph export "$dir\figures\coefplot-age6to14.png", as(png) replace

restore

* Men
preserve
keep if Gender == 1
keep if inrange(Age, 15, 64)
//keep if Principal_Activity_Status == 91

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
la var labor_1 "Employment & related activities"
la var labor_2 "Production of goods for own final use"
la var labor_3 "Unpaid domestic services for household members"
la var labor_4 "Unpaid caregiving services for household members"
la var labor_5 "Unpaid volunteer, trainee, & other unpaid work"
la var labor_6 "Learning"
la var labor_7 "Socializing and communciation"
la var labor_8 "Culture, leisure, mass-media, and sports practices"
la var labor_9 "Self-care and maintenance"
forval i = 1/9 {
	reghdfe labor_`i' sh_exposed, a(pc11_state_id) vce(cluster pc11_state_id)
	est sto m`i'
	outreg2 using results.xls, excel bdec(3) append label addtext(Sample, Working-age men)
}

restore

* Women
preserve
keep if Gender == 2
keep if inrange(Age, 15, 64)
//keep if Principal_Activity_Status == 91

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
la var labor_1 "Employment & related activities"
la var labor_2 "Production of goods for own final use"
la var labor_3 "Unpaid domestic services for household members"
la var labor_4 "Unpaid caregiving services for household members"
la var labor_5 "Unpaid volunteer, trainee, & other unpaid work"
la var labor_6 "Learning"
la var labor_7 "Socializing and communciation"
la var labor_8 "Culture, leisure, mass-media, and sports practices"
la var labor_9 "Self-care and maintenance"
forval i = 1/9 {
	reghdfe labor_`i' sh_exposed, a(pc11_state_id) vce(cluster pc11_state_id)
	est sto m`i'
	outreg2 using results.xls, excel bdec(3) append label addtext(Sample, Working-age women)
}

//coefplot m1 m2 m3 m4 m5 m6 m7 m8 m9, aseq swapnames drop(_cons) coeflabels(m1 = "Employment and related activities" m2 = "Production for own final use" m3 = "Unpaid domestic services for household members" m4 = "Unpaid caregiving services for household members" m5 = "Unpaid volunteer, trainee, & other unpaid work" m6 = "Learning" m7 = "Socializing and communciation" m8 = "Culture, leisure, mass-media, and sports practices" m9 = "Self-care and maintenance") legend(off) xtitle("Minutes") xline(0)
//graph export "$dir\figures\coefplot-1.png", as(png) replace

restore


preserve
//keep if Gender == 1
//keep if inrange(Age, 15, 64)
//keep if Principal_Activity_Status == 91

gen labor_unpaid = time_spent * inrange(Unpaid_Paid_Status, 1, 12)
gen labor_paid = time_spent * inrange(Unpaid_Paid_Status, 13, 18)
gen labor_self = time_spent * inlist(Unpaid_Paid_Status, 13, 14)
gen labor_wage = time_spent * inlist(Unpaid_Paid_Status, 15, 16)
gen labor_casl = time_spent * inlist(Unpaid_Paid_Status, 17, 18)
//gen labor_self_g = time_spent * (Unpaid_Paid_Status == 13)
//gen labor_self_s = time_spent * (Unpaid_Paid_Status == 14)
//gen labor_wage_g = time_spent * (Unpaid_Paid_Status == 15)
//gen labor_wage_s = time_spent * (Unpaid_Paid_Status == 16)
//gen labor_casl_g = time_spent * (Unpaid_Paid_Status == 17)
//gen labor_casl_s = time_spent * (Unpaid_Paid_Status == 18)

gen statecode_24 = real(substr(NSS_Region), 1, 2)
destring District, gen(districtcode_24)

collapse (sum) labor_* (mean) MULT, by(personid hhid state district)
merge m:1 statecode_24 districtcode_24 using "$dir\data\concordance_24tonew.dta", keepusing(area) nogen

gen wgt= MULT/100
collapse (mean) labor_* [pw = wgt], by(area)
saveold "$dir\data\tus-district.dta", replace

est drop _all
merge 1:m area using "$dir\data\exposure.dta", nogen 
foreach var of varlist labor_* {
	reghdfe `var' sh_exposed, a(pc11_state_id) vce(cluster pc11_state_id)
	est sto m`i'
	outreg2 using results.xls, excel bdec(3) append label addtext(Sample, Working-age men)
}

restore

preserve
keep if Gender == 1
//keep if inrange(Age, 15, 64)
keep if inrange(Principal_Activity_Status, 11, 81)

tab Unpaid_Paid_Status, gen(ups)
foreach var of varlist ups* {
	gen labor_`var' = time_spent * `var'
}
gen statecode_24 = real(substr(NSS_Region), 1, 2)
destring District, gen(districtcode_24)

collapse (sum) labor_* (mean) MULT, by(personid hhid state district)
merge m:1 statecode_24 districtcode_24 using "$dir\data\concordance_24tonew.dta", keepusing(area) nogen

gen wgt= MULT/100
collapse (mean) labor_* [pw = wgt], by(area)
saveold "$dir\data\tus-district.dta", replace

est drop _all
est drop _all
merge 1:m area using "$dir\data\exposure.dta", nogen 
foreach var of varlist labor_* {
	reghdfe `var' sh_exposed, a(pc11_state_id) vce(cluster pc11_state_id)
	//est sto m`i'
	outreg2 using results.xls, excel bdec(3) append label addtext(Sample, All-age men)
}

restore

preserve
keep if Gender == 2
keep if inrange(Age, 15, 64)
//keep if Principal_Activity_Status == 91

tab Unpaid_Paid_Status, gen(ups)
foreach var of varlist ups* {
	gen labor_`var' = time_spent * `var'
}
gen statecode_24 = real(substr(NSS_Region), 1, 2)
destring District, gen(districtcode_24)

collapse (sum) labor_* (mean) MULT, by(personid hhid state district)
merge m:1 statecode_24 districtcode_24 using "$dir\data\concordance_24tonew.dta", keepusing(area) nogen

gen wgt= MULT/100
collapse (mean) labor_* [pw = wgt], by(area)
saveold "$dir\data\tus-district.dta", replace

est drop _all
est drop _all
merge 1:m area using "$dir\data\exposure.dta", nogen 
foreach var of varlist labor_* {
	reghdfe `var' sh_exposed [aw = pc11_pca_tot_p], a(pc11_state_id) vce(cluster pc11_state_id)
	//est sto m`i'
	outreg2 using results.xls, excel bdec(3) append label addtext(Sample, Working-age men)
}

restore

preserve
keep if Gender == 2
//keep if inrange(Age, 15, 64)
//keep if Principal_Activity_Status == 91

tab Unpaid_Paid_Status, gen(ups)
foreach var of varlist ups* {
	gen labor_`var' = time_spent * `var'
}
gen statecode_24 = real(substr(NSS_Region), 1, 2)
destring District, gen(districtcode_24)

collapse (sum) labor_* (mean) MULT, by(personid hhid state district)
merge m:1 statecode_24 districtcode_24 using "$dir\data\concordance_24tonew.dta", keepusing(area) nogen

gen wgt= MULT/100
collapse (mean) labor_* [pw = wgt], by(area)
saveold "$dir\data\tus-district.dta", replace

est drop _all
est drop _all
merge 1:m area using "$dir\data\exposure.dta", nogen 
foreach var of varlist labor_* {
	reghdfe `var' sh_exposed [aw = pc11_pca_tot_p], a(pc11_state_id) vce(cluster pc11_state_id)
	//est sto m`i'
	outreg2 using results.xls, excel bdec(3) append label addtext(Sample, All-age women)
}

restore

preserve
keep if Gender == 2
keep if inrange(Age, 15, 64)
//keep if Principal_Activity_Status == 91

tab Unpaid_Paid_Status, gen(ups)
foreach var of varlist ups* {
	gen labor_`var' = time_spent * `var'
}
gen statecode_24 = real(substr(NSS_Region), 1, 2)
destring District, gen(districtcode_24)

collapse (sum) labor_* (mean) MULT, by(personid hhid state district)
merge m:1 statecode_24 districtcode_24 using "$dir\data\concordance_24tonew.dta", keepusing(area) nogen

gen wgt= MULT/100
collapse (mean) labor_* [pw = wgt], by(area)
saveold "$dir\data\tus-district.dta", replace

est drop _all
est drop _all
merge 1:m area using "$dir\data\exposure.dta", nogen 
foreach var of varlist labor_* {
	reghdfe `var' sh_exposed [aw = pc11_pca_tot_p], a(pc11_state_id) vce(cluster pc11_state_id)
	//est sto m`i'
	outreg2 using results.xls, excel bdec(3) append label addtext(Sample, Working-age women)
}

restore

preserve
keep if Gender == 1
keep if inrange(Age, 15, 64)
keep if inrange(Principal_Activity_Status, 11, 81) // labor force

gen labor_cgnp = time_spent * inlist(acty_2d, 11)
gen labor_hheg = time_spent * inlist(acty_2d, 12)
gen labor_hhes = time_spent * inlist(acty_2d, 13)
gen labor_brk = time_spent * inlist(acty_2d, 14)
gen labor_trn = time_spent * inlist(acty_2d, 15)
gen labor_seek = time_spent * inlist(acty_2d, 16)
gen labor_bus = time_spent * inlist(acty_2d, 17)
gen labor_com = time_spent * inlist(acty_2d, 18)
 //, 250, 380, 441, 442, 443, 444, 540, 640, 750, 860, 950)
//gen labor_com = time_spent * inlist(Activity_Code_3Digit, 181, 182, 250, 380, 441, 442, 443, 444, 540, 640, 750, 860, 950)
gen statecode_24 = real(substr(NSS_Region), 1, 2)
destring District, gen(districtcode_24)

collapse (sum) labor_* (mean) MULT, by(personid hhid state district)
merge m:1 statecode_24 districtcode_24 using "$dir\data\concordance_24tonew.dta", keepusing(area) nogen

gen wgt= MULT/100
collapse (mean) labor_* [pw = wgt], by(area)
saveold "$dir\data\tus-district.dta", replace

merge 1:m area using "$dir\data\exposure.dta", nogen 

foreach var of varlist labor_cgnp labor_hheg labor_hhes labor_brk labor_trn labor_seek labor_bus labor_com {
	reghdfe `var' sh_exposed [aw = pc11_pca_tot_p], a(pc11_state_id) vce(cluster pc11_state_id)
	est sto m`var'
	outreg2 using results.xls, excel bdec(3) append label
}

coefplot mlabor_cgnp mlabor_hheg mlabor_hhes mlabor_brk mlabor_trn mlabor_seek mlabor_bus mlabor_com, aseq swapnames drop(_cons) coeflabels(mlabor_cgnp = "Employment at corporations, government, and non-profits" mlabor_hheg = "Employment in household enterprise to produce goods" mlabor_hhes = "Employment in household enterprise to provide services" mlabor_brk = "Ancillary acitivities and breaks related to employment" mlabor_trn = "Training and studies in relation employment" mlabor_seek = "Seeking employment" mlabor_bus = "Setting up a business" mlabor_com = "Commute time") legend(off) xtitle("Minutes") xline(0)
graph export "$dir\figures\coefplot-2.png", as(png) replace width(1200) 

//reghdfe labor_com sh_exposed [aw = pc11_pca_tot_p], a(pc11_state_id) vce(cluster pc11_state_id)
//outreg2 using results.xls, excel bdec(3) append label

restore

* Do a coefplot for this showing all 9 categories
* Pascal asked school going increasing or not

* Look at school-going age
preserve
keep if inrange(Age, 6, 18)
//keep if Gender == 1
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
la var labor_1 "Employment & related activities"
la var labor_2 "Production of goods for own final use"
la var labor_3 "Unpaid domestic services for household members"
la var labor_4 "Unpaid caregiving services for household members"
la var labor_5 "Unpaid volunteer, trainee, & other unpaid work"
la var labor_6 "Learning"
la var labor_7 "Socializing and communciation"
la var labor_8 "Culture, leisure, mass-media, and sports practices"
la var labor_9 "Self-care and maintenance"
forval i = 1/9 {
	reghdfe labor_`i' sh_exposed, a(pc11_state_id) vce(cluster pc11_state_id)
	est sto m`i'
	outreg2 using results.xls, excel bdec(3) append label addtext(Sample, All school age)
}

restore

* Look at monthly expenditures at the household level.
use "$data\TUS (2024)\tus106HH.dta", clear
keep if Sector == "1"
gen statecode_24 = real(substr(NSS_Region), 1, 2)
destring District, gen(districtcode_24)
merge m:1 statecode_24 districtcode_24 using "$dir\data\concordance_24tonew.dta", keepusing(area) nogen

gen wgt= MULT/100
collapse (mean) exp_total=Monthly_Exp_E_Total [pw = wgt], by(area)
merge 1:1 area using "$dir\data\exposure.dta", nogen 
reghdfe exp_total sh_exposed [aw = pc11_pca_tot_p], absorb(pc11_state_id) vce(cluster pc11_state_id)

* Restrict to rural
