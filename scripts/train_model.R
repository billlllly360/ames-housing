file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- normalizePath(file.path(dirname(file), ".."), winslash = "/")
source(file.path(root, "R", "paths.R"))
source(file.path(root, "R", "features.R"))
source(file.path(root, "config", "params.R"))

args <- read_args(list("data-dir" = file.path(root, "data"),
  "output-dir" = file.path(root, "artifacts", "model"), "library" = file.path(root, ".R-library")))
load_packages(args[["library"]])
invisible(Sys.setlocale("LC_COLLATE", "C"))

train <- read_data(args[["data-dir"]], "train")
test <- read_data(args[["data-dir"]], "test")
sample_file <- read_data(args[["data-dir"]], "sample_submission")
stopifnot(!anyNA(train$SalePrice), all(train$SalePrice > 0), !anyDuplicated(train$Id))

train_x <- add_features(train)
test_x <- add_features(test)
stopifnot(identical(names(train_x), names(test_x)))
prep <- fit_preprocess(train_x)
train_pool <- catboost::catboost.load_pool(prep_data(train_x, prep), label = log(train$SalePrice))
create_output(args[["output-dir"]])
model <- catboost::catboost.train(train_pool, params = params)
test_pool <- catboost::catboost.load_pool(prep_data(test_x, prep))
pred <- as.numeric(catboost::catboost.predict(model, test_pool))
submission <- data.frame(Id = test$Id, SalePrice = exp(pred))
check_submission(submission, test, sample_file)

output <- args[["output-dir"]]
write.csv(submission, file.path(output, "submission.csv"), row.names = FALSE)
catboost::catboost.save_model(model, file.path(output, "catboost.cbm"))
saveRDS(prep, file.path(output, "prep.rds"))
capture.output(sessionInfo(), file = file.path(output, "session.txt"))
cat("Saved:", normalizePath(file.path(output, "submission.csv")), "\n")
