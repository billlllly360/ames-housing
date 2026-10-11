file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- normalizePath(file.path(dirname(file), ".."), winslash = "/")
lib <- file.path(root, ".R-library")
dir.create(lib, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))

if (.Platform$OS.type != "windows") stop("See CatBoost's R installation guide for macOS/Linux.")
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  install.packages("jsonlite", lib = lib, repos = "https://cloud.r-project.org")
}
if (!requireNamespace("catboost", quietly = TRUE)) {
  package <- tempfile(fileext = ".tgz")
  url <- "https://github.com/catboost/catboost/releases/download/v1.2.10/catboost-R-windows-x86_64-1.2.10.tgz"
  download.file(url, package, mode = "wb")
  install.packages(package, repos = NULL, type = "source", lib = lib,
    INSTALL_opts = c("--no-multiarch", "--no-test-load"))
}
stopifnot(requireNamespace("catboost", quietly = TRUE))
cat("Ready to run train_model.R\n")
