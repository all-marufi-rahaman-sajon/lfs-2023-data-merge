################################################################################
# LFS 2023 COMPLETE MERGE WITH VALIDATION
################################################################################
# Author: All-Marufi Rahaman Sajon
# Date: January 2025
# Purpose: Merge quarterly datasets from Bangladesh Labor Force Survey (LFS) 2023
#          with validation against published BBS statistics
# 
# Description:
# This script merges 4 quarterly datasets from the Labor Force Survey (LFS) 2023
# conducted by Bangladesh Bureau of Statistics. Each quarter contains 4 modules:
# - Employment & Education
# - Migration
# - Disability (Roster)
# - Socioeconomic (Household-level)
#
# Output: Individual-level dataset with all 4 quarters combined (validated)
################################################################################

# ==============================================================================
# 1. SETUP
# ==============================================================================

# Load required packages
library(haven)      # For reading/writing Stata files
library(dplyr)      # For data manipulation
library(tidyr)      # For data reshaping

# Set working directory (adjust to your path)
 setwd("D://Datasets/LFS 2023 Microdata")

# Disable scientific notation for better readability
options(scipen = 999)

cat("\n")
cat(rep("=", 80), "\n")
cat("LFS 2023 INDIVIDUAL-LEVEL DATA MERGE\n")
cat(rep("=", 80), "\n\n")

# ==============================================================================
# 2. IMPORT QUARTERLY DATASETS
# ==============================================================================

cat("Step 1: Importing datasets...\n\n")

# Employment & Education (all 4 quarters)
cat("  Loading Employment & Education data...\n")
q1_emped <- read_dta("BBS_LFS_Q1_2023_Employment_Education.dta")
q2_emped <- read_dta("BBS_LFS_Q2_2023_Employment_Education.dta")
q3_emped <- read_dta("BBS_LFS_Q3_2023_Employment_Education.dta")
q4_emped <- read_dta("BBS_LFS_Q4_2023_Employment_Education.dta")

# Migration (all 4 quarters)
cat("  Loading Migration data...\n")
q1_mig <- read_dta("BBS_LFS_Q1_2023_Migration.dta")
q2_mig <- read_dta("BBS_LFS_Q2_2023_Migration.dta")
q3_mig <- read_dta("BBS_LFS_Q3_2023_Migration.dta")
q4_mig <- read_dta("BBS_LFS_Q4_2023_Migration.dta")

# Disability/Roster (all 4 quarters)
cat("  Loading Disability/Roster data...\n")
q1_disab <- read_dta("BBS_LFS_Q1_2023_Roster_Disability.dta")
q2_disab <- read_dta("BBS_LFS_Q2_2023_Roster_Disability.dta")
q3_disab <- read_dta("BBS_LFS_Q3_2023_Roster_Disability.dta")
q4_disab <- read_dta("BBS_LFS_Q4_2023_Roster_Disability.dta")

# Socioeconomic (all 4 quarters - household-level)
cat("  Loading Socioeconomic data...\n")
q1_socecon <- read_dta("BBS_LFS_Q1_2023_Socio_Economic.dta")
q2_socecon <- read_dta("BBS_LFS_Q2_2023_Socio_Economic.dta")
q3_socecon <- read_dta("BBS_LFS_Q3_2023_Socio_Economic.dta")
q4_socecon <- read_dta("BBS_LFS_Q4_2023_Socio_Economic.dta")

cat("\n  ✓ All datasets imported successfully\n\n")

# ==============================================================================
# 3. STACK QUARTERS (APPEND)
# ==============================================================================

cat("Step 2: Stacking quarters...\n\n")

# ------------------------------------------------------------------------------
# 3.1 Employment & Education
# ------------------------------------------------------------------------------

cat("  Stacking Employment & Education...\n")
emp_ed_all <- bind_rows(q1_emped, q2_emped, q3_emped, q4_emped)

# Create unique person ID: YEAR_QUARTER_PSU_EAUM_HHNO_PERSONLINE
emp_ed_all <- emp_ed_all %>%
  mutate(person_id = paste(YEAR, QUARTER, PSU, EAUM, HHNO, EMP_HRLN, sep="_"))

cat("    Total rows:", nrow(emp_ed_all), "\n")
cat("    Unique persons:", n_distinct(emp_ed_all$person_id), "\n")
cat("    By quarter: Q1=", sum(emp_ed_all$QUARTER==1),
    ", Q2=", sum(emp_ed_all$QUARTER==2),
    ", Q3=", sum(emp_ed_all$QUARTER==3),
    ", Q4=", sum(emp_ed_all$QUARTER==4), "\n\n")

# ------------------------------------------------------------------------------
# 3.2 Migration
# ------------------------------------------------------------------------------

