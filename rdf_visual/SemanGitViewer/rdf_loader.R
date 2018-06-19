library(subprocess)
library(SPARQL)
library(stringr)
source('config.R')


#--------------------------------------
#           Helper Functions
#-------------------------------------
is_triple<-function(x){
  return(str_detect(x[1],"http:"))
}

object_is_subject <- function(x){
  return(str_detect(x[3],"http://www.dennis_stinkt_krass.pizza"))
  #!str_detect(x[2],"type")
}  

convert_to_nt <- function(x){
  if(str_detect(x,"http:")){
    x <- paste0("<",x,">")
  }
  return(x)
}

append_to_subject <- function(x){
  x <- paste0(x," ?"," ? \n")
}

wait_for_start<-function(handle)
{
  check = FALSE
  while(!check)
  {
    Sys.sleep(0.5)
    test = process_read(handle,PIPE_STDOUT)
    if(length(test)!=0){
      check = test[length(test)] == ">> "
    }
  }
}

ask_api <- function(handle,query){
  transformed = NULL
  check = FALSE
  process_write(handle, query)
  while(check == FALSE)
  {
    Sys.sleep(1)
    test = process_read(handle,PIPE_STDOUT)
    transformed = c(transformed,str_split(test, " ", 3))
    check = transformed[[length(transformed)]][1]==">>"
  }
  transformed = transformed[unlist(lapply(transformed,is_triple))]
  return(transformed)
}
#--------------------------------------
#           Programm
#-------------------------------------
bfs_on_hdt <- function(depth,query,data){
  handle <- spawn_process(paste0(hdt_path,'/hdt-java-cli/bin/hdtSearch.sh'), data, workdir = paste0(hdt_path,'/hdt-java-cli/'))
  transformed_total <- c("")
  queries<-c(query)
  old_queries<-c(query)
  wait_for_start(handle)
  for(i in 1:depth){
    new_queries<-c()
    if(length(queries)==0){
      break
    }
    for(j in 1:length(queries)){
      transformed = ask_api(handle, queries[j])
      if(i == 1){
        transformed_total<-c(transformed)
      }
      else{
        transformed_total<-c(transformed_total,transformed)
      }
      containing_new_subjects = transformed[unlist(lapply(transformed,object_is_subject))]
      new_subjects = unlist(containing_new_subjects)[c(FALSE, FALSE, TRUE)]
      new_subjects = lapply(new_subjects, append_to_subject)
      new_queries <- c(new_queries,new_subjects)
    }
    new_queries <- new_queries[!new_queries %in% old_queries]
    old_queries <- c(old_queries, new_queries)
    queries <- new_queries
  }
  df <- do.call(rbind.data.frame,transformed_total)
  df<- lapply(df,convert_to_nt)
  col_headings <- c('subject','predicate','object')
  names(df) <- col_headings
  return(df)
}



