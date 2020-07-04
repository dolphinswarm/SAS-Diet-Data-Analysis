/*

Author: Brad Schmitz
Course: STA 402 (Statistical Programming)
Assignment: Final Project

*/
/*  
	===========================================================
	=  _____             __  __    __          __             =
	= (_  |  /\    |__| /  \  _)  |_. _  _ |  |__)_ _ . _ _|_ =
	= __) | /--\      | \__/ /__  | || )(_||  |  | (_)|(-(_|_ =
	=                                                /        =
	===========================================================
*/
/*
Title: Analyzing the Relationship Between Health and Diet

Description: This SAS program does the following steps:
	1. If the dataset is not found, load it and create a dataset
		a. While loading, filter the data to get only necessary variables
		b. Clean the data to make it easier to read and use
	2. Create two SAS macros for analyzing the variables
		a. compare_health_var_num: Compares a categorical input with a numeric input by running PROC MEANS, 
			PROC SGPLOT (vertical box), and PROC NPAR1WAY
		b. compare_health_var_num: Compares two sepeate categorical inputs by running PROC FREQ
	3. Run the macros on the data to find trends
	4. Create statistical models for both mental and physical health the find the best predictors of each.
		This is accomplished through the use of PROC GLM and PROC GLMSELECT.

Variables:
	== Identifiers ==
		o	sex_: the sex of the respondent (male or female)
	== Overall Health ==
		o	general_health: a person’s overall health, on a scale of 1 to 5 (1 being Excellent and 5 being Poor)
		o	physical_health: the number of days physical health was not good in the past 30 days
		o	ph_group: A categorical version of physical_health, grouped by every 5 days
		o	mental_health: the number of days a person’s mental health was not good in the past 30 days
		o	mh_group: A categorical version of mental_health, grouped by every 5 days
	== Health Issues ==
		o	high_blood_pressure: Whether or not the respondent ever had high blood pressure
		o	high_cholesterol: Whether or not the respondent ever had high blood cholesterol
		o	heart_attack: Whether or not the respondent ever had a heart attack
		o	cor_heart_disease: Whether or not the respondent ever had a coronary heart disease
		o	stroke: Whether or not the respondent ever had a stroke
		o	asthma: Whether or not the respondent ever had asthma
		o	skin_cancer: Whether or not the respondent ever had skin cancer
		o	other_cancer: Whether or not the respondent ever had another type of cancer
		o	lung_disease: Whether or not the respondent ever had any lung diseases (bronchitis, pulmonary disease, etc.)
		o	arthritis: Whether or not the respondent ever had arthritis
		o	depressive_disorder: Whether or not the respondent ever had depressive disorder
		o	kidney_disease: Whether or not the respondent ever had kidney disease
		o	diabetes: Whether or not the respondent ever had diabetes
	== Diet Variables ==
		o	days_drank: The number of days the respondent consumed alcohol, in the past 30 days
		o	average_drinks: The average number of alcoholic drinks the respondent had in the past 30 days
		o	binge_drink: The number of times the respondent binge-drank in the past 30 days
		o	max_drinks: The most drinks consumed in a single occasion in the past 30 days
		o	fruit_times: The average number of times the respondent consumed fruit per day
		o	juice_times: The average number of times the respondent consumed pure fruit juices per day
		o	veggie_times: The average number of times the respondent consumed dark green vegetables per day
		o	fry_times: The average number of times the respondent consumed fried potatoes per day
		o	potato_times: The average number of times the respondent consumed non-fried potatoes per day
		o	ngveggie_times: The average number of times the respondent consumed non-dark green vegetables per day
		o	soda_times: The average number of times the respondent consumed soda per day
		o	swtdrnk_times: The average number of times the respondent consumed sugar-sweetened drinks per day
		o	red_sodium: Is the respondent reducing their sodium intake?
		o	ch_eat_hab: Is the respondent changing their eating habits?
		o	red_salt: Is the respondent reducing their salt intake?
		o	red_alcohol: Is the respondent reducing their alcohol intake?
		o	meal_money: How often can the respondent not afford balanced meals?
*/

/* ======= Set the filepath ======= */
%let filepath = M:\STA 402\Project\Data;

/* ======= Set the library ======= */
libname Project "&filepath";

