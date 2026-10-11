find_data <- function(folder, name) {
  files <- list.files(folder, pattern = paste0("^", name, "( \\([0-9]+\\))?\\.csv$"), full.names = TRUE)
  if (length(files) != 1) stop("Keep one ", name, " CSV in ", folder)
  files
}

read_data <- function(folder, name) {
  read.csv(find_data(folder, name), na.strings = c("", "NA"),
           stringsAsFactors = FALSE, check.names = FALSE)
}

add_features <- function(df) {
  df <- df[setdiff(names(df), c("Id", "SalePrice"))]
  df$MSSubClass <- as.character(df$MSSubClass)
  df$MoSold <- as.character(df$MoSold)
  df$age <- df$YrSold - df$YearBuilt
  df$remodel_age <- df$YrSold - df$YearRemodAdd
  # Unknown areas stay NA; they are not zero-sized spaces.
  df$total_area <- df$TotalBsmtSF + df[["1stFlrSF"]] + df[["2ndFlrSF"]]
  df$bathrooms <- df$FullBath + df$BsmtFullBath + .5 * (df$HalfBath + df$BsmtHalfBath)
  df$has_garage <- as.integer(df$GarageCars > 0)
  df$has_basement <- as.integer(df$TotalBsmtSF > 0)
  df$has_pool <- as.integer(df$PoolArea > 0)
  df$has_fireplace <- as.integer(df$Fireplaces > 0)
  df$quality_area <- df$OverallQual * df$GrLivArea
  for (col in c("LotArea", "GrLivArea", "total_area")) {
    if (any(df[[col]] < 0, na.rm = TRUE)) stop("Negative area: ", col)
    df[[paste0("log_", col)]] <- log1p(df[[col]])
  }
  df
}

fit_preprocess <- function(df) {
  num_cols <- names(df)[vapply(df, is.numeric, logical(1))]
  medians <- vapply(df[num_cols], function(values) {
    if (all(is.na(values))) 0 else median(values, na.rm = TRUE)
  }, numeric(1))
  list(num_cols = num_cols, medians = medians, cat_cols = setdiff(names(df), num_cols))
}

prep_data <- function(df, prep) {
  for (col in prep$num_cols) {
    missing <- is.na(df[[col]])
    df[[col]][missing] <- prep$medians[[col]]
    df[[col]] <- as.double(df[[col]])
    df[[paste0(col, "_missing")]] <- as.double(missing)
  }
  for (col in prep$cat_cols) {
    df[[col]] <- factor(ifelse(is.na(df[[col]]), "<MISSING>", as.character(df[[col]])))
  }
  stopifnot(!anyNA(df))
  df
}

check_submission <- function(submission, test, sample_file) {
  stopifnot(identical(names(submission), c("Id", "SalePrice")),
            nrow(submission) == nrow(test), identical(submission$Id, test$Id),
            identical(submission$Id, sample_file$Id), !anyDuplicated(submission$Id),
            all(is.finite(submission$SalePrice)), all(submission$SalePrice > 0))
  invisible(TRUE)
}
