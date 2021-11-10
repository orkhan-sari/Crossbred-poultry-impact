* Project: SPIA small grant - AGRICULTURAL INNOVATIONS IN ETHIOPIA
* Title: An analysis of adoption of crossbred poultry and its impact on well-being among rural poultry-keeping households in Ethiopia
* Author: Dr. Orkhan Sariyev
* Last update: 08.11.2021 
*****************************************************************************************************************

* PART 1: Data cleaning
* PART 2: Estimations
*****************************************************************************************************************

*********************************
**# Data cleaning
*********************************

**# Identify crosbred chickens
/* assign the folder for your research using the global folder command below in the line 19.
- within this folder create a folder named "ETH_2018_ESS_v02_M_Stata" for the raw downloaded data 
*/
global MyProject "C:\Users\490A\Dropbox\SPIA research\githubfiles" 
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_1_ls_w4.dta", clear
svyset [pw=pw_w4] 
format ls_s8_1q03 %12.0g
format ls_s8_1q01 ls_s8_1q02 %12.0g
drop if ls_code <10
drop if ls_code >12
tab ls_code
* drop if poultry is equal to 0
drop if ls_s8_1q01==0 // 1252 HH have poultry
//list household_id ls_s8_1q01 ls_s8_1q02 ls_s8_1q03 if ls_s8_1q01== ls_s8_1q02
//drop if ls_s8_1q01== ls_s8_1q02
* some hhs only have other hh's poultry. some have their own and others. some have only their own. it is not possible to make sure if hh's own poultry is crossbred.
mkdir "$MyProject\cleaned"
cd "$MyProject\cleaned"
gen cross=1
tab ls_s8_1q03, mis
tab ls_s8_1q01, mis
replace cross=0 if ls_s8_1q03==0
label def  cross 1 "Cross" 0 "noncross"
collapse (max) cross pw_w4 , by (household_id )
svy: tab cross
/*
(max)     |
cross     | proportion
----------+-----------
        0 |      .7867
        1 |      .2133
          | 
    Total |          1
	*/

label var cross "1=hh has crosbred male or female chicken;0 otherwise"
save crossbreed, replace
label var pw_w4 "sampling weights"
save crossbreed, replace


**# other cross_share // captures if hh has other cross animal 
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_1_ls_w4.dta", clear
format ls_s8_1q03 %12.0g
format ls_s8_1q01 ls_s8_1q02 %12.0g
drop if inlist(ls_code, 10, 11, 12)
gen cross_other=1
tab ls_s8_1q03, mis
drop if ls_s8_1q03==.
tab ls_s8_1q01, mis
replace cross_other=0 if ls_s8_1q03==0
keep cross_other household_id
collapse (max) cross_other , by (household_id )
cd "$MyProject/cleaned"
save crossother, replace


**# animal keepin hhs // animalhh.dta
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_1_ls_w4.dta", clear
drop if ls_s8_1q01==0
duplicates drop household_id, force
keep holder_id household_id pw_w4 ea_id
cd "$MyProject/cleaned"
save animalhh, replace

**# share of crosbred
use crossbreed, clear
merge 1:1 household_id pw_w4 using animalhh
recode cross (.=0)
svyset [pw=pw_w4]
svy: tab cross
/*
---------------------
1=hh has  |
crosbred  |
male or   |
female    |
chicken;0 |
otherwise | proportion
----------+-----------
        0 |      .8693
        1 |      .1307
          | 
    Total |          1
----------------------
  Key:  proportion  =  cell proportion
*/
 

**# currently poultry keepn hhs - poultryhhs.dta and poultrynumber.dta- I concantrate on this HHs, becuase they could be actual intervention target
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_1_ls_w4.dta", clear
svyset [pw=pw_w4] 
keep if inlist(ls_code, 10, 11, 12)
drop if ls_s8_1q01==0
tab ls_code
/*
     Livestock Code |      Freq.     Percent        Cum.
------------------------------+-----------------------------------
10. Chicken - cocks/ broilers |        664       28.04       28.04
   11. Chicken - hens/ layers |      1,145       48.35       76.39
                   12. Chicks |        559       23.61      100.00
------------------------------+-----------------------------------
                        Total |      2,368      100.00

*/
keep household_id pw_w4 ea_id holder_id saq09 ls_s8_1q05_1 ls_s8_1q05_2
bro
rename saq09 holders_id
format holders_id %12.0g
format ls_s8_1q05_1 %12.0g
format ls_s8_1q05_2 %12.0g
rename ls_s8_1q05_1 manager_id
rename ls_s8_1q05_2 manager_id2
* THERE CAN BE MORE THAN ONE HOLDER - this should be considered for the gender analysis later.
save poultryhhs, replace

/* later when we match these hhs with hhs generated income from poultry and eggs, we see that some hhs have owned poultry in the past 12 months, but not currently. There is a mismatch in reporting. Based on reporting of lost and sold in the past 12 months, some hhs must still have had some poultry during the survey. */

/// number of poultry
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_1_ls_w4.dta", clear
keep if inlist(ls_code, 10, 11, 12)
drop if ls_s8_1q01==0
bro household_id ls_code ls_s8_1q01 ls_s8_1q03
sort household_id
bysort household_id: egen n_poultry= total(ls_s8_1q01)
bysort household_id: egen c_poultry= total(ls_s8_1q03)
bysort household_id: gen count_layers= ls_s8_1q01 if ls_code==11
recode count_layers (.=0)
bysort household_id: gen cross_layers=ls_s8_1q03 if ls_code==11
recode cross_layers (.=0)
collapse (max) n_poultry c_poultry count_layers cross_layers, by(household_id)
gen cross_share= c_poultry/n_poultry
gen cross_share_layer= cross_layers/count_layers
recode cross_share cross_share_layer (.=0)
recode cross_share (.=0)
la var n_poultry "Number of poultry currently kept"
la var c_poultry "Number of crossbred poultry currently kept"
la var cross_share "Share of crossbred poultry currently kept"
la var count_layers "Number of layers/hens currently kept"
la var cross_layers "Number of crossbred layers/hens currently kept"
la var cross_share_layer "Share of crossbred layers currently kept"
save poultrynumber, replace


**# poultry income // p_income.dta, egg_income.dta

use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_2_ls_w4.dta", clear
svyset [pw=pw_w4] 
keep if inlist(ls_code, 10, 11, 12) //8022 obs
rename ls_s8_2q12 sold
rename ls_s8_2q14 income
bro household_id ls_code saq14 sold income
keep if sold==1
bysort household_id: egen poultry_inc= total(income)
label var poultry_inc "income from poultry - animals sold; 12 m."
sort income // There was no income reported for the sold poultry. There are some more HHs like this.  
keep household_id poultry_inc 
duplicates drop household_id poultry_inc, force //441 obs remained
duplicates list household_id  // 0 duplicates
save p_income, replace
// poultry egg - egg_income.dta
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_4_ls_w4.dta", clear
svyset [pw=pw_w4] 
keep if inlist(ls_code, 10, 11, 12)
rename ls_s8_4q17 sold
rename ls_s8_4q18 number
rename ls_s8_4q19 income
bro household_id ls_code sold number income
keep if sold==1
format number %12.0g
format income %12.0g
duplicates list household_id  // there some duplicates
bysort household_id: egen egg_income=sum(income)
sort household_id
keep household_id egg_income
duplicates drop household_id egg_income, force // 4 obs deleted
label var egg_income "income from egg sales; 3months"
save egg_income, replace

**# household size // hhsize.dta - found also in ls data

use "C:\Users\490A\Dropbox\SPIA research\Data analyses\ETH_2018_ESS_v02_M_Stata\sect1_hh_w4.dta", clear
drop if saq14==2
drop if s1q05==2
bysort household_id: egen hh_size= count (household_id)
collapse (max) hh_size, by (household_id)
label var hh_size "household size"
cd "$MyProject/cleaned"
save hhsize, replace


**# dependencyratio // depratio.dta - ratio of dependants to nondependants  

use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect1_hh_w4.dta", clear
drop if s1q05==2
drop if saq14==2
keep household_id s1q01  s1q03a
format s1q03a  %12.0g
gen hdep=1 if s1q03a<15 | s1q03a>64 & s1q01!=1
sort household_id
gen non_dep=1 if s1q03a>14 & s1q03a<65
replace non_dep=1 if s1q01==1
egen hhdep=count( hdep ), by ( household_id )
egen hhnondep=count( non_dep ), by ( household_id )
duplicates drop household_id, force
gen depratio= hhdep/hhnondep
label var depratio "HH dependency ratio"
tab depratio
keep household_id depratio
save depratio, replace

**# food expenditure //- exp_foodhome.dta

use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect6a_hh_w4.dta", clear
svyset [pw=pw_w4]
codebook saq14
drop if saq14==2
rename s6aq04 spend
drop if spend==.
bro household_id item_cd s6aq01 s6aq02a spend
bysort household_id: egen sum= sum(spend)
collapse (max) exp_foodhome=sum pw_w4, by (household_id)
label variable exp_foodhome "total expenditure on food cansumed from markets; 7 days, at home"
save exp_foodhome, replace

**# food expendirture //- exp_foodaway.dta & exp_food.dta - foodexp.dta

use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect6b4_hh_w4.dta", clear
svyset [pw=pw_w4]
codebook saq14
drop if saq14==2
codebook s6bq06
drop if s6bq06==2
bro household_id s6bq06 s6bq07
format s6bq07 %12.0g
bysort household_id: egen sum= sum(s6bq07)
collapse (max) exp_foodaway=sum pw_w4, by (household_id)
label variable exp_foodaway "total expenditure on food cansumed from markets; 7 days, away"
save exp_foodaway, replace


**# merge - exp_food.dta

use exp_foodhome, clear
bro
merge 1:1 household_id pw_w4 using exp_foodaway
gen nohomeexpenditure=0
replace nohomeexpenditure=1 if _merge==2
drop _merge
egen exp_food= rowtotal ( exp_foodaway exp_foodhome)
label variable exp_food "total expenditure on food cansumed from markets and away; 7 days"
save exp_food, replace

/* There are 3105 hhs in this data, but 3115 in food consumption data
Let's check*/
merge 1:1 household_id using hhsize
sort household_id
list household_id if _merge==2
/*
         +--------------------+
      |       household_id |
      |--------------------|
  78. | 010201088801806007 |
 274. | 010403088800201025 |
 852. | 030512088800206005 |
1370. | 040913088802102058 |
1548. | 041704088803702156 |
      |--------------------|
2436. | 071201088801101138 |
2463. | 071504088803610059 |
2642. | 120201088802501036 |
2747. | 120401088800504013 |
2755. | 120401088800504077 |
      +--------------------+
*/

/* Inspecting this HHs in raw data, it seems they consume only what they produce. so no data cleaning errror here.
There might be some reporting issue here. E.g. obs 274 above only reports sorghum to be consumed*/ 
drop _merge 
gen pc_exp_food= exp_food/hh_size
label var pc_exp_food "per capita food expenditure from markets and away; 7 days"
recode pc_exp_food (.=0)
save, replace
// data for main dataset
keep household_id exp_food pc_exp_food
save foodexp, replace

**#  holders_id.dta, holders_idls.dta, and merge file // - DATA.dta

use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect1_hh_w4.dta", clear
codebook saq14
drop if saq14==2
keep household_id individual_id s1q02 s1q03a
bro
format individual_id %12.0g
format s1q03a %12.0g
gen holders_id=individual_id
cd "$MyProject/cleaned"
save holders_id, replace
gen manager_id=individual_id
drop holders_id
save manager_id, replace

**#  holders_idls.dta & merges
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect_cover_ls_w4.dta", clear
rename saq09 holders_id
keep household_id holder_id holders_id saq12 saq16 saq15 saq14
save holders_idls.dta, replace
use poultryhhs, clear
merge m:1 household_id holders_id using holders_id
drop if _merge==2
drop _merge
merge m:1 household_id holders_id using holders_idls
drop if _merge==2
rename s1q02 genderh
rename s1q03a ageh 
label var genderh "gender of the holder"
label var ageh "age of the holder"
drop _merge
rename saq12 hhsize
drop saq14
rename saq16 eduh
cd "$MyProject/cleaned"
save DATA, replace
use DATA, clear
merge m:1 household_id manager_id using manager_id // matched using the main manager, second maanager is ignored to concantrate on the main.
drop if _merge==2
rename s1q02 genderm
rename s1q03a agem
label var agem "age of the main manager"
drop _merge
label var genderm "=2 if the main manager is female"
/* 60 cases (35 hhs) do not have data on gender and age because this hh is not in sect1_hh_w4.dta; additionally, 6 cases do not have holders gender, because holder who is usually 1 member, is not present in the aforementioned dta */ 
save, replace
svyset [pw=pw_w4] 
svy: tab genderm
/*
----------------------
=2 if the |
main      |
manager   |
is female | proportion
----------+-----------
  1. Male |      .3647
 2. Femal |      .6353
          | 
    Total |          1
----------------------
*/


**# collpased data on poultry farmers and managers. // hhlevelDATA.dtause
* Here I will collapse the data to hh level using the information from the the oldest manager for duplicate households where holders differ for poultry type.
use DATA, clear
duplicates drop household_id holders_id manager_id genderh genderm ageh agem saq15, force // 1021 obs deleted
duplicates report household_id
duplicates tag household_id, gen (tag)
tab tag
/*
 tag |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |      1,160       86.12       86.12
          1 |        178       13.21       99.33
          2 |          9        0.67      100.00
------------+-----------------------------------
      Total |      1,347      100.00
*/
sort tag household_id
bro household_id holders_id manager_id genderh genderm ageh agem tag
/* hh have different maangers, for these households, for the sake of a simplier analyses, I concantrate on the oldest manager*/
bysort tag household_id (agem): keep if _n==_N //one needs to be very careful when defining drop instead of keep, drop would drop all non-duplicate observations, but keeps makes sure they stay.
duplicates report household_id
drop tag
svyset [pw=pw_w4] 
svy: tab genderm
/*
Number of strata   =         1                  Number of obs     =      1,217
Number of PSUs     =     1,217                  Population size   =  6,849,722
                                                Design df         =      1,216

----------------------
=2 if the |
main      |
manager   |
is female | proportion
----------+-----------
  1. Male |      .3913
 2. Femal |      .6087
          | 
    Total |          1
----------------------
  Key:  proportion  =  cell proportion
*/
save hhlevelDATA, replace
cd "$MyProject/cleaned"