/* ======= Use a SAS transport file to import the dataset ======= */
/* Commented out because the dataset was imported. Uncomment out to import using the SAS Transport file */
/*
libname trans xport "&filepath\LLCP2017.XPT";
libname cdcdata v7 "&filepath";
proc copy in=trans out=cdcdata;
run;
*/

/* ======= Create SAS Macros for data handling ======= */
/* Macro for checking to see if the dataset exists */
%macro check_data(dataset);
	%if %sysfunc(exist(&dataset)) %then %do; %end;
	%else %load_data(&dataset);
%mend check_data;

/* Macro for loading data, if it does not exist */
%macro load_data(dataset);
	/* == Filter the dataset to get only wanted variables == */
	proc sql;
		create table project.raw_diet_data as
		select SEX, GENHLTH, PHYSHLTH, MENTHLTH, BPHIGH4, TOLDHI2, CVDINFR4, CVDCRHD4, 
			   CVDSTRK3, ASTHMA3, CHCSCNCR, CHCOCNCR, CHCCOPD1, HAVARTH3, ADDEPEV2, CHCKIDNY,
			   DIABETE3, ALCDAY5, AVEDRNK2, DRNK3GE5, MAXDRNKS, FRUIT2, FRUITJU2, FVGREEN1,
			   FRENCHF1, POTATOE1, VEGETAB2, SSBSUGR2, SSBFRUT3, WTCHSALT, BPEATHBT, BPSALT, BPALCHOL, SDHMEALS
		from project.llcp2017;
	quit;

	/* == Re-format the data to make it easier to read == */
	/* Re-format sex */
	data project.diet_data;
		/* Select the dataset */
		set project.raw_diet_data;

		/* Format new column */
		format sex_ $6.;

		/* Delete rows w/ missing or useless entries */
		if missing(SEX) then delete;
		if SEX >= 3 then delete;

		/* Reformat sex variable */
		if SEX = 1 then sex_ = "Male";
		if SEX = 2 then sex_ = "Female";

		/* Drop the old column */
		drop SEX;

		/* Label the new column */
		label sex_ = "Sex";
	run;

	/* Re-format general health */
	data project.diet_data;
		/* Select the dataset */
		set project.diet_data;

		/* Format new column */
		format general_health BEST12.;
		
		/* Delete rows w/ missing or useless entries */
		if missing(GENHLTH) then delete;
		if GENHLTH >= 7 then delete;

		/* Reformat the general health variable */
		general_health = GENHLTH;

		/* Drop the old column */
		drop GENHLTH;
		
		/* Label the new column */
		label general_health = "General Health";
	run;

	/* Re-format physical and mental health */
	data project.diet_data;
		/* Select the dataset */
		set project.diet_data;

		/* Delete rows w/ missing / useless entries */
		if missing(PHYSHLTH) then delete;
		if PHYSHLTH = 77 then delete;
		if PHYSHLTH = 99 then delete;
		if missing(MENTHLTH) then delete;
		if MENTHLTH = 77 then delete;
		if MENTHLTH = 99 then delete;

		/* Reformat the health variables */
		format physical_health BEST12.;
		if PHYSHLTH = 88 then physical_health = 0;
		if PHYSHLTH <= 30 then physical_health = PHYSHLTH;

		format mental_health BEST12.;
		if MENTHLTH = 88 then mental_health = 0;
		if MENTHLTH <= 30 then mental_health = MENTHLTH;

		/* Create new grouping columns */
		format mh_group BEST12.;
		if mental_health > 25 then mh_group = 6;
		else if mental_health > 20 then mh_group = 5;
		else if mental_health > 15 then mh_group = 4;
		else if mental_health > 10 then mh_group = 3;
		else if mental_health > 5 then mh_group = 2;
		else mh_group = 1;

		format ph_group BEST12.;
		if physical_health > 25 then ph_group = 6;
		else if physical_health > 20 then ph_group = 5;
		else if physical_health > 15 then ph_group = 4;
		else if physical_health > 10 then ph_group = 3;
		else if physical_health > 5 then ph_group = 2;
		else ph_group = 1;

		/* Drop the old columns */
		drop PHYSHLTH MENTHLTH;
		
		/* Label the new column */
		label physical_health = "Number of days physical health was not good in past 30 days";
		label ph_group = "Number of days physical health was not good in past 30 days (grouped)";
		label mental_health = "Number of days mental health was not good in past 30 days";
		label mh_group = "Number of days mental health was not good in past 30 days (grouped)";
	run;

	/* Re-format health issues */
	/*  BPHIGH4, TOLDHI2, CVDINFR4, CVDCRHD4, CVDSTRK3, ASTHMA3, CHCSCNCR, CHCOCNCR, CHCCOPD1, HAVARTH3, ADDEPEV2, CHCKIDNY, DIABETE3 */
	data project.diet_data;
		/* Select the dataset */
		set project.diet_data;

		/* Delete rows w/ missing / useless entries */
		if missing(BPHIGH4) then delete;
		if missing(TOLDHI2) then delete;
		if missing(CVDINFR4) then delete;
		if missing(CVDCRHD4) then delete;
		if missing(CVDSTRK3) then delete;
		if missing(ASTHMA3) then delete;
		if missing(CHCSCNCR) then delete;
		if missing(CHCOCNCR) then delete;
		if missing(CHCCOPD1) then delete;
		if missing(HAVARTH3) then delete;
		if missing(ADDEPEV2) then delete;
		if missing(CHCKIDNY) then delete;
		if missing(DIABETE3) then delete;

		/* Reformat the health issues */
		/* Blood pressure */
		format high_blood_pressure $3.;
		if BPHIGH4 = 1 then high_blood_pressure = "Yes";
		if BPHIGH4 = 2 then high_blood_pressure = "Yes";
		if BPHIGH4 = 3 then high_blood_pressure = "No";
		if BPHIGH4 = 4 then high_blood_pressure = "No";
		if BPHIGH4 >= 5 then delete;

		/* High choloesterol */
		format high_cholesterol $3.;
		if TOLDHI2 = 1 then high_cholesterol = "Yes";
		if TOLDHI2 = 2 then high_cholesterol = "No";
		if TOLDHI2 >= 3 then delete;

		/* Heart attack */
		format heart_attack $3.;
		if CVDINFR4 = 1 then heart_attack = "Yes";
		if CVDINFR4 = 2 then heart_attack = "No";
		if CVDINFR4 >= 3 then delete;

		/* Coronary Heart Disease */
		format cor_heart_disease $3.;
		if CVDCRHD4 = 1 then cor_heart_disease = "Yes";
		if CVDCRHD4 = 2 then cor_heart_disease = "No";
		if CVDCRHD4 >= 3 then delete;

		/* Stroke */
		format stroke $3.;
		if CVDSTRK3 = 1 then stroke = "Yes";
		if CVDSTRK3 = 2 then stroke = "No";
		if CVDSTRK3 >= 3 then delete;

		/* Asthma */
		format asthma $3.;
		if ASTHMA3 = 1 then asthma = "Yes";
		if ASTHMA3 = 2 then asthma = "No";
		if ASTHMA3 >= 3 then delete;

		/* Skin cancer */
		format skin_cancer $3.;
		if CHCSCNCR = 1 then skin_cancer = "Yes";
		if CHCSCNCR = 2 then skin_cancer = "No";
		if CHCSCNCR >= 3 then delete;

		/* Other types of cancer */
		format other_cancer $3.;
		if CHCOCNCR = 1 then other_cancer = "Yes";
		if CHCOCNCR = 2 then other_cancer = "No";
		if CHCOCNCR >= 3 then delete;

		/* Lung diseases */
		format lung_disease $3.;
		if CHCCOPD1 = 1 then lung_disease = "Yes";
		if CHCCOPD1 = 2 then lung_disease = "No";
		if CHCCOPD1 >= 3 then delete;

		/* Arthritis */
		format arthritis $3.;
		if HAVARTH3 = 1 then arthritis = "Yes";
		if HAVARTH3 = 2 then arthritis = "No";
		if HAVARTH3 >= 3 then delete;

		/* Depression */
		format depressive_disorder $3.;
		if ADDEPEV2 = 1 then depressive_disorder = "Yes";
		if ADDEPEV2 = 2 then depressive_disorder = "No";
		if ADDEPEV2 >= 3 then delete;

		/* Kidney disease */
		format kidney_disease $3.;
		if CHCKIDNY = 1 then kidney_disease = "Yes";
		if CHCKIDNY = 2 then kidney_disease = "No";
		if CHCKIDNY >= 3 then delete;

		/* Diabetes */
		format diabetes $3.;
		if DIABETE3 = 1 then diabetes = "Yes";
		if DIABETE3 = 2 then diabetes = "Yes";
		if DIABETE3 = 3 then diabetes = "No";
		if DIABETE3 = 4 then diabetes = "No";
		if DIABETE3 >= 5 then delete; 

		/* Drop the old columns */
		drop BPHIGH4 TOLDHI2 CVDINFR4 CVDCRHD4 CVDSTRK3 ASTHMA3 CHCSCNCR CHCOCNCR CHCCOPD1 HAVARTH3 ADDEPEV2 CHCKIDNY DIABETE3;

		/* Label the new columns */
		label high_blood_pressure = "Have / had high blood pressure?";
		label high_cholesterol = "Have high cholesterol?";
		label heart_attack = "Had heart attack?";
		label cor_heart_disease = "Have coronary heart disease?";
		label stroke = "Had stroke?";
		label asthma = "Have asthma?";
		label skin_cancer = "Have / had skin cancer?";
		label other_cancer = "Have / had other cancer?";
		label lung_disease = "Have lung disease (obstructive pulmonary disease, C.O.P.D., emphysema or chronic bronchitis)?";
		label arthritis = "Have arthritis?";
		label depressive_disorder = "Have depressive disorder?";
		label kidney_disease = "Have kidney disease?";
		label diabetes = "Have / had diabetes?";
	run;

	/* Re-format alcohol variables */
	/* ALCDAY5, AVEDRNK2, DRNK3GE5, MAXDRNKS */
	data project.diet_data;
		/* Select the dataset */
		set project.diet_data;

		/* Delete rows w/ missing / useless entries */
		if missing(ALCDAY5) then delete;
		if ALCDAY5 = 777 then delete;
		if ALCDAY5 = 999 then delete;
		if AVEDRNK2 = 77 then delete;
		if AVEDRNK2 = 99 then delete;
		if DRNK3GE5 = 77 then delete;
		if DRNK3GE5 = 99 then delete;
		if MAXDRNKS = 77 then delete;
		if MAXDRNKS = 99 then delete;

		/* Re-format columns */
		format days_drank 6.4;
		if ALCDAY5 = 888 then days_drank = 0;
		if substrn(ALCDAY5, 1, 1) = 1 then days_drank = substrn(ALCDAY5, 3, 1) * 7;
		if substrn(ALCDAY5, 1, 1) = 2 then days_drank = substrn(ALCDAY5, 2, 2);
		if days_drank >= 31 then delete;

		format average_drinks 6.4;
		if missing(AVEDRNK2) then average_drinks = 0;
		else average_drinks = substrn(AVEDRNK2, 1);
		if average_drinks >= 18 then delete;

		format binge_drink 6.4;
		if DRNK3GE5 = 88 then binge_drink = 0;
		else binge_drink = substrn(DRNK3GE5, 1);
		if missing(DRNK3GE5) then binge_drink = 0;
		if binge_drink >= 41 then delete;

		format max_drinks 6.4;
		if missing(MAXDRNKS) then max_drinks = 0;
		else max_drinks = substrn(MAXDRNKS, 1);
		if max_drinks >= 18 then delete;

		/* Drop the old columns */
		drop ALCDAY5 AVEDRNK2 DRNK3GE5 MAXDRNKS;

		/* Label the new columns */
		label days_drank = "Number of days alcohol was consumed in past 30 days";
		label average_drinks = "Average drinks per day";
		label binge_drink = "Times binge drinking in the last 30 days";
		label max_drinks = "Max number of drinks per session in last 30 days";
	run;

	/* Re-format fruit and veggie variables */
	/* FRUIT2, FRUITJU2, FVGREEN1, FRENCHF1, POTATOE1, VEGETAB2 */
	data project.diet_data;
		/* Select the dataset */
		set project.diet_data;

		/* Delete rows w/ missing / useless entries */
		if FRUIT2 = 777 then delete;
		if FRUIT2 = 999 then delete;
		if FRUITJU2 = 777 then delete;
		if FRUITJU2 = 999 then delete;
		if FVGREEN1 = 777 then delete;
		if FVGREEN1 = 999 then delete;
		if FRENCHF1 = 777 then delete;
		if FRENCHF1 = 999 then delete;
		if POTATOE1 = 777 then delete;
		if POTATOE1 = 999 then delete;
		if VEGETAB2 = 777 then delete;
		if VEGETAB2 = 999 then delete;

		/* Re-format columns */
		/* Fruit */
		format fruit_times 6.4;
		if substrn(FRUIT2, 1, 1) = 1 then fruit_times = substrn(FRUIT2, 2, 2);
		if substrn(FRUIT2, 1, 1) = 2 then fruit_times = substrn(FRUIT2, 2, 2) / 7; /* Average per week / days in week */
		if substrn(FRUIT2, 1, 1) = 3 then fruit_times = substrn(FRUIT2, 2, 2) / 30; /* Average per month / days in month */
		if FRUIT2 = 300 then fruit_times = 0;
		if FRUIT2 = 555 then fruit_times = 0;
		if fruit_times >= 16 then delete;

		/* Fruit juice */
		format juice_times 6.4;
		if substrn(FRUITJU2, 1, 1) = 1 then juice_times = substrn(FRUIT2, 2, 2);
		if substrn(FRUITJU2, 1, 1) = 2 then juice_times = substrn(FRUIT2, 2, 2) / 7;
		if substrn(FRUITJU2, 1, 1) = 3 then juice_times = substrn(FRUIT2, 2, 2) / 30;
		if FRUITJU2 = 300 then juice_times = 0;
		if FRUITJU2 = 555 then juice_times = 0;
		if juice_times >= 16 then delete;

		/* Green veggies */
		format veggie_times 6.4;
		if substrn(FVGREEN1, 1, 1) = 1 then veggie_times = substrn(FVGREEN1, 2, 2);
		if substrn(FVGREEN1, 1, 1) = 2 then veggie_times = substrn(FVGREEN1, 2, 2) / 7;
		if substrn(FVGREEN1, 1, 1) = 3 then veggie_times = substrn(FVGREEN1, 2, 2) / 30;
		if FVGREEN1 = 300 then veggie_times = 0;
		if FVGREEN1 = 555 then veggie_times = 0;
		if veggie_times >= 16 then delete;

		/* French fries */
		format fry_times 6.4;
		if substrn(FRENCHF1, 1, 1) = 1 then fry_times = substrn(FRENCHF1, 2, 2);
		if substrn(FRENCHF1, 1, 1) = 2 then fry_times = substrn(FRENCHF1, 2, 2) / 7;
		if substrn(FRENCHF1, 1, 1) = 3 then fry_times = substrn(FRENCHF1, 2, 2) / 30;
		if FRENCHF1 = 300 then fry_times = 0;
		if FRENCHF1 = 555 then fry_times = 0;
		if fry_times >= 16 then delete;

		/* Other potatoes */
		format potato_times 6.4;
		if substrn(POTATOE1, 1, 1) = 1 then potato_times = substrn(POTATOE1, 2, 2);
		if substrn(POTATOE1, 1, 1) = 2 then potato_times = substrn(POTATOE1, 2, 2) / 7; 
		if substrn(POTATOE1, 1, 1) = 3 then potato_times = substrn(POTATOE1, 2, 2) / 30;
		if POTATOE1 = 300 then potato_times = 0;
		if POTATOE1 = 555 then potato_times = 0;
		if potato_times >= 16 then delete;

		/* Non-green veggies */
		format ngveggie_times 6.4;
		if substrn(VEGETAB2, 1, 1) = 1 then ngveggie_times = substrn(VEGETAB2, 2, 2);
		if substrn(VEGETAB2, 1, 1) = 2 then ngveggie_times = substrn(VEGETAB2, 2, 2) / 7;
		if substrn(VEGETAB2, 1, 1) = 3 then ngveggie_times = substrn(VEGETAB2, 2, 2) / 30;
		if VEGETAB2 = 300 then ngveggie_times = 0;
		if VEGETAB2 = 555 then ngveggie_times = 0;
		if ngveggie_times >= 16 then delete;

		/* Drop the old columns */
		drop FRUIT2 FRUITJU2 FVGREEN1 FRENCHF1 POTATOE1 VEGETAB2;

		/* Label the new columns */
		label fruit_times = "Average fruit consumption frequency per day";
		label juice_times = "Average pure fruit juice consumption frequency per day";
		label veggie_times = "Average green vegetable consumption frequency per day";
		label fry_times = "Average fried potato consumption frequency per day";
		label potato_times = "Average non-fried potato consumption frequency per day";
		label ngveggie_times = "Average other vegetable consumption frequency per day";
	run;

	/* Re-format sugar variables */
	/* SSBSUGR2, SSBFRUT3 */
	data project.diet_data;
		/* Select the dataset */
		set project.diet_data;

		/* Delete rows w/ missing / useless entries */
		if SSBSUGR2 = 777 then delete;
		if SSBSUGR2 = 999 then delete;
		if SSBFRUT3 = 777 then delete;
		if SSBFRUT3 = 999 then delete;

		/* Re-format columns */
		/* Soda */
		format soda_times 6.4;
		if substrn(SSBSUGR2, 1, 1) = 1 then soda_times = substrn(SSBSUGR2, 2, 2);
		if substrn(SSBSUGR2, 1, 1) = 2 then soda_times = substrn(SSBSUGR2, 2, 2) / 7;
		if substrn(SSBSUGR2, 1, 1) = 3 then soda_times = substrn(SSBSUGR2, 2, 2) / 30;
		if SSBSUGR2 = 888 then soda_times = 0;
		if soda_times >= 16 then delete;

		/* Sugar-sweetened drinks */
		format swtdrnk_times 6.4;
		if substrn(SSBFRUT3, 1, 1) = 1 then swtdrnk_times = substrn(SSBFRUT3, 2, 2);
		if substrn(SSBFRUT3, 1, 1) = 2 then swtdrnk_times = substrn(SSBFRUT3, 2, 2) / 7;
		if substrn(SSBFRUT3, 1, 1) = 3 then swtdrnk_times = substrn(SSBFRUT3, 2, 2) / 30;
		if SSBFRUT3 = 888 then swtdrnk_times = 0;
		if swtdrnk_times >= 16 then delete;

		/* Drop the old columns */
		drop SSBSUGR2 SSBFRUT3;

		/* Re-format the new columns */
		label soda_times = "Average soda consumption frequency per day";
		label swtdrnk_times = "Average sugar-sweetened drink consumption frequency per day";
	run;

	/* Re-format eating habit variables */
	/* WTCHSALT, BPEATHBT, BPSALT, BPALCHOL, SDHMEALS */
	data project.diet_data;
		/* Select the dataset */
		set project.diet_data;

		/* Delete rows w/ missing / useless entries */
		if WTCHSALT = 7 then delete;
		if WTCHSALT = 9 then delete;
		if BPEATHBT = 7 then delete;
		if BPEATHBT = 9 then delete;
		if BPSALT = 7 then delete;
		if BPSALT = 9 then delete;
		if BPALCHOL = 7 then delete;
		if BPALCHOL = 9 then delete;
		if SDHMEALS = 7 then delete;
		if SDHMEALS = 9 then delete;

		/* Sodium intake */
		format red_sodium $3.;
		if WTCHSALT = 1 then red_sodium = "Yes";
		if WTCHSALT = 2 then red_sodium = "No";

		/* Salt intake */
		format red_salt $3.;
		if BPSALT = 1 then red_salt = "Yes";
		if BPSALT = 2 then red_salt = "No";

		/* Alcohol intake */
		format red_alcohol $3.;
		if BPALCHOL = 1 then red_alcohol = "Yes";
		if BPALCHOL = 2 then red_alcohol = "No";

		/* Change eating habits */
		format ch_eat_hab $3.;
		if BPEATHBT = 1 then ch_eat_hab = "Yes";
		if BPEATHBT = 2 then ch_eat_hab = "No";

		/* Money for meals? */
		format meal_money $9.;
		if SDHMEALS = 1 then meal_money = "Often";
		if SDHMEALS = 2 then meal_money = "Sometimes";
		if SDHMEALS = 3 then meal_money = "Never";

		/* Drop the old columns */
		drop WTCHSALT BPEATHBT BPSALT BPALCHOL SDHMEALS;

		/* Re-format the new columns */
		label red_sodium = "Reducing sodium intake?";
		label ch_eat_hab = "Changing eating habits?";
		label red_salt = "Reducing salt intake?";
		label red_alcohol = "Reducing alcohol intake?";
		label meal_money = "How often can you not afford balanced meals?";
	run;

	/* Create a subsetted dataset with only extreme data for overall health data */
	proc sql;
		create table project.diet_data_ep as
		select * from project.diet_data
		where general_health = 1 or general_health = 5;
	quit;

	proc sql;
		create table project.diet_data_ep as
		select * from project.diet_data_ep
		where ph_group = 1 or ph_group = 6;
	quit;

	proc sql;
		create table project.diet_data_ep as
		select * from project.diet_data_ep
		where mh_group = 1 or mh_group = 6;
	quit;
