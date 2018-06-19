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
         textInput("uri", "Search for URI", "_:fe1e3161bd5b71df9a66ad865d9749d2"),
        
         sliderInput("d",
                     "Depth:",
                     min = 1,
                     max = 10,
                     value = 1),
         
         actionButton("btn1", "Generate RDF"),
         textOutput("loading"),
         downloadButton("downloadData", "Download") 
         
         
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
         plotOutput("plot1"),
         plotOutput("plot2")

     )
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
    df2<-df[str_detect(df$predicate,"is_joined")]
    df2<-aggregate(subject ~ object, data = x, FUN = function(x){NROW(x)})
    df2<-df[order(df$subject),]
    df2<-df[1:60,]
    colfunc1 <- colorRampPalette(c("cyan","yellow"))
    output$plot1 <- renderPlot({
      barplot(df2$subject, col = colfunc1(nrow(df)))
    })
    colfunc2 <- colorRampPalette(c("green","yellow"))
    output$plot2 <- renderPlot({
      barplot(df2$subject, col = colfunc2(nrow(df)))
    })
    }
  )


}

# Run the application 
shinyApp(ui = ui, server = server)