use hhlevelDATA, clear
merge 1:1 household_id using depratio // 34 not matched 
drop if _merge==2
drop _merge
save, replace
// merges ****
use hhlevelDATA, clear
merge 1:1 household_id using egg_income.dta
/*  Result                           # of obs.
    -----------------------------------------
    not matched                           737
        from master                       680  (_merge==1)
        from using                         57  (_merge==2)

    matched                               572  (_merge==3)
    ----------------------------------------- */
drop if _merge==2
drop _merge
recode egg_income (.=0)
merge 1:1 household_id using p_income
/* Result                           # of obs.
    -----------------------------------------
    not matched                           943
        from master                       877  (_merge==1)
        from using                         66  (_merge==2)

    matched                               375  (_merge==3)
    -----------------------------------------*/
recode poultry_inc (.=0)
drop if _merge==2
drop _merge
save, replace

gen poultry_inc_all= poultry_inc/4 + egg_income
lab var poultry_inc_all "poultry_inc/4 + egg_income; 3 m"
save, replace
use hhlevelDATA, clear
merge 1:1 household_id using foodexp
drop if _merge==2
recode exp_food pc_exp_food (.=0) // 39 and 34 changes respectively
drop _merge
save, replace

**# HDDS12 // hdds.dta 
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect6b1_hh_w4.dta", clear
des
label list food_id
/*food_id:
           1 1. TEFF
           2 2. Other Cereal (rice, sorghum, millet, wheat bread, etc)
           3 3. ROOTS AND TUBERS
           4 4. Pasta, Macaroni and Biscuits
           5 5. SWEETS (Sugar or sugar products (honey, jam)
           6 6. Pulses, Nuts and Seeds
           7 7. Vegetables (including relish and leaves)
           8 8. Fruits: (Mango; Banana; Orange; Pineapple; Papaya; Avocado;  Other Fruit)
           9 9. Beef, sheep, goat, or other red meat and pork
          10 10. Poultry
          11 11. Eggs
          12 12. FISH AND SEAFOOD
          13 13. Oils/fats/butter
          14 14. Milk/yogurt/cheese/other dairy
          15 15. SPICES, CONDIMENTS, BEVERAGES (spices (pepper, salt), condiments , coffee, tea, al
> coholic beverages)
          16 16. Kocho/Bula
*/
keep if saq14==1
keep if s6bq01==1
bro household_id food_id saq14 s6bq01
sort household
bysort household_id: gen cereal=1 if inlist(food_id, 1, 2, 4)
bysort household_id: gen rootandtuber=1 if inlist(food_id, 3, 16)
bysort household_id: gen sweets=1 if inlist(food_id, 5)
bysort household_id: gen pulses=1 if inlist(food_id, 6)
bysort household_id: gen vegi=1 if inlist(food_id, 7)
bysort household_id: gen fruits=1 if inlist(food_id, 8)
bysort household_id: gen meat=1 if inlist(food_id, 9, 10)
bysort household_id: gen eggs=1 if inlist(food_id, 11)
bysort household_id: gen fish=1 if inlist(food_id, 12)
bysort household_id: gen fat=1 if inlist(food_id, 13)
bysort household_id: gen milk=1 if inlist(food_id, 14)
bysort household_id: gen spices=1 if inlist(food_id, 15, 16)
recode cereal rootandtuber sweets pulses vegi fruits meat eggs fish fat milk spices (.=0)
collapse (max) cereal rootandtuber sweets pulses vegi fruits meat eggs fish fat milk spices, by (household_id)
egen hdds= rowtotal (cereal rootandtuber sweets pulses vegi fruits meat eggs fish fat milk spices) 
egen hdds9= rowtotal (cereal rootandtuber pulses vegi fruits meat eggs fish milk)
label var hdds "hh dietary diversity score of 12 food groups"
label var hdds9 "hh dietary diversity score of 9 food groups"
cd "$MyProject/cleaned"
save hdds, replace

use hhlevelDATA,clear
merge 1:1 household_id using hdds
/*
Result                           # of obs.
    -----------------------------------------
    not matched                         1,928
        from master                        36  (_merge==1)
        from using                      1,892  (_merge==2)

    matched                             1,216  (_merge==3)
*/
drop if _merge==2
sort _merge
drop _merge
save, replace

**# managersedu // edu.dta

use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect2_hh_w4.dta",clear
rename s2q06 edu
format individual_id %12.0g
keep household_id individual_id s2q04 edu
rename individual_id manager_id
save edu, replace
use hhlevelDATA, clear
merge 1:1 household_id manager_id using edu
drop if _merge==2
drop i _merge
label var edu "education of the manager"
rename s2q04 edu_att
save, replace

**# other income - otherincome.dta // this includes pension, asset sales, rental, and remittances

use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect13_hh_w4_v2.dta", clear
drop if saq14==2
keep household_id source_cd s13q01 s13q02
rename s13q01 otherincome
rename s13q02 amm_otherincome
drop if otherincome==2
drop if otherincome==.
bro
format amm_otherincome %12.0g
format otherincome %6.0g
bysort household_id: egen total_otherincome= total(amm_otherincome)
bysort household_id: egen rental_inc= total(amm_otherincome) if inlist(source_cd,106,107,108,109)
bysort household_id: egen pensionandinvest= total(amm_otherincome) if inlist(source_cd,104,105)
bysort household_id: egen assetsales= total(amm_otherincome) if inlist(source_cd,110,111,112,113)
bysort household_id: egen transfers= total(amm_otherincome) if inlist(source_cd,101,102,103)
drop amm_otherincome
recode rental_inc pensionandinvest assetsales transfers (.=0)
collapse (max) total_otherincome rental_inc pensionandinvest assetsales transfers otherincome, by (household_id)
sort total_otherincome
bro
ssc inst extremes // check help extremes 
extremes total_otherincome
/* SOME OUTLIERS EXIST
+-----------------+
  | obs:   total_~e |
  |-----------------|
  |   1.          1 |
  |   2.         10 |
  |   3.         10 |
  |   4.         10 |
  |   5.         10 |
  +-----------------+

  +-----------------+
  | 841.     100000 |
  | 842.     100000 |
  | 843.     100000 |
  | 844.     120000 |
  | 845.     140000 |
*/
 /* HH with highest other income:
 
010306088801803150
130101088800202183
010105088802215070
031401088800709029
130101088800202110
031604088800605024
*/
save otherincome, replace
use hhlevelDATA, clear
merge 1:1 household_id using otherincome
drop if _merge==2
drop _merge
recode otherincome (.=2)
recode total_otherincome (.=0)
save, replace
merge 1:1 household_id pw_w4 using crossbreed // merge crossbreed information 
drop _merge
save, replace

**# ENTERPRISE INCOME
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect12b1_hh_w4.dta", clear
drop if saq14==2
sort household_id
bro household_id  s12bq01a s12bq01b s12bq01c s12bq24
gen enterprise_incshare= s12bq24
keep household_id enterprise_incshare
collapse (sum) enterprise_incshare, by (household_id)
tab enterprise_incshare // one obs=150
recode enterprise_incshare (150=100) 
lab var enterprise_incshare "% of hh cash income came from enterprise"
save enterpriseinc, replace
use hhlevelDATA, clear
merge 1:1 household_id using enterpriseinc
drop if _merge==2
recode enterprise_incshare (.=0)
drop _merge
save, replace


**# COMMUNITY CHARACTERISTICS
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect04_com_w4.dta", clear
keep ea_id saq14 cs4q02  cs4q14 cs4q15
tab saq14
drop if saq14 ==2
drop saq14
bro
format cs4q02 %14.0g
format cs4q15 %14.0g
recode cs4q15 (.=0)
save community, replace

/* Althoug, there must have been 565 EAs according to the BASIC INFORMATION DOCUMENT, THE DATA CONTAINS ONLY 528 EAs. thus  there is missing data problem for some .*/

use hhlevelDATA, clear
merge m:1 ea_id using community.dta
drop if _merge==2
drop _merge
save, replace
/*Some of the missing EAs
ea_id
060201088800507
040818088802107
040706088802003
040123088800102
150101088802908
150101088802908
040812088800704
040109088802004
040706088802003 */

/* community size -added 02.09.2021 */
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect03_com_w4.dta", clear
drop if saq14 ==2
rename cs3q03 com_size
keep ea_id com_size
save comsize, replace

 
**# Totalfieldsize // field.dta & landholding.dta - here I calculate total landholding (including rented in; I think does not included rented out) based on the size of fields
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect3_pp_w4.dta", replace
keep household_id saq01 saq02 saq03 s3q02a s3q02b s3q2b_os s3q08 s3q11 s3q11_os
bro household_id s3q02a s3q02b s3q2b_os s3q08
destring saq02, generate(zone) float
destring saq03, generate(woreda) float
gen region=saq01
gen local_unit=s3q02b
save land, replace
merge m:1  region zone woreda local_unit using "$MyProject\ETH_2018_ESS_v02_M_Stata\ET_local_area_unit_conversion.dta", gen (merge) //only conversions for timad, boy, senga, and kert to square meters are included
drop if merge==2
sort s3q08
bro household_id saq01 zone woreda local_unit s3q02a s3q02b conversion s3q08 s3q11 s3q11_os
save field_area, replace

//////////////////////////////////////////////////////////////////
// 							I adopt: https://github.com/EvansSchoolPolicyAnalysisAndResearch/357_Household-Land-Tenure/blob/master/EPAR_UW_357_Ethiopia%20ESS%202013-14%20LSMS%20ISA_W2.do

			*Many thanks to the Authors*								///
///////////////////////////////////////////////////////////////////
clear
use field_area
gen field_area_fr=.
replace field_area_fr=s3q02a/.0001 if s3q02b==1 //reports in hectares, converted to square meters; 471
replace field_area_fr=s3q02a if s3q02b==2 //reports in square meters; 1476
replace field_area_fr=s3q02a*conversion if inlist(s3q02b,3,4,5,6) //convert reports in timad, boy, senga, and kert to square meters where conversion factors available; 2356
bro household_id s3q02a s3q02b conversion field_area_fr
//to calcaulte the missing as good as possible - Impute conversion factors where missing

egen woreda_mean_conv=median(conversion), by (local_unit region zone woreda)
egen zone_mean_conv=median(conversion), by (local_unit region zone)
egen region_mean_conv=median(conversion), by (local_unit region)
egen nation_mean_conv=median(conversion), by (local_unit)

egen woreda_conv_ct=count(conversion), by (local_unit region zone woreda)
egen zone_conv_ct=count(conversion), by (local_unit region zone )
egen region_conv_ct=count(conversion), by (local_unit region)
egen nation_conv_ct=count(conversion), by (local_unit)

*Calculate the area using the imputed conversion factor at lowest possible level with at least 5 non-missing observations, if no conversion factor is available
replace field_area_fr=s3q02a*woreda_mean_conv if field_area_fr==. & woreda_conv_ct>=5 	// 0 changes
replace field_area_fr=s3q02a*zone_mean_conv if field_area_fr==. & zone_conv_ct>=5 		//1594 changes
replace field_area_fr=s3q02a*region_mean_conv if field_area_fr==. & region_conv_ct>=5 		//3801 changes
replace field_area_fr=s3q02a*nation_mean_conv if field_area_fr==. //1666 changes
bro household_id s3q02a s3q02b conversion field_area_fr s3q08
replace field_area_fr=field_area_fr*.0001 //convert to ha
la var field_area_fr "Farmer reported area of field, convert to hectares where possible"

// now GPS data
gen field_area_gps=.
replace field_area_gps= s3q08*0.0001 // converting the GPS measure to ha; there are 98 missing 
la var field_area_gps "Area of field, measured by GPS, in hectares"

// Use GPS as primary, FR as secondary; replace missing GPS area with farmer-reported, if available
gen field_area_ha=.
replace field_area_ha=field_area_gps // 19241 changes made; 98 missing
replace field_area_ha=field_area_fr if field_area_ha==. & field_area_fr!=. // 58 changes made
replace field_area_ha=field_area_fr if field_area_ha==0 & field_area_fr!=. // 0 changes made; 40 remaining missing
drop if field_area_ha==. // 40 deleted
lab var field_area_ha "field area measure, ha - GPS-based if they have one, farmer-report if not"
egen field_area= sum (field_area_ha), by (household_id)
sort household_id
bro household_id s3q02a s3q02b s3q08 field_area_gps field_area_ha field_area
collapse field_area, by (household_id)
la var field_area "field area measure, ha - GPS-based if they have one, farmer-report if not"

codebook field_area
sum field_area

/*   Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+----------------------------------------
  field_area |      2,877    .8783237     3.93268    .000217        200  */
  
//HH 010306088801803150 has 200 hectares!? repeat and check, save only after
// - this is based on what farmer reports; no GPS data on this HH, most likely an interviewer error; I should check if the HH is also in poultry and decide then //
save landholding, replace

****merge****
use hhlevelDATA, clear
merge 1:1 household_id using landholding // 3 unmatched only from master; 1249 matched 
drop if _merge==2
drop _merge
save, replace

**# other livestock // livestock.dta