%mend load_data;

/* Run the macro for loading data */
%check_data(project.diet_data);

/* ======= Create a SAS Format for the General Health, Mental Health Rank, and Physical Health Rank variables ======= */
proc format;
	value gh_rank
		1 = "Excellent"
		2 = "Very Good"
		3 = "Good"
		4 = "Fair"
		5 = "Poor";
	value mh_rank
		1 = "1-5 days"
		2 = "6-10 days"
		3 = "11-15 days"
		4 = "16-20 days"
		5 = "21-25 days"
		6 = "26-30 days";
	value ph_rank
		1 = "1-5 days"
		2 = "6-10 days"
		3 = "11-15 days"
		4 = "16-20 days"
		5 = "21-25 days"
		6 = "26-30 days";
run;

/* ======= Create SAS Macros for data viewing ======= */
/* Create macro variables for storing numeric predictors */
%let overall_health = general_health mh_group ph_group;

%let health_issues = high_blood_pressure high_cholesterol heart_attack 
						cor_heart_disease stroke asthma skin_cancer other_cancer lung_disease arthritis 
						depressive_disorder kidney_disease diabetes;

%let numeric_predictors = days_drank average_drinks binge_drink max_drinks  fruit_times juice_times 
							veggie_times fry_times potato_times ngveggie_times soda_times swtdrnk_times;

