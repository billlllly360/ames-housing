read_args <- function(defaults) {
  args <- defaults
  for (value in commandArgs(TRUE)) {
    if (!grepl("^--[^=]+=", value)) stop("Expected --name=value: ", value)
    name <- sub("^--([^=]+)=.*$", "\\1", value)
    if (!(name %in% names(defaults))) stop("Unknown option: ", name)
    args[[name]] <- sub("^--[^=]+=", "", value)
  }
  args
}

load_packages <- function(folder) {
  if (dir.exists(folder)) .libPaths(c(normalizePath(folder), .libPaths()))
  if (!requireNamespace("catboost", quietly = TRUE)) stop("Run install_packages.R or provide --library=PATH.")
  if (as.character(getNamespaceVersion("catboost")) != "1.2.10") stop("Use CatBoost 1.2.10 for this model.")
}

create_output <- function(folder) {
  if (dir.exists(folder)) stop("Output folder exists. Pick a new --output-dir.")
  dir.create(folder, recursive = TRUE)
}
