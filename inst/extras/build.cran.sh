/usr/bin/R CMD BATCH document.R
#/usr/bin/R CMD build ../../ --no-build-vignettes
/usr/bin/R CMD build ../../ 
/usr/bin/R CMD check --as-cran pxweb_0.4.23.tar.gz
/usr/bin/R CMD INSTALL pxweb_0.4.23.tar.gz

