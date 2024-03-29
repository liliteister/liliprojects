
library(shiny)
library(shinythemes)
library(dplyr)
library(ggplot2)
library(highcharter)
library(glue)


####################################################
# prepare data 


expd_filepath <- "Everest_Peak_Expeditions_Report_1980-2019.csv"
expeditions <- read.csv(paste("clean_data/", expd_filepath, sep = "")) 

years <- as.data.frame(c(1980:2019))
names(years) <- "Year"

expd_by_year <- years %>%
  left_join(
    expeditions %>%
      group_by(Year, Result_group) %>%
      summarize(Summiters = sum(Summiters),
                Deaths = sum(Deaths),
                Expeditions = n(),
                Total_Climbers = sum(Summiters) + sum(Deaths)),
    by = "Year"
  ) 


mbr_filepath <- "Everest_Total_Membership_1980-2019.csv"
members <- read.csv(paste("clean_data/", mbr_filepath, sep = "")) 


mbr_summ <- members %>%
    group_by(Citizenship) %>%
    summarise(Summiters_wHired = Mbrs_Succ_F + Mbrs_Succ_M + Hired_Succ,
              Deaths_wHired = Mbrs_Dead_F + Mbrs_Dead_M + Hired_Dead,
              Summiters_woHired = Mbrs_Succ_F + Mbrs_Succ_M,
              Deaths_woHired = Mbrs_Dead_F + Mbrs_Dead_M
    )


Nepalese_hired_pcnt_asc <- round(sum(members$Hired_Succ[members$Citizenship == "Nepal"]) / 
  sum(members$Mbrs_Succ_M + members$Mbrs_Succ_F + members$Hired_Succ),
  2) * 100


Nepalese_hired_pcnt_dead <- round(sum(members$Hired_Dead[members$Citizenship == "Nepal"]) / 
                               sum(members$Mbrs_Dead_M + members$Mbrs_Dead_F + members$Hired_Dead),
                             2) * 100

ascent_filepath <- "Everest_Peak_Ascent_Report_1980-2019.csv"
ascents <- read.csv(paste("clean_data/", ascent_filepath, sep = ""))

ascent_sex <- ascents %>%
  group_by(Year, Sex) %>%
  summarise(Climbers= n())

Female_ascent_pcnt <- round(sum(ascent_sex$Climbers[ascent_sex$Sex == "F"]) / sum(ascent_sex$Climbers),
                            2) * 100

ascent_age <- ascents %>%
  mutate(AgeGroup = case_when(
    Age <= 30 ~ "30 and Under",
    Age <= 45 ~ "31 to 45",
    Age <= 65 ~ "46 to 65",
    TRUE ~ "Over 65"
  )) %>%
  group_by(Year, AgeGroup) %>%
  summarise(Climbers= n())

deaths_filepath <- "Everest_Peak_Deaths_Report_1980-2019.csv"
deaths <- read.csv(paste("clean_data/", deaths_filepath, sep = ""))

deaths_oxy <- deaths %>%
  group_by(Year, Oxy) %>%
  summarise(Deaths = n())

