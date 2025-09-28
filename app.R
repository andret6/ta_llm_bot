# Local Key loading
#Sys.setenv(
#  OPENAI_API_KEY = trimws(readLines("C:/Users/12064/Documents/keys/open_ai_s_key.txt"))
#)
# Ensure API key is loaded, define embed model
key <- Sys.getenv("OPENAI_API_KEY")
if (identical(key, "") ) stop("OPENAI_API_KEY not set on server")
Sys.setenv(OPENAI_API_KEY = key)
EMBED_MODEL <- "text-embedding-3-small"  # low-cost, solid quality
library(shiny)
library(ellmer)
library(shinychat)
library(tidyverse)
library(httr2)
source('mood_based_responses.R') # Helper functions and logic for 


# Define UI
ui <- fluidPage(
  tags$div(
    tags$img(
      src = "not_unsw_logo.png",  # place the PNG in www/ folder
      style = "
        position: absolute;
        top: 10px; 
        right: 10px; 
        width: 120px;
        z-index: 1000;
      "
    )
  ),
  
  titlePanel("Teaching Assistant Bot"),
  
  # Main layout
  fluidRow(
    # Left column with description text
    column(
      width = 3,
      wellPanel(
        h4("About this app"),
        p("This teaching assistant bot is designed to help with 
           introductory courses in R, Python, SQL, and Statistics 
           for Non-Statisticians."),
        p("It will guide you by asking clarifying questions, 
           providing simple explanations, and referring to additional sources when possible.")
      )
    ),
    
    # Right column with chat window
    column(
      width = 9,
      shinychat::chat_mod_ui(id = "bot")
    )
  ),
  
  # Footer disclaimer at the bottom
  tags$hr(),
  tags$footer(
    style = "text-align:center; font-size: 0.8em; color: gray; padding: 10px;",
    "Disclaimer: This bot is for educational purposes only and should not 
    be relied upon for professional or legal advice. This bot uses OpenAI chat gpt models
    for chat completion and is not an official product of UNSW."
  )
)

# Server logic 
server <- function(input, output, session) {
  # Define your agent/persona via a system prompt
  chat <- chat_openai(
    system_prompt = "You are a teaching assistant for the following courses: intro to R, intro to Python, intro to SQL, and statistics for non stasticians.
    Give answers in the following way:
     - If a user asks you about working directory or installation of R, or other software questions, do not ask prompting follow up questions but rather try to resolve
      as helpfully and gently as possible
     - For coding and stats questions, start by prompting users to think about their questions and ask follow up questions.
     - If users still struggle to get an answer, or clearly seem frustrated, start to give partial answers, and then eventually give full answers.
     - Keep responses simple in language and explanation, but do use math and give formulas if prompted to do so.
     - cite sources when possible
    ",
    model = "gpt-4o-mini",
    echo = "none"
  )
  
  shinychat::chat_mod_server(
    id = "bot",
    client = chat
  )
}

# Launch app
shinyApp(ui, server)