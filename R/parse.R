


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Get the \code{Rd_tag} of the node in an \code{Rd} document.
#'
#' The \code{Rd_tag} gives meta-information about the Rd node and how to interpret it.
#'
#' @inheritParams parse_arguments
#'
#' @return characater string. 'NO TAG' if no tag was found
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_tag <- function(rd_node) {
  tag <- attr(rd_node, 'Rd_tag', exact = TRUE)

  if (is.null(tag)) {
    "NO TAG"
  } else {
    gsub("\\\\", "", tag)
  }
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Collapse character vector into a single character string
#'
#' @param text character vector
#'
#' @return single character string
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
collapse_whitespace <- function(text) {
  text <- paste(text, collapse = '')
  text <- gsub(" +", " ", text)
  text <- trimws(text)
  text <- gsub("\\n\\s+\\n", "\n\n", text)

  text
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Replase single newline with a space, and ollapse multiple newlines into a single newline
#'
#' @param text character string
#'
#' @return single character string
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
collapse_newlines <- function(text) {
    # Replace single \n with space
    text <- gsub("([^\n])\n([^\n])", "\\1 \\2", text)

    # Replace multiple \n with a single \n
    text <- gsub("\n+", "\n", text)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Parse text from the given node in an \code{Rd} document
#'
#' @inheritParams parse_arguments
#'
#' @return character string
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
parse_text <- function(rd_node) {

  tag <- get_tag(rd_node)

  ignored_tags <- c('COMMENT', 'USERMACRO')

  if (tag == 'item') {
    res <- parse_item(rd_node)
  } else if (tag %in% c('NO TAG', 'LIST')) {
    res <- vapply(rd_node, parse_text, character(1))
    res <- collapse_whitespace(res)
  } else if (tag %in% c('TEXT', 'RCODE', 'VERB')) {
    res <- as.character(rd_node)
  } else if (tag %in% markup_macros$name) {
    markup <- markup_macros[markup_macros$name == tag,]

    if (!is.na(markup$replace)) {
      res <- markup$replace
    } else if (identical(markup$n_arguments, 0)) {
      res <- ''
    } else if (tag == 'href') {
      res1 <- parse_text(rd_node[[1]])
      res2 <- parse_text(rd_node[[2]])
      res  <- paste0("[", res2, "](", res1, ")")
    } else if (tag %in% c('method', 'S3method', 'S4method')) {
      res1 <- parse_text(rd_node[[1]])
      res2 <- parse_text(rd_node[[2]])
      res  <- paste0(res1, markup$sep, res2)
    } else if (tag == 'ifelse') {
      # ifelse markup has 3 elements: document type, response for true, then
      # response for false. Document type is one of: text, html
      render_type <- parse_text(rd_node[[1]])
      if (render_type == 'text') {
        res <- parse_text(rd_node[[2]])
      } else {
        res <- parse_text(rd_node[[3]])
      }
    } else if (tag == 'itemize') {
      res <- parse_itemize(rd_node)
      res <- paste0(res, collapse = "\n\n\t* ")
      res <- collapse_whitespace(res)
      res <- paste0("\n\n\t* ", res, "\n\n")
    } else if (tag == 'enumerate') {
      res <- parse_itemize(rd_node)
      res <- paste0(seq(res), ". ", res)
      res <- paste0(res, collapse = "\n\n\t ")
      res <- collapse_whitespace(res)
      res <- paste0("\n\n\t ", res, "\n\n")
    } else if (tag == 'describe') {
      res <- parse_describe(rd_node)
    } else {
      res <- vapply(rd_node, parse_text, character(1))
      res <- collapse_whitespace(res)
    }

    res <- paste0(markup$delim, res, markup$delim)

  } else if (tag %in% ignored_tags) {
    res <- ''
  } else {
    warning("Markup not handled  [", tag, "]")
    res <- paste0("[Markup not handled:", tag, "]")
  }

  res
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Cut a vector between the given indices (non-including the indices themselves)
#'
#' @param v character vector
#' @param idxs indices
#'
#' @return one character vector for each pair of indices
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cut_with_index <- function(v, idxs) {
  N    <- length(idxs) - 1L
  vout <- character(N)
  for (i in seq(N)) {
    start <- idxs[i     ] + 1L
    end   <- idxs[i + 1L] - 1L
    vout[i] <- collapse_whitespace(paste(v[start:end], collapse=""))
  }
  vout
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Parse an 'itemize' or 'enumerate'
#'
#' @inheritParams parse_arguments
#'
#' @return vector of character strings
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
parse_itemize <- function(rd_node) {
  tag <- get_tag(rd_node)
  stopifnot(tag %in% c('itemize', 'enumerate'))

  res <- vapply(rd_node, parse_text, character(1))

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # the beginning of new items is marked with the 'item' markup which has
  # been transformed into the sentinel value of '[item]'.  Detect these
  # elements in the result, and use it to slice up the result into
  # complete items
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  item_idxs <- c(which(res == '[item]'), length(res) + 1L)
  res       <- cut_with_index(res, item_idxs)


  res
}




#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Parse a single \code{item} into a single character string or a named list with one element
#'
#' @inheritParams parse_arguments
#' @param into desired format of item. 'text' or 'list'. default: text
#'
#' @return named list of length 1
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
parse_item <- function(rd_node, into = c('text', 'list')) {
  tag <- get_tag(rd_node)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Don't process it if it isn't an 'item'.
  # There are often TEXT entries in itemize/enumerate lists (like newlines).
  # Just ignore these, as we only care about parsing out the item contents
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (!identical(tag, 'item')) { return() }

  into <- match.arg(into)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Within 'itemize' and 'enumerate' elements, the 'item' block itself is empty,
  # and is only used to signpost the beginning of the next item.
  # Return a sentinel value and use it later to divide up the text stream into
  # separate items
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (length(rd_node) == 0) {
    return('[item]')
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Each item consistes of 2 things. A name and a value
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  res1 <- parse_text(rd_node[[1]])
  res2 <- parse_text(rd_node[[2]])

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # If 'text', then just paste the name and value together.
  # If 'list', then create a named list (of length = 1)
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (into == 'text') {
    res <- paste0(res1, " -- ", res2)
  } else {
    res <- setNames(list(res2), res1)
  }

  res
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Parse a block of text which has an \code{Rd_tag} of \code{describe}
#'
#' @inheritParams parse_arguments
#'
#' @return named list
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
parse_describe <- function(rd_node) {
  tag <- get_tag(rd_node)
  stopifnot(tag == 'describe')

  res <- lapply(rd_node, parse_item, into = 'text')
  res <- Filter(Negate(is.null), res)
  res <- unlist(res, recursive = FALSE)
  res <- lapply(res, collapse_newlines)

  res <- paste(res, collapse = "\n\n\t* ")
  res <- paste0("\n\n\t* ", res, "\n\n")

  res
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Parse a section of an \code{Rd} object which has an \code{Rd_tag} of \code{arguments}
#'
#' @param rd_node element in an Rd document
#'
#' @return named list
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
parse_arguments <- function(rd_node) {
  tag <- get_tag(rd_node)
  stopifnot(tag == 'arguments')

  res <- lapply(rd_node, parse_item, into = 'list')
  res <- Filter(Negate(is.null), res)
  res <- unlist(res, recursive = FALSE)
  res <- lapply(res, collapse_newlines)

  res
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Parse a section from an Rd document.
#'
#' Parse a section from an Rd document given the document node for that section.
#'
#' See \url{https://developer.r-project.org/parseRd.pdf} page 5 for a list
#' of all sectioning macros
#'
#' Note: Only parsing \code{arguments}, \code{description}, \code{usage},
#' \code{title} and \code{name} for now.
#'
#' @param rd_section An element from an \code{Rd} document which represents a
#' \verb{section} such as the \code{title} or \code{description}.
#'
#' @return contents of section
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
parse_section <- function(rd_section) {
  tag <- get_tag(rd_section)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # `section_macros` contains all section names according to the docs.
  # If the given `rd_section` does not match those names, it's either a
  # mal-formed document, or there's been an updated to the Rd standard.
  # Either way, lets throw an error and figure out what's wrong.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (!tag %in% section_macros$name) {
    stop("Not a valid section: [", tag, "]")
  }

  excluded_sections <- c('examples')

  if (tag == 'arguments') {
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # 'arguments' section has a custom parser
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    value <- parse_arguments(rd_section)
  } else if (tag == 'section') {
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # This is a generic user-defined section in the documentation.
    # This is a 2 argument macro where the first argument is the title for the
    # section, and the second argument contains the body
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    tag   <- parse_text(rd_section[[1]])
    value <- parse_text(rd_section[-1])
    value <- collapse_newlines(value)
  } else if (tag %in% excluded_sections) {
    value <- NULL
  } else {
    attributes(rd_section) <- NULL
    value <- parse_text(rd_section)
    value <- collapse_newlines(value)
  }


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Name the object.
  # This is done here as some sections get their name from the first
  # item of their contents, and not the name of the section itself.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  setNames(list(value), tag)
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Parse documentation in Rd list format into a human-readable list
#'
#' This function is named to be similar to the \code{Rd2HTML} and \code{Rd2txt}
#' functions in the \pkg{tools} package.
#'
#' In contrast to those functions, \code{Rd2list} can only be given an \code{Rd}
#' object.
#'
#' @param rd_doc An \code{Rd} object as returned by \code{tools::parse_Rd} or
#' \code{get_rd_doc}.  An Rd doc is a list of lists with attributes.  The list
#' elements at the top-most level represent the sections within the documentation.
#'
#' @return structured character strings in a list object
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rd2list <- function(rd_doc) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # An 'Rd' object is just a list of docuement sections.
  # Parse each one and drop any empty ones
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  res <- lapply(unname(rd_doc), parse_section)
  res <- unlist(res, recursive = FALSE, use.names = TRUE)
  res <- Filter(Negate(is.null), res)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Totally empty doc?
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (length(res) == 0) {
    return(NULL)
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Collapse some sections which can occur multiple times into a single block.
  # e.g. rather than multiple `alias` sections, just pool all the aliases
  # into a single entry.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  collapse_names <- c('alias', 'concept', 'keyword')
  for (collapse_name in collapse_names) {
    collapse_idx   <- which(names(res) == collapse_name)
    if (length(collapse_idx) > 1L) {
      collapsed <- unlist(res[collapse_idx], use.names = FALSE)
      res[[collapse_idx[ 1]]] <- collapsed
      res[collapse_idx[-1]] <- NULL
    }
  }


  res
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Get the documentation for a function in an R list
#'
#' @inheritParams get_rd_doc
#'
#' @return named list of documentation
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_doc <- function(function_name, package_name = NULL) {
  rd_doc <- get_rd_doc(function_name, package_name)
  rd2list(rd_doc)
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Testing
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (FALSE) {
  suppressPackageStartupMessages({
    library(dplyr)
    library(purrr)
    library(rlang)
  })

  # geom_path has an itemize
  # diag has an enumerate
  # geom_qq has a describe

  rd_doc <- get_rd_doc('beta', 'base')
  class(rd_doc) <- NULL
  zz <- parse_rd_doc(rd_doc)

  zz


  function_names <- ls('package:base')
  for (function_name in function_names[100:300]) {
    rd_doc <- get_rd_doc(function_name, 'base')
    class(rd_doc) <- NULL
    zz <- parse_rd_doc(rd_doc)
  }

}














