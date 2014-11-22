## ----install1, eval=FALSE------------------------------------------------
#  install.packages("pxweb")

## ----install2, eval=FALSE------------------------------------------------
#  install.packages("devtools")
#  devtools::install_github("pxweb","rOpenGov")

## ----test, message=FALSE, warning=FALSE, eval=TRUE-----------------------
library(pxweb)

## ----apiparameters, message=FALSE, eval=TRUE-----------------------------
library(pxweb)
print(api_catalogue()[1:2])

## ----standardquery, message=FALSE, eval=FALSE----------------------------
#  # Get data from SCB (Statistics Sweden)
#  d <- interactive_pxweb(api = "api.scb.se")
#  
#  # Fetching data from the swedish SCB (Statistics Sweden) pxweb API using the alias 'scb'
#  d <- interactive_pxweb(api = "scb", version = "v1", lang = "sv")
#  
#  # Fetching data from statfi (Statistics Finland) using the alias 'statfi'
#  d <- interactive_pxweb(api = "statfi")

## ----add_api, message=FALSE, eval=FALSE----------------------------------
#  # Create a pxweb api object
#  my_api <-
#    pxweb_api$new(api = "foo.bar", # PXWEB api name
#                  alias = "foo", # Alias for the api, can be ignored
#                  url = "http://api.foo.bar/[version]/[lang]",
#                  description = "My own pxweb api",
#                  languages = "en", # Languages
#                  versions = "v1", # Versions
#                  calls_per_period = 1,
#                  period_in_seconds = 2,
#                  max_values_to_download = 10)
#  
#  # Test that the api works (in this case it does not)
#  my_api$test_api()
#  
#  # Add the api to the api catalogue
#  my_api$write_to_catalogue()
#  

## ----citation, message=FALSE, eval=TRUE----------------------------------
citation("pxweb")

## ----sessioninfo, message=FALSE, warning=FALSE---------------------------
sessionInfo()