%let categorical_predictors = red_sodium ch_eat_hab red_salt red_alcohol meal_money;

/* 
SAS Macro for comparing categorical health issues to numeric variables.
- Accepts a varibale or list of categorical variables, and a variable or list of numeric predictorss
*/
%macro compare_health_var_num(health, predictors);
	/* Loop through each health variable */
	%do j = 1 %to %sysfunc(countw(&health.));

		/* Loop through each numeric predictor variable */
		%do i = 1 %to %sysfunc(countw(&predictors.));

			/* Print the currently-running test */
			%put ============= Comparing %scan(&health., &j, ', ') to %scan(&predictors., &i, ', ');
			
			/* Run some statistics on the data */
			proc means data=project.diet_data n min max mean median stddev;
				format general_health gh_rank. mh_group mh_rank. ph_group ph_rank.;
				class %scan(&health., &j, ", ");
				var %scan(&predictors., &i, ", ");
			run;

			/* Run a five-number plot of the data */
			proc sgplot data=project.diet_data;
				format general_health gh_rank. mh_group mh_rank. ph_group ph_rank.;
				vbox %scan(&predictors., &i, ", ") / category = %scan(&health., &j, ", ");
			run;
			
			/* Run a t-test to compare the two most extreme groups */
			proc npar1way data=project.diet_data_ep plots=median wilcoxon;
				format general_health gh_rank. mh_group mh_rank. ph_group ph_rank.;
				class %scan(&health., &j, ", ");
				var %scan(&predictors., &i, ", ");
			run;
		%end;
	%end;
	