use "C:\Users\490A\Dropbox\SPIA research\Data analyses\ETH_2018_ESS_v02_M_Stata\sect8_1_ls_w4.dta", clear
drop if ls_s8_1q01==0
drop if ls_s8_1q01==.
keep household_id ls_code ls_s8_1q01 ls_s8_1q02
tab ls_code
/*
               Livestock Code |      Freq.     Percent        Cum.
------------------------------+-----------------------------------
                     1. Bulls |        190        1.80        1.80
                      2. Oxen |        962        9.13       10.94
                      3. Cows |      1,382       13.12       24.06
                    4. Steers |        489        4.64       28.71
                   5. Heifers |        655        6.22       34.93
                    6. Calves |      1,082       10.27       45.20
                     7. Goats |      1,061       10.08       55.27
                     8. Sheep |        872        8.28       63.56
                    9. Camels |        188        1.79       65.34
10. Chicken - cocks/ broilers |        664        6.31       71.65
   11. Chicken - hens/ layers |      1,145       10.87       82.52
                   12. Chicks |        559        5.31       87.83
                   13. Horses |        104        0.99       88.81
                    14. Mules |         31        0.29       89.11
                  15. Donkeys |        941        8.94       98.04
               16. Bee Colony |        206        1.96      100.00
------------------------------+-----------------------------------
                        Total |     10,531      100.00                                                                                 */

drop if inlist(ls_code, 10, 11, 12)
tab ls_code
gen animal= ls_s8_1q01- ls_s8_1q02  // how many belong to the hh? 
drop if animal==0
drop if animal==.
sort ls_code
bro
gen lrum=0
forval i= 1/6  {
	replace lrum=1 if ls_code == `i'
}
gen lrumsum= lrum*animal
egen lruminant= sum (lrumsum), by (household_id)
sort household_id
 gen srum=0
 forval i= 7/8  {
	replace srum=1 if ls_code == `i'
}
gen srumsum= srum*animal
egen sruminant= sum (srumsum), by (household_id)

keep household_id lruminant sruminant 
la var lruminant "number of large ruminants currently kept & owned"
la var sruminant "number of small ruminants currently kept & owned"
duplicates drop household_id lruminant sruminant, force
save livestock, replace

use hhlevelDATA, clear
merge 1:1 household_id using livestock // 144 unmatched from master
recode lruminant (.=0) // 144 changed
recode sruminant (.=0)
drop if _merge==2
drop _merge
save, replace

**# crop income // crop_income.dta
clear
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect11_ph_w4.dta"
drop if saq14==2
tab s11q07
codebook s11q12
codebook s11q11a // to check for inconsistencies. no obvious problem.
keep household_id s11q01 s11q03a1 s11q03a2 s11q03a2_os s11q11a s11q11b s11q12
describe
rename s11q12 income
drop if s11q11a==0
drop if s11q11a==. //6729 deleted
drop if income==. //10 more deleted
bysort household_id: egen crop_income = total (income)
sort household_id
bro
keep household_id crop_income
duplicates drop household_id crop_income, force
lab var crop_income "value of all sales in past 12 months"
save cropincome, replace
use hhlevelDATA, clear
merge 1:1 household_id using cropincome
drop if _merge==2
recode crop_income (.=0)
drop _merge
save, replace

**# livestock income // live_animal.dta, milk_inc.dta

use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_2_ls_w4.dta", clear
rename ls_s8_2q12 sold
rename ls_s8_2q14 income
sort household_id
tab ls_code
drop if inlist(ls_code, 10, 11, 12)
bro household_id ls_code saq14 sold income
keep if sold==1
format income %12.0g
bysort household_id: egen livesales_income = total (income)
lab var livesales_income "income generated from sales of live (nonpoultry) animals; 12 m."
keep household_id livesales_income
duplicates drop household_id livesales_income, force
save live_animal, replace //this does not include poultry income.

// milk and milk products 
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_4_ls_w4.dta", clear
bro household_id ls_s8_4q01 ls_s8_4_q02 ls_s8_4q03 ls_s8_4q07 ls_s8_4q08 ls_s8_4q09 ls_s8_4q10 ls_s8_4q11 ls_s8_4q12
keep if ls_s8_4q01==1
keep if ls_s8_4q08==1
rename ls_s8_4q12 milkproduct_inc
rename ls_s8_4q10 milk_inc
format milk_inc %12.0g
format milkproduct_inc %12.0g
recode milkproduct_inc (.=0)
bysort household_id: egen milk_income = total (milk_inc)
lab var milk_income "income generated from milk sales; average week in past 12m of milking"
bysort household_id: egen milkpr_income = total (milkproduct_inc)
lab var milkpr_income "income generated from milk products; average week in past 12m of milking"
sort household_id
keep household_id milk_income milkpr_income
duplicates drop household_id milk_income milkpr_income, force
save milk_inc, replace
//merge****
use hhlevelDATA, clear
merge 1:1 household_id using live_animal
drop if _merge==2
drop _merge
recode livesales_income (.=0)
merge 1:1 household_id using milk_inc
drop if _merge==2
drop _merge
recode milk_inc (.=0)
recode milkpr_income (.=0)
gen milk_inc_total= milk_income+ milkpr_income
lab var milk_inc_total " income generated from milk and milk products; average week in past 12m of milking"
save, replace 

**# non-food expenditure // nonfood_exp1.dta & nonfood_exp12.dta

clear
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect7a_hh_w4.dta"
drop if saq14==2 
keep household_id s7q01 s7q02
bro
keep if s7q01==1
sort household_id
bysort household_id: egen nonfood_exp1= total(s7q02)
duplicates drop house nonfood_exp1, force
keep household_id nonfood_exp1
lab var nonfood_exp1 "non-food expenditure; 1 month"
save nonfood_exp1, replace
// previous 12 months
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect7b_hh_w4_v2.dta", clear
drop if saq14==2 
keep household_id s7q03 s7q04
bro
keep if s7q03==1
sort household_id
bysort household_id: egen nonfood_exp12= total(s7q04)
duplicates drop house nonfood_exp12, force
keep household_id nonfood_exp12
lab var nonfood_exp12 "non-food expenditure; 12 month"
save nonfood_exp12, replace
//merge****
use hhlevelDATA, clear
merge 1:1 household_id using nonfood_exp1
drop if _merge==2
recode nonfood_exp1 (.=0)
drop _merge
merge 1:1 household_id using nonfood_exp12
drop if _merge==2
recode nonfood_exp12 (.=0)
drop _merge
save, replace

**# crop diversity // cropdiveristy.dta & crop.dta // based on post harvest and post planting data, respectively. 

clear
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect11_ph_w4.dta"
drop if saq14==2
tab s11q03a1
sort s11q03a1
bro household_id s11q01 s11q03a1 s11q03a2 s11q03a2_os // some crops have apperantly failed
drop if s11q03a1==.
drop if s11q03a1==0
keep household_id s11q01
by household_id s11q01, sort: gen nvals= _n==1
by household_id: gen nvalsum = sum(nvals)
by household_id: gen cropcount = nvalsum[_N] 
sort household_id
lab var cropcount "diversity in harvested crop"
keep household_id cropcount
duplicates drop household_id cropcount, force
save cropdiversity, replace
use hhlevelDATA, clear
merge 1:1 household_id using cropdiversity, gen (mergc) // 142 obs seem to have no harvest. needs to be checked - compare with postplanting.
drop if mergc==2
recode cropcount (.=0)
save, replace

// post planting dataset

use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect4_pp_w4.dta", clear
keep household_id s4q01b
bro
by household_id s4q01b, sort: gen nvals= _n==1
by household_id: gen nvalsum = sum(nvals)
by household_id: gen crop = nvalsum[_N] 
lab var crop "diversity in planted crop"
keep household_id crop
duplicates drop  household_id crop, force
save crop, replace
use hhlevelDATA, clear
merge 1:1 household_id using crop, gen (merg)
drop if merg==2
recode crop (.=0) // 94 changes
save, replace

**# school expenditure // consider only school aged children 4-16 years

use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect2_hh_w4.dta", clear
drop if saq14==2
sort household_id
bro household_id individual_id s2q00 s2q04 s2q06 s2q07 s2q08 s2q17 s2q18
format individual_id %12.0g
keep if s2q00==1
keep household_id  individual_id s2q00 s2q04 s2q06 s2q07 s2q08 s2q17 s2q18
save eduraw, replace
// needs to be merged to drop individuals older than 16
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect1_hh_w4.dta", clear
drop if saq14==2
bro household_id s1q01 s1q03a individual_id
format s1q03a %12.0g
format individual_id %12.0g
keep household_id individual_id s1q03a
rename s1q03a age
gen id=individual_id
save individualage, replace
use eduraw, clear
merge 1:1 household_id individual_id using individualage // all matched
drop if _merge==2
drop _merge
drop if age >16
drop if s2q04==2
rename s2q07 school_att 
recode school_att (.=2)
rename s2q17 school_fee
rename s2q18 school_oth
recode school_fee school_oth (.=0)
gen sch_exp= school_fee+ school_oth
bysort household_id: egen school_exp= total (sch_exp)
lab var school_exp "expenditure on school fees, books, uniforms and etc; 12m" 
bysort household_id: egen counter = count(household_id)
keep household_id school_exp counter
duplicates drop household_id school_exp counter, force
gen pc_school_exp= school_exp/counter
lab var pc_school_exp "school exp. per school aged child; 12m"
gen schoolaged_kid =1
lab var schoolaged_kid "=1 if HH has school aged kid"
drop counter
save school_exp, replace
//merge 
use hhlevelDATA, clear
merge 1:1 household_id using school_exp // 791 matched; 461 has no school aged kid apperantly 
drop if _merge==2
recode schoolaged_kid (.=0)
drop _merge
save, replace

**# spending on education // considers all members
use eduraw, clear
merge 1:1 household_id individual_id using individualage // all matched
drop if _merge==2
drop _merge
bro
drop if s2q04==2
drop if s2q07==2
drop if s2q07==.
rename s2q17 school_fee
rename s2q18 school_oth
sort school_oth
recode school_fee school_oth (.=0)
sort household_id
gen sch_exp= school_fee+ school_oth
bysort household_id: egen edu_exp= total (sch_exp)
lab var edu_exp "expenditure on education fees, books, uniforms and etc; 12m" 
bysort household_id: egen counter = count(household_id)
keep household_id edu_exp counter
collapse (max) edu_exp counter, by (household_id)
rename counter edu_current
gen pc_edu_exp= edu_exp/edu_current
lab var pc_edu_exp "edu exp. per member in school/uni"
save edu_exp, replace
use hhlevelDATA, clear
merge 1:1 household_id using edu_exp // 806 matched; 446 has no edu exp 
drop if _merge==2
drop _merge
save, replace

**# some household level characteristics // headedu.dta

use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect1_hh_w4.dta", clear
drop if saq14==2
keep if s1q01==1
rename s1q02 headsex
rename s1q03a headage
keep household_id headsex headage
save head, replace
// head edu
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect1_hh_w4.dta", clear
keep household_id individual_id s1q01
save headdef, replace

use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect2_hh_w4.dta", clear
keep household_id individual_id s2q03 s2q04 s2q06
merge 1:1 household_id individual_id using headdef
drop _merge
bro
keep if s1q01==1
rename s2q06 headedu 
rename s2q04 headschool
rename s2q03 headrw  
drop individual_id s1q01
gen eduyears=headedu
bro
recode eduyears (14=13) (15=13) (16=14) (17=15) (18=15) (19=16) (20=17) (21=9) (22=10) (23=11) (24=12) (25=11) (26=12) (27=12) (28=13) (29=13) (30=13) (31=13) (32=14) (33=15) (34=16) (35=17) (93=0) (94=0) (95=0) (96=0) (98=0) (99=0)
lab var eduyears "years of formal education for head"
save headedu, replace
//merge
use hhlevelDATA, clear
merge 1:1 household_id using headedu
drop if _merge==2
drop _merge
merge 1:1 household_id using head
drop if _merge==2
drop _merge
save, replace
  
**# per adult equivalent in the household // adulteq.dta; also correct hh_size here
use "$MyProject\ETH_2018_ESS_v02_M_Stata\cons_agg_w4.dta", clear
drop if saq14==2
keep household_id  adulteq hh_size nom_nonfoodcons_aeq
bro
format hh_size %12.0g
save adulteq, replace
use HHlevelDATA, clear
merge 1:1 household_id using adulteq
drop if _merge==2
drop _merge
drop hhsize // an error must have occured whne merging, the numbers are wrong, but hh_size is now correct
save, replace


**# managers and holder's empowerment // parcel.dta
cd "$MyProject\cleaned"
use hhlevelDATA, clear
bro
keep household_id manager_id holders_id
save managerinfo, replace
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect10c_hh_w4.dta", clear
drop if saq14==2
bro household_id individual_id ParcelName1 parcel_id s10c_q33 s10c_q34a s10c_q34b_1 s10c_q34b_2 s10c_q34b_3 s10c_q34c s10c_q34d s10c_q34e
merge m:1 household_id using managerinfo
keep if _merge==3
bro household_id individual_id manager_id holders_id s10c_q33 s10c_q34a s10c_q34b_1 s10c_q34b_2 s10c_q34b_3 s10c_q34c s10c_q34d s10c_q34e
bro household_id individual_id manager_id holders_id s10c_q33 s10c_q36 //Are you among the decisionmaker(s) across the PARCEL on this [PARCEL] regarding the timing of crop activities, crop choice, and input use? and If this [PARCEL] were to be rented out today, would you be among the individuals to decide how the money is used? 
// THIS IS THE AGRICULTURAL PARCEL 
gen parcel_acth=0
replace parcel_acth=1 if individual_id==holders_id & s10c_q33==1
gen parcel_renth=0
replace parcel_renth=1 if individual_id==holders_id & s10c_q36==1
gen parcel_actm=0
replace parcel_actm=1 if individual_id==manager_id & s10c_q33==1
gen parcel_rentm=0
replace parcel_rentm=1 if individual_id==manager_id & s10c_q36==1
keep household parcel_acth parcel_renth parcel_actm parcel_rentm
collapse (max) parcel_acth parcel_renth parcel_actm parcel_rentm, by (household_id)
lab var parcel_acth "=1 if holder decides on cropping activities"
lab var parcel_renth "=1 if holder decides on income if rented or sold"
lab var parcel_actm "=1 if manager decides on cropping activities"
lab var parcel_rentm "=1 if manager decides on income if rented or sold"
save parcelDM, replace
use HHlevelDATA, clear
merge 1:1 household_id using parcelDM // 35 missing
drop _merge
save, replace

