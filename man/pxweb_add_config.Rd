% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pxweb_add_config.R
\name{pxweb_add_config}
\alias{pxweb_add_config}
\title{Add the config slot to a pxweb object}
\usage{
pxweb_add_config(obj)
}
\arguments{
\item{obj}{an object to add config to}
}
\description{
Add the config slot to a pxweb object
}
\details{
Checks if there exist a config object in the object.
Otherwise it query the api to get it and add that call to the call stack.
}
\keyword{internal}