%mend compare_health_var_num;

/* 
SAS Macro for comparing categorical health issues to categorical variables.
- Accepts two separate varibales or lists of categorical variables
*/
%macro compare_health_var_cat(health, predictors);
	/* Loop through each health variable */
	%do j = 1 %to %sysfunc(countw(&health.));

		/* Loop through each numeric predictor variable */
		%do i = 1 %to %sysfunc(countw(&predictors.));

			/* Print the currently-running test */
			%put ============= Comparing %scan(&health., &j, ', ') to %scan(&predictors., &i, ', ');

			/* Run a two-sample chi-square test on the data */
			proc freq data=project.diet_data;
				format general_health gh_rank. mh_group mh_rank. ph_group ph_rank.;
				tables %scan(&predictors., &i, ", ")*%scan(&health., &j, ", ") / plots=mosaic chisq;
			run;

		%end;
	%end;
%mend compare_health_var_cat;

/* ======= Run the SAS Macros created above ======= */
/* WARNING - RUNNING ALL BELOW COMMANDS TAKES OVER 45 MINUTES */

/* Compare the overall health variables to the numeric predictors */
%compare_health_var_num(&overall_health, &numeric_predictors);

/* Compare the health issues to the numeric predictors */
%compare_health_var_num(&health_issues, &numeric_predictors);