cat("  Stacking Migration...\n")
mig_all <- bind_rows(q1_mig, q2_mig, q3_mig, q4_mig) %>%
  mutate(person_id = paste(YEAR, QUARTER, PSU, EAUM, HHNO, MGT_LN, sep="_"))

cat("    Total rows:", nrow(mig_all), "\n")
cat("    Unique persons:", n_distinct(mig_all$person_id), "\n\n")

# ------------------------------------------------------------------------------
# 3.3 Disability/Roster
# ------------------------------------------------------------------------------

cat("  Stacking Disability/Roster...\n")
disab_all <- bind_rows(q1_disab, q2_disab, q3_disab, q4_disab) %>%
  mutate(person_id = paste(YEAR, QUARTER, PSU, EAUM, HHNO, HR_LN, sep="_"))

cat("    Total rows:", nrow(disab_all), "\n")
cat("    Unique persons:", n_distinct(disab_all$person_id), "\n\n")

# ------------------------------------------------------------------------------
# 3.4 Socioeconomic (Household-level)
# ------------------------------------------------------------------------------

cat("  Stacking Socioeconomic (household-level)...\n")
socecon_all <- bind_rows(q1_socecon, q2_socecon, q3_socecon, q4_socecon) %>%
  mutate(hh_id = paste(YEAR, QUARTER, PSU, EAUM, HHNO, sep="_"))

cat("    Total rows:", nrow(socecon_all), "\n")
cat("    Unique households:", n_distinct(socecon_all$hh_id), "\n\n")

# ==============================================================================
# 4. MERGE MODULES
# ==============================================================================

cat("Step 3: Merging modules...\n\n")

# Start with Disability/Roster as base (contains all persons)
cat("  Base dataset: Disability/Roster\n")
master <- disab_all

# Merge Employment & Education
cat("  Merging Employment & Education...\n")
master <- master %>%
  left_join(emp_ed_all, by = "person_id", suffix = c("", "_emp"))

cat("    Rows after merge:", nrow(master), "\n")
cat("    Persons with employment data:", sum(!is.na(master$EMP_01)), "\n\n")

# Merge Migration
cat("  Merging Migration...\n")
master <- master %>%
  left_join(mig_all, by = "person_id", suffix = c("", "_mig"))

cat("    Rows after merge:", nrow(master), "\n")
cat("    Persons with migration data:", sum(!is.na(master$MGT_01A)), "\n\n")

# Create household ID and merge Socioeconomic
cat("  Merging Socioeconomic (household-level)...\n")
master <- master %>%
  mutate(hh_id = paste(YEAR, QUARTER, PSU, EAUM, HHNO, sep="_")) %>%
  left_join(socecon_all, by = "hh_id", suffix = c("", "_hh"))

cat("    Rows after merge:", nrow(master), "\n")
cat("    Persons with household data:", sum(!is.na(master$HI1)), "\n\n")

cat("  ✓ All modules merged successfully\n\n")

# ==============================================================================
# 5. CLEAN DUPLICATE COLUMNS
# ==============================================================================

cat("Step 4: Cleaning duplicate columns...\n\n")

# List duplicate columns created by merge
duplicate_cols <- grep("_emp$|_mig$|_hh$", names(master), value = TRUE)
cat("  Found", length(duplicate_cols), "duplicate columns\n")

# Define columns to drop (merge keys that were duplicated)
drop_cols <- c(
  # Duplicate merge keys from employment
  "YEAR_emp", "QUARTER_emp", "PSU_emp", "EAUM_emp", "HHNO_emp",
  # Duplicate merge keys from migration
  "YEAR_mig", "QUARTER_mig", "PSU_mig", "EAUM_mig", "HHNO_mig",
  # Duplicate merge keys from household
  "YEAR_hh", "QUARTER_hh", "PSU_hh", "EAUM_hh", "HHNO_hh",
  # Duplicate geographic/weight variables
  "RU_hh", "BBS_geo_hh", "BBSn_emp",
  # Duplicate quarterly weights from migration (keep from base)
  "wgt_2023q1_mig", "wgt_2023q2_mig", "wgt_2023q3_mig", "wgt_2023q4_mig"
)

# Remove duplicates
master_clean <- master %>%
  select(-any_of(drop_cols))

cat("  Columns before:", ncol(master), "\n")
cat("  Columns after: ", ncol(master_clean), "\n")
cat("  Dropped:       ", ncol(master) - ncol(master_clean), "\n\n")

cat("  ✓ Duplicate columns removed\n\n")

# ==============================================================================
# 6. QUALITY CHECKS
# ==============================================================================

cat("Step 5: Running quality checks...\n\n")

# Check 1: No duplicate persons
cat("  Check 1: Duplicate persons\n")
dup_check <- master_clean %>%
  group_by(person_id) %>%
  summarise(n = n(), .groups = "drop") %>%
  filter(n > 1)

