
* Loop over each year of data
forvalues year = 2013(3)2016{


	****** 1) Setup data **********

	* Store years file number
	if inlist(`year',2013){
		local filenum = "36164"
	}
	if inlist(`year',2016){
		local filenum = "37323"
	}

	* Import data
	clear all
	cd "${user}\Data\Law Enforcement Management and Administrative Statistics"
	unzipfile "LEMAS `year'", replace
	use "ICPSR_`filenum'/DS0001/`filenum'-0001-Data", clear
	foreach v of varlist *{
		cap replace `v' = 0 if inlist(`v',-88, -8)
	}
	do "ICPSR_`filenum'/DS0001/`filenum'-0001-Supplemental_syntax.do"
	cd "${user}"

	****** 2) Define Variables **********
	
	* Sampling strata
	if inlist(`year',2013){
		rename STRATCODE strata
	}
	if inlist(`year',2016){
		rename STRATA strata
	}
	
	* Location (recode agency names with missing ORI number to match backbone)
	if inlist(`year',2013){
		g agency = upper(BJS_AGENCYNAME)
		rename STATECODE stabb
	}
	if inlist(`year',2016){
		g agency = upper(AGENCYNAME)
		rename STATE stabb
	}
	replace agency = "ST LOUIS METRO POLICE DEPT" if inlist(agency, "SAINT LOUIS CITY POLICE DEPARTMENT")
	replace agency = "PINE BEACH POLICE" if inlist(agency, "BOROUGH OF PINE BEACH POLICE DEPARTMENT")
	replace agency = "BINGEN PD" if inlist(agency, "BINGEN-WHITE SALMONBINGEN POLICE DEPARTMENT")
	replace agency = "SHIPSHEWANA POLICE" if inlist(agency, "SHIPSHEWANA POLICE DEPT")
	rename CITY city

	* Year
	g year = `year'

	* Agency's total operating budget
	if inlist(`year',2013){
		g ag_budget = BDGT_TTL
	}
	if inlist(`year',2016){
		g ag_budget = OPBUDGET
	}
	
	* Workforce: Number of full time ag_officers
	gen ag_officers = FTSWORN

	* Workforce: Minimum starting wage of sworn officer
	if inlist(`year',2013){
		gen ag_wage =PAY_SAL_OFCR_MIN/(52.1429*40)
	}

	* Workforce: Share of full-time ag_officers that are male
	if inlist(`year',2013){
		g ag_officers_male=(PERS_PDSW_MFT)/(ag_officers)
	}
	if inlist(`year',2016){
		g ag_officers_male=(PERS_MALE)/(ag_officers)
	}

	* Workforce: Share of full-time ag_officers that are white nonhispanic
	if inlist(`year',2013){
		g ag_officers_white=(PERS_FTS_WHT)/ag_officers
	}
	if inlist(`year',2016){
		g ag_officers_white=(PERS_WHITE_MALE + PERS_WHITE_FEM)/ag_officers
	}

	* Workforce: Share of full-time ag_officers that are black nonhispanic
	if inlist(`year',2013){
		g ag_officers_black=(PERS_FTS_BLK)/ag_officers
	}
	if inlist(`year',2016){
		g ag_officers_black=(PERS_BLACK_MALE + PERS_BLACK_FEM)/ag_officers
	}

	* Workforce: Share of full-time ag_officers with bacherlor's degree or higher
	if inlist(`year',2013){
		g ag_officers_college=HIR_BD_VAR/ag_officers
	}

	* Workforce: Share of black intermediate supervisors
	if inlist(`year',2016){
		g ag_intermediate_black = PERS_SUP_INTM_BK / PERS_SUP_INTM_TOTR
	}

	* Workforce: Share of white intermediate supervisors
	if inlist(`year',2016){
		g ag_intermediate_white = PERS_SUP_INTM_WH / PERS_SUP_INTM_TOTR
	}

	* Workforce: Share of black sergeant
	if inlist(`year',2016){
		g ag_sgt_black =  PERS_SUP_SGT_BK / PERS_SUP_SGT_TOTR
	}

	* Workforce: Share of white sergeant
	if inlist(`year',2016){
		g ag_sgt_white =  PERS_SUP_SGT_WH / PERS_SUP_SGT_TOTR
	}

	* Workforce: Black chief exectutive
	if inlist(`year',2016){
		g ag_exe_black = PERS_CHF_RACE == 2
	}

	* Workforce: White chief exectutive
	if inlist(`year',2016){
		g ag_exe_white = PERS_CHF_RACE == 1
	}
	
	* Workforce: New hires share of full time ag_officers
	if inlist(`year',2013){
		g ag_new_officers=(HIR_NBR_TFT)/(ag_officers)
	}
	if inlist(`year',2016){
		g ag_new_officers=(PERS_NEW_TOTR)/(ag_officers)
	}
	
	* Workforce: Share of new hires that are black
	if inlist(`year',2016){
		g ag_new_officers_black = PERS_NEW_BLK / PERS_NEW_TOTR 
	}

	* Workforce: Share of new hires that are white
	if inlist(`year',2016){
		g ag_new_officers_white = PERS_NEW_WHT / PERS_NEW_TOTR 
	}
	
	* Workforce: Turnover rate
	if inlist(`year',2013){
		g ag_turnover=HIR_SEP_TTL / ag_officers
	}
	if inlist(`year',2016){
		g ag_turnover=PERS_SEP_TOTR / ag_officers
	}
	
	* Workforce: Black turnover rate
	if inlist(`year',2016){
		g ag_turnover_black = PERS_SEP_BLK / (PERS_BLACK_MALE + PERS_BLACK_FEM)
	}

	* Workforce: White turnover rate
	if inlist(`year',2016){
		g ag_turnover_white = PERS_SEP_WHT / (PERS_WHITE_MALE + PERS_WHITE_FEM)
	}

	* Workforce: Other Hiring
	if inlist(`year',2013){
		g ag_direct_hires = HIR_NBR_DRCT_FT+HIR_NBR_DRCT_PT
		g ag_involuntary_turnover = HIR_SEP_DIS/ag_officers
	}

	* 1) Community policing: mission statement
	if inlist(`year',2013){
		g ag_cp_mission = inlist(COM_MIS,3) if !inlist(COM_MIS,.)
	}
	if inlist(`year',2016){
		g ag_cp_mission = inlist(CP_MISSION,1) if !inlist(CP_MISSION,.)
	}	
	
	* 2) Community policing: 8 hour training, new recruits
	if inlist(`year',2013){
		g ag_cp_train_recruit = inlist(COM_TRN_REC,1,2,3) if !inlist(COM_TRN_REC,.)
	}
	if inlist(`year',2016){
		g ag_cp_train_recruit = inlist(CP_TRN_NEW,1,2) if !inlist(CP_TRN_NEW,.)
	}

	* 3) Community policing: 8 hour training, in service sworn personal
	if inlist(`year',2013){
		g ag_cp_train_current = inlist(COM_TRN_INSRV,1,2,3) if !inlist(COM_TRN_INSRV,.)
	}
	if inlist(`year',2016){
		g ag_cp_train_current = inlist(CP_TRN_INSRV,1,2) if !inlist(CP_TRN_INSRV,.)
	}
	
	* 4) Community policing: SARA-TYPE PROBLEM-SOLVING PROJECTS ACTIVELY ENCOURAGED
	if inlist(`year',2013){
		g ag_cp_sara = COM_NSARA > 0 if !inlist(COM_NSARA,.)
	}
	if inlist(`year',2016){
		g ag_cp_sara = CP_SARA_NUM > 0 if !inlist(CP_SARA_NUM,.)
	}
	
	* 5) Community policing: sara ag_officers
	if inlist(`year',2013){
		g ag_cp_nsara = COM_NSARA / ag_officers
	}
	if inlist(`year',2016){
		g ag_cp_nsara = CP_SARA_NUM / ag_officers
	}

	* 6) Community policing: PROBLEM-SOLVING PARTNERSHIP OR WRITTEN AGREEMENT WITH LOCAL ORGANIZATION
	if inlist(`year',2013){
		g ag_cp_problemsolve = inlist(COM_PTNR,1) if !inlist(COM_PTNR,.)
	}
	if inlist(`year',2016){
		g ag_cp_problemsolve = inlist(CP_PSP_ADVGRP,1) | inlist(CP_PSP_BUSGRP,1) |	///
			inlist(CP_PSP_LEA,1) | inlist(CP_PSP_NEIGH,1) | 					///
			inlist(CP_PSP_UNIV,1) | inlist(CP_PSP_OTH,1) 						///
			if !inlist(CP_PSP_ADVGRP,.) & !inlist(CP_PSP_BUSGRP,.)				///
			& !inlist(CP_PSP_LEA,.) & !inlist(CP_PSP_NEIGH,.) 					///
			& !inlist(CP_PSP_UNIV,.)	& !inlist(CP_PSP_OTH,.)
	}
	
	* 7) Community policing: same patrol areas
	if inlist(`year',2013){
		g ag_cp_patrol = COM_NBT > 0 if !inlist(COM_NBT,.)
	}
	if inlist(`year',2016){
		g ag_cp_patrol = CP_BEATS_NUM > 0 if !inlist(CP_BEATS_NUM,.)
	}	

	* 8) Community policing: number same patrol areas
	if inlist(`year',2013){
		g ag_cp_npatrol = COM_NBT / ag_officers
	}
	if inlist(`year',2016){
		g ag_cp_npatrol = CP_BEATS_NUM / ag_officers
	}

	* Use-of-force equipment: neck restraint
	if inlist(`year',2013){
		g ag_uof_neck = inlist(SAFE_AUTH_NECK,1,2) if !inlist(SAFE_AUTH_NECK,.)
	}
	if inlist(`year',2016){
		g ag_uof_neck = inlist(EQ_AUTH_NECK,1,2)  if !inlist(EQ_AUTH_NECK,.)
	}

	* Use-of-force equipment: chemical agent
	if inlist(`year',2013){
		g ag_uof_chem = inlist(SAFE_AUTH_CHEM,1,2) if !inlist(SAFE_AUTH_CHEM,.)
	}
	if inlist(`year',2016){
		g ag_uof_chem = inlist(EQ_AUTH_CHEM,1,2)  if !inlist(EQ_AUTH_CHEM,.)
	}
	
	* Use-of-force equipment: handgun (primary sidearm)
	if inlist(`year',2013){
		g ag_uof_handgun = inlist(SAFE_AUTH_HGN,1,2) if !inlist(SAFE_AUTH_HGN,.)
	}
	if inlist(`year',2016){
		
		* semi automatic sidearm
		g ag_uof_semi = inlist(EQ_SEMI_ON_PRIM,1) | inlist(EQ_SEMI_ON_BACK,1)  if !inlist(EQ_SEMI_ON_PRIM,.)
		
		* revolver
		g ag_uof_revolver = inlist(EQ_REV_ON_PRIM,1) | inlist(EQ_REV_ON_BACK,1)  if !inlist(EQ_REV_ON_PRIM,.)
		
		* Either
		g ag_uof_handgun = inlist(ag_uof_semi,1) | inlist(ag_uof_revolver,1) if !inlist(ag_uof_semi,.)&!inlist(ag_uof_revolver,.)
		replace ag_uof_handgun = 1 if inlist(ag_uof_semi,1) | inlist(ag_uof_revolver,1) 
		drop ag_uof_revolver ag_uof_semi
	
	}
	
	* Documentation of use-of-force: neck restraint
	if inlist(`year',2013){
		g ag_doc_neck = inlist(SAFE_DOC_NECK,1) if !inlist(SAFE_DOC_NECK,.)
	}
	if inlist(`year',2016){
		g ag_doc_neck = inlist(EQ_DOC_NECK,1)  if !inlist(EQ_DOC_NECK,.)
	}
	
	* Documentation of use-of-force: chemical agent
	if inlist(`year',2013){
		g ag_doc_chem = inlist(SAFE_DOC_CHEM,1) if !inlist(SAFE_DOC_CHEM,.)
	}
	if inlist(`year',2016){
		g ag_doc_chem = inlist(EQ_DOC_CHEM,1)  if !inlist(EQ_DOC_CHEM,.)
	}
	
	* Documentation of use-of-force: display of fire arm
	if inlist(`year',2013){
		g ag_doc_display = inlist(SAFE_DOC_DISF,1) if !inlist(SAFE_DOC_DISF,.)
	}
	if inlist(`year',2016){
		g ag_doc_display = inlist(EQ_DOC_DIS_GUN,1)  if !inlist(EQ_DOC_DIS_GUN,.)
	}
	
	* Documentation of use-of-force: use of fire arm
	if inlist(`year',2013){
		g ag_doc_discharge = inlist(SAFE_DOC_DCHF,1) if !inlist(SAFE_DOC_DCHF,.)
	}
	if inlist(`year',2016){
		g ag_doc_discharge = inlist(EQ_DOC_DCHG_GUN,1)  if !inlist(EQ_DOC_DCHG_GUN,.)
	}
	
	* Screening techniques: Minimum education requirement (Some college)
	if inlist(`year',2013){
		g ag_min_edu = ( HIR_EDU_AD == 1 | HIR_EDU_BD == 1 ) if HIR_EDU_AD !=. & HIR_EDU_BD != .
	}
	if inlist(`year',2016){
		g ag_min_edu = inlist(PERS_EDU_MIN,1,2) if !inlist(PERS_EDU_MIN,.)
	}
	
	*  Other policy indiactors, 2013
	if inlist(`year',2013){
		g ag_patrol=PERS_RESP_PATRL/ag_officers
		g ag_union=(PAY_BARG==1)
			replace ag_union=. if PAY_BARG==.
		g ag_union_agreement=(PAY_SBARG==1)
			replace ag_union_agreement=. if PAY_SBARG==.
		g ag_overtime_partrol=(PAY_FUNC_PTRL==1)
			replace ag_overtime_partrol=. if PAY_FUNC_PTRL==.
		g ag_overtime_emergency=(PAY_FUNC_EMRG==1)
			replace ag_overtime_emergency=. if PAY_FUNC_EMRG==.
		g ag_marked_car=VEH_OPRT_MK/(VEH_OPRT_UNMK+VEH_OPRT_MK)
		drop VEH_OPRT_UNMK VEH_OPRT_MK

		local policy="HIR_TRN_NO_L BDGT_RED VEH_REST_NO SAFE_FINC NO_RECORD_FORCE SAFE_FRC_INC SAFE_FRC_OFFC SAFE_FTTL SAFE_RQUR_ACC SAFE_RQUR_RSK SAFE_RQUR_ALL ISSU_ADDR_GANG TECH_TYP_VPUB TECH_TYP_VVEH TECH_TYP_VPAT TECH_TYP_VWPN"
		foreach v in `policy' {
			replace `v'=(`v'==1) if `v'!=.
			rename `v' ag_`v'
			rename ag_`v', lower
		}
	}
	
	****** 3) Clean and Save **********

	* Clean up
	local lower = ""
	foreach v of varlist *{
		if lower("`v'") == "`v'"{
			local lower = "`lower' `v'"
		}
	}
	cap rename FINALWGT FINALWT
	keep ORI* FINALWT  strata `lower'

	* save file
	aorder
	order ORI* FINALWT strata agency stabb city year
	compress
	save DTA/LEMAS_`year', replace
	
	* Delete unused directory to save memory
	sleep 5000
	shell rmdir "Data/Law Enforcement Management and Administrative Statistics/ICPSR_`filenum'" /s /q
	cap rmdir "Data/Law Enforcement Management and Administrative Statistics/ICPSR_`filenum'"

}



