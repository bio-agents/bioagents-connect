## Script to import the content of ms-utils.org into bio.agents
##
## Update: Adapted to bio.agents schema 2.0
## Not working: head of xml-file still requires substitution of "xmlns:xmlns" to "xmlns"


library(biocViews)
library(igraph)
library(XML)
library(stringr)
library(ontologyIndex)
# get_OWL got depreciated, therefore load function from version 2.2
# library(ontoCAT)

setwd("/home/veit/devel/Proteomics/IECHOR_EDAM/DataRetrieval")
source("ontologyIndex_get_OWL.R")

############### get recent EDAM ontology for mapping of terms
system("rm EDAM.owl")
system("wget http://edamontology.org/EDAM.owl")
EDAM <- get_OWL("EDAM.owl")

## Remove obsolete terms
FullEDAM <- EDAM
EDAM$id <- EDAM$id[!EDAM$obsolete]
EDAM$name <- EDAM$name[!EDAM$obsolete]
EDAM$parents <- EDAM$parents[!EDAM$obsolete]
EDAM$children <- EDAM$children[!EDAM$obsolete]
EDAM$ancestors <- EDAM$ancestors[!EDAM$obsolete]
EDAM$obsolete <- EDAM$obsolete[!EDAM$obsolete]


############### DATA MSUTILS.ORG -> IECHOR REGISTRY
# get data
system("wget http://www.ms-utils.org/wiki/pmwiki.php/Main/SoftwareList?action=source -O msutils.txt")
system("sed -i 's/||/@/g' msutils.txt")
msutils <- read.csv("msutils.txt",sep="@",skip=1,row.names=NULL,stringsAsFactors = F,quote="")
tempstr <- NA
for (i in 1:nrow(msutils)) {
  if(length(grep("[++",msutils[i,2],fixed = T))>0) {
    tempstr <- gsub("+","",gsub("]","",gsub("[","",as.character(msutils[i,2]),fixed=T),fixed=T),fixed=T)
  }
  msutils[i,1] <- tempstr
}
msutils <- msutils[msutils[,3]!="",]
colnames(msutils) <- c("Category","link","description","lang","interface","name","Email")

msutils$name <- sapply(msutils[,2],function(x) gsub("\\]","",strsplit(x,"\\|")[[1]][2]))
msutils$link <- sapply(msutils[,2],function(x) gsub("\\[","",strsplit(x,"\\|")[[1]][1]))
#msutils$name <- unlist(...)
msutils$source <- msutils$paper <- msutils$weblink <- msutils$email <- NA
for (i in 1:nrow(msutils)) {
  ttt <- msutils$lang[i]
  msutils$source[i] <- msutils$lang[i] <- NA
  if (length(grep("\\[",ttt))>0) {
    msutils$source[i] <- gsub("\\[","",strsplit(ttt,"\\|")[[1]][1])
    msutils$lang[i] <- gsub("\\]","",strsplit(ttt,"\\|")[[1]][2])
  } else if (nchar(gsub(" ","",ttt))>0) {
    msutils$lang[i] <- ttt
  }
  ttt <- msutils$interface[i]
  msutils$weblink[i] <- msutils$interface[i] <- NA
  if (length(grep("\\[",ttt))>0) {
    msutils$weblink[i] <- gsub("\\[","",strsplit(ttt,"\\|")[[1]][1])
    msutils$interface[i] <- gsub("\\]","",strsplit(ttt,"\\|")[[1]][2])
  } else  if (nchar(gsub(" ","",ttt))>0) {
    msutils$interface[i] <- ttt
  }
  ttt <- msutils$description[i]
  msutils$paper[i] <- NA
  if (length(grep("\\[",ttt))>0) {
    if (length(grep("pubmed",ttt))>0) {
      tpaper <-  regmatches(ttt,gregexpr("www[a-z,\\.]*/pubmed/[0-9]*",ttt))
      # multiple entries are separated by "|"
      msutils$paper[i] <- paste(grep("[0-9]",unlist(lapply(tpaper,function(x) strsplit(x,"pubmed/"))),value=T),collapse="|")
    } else if (length(grep("dx\\.doi",ttt))>0) {
      tpaper <-  regmatches(ttt,gregexpr("dx\\.doi[a-z,\\.]*/[0-9\\.]*/[0-9,a-z,A-Z,\\.]*",ttt))[[1]]
      tpaper <- strsplit(tpaper,"/")
      msutils$paper[i] <- tpaper[[1]][length(tpaper[[1]])]
    }
    
    msutils$description[i] <- gsub("\\#","",gsub("\\]\\]","",gsub("\\[\\[[a-z,0-9,\\.,\\/,\\:,\\#,\\A-Z]*\\|","",ttt)))
  }
}