if (nrow(dup_check) == 0) {
  cat("    Status: ✓ PASS - No duplicates\n\n")
} else {
  cat("    Status: ✗ FAIL - Found", nrow(dup_check), "duplicate persons\n\n")
}

# Check 2: All persons have base variables
cat("  Check 2: Base variables present\n")
key_vars <- c("YEAR", "QUARTER", "PSU", "EAUM", "HHNO", "HR_LN")
all_present <- all(key_vars %in% names(master_clean))
if (all_present) {
  cat("    Status: ✓ PASS - All key variables present\n\n")
} else {
  missing <- key_vars[!key_vars %in% names(master_clean)]
  cat("    Status: ✗ FAIL - Missing:", paste(missing, collapse = ", "), "\n\n")
}

# Check 3: Household repetition across quarters
cat("  Check 3: Household repetition across quarters\n")
hh_quarters <- master_clean %>%
  mutate(hh_base = paste(PSU, EAUM, HHNO, sep="_")) %>%
  group_by(hh_base) %>%
  summarise(n_quarters = n_distinct(QUARTER), .groups = "drop")

cat("    Households appearing in:\n")
cat("      1 quarter: ", sum(hh_quarters$n_quarters == 1), "\n")
cat("      2 quarters:", sum(hh_quarters$n_quarters == 2), "\n")
cat("      3 quarters:", sum(hh_quarters$n_quarters == 3), "\n")
cat("      4 quarters:", sum(hh_quarters$n_quarters == 4), "\n\n")

# ==============================================================================
# 7. VALIDATION AGAINST PUBLISHED STATISTICS
# ==============================================================================

cat(rep("=", 80), "\n")
cat("VALIDATION AGAINST PUBLISHED BBS LFS 2023 STATISTICS\n")
cat(rep("=", 80), "\n\n")

# Prepare data for validation
cat("Preparing data for validation...\n")

df_valid <- master_clean %>%
  filter(HR_04 >= 15) %>%  # Working age population
  mutate(
    # Assign quarter-specific weights
    weight = case_when(
      QUARTER == 1 ~ wgt_2023q1,
      QUARTER == 2 ~ wgt_2023q2,
      QUARTER == 3 ~ wgt_2023q3,
      QUARTER == 4 ~ wgt_2023q4,
      TRUE ~ NA_real_
    ),
    # Define youth (15-29 years)
    is_youth = (HR_04 >= 15 & HR_04 <= 29)
  ) %>%
  filter(!is.na(weight))  # Remove rows without valid weights

cat("  Working age population (15+):", format(nrow(df_valid), big.mark=","), "persons\n")
cat("  Youth population (15-29):    ", format(sum(df_valid$is_youth), big.mark=","), "persons\n\n")

# ------------------------------------------------------------------------------
# Validation 1: Youth Unemployment Rate (Table 4.5 - LFS 2023 Report)
# ------------------------------------------------------------------------------

cat("Validation 1: Youth Unemployment Rate (Ages 15-29)\n")
cat(rep("-", 80), "\n")

youth_unemp <- df_valid %>%
  filter(is_youth, BBS_lfs13 %in% c(1, 2)) %>%  # Youth in labor force only
  summarise(
    total_labor_force = sum(weight),
    unemployed = sum(weight[BBS_lfs13 == 2]),
    unemployment_rate = (unemployed / total_labor_force) * 100
  )

cat("  Calculated youth unemployment rate:", round(youth_unemp$unemployment_rate, 2), "%\n")
cat("  Published BBS rate (2023):         ", "7.2%\n")
cat("  Difference:                        ", 
    round(abs(youth_unemp$unemployment_rate - 7.2), 2), "pp\n")

# Check if match
youth_match <- abs(youth_unemp$unemployment_rate - 7.2) < 0.1
if (youth_match) {
  cat("  Status: ✓ PASS\n\n")
} else {
  cat("  Status: ⚠ WARNING\n\n")
}

# ------------------------------------------------------------------------------
# Validation 2: Youth Share of Total Unemployed
# ------------------------------------------------------------------------------

cat("Validation 2: Youth Share of Total Unemployed\n")
cat(rep("-", 80), "\n")

youth_share <- df_valid %>%
  filter(BBS_lfs13 == 2) %>%  # All unemployed persons
  summarise(
    total_unemployed = sum(weight),
    youth_unemployed = sum(weight[is_youth]),
    youth_percentage = (youth_unemployed / total_unemployed) * 100
  )

cat("  Calculated youth share:", round(youth_share$youth_percentage, 2), "%\n")
cat("  Published BBS share:   ", "78.9%\n")
cat("  Difference:            ", 
    round(abs(youth_share$youth_percentage - 78.9), 2), "pp\n")

