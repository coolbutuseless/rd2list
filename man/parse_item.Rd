% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/parse.R
\name{parse_item}
\alias{parse_item}
\title{Parse a single \code{item} into a single character string or a named list with one element}
\usage{
parse_item(rd_node, into = c("text", "list"))
}
\arguments{
\item{rd_node}{element in an Rd document}

\item{into}{desired format of item. 'text' or 'list'. default: text}
}
\value{
named list of length 1
}
\description{
Parse a single \code{item} into a single character string or a named list with one element
}