**# CROP INCOME*** //Post -harvest data has many missing, thus only 714 could be merged, 538 from master were not matched at the end
clear
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect11_ph_w4.dta"
drop if saq14==2
bro household_id harvestedcrop_id s11q12 s11q13_1 s11q13_2 s11q07
keep if s11q07==1
keep household_id s11q12 s11q13_1 s11q13_2
merge m:1 household_id using managerinfo
keep if _merge==3
drop _merge
gen crop_inch=0
local formal s11q13_1 s11q13_2
foreach i of local formal {
	replace crop_inch=1 if `i'==holders_id
}
gen crop_incm=0
local formal s11q13_1 s11q13_2
foreach i of local formal {
	replace crop_incm=1 if `i'==manager_id
}
keep household_id crop_inch crop_incm
collapse (max) crop_inch crop_incm, by (household_id)
lab var crop_incm "=1 if manager can decide what to do with crop income"
lab var crop_inch "=1 if holder can decide what to do with crop income"
save crop_incDM, replace
use HHlevelDATA, clear
merge 1:1 household_id using crop_incDM // Post -harvest data mas many missing, thus only 714 could be merged, 538 from master were not matched - thus, not included. 

**# Land ownership of the manager - merged later
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect10c_hh_w4.dta", clear
drop if saq14==2
keep if s10bq07==1 // to concantrate on parcels that are used for ag. production
bro household_id individual_id s10c_q03
drop if s10c_q03==2
drop if s10c_q03==.
merge m:1 household_id using managerinfo
keep if _merge==3
drop _merge
gen landownm=0
local formal individual_id
foreach i of local formal {
	replace landownm=1 if `i'==manager_id
}
collapse (max) landownm, by (household_id)
tab landownm
lab var landownm "=1 if manager owns land"
save landownm, replace

**# mphone ownership - mphone.dta
clear
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect11b1_hh_w4.dta"
keep household_id individual_id s11b_ind_01
bro
merge m:1 household_id using managerinfo
keep if _merge==3
drop _merge
keep if s11b_ind_01==1
gen mphoneh=0
replace mphoneh=1 if individual_id==holders_id
gen mphonem=0
replace mphonem=1 if individual_id==manager_id
keep household_id mphonem mphoneh
collapse (max) mphoneh mphonem, by (household_id)
lab var mphoneh "holders exclusively or joinlty owns a mobile phone"
lab var mphonem "manager exclusively or joinlty owns a mobile phone"
save mphone, replace
use HHlevelDATA, clear
merge 1:1 household_id using mphone
drop _merge
recode mphoneh mphonem (.=0)
save, replace


**# extension program and advicory services
clear
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect7_pp_w4.dta"
drop if saq14==2
sort household_id
bro household_id s7q04 s7q05 s7q09
keep if s7q04==1
keep household_id s7q04
rename s7q04 extension_prgrm
lab var extension_prgrm "=1 if HH participated in extension program"
duplicates drop household_id extension_prgrm, force
save extension_prgrm, replace
clear
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect7_pp_w4.dta"
drop if saq14==2
keep if s7q09==1
keep household_id s7q09
bro
rename s7q09 advicery_srvc
lab var advicery_srvc "=1 if HH got advicery services"
duplicates drop household_id advicery_srvc, force
save advicery_services, replace
use HHlevelDATA, clear
merge 1:1 household_id using advicery_services
drop if _merge==2
recode advicery_srvc (.=0)
drop _merge
merge 1:1 household_id using extension_prgrm
drop if _merge==2
recode extension_prgrm (.=0)
drop _merge
save, replace


**# region - region.dta
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect_cover_hh_w4.dta", clear
drop if saq14==2
rename saq01 region
rename saq06 kebele
keep household_id region kebele
save region, replace


**#  asphalt road 
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect04_com_w4.dta", clear
drop if saq14 ==2
keep ea_id saq14 cs4q01
gen asphalt=0
replace asphalt=1 if cs4q01==1
lab var asphalt "Asphalt as a main access road"
keep ea_id asphalt
save asphalt, replace


**#  wealth index variables - dwelling.dta, foodsec.dta, w_asset.dta
//dwelling - exp_phone private nokitchen ironroof toiletelswhere mudfloor kerosenelamp
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect10a_hh_w4.dta", clear
drop if saq14==2
bro household_id s10aq02 s10aq06 s10aq16  s10aq10
rename s10aq06 n_rooms
format n_rooms %12.0g
gen kitchen=1
replace kitchen =0 if s10aq10==1
gen toilet=1
replace toilet =0 if s10aq16==3
lab var toilet "toilet avialable in dwelling or in yard; not elswhere"
gen ironroof=0
replace ironroof=1 if s10aq08==1
keep household_id  kitchen ironroof toilet n_rooms
save dwelling, replace
// food security - dailycons_food s8q02b s8q02c s8q02d s8q02e s8q02f s8q02h insecuremonths
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_hh_w4.dta", clear
bro household_id  s8q01 s8q02b s8q02c s8q02d s8q02e s8q02f s8q02h
format s8q02b s8q02c s8q02d s8q02e s8q02f s8q02h %12.0g
bro household_id s8q06 s8q07__1 s8q07__2 s8q07__3 s8q07__4 s8q07__5 s8q07__6 s8q07__7 s8q07__8 s8q07__9 s8q07__10 s8q07__11 s8q07__12 s8q07__13 s8q07__14
format s8q07__1 s8q07__2 s8q07__3 s8q07__4 s8q07__5 s8q07__6 s8q07__7 s8q07__8 s8q07__9 s8q07__10 s8q07__11 s8q07__12 s8q07__13 s8q07__14  %12.0g
egen insecuremonths= rowtotal (s8q07__1 s8q07__2 s8q07__3 s8q07__4 s8q07__5 s8q07__6 s8q07__7 s8q07__8 s8q07__9 s8q07__10 s8q07__11 s8q07__12 s8q07__13 s8q07__14)
keep house insecuremonths s8q02b s8q02c s8q02d s8q02e s8q02f s8q02h
lab var insecuremonths "number of food insecure months in past 12m"
save foodsec, replace
//animal aset
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_1_ls_w4.dta", clear
drop if ls_s8_1q01==0
drop if ls_s8_1q01==.
keep household_id ls_code ls_s8_1q01 ls_s8_1q02
gen animal= ls_s8_1q01- ls_s8_1q02  // how many belong to the hh? 
gen lrum=0
bro
forval i= 1/6  {
	replace lrum=1 if ls_code == `i'
}
bysort household_id: egen count_lruminant=sum(animal) if lrum==1
gen srum=0
forval i= 7/8  {
	replace srum=1 if ls_code == `i'
}
bysort household_id: egen count_sruminant=sum(animal) if srum==1
collapse (max) count_lruminant count_sruminant, by (household_id)
recode count_lruminant count_sruminant (.=0)
save bullcow, replace

// education
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect1_hh_w4.dta", clear
drop if saq14==2
keep household_id individual_id s1q03a s1q05
save age, replace
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect2_hh_w4.dta", clear
drop if saq14==2
keep household_id individual_id s2q00 s2q03
merge 1:1 household_id individual_id using age
drop if _merge==2
drop _merge
drop if s1q05==2 // dropping those who left the housheold; there are also misising values, but those supposedly are still in the hh because there is not reason specified for leaving the hh.
format s1q03a %12.0g
bro
drop if s1q03a<15
gen read=0
replace read=1 if s2q03==1
gen noread=0
replace noread=1 if s2q03==2
collapse (sum) read noread, by(household_id)
gen read_write=read/noread
lab var read_write "share of adults who can read and write"
keep household_id read_write
save readandwrite, replace
// avera age of adults
use age, clear
drop if s1q05==2 // dropping those who left the housheold; there are also misising values, but those supposedly are still in the hh because there is not reason specified for leaving the hh.
bro
format s1q03a %12.0g
drop if s1q03a<15
collapse s1q03a, by (household_id)
rename s1q03a average_age
lab var average_age "average age of household adults"
save average_age, replace
// number of children 
use age, clear
drop if s1q05==2 // dropping those who left the housheold; there are also misising values, but those supposedly are still in the hh because there is not reason specified for leaving the hh.
bro
format s1q03a %12.0g
bysort household_id: egen children= count(s1q03a) if s1q03a<15
bysort household_id: egen adults= count(s1q03a) if s1q03a>14
collapse (max) children adults, by (household_id)
recode children adults (.=0)
gen childepn = children/adults
lab var childepn "Child dependency ratio"
lab var children "Number of children below 15 years of age in the household"
save nofchildren, replace

**#  merge files
use dwelling, clear
merge 1:1 household_id using foodsec
drop if _merge==2
drop _merge
merge 1:1 household_id using bullcow
drop if _merge==2
recode count_lruminant count_sruminant (.=0)
drop _merge
merge 1:1 household_id using readandwrite
drop if _merge==2
drop _merge
merge 1:1 household_id using average_age
drop if _merge==2
drop _merge
merge 1:1 household_id using nofchildren
drop if _merge==2
drop _merge
save wealth, replace

**#  Electronic apliences added on 01.09.2021*/
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect11_hh_w4.dta", clear
drop if s11q00== 2
drop if saq14==2
tab asset_cd
bysort household_id: gen electapplience=1 if inlist(asset_cd, 3,8,9,10,16, 19, 20, 21)
recode electapplience (.=0)
collapse (max) electapplience, by(household_id)
lab var electapplience "=1 if electronic appliences are owned like radio, tv, refrgtr, cdplayer"
keep household_id electapplience
cd "$MyProject/cleaned"
save electapplience, replace

**# Share of adult women
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect1_hh_w4.dta", clear
drop if saq14==2
drop if s1q05==2
bro household_id s1q02 s1q03a
format s1q03a %12.0g
drop if s1q03a<15
bysort household_id: egen number= count(s1q02) if s1q02==2
collapse (max) number, by (household_id)
rename number femalecount 
recode femalecount (.=0)
lab var femalecount "number of adult females"
save femalecount, replace


**# woreda infor
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect_cover_hh_w4.dta", clear
drop if saq14==2
rename saq03 woreda
rename saq02 zone
keep household_id woreda zone
save woreda,replace


**# cleaning the merged file - data.dta // here, differences in edu codes arises due to the differences in livestock questionnarie and hh questionnarie 
use HHlevelDATA, clear
bro household_id eduh 
gen eduyearsh=eduh
recode eduyearsh (1=0) (2=0) (3=1) (4=2) (5=3) (6=4) (7=5) (8=6) (9=7) (10=8) (11=9) (12=10) (13=11) (14=12) (15=13) (16=9) (17=10) (18=12) (19=13) (21=12) (22=13)
lab def yesno 1"Yes" 0"No"
label val mphoneh mphonem  yesno
codebook genderh ageh mphoneh eduh // 39 missing for genderh and ageh
lab var eduyearsh "years of formal education for the holder"
save, replace
codebook genderm agem edu saq15 mphonem //35 missing gender and age for member
gen eduyearsm= edu
bro household_id edu eduyearsm
recode eduyearsm (17=15) (21=9) (22=10) (23=11) (24=12) (25=11) (28=13) (29=13) (30=13) (32=14) (34=16) (93=0) (94=0) (96=0) (98=0)
recode eduyearsm (.=0)
lab var eduyearsm "years of formal education for the maanger"
rename saq15 h_farmtype
codebook advicery_srvc extension_prgrm
rename cs4q02 nearest_road
rename cs4q15 market_weekly
lab val parce* yesno
recode genderm genderh (1=0) (2=1)
lab def sex 0"Male" 1"Female"
lab val gender* sex
recode headsex (1=0) (2=1)
lab val headsex sex
lab var genderm "=1 if the main manager is female"
lab var genderh "=1 if the holder is female"
des gender*
save, replace
sort genderm genderh hdds poultry_inc_all hh_size field_area crop cross headsex
bro genderm genderh hdds poultry_inc_all hh_size field_area crop cross headsex
drop if headsex==.
/*household_id
household_id
031401088800709013
040310088800903005
120105088801201033
010203088800910081
070305088801101071
*/ //check these households holder info * all holders are Member 1
// Checking datasets again, I see that these households exist in the sect1_hh_w4.dta, but the info on the holders who are the first member are misssing. I suppose there has been some kind of an error.
drop if genderm==.
drop if genderh==. //1212 HHs remaining
codebook field_area // 2 missing - these households are misisng in post planting data.
drop if field_area== .
save data, replace // 1210 HH remaining
use data, clear
merge 1:1 household_id using wealth 
drop if _merge==2
drop _merge
recode read_write (.=0)
merge 1:1 household_id using region
drop if _merge==2
drop _merge
save, replace

**# Poultry production
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_4_ls_w4.dta", clear
keep if ls_s8_4q13==1
sort household_id
des household_id ls_s8_4q13 ls_s8_4q14 ls_s8_4q15 ls_s8_4q16 ls_s8_4q17 ls_s8_4q18
bro household_id ls_s8_4q13 ls_s8_4q14 ls_s8_4q15 ls_s8_4q16 ls_s8_4q17 ls_s8_4q18
keep household_id ls_s8_4q13 ls_s8_4q14 ls_s8_4q15 ls_s8_4q16 ls_s8_4q17 ls_s8_4q18
keep if ls_s8_4q17==1
duplicates tag household_id , gen(tag)
list household_id if tag>0 // there are 3 households with duplicates; i still do not yet understand the reason
collapse (sum) ls_s8_4q18 ls_s8_4q16, by (household_id)
rename ls_s8_4q18 eggssold
rename ls_s8_4q16 hens
format eggssold hens %12.0g
gen eggperhen=eggssold/hens
drop hens
lab var eggssold "How many of the eggs produced did you sell; 3 months?"
lab var eggperhen "eggs sold per hen"
save eggpro, replace
// there are many outliers in production, thus number of sold eggs is the only variable used in the analyses
// market orietnation based on purpose of producing - sometimes they have different purposes depending on the type of poultry
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_1_ls_w4.dta", clear
drop if ls_s8_1q01==0
drop if ls_code <10
drop if ls_code >12
gen sale_purpose=0
replace sale_purpose =1 if ls_s8_1q06==1
gen sale_purpose1=0
replace sale_purpose1 =1 if ls_s8_1q06==2
gen food_purpose=0
replace food_purpose=1 if ls_s8_1q06==3
collapse (max) sale_purpose sale_purpose1 food_purpose, by (household_id) 
*depending on the type of poultry (chik, cock, hen), holder might have different purposes to keep. o the variables are not mutually exclusive
lab var sale_purpose "=1 if main purpose to hold is to sell live animal"
lab var sale_purpose1 "=1 if main purpose to hold is to sell lives product"
lab var food_purpose "=1 if main purpose to hold is to have food for family"
save marketorient, replace

**# Corrections 
use data, clear
merge 1:1 household_id using femalecount
drop if _merge==2
drop _merge
gen femaleshare= femalecount/adults
merge 1:1 household_id using woreda
drop if _merge==2
drop _merge
merge 1:1 household_id using crossother
recode cross_other (.=0)
drop if _merge==2
drop _merge
merge m:1 ea_id using asphalt // 33 missing
drop if _merge==2
drop _merge
gen memberinedu=1
replace memberinedu= 0 if pc_edu_exp==.
recode pc_edu_exp (.=0)
save, replace


**# Food Consumption Score 
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect6b1_hh_w4.dta", clear
keep if saq14==1
keep if s6bq01==1
bro household_id food_id saq14 s6bq01 s6bq02
gen weight=.
sort household
* These food groups (and weights in parentheses) are:  Starch staples(2), pulses(3), vegetables(1), 
//fruit(1), fats(0.5), sugars(0.5), meat/fish/eggs (4), milk/dairy(4), 
//condiments(0)
gen food=.
bysort household_id: replace food=1 if inlist(food_id, 1, 2, 3, 4, 16)
bysort household_id: replace food=2 if inlist(food_id, 5)
bysort household_id: replace food=3 if inlist(food_id, 6)
bysort household_id: replace food=4 if inlist(food_id, 7)
bysort household_id: replace food=5 if inlist(food_id, 8)
bysort household_id: replace food=6 if inlist(food_id, 9, 10, 11, 12)
bysort household_id: replace food=7 if inlist(food_id, 13)
bysort household_id: replace food=8 if inlist(food_id, 14)
bysort household_id: replace food=9 if inlist(food_id, 15, 16)
* here:  1-staarch,2-sweets,3-pulses,4-vegi,5-fruit,6-meatfishegg,7-fat,8-milk,9-spices
duplicates tag household_id food , gen(tag)
replace tag=1 if tag>0
replace tag= tag*s6bq02
bysort household_id food: egen flag=max(tag)
duplicates drop household_id food flag, force
bysort household_id: replace s6bq02=flag if tag>0
bysort household_id: replace weight=2 if food==1
bysort household_id: replace weight=0.5 if food==2
bysort household_id: replace weight=3 if food==3
bysort household_id: replace weight=1 if food==4
bysort household_id: replace weight=1 if food==5
bysort household_id: replace weight=4 if food==6
bysort household_id: replace weight=0.5 if food==7
bysort household_id: replace weight=4 if food==8
bysort household_id: replace weight=0 if food==9
gen fcs=weight*s6bq02
preserve
collapse (sum) fcs, by (household_id)
label var fcs "food consumption score"
save fcs, replace
restore
bro household_id food s6bq02
gen food_starch=0
bysort household_id: replace food_starch=s6bq02 if food==1
gen  food_sweets=0
bysort household_id: replace food_sweets=s6bq02 if food==2
gen  food_pulses=0
bysort household_id: replace food_pulses=s6bq02 if food==3
gen  food_vegi=0
bysort household_id: replace food_vegi=s6bq02 if food==4
gen  food_fruit=0
bysort household_id: replace food_fruit=s6bq02 if food==5
gen food_meatandegg=0
bysort household_id: replace food_meatandegg=s6bq02 if food==6
gen food_fat=0
bysort household_id: replace food_fat=s6bq02 if food==7
gen food_milk=0
bysort household_id: replace food_milk=s6bq02 if food==8
gen food_spice=0
bysort household_id: replace food_spice=s6bq02 if food==9
collapse (max) food_starch  food_sweets food_pulses food_vegi food_fruit food_meatandegg food_fat food_milk food_spice, by (household_id)
save food_weekly, replace /// number of days the sepcific group of food was consumed

**# Indetifying the managers and holders
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect1_hh_w4.dta", clear
drop if saq14==2
keep household_id individual_id s1q01
format individual_id %9.0g
rename individual_id holders_id
rename s1q01 kinh
save kinshiph, replace

use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect1_hh_w4.dta", clear
drop if saq14==2
keep household_id individual_id s1q01
format individual_id %9.0g
rename individual_id manager_id
rename s1q01 kinm
save kinshipm, replace

**# Clothing expenditure
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect7b_hh_w4_v2.dta", clear
keep if inlist( item_cd_12months,3,4)
gen girlcloth_exp= s7q04 if item_cd_12months ==4
gen boycloth_exp= s7q04 if item_cd_12months ==3
recode girlcloth_exp  boycloth_exp (.=0)
bro household_id girlcloth_exp boycloth_exp
collapse (max)  girlcloth_exp boycloth_exp, by (household_id)
gen childcloth_exp=girlcloth_exp+boycloth_exp
save clothing_exp, replace
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect1_hh_w4.dta", clear
keep household_id s1q02 s1q03a
bro
rename s1q02 sex
rename s1q03a age
format age %8.0g
sort household_id
bysort household_id: egen boyc=count (household_id) if sex==1&age<18
bysort household_id: egen girlc=count (household_id) if sex==2&age<18
collapse (max) boyc girlc, by(household_id)
recode boyc girlc (.=0)
save malefemalecount, replace
merge 1:1 household_id using clothing_exp
drop _merge
gen count = boyc+girlc
gen pc_childclothing_exp = childcloth_exp  / count
keep household_id pc_childclothing_exp
save pc_clothing_exp, replace

**# Adult eqivalent scale and annual expenditure for hhs
use "$MyProject\ETH_2018_ESS_v02_M_Stata\cons_agg_w4.dta", clear
keep household_id adulteq food_cons_ann nonfood_cons_ann utilities_cons_ann total_cons_ann
cd "$MyProject/cleaned"
save adulteq, replace

**# Off-farm income
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect4_hh_w4.dta", clear
drop if saq14==2
keep household_id s4q33 s4q33b s4q45 s4q48
des
/*Variable      Storage   Display    Value
    name         type    format    label      Variable label
------------------------------------------------------------------------------------------------------------------------------
household_id    str18   %18s                  Unique Household Indentifier
s4q33           double  %1.0g      s4q33      33. Was [NAME] employed in last 12 months?
s4q33b          double  %1.0g      s4q33b     33b. HAS [NAME] WORKED FOR PAYMENT IN THE LAST 12 MONTHS?
s4q45           double  %1.0g      s4q45      45. In the past 12 months has [NAME] been employed as temporary labour by PSNP?
s4q48           double  %1.0g      s4q48      48. Does [NAME] do any other casual/temporary labour work in past 12 months?
*/
gen work4pay=0
replace work4pay=1 if s4q45==1
replace work4pay=1 if s4q48==1
gen member_employed=0
replace member_employed=1 if s4q33==1
collapse (max) work4pay member_employed, by (household_id)
lab var work4pay "=1; if has member who worked as temporary labor off-farm; 12m"
lab var member_employed "=1; if has member who was employed in permanent job; 12m"
cd "$MyProject/cleaned"
save work4pay, replace

**# Food Insecurity Experience Scale (FIES) raw score
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_hh_w4.dta", clear
keep household_id saq14 s8q01 s8q02a s8q02b s8q02c s8q02d s8q02e s8q02f s8q02g s8q02h
drop if saq14==2
local car s8q02a s8q02b s8q02c s8q02d s8q02e s8q02f s8q02g s8q02h
foreach c of local car {
    gen x`c'=0
	replace x`c'=1 if `c'>0
}
egen fies= rowtotal (xs8q02a - xs8q02h)
sum fies
/*  
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
        fies |      3,115    .9370787      1.7618          0          8
*/
keep household fies  
duplicates report household_id
lab var fies "raw Food Insecurity Experience Scale (FIES) score"
cd "$MyProject/cleaned"
save fies, replace

