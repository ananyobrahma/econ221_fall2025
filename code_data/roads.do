
clear
set more off

global data "C:\Users\anany\Dropbox\Data"
global dir "C:\Users\anany\Dropbox\UCSC - Year 4\Quarter 1 - Fall 2025\Econ 221A\Research"

use "$dir\data\shrug-pc-keys-dta\shrid_pc11dist_key.dta", clear
merge m:1 shrid2 using "$dir\data\shrug-pmgsy-dta\pmgsy_2015_shrid.dta", nogen
merge m:1 shrid2 using "$dir\data\shrug-pca11-dta\pc11_pca_clean_shrid.dta", nogen
destring pc11_district_id, replace
merge m:1 pc11_district_id using "$dir\data\concordance_newto11.dta", nogen force

* Given the frequency table, it seems likely that they scraped the PMGSY website sometime early in 2015.
gen year_comp = year(dofc(road_comp_date_new))
gen road = (year_comp != .)

duplicates drop shrid2, force
preserve
	collapse (sum) road (mean) road_length_new, by(year_comp)
restore

gen exposed = road * pc11_pca_tot_p
collapse (sum) exposed pc11_pca_tot_p, by(area pc11_state_id)
gen sh_exposed = exposed/pc11_pca_tot_p
la var sh_exposed "Share exposed"
drop if area == .
isid area
merge 1:m area using"$dir\data\concordance_newto11.dta", nogen force
rename pc11_district_id pc11_d_id
saveold "$dir\data\exposure.dta", replace