write.csv(msutils,"msutils.csv")

############# temporary solution to read from csv-file
msutils <- read.csv("msutils_with_EDAM - msutils_agents - temporary solution.csv", stringsAsFactors = F)

msutils$interface[msutils$interface == "offline"] <- NA
msutils$description[msutils$description == ""] <- NA
msutils$email[msutils$email == ""] <- NA

############# Visualize EDAM terms
topics <- strsplit(msutils$EDAM.topic.1,"\\|")
topics <-  lapply(topics,function(x) {sub(" ","",x); x})
operations <- strsplit(msutils$EDAM.operation.1,"\\|")
operations <-  lapply(operations,function(x) {sub(" ","",x); FullEDAM$name[paste("http://edamontology.org/",x,sep="")]})
data_in <- strsplit(msutils$EDAM.data.in,"\\|")
data_in <-  lapply(data_in,function(x) {sub(" ","",x); FullEDAM$name[paste("http://edamontology.org/",x,sep="")]})
formats_in <- strsplit(msutils$EDAM.input.format,"\\|")
formats_in <-  lapply(formats_in,function(x) {sub(" ","",x); FullEDAM$name[paste("http://edamontology.org/",x,sep="")]})
data_out <- strsplit(msutils$EDAM.data.out,"\\|")
data_out <-  lapply(data_out,function(x) {sub(" ","",x); FullEDAM$name[paste("http://edamontology.org/",x,sep="")]})
formats_out <- strsplit(msutils$EDAM.data.format.out,"\\|")
formats_out <-  lapply(formats_out,function(x) {sub(" ","",x); FullEDAM$name[paste("http://edamontology.org/",x,sep="")]})
op_formats <- lapply(msutils$EDAM.data.in.input.format.data.in.input.format..operation..data.out.output.format.data.out.output.format, 
                     function(x) strsplit(x,"\n"))


