



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# From https://developer.r-project.org/parseRd.pdf page 5
# Use this information to aid in parsing
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
section_macros <- readr::read_csv(
'name      ,  n_arguments,   section, list_type, text_type
arguments  ,            1,       yes,  item{}{}, Latex-like
author     ,            1,       yes,        no, Latex-like
concept    ,            1,       yes,        no, Latex-like
description,            1,       yes,        no, Latex-like
details    ,            1,       yes,        no, Latex-like
docType    ,            1,       yes,        no, Latex-like
encoding   ,            1,       yes,        no, Latex-like
format     ,            1,       yes,        no, Latex-like
keyword    ,            1,       yes,        no, Latex-like
name       ,            1,       yes,        no, Latex-like
note       ,            1,       yes,        no, Latex-like
references ,            1,       yes,        no, Latex-like
section    ,            2,       yes,        no, Latex-like
seealso    ,            1,       yes,        no, Latex-like
source     ,            1,       yes,        no, Latex-like
title      ,            1,       yes,        no, Latex-like
value      ,            1,       yes,  item{}{}, Latex-like
examples   ,            1,       yes,        no, R-like
usage      ,            1,       yes,        no, R-like
alias      ,            1,       yes,        no, Verbatim
Rdversion  ,            1,       yes,        no, Verbatim
synopsis   ,            1,       yes,        no, Verbatim
Sexpr      ,            1, sometimes,        no, R-like
RdOpts     ,            1,       yes,        no, Verbatim
')


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# From https://developer.r-project.org/parseRd.pdf page 6 + 7
# Use this information to aid in parsing
#
#  'delim'   - put this string at the start/end of the parsed text for this markup
#  'replace' - If given, don't parse the tag, but use this instead
#  'sep'     - The separator between elements
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
markup_macros <- readr::read_csv(
'name       , n_arguments,   section, list_type, text_type , delim, replace, sep
acronym     ,           1,        no,        no, Latex-like,      ,        ,
bold        ,           1,        no,        no, Latex-like,   ** ,        ,
cite        ,           1,        no,        no, Latex-like,      ,        ,
command     ,           1,        no,        no, Latex-like,      ,        ,
dfn         ,           1,        no,        no, Latex-like,      ,        ,
dQuote      ,           1,        no,        no, Latex-like,    " ,        ,
email       ,           1,        no,        no, Latex-like,      ,        ,
emph        ,           1,        no,        no, Latex-like,    * ,        ,
file        ,           1,        no,        no, Latex-like,    ` ,        ,
item        ,          NA,        no,        no, Latex-like,      ,        ,
linkS4class ,           1,        no,        no, Latex-like,      ,        ,
pkg         ,           1,        no,        no, Latex-like,    ` ,        ,
sQuote      ,           1,        no,        no, Latex-like,   \' ,        ,
strong      ,           1,        no,        no, Latex-like,   ** ,        ,
var         ,           1,        no,        no, Latex-like,    ` ,        ,
describe    ,           1,        no,  item{}{}, Latex-like,      ,        ,
enumerate   ,           1,        no,      item, Latex-like,      ,        ,
itemize     ,           1,        no,      item, Latex-like,      ,        ,
enc         ,           2,        no,        no, Latex-like,      ,        ,
if          ,           2,        no,        no, Latex-like,      ,        ,
ifelse      ,           3,        no,        no, Latex-like,      ,        ,
method      ,           2,        no,        no, Latex-like,    ` ,        , .
S3method    ,           2,        no,        no, Latex-like,    ` ,        , .
S4method    ,           2,        no,        no, Latex-like,    ` ,        , @
tabular     ,           2,        no,        no, Latex-like,      ,        ,
subsection  ,           2,        no,        no, Latex-like,      ,        ,
link        ,           1,        no,        no, Latex-like,      ,        ,
href        ,           2,        no,        no, Verbatim  ,      ,        ,
cr          ,           0,        no,        no,           ,      ,        ,
dots        ,           0,        no,        no,           ,      , ...    ,
ldots       ,           0,        no,        no,           ,      , ...    ,
R           ,           0,        no,        no,           ,      , R      ,
tab         ,           0,        no,        no,           ,      ,        ,
code        ,           1,        no,        no,     R-like,    ` ,        ,
dontshow    ,           1,        no,        no,     R-like,      ,        ,
donttest    ,           1,        no,        no,     R-like,      ,        ,
testonly    ,           1,        no,        no,     R-like,      ,        ,
dontrun     ,           1,        no,        no,   Verbatim,      ,        ,
env         ,           1,        no,        no,   Verbatim,      ,        ,
kbd         ,           1,        no,        no,   Verbatim,      ,        ,
option      ,           1,        no,        no,   Verbatim,    " ,        ,
out         ,           1,        no,        no,   Verbatim,      ,        ,
preformatted,           1,        no,        no,   Verbatim,      ,        ,
samp        ,           1,        no,        no,   Verbatim,      ,        ,
special     ,           1,        no,        no,   Verbatim,      ,        ,
url         ,           1,        no,        no,   Verbatim,      ,        ,
verb        ,           1,        no,        no,   Verbatim,      ,        ,
deqn        ,           2,        no,        no,   Verbatim,      ,        ,
eqn         ,           2,        no,        no,   Verbatim,      ,        ,
newcommand  ,           2,      both,        no,   Verbatim,      ,        ,
renewcommand,           2,      both,        no,   Verbatim,      ,        ,
', quote = "^")


markup_macros$delim[is.na(markup_macros$delim)] <- ''
markup_macros$sep  [is.na(markup_macros$sep  )] <- ''


usethis::use_data(section_macros, markup_macros, internal = TRUE, overwrite = TRUE)