################################# UI
ui <- fluidPage(theme = shinytheme("yeti"),
               
    navbarPage(title =
                 div(
                   img(
                     src = "mountain.png",
                     height = 25,
                     width = 25
                   ),
                   " Everest Expeditions"
                 ),
               
    tabPanel("Home",
      sidebarLayout(
        sidebarPanel(
          position = "top",
          h5(strong("Expeditions to summit Mt Everest have risen dramatically in recent years.")),
          h5("Large, commercial expeditions have been popularized, as international climbers and tourists seek the adventure and achievement conquering the world's most famous peak."),
          h5("This project explores the Himalayan Databases's expedition and climber data in recent decades.")
          ),
        mainPanel(
          tabsetPanel(
            type = "tabs",
            tabPanel("Expeditions",
                     highchartOutput("expd_plot",
                                     width = "100%",
                                     height = "100%"),
                     h6(em("*An avalanche resulting from the 2015 earthquake in Nepal put a halt to that climbing season.")),
                     br(),
                     h4("Expeditions to Mt Everest's peak have been attempted since 1921, long before the first successful summit by Edmund Hillary in 1953, and become more popular since, particularly since the 1980s. "),
                     h4("Now, hundreds of climbers attempt each season, raising concern about maintaining a safe and balanced environment.")
            ),
            tabPanel("Ascents",
                     checkboxInput("include_hired_asc", label = "Include Hired Climbers", value = FALSE),
                     highchartOutput("ascents",
                                     width = "100%",
                                     height = "600px"),
                     h4(paste("Climbers hail from all over the world, but they require the assistance of local sherpas to assist with gear, routes, and even carrying climbers up or down the mountain. ",
                              glue("Since 1980, {Nepalese_hired_pcnt_asc}% of summits were by Nepalese climbers hired to assist an expedition."))),
                     h4("Many sherpas are ethnic Nepali Sherpa, who have origins in Tibet and reside in the Himalayan region of Nepal. They have been vital to the success of recreational mountaineering in the Himalayas since it began."),
                     br(),
                     highchartOutput("ascents_sex",
                                     width = "50%"),
                     h4(glue("While only {Female_ascent_pcnt}% of summits have been by women, the share of female mountaineers is increasing.")),
                     br(),
                     highchartOutput("ascents_age",
                                     width = "50%"),
                     h4("Advancing technology and preparation has allowed a variety of climbers to be successful."),
                     br(),
                     br()
            ),
            tabPanel("Deaths",
                     checkboxInput("include_hired_deaths", label = "Include Hired Climbers", value = FALSE),
                     highchartOutput("deaths",
                                     width = "100%",
                                     height = "600px"),
                     h4("Attempting to summit Everest remains a dangerous endeavor."),
                     br(),
                     highchartOutput("deaths_oxy",
                                     width = "50%"),
                     h4("Summitting without summplemental oxygen has increasingly been attempted since the first summit without it in 1978."),
                     br(),
                     br()
            )
          )
        )
      )
      ),
    tabPanel("Info",
             h4("Resources"),
             p('"Peak Ascents Report", The Himalayan Database. The Himalayan Database: A Non-Profit Organization. Updated July 2020. https://www.himalayandatabase.com/Online/peaksmtr.html'),
             p('"Peak Deaths Report", The Himalayan Database. The Himalayan Database: A Non-Profit Organization. Updated July 2020. https://www.himalayandatabase.com/Online/peakdead.html'),
             p('"Peak Expeditions Report", The Himalayan Database. The Himalayan Database: A Non-Profit Organization. Updated July 2020. https://www.himalayandatabase.com/Online/peakexp.html'),
             p('"Peak Member Statistial Summary", The Himalayan Database. The Himalayan Database: A Non-Profit Organization. Updated July 2020. https://www.himalayandatabase.com/Online/peakmstat.html'),
             p("O'Grady, Siobhan. 'Mount Everest has gotten so crowded that climbers are perishing in the traffic jams.' The Washington Post. May 25, 2019. https://www.washingtonpost.com/world/2019/05/24/mount-everest-has-gotten-so-crowded-that-climbers-are-perishing-traffic-jams/"),
             p("The Editors of Encyclopaedia Britannica. 'Sherpa.' Encyclopædia Britannica. Encyclopædia Britannica, inc. September 12, 2019. https://www.britannica.com/topic/Sherpa-people"),
             p("(Henry Cecil) John Hunt, Wilfrid Noyce and Others. 'Mount Everest: Extraordinary Feats.' Encyclopædia Britannica. Encyclopædia Britannica, inc. April 09, 2020. https://www.britannica.com/place/Mount-Everest/Extraordinary-feats"))
    
  )
)



############################## Server

