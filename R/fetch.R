

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Get the raw Rd for the help for a function
#'
#' @param function_name character name of function
#' @param package_name character name of package. If NULL, search within all
#' packages whose namespaces are loaded
#'
#' @return Rd document object
#'
#' @importFrom stats setNames
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_rd_doc <- function(function_name, package_name = NULL) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Ask for the location of the help for this function.
  # This returns a link to a location that doesn't actually exist, but gets
  # us to the right ballpark
  # Convert it to a character as this is a bit easier to cope with
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  help_location <- as.character(
    utils::help((function_name), package = (package_name), help_type = 'text')
  )

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # This is the easiest place to trap the error if the user requests help
  # for something that doesn't have it
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (length(help_location) == 0L) {
    warning("No Rd documentation available for '", package_name, "::", function_name, "'")
    return(NULL)
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Construct the basename of the actual Rd database file. Later on in
  # 'lazyLoadDBfetch' this will be suffixed with '.rdx' to point to
  # the actual real file with documentation information.
  # Since package_name could be NULL, parse out the package name from the
  # help location.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  package_name <- basename(dirname(dirname(help_location)))
  filebase     <- file.path(dirname(help_location), package_name)
  key          <- basename(help_location)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # The following code is a modified version of the body of
  # tools:::fetchRdDB with just the bits I need for this call
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  fun <- function(db) {
    lazyLoadDBfetch(db$vals[key][[1L]], db$datafile, db$compressed, db$envhook)
  }

  rd_doc <- lazyLoadDBexec(filebase, fun)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Use the 'Rd_tag' attribute to generate a name for each section
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  section_names <- vapply(
    rd_doc,
    function(.x) { gsub("\\\\", "", attr(.x, 'Rd_tag')) },
    character(1)
  )


  setNames(rd_doc, section_names)
}