/* Codebook for "other" policies
HIR_TRN_NO_L - C4A1.NO ADDITIONAL LAW ENFORCEMENT TRAINING FOR LATERAL HIRES
BDGT_RED - D4.AGENCY-WIDE REDUCTIONS IN BASE SALARY IMPLEMENTED
VEH_REST_NO - G6.NO WRITTEN POLICY ON FOOT PURSUITS
SAFE_FINC - H3.DOCUMENTATION OF USE OF FORCE
NO_RECORD_FORCE - H4.NO RECORD OF USES OF FORCE
SAFE_FRC_INC - H4A.ONE REPORT PER USE OF FORCE INCIDENT
SAFE_FRC_OFFC - H4B.ONE REPORT PER OFFICER INVOLVED IN USE OF FORCE INCIDENT
SAFE_FTTL - H5.NUMBER OF USE OF FORCE INCIDENTS
SAFE_RQUR_ACC - H8A.REQUIRED ACCESS TO BODY ARMOR FOR UNIFORMED FIELD/PATROL OFFICERS AT ALL TIMES
SAFE_RQUR_RSK - H8B.UNIFORMED FIELD/PATROL OFFICERS REQUIRED TO WEAR BODY ARMOR IN HIGH RISK CONDITIONS
SAFE_RQUR_ALL - H8C.UNIFORMED FIELD/PATROL OFFICERS REQUIRED TO WEAR BODY ARMOR AT ALL TIMES
ISSU_ADDR_GANG - I1J.SPECIALIZED UNIT FOR GANGS
TECH_TYP_VPUB - F1D.UTILIZED VIDEO SURVEILLANCE OF PUBLIC AREAS
TECH_TYP_VVEH - F1E.UTILIZED VIDEO CAMERAS IN PATROL VEHICLES
TECH_TYP_VPAT - F1F.UTILIZED VIDEO CAMERAS ON PATROL OFFICERS
TECH_TYP_VWPN - F1G.UTILIZED VIDEO CAMERAS ON WEAPONS