/* Compare the overall health variables to the categorical predictors */
%compare_health_var_cat(&overall_health, &categorical_predictors);

/* Compare the health issues to the categorical predictors */
%compare_health_var_cat(&health_issues, &categorical_predictors);

/* Compare the overall health variables to the health issues */
%compare_health_var_cat(general_health, &health_issues);

/* Compare the sex to the numeric predictors */
%compare_health_var_num(sex_, &numeric_predictors);

/* Compare the sex to the categorical predictors */
%compare_health_var_cat(sex_, &categorical_predictors);

/* ======= Create a model for predicting a person's mental health ======= */
/* Run a model with all health issues */
proc glm data=project.diet_data plots(maxpoints=329047)=all;
	class &health_issues meal_money;
	model mental_health = &health_issues meal_money;
run;

/* Run a model with all numerical variables */
proc glm data=project.diet_data plots(maxpoints=329047)=all;
	model mental_health = &numeric_predictors;
run;

/* Run a model with all misc. categorical variables (minus meal_money, since it doesn't work with the others) */
proc glm data=project.diet_data plots(maxpoints=329047)=all;
	class sex_ red_sodium ch_eat_hab red_salt red_alcohol;
	model mental_health = sex_ red_sodium ch_eat_hab red_salt red_alcohol;
