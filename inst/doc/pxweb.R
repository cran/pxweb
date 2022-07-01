## ----install1, eval=FALSE-----------------------------------------------------
#  install.packages("pxweb")

## ----install2, eval=FALSE-----------------------------------------------------
#  library("devtools")
#  devtools::install_github("ropengov/pxweb")

## ----test, message=FALSE, warning=FALSE, eval=TRUE----------------------------
library(pxweb)

## ----locale, eval=FALSE-------------------------------------------------------
#  Sys.setlocale(locale="UTF-8")

## ----standardquery, message=FALSE, eval=FALSE---------------------------------
#  # Navigate through all pxweb api:s in the R package API catalogue
#  d <- pxweb_interactive()
#  
#  # Get data from SCB (Statistics Sweden)
#  d <- pxweb_interactive("api.scb.se")
#  
#  # Fetching data from statfi (Statistics Finland)
#  d <- pxweb_interactive("pxnet2.stat.fi")
#  
#  # Fetching data from StatBank (Statistics Norway)
#  d <- pxweb_interactive("data.ssb.no")
#  
#  # To see all available PXWEB APIs use
#  pxweb_apis <- pxweb_api_catalogue()

## ----inapi, message=FALSE, eval=FALSE-----------------------------------------
#  # Start with a specific path.
#  d <- pxweb_interactive("http://api.scb.se/OV0104/v1/doris/en/ssd/BE/BE0101/BE0101A")

## ---- message=FALSE, eval=FALSE-----------------------------------------------
#  file.edit(pxweb_api_catalogue_path())

## ----levels, message=FALSE, eval=TRUE-----------------------------------------
# Get PXWEB levels
px_levels <- pxweb_get("http://api.scb.se/OV0104/v1/doris/en/ssd/BE/BE0101/BE0101A/")
px_levels

## ----meta, message=FALSE, eval=TRUE-------------------------------------------
# Get PXWEB metadata about a table
px_meta <- pxweb_get("http://api.scb.se/OV0104/v1/doris/en/ssd/BE/BE0101/BE0101A/BefolkningNy")
px_meta

## ---- message=FALSE, eval=FALSE-----------------------------------------------
#  d <- pxweb_interactive("http://api.scb.se/OV0104/v1/doris/en/ssd/BE/BE0101/BE0101A/BefolkningNy")

## ---- message=FALSE, eval=TRUE, echo=FALSE------------------------------------
# save(d, file = "d_example.rda")
load("d_example.rda")

## ---- message=FALSE, eval=TRUE------------------------------------------------
d$url
d$query

## ----interactive_query, message=FALSE, eval=TRUE------------------------------
pxweb_query_as_json(d$query, pretty = TRUE)

## ----pxq, message=FALSE, eval=FALSE-------------------------------------------
#  pxq <- pxweb_query("path/to/the/json/query.json")

## ----rquery, message=FALSE, eval=TRUE-----------------------------------------
pxweb_query_list <- 
  list("Civilstand"=c("*"), # Use "*" to select all
       "Kon"=c("1","2"),
       "ContentsCode"=c("BE0101N1"),
       "Tid"=c("2015","2016","2017"))
pxq <- pxweb_query(pxweb_query_list)
pxq

## ----validate_query, message=FALSE, eval=TRUE---------------------------------
pxweb_validate_query_with_metadata(pxq, px_meta)

## ---- message=FALSE, eval=TRUE------------------------------------------------
pxd <- pxweb_get("http://api.scb.se/OV0104/v1/doris/en/ssd/BE/BE0101/BE0101A/BefolkningNy",
                 pxq)
pxd

## ---- message=FALSE, eval=TRUE------------------------------------------------
pxq$response$format <- "json-stat"
pxjstat <- pxweb_get("http://api.scb.se/OV0104/v1/doris/en/ssd/BE/BE0101/BE0101A/BefolkningNy",
                     pxq)
pxjstat

## ---- message=FALSE, eval=TRUE------------------------------------------------
pxq$response$format <- "px"
pxfp <- pxweb_get("http://api.scb.se/OV0104/v1/doris/en/ssd/BE/BE0101/BE0101A/BefolkningNy",
                     pxq)
pxfp

## ---- message=FALSE, eval=TRUE------------------------------------------------
pxdf <- as.data.frame(pxd, column.name.type = "text", variable.value.type = "text")
head(pxdf)

## ---- message=FALSE, eval=TRUE------------------------------------------------
pxdf <- as.data.frame(pxd, column.name.type = "code", variable.value.type = "code")
head(pxdf)

## ---- message=FALSE, eval=TRUE------------------------------------------------
pxmat <- as.matrix(pxd, column.name.type = "code", variable.value.type = "code")
head(pxmat)

## ---- message=FALSE, eval=TRUE------------------------------------------------
pxdc <- pxweb_data_comments(pxd)
pxdc

## ---- message=FALSE, eval=FALSE-----------------------------------------------
#  as.data.frame(pxdc)

## ---- message=FALSE, eval=TRUE------------------------------------------------
pxweb_cite(pxd)

## ----sessioninfo, message=FALSE, warning=FALSE--------------------------------
sessionInfo()