**# Final merges
cd "$MyProject/cleaned"
use data, clear
lab var kitchen "If HH has a room for kitchen"
lab var ironroof "Roof is corrugated iron sheet"
merge 1:1 household_id using poultrynumber
drop if _merge==2
drop _merge
merge 1:1 household_id using marketorient
drop if _merge==2 
drop _merge
merge 1:1 household_id using eggpro
drop if _merge==2 
recode eggssold eggperhen (.=0)
drop _merge
merge 1:1 household_id using fcs // 2 missing
drop if _merge==2
drop _merge
replace eggssold=0 if eggperhen==0 // one hh did not have a laying hen, but reported to sell eggs in past 3 monhts.
gen soldeggs=1
replace soldeggs=0 if eggssold==0
lab var soldeggs "=1 if hh sold eggs in past 3 months"
merge 1:1 household_id holders_id using kinshiph 
drop if _merge==2
drop _merge
merge 1:1 household_id manager_id using kinshipm 
drop if _merge==2
drop _merge
gen lruminant_D=1
replace lruminant_D=0 if lruminant==0
gen sruminant_D=1
replace sruminant_D=0 if sruminant==0
merge 1:1 household_id using landownm
drop if _merge==2
drop _merge
recode landownm (.=0)
gen empow=0
replace empow=1 if parcel_actm==1 & parcel_rentm==1 & landownm ==1
lab var empow "manager owns the parcel and decides on activities and income from the parcel"
label list yesno
label val empow yesno
lab var cross_other "=1 if HH other crossbred livestock"
merge 1:1 household_id using pc_clothing_exp 
drop if _merge==2
drop _merge
lab var pc_childclothing_exp "clothing expenditure per child <18, 12 month"
recode eduyears (.=0) // 761 changes made
merge 1:1 household_id using work4pay
drop if _merge==2
drop _merge
recode work4pay (.=2)
lab val work4pay member_employed yesno
gen agri_inc= crop_income + livesales_income
label var agri_inc "income from crop and live animal sales; 12m"
merge 1:1 household_id using fies
drop if _merge==2
drop _merge
recode fies (.=0)
save data, replace 


*******************************
**# Estimations 	
*******************************

cd "$MyProject/cleaned"
use data, clear
label list saq01
/* 		   1 TIGRAY
           2 AFAR
           3 AMHARA
           4 OROMIA
           5 SOMALI
           6 BENISHANGUL GUMUZ
           7 SNNP
          12 GAMBELA
          13 HARAR
          14 ADDIS ABABA
          15 DIRE DAWA
*/
gen regiondef=5
replace regiondef =1 if region==1 // tigray
replace regiondef =2 if region==3 // amhara
replace regiondef =3 if region==7 // snnp
replace regiondef =4 if region==4 // oromia
lab def regiondef 1 "Tigray" 2 "Amhara" 3 "SNNP" 4 "Oromia" 5 "Other regions"
lab val regiondef regiondef
lab var regiondef "regions defined to 4 big + other regions"
save, replace

mkdir "$MyProject/outputfigure" 
mkdir "$MyProject/outputtables"

**# Descriptives - Table 1
cd "$MyProject/cleaned"
use data, clear
cd "$MyProject/outputtables"
set cformat %5.3f
gen food_aeq=exp_food/adulteq
gen nonfood_aeq1=nonfood_exp1/adulteq
replace agri_inc = agri_inc / 1000
gen poultrysales=1
replace poultrysales =0 if poultry_inc==0

estpost tabstat headsex headage eduyears genderm agem eduyearsm hh_size lruminant_D sruminant_D field_area agri_inc crop cross_other n_poultry count_layers hdds fcs fies soldeggs food_aeq nonfood_aeq1 , by (cross) statistics(mean sd) columns(statistics) listwise nototal
esttab using mydes.tex, replace main(mean) aux(sd) t(2) b(2)wide nostar unstack noobs nonote nomtitle nonumber nogaps nolines onecell
estpost ttest headsex headage eduyears genderm agem eduyearsm hh_size lruminant_D sruminant_D field_area agri_inc crop cross_other n_poultry count_layers hdds fcs fies soldeggs food_aeq nonfood_aeq1 , by ( cross)
esttab using mydesdif.tex, replace wide nonumber mtitle("diff.") t(2) b(2) nogaps onecell
/*two sample proportions test for binary varaibles*/
local test headsex genderm lruminant_D sruminant_D cross_other soldeggs poultrysales
foreach i of local test {
	tabulate `i' cross, chi2
}
foreach i of local test {
	prtest `i', by(cross)
}
/*mann-whitney test if nonnormal distributed varaibles*/