# data.frame with edgs and vertices
pdf("msutils_EDAM_diagrams.pdf",width=12,height=18)
for (i in 1:nrow(msutils)) {
  edgelist <- vertices <- NULL
  tops <- topics[[i]]
  if (length(tops)> 0) {
    if (!is.na(tops)) {
      full <- unlist(op_formats[[i]])
      for (t in 1:length(topics[[i]])) {
        edgelist <- rbind(edgelist,c(tops[t],tops[min(t+1,length(tops))],0))
        vertices <- rbind(vertices,c(tops[t],names(tops)[t],tops[t],"#333333"))
      }
      if (length(full)>0) {
        for (t in 1:length(full)) {
          tvertices <- tedgelist <- NULL
          ## ERROR as combos of data+format
          triples <- unlist(strsplit(full[t],"->"))
          ops <- unlist(strsplit(triples[2],"\\|"))
          infuncs <- unlist(strsplit(triples[1],";"))
          outfuncs <- unlist(strsplit(triples[3],";"))
          allindats <- unlist(str_extract_all(triples[1],"data_[0-9]*"))
          alloutdats <- unlist(str_extract_all(triples[3],"data_[0-9]*"))
          
          for (f in 1:length(infuncs)) {
            indats <- unlist(strsplit(infuncs[[f]],"\\+"))
            inds <- unlist(strsplit(indats[1],"\\|"))
            infs <- unlist(strsplit(indats[2],"\\|"))
            for (l1 in 1:length(infs)) {
              tvertices <- rbind(tvertices,c(infs[l1],names(infs)[l1],"#339933"))
              for (l2 in 1:length(inds)) {
                tedgelist <- rbind(tedgelist,c(infs[l1],inds[l2],1))
              }
            }
          }
          for (f in 1:length(outfuncs)) {
            outdats <- unlist(strsplit(outfuncs[[f]],"\\+"))
            outds <- unlist(strsplit(outdats[1],"\\|"))
            outfs <- unlist(strsplit(outdats[2],"\\|"))
            for (l1 in 1:length(outfs)) {
              tvertices <- rbind(tvertices,c(outfs[l1],names(outfs)[l1],"#339933"))
              for (l2 in 1:length(outds)) {
                tedgelist <- rbind(tedgelist,c(outds[l2],outfs[l1],1))
              }
            }
          }
          
          for (o in 1:length(ops))
            tvertices <- rbind(tvertices,c(ops[o],names(ops)[o],"#993399"))
          
          for (l2 in 1:length(allindats)){
            tvertices <- rbind(tvertices,c(allindats[l2],names(allindats)[l2],"#339999"))
            for (o in 1:length(ops))
              tedgelist <- rbind(tedgelist,c(allindats[l2],ops[o],2))
          }
          for (l2 in 1:length(alloutdats)) {
            tvertices <- rbind(tvertices,c(alloutdats[l2],names(alloutdats)[l2],"#339999"))
            for (o in 1:length(ops))
              tedgelist <- rbind(tedgelist,c(ops[o],alloutdats[l2],2))
          }
          add_pipe <- ""
          if (length(full)>1) {
            add_pipe <- paste("pipeline ",t,"\n")
          }
          vertices <- rbind(vertices,cbind(paste(add_pipe,tvertices[,1],sep=""),tvertices))
          tedgelist[,1] <- paste(add_pipe,tedgelist[,1],sep="")
          tedgelist[,2] <- paste(add_pipe,tedgelist[,2],sep="")
          edgelist <- rbind(edgelist,tedgelist)
        }
      }
      vertices <- cbind(vertices, label=paste(vertices[,1],
                                              FullEDAM$name[paste("http://edamontology.org/",vertices[,2],sep="")],sep="\n"))
      colnames(vertices) <- c("name","id","color","label")
      colnames(edgelist) <- c("e1","e2","color")
      edgelist <- data.frame(edgelist,stringsAsFactors = F)
      edgelist[,3] <- as.numeric(edgelist[,3])
      vertices <- vertices[!duplicated(vertices[,1]),]
      #layout on grid with types separated on x-axis
      grid <- matrix(0,nrow=nrow(vertices), ncol=2)
      tt <- grid[vertices[,"color"]=="#333333",  ,drop=F]
      grid[vertices[,"color"]=="#333333", ] <- cbind(seq(0,1,len=nrow(tt)),0)
      tt <- grid[vertices[,"color"]=="#339933",  ,drop=F]
      grid[vertices[,"color"]=="#339933", ] <- cbind(seq(0,1,len=nrow(tt)),1)
      tt <- grid[vertices[,"color"]=="#339999", ,drop=F]
      grid[vertices[,"color"]=="#339999",] <- cbind(seq(0,1,len=nrow(tt)),2)
      tt <- grid[vertices[,"color"]=="#993399",  ,drop=F]
      grid[vertices[,"color"]=="#993399", ] <- cbind(seq(0,1,len=nrow(tt)),3)
      
      tgraph <- graph_from_data_frame(edgelist,vertices = vertices)
      layout <- layout.norm(grid)
      
      V(tgraph)$name <- paste(V(tgraph)$name,unlist(sub("http://edamontology.org/","",V(tgraph)$id)),sep="\n")
      plot(tgraph,color=tgraph$V, layout=layout, main=msutils$name[i], vertex.label.dist=2, vertex.label.degree=pi/2,
           sub=paste(strwrap(msutils$description[i]),collapse="\n"))
    }
  }
}
dev.off()
############# Create XML file for upload to bio.agents