# Check if match
share_match <- abs(youth_share$youth_percentage - 78.9) < 0.2
if (share_match) {
  cat("  Status: ✓ PASS\n\n")
} else {
  cat("  Status: ⚠ WARNING\n\n")
}

# ------------------------------------------------------------------------------
# Validation Summary Table
# ------------------------------------------------------------------------------

cat(rep("=", 80), "\n")
cat("VALIDATION SUMMARY\n")
cat(rep("=", 80), "\n\n")

validation_summary <- data.frame(
  Indicator = c(
    "Youth unemployment rate (%)",
    "Youth share of unemployed (%)"
  ),
  Calculated = c(
    round(youth_unemp$unemployment_rate, 2),
    round(youth_share$youth_percentage, 2)
  ),
  Published = c(7.2, 78.9),
  Difference = c(
    round(youth_unemp$unemployment_rate - 7.2, 2),
    round(youth_share$youth_percentage - 78.9, 2)
  ),
  Status = c(
    ifelse(youth_match, "✓ PASS", "⚠ WARNING"),
    ifelse(share_match, "✓ PASS", "⚠ WARNING")
  )
)

print(validation_summary)
cat("\n")

# Overall validation status
if (youth_match & share_match) {
  cat("Overall Assessment: ✓ EXCELLENT - All validations passed\n")
  cat("Dataset matches published LFS 2023 Report statistics\n\n")
} else {
  cat("Overall Assessment: ⚠ Review - Some validations need attention\n\n")
}

# ==============================================================================
# 8. SAVE MERGED DATASET
# ==============================================================================

cat(rep("=", 80), "\n")
cat("SAVING MERGED DATASET\n")
cat(rep("=", 80), "\n\n")

# Save in multiple formats

# R format (preserves labels and attributes)
saveRDS(master_clean, "LFS_2023_Master_AllPersons.rds")
cat("  ✓ Saved: LFS_2023_Master_AllPersons.rds\n")

# Stata format
write_dta(master_clean, "LFS_2023_Master_AllPersons.dta")
cat("  ✓ Saved: LFS_2023_Master_AllPersons.dta\n")

# CSV format (for Excel/other software)
write.csv(master_clean, "LFS_2023_Master_AllPersons.csv", row.names = FALSE)
cat("  ✓ Saved: LFS_2023_Master_AllPersons.csv\n\n")

# ==============================================================================
# 9. SUMMARY
# ==============================================================================

cat(rep("=", 80), "\n")
cat("MERGE COMPLETE\n")
cat(rep("=", 80), "\n\n")

cat("FINAL DATASET SUMMARY:\n")
cat("  Rows (persons):      ", format(nrow(master_clean), big.mark=","), "\n")
cat("  Columns (variables): ", ncol(master_clean), "\n")
cat("  Unique households:   ", format(n_distinct(master_clean$hh_id), big.mark=","), "\n\n")

cat("MODULES MERGED:\n")
cat("  1. Disability/Roster (base) - All persons\n")
cat("  2. Employment & Education   - Labor force characteristics\n")
cat("  3. Migration                - Migration history\n")
cat("  4. Socioeconomic            - Household characteristics\n\n")

cat("PERSON ID STRUCTURE:\n")
cat("  Format: YEAR_QUARTER_PSU_EAUM_HHNO_PERSONLINE\n")
cat("  Example: 2023_1_001_01_0001_01\n\n")

cat("VALIDATION STATUS:\n")
cat("  Youth unemployment rate:   ", ifelse(youth_match, "✓ PASS", "⚠ WARNING"), "\n")
cat("  Youth share of unemployed: ", ifelse(share_match, "✓ PASS", "⚠ WARNING"), "\n\n")

cat("NOTES:\n")
cat("  • Left join used (preserves all persons from roster)\n")
cat("  • Missing values (NA) indicate person/household did not have that data\n")
cat("  • Different modules use different person line variables:\n")
cat("    - Disability: HR_LN\n")
cat("    - Employment: EMP_HRLN\n")
cat("    - Migration: MGT_LN\n")
cat("  • Socioeconomic is household-level (no person line)\n")
cat("  • Use quarter-specific weights (wgt_2023q1, wgt_2023q2, etc.)\n\n")

cat("FILES CREATED:\n")
cat("  1. LFS_2023_Master_AllPersons.rds  (R format - recommended)\n")
cat("  2. LFS_2023_Master_AllPersons.dta  (Stata format)\n")
cat("  3. LFS_2023_Master_AllPersons.csv  (CSV format)\n\n")

cat(rep("=", 80), "\n")
cat("Ready for analysis!\n")
cat(rep("=", 80), "\n\n")

################################################################################
# END OF SCRIPT
################################################################################