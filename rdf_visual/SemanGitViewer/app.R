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
         textInput("uri", "Search for URI", "_:660800c2a774d50f86560ec1999b3eae"),
        
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
    df<-aggregate(subject ~ obj + predicate, data = x, FUN = function(x){NROW(x)})
    colfunc1 <- colorRampPalette(c("cyan","red"))
    df1<-df[df$predicate=="<http://www.sg.com/ont/github_organization_joined_by>",]
    output$plot1 <- renderPlot({
      barplot(df1$subject, col = colfunc1(nrow(df1)), xlab="Users", ylab="joined")
    })
    df2<-df[df$predicate=="<http://www.sg.com/ont/github_organization_is_joined>",]
    colfunc2 <- colorRampPalette(c("red","green"))
    output$plot2 <- renderPlot({
      barplot(df2$subject, col = colfunc2(nrow(df2)), xlab="Organization", ylab="was joint by")
    })
    }
  )


}
#_:0af737b52053569d48e74b39a31a1383
#_:0afa2703a06b32e69c8ed0c686f2fb25
# Run the application 
shinyApp(ui = ui, server = server)