## remove duplicates
FullPcks <- FullPcks[!duplicated(FullPcks$name), ]

FullPcks <- msutils
xml_out = newXMLNode(name="agents",namespace=list(xmlns="http://bio.agents"),namespaceDefinitions = list("xsi"="http://www.w3.org/2001/XMLSchema-instance"),attrs = list("xsi:schemaLocation"="http://bio.agents bioagents-2.0-beta-04.xsd"))
for (i in 1:nrow(FullPcks)) {
  currAgent <- FullPcks[i,]
  # Check for minimal requirements of schema
  if (!is.na(currAgent["name"])  && grepl("http",currAgent["link"]) && !is.na(currAgent["description"]) && 
      !is.na(currAgent["interface"]) && !(grepl("not",currAgent["interface"]))) {
    
    tnode <- newXMLNode("agent",parent=xml_out)
    tnode2 <- newXMLNode("summary",parent=tnode)
    ## need to remove ! from name as well
    currAgent$name <- gsub("\\!","",currAgent$name)
    newXMLNode("name",parent=tnode2,text=sub("\\(.*","",currAgent["name"]))
    ###### agent id without special characters and spaces (_ instead), max. 12 characters
    currAgent$agentID <- gsub("\\!","",currAgent$name)
    currAgent$agentID <- gsub(" ","_",currAgent$agentID)
    currAgent$agentID <- gsub("\\+","Plus",currAgent$agentID)
    currAgent$agentID <- gsub("\\.","",currAgent$agentID)
    currAgent$agentID <- strtrim(currAgent$agentID,12)
    newXMLNode("agentID",parent=tnode2,text=sub("\\(.*","",currAgent["agentID"]))
    newXMLNode("shortDescription",parent=tnode2,text=gsub('\n'," ",currAgent["description"]))
    newXMLNode("description",parent=tnode2,text=gsub('\n'," ",currAgent["description"]))
    newXMLNode("homepage",parent=tnode2,text=currAgent["link"])
    
    ## Probably need to adapt to allow multiple functions with different input/output in future
    tnode2 <- newXMLNode("function",parent=tnode)
    if (is.na(currAgent$EDAM.operation) | currAgent$EDAM.operation == "") {
      tnode3 <- newXMLNode("operation",parent=tnode2)
      alt_name <- "http://edamontology.org/operation_0004"
      newXMLNode("uri",parent=tnode3,alt_name)
      newXMLNode("term",parent=tnode3,EDAM$name[alt_name])
    } else {
      edam_list <- strsplit(as.character(currAgent$EDAM.operation), "\\|")
      for (e in unlist(edam_list)) {
        e <- gsub(" ","",e)
        tnode3 <- newXMLNode("operation",parent=tnode2)
        edam_name <- paste("http://edamontology.org/",e, sep="")
        newXMLNode("uri",parent=tnode3,edam_name)
        newXMLNode("term",parent=tnode3,EDAM$name[edam_name])
      }
    }
    tnode3 <- newXMLNode("input",parent=tnode2)
    ### Data terms still to come
    # if (is.na(currAgent$EDAM.data) | currAgent$EDAM.data == "")
    tnode4 <- newXMLNode("data",parent=tnode3)
    alt_name <- "http://edamontology.org/data_0006"
    newXMLNode("uri",parent=tnode4, alt_name)
    newXMLNode("term",parent=tnode4, EDAM$name[alt_name])
    if (is.na(currAgent$EDAM.data.format.in) | currAgent$EDAM.data.format.in == "") {
      tnode4 <- newXMLNode("format",parent=tnode3)
      alt_name <- "http://edamontology.org/format_1915"
      newXMLNode("uri",parent=tnode4, alt_name)
      newXMLNode("term",parent=tnode4, EDAM$name[alt_name])
    } else {
      edam_list <- strsplit(as.character(currAgent$EDAM.data.format.in), "\\|")
      for (e in unlist(edam_list)) {
        e <- gsub(" ","",e)
        tnode4 <- newXMLNode("format",parent=tnode3)
        edam_name <- paste("http://edamontology.org/",e, sep="")
        newXMLNode("uri",parent=tnode4, edam_name)
        newXMLNode("term",parent=tnode4, EDAM$name[edam_name])
      }
    }
    tnode3 <- newXMLNode("output",parent=tnode2)
    ### Data terms still to come
    # if (is.na(currAgent$EDAM.data) | currAgent$EDAM.data == "")
    tnode4 <- newXMLNode("data",parent=tnode3)
    alt_name <- "http://edamontology.org/data_0006"
    newXMLNode("uri",parent=tnode4, alt_name)
    newXMLNode("term",parent=tnode4, EDAM$name[alt_name])
    if (is.na(currAgent$EDAM.data.format.out) | currAgent$EDAM.data.format.out == "") {
      tnode4 <- newXMLNode("format",parent=tnode3)
      alt_name <- "http://edamontology.org/format_1915"
      newXMLNode("uri",parent=tnode4, alt_name)
      newXMLNode("term",parent=tnode4, EDAM$name[alt_name])
    } else {
      edam_list <- strsplit(as.character(currAgent$EDAM.data.format.out), "\\|")
      for (e in unlist(edam_list)) {
        e <- gsub(" ","",e)
        tnode4 <- newXMLNode("format",parent=tnode3)
        edam_name <- paste("http://edamontology.org/",e, sep="")
        newXMLNode("uri",parent=tnode4, edam_name)
        newXMLNode("term",parent=tnode4, EDAM$name[edam_name])
      }
    }
    
    tnode2 <- newXMLNode("labels",parent=tnode)
    ##  transform special interfaces
    interface_list <- strsplit(as.character(currAgent$interface), "\\|")
    for (e in unlist(interface_list)) {
      if (e == "Linux distribution") {
        newXMLNode("agentType",parent=tnode2,text="Suite")
      } else if (e == "iOS app") {
        newXMLNode("agentType",parent=tnode2,text="Desktop application")
      } else {
        ## CHECK NAMES
        newXMLNode("agentType",parent=tnode2,text = e)
      }
    }
    
    ## write EDAM terms if available, else write most general one
    if (is.na(currAgent$EDAM.topic) | currAgent$EDAM.topic == "") {
      tnode3 <- newXMLNode("topic",parent=tnode2)
      alt_name <- "http://edamontology.org/topic_0003"
      newXMLNode("uri",parent=tnode3, alt_name)
      newXMLNode("term",parent=tnode3, EDAM$name[alt_name])
    } else {
      edam_list <- strsplit(as.character(currAgent$EDAM.topic), "\\|")
      for (e in unlist(edam_list)) {
        e <- gsub(" ","",e,)
        tnode3 <- newXMLNode("topic",parent=tnode2)
        edam_name <- paste("http://edamontology.org/",e, sep="")
        newXMLNode("uri",parent=tnode3, edam_name)
        newXMLNode("term",parent=tnode3, EDAM$name[edam_name])
      }
    }
    if (!is.na(currAgent["lang"]) & currAgent$lang != "" & currAgent$lang != "Excel") {
      lang_list <- unlist(strsplit(as.character(currAgent$lang), "\\/"))
      for (e in lang_list) {
        if (e == "Visual C++")
          e <- "C++"
        if (e == "VC")
          e <- "C"
        newXMLNode("language",parent=tnode2,text=e)
      }
    }
    if (!is.na(currAgent["SPDX.license.IDs"]) & currAgent$license != "") {
      newXMLNode("license",parent=tnode2,text=gsub('\n'," ",currAgent["SPDX.license.IDs"]))
    }
    newXMLNode("collectionID",parent=tnode2,text="ms-utils")
    # newXMLNode("cost",parent=tnode2,text="Free of charge")
    # newXMLNode("accessibility",parent=tnode2,text="Open access")
    
    if (!is.na(currAgent$weblink) & currAgent$weblink != "") {
      tnode2 <- newXMLNode("link",parent=tnode)
      newXMLNode("url",parent=tnode2,currAgent$weblink)
      newXMLNode("type",parent=tnode2,"Mirror")
    }
    
    tnode2 <- newXMLNode("link",parent=tnode)
    newXMLNode("url",parent=tnode2,"http://ms-utils.org")
    newXMLNode("type",parent=tnode2,"Registry")
    
    if (!is.na(currAgent$source) & currAgent$source != "") {
      tnode2 <- newXMLNode("download",parent=tnode)
      newXMLNode("url",parent=tnode2,currAgent$source)
      newXMLNode("type",parent=tnode2,"Source code")
    }
    
    if (!is.na(currAgent["paper"]) & currAgent$paper != "") {
      pub_list <- unlist(strsplit(as.character(currAgent$paper), "\\|"))
      for (e in pub_list) {
        tnode2 <- newXMLNode("publication",parent=tnode)
        if (!grepl("/",e)) {
          newXMLNode("pmid",parent=tnode2,text=e)
        } else {
          newXMLNode("doi",parent=tnode2,text=e)
        }
      }
    }
    
    
    tnode2 <- newXMLNode("contact",parent=tnode)
    ## TBD:
    newXMLNode("email",parent=tnode2,text="webmaster@ms-utils.org")
    newXMLNode("url",parent=tnode2,text="ms-utils.org")
    
    maintainers <- strsplit(as.character(currAgent["email"]),"\\|")
    for (m in unlist(maintainers)) {
      if (m != " " & m != "" & !is.na(m) & !is.na(m)) {
        if(!is.na(m)) {
          tnode2 <- newXMLNode("credit",parent=tnode)
          newXMLNode("name",parent=tnode2,"see publication")
          newXMLNode("email",parent=tnode2,text=m)
          newXMLNode("typeEntity",parent=tnode2,text="Person")
          newXMLNode("typeRole",parent=tnode2,text="Maintainer")
        }
      }
    }
  }
  
}


