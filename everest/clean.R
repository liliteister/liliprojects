
# clean.R
# Input: raw report data
# Output: clean data for app

library(dplyr)
setwd("everest")

# expeditions-------------------------------------------------------------
expd_filepath <- "Everest_Peak_Expeditions_Report_1980-2019.csv"

expeditions <- read.csv(paste("raw_data/", expd_filepath, sep = "")) %>%
  mutate(Year = as.integer(substr(Yr.Seas, 1, 5)),
         Result_group = case_when(
           Result %in% c("Bad Conditions","Bad Weather") 
            ~ "Bad Conditions/Weather",
           grepl("Success", Result) 
            ~ "Success",
           TRUE ~ Result)
  )

expeditions$Smtrs[is.na(expeditions$Smtrs)] <- 0
expeditions$Dead[is.na(expeditions$Dead)] <- 0

names(expeditions) <- c(
  "Season",
  "Host",
  "Nationalities",
  "Leader",
  "Route",
  "Result",
  "Summiters",
  "Deaths",
  "ExpeditionID",
  "Year",
  "Result_group"
)

write.csv(expeditions,
  paste("clean_data/", expd_filepath, sep = ""),
  row.names = FALSE
)

#ascents-----------------------------------------------------------

summ_filepath <- "Everest_Peak_Ascent_Report_1980-2019.csv"

ascents <- read.csv(paste("raw_data/", summ_filepath, sep = "")) %>%
  mutate(
    Year = as.integer(substr(Yr.Seas, 1, 5)),
    Oxy = as.logical(
      case_when(
        Oxy == "Y" ~ 1,
        TRUE ~ 0
      )
    ),
    Dth = as.logical(
      case_when(
        Dth == "Y" ~ 1,
        TRUE ~ 0
      )
    )
  ) %>%
  rename(Season = `Yr.Seas`) 
  

#separate out dual-citizenship people
dual_citizens <- ascents[grepl("/", ascents$Citizenship),]

#remove the second country from dual citizens in first dataset
ascents$Citizenship <-  gsub("/..*", "", ascents$Citizenship)

#remove the first country from the dual citizens parsed out
dual_citizens$Citizenship <- gsub("..*/", "", dual_citizens$Citizenship)

ascents <- rbind(
  ascents,
  dual_citizens
) %>%
  mutate( # rename countries to align with highcharter worldgeojson
    Citizenship = case_when(
      Citizenship == "USA" ~ "United States of America",
      TRUE ~ Citizenship
    )
  ) %>%
  arrange(Year, Name)
  


write.csv(ascents,
          paste("clean_data/", summ_filepath, sep = ""),
          row.names = FALSE
)




#deaths -----------------------------------------------------------
death_filepath <- "Everest_Peak_Deaths_Report_1980-2019.csv"

deaths <- read.csv(paste("raw_data/", death_filepath, sep = "")) %>%
  mutate(
    Year = as.integer(substr(Yr.Seas, 1, 5)),
    Oxy = as.logical(
      case_when(
        Oxy == "Y" ~ 1,
        TRUE ~ 0
      )
    ),
    Smt = as.logical(
      case_when(
        Smt == "Y" ~ 1,
        TRUE ~ 0
      )
    )
  ) %>%
  rename(Season = `Yr.Seas`) 

#separate out dual-citizenship people
dual_citizens <- deaths[grepl("/", deaths$Citizenship),]

deaths$Citizenship <-  gsub("/..*", "", deaths$Citizenship)

dual_citizens$Citizenship <- gsub("..*/", "", dual_citizens$Citizenship)

deaths <- rbind(
  deaths,
  dual_citizens
) %>%
  mutate( 
    Citizenship = case_when(
      Citizenship == "USA" ~ "United States of America",
      TRUE ~ Citizenship
    )
  ) %>%
  arrange(Year, Name)

write.csv(deaths,
          paste("clean_data/", death_filepath, sep = ""),
          row.names = FALSE
)


#--------------------------------------------
# the membership summary separates out hired members, which the member-level reports do not identify

members_filepath <- "Everest_Total_Membership_1980-2019.csv"

membership <- read.csv(paste("raw_data/", members_filepath, sep = ""))

# separate out dual-citizens to count for both countries
dual_citizens <- membership[grepl("/", membership$Citizenship),]

membership$Citizenship <-  gsub("/..*", "", membership$Citizenship)

dual_citizens$Citizenship <- gsub("..*/", "", dual_citizens$Citizenship)

membership <- rbind(
  membership,
  dual_citizens
) %>%
  mutate( 
    Citizenship = case_when(
      Citizenship == "USA" ~ "United States of America",
      TRUE ~ Citizenship
    )
  ) %>%
  group_by(Citizenship) %>%
  summarise(
    Total_Mbrs_M = sum(`Total.Mbrs..M.`),
    Total_Mbrs_F = sum(`Total.Mbrs..F.`),
    Mbrs_Abv_BC_M = sum(`Mbrs.Abv.BC..M.`),
    Mbrs_Abv_BC_F = sum(`Mbrs.Abv.BC..F.`),
    Mbrs_Succ_M = sum(`Mbrs.Succ..M.`),
    Mbrs_Succ_F = sum(`Mbrs.Succ..F.`),
    Hired_Succ = sum(`Hired.Succ`),
    Mbrs_Dead_M = sum(`Mbrs.Dead..M.`),
    Mbrs_Dead_F = sum(`Mbrs.Dead..F.`),
    Hired_Dead = sum(`Hired.Dead`)
  ) %>%
  filter(Citizenship != "Totals")


write.csv(membership,
          paste("clean_data/", members_filepath, sep = ""),
          row.names = FALSE
)