local test1 eduyears agem eduyearsm hh_size field_area agri_inc food_aeq nonfood_aeq1
foreach i of local test1 {
	sktest `i' if cross==0
	sktest `i' if cross==1
}
local test2 eduyears agem eduyearsm hh_size field_area agri_inc food_aeq nonfood_aeq1
foreach i of local test2 {
	ranksum `i', by(cross)
}

local test3 hdds fcs fies crop count_layers 
foreach i of local test3 {
	ranksum `i', by(cross)
}


**# Wealth estimation - Table 2
cd "$MyProject/cleaned"
use data, clear
set scheme plotplainblind
lab def cross 1 "crossbreed" 0 "local"
lab val cross cross
merge m:1 ea_id using comsize
drop if _merge==2
drop _merge
format com_size %12.0g
save, replace
cd "$MyProject/cleaned"
use data, clear
merge 1:1 household_id using electapplience
drop if _merge==2
drop _merge
recode electapplience (.=0)
save, replace
set cformat %5.3f
recode s8q02b (.=0)
factor average_age childepn read_write depratio nom_nonfoodcons_aeq kitchen ironroof toilet n_rooms lruminant sruminant electapplience s8q02d s8q02b insecuremonths, pcf
factor depratio childepn  read_write nom_nonfoodcons_aeq kitchen ironroof toilet n_rooms electapplience s8q02d s8q02b insecuremonths, pcf
estat kmo
predict wealth
save dataw, replace //dataw will be used when full sample is employed.

**# Probit model - Table 3
cd "$MyProject/cleaned" 
use dataw, clear
global ylist i.headsex headage eduyears i.h_farmtype i.genderm##i.empow agem eduyearsm i.mphonem hh_size i.lruminant_D i.sruminant_D field_area wealth agri_inc milk_inc_total total_otherincome crop i.cross_other i.advicery_srvc i.extension_prgrm n_poultry femaleshare i.sale_purpose i.sale_purpose1 i.food_purpose nearest_road market_weekly com_size i.regiondef 
replace agri_inc= agri_inc /1000
replace milk_inc_total = milk_inc_total /1000
replace total_otherincome = total_otherincome /1000
replace nearest_road= nearest_road/60
replace com_size =com_size/1000
regress cross $ylist, vce(robust)
outreg2 using mainlpm.tex, replace sideway stats(coef aster se) dec(3) nocons noparen adds(Adjust. R2, e(r2_a)) // this is for latex tabel 3
cd "$MyProject/outputfigure"
set scheme plotplainblind
lab def empow 0 "Constrained" 1"Empowered"
lab val empow empow
margins, dydx( genderm ) at( empow =(0(1)1))
marginsplot, horizontal recast(scatter) xline(0, lcolor(red)) ytitle (Manager's status) xtitle(Marginal effect with 95% CI) title(Female vs Male manager, size (small) color(black) margin(medsmall))
graph save margins, replace
graph export margins.png, as(png) replace // this is Figure 5

* for q values:
cd "$MyProject/cleaned" 
use dataw, clear
ssc install parmest, replace
global ylist i.headsex headage eduyears i.h_farmtype i.genderm##i.empow agem eduyearsm i.mphonem hh_size i.lruminant_D i.sruminant_D field_area wealth agri_inc milk_inc_total total_otherincome crop i.cross_other i.advicery_srvc i.extension_prgrm n_poultry femaleshare i.sale_purpose i.sale_purpose1 i.food_purpose nearest_road market_weekly com_size i.regiondef 
replace agri_inc= agri_inc /1000
replace milk_inc_total = milk_inc_total /1000
replace total_otherincome = total_otherincome /1000
replace nearest_road= nearest_road/60
replace com_size =com_size/1000
regress cross $ylist, vce(robust)
parmby "regress cross $ylist, vce(robust)", label eform saving(pvalues.dta)
use pvalues, clear
keep p
rename p pval
// for calcuation of q values refer to https://are.berkeley.edu/~mlanderson/downloads/fdr_sharpened_qvalues.do.zip
/*Anderson, M. L. (2008). Multiple inference and gender differences in the effects of early
intervention: A reevaluation of the abecedarian, perry preschool, and early training
projects. Journal of the American Statistical Association, 103 (484), 1481–1495.
https://doi.org/10.1198/016214508000000841*/
quietly sum pval
local totalpvals = r(N)

* Sort the p-values in ascending order and generate a variable that codes each p-value's rank

quietly gen int original_sorting_order = _n
quietly sort pval
quietly gen int rank = _n if pval~=.

* Set the initial counter to 1 

local qval = 1

* Generate the variable that will contain the BKY (2006) sharpened q-values

gen bky06_qval = 1 if pval~=.

* Set up a loop that begins by checking which hypotheses are rejected at q = 1.000, then checks which hypotheses are rejected at q = 0.999, then checks which hypotheses are rejected at q = 0.998, etc.  The loop ends by checking which hypotheses are rejected at q = 0.001.


while `qval' > 0 {
	* First Stage
	* Generate the adjusted first stage q level we are testing: q' = q/1+q
	local qval_adj = `qval'/(1+`qval')
	* Generate value q'*r/M
	gen fdr_temp1 = `qval_adj'*rank/`totalpvals'
	* Generate binary variable checking condition p(r) <= q'*r/M
	gen reject_temp1 = (fdr_temp1>=pval) if pval~=.
	* Generate variable containing p-value ranks for all p-values that meet above condition
	gen reject_rank1 = reject_temp1*rank
	* Record the rank of the largest p-value that meets above condition
	egen total_rejected1 = max(reject_rank1)

	* Second Stage
	* Generate the second stage q level that accounts for hypotheses rejected in first stage: q_2st = q'*(M/m0)
	local qval_2st = `qval_adj'*(`totalpvals'/(`totalpvals'-total_rejected1[1]))
	* Generate value q_2st*r/M
	gen fdr_temp2 = `qval_2st'*rank/`totalpvals'
	* Generate binary variable checking condition p(r) <= q_2st*r/M
	gen reject_temp2 = (fdr_temp2>=pval) if pval~=.
	* Generate variable containing p-value ranks for all p-values that meet above condition
	gen reject_rank2 = reject_temp2*rank
	* Record the rank of the largest p-value that meets above condition
	egen total_rejected2 = max(reject_rank2)

	* A p-value has been rejected at level q if its rank is less than or equal to the rank of the max p-value that meets the above condition
	replace bky06_qval = `qval' if rank <= total_rejected2 & rank~=.
	* Reduce q by 0.001 and repeat loop
	drop fdr_temp* reject_temp* reject_rank* total_rejected*
	local qval = `qval' - .001
}
	
quietly sort original_sorting_order
list pval bky06_qval

* annex probit
cd "$MyProject/cleaned"
use dataw, clear
probit cross $ylist, vce(robust)
cd "$MyProject/outputtables"
margins, dydx(*) post
outreg2 using probitip.tex, replace sideway stats(coef aster se) dec(3) nocons noparen