saveXML(xml_out,"FullMSUtils.xml")

############### IECHOR REGISTRY -> MSUTILS.ORG 

url <- system("wget https://iechor-registry.cbs.dtu.dk/api/agent?format=xml -O FulliEchor.xml")
FullRegistry <- xmlTreeParse("FulliEchor.xml")
FullReg <- xmlToList(FullRegistry)

# Extract the ones with EDAM "Proteomics"

sublist <- NULL
tname <- "Proteomics"
for (i in 1:length(FullReg)) {
  tttt <- FullReg[[i]]
  topics <- tttt[which(names(tttt)== "topic")]
  if (length(topics) >= 1) {
    if(length(topics) == 1) {
      try(
        # print(topics$topic$text),
        if (topics$topic$text == tname)
          sublist <- c(sublist,list(tttt)))
    } else {
      for (j in 1:length(topics)) {
        try(if (topics[[j]]$text == tname)
          sublist <- c(sublist,list(tttt)))
      }
    }
  }
}

# Generate line for wiki file

textout <- ""
for (i in 1:length(sublist)) {
  
  ttt <- sublist[[i]]
  if(length(ttt$language)==0)
    ttt$language <- ""
  if(length(ttt$publications$publicationsPrimaryID)==0)
    ttt$publications$publicationsPrimaryID <- ""
  if(length(ttt$interface$interfaceType)==0)
    ttt$interface$interfaceType <- ""
  
  textout <- paste(textout,"\n","||[[",ttt$homepage,"|",ttt$name,"]]||",
                   ttt$description,"[[",ttt$publications$publicationsPrimaryID,"|#]]||",ttt$language,"||",
                   ttt$interface$interfaceType,"||"
                   ,sep="")
}

write(textout,"msutils_in.txt")



