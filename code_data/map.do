
clear
set more off

global data "C:\Users\anany\Dropbox\Data"
global dir "C:\Users\anany\Dropbox\UCSC - Year 4\Quarter 1 - Fall 2025\Econ 221A\Research"

cd "$dir\data"
spshape2dta "$dir\data\shrug-pc11dist-poly-shp\district", replace 
use "$dir\data\district.dta", clear
destring pc11_d_id, replace
merge 1:1 pc11_d_id using "$dir\data\exposure.dta"

format sh_exposed %5.3f
spmap sh_exposed using "$dir\data\district_shp", id(_ID) fcolor(Reds) legend(pos(2)) clm(eqint) clnumber(9)
graph export "$dir\figures\map-2015.png", as(png) replace width(1200)