**# Egg sales impact - Table 4
* if sold any eggs -  soldeggs*/
cd "$MyProject/cleaned"
use dataw, clear
set scheme plotplainblind
set cformat %5.3f
global ylist i.headsex headage eduyears i.h_farmtype i.genderm##i.empow agem eduyearsm i.mphonem hh_size i.lruminant_D i.sruminant_D field_area wealth agri_inc milk_inc_total total_otherincome crop i.cross_other i.advicery_srvc i.extension_prgrm n_poultry femaleshare i.sale_purpose i.sale_purpose1 i.food_purpose nearest_road market_weekly com_size i.regiondef 
probit cross $ylist, vce (robust)
predict ps
tabstat ps, by(cross) stats (N min max) //to restrict to a region of overlap;
/*

     cross |         N       Min       Max
-----------+------------------------------
     local |       906  .0004952  .8037205
crossbreed |       271  .0435367  .9093631
-----------+------------------------------
     Total |      1177  .0004952  .9093631
------------------------------------------

------------------------------------------

*/
gen keep = 1 if ps >= .0435367 & ps <= .8037205
tab cross if keep==1
set cformat %5.4f
teffects ipwra (soldeggs i.headsex headage eduyears i.h_farmtype i.genderm##i.empow agem eduyearsm i.mphonem hh_size i.lruminant_D i.sruminant_D field_area wealth agri_inc milk_inc_total total_otherincome crop i.cross_other i.advicery_srvc i.extension_prgrm count_layers femaleshare i.sale_purpose i.sale_purpose1 i.food_purpose nearest_road market_weekly com_size i.regiondef ) (cross  $ylist, probit) if keep==1, atet vce(robust)
* p= 0.016
cd "$MyProject/outputtables"
outreg2 using atetip.xls, replace drop($ylist 0.cross) dec(2) nocons ctitle (Prob. of selling eggs (3 months)) addtext (Observations restricted to a region of common support)
cd "$MyProject/outputfigure"
set scheme plottig
teoverlap, legend ( position (12) ring(0) col(1) size(small) label(1 "Local breed") label( 2 "Crossbreed")) xtitle(Predicted probability of adoption) note (Figure A, position (6) size (8pt)) ptlevel(1) kernel(gau)
graph save figa, replace
/*STATA example for interpretation of the graph: 
The graph displays the estimated density of the predicted probabilities that a nonsmoking mother
is a nonsmoker and the estimated density of the predicted probabilities that a smoking mother is a
nonsmoker.
Neither plot indicates too much probability mass near 0 or 1, and the two estimated densities
have most of their respective masses in regions in which they overlap each other. Thus there is no
evidence that the overlap assumption is violated*/

* eggssold
cd "$MyProject/cleaned"
use data, clear
keep if soldeggs==1
set scheme plotplainblind
set cformat %5.3f
factor average_age childepn read_write depratio nom_nonfoodcons_aeq kitchen ironroof toilet n_rooms lruminant sruminant electapplience s8q02d s8q02b insecuremonths, pcf
factor childepn read_write depratio nom_nonfoodcons_aeq kitchen ironroof toilet n_rooms electapplience s8q02d s8q02b insecuremonths, pcf
predict wealth
probit cross $ylist
predict ps
tabstat ps, by(cross) stats (N min max)
/*
     cross |         N       Min       Max
-----------+------------------------------
     local |       403  .0000275  .8818747
crossbreed |       148   .023036  .9833176
-----------+------------------------------
     Total |       551  .0000275  .9833176

*/
gen keep = 1 if ps >= .023036 & ps <= .8818747
tab cross if keep==1
teffects ipwra (eggssold i.headsex headage eduyears i.h_farmtype i.genderm##i.empow agem eduyearsm i.mphonem hh_size i.lruminant_D i.sruminant_D field_area wealth agri_inc milk_inc_total total_otherincome crop i.cross_other i.advicery_srvc i.extension_prgrm count_layers femaleshare i.sale_purpose i.sale_purpose1 i.food_purpose nearest_road market_weekly com_size i.regiondef ) (cross  $ylist, probit) if keep==1, atet vce(robust)
* p= 0.000
cd "$MyProject/outputtables"
outreg2 using atetip.xls, append drop($ylist 0.cross) dec(2) nocons ctitle (# of eggs sold per hen (3 months)) addtext (Observations restricted to a region of common support)
cd "$MyProject/outputfigure"
set scheme plottig
teoverlap, legend ( position (12) ring(0) col(1) size(small) label(1 "Local breed") label( 2 "Crossbreed")) xtitle(Predicted probability of adoption) note (Figure B, position (6) size (8pt)) ptlevel(1) kernel(gau)
graph save figb, replace

* income from eggs
cd "$MyProject/cleaned"
use data, clear
keep if soldeggs==1
set scheme plotplainblind
set cformat %5.3f
factor average_age childepn read_write depratio nom_nonfoodcons_aeq kitchen ironroof toilet n_rooms lruminant sruminant electapplience s8q02d s8q02b insecuremonths, pcf
factor childepn read_write depratio nom_nonfoodcons_aeq kitchen ironroof toilet n_rooms electapplience s8q02d s8q02b insecuremonths, pcf
predict wealth
probit cross $ylist
predict ps
tabstat ps, by(cross) stats (N min max)
gen keep = 1 if ps >= .023036 & ps <= .8818747
tab cross if keep==1
teffects ipwra (egg_income i.headsex headage eduyears i.h_farmtype i.genderm##i.empow agem eduyearsm i.mphonem hh_size field_area wealth agri_inc milk_inc_total total_otherincome i.advicery_srvc i.extension_prgrm count_layers i.sale_purpose1 nearest_road market_weekly com_size i.regiondef) (cross  $ylist, probit) if keep==1, atet vce(robust) aeq
*p= 0.000
* Results here show that an additional chickenincreases average quarterly revenue from egg sales, on average, by 110 and 37 Birr forcrossbreed adopters and non-adopters, respectively. 
cd "$MyProject/outputtables"
outreg2 using atetip.xls, append drop($ylist 0.cross) dec(2) nocons ctitle (Income from egg sales (3 months)) addtext (Observations restricted to a region of common support) 
//use https://www.tablesgenerator.com/ 

* graph combine - Figure A1
cd "$MyProject/outputfigure"
set scheme plottig
graph combine figa.gph figb.gph, graphregion( color(white) ) iscale (0.9) imargin (zero) xcommon ycommon 
graph save figaandb.eps, replace // even better - save as eps for tif preview for latex

end

**# Consumption expenditure - Table 5
* non-food consumption expenditure - egg sellers 
cd "$MyProject/cleaned"
use data, clear
keep if soldeggs==1
gen nonfood_aeq1=nonfood_exp1/adulteq
cd "$MyProject/outputtables"
set cformat %5.3f
factor average_age childepn read_write depratio kitchen ironroof toilet n_rooms lruminant sruminant electapplience s8q02d s8q02b insecuremonths, pcf
factor childepn read_write depratio kitchen ironroof toilet n_rooms electapplience s8q02d s8q02b insecuremonths, pcf
/* indicators load on poverty and not wealth*/
predict poverty
global ylist i.headsex headage eduyears i.h_farmtype i.genderm##i.empow agem eduyearsm i.mphonem hh_size i.lruminant_D i.sruminant_D field_area poverty agri_inc milk_inc_total total_otherincome crop i.cross_other i.advicery_srvc i.extension_prgrm n_poultry femaleshare i.sale_purpose i.sale_purpose1 i.food_purpose nearest_road market_weekly com_size i.regiondef 
probit cross $ylist
predict ps
tabstat ps, by(cross) stats (N min max)
/*
     cross |         N       Min       Max
-----------+------------------------------
     local |       403  .0000271  .8863522
crossbreed |       148  .0238855  .9829655
-----------+------------------------------
     Total |       551  .0000271  .9829655

------------------------------------------
*/
gen keep = 1 if ps >= .0238855 & ps <= .8863522
tab cross if keep==1
teffects ipwra (nonfood_aeq1 $ylist) (cross  $ylist, probit) if keep==1, atet vce(robust)
outreg2 using atetipexp.xls, replace drop($ylist 0.cross) dec(2) nocons ctitle (Non-food expenditure (1 month)) addnote (Observations restricted to a region of common support)
*p=0.387
cd "$MyProject/outputfigure"
set scheme plottig
teoverlap, legend ( position (12) ring(0) col(1) size(small) label(1 "Local breed") label( 2 "Crossbreed")) xtitle(Predicted probability of adoption) note (Figure A, position (6) size (8pt)) ptlevel(1) kernel(gau)
graph save egg, replace

* food consumption expenditure from markets and away - egg sellers 
cd "$MyProject/cleaned"
use data, clear
keep if soldeggs==1  
gen food_aeq=exp_food/adulteq
cd "$MyProject/outputtables"
set scheme plotplainblind
set cformat %5.3f
factor childepn read_write depratio kitchen ironroof toilet n_rooms electapplience s8q02d s8q02b insecuremonths, pcf
/* varaibles load on poverty index*/
predict poverty
probit cross $ylist
predict ps
tabstat ps, by(cross) stats (N min max)
gen keep = 1 if ps >= .0238855 & ps <= .8863522
teffects ipwra (food_aeq $ylist) (cross  $ylist, probit) if keep==1, atet vce(robust)
*p=0.485
outreg2 using atetipexp.xls, append drop($ylist 0.cross) dec(2) nocons ctitle (Food expenditure on food from markets and away (7 days)) addnote (Observations restricted to a region of common support)

* whole sample non-food
cd "$MyProject/cleaned"
use dataw, clear
cd "$MyProject/outputtables"
set scheme plotplainblind
set cformat %5.3f
gen nonfood_aeq1=nonfood_exp1/adulteq
factor average_age childepn read_write depratio kitchen ironroof toilet n_rooms lruminant sruminant electapplience s8q02d s8q02b insecuremonths, pcf
factor childepn read_write depratio kitchen ironroof toilet n_rooms electapplience s8q02d s8q02b insecuremonths, pcf
predict poverty
probit cross $ylist
predict ps
tabstat ps, by(cross) stats (N min max)
/*

     cross |         N       Min       Max
-----------+------------------------------
     local |       906  .0005843  .8160605
crossbreed |       271  .0444448  .9098579
-----------+------------------------------
     Total |      1177  .0005843  .9098579
------------------------------------------
*/

gen keep = 1 if ps >= .0444448 & ps <= .8160605
tab cross if keep==1
teffects ipwra (nonfood_aeq1 $ylist ) (cross  $ylist, probit) if keep==1, atet vce(robust)
*p=0.169
outreg2 using atetipexp.xls, append drop($ylist 0.cross) dec(2) nocons ctitle (Non-food expenditure (1 month))
gen food_aeq=exp_food/adulteq
teffects ipwra (food_aeq $ylist ) (cross  $ylist, probit) if keep==1, atet vce(robust)
*p=0.280
outreg2 using atetipexp.xls, append drop($ylist 0.cross) dec(2) nocons ctitle (Food expenditure on food from markets and away (7 days))
cd "$MyProject/outputfigure"
set scheme plottig
teoverlap, legend ( position (12) ring(0) col(1) size(small) label(1 "Local breed") label( 2 "Crossbreed")) xtitle(Predicted probability of adoption) note (Figure B, position (6) size (8pt)) ptlevel(1) kernel(gau)
graph save whole, replace

* graph combine - Figure A2
cd "$MyProject/outputfigure"
set scheme plottig
graph combine egg.gph whole.gph, graphregion( color(white) ) iscale (0.9) imargin (zero) xcommon ycommon 
graph save eggandwhole.eps, replace

**# Dietary outcomes - Table 6
* hdds
cd "$MyProject/cleaned"
use data, clear
drop if hdds==. // 2hhs have missing data here
set scheme plotplainblind
set cformat %5.3f
factor average_age childepn read_write depratio nom_nonfoodcons_aeq kitchen ironroof toilet n_rooms lruminant sruminant electapplience, pcf
// varaibles related to food security are not included to wealth estimation here
factor childepn read_write depratio nom_nonfoodcons_aeq kitchen ironroof toilet n_rooms electapplience , pcf
predict wealth
save datadiet, replace // data for dietar analyses
cd "$MyProject/outputtables"
global ylist i.headsex headage eduyears i.h_farmtype i.genderm##i.empow agem eduyearsm i.mphonem hh_size i.lruminant_D i.sruminant_D field_area wealth agri_inc milk_inc_total total_otherincome crop i.cross_other i.advicery_srvc i.extension_prgrm n_poultry femaleshare i.sale_purpose i.sale_purpose1 i.food_purpose nearest_road market_weekly com_size i.regiondef 
probit cross $ylist
predict ps
tabstat ps, by(cross) stats (N min max)
/*
     cross |         N       Min       Max
-----------+------------------------------
     local |       905  .0011027   .804804
crossbreed |       270  .0408694  .9111308
-----------+------------------------------
     Total |      1175  .0011027  .9111308
------------------------------------------
*/
gen keep = 1 if ps >= .0408694 & ps <= .804804
tab cross if keep==1
teffects ipwra (hdds $ylist, poisson ) (cross $ylist, probit) if keep==1, atet vce(robust) 
*p=0.151
outreg2 using atetdiet.xls, replace drop($ylist 0.cross) dec(2) nocons ctitle (HDDS) addnote (Observations restricted to a region of common support)
cd "$MyProject/outputfigure"
set scheme plottig
teoverlap, legend ( position (12) ring(0) col(1) size(small) label(1 "Local breed") label( 2 "Crossbreed")) xtitle(Predicted probability of adoption) ptlevel(1) kernel(gau) // Figure A3
teffects ipwra (fies i.headsex headage eduyears hh_size crop i.lruminant_D i.sruminant_D field_area wealth agri_inc milk_inc_total total_otherincome n_poultry nearest_road market_weekly i.regiondef , poisson ) (cross  $ylist, probit) if keep==1, atet vce(robust) 
*p= 0.350
teffects ipwra (fcs i.headsex headage eduyears hh_size crop i.lruminant_D i.sruminant_D field_area wealth agri_inc milk_inc_total total_otherincome n_poultry nearest_road market_weekly i.regiondef  , poisson ) (cross  $ylist, probit) if keep==1, atet vce(robust) 
*p=0.697
outreg2 using atetdiet.xls, append drop($ylist 0.cross) dec(2) nocons ctitle (FCS) addnote (Observations restricted to a region of common support)

**# Children's human capital - Table A2
cd "$MyProject/cleaned"
use data, clear
codebook memberinedu  pc_edu_exp pc_childclothing_exp
keep if schoolaged_kid==1 // only school
factor average_age childepn read_write depratio nom_nonfoodcons_aeq kitchen ironroof toilet n_rooms lruminant sruminant electapplience s8q02d s8q02b insecuremonths, pcf
factor childepn read_write depratio nom_nonfoodcons_aeq kitchen ironroof n_rooms electapplience s8q02d s8q02b insecuremonths, pcf
predict poverty //indicators load on poverty not wealth
global ylist i.headsex headage eduyears i.h_farmtype i.genderm##i.empow agem eduyearsm i.mphonem hh_size i.lruminant_D i.sruminant_D field_area poverty agri_inc milk_inc_total total_otherincome crop i.cross_other i.advicery_srvc i.extension_prgrm n_poultry femaleshare i.sale_purpose i.sale_purpose1 i.food_purpose nearest_road market_weekly com_size i.regiondef 
probit cross $ylist
predict ps
tabstat ps, by(cross) stats (N min max)
/*

     cross |         N       Min       Max
-----------+------------------------------
     local |       586  .0000231  .7980721
crossbreed |       180  .0496866  .9149506
-----------+------------------------------
     Total |       766  .0000231  .9149506
------------------------------------------
*/
gen keep = 1 if ps >= .0496866 & ps <= .7980721
tab cross if keep==1
teffects ipwra (pc_school_exp i.headsex headage eduyears i.h_farmtype i.genderm##i.empow agem eduyearsm i.mphonem hh_size field_area poverty agri_inc milk_inc_total total_otherincome n_poultry femaleshare nearest_road market_weekly com_size i.regiondef ) (cross $ylist, probit) if keep==1, atet vce(robust) // as expected poverty significant and negative
*p=0.407
*clothing expenditure 
cd "$MyProject/cleaned"
use data, clear
drop if pc_childclothing_exp==.
factor average_age childepn read_write depratio nom_nonfoodcons_aeq kitchen ironroof toilet n_rooms lruminant sruminant electapplience s8q02d s8q02b insecuremonths, pcf
factor  childepn read_write depratio nom_nonfoodcons_aeq kitchen ironroof toilet n_rooms electapplience s8q02d s8q02b insecuremonths, pcf
predict wealth
global ylist i.headsex headage eduyears i.h_farmtype i.genderm##i.empow agem eduyearsm i.mphonem hh_size i.lruminant_D i.sruminant_D field_area wealth agri_inc milk_inc_total total_otherincome crop i.cross_other i.advicery_srvc i.extension_prgrm n_poultry femaleshare i.sale_purpose i.sale_purpose1 i.food_purpose nearest_road market_weekly com_size i.regiondef 
probit cross $ylist
predict ps
tabstat ps, by(cross) stats (N min max)
/*

     cross |         N       Min       Max
-----------+------------------------------
     local |       814  .0002408  .7912167
crossbreed |       243  .0418829  .9263776
-----------+------------------------------
     Total |      1057  .0002408  .9263776

*/
gen keep = 1 if ps >= .0418829 & ps <= .7912167
tab cross if keep==1
teffects ipwra (pc_childclothing_exp i.headsex headage eduyears i.genderm agem eduyearsm hh_size wealth n_poultry ) (cross $ylist, probit) if keep==1, atet vce(robust)
*p=0.381


**# Sharpened q-values
/*Anderson, M. L. (2008). Multiple inference and gender differences in the effects of early
intervention: A reevaluation of the abecedarian, perry preschool, and early training
projects. Journal of the American Statistical Association, 103 (484), 1481–1495.
https://doi.org/10.1198/016214508000000841 */

clear all
set obs 12
bro
quietly gen float pval = .
replace pval= 0.016 in 1
replace pval= 0.0001 in 2 
replace pval= 0.0001 in 3
replace pval= 0.387 in 4
replace pval= 0.485 in 5
replace pval= 0.169 in 6
replace pval= 0.280 in 7
replace pval= 0.151 in 8
replace pval= 0.350 in 9
replace pval= 0.697 in 10
replace pval= 0.407 in 11
replace pval= 0.381 in 12
pause

* Collect the total number of p-values tested

quietly sum pval
local totalpvals = r(N)

* Sort the p-values in ascending order and generate a variable that codes each p-value's rank

quietly gen int original_sorting_order = _n
quietly sort pval
quietly gen int rank = _n if pval~=.

* Set the initial counter to 1 

local qval = 1

* Generate the variable that will contain the BKY (2006) sharpened q-values

gen bky06_qval = 1 if pval~=.

* Set up a loop that begins by checking which hypotheses are rejected at q = 1.000, then checks which hypotheses are rejected at q = 0.999, then checks which hypotheses are rejected at q = 0.998, etc.  The loop ends by checking which hypotheses are rejected at q = 0.001.


while `qval' > 0 {
	* First Stage
	* Generate the adjusted first stage q level we are testing: q' = q/1+q
	local qval_adj = `qval'/(1+`qval')
	* Generate value q'*r/M
	gen fdr_temp1 = `qval_adj'*rank/`totalpvals'
	* Generate binary variable checking condition p(r) <= q'*r/M
	gen reject_temp1 = (fdr_temp1>=pval) if pval~=.
	* Generate variable containing p-value ranks for all p-values that meet above condition
	gen reject_rank1 = reject_temp1*rank
	* Record the rank of the largest p-value that meets above condition
	egen total_rejected1 = max(reject_rank1)

	* Second Stage
	* Generate the second stage q level that accounts for hypotheses rejected in first stage: q_2st = q'*(M/m0)
	local qval_2st = `qval_adj'*(`totalpvals'/(`totalpvals'-total_rejected1[1]))
	* Generate value q_2st*r/M
	gen fdr_temp2 = `qval_2st'*rank/`totalpvals'
	* Generate binary variable checking condition p(r) <= q_2st*r/M
	gen reject_temp2 = (fdr_temp2>=pval) if pval~=.
	* Generate variable containing p-value ranks for all p-values that meet above condition
	gen reject_rank2 = reject_temp2*rank
	* Record the rank of the largest p-value that meets above condition
	egen total_rejected2 = max(reject_rank2)

	* A p-value has been rejected at level q if its rank is less than or equal to the rank of the max p-value that meets the above condition
	replace bky06_qval = `qval' if rank <= total_rejected2 & rank~=.
	* Reduce q by 0.001 and repeat loop
	drop fdr_temp* reject_temp* reject_rank* total_rejected*
	local qval = `qval' - .001
}
	

quietly sort original_sorting_order
pause off
set more on


**# other figures
* Figure 3:
// differentiatted by  holder gender  - sampling weights no-considered - sample characteristics only. 
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_1_ls_w4.dta", clear
drop if ls_s8_1q01==0
drop if ls_code <10
drop if ls_code >12
rename saq09 holders_id
cd "$MyProject/cleaned"
merge m:m household_id holders_id using holders_id
drop if _merge==2
drop if _merge==1
drop _merge
rename s1q02 gender
keep if gender==1
set scheme plotplainblind
cd "$MyProject/outputfigure"
graph pie,  over(ls_s8_1q06) sort descending plabel(_all percent, color (navy) size(10pt) format(%1.0f) gap(5)) pie(1, explode) pie(2, explode) legend ( label(1 "Animal sales") label (2 "Sales of livestock products") label (3 "Food for the family") label (4 "Savings and insourance") label (5 "Social status") label (6 "Other") label (7 "Manure") position(6) col (3) size (8pt) region (color(none)) margin (zero)) graphregion(fcolor(white)) title(Purpose for keeping poultry - Male holder , color(navy) margin(medsmall))
graph save malepurpose, replace
graph export malepurpose.tif, as(tif) replace
 *female
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_1_ls_w4.dta", clear
drop if ls_s8_1q01==0
drop if ls_code <10
drop if ls_code >12
rename saq09 holders_id
cd "$MyProject/cleaned"
merge m:m household_id holders_id using holders_id
drop if _merge==2
drop if _merge==1
drop _merge
rename s1q02 gender
keep if gender==2
tab ls_s8_1q06
/*
 6.What are the holder's major purposes |
       for owning /keeping [LIVESTOCK]? |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                1. SALE OF LIVE ANIMALS |        108       28.42       28.42
          2. SALE OF LIVESTOCK PRODUCTS |        102       26.84       55.26
                 3. FOOD FOR THE FAMILY |         67       17.63       72.89
               4. SAVINGS AND INSURANCE |         46       12.11       85.00
                       5. SOCIAL STATUS |         45       11.84       96.84
6. CROP AGRICULTURE (MANURE, DRAUGHT PO |          1        0.26       97.11
                     8. OTHER (SPECIFY) |         11        2.89      100.00
----------------------------------------+-----------------------------------
                                  Total |        380      100.00
*/
cd "$MyProject/outputfigure"
graph pie,  over(ls_s8_1q06) sort descending plabel(_all percent, color (navy) size(10pt) format(%1.0f) gap(5)) pie(1, explode) pie(2, explode) legend ( label(1 "Animal sales") label (2 "Sales of livestock products") label (3 "Food for the family") label (4 "Savings and insourance") label (5 "Social status") label (6 "Other") label (7 "Manure") position(6) col (3) size (8pt) region (color(none)) margin (zero)) graphregion(fcolor(white)) title(Purpose for keeping poultry - Female holder, color(navy) margin(medsmall))
graph save femalepurpose, replace
graph export femalepurpose.tif, as(tif) replace
cd "$MyProject/outputfigure"
net install grc1leg.pkg
grc1leg malepurpose.gph femalepurpose.gph, graphregion( color(white) ) iscale (0.6) imargin (zero)
graph save "Graph" "C:\Users\490A\Dropbox\SPIA research\Data analyses\outputfigure\holderpurposes.gph" //manyally moved 0 and 1 for better visibility 
graph export holderpurpose.tif, as(tif) replace
graph export holderpurpose.png, as(png) replace

* Figure 4:
//differentiate by manager gender
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_1_ls_w4.dta", clear
drop if ls_s8_1q01==0
drop if ls_code <10
drop if ls_code >12
set scheme plotplainblind
rename ls_s8_1q05_1 manager_id
cd "$MyProject/cleaned"
merge m:m household_id manager_id using manager_id // matched using he main manager, second maanager is ignored to concantrate on the main.
drop if _merge==2
drop if _merge==1
drop _merge
rename s1q02 gender
keep if gender==1
tab ls_s8_1q06
/*

 6.What are the holder's major purposes |
       for owning /keeping [LIVESTOCK]? |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                1. SALE OF LIVE ANIMALS |        230       28.15       28.15
          2. SALE OF LIVESTOCK PRODUCTS |        176       21.54       49.69
                 3. FOOD FOR THE FAMILY |        173       21.18       70.87
               4. SAVINGS AND INSURANCE |        137       16.77       87.64
                       5. SOCIAL STATUS |         79        9.67       97.31
6. CROP AGRICULTURE (MANURE, DRAUGHT PO |          1        0.12       97.43
                     8. OTHER (SPECIFY) |         21        2.57      100.00
----------------------------------------+-----------------------------------
                                  Total |        817      100.00

*/
cd "$MyProject/outputfigure"
graph pie,  over(ls_s8_1q06) sort (ls_s8_1q06) plabel(_all percent, color (navy) size(10pt) format(%1.0f) gap(5)) pie(1, explode) pie(2, explode) legend ( label(1 "Animal sales") label (2 "Sales of livestock products") label (3 "Food for the family") label (4 "Savings and insourance") label (5 "Social status") label (6 "Manure") label (7 "Other") position(6) col (3) size (8pt) region (color(none)) margin (zero)) graphregion(fcolor(white)) title(Purpose for keeping poultry - Male manager , color(navy) margin(medsmall) size (10pt))
graph save malepurpose_manager, replace
graph export malemanagerpurpose.tif, as(tif) replace
clear
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_1_ls_w4.dta", clear
drop if ls_s8_1q01==0
drop if ls_code <10
drop if ls_code >12
set scheme plotplainblind
rename ls_s8_1q05_1 manager_id
cd "$MyProject/cleaned"
merge m:m household_id manager_id using manager_id // matched using he main manager, second maanager is ignored to concantrate on the main.
drop if _merge==2
drop if _merge==1
drop _merge
rename s1q02 gender
keep if gender==2 // distribution is different for this gorup; see the labels
tab ls_s8_1q06
/* 6.What are the holder's major purposes |
       for owning /keeping [LIVESTOCK]? |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                1. SALE OF LIVE ANIMALS |        490       32.86       32.86
          2. SALE OF LIVESTOCK PRODUCTS |        423       28.37       61.23
                 3. FOOD FOR THE FAMILY |        289       19.38       80.62
               4. SAVINGS AND INSURANCE |        118        7.91       88.53
                       5. SOCIAL STATUS |        134        8.99       97.52
6. CROP AGRICULTURE (MANURE, DRAUGHT PO |          4        0.27       97.79
                     8. OTHER (SPECIFY) |         33        2.21      100.00
----------------------------------------+-----------------------------------
                                  Total |      1,491      100.00
*/
cd "$MyProject/outputfigure"
graph pie,  over(ls_s8_1q06) sort (ls_s8_1q06) plabel(_all percent, color (navy) size(10pt) format(%1.0f) gap(5)) pie(1, explode) pie(2, explode) legend ( label(1 "Animal sales") label (2 "Sales of livestock products") label (3 "Food for the family") label (4 "Savings and insourance") label (5 "Social status") label (6 "Manure") label (7 "Other") position(6) col (3) size (8pt) region (color(none)) margin (zero)) graphregion(fcolor(white)) title(Purpose for keeping poultry - Female manager , color(navy) margin(medsmall) size (10pt))
graph save femalepurpose_manager, replace
grc1leg malepurpose_manager.gph femalepurpose_manager.gph, graphregion( color(white) ) iscale (0.6) imargin (zero)
graph save "Graph" "C:\Users\490A\Dropbox\SPIA research\Data analyses\outputfigure\managerpurposesmerged.gph"
graph export managerpurposes.tif, as(tif) replace
graph export managerpurposes.png, as(png) replace

**# identyfing which family members manage the poultry. Figure 1 and Figure2: 
// ownership status in male vs female headed households - // these descriptive figures are depicted for 1210 hhs
cd "$MyProject/cleaned"
use data, replace
recode kinm (8=6) // 1 obs per each case, merging to other to improve the figure visually
cd "$MyProject/outputfigure"
set scheme plotplainblind
keep if headsex==0
graph pie [pweight = pw_w4],  over(kinh) sort (kinh) plabel( _all percent, color (black) size(12pt) format(%1.0f) gap(5)) pie(_all, explode) legend ( label(1 "Head") label (2 "Spouse") label (3 "Son/Daughter") label (4 "Father/Mother") label (5 "Other(sister,brother,etc)") position(6) col (3) size (8pt) region (color(none)) margin (zero)) graphregion(fcolor(white)) title(Ownership, color(black) margin(medsmall) size (10pt))
graph save graph1v1, replace
graph pie [pweight = pw_w4],  over(kinm) sort (kinm) plabel( _all percent, color (black) size(12pt) format(%1.0f) gap(5)) legend ( label(1 "Head") label (2 "Spouse") label (3 "Son/Daughter") label (4 "Father/Mother") label (5 "Other(sister,brother,etc)") position(6) col (3) size (8pt) region (color(none)) margin (zero)) graphregion(fcolor(white)) title( Management, color(black) margin(medsmall) size (10pt))
graph save graph2v1, replace
grc1leg graph1v1.gph graph2v1.gph, graphregion( color(white) ) iscale (0.6) imargin (zero) title (Male headed households, color(black) margin(medsmall) size (12pt) )
graph save ownershipandmanagementmalehh, replace
graph export ownershipandmanagementmalehh.tif, as(tif) replace
graph export ownershipandmanagementmalehh.png, as(png) replace

/* alternative: 
graph hbar (count), over(kinh, relabel(1 "Head" 2 "Spouse" 3"Son/Doughter" 4"Parent" 5 "Other") label(labsize(small))) over(headsex, relabel (1 "Male headed" 2 "Female headed") label(angle(90) labsize(medium))) title(Ownership, size (large) color(black) margin(small)) blabel (total )
graph save graph1, replace
*/

// management status in male vs female headed households
cd "$MyProject/cleaned"
use data, replace
recode kinm (8=6) // 1 obs per each case, merging to other to improve the figure visually
cd "$MyProject/outputfigure"
set scheme plotplainblind
keep if headsex==1
graph pie [pweight = pw_w4],  over(kinh) sort (kinh) plabel( _all percent, color (black) size(12pt) format(%1.0f) gap(5)) pie(_all, explode) legend ( label(1 "Head") label (2 "Spouse") label (3 "Son/Daughter") label (4 "Father/Mother") label (5 "Other(sister,brother,etc)") position(6) col (3) size (8pt) region (color(none)) margin (zero)) graphregion(fcolor(white)) title(Ownership, color(black) margin(medsmall) size (10pt))
graph save graph3v1, replace
graph pie [pweight = pw_w4],  over(kinm) sort (kinm) plabel( _all percent, color (black) size(12pt) format(%1.0f) gap(5)) pie(_all, explode) legend ( label(1 "Head") label (2 "Spouse") label (3 "Son/Daughter") label (4 "Father/Mother") label (5 "Other(sister,brother,etc)") position(6) col (3) size (8pt) region (color(none)) margin (zero)) graphregion(fcolor(white)) title( Management, color(black) margin(medsmall) size (10pt))
graph save graph4v1, replace
grc1leg graph3v1.gph graph4v1.gph, graphregion( color(white) ) iscale (0.6) imargin (zero) title (Female headed households, color(black) margin(medsmall) size (12pt) )
graph save ownershipandmanagementfemalehh, replace
graph export ownershipandmanagementfemalehh.tif, as(tif) replace
graph export ownershipandmanagementfemalehh.png, as(png) replace


/*alternative graph and merge
graph hbar (count), over(kinm, relabel(1 "Head" 2 "Spouse" 3"Son/Doughter" 4"Parent" 5 "Other")  label(labsize(small))) over(headsex, relabel (1 "Male headed" 2 "Female headed") label( angle(90) labsize(medium))) title(Management, size (large) color(black) margin(medsmall)) blabel (total)
graph save graph2, replace
*select the graph folder as directory and with correct names run the following 
cd "$MyProject/outputfigure"
graph combine graph1.gph graph2.gph, graphregion( color(white) ) iscale (0.6) imargin (zero) ycommon
graph save family, replace
graph export family.tif, as(tif) replace
graph export family.png, as(png) replace
*/

**# figure on income and expenditure. Figure 6:
cd "$MyProject/cleaned"
use data, replace
merge 1:1 household_id using adulteq
drop if _merge==2
drop _merge
cd "$MyProject/outputfigure"
set scheme plottig
gen egg_inc12= egg_income *4
recode egg_inc12 (0=.)
recode poultry_inc (0=.)
gen crossegginc=egg_inc12 if cross==1
gen localegginc=egg_inc12 if cross==0
gen total_eggsellers=  total_cons_ann if soldeggs==1
graph bar (mean) egg_inc12 crossegginc localegginc  poultry_inc total_cons_ann total_eggsellers , blabel (total, format(%9.0f) position (outside) size (8pt)) legend ( position (11) ring(0) col(1) label (1 "Egg sales*") label (2 "Egg sales: crossbreed adopters*") label (3 "Egg sales: local breed adopters*") label(4 "Poultry sales*") label(5 "Consumption expenditure: all´") label(6 "Consumption expenditure: those who sell eggs´") size (8pt)) note ("* mean annual revenue of those who sell" "´ mean annual expenditure" "", size (8pt)  margin(small) position (7))
graph save consumption, replace
graph export consumption.tif, as(tif) replace



**# feeding practice
use "$MyProject\ETH_2018_ESS_v02_M_Stata\sect8_3_ls_w4.dta", clear
keep if ls_type ==4
tab ls_s8_3q12_1 // major feeding practice is missing
tab ls_s8_3q13
tab ls_s8_3q11
tab ls_s8_3q04 // no fodder purchased of course

