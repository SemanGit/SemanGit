#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
source('rdf_loader.R')
library(shiny)
library(redland)
library(SPARQL)

# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel("Semangit"),
   

   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
         textInput("uri", "Search for URI", "http://www.dennis_stinkt_krass.pizza#ghuser_10"),
        
         sliderInput("d",
                     "Depth:",
                     min = 1,
                     max = 10,
                     value = 1),
         
         actionButton("btn1", "Generate RDF"),
         textOutput("loading")
         
         
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
         plotOutput("plot1"),
         downloadButton("downloadData", "Download")      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  x <- NULL
  output$loading = renderText("Ready")
  observeEvent(input$btn1, {
    output$loading <- renderText("Calculating")
    x <- NULL
    x <- bfs_on_hdt(input$d, append_to_subject(input$uri), data3 )
    output$loading <- renderText("Finished")
    output$downloadData <- downloadHandler(
      filename = function() {
        paste(input$uri,"_",input$d, ".nt", sep = "")
      },
      content = function(file) {
        write.table(x, file, row.names=FALSE, quote=FALSE, col.names = FALSE)
      }
    )
    df<-data.frame(table(x$subject.predicate))
    df<-aggregate(predicate ~ subject, data = x, FUN = function(x){NROW(x)})
    df<-df[order(df$predicate),]
    colfunc <- colorRampPalette(c("cyan","green","yellow"))
    output$plot1 <- renderPlot({
      barplot(df$predicate, names=df$subject, col = colfunc(nrow(df)))
    })
  }
  )


}

# Run the application 
shinyApp(ui = ui, server = server)