run;

/* Run a model with all the most significant variables from the above modeling tests */
proc glm data=project.diet_data plots(maxpoints=329047)=all;
	class stroke asthma skin_cancer lung_disease arthritis depressive_disorder diabetes meal_money;
	model mental_health = stroke asthma skin_cancer lung_disease arthritis depressive_disorder diabetes meal_money
			days_drank binge_drink fruit_times veggie_times soda_times swtdrnk_times;
run;

/* Remove insignficant terms, then run a stepwise selection on the model */
proc glmselect data=project.diet_data plots=all;
	class depressive_disorder meal_money lung_disease stroke arthritis;
	model mental_health = depressive_disorder meal_money lung_disease stroke arthritis binge_drink soda_times
			/ selection=stepwise(select=SL) details=all stats=all;
run;

/* ======= Create a model for predicting a person's physical health ======= */
/* Run a model with all health issues */
proc glm data=project.diet_data plots(maxpoints=329047)=all;
	class &health_issues meal_money;
	model physical_health = &health_issues meal_money;
run;

/* Run a model with all numerical variables */
proc glm data=project.diet_data plots(maxpoints=329047)=all;
	model physical_health = &numeric_predictors;
run;

/* Run a model with all misc. categorical variables (minus meal_money, since it doesn't work with the others) */
proc glm data=project.diet_data plots(maxpoints=329047)=all;
	class sex_ red_sodium ch_eat_hab red_salt red_alcohol;
	model physical_health = sex_ red_sodium ch_eat_hab red_salt red_alcohol;
