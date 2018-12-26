context("test-basic-usage")


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Selecting some base functions to to ensure I have good test coverage
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
test_that("basic usage 1", {

  function_names <- c('diag', '-.POSIXt', '!', 'bitwAnd', 'as.vector')

  for (function_name in function_names) {
    res <- get_doc(function_name = function_name, package = 'base')

    expect_true(length(res) > 0)
    expect_true('name'        %in% names(res))
    expect_true('arguments'   %in% names(res))
    expect_true('description' %in% names(res))
  }

})




test_that("Handles non-existant function", {
  expect_warning({
    res <- get_doc(function_name = 'diag_xxx', package = 'base')
  }, "No Rd documentation")

  expect_null(res)
})



test_that("Handles non-existant package", {
  expect_error({
    res <- get_doc(function_name = 'diag', package = 'base_xxx')
  }, "no package called")

})