server <- function(input, output, session){
  
  data(worldgeojson, package = "highcharter")
  
  output$expd_plot <- renderHighchart({
    expd_by_year %>%
      hchart(
        'column', hcaes(x = Year, y = Expeditions, group = Result_group),
        stacking = 'normal'
      ) %>%
      hc_title(text = "Everest Expeditions by Year, Result") %>%
      hc_subtitle(text = "1980 to 2019") %>%
      hc_colors(c(
        "#990033",
        "#003366",
        "#336666",
        "#996633",
        "#CC6633",
        "#CC6699",
        "#CC66FF",
        "#99FF00",
        "#0000CC",
        "#009900",
        "#999999")
      ) %>%
      hc_yAxis(max = 125) %>%
      hc_legend(align = "right",
                verticalAlign = "middle",
                layout = "vertical")
  })
    
  
  hired_asc <- reactive(input$include_hired_asc)
  
    output$ascents <- renderHighchart({
      
      if(input$include_hired_asc){
        highchart() %>%
          hc_add_series_map(
            worldgeojson, mbr_summ, value = "Summiters_wHired", joinBy = c('name','Citizenship'),
            name = "Successful Summits"
          )  %>% 
          hc_colorAxis(min = 0, max = (
            max(mbr_summ$Summiters_wHired)
          ),
          stops = color_stops()) %>% 
          hc_subtitle(text = "1980 to 2019") %>% 
          hc_title(text = "Everest Summits by Citizenship")
      } else {
        highchart() %>%
          hc_add_series_map(
            worldgeojson, mbr_summ, value = "Summiters_woHired", joinBy = c('name','Citizenship'),
            name = "Successful Summits"
          )  %>% 
          hc_colorAxis(min = 0, max = (
            max(mbr_summ$Summiters_woHired)
          ),
          stops = color_stops()) %>% 
          hc_subtitle(text = "1980 to 2019") %>% 
          hc_title(text = "Everest Summits by Citizenship")
      }
      
    })
    
    output$ascents_sex <- renderHighchart({
      ascent_sex %>%
        hchart(
          'column', hcaes(x = Year, y = Climbers, group = Sex),
          stacking = 'normal'
        ) %>%
        hc_title(text = "Everest Ascents by Year, Sex") %>%
        hc_subtitle(text = "1980 to 2019, All Climbers") %>%
        hc_colors(c(
          "#F5B041",
          "#5DADE2")
        )
        
    })
    
    output$ascents_age <- renderHighchart({
      ascent_age %>%
        hchart(
          'column', hcaes(x = Year, y = Climbers, group = AgeGroup),
          stacking = 'normal'
        ) %>%
        hc_title(text = "Everest Ascents by Year, Age Group") %>%
        hc_subtitle(text = "1980 to 2019, All Climbers")
    })
    
    hired_deaths <- reactive(input$include_hired_deaths)
    
    output$deaths <- renderHighchart({
      
      if(input$include_hired_deaths){
        highchart() %>%
          hc_add_series_map(
            worldgeojson, mbr_summ, value = "Deaths_wHired", joinBy = c('name','Citizenship'),
            name = "Deaths"
          )  %>% 
          hc_colorAxis(min = 0, max = (
            max(mbr_summ$Deaths_wHired)
          ),
          stops = color_stops()) %>% 
          hc_subtitle(text = "1980 to 2019") %>% 
          hc_title(text = "Everest Deaths by Citizenship") 
      } else {
        highchart() %>%
          hc_add_series_map(
            worldgeojson, mbr_summ, value = "Deaths_woHired", joinBy = c('name','Citizenship'),
            name = "Deaths"
          )  %>% 
          hc_colorAxis(min = 0, max = (
            max(mbr_summ$Deaths_woHired)
          ),
          stops = color_stops()) %>% 
          hc_subtitle(text = "1980 to 2019") %>% 
          hc_title(text = "Everest Deaths by Citizenship") 
      }
      
    })
    
    output$deaths_oxy <- renderHighchart({
      deaths_oxy %>%
        hchart(
          'column', hcaes(x = Year, y = Deaths, group = Oxy),
          stacking = 'normal'
        ) %>%
        hc_title(text = "Everest Deaths by Year, Use of Oxygen") %>%
        hc_subtitle(text = "1980 to 2019, All Climbers") %>%
        hc_colors(c(
          "#C0392B",
          "#76D7C4")
        )
    })

}


###########
shinyApp(ui = ui, server = server)
###########