run;

/* Run a model with all the most significant variables from the above modeling tests */
proc glm data=project.diet_data plots(maxpoints=329047)=all;
	class high_blood_pressure heart_attack cor_heart_disease stroke asthma other_cancer lung_disease arthritis 
			depressive_disorder kidney_disease diabetes meal_money;
	model physical_health = high_blood_pressure heart_attack cor_heart_disease stroke asthma other_cancer lung_disease arthritis 
			depressive_disorder kidney_disease diabetes days_drank average_drinks binge_drink max_drinks  fruit_times
			veggie_times potato_times ngveggie_times soda_times swtdrnk_times meal_money;
run;

/* Remove insignficant terms, then run a stepwise selection on the model */
proc glmselect data=project.diet_data plots=all;
	class heart_attack cor_heart_disease stroke asthma other_cancer lung_disease arthritis depressive_disorder kidney_disease diabetes meal_money;
	model physical_health = heart_attack cor_heart_disease stroke asthma other_cancer lung_disease arthritis 
			depressive_disorder kidney_disease diabetes binge_drink veggie_times potato_times meal_money 
			/ selection=stepwise(select=SL) details=all stats=all;
run;

/* ======= Run a stepwise selection on only diet variables ======= */
/* Run a stepwise selection for the mental health using only diet variables */
proc glmselect data=project.diet_data plots=all;
	model mental_health = &numeric_predictors
			/ selection=stepwise(select=SL) details=all stats=all;
run;

/* Run a stepwise selection for the physical health using only diet variables */
proc glmselect data=project.diet_data plots=all;
	model physical_health = &numeric_predictors
			/ selection=stepwise(select=SL) details=all stats=all;
run;
